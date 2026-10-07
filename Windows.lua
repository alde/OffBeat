local OffBeat = _G.OffBeat
local Windows = OffBeat:NewModule("Windows", "AceEvent-3.0")

-- Training: cooldown window coaching and top-parse benchmarks. Only runs in
-- training mode (/ob training, see OffBeat:ToggleTraining).
--
-- A window is opened by casting `trigger` and lasts `duration` seconds:
--
--   windows = { {
--       name = "Tyrant", trigger = 265187, duration = 25,
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
--   }
--
-- `values` follow `rates` order as { low, median, high } (low/high = middle
-- half); `window` is the top players' median goal count per window on that
-- boss. A boss without data gets no comparison rather than another boss's.
-- `all = true` counts every rotationSpells cast.
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
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "ApplyLock")
    self:RegisterMessage("OFFBEAT_TRAINING_CHANGED", "OnTrainingChanged")
    self:ApplyLock()
end

function Windows:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if active and active.timer then active.timer:Cancel() end
    active, fight, encounter = nil, nil, nil
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
                      setup = {}, goals = {} }
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
        byTrigger[w.trigger] = def
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

local function NewFight()
    return { start = GetTime(), inRaid = InRaid(), casts = {}, rotation = 0, results = {},
             encounterId = encounter and encounter.id, encounterName = encounter and encounter.name }
end

-- Does this fight count? In a raid with "boss encounters only", only fights
-- that are (or became) a boss encounter count.
local function Counts(f)
    if not f then return false end
    if f.inRaid and OffBeat.db.profile.trainingBossOnly and not f.encounterId then return false end
    return true
end

function Windows:ENCOUNTER_START(_, encounterId, encounterName)
    encounter = { id = encounterId, name = encounterName }
    if fight and not fight.encounterId then
        fight.encounterId, fight.encounterName = encounterId, encounterName
    end
end

function Windows:ENCOUNTER_END()
    encounter = nil
end

function Windows:PLAYER_REGEN_DISABLED()
    if OffBeat.training then fight = NewFight() end
end

function Windows:PLAYER_REGEN_ENABLED()
    if active then self:Close() end
    if fight and Counts(fight) then
        self:PrintSummary(fight)
        self:PrintBenchmarks(fight)
        self:FoldFight()
    end
    fight = nil
    wipe(pendingSetup)
end

-- Events

function Windows:OnTrainingChanged(_, on)
    if on then
        session = { fights = {} }
        if UnitAffectingCombat("player") then fight = NewFight() end -- count from now
        return
    end
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
    local def = byTrigger[spellId]
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

    local def = byTrigger[spellId]
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

--- The benchmark for a fight: its boss's numbers, or the all-boss numbers
--- for fights that aren't a boss encounter (dummies). nil when the boss has
--- no data.
function Windows:BenchmarkFor(f)
    local bm = OffBeat.activeProfile and OffBeat.activeProfile.benchmarks
    if not bm then return nil end
    if f.encounterId then return bm.encounters and bm.encounters[f.encounterId] end
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
    local minutes = (GetTime() - f.start) / 60
    if minutes < 1 then return end
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

function Windows:FoldFight()
    if not session or not fight then return end
    fight.minutes = (GetTime() - fight.start) / 60
    session.fights[#session.fights + 1] = fight
end

-- Group the session's fights by boss and show the report.
function Windows:FinishSession()
    local s = session
    session = nil
    local total, groups, byKey = 0, {}, {}
    for _, f in ipairs(s and s.fights or {}) do
        total = total + f.minutes
        local key = f.encounterId or 0
        local g = byKey[key]
        if not g then
            g = { name = f.encounterName or "Training dummy / outside raids", encounterId = f.encounterId,
                  fights = 0, minutes = 0, casts = {}, rotation = 0, results = {} }
            byKey[key] = g
            groups[#groups + 1] = g
        end
        if f.minutes >= 0.25 then g.fights = g.fights + 1 end
        g.minutes = g.minutes + f.minutes
        for id, n in pairs(f.casts) do g.casts[id] = (g.casts[id] or 0) + n end
        g.rotation = g.rotation + f.rotation
        for _, r in ipairs(f.results) do g.results[#g.results + 1] = r end
    end
    if total < 0.5 and #groups == 0 then
        OffBeat:Print("Training ended. No fights were recorded, so there is no report.")
        return
    end

    local profile = OffBeat.activeProfile
    local report = { spec = profile and profile.meta.name or "", minutes = total, fights = 0, groups = {} }
    for _, g in ipairs(groups) do
        report.fights = report.fights + g.fights
        local bench = self:BenchmarkFor(g)
        report.groups[#report.groups + 1] = {
            name = g.name, fights = g.fights, minutes = g.minutes,
            windows = self:Aggregate(g.results),
            detail = g.results, -- each window's goals/setup, drawn as bars
            benchName = bench and bench.name, topWindow = bench and bench.window,
            hasBenchmarks = profile and profile.benchmarks ~= nil,
            rates = (bench and g.minutes >= 1) and self:BenchmarkRows(bench, g.minutes, g.casts, g.rotation) or nil,
        }
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
    if #f.results == 0 or not OffBeat.db.profile.combatReport then return end
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

local R_PAD, R_LABEL, R_ROW, R_WIDTH = 10, 120, 14, 460
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
    f:EnableMouse(true)
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

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", R_PAD, -(R_PAD + 34))
    f.content:SetPoint("BOTTOMRIGHT", -R_PAD, R_PAD)
    f.texts, f.textures = {}, {}
    f:Hide()
    self.reportFrame = f
    return f
end

local function fmtTime(minutes)
    return string.format("%dm %02ds", math.floor(minutes), math.floor((minutes % 1) * 60))
end

function Windows:ShowReport(report)
    if not report.groups then
        OffBeat:Print("That report was saved by an older version of OffBeat. Train again for a new one.")
        return
    end
    local f = self:GetReportFrame()
    local c = f.content
    for _, t in ipairs(f.texts) do t:Hide() end
    for _, t in ipairs(f.textures) do t:Hide() end
    local nText, nTex, y = 0, 0, 0
    local barW = R_WIDTH - R_PAD * 2 - R_LABEL - 70 -- room for the value column

    local function text(str, x, yy, color, offset, width, justify)
        nText = nText + 1
        local fs = f.texts[nText]
        if not fs then fs = c:CreateFontString(nil, "OVERLAY"); f.texts[nText] = fs end
        fs:SetFont(OffBeat:GetFont(offset or 0))
        fs:SetTextColor(unpack(color or { 0.85, 0.85, 0.85 }))
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", c, "TOPLEFT", x, yy)
        fs:SetWidth(width or 0)
        fs:SetJustifyH(justify or "LEFT")
        fs:SetWordWrap(false)
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
        text(str, 0, y, { 0.55, 0.55, 0.55 }, -1)
        y = y - 16
    end

    f.title:SetFont(OffBeat:GetFont(2))
    f.closeButton.label:SetFont(OffBeat:GetFont(1))
    f.title:SetText(string.format("OffBeat — Training report (%d fight%s, %s)",
        report.fights, report.fights == 1 and "" or "s", fmtTime(report.minutes)))

    for gi, grp in ipairs(report.groups) do
        if gi > 1 then
            rect(0, y + 4, R_WIDTH - R_PAD * 2, 1, 1, 1, 1, 0.12)
            y = y - 6
        end
        text(string.format("%s  ·  %d fight%s, %s", grp.name, grp.fights, grp.fights == 1 and "" or "s",
            fmtTime(grp.minutes)), 0, y, C_BOSS, 1)
        y = y - 20

        -- Cooldown windows: one bar per window, tick = goal
        for _, agg in ipairs(grp.windows or {}) do
            local g1 = agg.goals[1]
            local scale = math.max(g1 and g1.min or 1, g1 and g1.best or 1, grp.topWindow or 0) * 1.25
            header(string.format("%s WINDOWS  ·  %d of %d on target  ·  %s avg %.1f, best %d, goal %d%s%s",
                string.upper(agg.name), agg.met, agg.n, g1 and g1.name or "",
                (g1 and agg.n > 0) and g1.total / agg.n or 0, g1 and g1.best or 0, g1 and g1.min or 0,
                grp.topWindow and string.format(", top median %d", grp.topWindow) or "",
                agg.early > 0 and string.format("  ·  %d ended early", agg.early) or ""))
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
                    text(SetupLine(st, agg.n), 0, y, { 0.7, 0.7, 0.7 }, -1)
                    y = y - 14
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
            text(why, 0, y, { 0.6, 0.6, 0.6 }, -1)
            y = y - 14
        end
        y = y - 6
    end

    f:SetHeight(-y + R_PAD * 2 + 34)
    f:Show()
end

--- Reopen the last training report (/ob report).
function Windows:ShowLastReport()
    local report = OffBeat.db.profile.lastTrainingReport
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
        backdrop = {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 },
        },
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
    f:SetAlpha(1)
    f:Show()
end

function Windows:ShowResult(result)
    if not SpecOr("windowLive") or not self.frame then return end
    local f = self.frame
    f.timerText:SetText("")
    f.title:SetText(string.upper(result.name) .. (result.met and "  ON TARGET" or "  MISSED"))
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
