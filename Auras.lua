local OffBeat = _G.OffBeat
local Auras = OffBeat:NewModule("Auras", "AceEvent-3.0")

-- Built on enable from activeProfile.trackedAuras
local trackedById = {}
local nameToId = {}
local auraIdCache = {}

function Auras:OnEnable()
    self:BuildLookups()
    self:RegisterEvent("UNIT_AURA")
    OffBeat.state.auras = self:ScanPlayer()
end

function Auras:OnDisable()
    self:UnregisterEvent("UNIT_AURA")
    wipe(OffBeat.state.auras)
    wipe(trackedById)
    wipe(nameToId)
    wipe(auraIdCache)
end

function Auras:BuildLookups()
    wipe(trackedById)
    wipe(nameToId)
    wipe(auraIdCache)

    local profile = OffBeat.activeProfile
    if not profile or not profile.trackedAuras then return end

    local hasHarmful = false
    for _, aura in ipairs(profile.trackedAuras) do
        trackedById[aura.spellId] = aura
        if aura.name then
            nameToId[aura.name] = aura.spellId
        end
        if aura.filter == "HARMFUL" then hasHarmful = true end
    end

    self.auraFilters = { "HELPFUL" }
    if hasHarmful then self.auraFilters[2] = "HARMFUL" end
end

local function ResolveSpellId(auraSpellId)
    return OffBeat.ResolveSpellId(auraSpellId, trackedById, nameToId, auraIdCache)
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

local function ExtractAuraRecord(aura, info)
    local d = SafeNumber(aura.duration, 0)
    local e = SafeNumber(aura.expirationTime, 0)
    local duration, expirationTime

    if d > 0 then
        duration = d
        expirationTime = e
    else
        duration = info.baseDuration or 0
        expirationTime = duration > 0 and (GetTime() + duration) or 0
    end

    local stacks = SafeNumber(aura.applications, 0)

    return {
        name = info.name,
        duration = duration,
        expirationTime = expirationTime,
        stacks = stacks,
    }
end

function Auras:ScanPlayer()
    local found = {}

    local profile = OffBeat.activeProfile
    if not profile or not profile.trackedAuras then return found end

    -- 1. Direct query via GetPlayerAuraBySpellID for each tracked aura.
    -- This targets specific spell IDs and completely sidesteps secret encounter auras,
    -- avoiding the "Auras cannot be accessed when secret while tainted" engine restriction.
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        for _, info in ipairs(profile.trackedAuras) do
            local trackedId = info.spellId
            local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, trackedId)
            if ok and aura and not IsSecret(aura) then
                found[trackedId] = ExtractAuraRecord(aura, info)
            end
        end
    end

    -- 2. Fallback scan using GetUnitAuraInstanceIDs for any tracked auras not found above
    -- (e.g. if an aura is applied by a different sub-spell ID or matched by name).
    -- We skip this if C_Secrets flags that secret auras are active, and guard the call with pcall.
    local shouldSkip = false
    if C_Secrets and C_Secrets.ShouldAurasBeSecret then
        local ok, secret = pcall(C_Secrets.ShouldAurasBeSecret)
        if ok and secret then
            shouldSkip = true
        end
    end

    if not shouldSkip then
        for _, filter in ipairs(self.auraFilters) do
            self:ScanPlayerFilter(found, filter)
        end
    end

    return found
end

function Auras:ScanPlayerFilter(found, filter)
    if not C_UnitAuras or not C_UnitAuras.GetUnitAuraInstanceIDs then return end

    local ok, ids = pcall(C_UnitAuras.GetUnitAuraInstanceIDs, "player", filter)
    if not ok or not ids or IsSecret(ids) then return end

    for _, instanceId in ipairs(ids) do
        if not IsSecret(instanceId) then
            local auraOk, aura = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", instanceId)
            if auraOk and aura and not IsSecret(aura) then
                local trackedId
                if aura.spellId and not IsSecret(aura.spellId) then
                    trackedId = ResolveSpellId(aura.spellId)
                end

                if not trackedId and aura.name and not IsSecret(aura.name) and nameToId[aura.name] then
                    trackedId = nameToId[aura.name]
                end

                if trackedId and not found[trackedId] then
                    local info = trackedById[trackedId]
                    if info then
                        found[trackedId] = ExtractAuraRecord(aura, info)
                    end
                end
            end
        end
    end
end


function Auras:UNIT_AURA(_, unit)
    if unit ~= "player" then return end

    local previous = OffBeat.state.auras or {}
    local current = self:ScanPlayer()

    for spellId, aura in pairs(current) do
        if not previous[spellId] then
            OffBeat:Debug("Aura gained:", aura.name, "stacks:", aura.stacks)
            self:SendMessage("OFFBEAT_AURA_GAINED", spellId, aura)
        elseif aura.stacks ~= previous[spellId].stacks then
            OffBeat:Debug("Aura stacks:", aura.name, previous[spellId].stacks, "->", aura.stacks)
            self:SendMessage("OFFBEAT_AURA_STACKS", spellId, aura)
        end
    end

    for spellId in pairs(previous) do
        if not current[spellId] then
            local info = trackedById[spellId]
            OffBeat:Debug("Aura lost:", info and info.name or spellId)
            self:SendMessage("OFFBEAT_AURA_LOST", spellId)
        end
    end

    OffBeat.state.auras = current
    self:SendMessage("OFFBEAT_AURAS_UPDATED")
end

function Auras:GetAura(spellId)
    return OffBeat.state.auras and OffBeat.state.auras[spellId]
end

function Auras:IsActive(spellId)
    return self:GetAura(spellId) ~= nil
end
