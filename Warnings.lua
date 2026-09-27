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
        if rule.requireBuff then
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

    local buff = self:GetRequiredBuff(rule.requireBuff)
    if not buff then
        self:Fire(string.format("%s cast — no %s", name, rule.buffName or "required buff"))
        return
    end

    local castTime = self:GetCastTime()
    local remaining = buff.expirationTime - GetTime()
    if castTime > remaining then
        self:Fire(string.format("%s (%.1fs) > %s (%.1fs)",
            name, castTime, rule.buffName or "buff", remaining))
    end
end

function Warnings:GetRequiredBuff(spellId)
    if not spellId then return nil end
    local guid = UnitGUID("player")
    local spells = guid and OffBeat.state.buffs[guid]
    return spells and spells[spellId]
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
