local OffBeat = _G.OffBeat
local Warnings = OffBeat:NewModule("Warnings", "AceEvent-3.0")

local SOUND_ID = 8959 -- SOUNDKIT.RAID_WARNING

-- Built on enable from activeProfile.castWarnings
local trackedCastNames = {} -- spellName -> warning rule
local requiredBuffIds = {}  -- spellId -> true (buffs to check for)

function Warnings:OnEnable()
    self:BuildLookups()
    self:RegisterEvent("UNIT_SPELLCAST_START", "OnCastStart")
    self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START", "OnCastStart")
end

function Warnings:OnDisable()
    self:UnregisterAllEvents()
    wipe(trackedCastNames)
    wipe(requiredBuffIds)
end

function Warnings:BuildLookups()
    wipe(trackedCastNames)
    wipe(requiredBuffIds)

    local profile = OffBeat.activeProfile
    if not profile or not profile.castWarnings then return end

    for _, rule in ipairs(profile.castWarnings) do
        if rule.castNames then
            for _, name in ipairs(rule.castNames) do
                trackedCastNames[name] = rule
            end
        end
        if type(rule.requireBuff) == "table" then
            for _, id in ipairs(rule.requireBuff) do requiredBuffIds[id] = true end
        elseif rule.requireBuff then
            requiredBuffIds[rule.requireBuff] = true
        end
    end
end

function Warnings:OnCastStart(_, unit, _, spellId)
    if unit ~= "player" then return end
    if not OffBeat.db.profile.castWarnings then return end

    local name = C_Spell.GetSpellName(spellId)
    if not name then return end

    local rule = trackedCastNames[name]
    if not rule then return end

    -- true = up, false = not up, nil = the game won't say (no warning)
    local up, buff = self:GetRequiredBuff(rule.requireBuff)
    if up == false then
        self:Fire(string.format("%s cast — no %s", name, rule.buffName or "required buff"))
        return
    end
    if not up or not buff then return end

    -- only when the real timer is readable, not a guess
    local castTime = self:GetCastTime()
    local remaining = buff.expirationTime - GetTime()
    if castTime > 0 and castTime > remaining then
        self:Fire(string.format("%s (%.1fs) > %s (%.1fs)",
            name, castTime, rule.buffName or "buff", remaining))
    end
end

local function IsSecret(v)
    if v == nil or not _G.issecretvalue then return false end
    local ok, s = pcall(_G.issecretvalue, v)
    return ok and s
end

--- Is the buff up on you right now? Asks the game at cast time (any of
--- the IDs, e.g. Ebon Might 395296 / 395152), falling back to the buff
--- panel's state. Returns true/false, or nil when auras are hidden and
--- nothing says it's up, plus a record with a readable expirationTime.
function Warnings:GetRequiredBuff(ids)
    if not ids then return nil end
    if type(ids) ~= "table" then ids = { ids } end
    local C = OffBeat.Conditions
    -- 1. The game says it's up (out of combat, or when it shows it)
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        for _, id in ipairs(ids) do
            local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
            if ok and aura ~= nil then
                if IsSecret(aura) then return true, nil end
                local okE, e = pcall(tonumber, aura.expirationTime)
                local okD, d = pcall(tonumber, aura.duration)
                if okE and okD and e and d and not IsSecret(e) and not IsSecret(d) and d > 0 then
                    return true, { expirationTime = e }
                end
                return true, nil
            end
        end
    end
    local guid = UnitGUID("player")
    local spells = guid and OffBeat.state.buffs[guid]
    if spells then
        for _, id in ipairs(ids) do
            local rec = spells[id]
            if rec and not rec.modeled then return true, (not rec.hiddenTimer) and rec or nil end
        end
    end
    -- 2. Since 12.1 the game hides auras in combat: go by your casts
    for _, id in ipairs(ids) do
        local up = C.CastAuraUp(id)
        if up ~= nil then return up, nil end
    end
    -- 3. No model: only trust "not up" when the game isn't hiding auras
    if C.AurasHidden() then return nil end
    return false
end

function Warnings:GetCastTime()
    local _, _, _, startMS, endMS = UnitCastingInfo("player")
    if not startMS then
        _, _, _, startMS, endMS = UnitChannelInfo("player")
    end
    if startMS and endMS and endMS > startMS then
        return (endMS - startMS) / 1000
    end
    return 0
end

function Warnings:Fire(msg)
    PlaySound(SOUND_ID, "Master")
    OffBeat:Print("|cffff8800Warning:|r " .. msg)
end
