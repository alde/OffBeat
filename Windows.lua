local OffBeat = _G.OffBeat
local Windows = OffBeat:NewModule("Windows", "AceEvent-3.0")

-- Cooldown window coaching. A profile window is opened by casting `trigger`
-- and lasts `duration` seconds:
--
--   windows = { {
--       name = "Tyrant", trigger = 265187, duration = 25,
--       setup = { { name = "5 Soul Shards", when = { power = "SoulShards", min = 5 } } },
--       goals = { { name = "Hand of Gul'dan", spells = { 105174 }, min = 7 } },
--   } }
--
-- Only runs in training mode (/ob training, see OffBeat:ToggleTraining).
--
-- Setup checks are judged when the trigger is pressed (UNIT_SPELLCAST_SENT,
-- like mistake rules) using the shared Conditions. Goals count successful
-- casts inside the window. A live counter shows during the window; a
-- scorecard prints when it closes and a summary when combat ends.

local READY = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"
local MISS  = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t"
local FONT  = "Fonts\\FRIZQT__.TTF"

local defs = {}          -- built window definitions
local byTrigger = {}     -- trigger spellId -> def
local pendingSetup = {}  -- castGUID -> setup results, judged at SENT
local active             -- the open window, or nil
local combatResults = {} -- closed windows this combat

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

--- Goal target: the per-spec override from the Spec page, else the profile's.
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
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "ApplyLock")
    self:RegisterMessage("OFFBEAT_TRAINING_CHANGED", "OnTrainingChanged")
    self:ApplyLock()
end

function Windows:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if active and active.timer then active.timer:Cancel() end
    active = nil
    wipe(pendingSetup)
    wipe(combatResults)
    if self.frame then self.frame:Hide() end
end

function Windows:BuildLookups()
    wipe(defs)
    wipe(byTrigger)
    local profile = OffBeat.activeProfile
    if not profile or not profile.windows then return end

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

local function JudgeSetup(def)
    local results = {}
    for i, s in ipairs(def.setup) do
        results[i] = OffBeat.Conditions.Check(s.conds)
    end
    return results
end

-- Events

function Windows:OnTrainingChanged(_, on)
    if on then return end
    -- Turning training off mid-window drops it without a scorecard.
    if active and active.timer then active.timer:Cancel() end
    active = nil
    wipe(pendingSetup)
    wipe(combatResults)
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

    local def = byTrigger[spellId]
    if def then
        local setup
        if castGUID and not OffBeat.Conditions.IsSecret(castGUID) then
            setup = pendingSetup[castGUID]
            pendingSetup[castGUID] = nil
        end
        self:Open(def, setup or JudgeSetup(def)) -- no SENT snapshot: judge now
        return
    end

    if active then
        for i, g in ipairs(active.def.goals) do
            if g.spells[spellId] then
                active.counts[i] = active.counts[i] + 1
            end
        end
        self:RefreshFrame()
    end
end

function Windows:PLAYER_REGEN_DISABLED()
    wipe(combatResults)
end

function Windows:PLAYER_REGEN_ENABLED()
    if active then self:Close() end
    self:PrintSummary()
    wipe(combatResults)
    wipe(pendingSetup)
end

-- Window lifecycle

function Windows:Open(def, setup)
    if active then self:Close() end -- a re-trigger closes the previous window
    local counts = {}
    for i = 1, #def.goals do counts[i] = 0 end
    active = { def = def, setup = setup, counts = counts,
               endsAt = GetTime() + def.duration }
    active.timer = C_Timer.NewTimer(def.duration, function() Windows:Close() end)
    self:SendMessage("OFFBEAT_WINDOW_OPENED", def.name)
    self:RefreshFrame()
end

function Windows:Close()
    local w = active
    if not w then return end
    active = nil
    if w.timer then w.timer:Cancel() end

    local result = { name = w.def.name, setup = {}, goals = {}, met = true }
    for i, s in ipairs(w.def.setup) do
        local ok = w.setup[i] and true or false
        result.setup[i] = { name = s.name, ok = ok }
        if not ok then result.met = false end
    end
    for i, g in ipairs(w.def.goals) do
        local min = self:GetGoalMin(w.def, g)
        local ok = w.counts[i] >= min
        result.goals[i] = { name = g.name, count = w.counts[i], min = min, ok = ok }
        if not ok then result.met = false end
    end
    combatResults[#combatResults + 1] = result

    if SpecOr("windowChat") then
        local parts = {}
        for _, g in ipairs(result.goals) do
            parts[#parts + 1] = string.format("%s %s %d/%d", g.ok and READY or MISS, g.name, g.count, g.min)
        end
        for _, s in ipairs(result.setup) do
            parts[#parts + 1] = string.format("%s %s", s.ok and READY or MISS, s.name)
        end
        OffBeat:Print(string.format("%s window: %s", result.name, table.concat(parts, "  ")))
    end

    self:SendMessage("OFFBEAT_WINDOW_CLOSED", result)
    self:ShowResult(result)
end

function Windows:PrintSummary()
    if #combatResults == 0 or not OffBeat.db.profile.combatReport then return end

    local byName = {}
    for _, r in ipairs(combatResults) do
        local s = byName[r.name]
        if not s then
            s = { n = 0, met = 0, goals = {}, setupOk = {} }
            byName[r.name] = s
        end
        s.n = s.n + 1
        if r.met then s.met = s.met + 1 end
        for i, g in ipairs(r.goals) do
            local t = s.goals[i] or { name = g.name, total = 0, best = 0, min = g.min }
            t.total = t.total + g.count
            if g.count > t.best then t.best = g.count end
            s.goals[i] = t
        end
        for i, st in ipairs(r.setup) do
            local t = s.setupOk[i] or { name = st.name, ok = 0 }
            if st.ok then t.ok = t.ok + 1 end
            s.setupOk[i] = t
        end
    end

    for name, s in pairs(byName) do
        local parts = { string.format("%d/%d on target", s.met, s.n) }
        for _, g in ipairs(s.goals) do
            parts[#parts + 1] = string.format("%s avg %.1f (goal %d, best %d)",
                g.name, g.total / s.n, g.min, g.best)
        end
        for _, t in ipairs(s.setupOk) do
            parts[#parts + 1] = string.format("%s %d/%d", t.name, t.ok, s.n)
        end
        OffBeat:Print(string.format("%s windows: %s", name, table.concat(parts, ", ")))
    end
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
        if not active.setup[i] then lines[#lines + 1] = MISS .. " " .. s.name end
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
