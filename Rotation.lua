local OffBeat = _G.OffBeat
local Rotation = OffBeat:NewModule("Rotation", "AceEvent-3.0")

-- Built on enable from activeProfile
local rotationSpellSet = {}   -- spellId -> true
local idleCooldownSet = {}    -- spellId -> { name }
local procWasteRules = {}     -- array of { procAura, wasteSpells={id->true}, name }
local hasRepeatCastMistake = false
local repeatCastName = "Mistake"
local keyCd                   -- profile.keyCooldown or nil

local MISTAKE_EVALUATORS = {
    repeat_cast = function(spellId, state)
        return spellId == state.lastSpellId
    end,
    proc_waste = function(spellId, state, rule)
        local auras = OffBeat:GetModule("Auras", true)
        return auras and auras:IsActive(rule.procAura) and rule.wasteSpells[spellId]
    end,
}

local function NewCombatStats()
    return {
        totalCasts = 0,
        mistakes = 0,
        mistakeLog = {},
        casts = {},
        startTime = GetTime(),
    }
end

local function RecordToStats(stats, spellId, now, mistakeName)
    stats.totalCasts = stats.totalCasts + 1
    local entry = { spellId = spellId, time = now }
    if mistakeName then
        entry.mistake = mistakeName
        stats.mistakes = stats.mistakes + 1
        stats.mistakeLog[#stats.mistakeLog + 1] = { spellId = spellId, time = now, name = mistakeName }
    end
    stats.casts[#stats.casts + 1] = entry
end

function Rotation:OnEnable()
    self:BuildLookups()
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("CHALLENGE_MODE_RESET")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")

    if OffBeat.activeProfile and OffBeat.activeProfile.procTracking then
        self:RegisterMessage("OFFBEAT_AURA_GAINED", "OnAuraGained")
        self:RegisterMessage("OFFBEAT_AURA_LOST", "OnAuraLost")
    end
end

function Rotation:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    self.keyCdReady = nil
    self.keyCdActiveUntil = nil
    self.idleState = nil
    self.procState = nil
end

function Rotation:BuildLookups()
    wipe(rotationSpellSet)
    wipe(idleCooldownSet)
    wipe(procWasteRules)
    hasRepeatCastMistake = false
    keyCd = nil

    local profile = OffBeat.activeProfile
    if not profile then return end

    if profile.rotationSpells then
        for _, spell in ipairs(profile.rotationSpells) do
            rotationSpellSet[spell.spellId] = true
        end
    end

    if profile.mistakes then
        for _, rule in ipairs(profile.mistakes) do
            if rule.type == "repeat_cast" then
                hasRepeatCastMistake = true
                repeatCastName = rule.name or "Mistake"
            elseif rule.type == "proc_waste" then
                local wasteSet = {}
                if rule.wasteSpells then
                    for _, id in ipairs(rule.wasteSpells) do wasteSet[id] = true end
                end
                procWasteRules[#procWasteRules + 1] = {
                    procAura = rule.procAura,
                    wasteSpells = wasteSet,
                    name = rule.name or "Proc Waste",
                }
            end
        end
    end

    if profile.idleCooldowns then
        for _, cd in ipairs(profile.idleCooldowns) do
            idleCooldownSet[cd.spellId] = { name = cd.name or tostring(cd.spellId) }
        end
    end

    keyCd = profile.keyCooldown
end

-- Cast tracking

function Rotation:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, spellId)
    if unit ~= "player" then return end
    if not rotationSpellSet[spellId] then return end
    self:RecordAbility(spellId)
end

function Rotation:RecordAbility(spellId)
    local state = OffBeat.state
    local maxHistory = OffBeat.db.profile.historyCount

    local mistakeName = self:EvaluateMistakes(spellId, state)

    if mistakeName then
        if OffBeat.db.profile.soundEnabled then
            OffBeat:PlayConfigSound("mistakeSound")
        end
        self:SendMessage("OFFBEAT_MISTAKE", spellId, mistakeName)
    end

    if keyCd and keyCd.wasteSpell and OffBeat.db.profile.keyCdWasteAlert then
        local wasteId = type(keyCd.wasteSpell) == "table" and keyCd.wasteSpell.spellId or keyCd.wasteSpell
        if spellId == wasteId then
            local auras = OffBeat:GetModule("Auras", true)
            local cdActive = (auras and auras:IsActive(keyCd.spellId))
                or (self.keyCdActiveUntil and GetTime() < self.keyCdActiveUntil)
            if cdActive then
                OffBeat:PlayConfigSound("keyCdWasteSound")
                local wasteName = type(keyCd.wasteSpell) == "table" and keyCd.wasteSpell.name or nil
                self:SendMessage("OFFBEAT_PROC_WASTE", spellId, wasteName)
            end
        end
    end

    state.lastSpellId = spellId

    table.insert(state.history, 1, {
        spellId = spellId,
        mistake = mistakeName,
        time = GetTime(),
    })

    while #state.history > maxHistory do
        table.remove(state.history)
    end

    local now = GetTime()
    if state.combat then RecordToStats(state.combat, spellId, now, mistakeName) end
    if state.rotationKeystone then RecordToStats(state.rotationKeystone, spellId, now, mistakeName) end

    self:SendMessage("OFFBEAT_HISTORY_UPDATED")
end

function Rotation:EvaluateMistakes(spellId, state)
    if hasRepeatCastMistake then
        if MISTAKE_EVALUATORS.repeat_cast(spellId, state) then
            return repeatCastName
        end
    end

    for _, rule in ipairs(procWasteRules) do
        if MISTAKE_EVALUATORS.proc_waste(spellId, state, rule) then
            return rule.name
        end
    end

    return nil
end

-- Key cooldown tracking

function Rotation:SPELL_UPDATE_COOLDOWN()
    self:CheckKeyCdReady()
    if OffBeat.db.profile.idleCooldownAlert and UnitAffectingCombat("player") then
        self:CheckIdleCooldowns()
    end
end

function Rotation:CheckKeyCdReady()
    if not keyCd then return end
    if not IsPlayerSpell(keyCd.spellId) then return end

    local info = C_Spell.GetSpellCooldown(keyCd.spellId)
    if not info then return end

    local ready = not info.isActive

    -- Spells like Avenging Wrath start their cooldown after the buff
    -- expires, so isActive is false during the buff. Check the aura too.
    if ready then
        local auras = OffBeat:GetModule("Auras", true)
        if auras and auras:IsActive(keyCd.spellId) then
            ready = false
        end
    end

    if ready and not self.keyCdReady then
        self.keyCdReady = true
        if OffBeat.db.profile.keyCdAlert and UnitAffectingCombat("player") then
            OffBeat:PlayConfigSound("keyCdSound")
        end
        self:SendMessage("OFFBEAT_KEY_CD_READY", keyCd)
    elseif not ready and self.keyCdReady then
        self.keyCdReady = false
        local dur = OffBeat.db.profile.keyCdDuration
        self.keyCdActiveUntil = GetTime() + dur
        OffBeat:Debug("Key CD pressed, window for", dur .. "s")
        self:SendMessage("OFFBEAT_KEY_CD_USED", keyCd)
    elseif not ready then
        self.keyCdReady = false
    end
end

function Rotation:CheckIdleCooldowns()
    local now = GetTime()
    local threshold = OffBeat.db.profile.idleCooldownThreshold

    if not self.idleState then self.idleState = {} end

    for spellId, info in pairs(idleCooldownSet) do
        if IsPlayerSpell(spellId) then
            local cdInfo = C_Spell.GetSpellCooldown(spellId)
            local usable = C_Spell.IsSpellUsable(spellId)
            local ready = cdInfo and not cdInfo.isActive and usable

            if ready then
                local st = self.idleState[spellId]
                if not st then
                    self.idleState[spellId] = { readySince = now, warned = false }
                elseif not st.warned and (now - st.readySince) >= threshold then
                    st.warned = true
                    OffBeat:PlayConfigSound("idleCooldownSound")
                    self:SendMessage("OFFBEAT_COOLDOWN_IDLE", spellId, info.name)
                end
            else
                self.idleState[spellId] = nil
            end
        end
    end
end

-- Proc tracking (e.g., Rime)

function Rotation:OnAuraGained(_, spellId)
    local profile = OffBeat.activeProfile
    if not profile or not profile.procTracking then return end

    if not self.procState then self.procState = {} end

    for _, pt in ipairs(profile.procTracking) do
        if spellId == pt.procAura then
            self.procState[spellId] = { gained = GetTime() }
            if OffBeat.state.combat then
                OffBeat.state.combat.procsGained = (OffBeat.state.combat.procsGained or 0) + 1
            end
        end
    end
end

function Rotation:OnAuraLost(_, spellId)
    local profile = OffBeat.activeProfile
    if not profile or not profile.procTracking then return end

    for _, pt in ipairs(profile.procTracking) do
        if spellId == pt.procAura then
            local window = pt.window or 0.5
            local consumed = false
            for _, entry in ipairs(OffBeat.state.history) do
                if entry.spellId == pt.consumeSpell and (GetTime() - entry.time) <= window then
                    consumed = true
                    break
                end
            end
            if not consumed then
                if OffBeat.db.profile.procExpireAlert then
                    OffBeat:PlayConfigSound("procExpireSound")
                end
                self:SendMessage("OFFBEAT_PROC_EXPIRED", spellId, pt.name)
                if OffBeat.state.combat then
                    OffBeat.state.combat.procsExpired = (OffBeat.state.combat.procsExpired or 0) + 1
                end
            end
            if self.procState then self.procState[spellId] = nil end
        end
    end
end

-- Combat tracking

function Rotation:PLAYER_REGEN_DISABLED()
    OffBeat.state.combat = NewCombatStats()
    self.idleState = nil
end

function Rotation:PLAYER_REGEN_ENABLED()
    local combat = OffBeat.state.combat
    if combat and combat.totalCasts > 0 then
        combat.endTime = GetTime()
        self:PrintCombatReport(combat, "Combat")
        OffBeat.state.lastEncounter = combat
        self:SendMessage("OFFBEAT_ROTATION_ENCOUNTER_END", combat)
    end
    OffBeat.state.combat = nil

    if OffBeat.db.profile.clearOnCombatEnd then
        wipe(OffBeat.state.history)
        OffBeat.state.lastSpellId = nil
        self:SendMessage("OFFBEAT_HISTORY_UPDATED")
    end
end

-- Keystone tracking

function Rotation:CHALLENGE_MODE_START()
    OffBeat.state.rotationKeystone = NewCombatStats()
    OffBeat:Print("Keystone started — tracking rotation.")
end

function Rotation:CHALLENGE_MODE_COMPLETED()
    self:EndKeystone()
end

function Rotation:CHALLENGE_MODE_RESET()
    self:EndKeystone()
end

function Rotation:PLAYER_ENTERING_WORLD()
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive()
        and not OffBeat.state.rotationKeystone then
        OffBeat.state.rotationKeystone = NewCombatStats()
    end
end

function Rotation:EndKeystone()
    local ks = OffBeat.state.rotationKeystone
    if ks and ks.totalCasts > 0 then
        ks.endTime = GetTime()
        self:PrintCombatReport(ks, "Keystone")
        OffBeat.state.lastEncounter = ks
        self:SendMessage("OFFBEAT_ROTATION_ENCOUNTER_END", ks)
    end
    OffBeat.state.rotationKeystone = nil
end

-- Reporting

function Rotation:PrintCombatReport(stats, label)
    if not OffBeat.db.profile.combatReport then return end

    local pct = stats.totalCasts > 0
        and (1 - stats.mistakes / stats.totalCasts) * 100
        or 100

    local color = pct == 100 and "|cff00ff00" or (pct >= 95 and "|cffffff00" or "|cffff4444")
    OffBeat:Print(string.format(
        "%s end — %s%.1f%%|r accuracy (%d/%d casts, %d mistake%s)",
        label, color, pct,
        stats.totalCasts - stats.mistakes, stats.totalCasts,
        stats.mistakes, stats.mistakes == 1 and "" or "s"
    ))

    if #stats.mistakeLog > 0 then
        local counts = {}
        for _, entry in ipairs(stats.mistakeLog) do
            local info = C_Spell.GetSpellInfo(entry.spellId)
            local name = info and info.name or tostring(entry.spellId)
            local key = entry.name .. ": " .. name
            counts[key] = (counts[key] or 0) + 1
        end

        local parts = {}
        for name, count in pairs(counts) do
            parts[#parts + 1] = string.format("%s x%d", name, count)
        end
        table.sort(parts)
        OffBeat:Print("  " .. table.concat(parts, ", "))
    end

    if stats.procsGained and stats.procsGained > 0 then
        local expired = stats.procsExpired or 0
        local consumed = stats.procsGained - expired
        local procPct = (consumed / stats.procsGained) * 100
        OffBeat:Print(string.format("  Procs: %d/%d consumed (%.1f%%)",
            consumed, stats.procsGained, procPct))
    end
end

-- Test data injection

function Rotation:InjectTestData()
    local profile = OffBeat.activeProfile
    if not profile or not profile.rotationSpells then
        OffBeat:Print("No rotation profile loaded.")
        return
    end

    wipe(OffBeat.state.history)
    OffBeat.state.lastSpellId = nil

    OffBeat.state.combat = NewCombatStats()

    local spells = profile.rotationSpells
    local count = math.min(#spells, 5)
    for i = 1, count do
        self:RecordAbility(spells[i].spellId)
    end
    -- Repeat last to trigger a mistake
    if count > 0 then
        self:RecordAbility(spells[count].spellId)
        self:RecordAbility(spells[count].spellId)
    end

    local combat = OffBeat.state.combat
    combat.endTime = GetTime()
    self:PrintCombatReport(combat, "Test")
    OffBeat.state.lastEncounter = combat
    OffBeat.state.combat = nil

    local timeline = OffBeat:GetModule("RotationTimeline", true)
    if timeline and timeline:IsEnabled() then timeline:Show(combat) end

    OffBeat:Print("Injected test data.")
end

function OffBeat:InjectTestData()
    local rot = self:GetModule("Rotation", true)
    if rot and rot:IsEnabled() then
        rot:InjectTestData()
    end
end
