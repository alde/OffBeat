local OffBeat = _G.OffBeat
local Rotation = OffBeat:NewModule("Rotation", "AceEvent-3.0")

-- Built on enable from activeProfile
local rotationSpellSet = {}   -- spellId -> true
local idleCooldownSet = {}    -- spellId -> { name }
local badCastRules = {}       -- array of { spells={id->true}, conds={...}, name }
local pendingCasts = {}       -- castGUID -> mistake name (or false), judged at UNIT_SPELLCAST_SENT
local pendingCount = 0
local hasRepeatCastMistake = false
local repeatCastName = "Mistake"
local activeSpecId            -- cached for specSettings lookups
local keyCd                   -- profile.keyCooldown or nil
local keyCdResolvedId         -- resolved spell ID for key cooldown

-- Is the spell's real cooldown running? The global cooldown (GCD) does not count:
-- GetSpellCooldown reports GCD-bound spells (e.g. Dancing Rune Weapon) as active
-- after every button press, which made them look "used" and reset idle timers.
local GCD_SPELL_ID = 61304

function OffBeat:IsSpellOnRealCooldown(spellId)
    local info = C_Spell.GetSpellCooldown(spellId)
    if not info or not info.isActive then return false end
    if info.isOnGCD then return false end
    local ok, onGcd = pcall(function()
        local gcd = C_Spell.GetSpellCooldown(GCD_SPELL_ID)
        return gcd and gcd.duration and gcd.duration > 0
            and info.startTime == gcd.startTime and info.duration == gcd.duration
    end)
    if ok and onGcd then return false end
    return true
end

local function ResolvePlayerSpell(spellId, name)
    if IsPlayerSpell(spellId) then return spellId end
    if FindSpellOverrideByID then
        local override = FindSpellOverrideByID(spellId)
        if override ~= spellId and IsPlayerSpell(override) then return override end
    end
    if name then
        local info = C_Spell.GetSpellInfo(name)
        if info and info.spellID and IsPlayerSpell(info.spellID) then return info.spellID end
    end
    return spellId
end

-- Offensive racial cooldowns. Shared by every spec; entries the character
-- doesn't know are skipped, so only your own race's racial is tracked.
-- Utility racials (Arcane Torrent, War Stomp, ...) are intentionally left out.
OffBeat.RACIAL_COOLDOWNS = {
    { spellId = 26297,  name = "Berserking" },        -- Troll
    { spellId = 20572,  name = "Blood Fury" },        -- Orc (attack power)
    { spellId = 33702,  name = "Blood Fury" },        -- Orc (spell power)
    { spellId = 33697,  name = "Blood Fury" },        -- Orc (hybrid)
    { spellId = 274738, name = "Ancestral Call" },    -- Mag'har Orc
    { spellId = 265221, name = "Fireblood" },         -- Dark Iron Dwarf
    { spellId = 255647, name = "Light's Judgment" },  -- Lightforged Draenei
    { spellId = 312411, name = "Bag of Tricks" },     -- Vulpera
}

--- Racials from RACIAL_COOLDOWNS the current character knows.
function OffBeat:GetKnownRacials()
    local known = {}
    for _, r in ipairs(self.RACIAL_COOLDOWNS) do
        if IsPlayerSpell(r.spellId) then
            local info = C_Spell.GetSpellInfo(r.spellId)
            known[#known + 1] = {
                spellId = r.spellId,
                name = (info and info.name) or r.name, -- localized name when available
            }
        end
    end
    return known
end

-- Mistakes
--
-- Two rule types:
--   repeat_cast  same spell twice in a row
--   bad_cast     one of `spells` cast while every condition in `when` holds
--
-- Conditions (a single table, or a list of them that must all hold):
--   { aura = id, [minStacks = n], [maxStacks = n], [absent = true] }
--   { power = "SoulShards" | Enum.PowerType value, [min = n], [max = n] }
-- A value that can't be read (secret, missing) never matches, so unreadable
-- state can only hide a mistake, never invent one.

local function IsSecret(val)
    if val == nil or not _G.issecretvalue then return false end
    local ok, secret = pcall(_G.issecretvalue, val)
    return ok and secret
end

local function ReadNumber(val)
    if val == nil or IsSecret(val) then return nil end
    local ok, num = pcall(tonumber, val)
    if ok and num and not IsSecret(num) then return num end
    return nil
end

local function InRange(v, min, max)
    if min and v < min then return false end
    if max and v > max then return false end
    return true
end

local CONDITION_CHECKS = {
    aura = function(c)
        local auras = OffBeat:GetModule("Auras", true)
        if not auras then return false end
        local active = auras:IsActive(c.aura)
        if c.absent then return not active end
        if not active then return false end
        if c.minStacks or c.maxStacks then
            local rec = auras:GetAura(c.aura)
            local stacks = rec and ReadNumber(rec.stacks)
            if not stacks or stacks == 0 then return false end -- 0 = unreadable
            return InRange(stacks, c.minStacks, c.maxStacks)
        end
        return true
    end,
    power = function(c)
        local ok, v = pcall(UnitPower, "player", c.powerType)
        v = ok and ReadNumber(v)
        if not v then return false end
        return InRange(v, c.min, c.max)
    end,
}

local function ConditionKind(c)
    if c.aura then return "aura" end
    if c.power then return "power" end
end

local function NormalizeCondition(c)
    local kind = ConditionKind(c)
    if kind == "power" then
        local pt = c.power
        if type(pt) == "string" then pt = Enum and Enum.PowerType and Enum.PowerType[pt] end
        if type(pt) ~= "number" then return nil end
        return { kind = kind, powerType = pt, min = c.min, max = c.max }
    elseif kind == "aura" then
        return { kind = kind, aura = c.aura, minStacks = c.minStacks,
                 maxStacks = c.maxStacks, absent = c.absent }
    end
end

local function BuildBadCastRule(rule)
    local spells, conds = {}, {}
    for _, id in ipairs(rule.spells) do spells[id] = true end

    local when = rule.when
    if when and (when.aura or when.power) then when = { when } end
    for _, c in ipairs(when or {}) do
        local n = NormalizeCondition(c)
        if not n then return nil end -- unknown power type etc: drop the whole rule
        conds[#conds + 1] = n
    end
    if #conds == 0 then return nil end

    return {
        spells = spells,
        conds = conds,
        name = rule.name or "Mistake",
    }
end

local function MatchBadCast(spellId)
    for _, rule in ipairs(badCastRules) do
        if rule.spells[spellId] then
            local all = true
            for _, c in ipairs(rule.conds) do
                if not CONDITION_CHECKS[c.kind](c) then all = false; break end
            end
            if all then return rule.name end
        end
    end
    return nil
end

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
    self:RegisterEvent("UNIT_SPELLCAST_SENT")
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

local function GetSpecSettings()
    if not activeSpecId then return nil end
    return OffBeat.db.profile.specSettings[activeSpecId]
end

local function GetSpecOr(key)
    local ss = GetSpecSettings()
    if ss and ss[key] ~= nil then return ss[key] end
    return OffBeat.db.profile[key]
end

local function PlaySpecOrGlobalSound(specKey, globalKey)
    local ss = GetSpecSettings()
    local soundKey = ss and ss[specKey]
    if soundKey then OffBeat:PlaySoundKey(soundKey)
    else OffBeat:PlayConfigSound(globalKey) end
end

function Rotation:BuildLookups()
    wipe(rotationSpellSet)
    wipe(idleCooldownSet)
    wipe(badCastRules)
    wipe(pendingCasts)
    pendingCount = 0
    hasRepeatCastMistake = false
    keyCd = nil
    keyCdResolvedId = nil

    local profile = OffBeat.activeProfile
    if not profile then activeSpecId = nil; return end

    activeSpecId = profile.meta.specId
    local ss = GetSpecSettings()
    local disabledIdle = ss and ss.disabledIdleCooldowns

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
            elseif rule.type == "bad_cast" then
                local built = BuildBadCastRule(rule)
                if built then
                    badCastRules[#badCastRules + 1] = built
                else
                    OffBeat:Debug("Skipping mistake rule (bad conditions):", rule.name)
                end
            end
        end
    end

    if profile.idleCooldowns then
        for _, cd in ipairs(profile.idleCooldowns) do
            if not (disabledIdle and disabledIdle[cd.spellId]) then
                local resolved = ResolvePlayerSpell(cd.spellId, cd.name)
                idleCooldownSet[resolved] = { name = cd.name or tostring(cd.spellId) }
            end
        end
    end

    -- Racial cooldowns join the idle tracking for every spec (toggle per spec)
    if GetSpecOr("trackRacials") then
        for _, r in ipairs(OffBeat:GetKnownRacials()) do
            if not (disabledIdle and disabledIdle[r.spellId]) and not idleCooldownSet[r.spellId] then
                idleCooldownSet[r.spellId] = { name = r.name, racial = true }
            end
        end
    end

    keyCd = profile.keyCooldown
    if keyCd then
        keyCdResolvedId = ResolvePlayerSpell(keyCd.spellId, keyCd.name)
    end

end

-- Cast tracking

-- Judge bad_cast conditions when the button is pressed: by the time a cast
-- succeeds its cost is paid (Hand of Gul'dan at 3 shards reads as 0) and
-- procs it consumes are gone. Cancelled casts never reach SUCCEEDED, so the
-- verdict is only recorded if the cast goes through.
function Rotation:UNIT_SPELLCAST_SENT(_, unit, _, castGUID, spellId)
    if unit ~= "player" or #badCastRules == 0 then return end
    if not castGUID or IsSecret(castGUID) or IsSecret(spellId) then return end
    if not rotationSpellSet[spellId] then return end
    if pendingCount > 20 then wipe(pendingCasts); pendingCount = 0 end
    pendingCasts[castGUID] = MatchBadCast(spellId) or false
    pendingCount = pendingCount + 1
end

function Rotation:UNIT_SPELLCAST_SUCCEEDED(_, unit, castGUID, spellId)
    if unit ~= "player" then return end
    if rotationSpellSet[spellId] then
        self:RecordAbility(spellId, castGUID)
    end
end

function Rotation:RecordAbility(spellId, castGUID)
    local state = OffBeat.state
    local maxHistory = OffBeat.db.profile.historyCount

    local mistakeName = self:EvaluateMistakes(spellId, state, castGUID)

    if mistakeName then
        if GetSpecOr("soundEnabled") then
            PlaySpecOrGlobalSound("mistakeSound", "mistakeSound")
        end
        self:SendMessage("OFFBEAT_MISTAKE", spellId, mistakeName)
    end

    if keyCd and keyCd.wasteSpell and GetSpecOr("keyCdWasteAlert") then
        local wasteId = type(keyCd.wasteSpell) == "table" and keyCd.wasteSpell.spellId or keyCd.wasteSpell
        if spellId == wasteId then
            local auras = OffBeat:GetModule("Auras", true)
            local cdActive = (auras and auras:IsActive(keyCd.spellId))
                or (self.keyCdActiveUntil and GetTime() < self.keyCdActiveUntil)
            if cdActive then
                PlaySpecOrGlobalSound("keyCdWasteSound", "keyCdWasteSound")
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

function Rotation:EvaluateMistakes(spellId, state, castGUID)
    if hasRepeatCastMistake and spellId == state.lastSpellId then
        return repeatCastName
    end

    if #badCastRules > 0 then
        local pending
        if castGUID and not IsSecret(castGUID) then
            pending = pendingCasts[castGUID]
            if pending ~= nil then
                pendingCasts[castGUID] = nil
                pendingCount = pendingCount - 1
            end
        end
        if pending ~= nil then return pending or nil end
        return MatchBadCast(spellId) -- no SENT snapshot: judge on current state
    end

    return nil
end

-- Key cooldown tracking

function Rotation:SPELL_UPDATE_COOLDOWN()
    self:CheckKeyCdReady()
    if GetSpecOr("idleCooldownAlert") and UnitAffectingCombat("player") then
        self:CheckIdleCooldowns()
    end
end

function Rotation:CheckKeyCdReady()
    if not keyCd then return end
    local spellId = keyCdResolvedId or keyCd.spellId
    if not IsPlayerSpell(spellId) then return end

    local usable = C_Spell.IsSpellUsable(spellId)
    local ready = usable and not OffBeat:IsSpellOnRealCooldown(spellId)

    -- Spells like Avenging Wrath report isActive=false during the buff
    -- and briefly after it expires. The aura check catches the buff window;
    -- IsSpellUsable catches the gap between buff expiry and CD start.
    if ready then
        local auras = OffBeat:GetModule("Auras", true)
        if auras and (auras:IsActive(spellId) or auras:IsActive(keyCd.spellId)) then
            ready = false
        end
    end

    if ready and not self.keyCdReady then
        self.keyCdReady = true
        if GetSpecOr("keyCdAlert") and UnitAffectingCombat("player") then
            PlaySpecOrGlobalSound("keyCdSound", "keyCdSound")
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
    local threshold = GetSpecOr("idleCooldownThreshold")

    if not self.idleState then self.idleState = {} end

    for spellId, info in pairs(idleCooldownSet) do
        if IsPlayerSpell(spellId) then
            local usable = C_Spell.IsSpellUsable(spellId)
            local ready = usable and not OffBeat:IsSpellOnRealCooldown(spellId)

            if ready then
                local st = self.idleState[spellId]
                if not st then
                    self.idleState[spellId] = { readySince = now, warned = false }
                elseif not st.warned and (now - st.readySince) >= threshold then
                    st.warned = true
                    PlaySpecOrGlobalSound("idleCooldownSound", "idleCooldownSound")
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
                if (GetTime() - entry.time) > window then break end -- history is newest first
                for _, id in ipairs(pt.consumeSpells) do
                    if entry.spellId == id then consumed = true; break end
                end
                if consumed then break end
            end
            if not consumed then
                if GetSpecOr("procExpireAlert") then
                    PlaySpecOrGlobalSound("procExpireSound", "procExpireSound")
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

    local hasMistakeRules = hasRepeatCastMistake or #badCastRules > 0
    local hasProcs = stats.procsGained and stats.procsGained > 0

    if not hasMistakeRules and not hasProcs then return end

    local segments = {}

    if hasMistakeRules then
        local pct = stats.totalCasts > 0
            and (1 - stats.mistakes / stats.totalCasts) * 100
            or 100
        local color = pct == 100 and "|cff00ff00" or (pct >= 95 and "|cffffff00" or "|cffff4444")
        segments[#segments + 1] = string.format(
            "%s%.1f%%|r accuracy (%d/%d, %d mistake%s)",
            color, pct,
            stats.totalCasts - stats.mistakes, stats.totalCasts,
            stats.mistakes, stats.mistakes == 1 and "" or "s")
    end

    if hasProcs then
        local gained = stats.procsGained
        local expired = stats.procsExpired or 0
        local consumed = gained - expired
        local pct = (consumed / gained) * 100
        local color = pct == 100 and "|cff00ff00" or (pct >= 80 and "|cffffff00" or "|cffff4444")
        segments[#segments + 1] = string.format(
            "%s%.0f%%|r proc use (%d/%d, %d wasted)",
            color, pct, consumed, gained, expired)
    end

    OffBeat:Print(string.format("%s end — %s", label, table.concat(segments, ", ")))

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
