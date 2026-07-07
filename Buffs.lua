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
    if auraIdCache[auraSpellId] ~= nil then
        return auraIdCache[auraSpellId]
    end

    if trackedById[auraSpellId] then
        auraIdCache[auraSpellId] = auraSpellId
        return auraSpellId
    end

    local name = C_Spell.GetSpellName(auraSpellId)
    if name and spellNameToId[name] then
        auraIdCache[auraSpellId] = spellNameToId[name]
        return spellNameToId[name]
    end

    auraIdCache[auraSpellId] = false
    return false
end

local scanErrorLogged = false

function Buffs:ScanUnit(unitId)
    local found = {}
    if not cachedPlayerGUID then cachedPlayerGUID = UnitGUID("player") end

    local ids = C_UnitAuras.GetUnitAuraInstanceIDs(unitId, "HELPFUL")
    if not ids then return found end

    local unitIsPlayer = UnitIsUnit(unitId, "player")

    for _, instanceId in ipairs(ids) do
        local ok, err = pcall(function()
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unitId, instanceId)
            if not aura or not aura.spellId or issecretvalue(aura.spellId) then return end

            local trackedId = ResolveSpellId(aura.spellId)
            if not trackedId then return end

            local info = trackedById[trackedId]

            if info.selfBuff and not unitIsPlayer then return end

            if not unitIsPlayer then
                local sourceOk, isOurs = pcall(function()
                    if aura.sourceUnit and not issecretvalue(aura.sourceUnit) then
                        return UnitIsUnit(aura.sourceUnit, "player")
                    end
                    return true
                end)
                if sourceOk and not isOurs then return end
            end

            local duration, expirationTime
            local durOk, d, e = pcall(function()
                return tonumber(aura.duration) or 0, tonumber(aura.expirationTime) or 0
            end)
            if durOk and d and d > 0 then
                duration = d
                expirationTime = e
            else
                duration = info.baseDuration or 0
                expirationTime = GetTime() + duration
            end

            found[trackedId] = {
                name = info.name,
                duration = duration,
                expirationTime = expirationTime,
                applied = expirationTime - duration,
            }
        end)

        if not ok and not scanErrorLogged then
            OffBeat:Print("Aura scan error (subsequent errors suppressed): " .. tostring(err))
            scanErrorLogged = true
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
