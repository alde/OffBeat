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

    for _, aura in ipairs(profile.trackedAuras) do
        trackedById[aura.spellId] = aura
        if aura.name then
            nameToId[aura.name] = aura.spellId
        end
    end
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
    if name and nameToId[name] then
        auraIdCache[auraSpellId] = nameToId[name]
        return nameToId[name]
    end

    auraIdCache[auraSpellId] = false
    return false
end

local scanErrorLogged = false

function Auras:ScanPlayer()
    local found = {}

    local ids = C_UnitAuras.GetUnitAuraInstanceIDs("player", "HELPFUL")
    if not ids then return found end

    for _, instanceId in ipairs(ids) do
        local ok, err = pcall(function()
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", instanceId)
            if not aura then return end

            local trackedId
            local spellIdOk, sid = pcall(function() return aura.spellId end)
            if spellIdOk and sid and not issecretvalue(sid) then
                trackedId = ResolveSpellId(sid)
            end

            if not trackedId then
                local nameOk, auraName = pcall(function() return aura.name end)
                if nameOk and auraName and not issecretvalue(auraName) and nameToId[auraName] then
                    trackedId = nameToId[auraName]
                end
            end

            if not trackedId then return end

            local info = trackedById[trackedId]

            local duration, expirationTime, stacks
            local durOk, d, e = pcall(function()
                return tonumber(aura.duration) or 0, tonumber(aura.expirationTime) or 0
            end)
            if durOk and d and d > 0 then
                duration = d
                expirationTime = e
            else
                duration = info.baseDuration or 0
                expirationTime = duration > 0 and (GetTime() + duration) or 0
            end

            local stackOk, s = pcall(function() return aura.applications or 0 end)
            stacks = stackOk and s or 0

            found[trackedId] = {
                name = info.name,
                duration = duration,
                expirationTime = expirationTime,
                stacks = stacks,
            }
        end)

        if not ok and not scanErrorLogged then
            OffBeat:Print("Aura scan error (subsequent errors suppressed): " .. tostring(err))
            scanErrorLogged = true
        end
    end

    return found
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
