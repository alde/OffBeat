local OffBeat = _G.OffBeat
local Buffs = OffBeat:NewModule("Buffs", "AceEvent-3.0")

-- Built on enable from activeProfile.trackedBuffs
local trackedById = {}      -- spellId -> buff entry
local spellNameToId = {}    -- spell name -> canonical spell ID
local auraIdCache = {}      -- aura spell ID -> canonical spell ID (or false)
local cachedPlayerGUID

function Buffs:OnEnable()
    self:BuildLookups()
    self:RegisterEvent("UNIT_AURA")

    local guid = UnitGUID("player")
    if guid then
        local current = self:ScanUnit("player")
        if next(current) then
            OffBeat.state.buffs[guid] = current
        end
    end
end

function Buffs:OnDisable()
    self:UnregisterEvent("UNIT_AURA")
    wipe(trackedById)
    wipe(spellNameToId)
    wipe(auraIdCache)
end

function Buffs:BuildLookups()
    wipe(trackedById)
    wipe(spellNameToId)
    wipe(auraIdCache)

    local profile = OffBeat.activeProfile
    if not profile or not profile.trackedBuffs then return end

    for _, buff in ipairs(profile.trackedBuffs) do
        trackedById[buff.spellId] = buff
        if buff.name then
            spellNameToId[buff.name] = buff.spellId
        end
    end
end

function Buffs:GetTrackedBuff(spellId)
    return trackedById[spellId]
end

local function ResolveSpellId(auraSpellId)
    return OffBeat.ResolveSpellId(auraSpellId, trackedById, spellNameToId, auraIdCache)
end

local function IsSecret(val)
    if val == nil then return false end
    if _G.issecretvalue then
        local ok, secret = pcall(_G.issecretvalue, val)
        return ok and secret
    end
    return false
end

local function SafeNumber(val, default)
    if val == nil or IsSecret(val) then return default or 0 end
    local ok, num = pcall(tonumber, val)
    if ok and num and not IsSecret(num) then
        return num
    end
    return default or 0
end

function Buffs:ScanUnit(unitId)
    local found = {}
    if not cachedPlayerGUID then cachedPlayerGUID = UnitGUID("player") end

    local unitIsPlayer = UnitIsUnit(unitId, "player")

    -- For player, direct lookup via GetPlayerAuraBySpellID avoids secret aura restrictions
    if unitIsPlayer and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local profile = OffBeat.activeProfile
        if profile and profile.trackedBuffs then
            for _, info in ipairs(profile.trackedBuffs) do
                local trackedId = info.spellId
                local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, trackedId)
                if ok and aura and not IsSecret(aura) then
                    local d = SafeNumber(aura.duration, 0)
                    local e = SafeNumber(aura.expirationTime, 0)
                    local duration = (d > 0) and d or (info.baseDuration or 0)
                    local expirationTime = (d > 0) and e or (GetTime() + duration)
                    found[trackedId] = {
                        name = info.name,
                        duration = duration,
                        expirationTime = expirationTime,
                        applied = expirationTime - duration,
                    }
                end
            end
        end
    end

    local shouldSkip = false
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local ok, secret = pcall(C_Secrets.ShouldAurasBeSecret)
        if ok and secret then
            shouldSkip = true
        end
    end
    if shouldSkip then return found end

    if not C_UnitAuras or not C_UnitAuras.GetUnitAuraInstanceIDs then return found end

    local ok, ids = pcall(C_UnitAuras.GetUnitAuraInstanceIDs, unitId, "HELPFUL")
    if not ok or not ids or IsSecret(ids) then return found end

    for _, instanceId in ipairs(ids) do
        if not IsSecret(instanceId) then
            local auraOk, aura = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, unitId, instanceId)
            if auraOk and aura and not IsSecret(aura) then
                local trackedId
                if aura.spellId and not IsSecret(aura.spellId) then
                    trackedId = ResolveSpellId(aura.spellId)
                end
                if not trackedId and aura.name and not IsSecret(aura.name) and spellNameToId[aura.name] then
                    trackedId = spellNameToId[aura.name]
                end

                if trackedId and not found[trackedId] then
                    local info = trackedById[trackedId]
                    if info and (not info.selfBuff or unitIsPlayer) then
                        local isOurs = true
                        if not unitIsPlayer and aura.sourceUnit and not IsSecret(aura.sourceUnit) then
                            isOurs = UnitIsUnit(aura.sourceUnit, "player")
                        end
                        if isOurs then
                            local d = SafeNumber(aura.duration, 0)
                            local e = SafeNumber(aura.expirationTime, 0)
                            local duration = (d > 0) and d or (info.baseDuration or 0)
                            local expirationTime = (d > 0) and e or (GetTime() + duration)
                            found[trackedId] = {
                                name = info.name,
                                duration = duration,
                                expirationTime = expirationTime,
                                applied = expirationTime - duration,
                            }
                        end
                    end
                end
            end
        end
    end

    return found
end


function Buffs:UNIT_AURA(_, unitId)
    if not self:IsTrackedUnit(unitId) then return end
    if unitId ~= "player" and UnitIsUnit(unitId, "player") then return end

    local guid = UnitGUID(unitId)
    if not guid then return end

    local now = GetTime()
    local previous = OffBeat.state.buffs[guid] or {}
    local current = self:ScanUnit(unitId)

    for spellId, aura in pairs(current) do
        if not previous[spellId] then
            self:SendMessage("OFFBEAT_BUFF_APPLIED", guid, spellId, aura, now)
        end
    end

    for spellId in pairs(previous) do
        if not current[spellId] then
            self:SendMessage("OFFBEAT_BUFF_REMOVED", guid, spellId, now)
        end
    end

    if next(current) then
        OffBeat.state.buffs[guid] = current
    else
        OffBeat.state.buffs[guid] = nil
    end

    self:SendMessage("OFFBEAT_BUFFS_UPDATED")
end

function Buffs:IsTrackedUnit(unitId)
    if not unitId then return false end
    return unitId == "player" or unitId:match("^party%d") or unitId:match("^raid%d")
end

function Buffs:GetSortedSpells()
    local primary, secondary = {}, {}
    for id, info in pairs(trackedById) do
        if info.category == "primary" then
            primary[#primary + 1] = id
        else
            secondary[#secondary + 1] = id
        end
    end
    table.sort(primary)
    table.sort(secondary)
    local result = {}
    for _, id in ipairs(primary) do result[#result + 1] = id end
    for _, id in ipairs(secondary) do result[#result + 1] = id end
    return result
end
