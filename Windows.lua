local OffBeat = _G.OffBeat
local Windows = OffBeat:NewModule("Windows", "AceEvent-3.0")

-- Training: cooldown window coaching and top-parse benchmarks. Only runs in
-- training mode (/ob training, see OffBeat:ToggleTraining).
--
-- A window is opened by casting `trigger` and lasts `duration` seconds:
--
--   windows = { {
--       name = "Tyrant", trigger = 265187, duration = 25,
--       content = "raid",   -- optional: only in raid ("dungeon": M+ / delves)
--       setup = { { name = "5 Soul Shards", when = { power = "SoulShards", min = 5 } } },
--       goals = { { name = "Hand of Gul'dan", spells = { 105174 }, min = 8 } },
--   } }
--
-- Setup checks are judged when the trigger is pressed (UNIT_SPELLCAST_SENT,
-- like mistake rules) with the shared Conditions; a check the game won't let
-- us read is "unknown", shown as ?, never as a miss. Goals count successful
-- casts inside the window. A window cut short by the end of combat (the boss
-- died) only counts if its goals were already reached; otherwise it's shown
-- as "ended early" and left out of the score.
--
-- Benchmarks are casts per minute from top parses, per boss encounter:
--
--   benchmarks = {
--       source = "...",
--       rates = { { name = "Rotation casts", all = true },
--                 { name = "Hand of Gul'dan", spells = { 105174 } } },
--       encounters = {                       -- encounter ID (ENCOUNTER_START)
--           [3492] = { name = "Ula'tek", window = 8,
--                      values = { { 40.5, 41.5, 42.7 }, { 12.7, 13.1, 13.6 } } },
--       },
--       overall = { name = "all heroic bosses", values = { ... } }, -- dummies etc.
--       dungeons = {                         -- instance ID (GetInstanceInfo)
--           [2993] = { name = "Altar of Fangs", window = 3, values = { ... } },
--       },
--       dungeonOverall = { name = "all M+ dungeons", values = { ... } },
--   }
--
-- `values` follow `rates` order as { low, median, high } (low/high = middle
-- half); `window` is the top players' median goal count per window on that
-- boss. A boss without data gets no comparison rather than another boss's.
-- `all = true` counts every rotationSpells cast. A Mythic+ run is compared
-- with its dungeon's numbers (casts per minute in combat); a dungeon without
-- data gets none. Other fights outside a boss (dummies) use `dungeonOverall`
-- when the content mode is Mythic+ (/ob mode), `overall` otherwise.
--
-- In a raid, only boss encounters count (setting, on by default), so training
-- can stay on all night; trash is ignored. Outside raids (dummies) every fight
-- counts. Each fight is folded into the session; turning training off shows
-- a report grouped by boss.

local READY   = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"
local MISS    = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t"
local UNKNOWN = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:0|t"
local FONT    = "Fonts\\FRIZQT__.TTF"

local defs = {}          -- built window definitions
local byTrigger = {}     -- trigger spellId -> def
local pendingSetup = {}  -- castGUID -> setup results, judged at SENT
local active             -- the open window, or nil
local rotationSet = {}   -- profile.rotationSpells as a set
local encounter          -- { id, name } while a boss encounter is running
local fight              -- the current fight, see NewFight
local session            -- { fights = { folded fights } }, reported when training ends
local run                -- the Mythic+ run in progress: one fight that every pull folds into

local function GetSpecSettings()
    local profile = OffBeat.activeProfile
    if not profile then return nil end
    local ss = OffBeat.db.profile.specSettings
    ss[profile.meta.specId] = ss[profile.meta.specId] or {}
    return ss[profile.meta.specId]
end

local function SpecOr(key)
    local ss = GetSpecSettings()
    if ss and ss[key] ~= nil then return ss[key] end
    return OffBeat.db.profile[key]
end

local function Mark(ok)
    if ok == true then return READY elseif ok == false then return MISS end
    return UNKNOWN
end

--- Goal target: the per-spec override from the Training page, else the profile's.
function Windows:GetGoalMin(def, goal)
    local ss = GetSpecSettings()
    local key = def.name .. ":" .. goal.name
    return (ss and ss.windowGoals and ss.windowGoals[key]) or goal.min
end

function Windows:SetGoalMin(def, goal, value)
    local ss = GetSpecSettings()
    if not ss then return end
    ss.windowGoals = ss.windowGoals or {}
    ss.windowGoals[def.name .. ":" .. goal.name] = (value ~= goal.min) and value or nil
end

function Windows:OnEnable()
    self:BuildLookups()
    self:RegisterEvent("UNIT_SPELLCAST_SENT")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("ENCOUNTER_START")
    self:RegisterEvent("ENCOUNTER_END")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("CHALLENGE_MODE_RESET")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "ApplyLock")
    self:RegisterMessage("OFFBEAT_TRAINING_CHANGED", "OnTrainingChanged")
    self:RegisterMessage("OFFBEAT_PET_LOST", "OnPetLost")
    self:RegisterMessage("OFFBEAT_PET_BACK", "OnPetBack")
    self:RegisterMessage("OFFBEAT_MISTAKE", "OnMistake")
    self:RegisterMessage("OFFBEAT_FAIL_STRETCH", "OnMistake") -- counted like a mistake, no red flash
    self:ApplyLock()
end

function Windows:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if active and active.timer then active.timer:Cancel() end
    active, fight, encounter, run = nil, nil, nil, nil
    wipe(pendingSetup)
    if self.frame then self.frame:Hide() end
end

function Windows:BuildLookups()
    wipe(defs)
    wipe(byTrigger)
    wipe(rotationSet)
    local profile = OffBeat.activeProfile
    if not profile then return end
    for _, s in ipairs(profile.rotationSpells or {}) do rotationSet[s.spellId] = true end
    if not profile.windows then return end

    for _, w in ipairs(profile.windows) do
        local def = { name = w.name, trigger = w.trigger, duration = w.duration,
                      content = w.content, setup = {}, goals = {} }
        for _, s in ipairs(w.setup or {}) do
            local conds = OffBeat.Conditions.Normalize(s.when)
            if conds then def.setup[#def.setup + 1] = { name = s.name, conds = conds } end
        end
        for _, g in ipairs(w.goals or {}) do
            local set = {}
            for _, id in ipairs(g.spells) do set[id] = true end
            def.goals[#def.goals + 1] = { name = g.name, spells = set, min = g.min }
        end
        defs[#defs + 1] = def
        -- several windows can share a trigger, one per content (Holy
        -- Paladin's wings: raid and M+ builds press different spells)
        byTrigger[w.trigger] = byTrigger[w.trigger] or {}
        table.insert(byTrigger[w.trigger], def)
    end
end

--- The window `spellId` opens in the content you're in (/ob mode), if any.
local function DefFor(spellId)
    local list = byTrigger[spellId]
    if not list then return nil end
    for _, def in ipairs(list) do
        if OffBeat:InContent(def.content) then return def end
    end
end

-- true / false / nil (unknown) per setup check
local function JudgeSetup(def)
    local results = {}
    for i, s in ipairs(def.setup) do
        results[i] = OffBeat.Conditions.Status(s.conds)
    end
    return results
end

-- Fights

local function InRaid()
    local ok, inInstance, kind = pcall(IsInInstance)
    return ok and inInstance and kind == "raid"
end

local function PetWanted()
    local pet = OffBeat:GetModule("Pet", true)
    return pet and pet:IsEnabled() and pet:Wanted() or false
end

local function NewFight()
    return { start = GetTime(), inRaid = InRaid(), casts = {}, rotation = 0, results = {}, petWanted = PetWanted(),
             encounterId = encounter and encounter.id, encounterName = encounter and encounter.name,
             content = OffBeat:ContentMode() }
end

-- Does this fight count? In a raid with "boss encounters only", only fights
-- that are (or became) a boss encounter count.
local function Counts(f)
    if not f then return false end
    if f.inRaid and OffBeat.db.profile.trainingBossOnly and not f.encounterId then return false end
    return true
end

-- Pet (Pet.lua): deaths and time without a pet, per fight

local function ClosePetClock(f)
    if f and f.petDownAt then
        f.petDown = (f.petDown or 0) + (GetTime() - f.petDownAt)
        f.petDownAt = nil
    end
end

function Windows:OnPetLost(_, reason)
    if not fight then return end
    if reason == "died" then fight.petDeaths = (fight.petDeaths or 0) + 1 end
    fight.petDownAt = fight.petDownAt or GetTime()
end

-- Mistake rules (profile.mistakes) that fired, counted per fight by name.
function Windows:OnMistake(_, _, name)
    if not fight or not name then return end
    fight.mistakes = fight.mistakes or {}
    fight.mistakes[name] = (fight.mistakes[name] or 0) + 1
end

local function MistakeLine(counts)
    local list = {}
    for name, n in pairs(counts or {}) do list[#list + 1] = { name, n } end
    if #list == 0 then return nil end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    for i, m in ipairs(list) do list[i] = string.format("%s %d", m[1], m[2]) end
    return table.concat(list, ", ")
end

function Windows:OnPetBack()
    ClosePetClock(fight)
end

local function PetLine(deaths, down)
    deaths, down = deaths or 0, math.floor((down or 0) + 0.5)
    if deaths == 0 and down < 1 then return nil end
    local parts = {}
    if deaths > 0 then parts[#parts + 1] = string.format("died %d time%s", deaths, deaths == 1 and "" or "s") end
    if down >= 1 then parts[#parts + 1] = string.format("%ds without a pet", down) end
    return table.concat(parts, ", ")
end

-- Mythic+ runs
--
-- A keystone run counts as one fight: every pull (trash and bosses) folds
-- into it, its length is time in combat, and it ends timed, over time or
-- abandoned. Profiles with `benchmarks.dungeons` compare it with the top
-- runs of that dungeon, per minute in combat.

local function KeyActive()
    if not (C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive) then return false end
    local ok, on = pcall(C_ChallengeMode.IsChallengeModeActive)
    return ok and on and true or false
end

local function KeyName()
    local name, level
    local ok, mapId = pcall(C_ChallengeMode.GetActiveChallengeMapID)
    if ok and mapId then
        local ok2, n = pcall(C_ChallengeMode.GetMapUIInfo, mapId)
        if ok2 then name = n end
    end
    local ok3, lvl = pcall(C_ChallengeMode.GetActiveKeystoneInfo)
    if ok3 then level = lvl end
    name = name or "Mythic+"
    return (level and level > 0) and string.format("%s +%d", name, level) or name
end

local function InstanceId()
    local ok, _, _, _, _, _, _, _, id = pcall(GetInstanceInfo)
    return ok and id or nil
end

local function StartRun()
    run = { start = GetTime(), inRaid = false, casts = {}, rotation = 0, results = {}, petWanted = PetWanted(),
            run = true, encounterName = KeyName(), instanceId = InstanceId(), minutes = 0 }
end

-- Add the current stretch of combat to the run's length.
local function StopRunClock()
    if run and run.combatStart then
        run.minutes = run.minutes + (GetTime() - run.combatStart) / 60
        run.combatStart = nil
    end
end

function Windows:FinishRun(outcome)
    if not run then return end
    if active then self:Close() end
    StopRunClock()
    run.outcome = outcome
    local r = run
    run = nil
    if fight == r then fight = nil end
    self:PrintSummary(r)
    self:PrintBenchmarks(r)
    self:FoldFight(r)
end

function Windows:CHALLENGE_MODE_COMPLETED()
    if not run then return end
    local onTime
    if C_ChallengeMode.GetChallengeCompletionInfo then
        local ok, info = pcall(C_ChallengeMode.GetChallengeCompletionInfo)
        if ok and type(info) == "table" then onTime = info.onTime end
    end
    self:FinishRun(onTime == true and "timed" or (onTime == false and "over time" or "completed"))
end

function Windows:CHALLENGE_MODE_RESET()
    self:FinishRun("abandoned")
end

-- Left the dungeon (or reloaded outside it) with the run still open.
function Windows:PLAYER_ENTERING_WORLD()
    if run and not KeyActive() then self:FinishRun("abandoned") end
end

function Windows:ENCOUNTER_START(_, encounterId, encounterName)
    encounter = { id = encounterId, name = encounterName }
    if fight and not fight.encounterId and not fight.run then
        fight.encounterId, fight.encounterName = encounterId, encounterName
    end
end

function Windows:ENCOUNTER_END(_, _, _, _, _, success)
    encounter = nil
    if fight and fight.encounterId then fight.kill = success == 1 end
end

local function StartFight()
    if KeyActive() then
        if not run then StartRun() end
        run.combatStart = GetTime()
        return run
    end
    return NewFight()
end

function Windows:PLAYER_REGEN_DISABLED()
    if OffBeat.training then fight = StartFight() end
end

function Windows:PLAYER_REGEN_ENABLED()
    if active then self:Close() end
    ClosePetClock(fight)
    if fight and fight.run then -- a pull of a key: the run goes on
        StopRunClock()
        fight = nil
        wipe(pendingSetup)
        return
    end
    if fight and Counts(fight) then
        self:PrintSummary(fight)
        self:PrintBenchmarks(fight)
        self:FoldFight()
    end
    fight = nil
    wipe(pendingSetup)
end

-- Events

function Windows:OnTrainingChanged(_, on, resumed)
    if on then
        session = resumed or { fights = {} }
        local open = session.openRun -- a run parked across a /reload
        session.openRun = nil
        if open then
            if KeyActive() then run = open else self:FoldFight(open) end
        end
        if UnitAffectingCombat("player") then fight = StartFight() end -- count from now
        return
    end
    if run then self:FinishRun("training turned off") end
    -- An open window is dropped (it never ran its full duration); the
    -- unfinished fight still counts toward the report.
    if active and active.timer then active.timer:Cancel() end
    active = nil
    if fight and Counts(fight) then self:FoldFight() end
    fight = nil
    self:FinishSession()
    wipe(pendingSetup)
    if self.frame and OffBeat.db.profile.locked then self.frame:Hide() end
end

function Windows:UNIT_SPELLCAST_SENT(_, unit, _, castGUID, spellId)
    if unit ~= "player" or not OffBeat.training then return end
    local IsSecret = OffBeat.Conditions.IsSecret
    if not castGUID or IsSecret(castGUID) or IsSecret(spellId) then return end
    local def = DefFor(spellId)
    if not def then return end
    pendingSetup[castGUID] = JudgeSetup(def)
end

function Windows:UNIT_SPELLCAST_SUCCEEDED(_, unit, castGUID, spellId)
    if unit ~= "player" or not OffBeat.training then return end
    if OffBeat.Conditions.IsSecret(spellId) then return end
    if fight then
        fight.casts[spellId] = (fight.casts[spellId] or 0) + 1
        if rotationSet[spellId] then fight.rotation = fight.rotation + 1 end
    end

    local def = DefFor(spellId)
    if def then
        local setup
        if castGUID and not OffBeat.Conditions.IsSecret(castGUID) then
            setup = pendingSetup[castGUID]
            pendingSetup[castGUID] = nil
        end
        -- raid trash with "boss encounters only": no window
        if fight == nil or Counts(fight) then
            self:Open(def, setup or JudgeSetup(def)) -- no SENT snapshot: judge now
        end
        return
    end

    if active then
        for i, g in ipairs(active.def.goals) do
            if g.spells[spellId] then active.counts[i] = active.counts[i] + 1 end
        end
        self:RefreshFrame()
    end
end

-- Benchmarks

--- The benchmark for a fight: its boss's numbers, its dungeon's for a
--- Mythic+ run, or the all-boss numbers for fights that aren't a boss
--- encounter (dummies). nil when the boss or dungeon has no data.
function Windows:BenchmarkFor(f)
    local bm = OffBeat.activeProfile and OffBeat.activeProfile.benchmarks
    if not bm then return nil end
    if f.run then return bm.dungeons and f.instanceId and bm.dungeons[f.instanceId] end
    if f.encounterId then return bm.encounters and bm.encounters[f.encounterId] end
    if f.content == "dungeon" and bm.dungeonOverall then return bm.dungeonOverall end
    return bm.overall
end

function Windows:BenchmarkRows(bench, minutes, casts, rotation)
    local bm = OffBeat.activeProfile and OffBeat.activeProfile.benchmarks
    if not bm or not bench then return nil end
    local rows = {}
    for i, r in ipairs(bm.rates) do
        local v = bench.values[i]
        if v then
            local count = 0
            if r.all then
                count = rotation
            else
                for _, id in ipairs(r.spells) do count = count + (casts[id] or 0) end
            end
            local rate = count / minutes
            rows[#rows + 1] = { name = r.name, rate = rate, low = v[1], median = v[2], high = v[3], ok = rate >= v[1] }
        end
    end
    return rows
end

-- Per-minute rates for this fight against its boss's top-parse numbers.
-- Skipped for short fights, where a single cast swings the rate.
function Windows:PrintBenchmarks(f)
    local bm = OffBeat.activeProfile and OffBeat.activeProfile.benchmarks
    if not bm then return end
    local minutes = f.run and f.minutes or (GetTime() - f.start) / 60 -- a run: time in combat
    if minutes < 1 then return end
    if f.run and not bm.dungeons then return end
    local bench = self:BenchmarkFor(f)
    if not bench then
        OffBeat:Print(string.format("No top-parse numbers for %s yet.", f.encounterName or "this fight"))
        return
    end
    OffBeat:Print(string.format("Vs top parses (%s), per minute:", bench.name))
    for _, row in ipairs(self:BenchmarkRows(bench, minutes, f.casts, f.rotation)) do
        OffBeat:Print(string.format("  %s %s %.1f  (top %.1f-%.1f, median %.1f)",
            Mark(row.ok), row.name, row.rate, row.low, row.high, row.median))
    end
end

-- Training session

function Windows:FoldFight(f)
    f = f or fight
    if not session or not f then return end
    ClosePetClock(f)
    if not f.run then f.minutes = (GetTime() - f.start) / 60 end -- a run's is time in combat
    session.fights[#session.fights + 1] = f
end

-- The session for saving across a /reload, with any counting fight folded
-- in. An open Mythic+ run is parked and picked up again after the reload.
function Windows:ExportSession()
    if run then
        StopRunClock()
        ClosePetClock(run)
        if session then session.openRun = run end
        if fight == run then fight = nil end
        run = nil
    end
    if fight and Counts(fight) then self:FoldFight() end
    fight = nil
    return session
end

-- One report page from a set of fights (a whole boss, or a single pull).
function Windows:BuildPage(name, encounterId, fights, subtitle, isRun)
    local minutes, casts, rotation, results = 0, {}, 0, {}
    local petDeaths, petDown, petWanted = 0, 0, false
    local mistakes = {}
    for _, f in ipairs(fights) do
        for name, n in pairs(f.mistakes or {}) do mistakes[name] = (mistakes[name] or 0) + n end
        petWanted = petWanted or f.petWanted
        minutes = minutes + f.minutes
        petDeaths, petDown = petDeaths + (f.petDeaths or 0), petDown + (f.petDown or 0)
        for id, n in pairs(f.casts) do casts[id] = (casts[id] or 0) + n end
        rotation = rotation + f.rotation
        for _, res in ipairs(f.results) do results[#results + 1] = res end
    end
    local profile = OffBeat.activeProfile
    local bench = self:BenchmarkFor({ encounterId = encounterId, run = isRun,
        instanceId = fights[1] and fights[1].instanceId, content = fights[1] and fights[1].content })
    return {
        name = name, subtitle = subtitle, minutes = minutes,
        pet = petWanted and { deaths = petDeaths, down = petDown } or nil,
        mistakes = (profile and profile.mistakes) and mistakes or nil,
        windows = self:Aggregate(results),
        detail = results, -- each window's goals/setup, drawn as bars
        benchName = bench and bench.name, topWindow = bench and bench.window,
        hasBenchmarks = profile and profile.benchmarks ~= nil and (not isRun or profile.benchmarks.dungeons ~= nil),
        rates = (bench and minutes >= 1) and self:BenchmarkRows(bench, minutes, casts, rotation) or nil,
    }
end

local function fmtTime(minutes)
    return string.format("%dm %02ds", math.floor(minutes), math.floor((minutes % 1) * 60))
end

-- A session's report: one page per pull, in boss order. nil when nothing
-- counted.
function Windows:BuildReport(s)
    local total, groups, byKey = 0, {}, {}
    for _, f in ipairs(s and s.fights or {}) do
        -- a blip of combat (under 15s) with no window isn't a pull
        if f.minutes >= 0.25 or #f.results > 0 then
            total = total + f.minutes
            -- each key run is its own entry; other fights split by content mode
            local key = f.run and f or (f.encounterId or ("other:" .. (f.content or "")))
            local g = byKey[key]
            if not g then
                g = { name = f.encounterName or (f.content == "dungeon" and "Training dummy / outside keys (Mythic+)"
                          or "Training dummy / outside raids"), encounterId = f.encounterId,
                      isRun = f.run, fights = {} }
                byKey[key] = g
                groups[#groups + 1] = g
            end
            g.fights[#g.fights + 1] = f
        end
    end
    if #groups == 0 then return nil end

    local profile = OffBeat.activeProfile
    local report = { spec = profile and profile.meta.name or "", minutes = total, fights = 0, pages = {} }
    for _, g in ipairs(groups) do
        local n = #g.fights
        report.fights = report.fights + n
        local word = g.isRun and "run" or (g.encounterId and "pull" or "fight")
        for i, f in ipairs(g.fights) do
            local outcome = f.outcome or (f.kill == true and "kill" or (f.kill == false and "wipe" or nil))
            local parts = {}
            if n > 1 then parts[#parts + 1] = string.format("%s %d of %d", word, i, n) end
            if outcome then parts[#parts + 1] = outcome end
            parts[#parts + 1] = fmtTime(f.minutes)
            if g.isRun then parts[#parts] = fmtTime(f.minutes) .. " in combat" end
            local page = self:BuildPage(g.name, g.encounterId, { f }, table.concat(parts, "  ·  "), g.isRun)
            page.menuText = g.isRun
                and string.format("%s%s  ·  %s", g.name, outcome and ("  ·  " .. outcome) or "", fmtTime(f.minutes))
                or string.format("%s  ·  %s %d%s  ·  %s", g.name, word, i,
                    outcome and ("  ·  " .. outcome) or "", fmtTime(f.minutes))
            report.pages[#report.pages + 1] = page
        end
    end
    return report
end

-- Training turned off: save and show the session's report.
function Windows:FinishSession()
    local report = self:BuildReport(session)
    session = nil
    if not report then
        OffBeat:Print("Training ended. No fights were recorded, so there is no report.")
        return
    end
    OffBeat.db.profile.lastTrainingReport = report
    self:ShowReport(report)
end

-- Window lifecycle

function Windows:Open(def, setup)
    if active then self:Close() end -- a re-trigger closes the previous window
    local counts = {}
    for i = 1, #def.goals do counts[i] = 0 end
    active = { def = def, setup = setup, counts = counts, endsAt = GetTime() + def.duration }
    active.timer = C_Timer.NewTimer(def.duration, function() Windows:Close() end)
    self:SendMessage("OFFBEAT_WINDOW_OPENED", def.name)
    self:RefreshFrame()
end

function Windows:Close()
    local w = active
    if not w then return end
    active = nil
    if w.timer then w.timer:Cancel() end
    local cutShort = GetTime() < w.endsAt - 0.5

    local result = { name = w.def.name, setup = {}, goals = {}, met = true }
    for i, s in ipairs(w.def.setup) do
        local ok = w.setup[i] -- true / false / nil (unknown)
        result.setup[i] = { name = s.name, ok = ok }
        if ok == false then result.met = false end
    end
    for i, g in ipairs(w.def.goals) do
        local min = self:GetGoalMin(w.def, g)
        local ok = w.counts[i] >= min
        result.goals[i] = { name = g.name, count = w.counts[i], min = min, ok = ok }
        if not ok then result.met = false end
    end
    -- Cut short and not yet on target: you never had the full window.
    if cutShort and not result.met then result.early = true end
    if fight then fight.results[#fight.results + 1] = result end

    if result.early then
        if SpecOr("windowChat") then
            local g = result.goals[1]
            OffBeat:Print(string.format("%s window ended early (combat ended)%s: not scored.", result.name,
                g and string.format(", %s %d", g.name, g.count) or ""))
        end
        self:SendMessage("OFFBEAT_WINDOW_CLOSED", result)
        if self.frame and OffBeat.db.profile.locked then self.frame:Hide() end
        return
    end

    if SpecOr("windowChat") then
        local parts = {}
        for _, g in ipairs(result.goals) do
            parts[#parts + 1] = string.format("%s %s %d/%d", Mark(g.ok), g.name, g.count, g.min)
        end
        for _, s in ipairs(result.setup) do
            parts[#parts + 1] = string.format("%s %s%s", Mark(s.ok), s.name, s.ok == nil and " (couldn't read)" or "")
        end
        OffBeat:Print(string.format("%s window: %s", result.name, table.concat(parts, "  ")))
    end

    self:SendMessage("OFFBEAT_WINDOW_CLOSED", result)
    self:ShowResult(result)
end

-- Window results grouped by window name: count, on-target, per-goal
-- totals/best, per-setup ok / unknown counts. List in first-seen order.
function Windows:Aggregate(results)
    local byName, order = {}, {}
    for _, r in ipairs(results) do
        local s = byName[r.name]
        if not s then
            s = { name = r.name, n = 0, met = 0, early = 0, goals = {}, setupOk = {} }
            byName[r.name] = s
            order[#order + 1] = s
        end
        if r.early then
            s.early = s.early + 1
        else
            s.n = s.n + 1
            if r.met then s.met = s.met + 1 end
            for i, g in ipairs(r.goals) do
                local t = s.goals[i] or { name = g.name, total = 0, best = 0, min = g.min }
                t.total = t.total + g.count
                if g.count > t.best then t.best = g.count end
                s.goals[i] = t
            end
            for i, st in ipairs(r.setup) do
                local t = s.setupOk[i] or { name = st.name, ok = 0, unknown = 0 }
                if st.ok == true then t.ok = t.ok + 1 elseif st.ok == nil then t.unknown = t.unknown + 1 end
                s.setupOk[i] = t
            end
        end
    end
    return order
end

local function SetupLine(t, n)
    local known = n - t.unknown
    local mark = (known > 0 and t.ok == known) and READY or (known == 0 and UNKNOWN or MISS)
    local s = string.format("%s %s on %d of %d windows", mark, t.name, t.ok, n)
    if t.unknown > 0 then s = s .. string.format(" (%d couldn't be read)", t.unknown) end
    return s
end

function Windows:PrintSummary(f)
    if not OffBeat.db.profile.combatReport then return end
    local pet = PetLine(f.petDeaths, f.petDown)
    if pet then OffBeat:Print("|cffff8800Pet: " .. pet .. "|r") end
    local mistakes = MistakeLine(f.mistakes)
    if mistakes then OffBeat:Print("|cffff8800Mistakes: " .. mistakes .. "|r") end
    if #f.results == 0 then return end
    for _, s in ipairs(self:Aggregate(f.results)) do
        if s.n > 0 then
            local parts = { string.format("%d/%d on target", s.met, s.n) }
            for _, g in ipairs(s.goals) do
                parts[#parts + 1] = string.format("%s avg %.1f (goal %d, best %d)", g.name, g.total / s.n, g.min, g.best)
            end
            for _, t in ipairs(s.setupOk) do
                parts[#parts + 1] = string.format("%s %d/%d%s", t.name, t.ok, s.n,
                    t.unknown > 0 and string.format(" (%d unread)", t.unknown) or "")
            end
            if s.early > 0 then parts[#parts + 1] = string.format("%d ended early", s.early) end
            OffBeat:Print(string.format("%s windows: %s", s.name, table.concat(parts, ", ")))
        elseif s.early > 0 then
            OffBeat:Print(string.format("%s windows: %d ended early (combat ended), not scored", s.name, s.early))
        end
    end
end

-- Training report window
--
-- Drawn like the post-fight buff timeline (BuffTimeline.lua): a dark panel,
-- a label column on the left and horizontal bars on the right. One section
-- per boss.

local R_PAD, R_LABEL, R_ROW, R_WIDTH = 12, 165, 15, 580
local NAV_NORMAL = { 0.85, 0.85, 0.85 }
local NAV_HOVER  = { 1.00, 0.82, 0.30 }
local C_GOOD = { 0.30, 0.85, 0.45 }
local C_BAD  = { 0.90, 0.35, 0.30 }
local C_BAND = { 0.35, 0.70, 1.00 }
local C_BOSS = { 1.00, 0.82, 0.30 }

function Windows:GetReportFrame()
    if self.reportFrame then return self.reportFrame end
    local f = CreateFrame("Frame", "OffBeatTrainingReport", UIParent, "BackdropTemplate")
    f:SetBackdrop(OffBeat:BuildBackdrop())
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    f:SetSize(R_WIDTH, 200)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true) -- a popup you open yourself: always takes clicks and drags
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        OffBeat.db.profile.trainingReportPosition = { point = point, relPoint = relPoint, x = x, y = y }
    end)
    tinsert(UISpecialFrames, "OffBeatTrainingReport") -- Escape closes it

    local pos = OffBeat.db.profile.trainingReportPosition
    if pos then f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else f:SetPoint("CENTER", UIParent, "CENTER", 0, 60) end

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(OffBeat:GetFont(2))
    title:SetPoint("TOPLEFT", R_PAD, -R_PAD)
    title:SetTextColor(0.6, 0.8, 1.0)
    f.title = title

    local close = CreateFrame("Button", nil, f)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", -R_PAD, -R_PAD + 2)
    local x = close:CreateFontString(nil, "OVERLAY")
    x:SetFont(OffBeat:GetFont(1))
    x:SetPoint("CENTER")
    x:SetText("X")
    x:SetTextColor(unpack(NAV_NORMAL))
    close.label = x
    close:SetScript("OnClick", function() f:Hide() end)
    close:SetScript("OnEnter", function() x:SetTextColor(unpack(NAV_HOVER)) end)
    close:SetScript("OnLeave", function() x:SetTextColor(unpack(NAV_NORMAL)) end)
    f.closeButton = close

    -- < page / pages >: one page per boss, then one per pull
    local function navButton(label, anchorTo, dx, onClick)
        local b = CreateFrame("Button", nil, f)
        b:SetSize(18, 18)
        b:SetPoint("RIGHT", anchorTo, "LEFT", dx, 0)
        local t = b:CreateFontString(nil, "OVERLAY")
        t:SetFont(OffBeat:GetFont(1))
        t:SetPoint("CENTER")
        t:SetText(label)
        t:SetTextColor(unpack(NAV_NORMAL))
        b.label = t
        b:SetScript("OnClick", onClick)
        b:SetScript("OnEnter", function() t:SetTextColor(unpack(NAV_HOVER)) end)
        b:SetScript("OnLeave", function() t:SetTextColor(unpack(NAV_NORMAL)) end)
        return b
    end
    f.nextButton = navButton(">", close, -10, function() Windows:ShowReport(f.report, f.page + 1) end)
    -- "3 / 9 v": click for a list of every pull to jump to
    local pick = CreateFrame("Button", nil, f)
    pick:SetSize(60, 18)
    pick:SetPoint("RIGHT", f.nextButton, "LEFT", -2, 0)
    local pageText = pick:CreateFontString(nil, "OVERLAY")
    pageText:SetFont(OffBeat:GetFont(0))
    pageText:SetPoint("CENTER")
    pageText:SetTextColor(unpack(NAV_NORMAL))
    pick:SetScript("OnEnter", function() pageText:SetTextColor(unpack(NAV_HOVER)) end)
    pick:SetScript("OnLeave", function() pageText:SetTextColor(unpack(NAV_NORMAL)) end)
    pick:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(_, root)
            for i, pg in ipairs(f.report.pages) do
                root:CreateRadio(pg.menuText, function() return f.page == i end,
                    function() Windows:ShowReport(f.report, i) end)
            end
        end)
    end)
    f.pageText, f.pagePicker = pageText, pick
    f.prevButton = navButton("<", pick, -2, function() Windows:ShowReport(f.report, f.page - 1) end)

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", R_PAD, -(R_PAD + 34))
    f.content:SetPoint("BOTTOMRIGHT", -R_PAD, R_PAD)
    f.texts, f.textures = {}, {}
    f:Hide()
    self.reportFrame = f
    return f
end

function Windows:ShowReport(report, page)
    local f = self:GetReportFrame()
    local c = f.content
    local nPages = #report.pages
    page = math.max(1, math.min(page or 1, nPages))
    f.report, f.page = report, page
    for _, t in ipairs(f.texts) do t:Hide() end
    for _, t in ipairs(f.textures) do t:Hide() end
    local nText, nTex, y = 0, 0, 0
    local barW = R_WIDTH - R_PAD * 2 - R_LABEL - 70 -- room for the value column

    local contentW = R_WIDTH - R_PAD * 2
    -- width: nil = to the right edge. wrap: long text breaks onto more lines
    -- (use the returned font string's height to move down).
    local function text(str, x, yy, color, offset, width, justify, wrap)
        nText = nText + 1
        local fs = f.texts[nText]
        if not fs then fs = c:CreateFontString(nil, "OVERLAY"); f.texts[nText] = fs end
        fs:SetFont(OffBeat:GetFont(offset or 0))
        fs:SetTextColor(unpack(color or { 0.85, 0.85, 0.85 }))
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", c, "TOPLEFT", x, yy)
        fs:SetWidth((width and width > 0) and width or (contentW - x))
        fs:SetJustifyH(justify or "LEFT")
        fs:SetWordWrap(wrap and true or false)
        fs:SetText(str)
        fs:Show()
        return fs
    end
    local function rect(x, yy, w, h, r, g, b, a)
        nTex = nTex + 1
        local t = f.textures[nTex]
        if not t then t = c:CreateTexture(nil, "ARTWORK"); f.textures[nTex] = t end
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", c, "TOPLEFT", x, yy)
        t:SetSize(math.max(1, w), h)
        t:SetColorTexture(r, g, b, a or 1)
        t:Show()
        return t
    end
    local function header(str)
        local fs = text(str, 0, y, { 0.55, 0.55, 0.55 }, -1, nil, nil, true)
        y = y - math.max(16, math.ceil(fs:GetStringHeight()) + 4)
    end
    -- a line that wraps when long, moving y down by its height
    local function line(str, color)
        local fs = text(str, 0, y, color, -1, nil, nil, true)
        y = y - math.max(14, math.ceil(fs:GetStringHeight()) + 4)
    end

    f.title:SetFont(OffBeat:GetFont(2))
    f.closeButton.label:SetFont(OffBeat:GetFont(1))
    -- (the pull picker on the right has the session's pulls; keep this short)
    f.title:SetText(report.soFar and "OffBeat — Training so far" or "OffBeat — Training report")
    for _, b in ipairs({ f.prevButton, f.nextButton }) do
        b.label:SetFont(OffBeat:GetFont(1))
        b:SetShown(nPages > 1)
    end
    f.prevButton:SetEnabled(page > 1)
    f.prevButton.label:SetAlpha(page > 1 and 1 or 0.3)
    f.nextButton:SetEnabled(page < nPages)
    f.nextButton.label:SetAlpha(page < nPages and 1 or 0.3)
    f.pageText:SetFont(OffBeat:GetFont(0))
    f.pageText:SetText(string.format("%d / %d  v", page, nPages))
    f.pagePicker:SetShown(nPages > 1)

    do
        local grp = report.pages[page]
        text(string.format("%s  ·  %s", grp.name, grp.subtitle), 0, y, C_BOSS, 1)
        y = y - 20
        if grp.pet then
            local petLine = PetLine(grp.pet.deaths, grp.pet.down)
            line(petLine and ("PET  ·  " .. petLine) or "PET  ·  alive the whole time", petLine and C_BAD or C_GOOD)
        end
        if grp.mistakes then
            local mLine = MistakeLine(grp.mistakes)
            line(mLine and ("MISTAKES  ·  " .. mLine) or "MISTAKES  ·  none", mLine and C_BAD or C_GOOD)
        end

        -- Cooldown windows: one bar per window, tick = goal
        for _, agg in ipairs(grp.windows or {}) do
            local g1 = agg.goals[1]
            local scale = math.max(g1 and g1.min or 1, g1 and g1.best or 1, grp.topWindow or 0) * 1.25
            if agg.n == 0 then
                header(string.format("%s WINDOWS  ·  %d ended early, not scored", string.upper(agg.name), agg.early))
            else
            header(string.format("%s WINDOWS  ·  %d of %d on target  ·  %s avg %.1f, best %d, goal %d%s%s",
                string.upper(agg.name), agg.met, agg.n, g1 and g1.name or "",
                (g1 and agg.n > 0) and g1.total / agg.n or 0, g1 and g1.best or 0, g1 and g1.min or 0,
                grp.topWindow and string.format(", top median %d", grp.topWindow) or "",
                agg.early > 0 and string.format("  ·  %d ended early", agg.early) or ""))
            end
            local idx = 0
            for _, r in ipairs(grp.detail or {}) do
                if r.name == agg.name and r.goals[1] then
                    idx = idx + 1
                    local g = r.goals[1]
                    local setup = true
                    for _, st in ipairs(r.setup) do
                        if st.ok == false then setup = false elseif st.ok == nil and setup then setup = nil end
                    end
                    text(string.format("%s %d", agg.name, idx), 0, y, nil, 0, R_LABEL - 20)
                    if setup ~= true then text(Mark(setup), R_LABEL - 18, y) end
                    rect(R_LABEL, y - 1, barW, R_ROW - 2, 0.15, 0.15, 0.15, 0.8)
                    local col = r.early and { 0.5, 0.5, 0.5 } or (g.ok and C_GOOD or C_BAD)
                    rect(R_LABEL, y - 1, barW * math.min(1, g.count / scale), R_ROW - 2, col[1], col[2], col[3], 0.85)
                    rect(R_LABEL + barW * math.min(1, g.min / scale), y - 1, 2, R_ROW - 2, 1, 1, 1, 0.9)
                    if grp.topWindow then
                        rect(R_LABEL + barW * math.min(1, grp.topWindow / scale), y - 1, 2, R_ROW - 2,
                            C_BAND[1], C_BAND[2], C_BAND[3], 1)
                    end
                    text(r.early and string.format("%d  early", g.count) or string.format("%d / %d", g.count, g.min),
                        R_LABEL + barW + 6, y, col, 0, 60)
                    y = y - R_ROW - 2
                end
            end
            for _, st in ipairs(agg.setupOk) do
                if agg.n > 0 then
                    line(SetupLine(st, agg.n), { 0.7, 0.7, 0.7 })
                end
            end
            y = y - 8
        end

        -- Casts per minute: your rate over this boss's top players' middle half
        if grp.rates then
            header("CASTS PER MINUTE  ·  YOU VS TOP PARSES ON " .. string.upper(grp.benchName or "")
                .. "  (band = middle half, tick = median)")
            for _, r in ipairs(grp.rates) do
                local scale = math.max(r.rate, r.high) * 1.15
                local px = function(v) return R_LABEL + barW * math.min(1, v / scale) end
                text(r.name, 0, y, nil, 0, R_LABEL - 6)
                rect(R_LABEL, y - 1, barW, R_ROW - 2, 0.15, 0.15, 0.15, 0.8)
                rect(px(r.low), y - 1, px(r.high) - px(r.low), R_ROW - 2, C_BAND[1], C_BAND[2], C_BAND[3], 0.30)
                local col = r.ok and C_GOOD or C_BAD
                rect(R_LABEL, y + 3 - R_ROW / 2, px(r.rate) - R_LABEL, 4, col[1], col[2], col[3], 0.95)
                rect(px(r.median), y - 1, 2, R_ROW - 2, C_BAND[1], C_BAND[2], C_BAND[3], 1)
                text(string.format("%.1f", r.rate), R_LABEL + barW + 6, y, col, 0, 30, "RIGHT")
                text(string.format("/%.1f", r.median), R_LABEL + barW + 37, y, { 0.55, 0.55, 0.55 }, -1)
                y = y - R_ROW - 2
            end
            y = y - 6
        elseif grp.hasBenchmarks then
            local why = grp.benchName and "Fight at least a minute for the casts-per-minute comparison."
                or string.format("No top-parse numbers for %s yet.", grp.name)
            line(why, { 0.6, 0.6, 0.6 })
        end
        y = y - 6
    end

    f:SetHeight(-y + R_PAD * 2 + 34)
    f:Show()
end

--- /ob report: the session so far while training is on, otherwise the
--- last finished session.
function Windows:ShowLastReport()
    if OffBeat.training and session then
        local live = self:BuildReport(session)
        if not live then
            OffBeat:Print("Training is on, but no fights have been recorded yet this session.")
            return
        end
        live.soFar = true
        self:ShowReport(live, #live.pages) -- the latest pull
        return
    end
    local report = OffBeat.db.profile.lastTrainingReport
    if report and not report.pages then
        -- saved by an older version in a layout this one can't draw
        OffBeat.db.profile.lastTrainingReport = nil
        OffBeat:Print("The saved report was from an older version of OffBeat and has been cleared.")
        return
    end
    if not report then
        OffBeat:Print("No training report yet. Turn on /ob training, fight, then turn it off.")
        return
    end
    self:ShowReport(report)
end

-- Live counter frame

function Windows:GetFrame()
    if self.frame then return self.frame end
    local f = OffBeat:CreateMovableFrame("OffBeatWindow", "windowPosition", {
        width = 200, height = 46,
        backdrop = OffBeat.FLAT_BACKDROP,
        backdropColor = { 0.05, 0.05, 0.05, 0.8 },
        borderColor = { 0.5, 0.5, 0.5, 0.6 },
        defaultY = 200,
    })
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 11, "OUTLINE")
    title:SetPoint("TOPLEFT", 8, -7)
    f.title = title
    local timer = f:CreateFontString(nil, "OVERLAY")
    timer:SetFont(FONT, 11, "OUTLINE")
    timer:SetPoint("TOPRIGHT", -8, -7)
    f.timerText = timer
    local body = f:CreateFontString(nil, "OVERLAY")
    body:SetFont(FONT, 13, "OUTLINE")
    body:SetPoint("BOTTOMLEFT", 8, 7)
    body:SetJustifyH("LEFT")
    f.body = body
    f.unlockOverlay = OffBeat:CreateUnlockOverlay(f, "Cooldown Window")
    f:SetScript("OnUpdate", function(self)
        if active then
            self.timerText:SetFormattedText("%.0fs", math.max(0, active.endsAt - GetTime()))
        end
    end)
    f:Hide()
    self.frame = f
    return f
end

function Windows:RefreshFrame()
    if not active or not SpecOr("windowLive") then return end
    local f = self:GetFrame()
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.6)
    f.title:SetText(string.upper(active.def.name))
    f.title:SetTextColor(1, 0.82, 0)
    local lines = {}
    for i, g in ipairs(active.def.goals) do
        local min = self:GetGoalMin(active.def, g)
        local color = active.counts[i] >= min and "|cff33ff66" or "|cffffffff"
        lines[#lines + 1] = string.format("%s %s%d|r / %d", g.name, color, active.counts[i], min)
    end
    for i, s in ipairs(active.def.setup) do
        if active.setup[i] ~= true then lines[#lines + 1] = Mark(active.setup[i]) .. " " .. s.name end
    end
    f.body:SetText(table.concat(lines, "\n"))
    f:SetHeight(30 + 15 * #lines)
    f:SetWidth(math.max(200, OffBeat:TextWidth(f.body) + 18,
        OffBeat:TextWidth(f.title) + OffBeat:TextWidth(f.timerText) + 30))
    f:SetAlpha(1)
    f:Show()
end

function Windows:ShowResult(result)
    if not SpecOr("windowLive") or not self.frame then return end
    local f = self.frame
    f.timerText:SetText("")
    f.title:SetText(string.upper(result.name) .. (result.met and "  ON TARGET" or "  MISSED"))
    f:SetWidth(math.max(f:GetWidth(), OffBeat:TextWidth(f.title) + 24))
    if result.met then
        f.title:SetTextColor(0.2, 1, 0.4)
        f:SetBackdropBorderColor(0.2, 0.8, 0.4, 0.8)
    else
        f.title:SetTextColor(1, 0.3, 0.3)
        f:SetBackdropBorderColor(0.9, 0.2, 0.2, 0.8)
    end
    local token = {}
    self.resultToken = token
    C_Timer.After(4, function()
        if Windows.resultToken == token and not active and OffBeat.db.profile.locked then
            f:Hide()
        end
    end)
end

function Windows:ApplyLock()
    local locked = OffBeat.db.profile.locked
    if locked then
        if self.frame then
            self.frame:EnableMouse(false)
            self.frame.unlockOverlay:Hide()
            if not active then self.frame:Hide() end
        end
    else
        local f = self:GetFrame()
        f:EnableMouse(true)
        f.unlockOverlay:Show()
        f:SetHeight(46)
        f:Show()
        f:SetAlpha(1)
    end
end
