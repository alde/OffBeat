local OffBeat = _G.OffBeat
local Buffs = OffBeat:NewModule("Buffs", "AceEvent-3.0")

-- Built on enable from activeProfile.trackedBuffs
local trackedById = {}      -- spellId -> buff entry
local spellNameToId = {}    -- spell name -> canonical spell ID
local auraIdCache = {}      -- aura spell ID -> canonical spell ID (or false)
local cachedPlayerGUID

local TICK = 0.25
local ticker
local sentTarget = {}       -- castGUID -> target name (UNIT_SPELLCAST_SENT)

function Buffs:OnEnable()
    self:BuildLookups()
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_SPELLCAST_SENT")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    -- Countdowns move and expired buffs drop off between aura events (and
    -- while the game hides other players' auras, when no events come).
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(TICK, function() Buffs:Tick() end)

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
    self:UnregisterEvent("UNIT_SPELLCAST_SENT")
    self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    if ticker then ticker:Cancel(); ticker = nil end
    wipe(sentTarget)
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

local function AurasSecret()
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local ok, secret = pcall(C_Secrets.ShouldAurasBeSecret)
        return ok and secret and not IsSecret(secret) and true or false
    end
    return false
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
                local ids = { trackedId }
                for _, a in ipairs(info.alt or {}) do ids[#ids + 1] = a end
                for _, id in ipairs(ids) do
                    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
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
                            -- the game hid the real timer: this is a guess
                            hiddenTimer = not (d > 0) or nil,
                        }
                        break
                    end
                end
            end
        end
    end

    -- Walk the unit's auras one by one even when the game says auras are
    -- secret (as AugWoke did): your own Augmentation buffs stay readable in
    -- combat, only individual hidden auras are skipped. The by-ID lookup
    -- above returns nothing in combat, so this is the one that counts.
    if not C_UnitAuras or not C_UnitAuras.GetUnitAuraInstanceIDs then return found, false end

    local ok, ids = pcall(C_UnitAuras.GetUnitAuraInstanceIDs, unitId, "HELPFUL")
    if not ok or not ids or IsSecret(ids) then return found, false end

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
                                hiddenTimer = not (d > 0) or nil,
                            }
                        end
                    end
                end
            end
        end
    end

    return found, true
end


function Buffs:UNIT_AURA(_, unitId)
    if not self:IsTrackedUnit(unitId) then return end
    if unitId ~= "player" and UnitIsUnit(unitId, "player") then return end

    local guid = UnitGUID(unitId)
    if not guid or IsSecret(guid) then return end

    local now = GetTime()
    local previous = OffBeat.state.buffs[guid] or {}
    local current, readable = self:ScanUnit(unitId)
    -- a scan the game refused says nothing: keep what we had (it expires
    -- on its own timer) instead of wiping it
    if not readable then return end
    -- Since 12.1 the game hides aura data in combat, so a buff missing from
    -- the scan may just be hidden: keep what we had (Prescience from your
    -- casts, Ebon Might from the cast model); it runs out on its own timer.
    if OffBeat.Conditions.AurasHidden() then
        for spellId, rec in pairs(previous) do
            if not current[spellId] then current[spellId] = rec end
        end
    end

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

--- Find the group unit with this name (for a cast's target).
local function UnitByName(name)
    if not name or IsSecret(name) or name == "" then return nil end
    local short = name:match("^([^-]+)") or name
    local function match(u)
        if not UnitExists(u) then return false end
        local ok, n = pcall(UnitName, u)
        return ok and n and not IsSecret(n) and (n == name or n == short)
    end
    if match("player") then return "player" end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            if match("raid" .. i) then return "raid" .. i end
        end
    else
        for i = 1, 4 do
            if match("party" .. i) then return "party" .. i end
        end
    end
    return nil
end

function Buffs:UNIT_SPELLCAST_SENT(_, unit, target, castGUID)
    if unit ~= "player" or not castGUID or IsSecret(castGUID) then return end
    sentTarget[castGUID] = target
end

--- Your own buff casts on others, for when their auras are hidden: the
--- buff goes on the cast's target for its base duration (Prescience 18s).
--- While auras can be read, UNIT_AURA has the real values and this skips.
function Buffs:UNIT_SPELLCAST_SUCCEEDED(_, unit, castGUID, spellId)
    if unit ~= "player" then return end
    local target = castGUID and not IsSecret(castGUID) and sentTarget[castGUID]
    if castGUID and not IsSecret(castGUID) then sentTarget[castGUID] = nil end
    if not spellId or IsSecret(spellId) or not AurasSecret() then return end

    local trackedId = ResolveSpellId(spellId)
    local info = trackedId and trackedById[trackedId]
    if not info or info.selfBuff or not info.baseDuration or info.baseDuration <= 0 then return end

    local u = UnitByName(target)
    local guid = u and UnitGUID(u)
    if not guid or IsSecret(guid) then return end

    local now = GetTime()
    local spells = OffBeat.state.buffs[guid] or {}
    local isNew = not spells[trackedId]
    spells[trackedId] = {
        name = info.name,
        duration = info.baseDuration,
        expirationTime = now + info.baseDuration,
        applied = now,
        estimated = true,
    }
    OffBeat.state.buffs[guid] = spells
    if isNew then
        self:SendMessage("OFFBEAT_BUFF_APPLIED", guid, trackedId, spells[trackedId], now)
    end
    self:SendMessage("OFFBEAT_BUFFS_UPDATED")
end

--- Drop buffs that ran out without an aura event telling us, and redraw
--- the countdowns.
function Buffs:Tick()
    local buffs = OffBeat.state.buffs
    local now = GetTime()
    self:ApplyCastModels(now)
    if not next(buffs) then return end
    for guid, spells in pairs(buffs) do
        for spellId, aura in pairs(spells) do
            local e = aura.expirationTime
            if type(e) == "number" and e > 0 and e < now - 0.5 and not aura.modeled then
                spells[spellId] = nil
                self:SendMessage("OFFBEAT_BUFF_REMOVED", guid, spellId, now)
            end
        end
        if not next(spells) then buffs[guid] = nil end
    end
    self:SendMessage("OFFBEAT_BUFFS_UPDATED")
end

--- Self buffs with a cast model (Ebon Might): while the game hides the
--- real aura, show the estimate from your casts; drop it when it runs out.
function Buffs:ApplyCastModels(now)
    local guid = UnitGUID("player")
    if not guid then return end
    local C = OffBeat.Conditions
    for id, info in pairs(trackedById) do
        if info.selfBuff then
            local up, untilT = C.CastAuraUp(id)
            if up ~= nil then
                local spells = OffBeat.state.buffs[guid]
                local rec = spells and spells[id]
                local real = rec and not rec.modeled and not rec.hiddenTimer
                if not real then
                    if up and untilT and untilT > now then
                        spells = spells or {}
                        local isNew = not rec
                        spells[id] = {
                            name = info.name,
                            duration = math.max(untilT - now, rec and rec.duration or 0),
                            expirationTime = untilT,
                            applied = rec and rec.applied or now,
                            modeled = true,
                        }
                        OffBeat.state.buffs[guid] = spells
                        if isNew then self:SendMessage("OFFBEAT_BUFF_APPLIED", guid, id, spells[id], now) end
                    elseif rec and not up then
                        spells[id] = nil
                        if not next(spells) then OffBeat.state.buffs[guid] = nil end
                        self:SendMessage("OFFBEAT_BUFF_REMOVED", guid, id, now)
                    end
                end
            end
        end
    end
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
