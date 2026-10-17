local OffBeat = _G.OffBeat

-- The settings window (/ob). Three places in the sidebar:
--
--   <your spec>  tabs: Overview, Alerts, Training, Keys & Bars, Gear
--                (only the tabs this spec's profile uses)
--   Panels       how each on-screen element looks, shared by every spec
--   General      behaviour, profile import / export
--
-- Pages are built from cards laid out in two columns (masonry: each card
-- goes into the shorter column); a full-width card spans both.

local PANEL_W, PANEL_H = 940, 680
local SIDEBAR_W = 200
local HEADER_H = 44
local TABS_H = 30
local PAD = 16
local GAP = 12
local SCROLLBAR = 22
local CARD_HEAD = 30
local CARD_PAD = 8

local ACCENT = { 0.35, 0.70, 1.0 }
local BG_COLOR = { 0.05, 0.07, 0.09, 0.97 }
local SIDEBAR_BG = { 0.035, 0.045, 0.06, 1 }
local FONT = "Fonts\\FRIZQT__.TTF"

local mainFrame, sidebar, tabBar, scrollFrame, scrollChild, titleText
local navButtons, tabButtons = {}, {}
local activeNav, activeTab = "spec", "overview"
local tabBuilders, navBuilders = {}, {}
local Select -- forward

local function W() return OffBeat.Widgets end
local function DB() return OffBeat.db.profile end

local function GetSpecSettings(specId)
    local db = DB()
    db.specSettings[specId] = db.specSettings[specId] or {}
    return db.specSettings[specId]
end

local function SpecName()
    local profile = OffBeat.activeProfile
    if profile then return profile.meta.name end
    local spec = GetSpecialization and GetSpecialization()
    if spec then
        local _, name = GetSpecializationInfo(spec)
        local className = UnitClass("player")
        if name then return name .. " " .. (className or "") end
    end
    return "Your Spec"
end

local function Module(name)
    local m = OffBeat:GetModule(name, true)
    return (m and m:IsEnabled()) and m or nil
end

-- Spec tabs, in order. `show` decides whether this spec gets the tab.
local TABS = {
    { key = "overview", label = "Overview", show = function() return true end },
    { key = "alerts",   label = "Alerts",   show = function(p)
        return p and (p.keyCooldown or p.prep or (p.mistakes and #p.mistakes > 0) or p.procTracking
            or p.failNudges or p.movingCasts or p.pet or (p.idleCooldowns and #p.idleCooldowns > 0)
            or p.trackedBuffs) and true or false end },
    { key = "training", label = "Training", show = function(p) return p and p.windows ~= nil end },
    { key = "keys",     label = "Keys & Bars", show = function(p) return p and (p.keyLayout or p.barLayout) and true or false end },
    { key = "gear",     label = "Gear",     show = function() return OffBeat:GetGearRecs() ~= nil end },
}

-- Layout: two columns of cards

local function CreateCard(parent, title, x, y, w)
    local card = CreateFrame("Frame", nil, parent)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    card:SetWidth(w)
    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1, 0.025)
    W().FlatBorder(card, 1, 1, 1, 0.07)
    local t = card:CreateFontString(nil, "OVERLAY")
    t:SetFont(FONT, 10, "")
    t:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -11)
    t:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    t:SetJustifyH("LEFT")
    t:SetWordWrap(false)
    t:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
    t:SetText(string.upper(title))
    local inner = CreateFrame("Frame", nil, card)
    inner:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -CARD_HEAD)
    inner:SetWidth(w)
    return card, inner
end

local function NewLayout(parent, width)
    local L = { colW = math.floor((width - GAP) / 2), cols = { -PAD, -PAD } }
    -- build(inner) adds widgets from y = 0 down and returns the final y.
    function L:Card(title, build, full)
        local x, y, w, col
        if full then
            y, x, w = math.min(self.cols[1], self.cols[2]), 0, width
        else
            col = (self.cols[1] >= self.cols[2]) and 1 or 2
            y, x, w = self.cols[col], (col == 1) and 0 or (self.colW + GAP), self.colW
        end
        local card, inner = CreateCard(parent, title, x, y, w)
        local endY = build(inner, 0) or 0
        inner:SetHeight(math.max(1, -endY))
        local h = CARD_HEAD + (-endY) + CARD_PAD
        card:SetHeight(h)
        if full then
            self.cols[1] = y - h - GAP
            self.cols[2] = self.cols[1]
        else
            self.cols[col] = y - h - GAP
        end
    end
    function L:Height() return -math.min(self.cols[1], self.cols[2]) end
    return L
end

-- Small builders shared by the pages

-- A per-spec on/off with the global default as fallback.
local function SpecToggle(parent, y, label, ss, key, onChange)
    local _, h = W():Toggle(parent, label, y,
        function()
            local v = ss[key]
            if v == nil then return DB()[key] end
            return v
        end,
        function(v) ss[key] = v; if onChange then onChange(v) end end)
    return y - h
end

local function SpecSound(parent, y, label, ss, key)
    local _, h = W():SoundPicker(parent, label, y,
        function() return ss[key] or DB()[key] end,
        function(v) ss[key] = v end)
    return y - h
end

local function Para(parent, y, text)
    local _, h = W():Paragraph(parent, text, y)
    return y - h
end

-- Spec: Overview

tabBuilders.overview = function(L)
    local profile = OffBeat.activeProfile

    L:Card("Profile", function(p, y)
        local specId = OffBeat.activeSpecId
        local available = specId and OffBeat.profiles[specId]
        if available and #available > 1 then
            local vals, order = {}, {}
            for _, pr in ipairs(available) do vals[pr.meta.name] = pr.meta.name; order[#order + 1] = pr.meta.name end
            local _, h = W():Dropdown(p, "Profile", y, vals,
                function() return profile and profile.meta.name or order[1] end,
                function(name) OffBeat:SwitchProfile(name); Select("spec", "overview") end, order)
            y = y - h
        end
        if profile then
            y = Para(p, y, profile.meta.name .. (profile.meta.source and (" — " .. profile.meta.source) or ""))
        else
            y = Para(p, y, "No OffBeat profile for this spec yet. The Gear tab still works.")
        end
        return y
    end)

    if OffBeat:ProfileUsesContent(profile) then
        L:Card("Raid or Mythic+", function(p, y)
            local _, h = W():Dropdown(p, "Content", y,
                { auto = "Auto", raid = "Raid", mythic = "Mythic+" },
                function() return OffBeat.db.profile.contentMode or "auto" end,
                function(v) OffBeat:SetContentMode(v); Select("spec", "overview") end,
                { "auto", "raid", "mythic" })
            y = y - h
            return Para(p, y, "Now: " .. OffBeat:ContentModeText() .. ". Picks the cheat sheet sections, idle alerts "
                .. "and the numbers dummy fights are compared with. Auto reads the instance (delves count as Mythic+); "
                .. "outside one it shows both. Also /ob mode auto | raid | mythic.")
        end)
    end

    if profile then
        -- What this profile turns on, so you know where to look.
        L:Card("What OffBeat does for this spec", function(p, y)
            local lines = {}
            local function add(ok, text) if ok then lines[#lines + 1] = "•  " .. text end end
            add(profile.rotationSpells, "Ability history panel")
            add(profile.keyCooldown, (profile.keyCooldown and profile.keyCooldown.name or "") .. " ready alert and icon")
            add(profile.prep, "Countdown before " .. (profile.prep and profile.prep.name or "the cooldown"))
            add(profile.mistakes and #profile.mistakes > 0, (profile.mistakes and #profile.mistakes or 0) .. " mistake check(s)")
            add(profile.failNudges, "What to press when a press fails")
            add(profile.procTracking, "Wasted proc warnings")
            add(profile.idleCooldowns and #profile.idleCooldowns > 0, "Idle cooldown nag")
            add(profile.movingCasts, "Instant-while-moving nudge")
            add(profile.pet, "Pet warnings")
            add(profile.windows, "Training windows and top-parse benchmarks")
            add(profile.rotationSheet, "Rotation sheet")
            add(profile.barLayout, "Bar layout (Keys & Bars)")
            add(profile.trackedBuffs, "Buff panel and timeline")
            return Para(p, y, table.concat(lines, "\n"))
        end)
    end

    if profile and profile.rotationSheet then
        L:Card("Rotation sheet", function(p, y)
            local ss = GetSpecSettings(profile.meta.specId)
            local function refresh() local m = Module("Sheet"); if m then m:Render() end end
            y = SpecToggle(p, y, "Show Rotation Sheet", ss, "showSheet", refresh)
            y = SpecToggle(p, y, "Hide It in Combat", ss, "sheetHideInCombat", refresh)
            return Para(p, y, "Also /ob sheet. Drag it while frames are unlocked.")
        end)
    end

    if C_AssistedCombat and profile and profile.rotationSpells then
        L:Card("Blizzard's next spell", function(p, y)
            local _, h = W():Toggle(p, "Show Next Spell (this spec)", y,
                function() return OffBeat:AssistedCombatOn() end,
                function(v)
                    GetSpecSettings(profile.meta.specId).assistedCombat = v
                    local rd = Module("RotationDisplay"); if rd then rd:RefreshAssisted() end
                end)
            y = y - h
            return Para(p, y, "Size and keybind text are on the Panels page.")
        end)
    end
end

-- Spec: Alerts

tabBuilders.alerts = function(L)
    local profile = OffBeat.activeProfile
    if not profile then return end
    local db = DB()
    local ss = GetSpecSettings(profile.meta.specId)

    if profile.keyCooldown or profile.prep then
        L:Card("Main cooldown" .. (profile.keyCooldown and (" — " .. profile.keyCooldown.name) or ""), function(p, y)
            if profile.keyCooldown then
                y = SpecToggle(p, y, "Ready Alert", ss, "keyCdAlert")
                y = SpecSound(p, y, "Ready Sound", ss, "keyCdSound")
                y = SpecToggle(p, y, "Waste Warning", ss, "keyCdWasteAlert")
                y = SpecSound(p, y, "Waste Sound", ss, "keyCdWasteSound")
            end
            if profile.prep then
                y = SpecToggle(p, y, "Countdown: What to Hold", ss, "prepEnabled")
                local _, h = W():Slider(p, "Seconds Before", y, 3, 10, 1,
                    function() return ss.prepLead or db.prepLead or profile.prep.lead or 5 end,
                    function(v) ss.prepLead = v end)
                y = y - h
            end
            return y
        end)
    end

    local hasMistakes = profile.mistakes and #profile.mistakes > 0
    if hasMistakes or profile.procTracking or profile.failNudges then
        L:Card("Mistakes & procs", function(p, y)
            if hasMistakes then
                y = SpecToggle(p, y, "Mistake Sound", ss, "soundEnabled")
                y = SpecSound(p, y, "Sound", ss, "mistakeSound")
            end
            if profile.procTracking and #profile.procTracking > 0 then
                y = SpecToggle(p, y, "Proc Expiring Warning", ss, "procExpireAlert")
                y = SpecSound(p, y, "Expire Sound", ss, "procExpireSound")
            end
            if profile.failNudges then
                y = SpecToggle(p, y, "Failed Press: What Instead", ss, "failNudge")
            end
            return y
        end)
    end

    if profile.idleCooldowns and #profile.idleCooldowns > 0 then
        L:Card("Idle cooldowns", function(p, y)
            y = SpecToggle(p, y, "Idle Warning", ss, "idleCooldownAlert")
            y = SpecToggle(p, y, "Visual Nag", ss, "idleCooldownNag")
            local _, h = W():Slider(p, "After (seconds)", y, 2, 15, 1,
                function() return ss.idleCooldownThreshold or db.idleCooldownThreshold end,
                function(v) ss.idleCooldownThreshold = v end)
            y = y - h
            y = SpecSound(p, y, "Sound", ss, "idleCooldownSound")
            ss.disabledIdleCooldowns = ss.disabledIdleCooldowns or {}
            local function rebuild() local r = OffBeat:GetModule("Rotation", true); if r then r:BuildLookups() end end
            for _, cd in ipairs(profile.idleCooldowns) do
                local tag = cd.content == "raid" and "  (raid)" or (cd.content == "dungeon" and "  (M+ / delves)" or "")
                _, h = W():Toggle(p, "   " .. cd.name .. tag, y,
                    function() return not ss.disabledIdleCooldowns[cd.spellId] end,
                    function(v) ss.disabledIdleCooldowns[cd.spellId] = (not v) or nil; rebuild() end)
                y = y - h
            end
            local racials = OffBeat:GetKnownRacials()
            if #racials > 0 then
                y = SpecToggle(p, y, "Racial Cooldowns", ss, "trackRacials", rebuild)
            end
            return y
        end)
    end

    if profile.movingCasts or profile.pet then
        L:Card("Situational", function(p, y)
            if profile.movingCasts then
                local names = {}
                for _, m in ipairs(profile.movingCasts) do names[#names + 1] = m.name or tostring(m.spellId) end
                y = SpecToggle(p, y, "Moving: " .. table.concat(names, ", ") .. " Is Instant", ss, "movingNudge")
                local _, h = W():Slider(p, "After Moving (s)", y, 0.5, 4, 0.5,
                    function() return ss.movingNudgeDelay or db.movingNudgeDelay end,
                    function(v) ss.movingNudgeDelay = v end)
                y = y - h
                y = SpecSound(p, y, "Moving Sound", ss, "movingNudgeSound")
            end
            if profile.pet then
                y = SpecToggle(p, y, "Pet Died / Missing", ss, "petAlert")
                y = SpecToggle(p, y, "Pet Low Health", ss, "petLowHealthAlert")
                y = SpecSound(p, y, "Pet Sound", ss, "petAlertSound")
            end
            return y
        end)
    end

    if profile.trackedBuffs then
        L:Card("Buff tracking", function(p, y)
            local _, h = W():Toggle(p, "Chat Output", y,
                function() return db.chatOutput end, function(v) db.chatOutput = v end)
            y = y - h
            _, h = W():Toggle(p, "Cast Warnings", y,
                function() return db.castWarnings end, function(v) db.castWarnings = v end)
            return y - h
        end)
    end
end

-- Spec: Training

tabBuilders.training = function(L)
    local profile = OffBeat.activeProfile
    if not profile or not profile.windows then return end
    local db = DB()
    local ss = GetSpecSettings(profile.meta.specId)
    local win = OffBeat:GetModule("Windows", true)

    L:Card("Training", function(p, y)
        local _, h = W():Toggle(p, "Training Mode (this session)", y,
            function() return OffBeat.training end,
            function(v) if v ~= OffBeat.training then OffBeat:ToggleTraining() end end)
        y = y - h
        _, h = W():Toggle(p, "In Raids, Only Count Bosses", y,
            function() return db.trainingBossOnly end, function(v) db.trainingBossOnly = v end)
        y = y - h
        _, h = W():Toggle(p, "Log Combat While Training", y,
            function() return db.trainingCombatLog end, function(v) db.trainingCombatLog = v end)
        y = y - h
        y = SpecToggle(p, y, "Live Counter", ss, "windowLive")
        y = SpecToggle(p, y, "Chat Scorecard", ss, "windowChat")
        _, h = W():Button(p, "Last Report", y, function()
            if win and win:IsEnabled() then win:ShowLastReport() end
        end, "/ob report")
        return y - h
    end)

    L:Card("How it works", function(p, y)
        return Para(p, y,
            "Press your big cooldown and OffBeat counts the casts that matter inside the window "
            .. "against a goal from top parses: a live counter while it runs, a scorecard when it "
            .. "ends. After each fight your casts per minute are compared with that boss's top "
            .. "players, and turning training off (or /ob training) opens a report with a page per "
            .. "pull. It survives a /reload and switches off when you log out.")
    end)

    for _, w in ipairs(profile.windows) do
        L:Card(w.name .. " window (" .. w.duration .. "s)", function(p, y)
            if w.note then y = Para(p, y, w.note) end
            for _, st in ipairs(w.setup or {}) do y = Para(p, y, "Setup check: " .. st.name) end
            if win then
                for _, g in ipairs(w.goals or {}) do
                    local _, h = W():Slider(p, g.name, y, 1, 20, 1,
                        function() return win:GetGoalMin(w, g) end,
                        function(v) win:SetGoalMin(w, g, v) end)
                    y = y - h
                end
            end
            return y
        end)
    end

    local bm = profile.benchmarks
    if bm then
        L:Card("Top-parse benchmarks", function(p, y)
            local names, lines = {}, {}
            for _, e in pairs(bm.encounters or {}) do names[#names + 1] = e.name end
            table.sort(names)
            for _, r in ipairs(bm.rates) do lines[#lines + 1] = r.name end
            local dungeons = {}
            for _, e in pairs(bm.dungeons or {}) do dungeons[#dungeons + 1] = e.name end
            table.sort(dungeons)
            return Para(p, y, "From " .. (bm.source or "top parses") .. ". Measured: "
                .. table.concat(lines, ", ") .. ".\nBosses: " .. (#names > 0 and table.concat(names, ", ") or "none")
                .. ". Dummies and other fights use " .. (bm.overall and bm.overall.name or "no benchmark") .. "."
                .. (#dungeons > 0 and ("\nMythic+ (per minute in combat): " .. table.concat(dungeons, ", ") .. "."
                    .. (bm.dungeonOverall and (" With /ob mode mythic, dummies use " .. bm.dungeonOverall.name .. ".") or "")) or ""))
        end)
    end
end

-- Spec: Keys & Bars

local DEFAULT_LAYOUT_LABELS = { st = "ST", aoe = "AoE", stLong = "Single Target", aoeLong = "AoE" }

local KEY_TIERS = {
    { tier = 1, label = "Core — your best keys",
      hint = "Pressed every few GCDs. Put these on the keys your fingers rest on." },
    { tier = 2, label = "Regular — easy reach",
      hint = "Used every cycle or on procs. Unmodified keys close to home." },
    { tier = 3, label = "Cooldowns — modifiers are fine",
      hint = "Once every minute or two. Shift/Ctrl binds or a farther key." },
}

local function ResolveLayoutSpell(entry)
    local ids = { entry.spellId }
    for _, id in ipairs(entry.alt or {}) do ids[#ids + 1] = id end
    -- A base spell replaced by a talent (Immolate -> Wither) is still known,
    -- but the replacement is what sits on your bar.
    for _, id in ipairs(ids) do
        local current, known = id, IsPlayerSpell(id)
        if FindSpellOverrideByID then
            local override = FindSpellOverrideByID(id)
            if override and override ~= id then
                current = override
                known = known or IsPlayerSpell(override)
            end
        end
        if known then return current, true end
    end
    return entry.spellId, false
end

local function BuildLayoutRows(layout)
    local rows, byName = {}, {}
    for _, entry in ipairs(layout) do
        local id, known = ResolveLayoutSpell(entry)
        local info = C_Spell.GetSpellInfo(id)
        local name = (info and info.name) or entry.name or ("Spell " .. id)
        local existing = byName[name]
        if existing then
            if known and not existing.known then
                existing.known, existing.spellId, existing.icon = true, id, info and info.iconID
            end
            if entry.st and (not existing.st or entry.st < existing.st) then existing.st = entry.st end
            if entry.aoe and (not existing.aoe or entry.aoe < existing.aoe) then existing.aoe = entry.aoe end
        else
            local row = { spellId = id, name = name, icon = info and info.iconID,
                          note = entry.note, st = entry.st, aoe = entry.aoe, known = known }
            rows[#rows + 1] = row
            byName[name] = row
        end
    end
    return rows
end

local function RowTier(row, view)
    if view == "st" then return row.st end
    if view == "aoe" then return row.aoe end
    if row.st and row.aoe then return math.min(row.st, row.aoe) end
    return row.st or row.aoe
end

tabBuilders.keys = function(L)
    local profile = OffBeat.activeProfile
    if not profile then return end
    local db = DB()

    if profile.barLayout then
        L:Card("Bar layout", function(p, y)
            local ss = GetSpecSettings(profile.meta.specId)
            local split = OffBeat:BarLayoutHasContent()
            local content
            if split then
                -- which layout to show: picked here, else the content you're in, else raid
                content = ss.barLayoutView or OffBeat:ContentMode() or ss.barLayoutContent or "raid"
                local _, h = W():Dropdown(p, "Layout", y, { raid = "Raid", dungeon = "Mythic+ / delves" },
                    function() return content end,
                    function(v) ss.barLayoutView = v; Select("spec", "keys") end, { "raid", "dungeon" })
                y = y - h
                local onBars = ss.barLayoutContent
                y = Para(p, y, "On your bars now: " .. (onBars == "raid" and "raid" or onBars == "dungeon" and "Mythic+"
                    or "not placed by OffBeat yet") .. ". Heals are mouseover macros (your target when "
                    .. "there's no one under the mouse).")
                y = SpecToggle(p, y, "Offer to Swap on Spec Switch / Raid-M+ Change", ss, "barSwapOffer")
            end
            local plan = OffBeat:GetBarLayoutPlan(content) or {}
            for _, r in ipairs(plan) do
                local info = C_Spell.GetSpellInfo(r.spellId)
                local _, h = W():InfoRow(p, y, r.key, r.text .. (r.known and "" or "  (not talented, skipped)"),
                    info and info.iconID, not r.known)
                y = y - h
            end
            local _, h = W():Button(p, "Put These on My Bars", y, function()
                OffBeat:ShowBarLayout(true, content and (content == "dungeon" and "mythic" or "raid"))
                Select("spec", "keys")
            end, "Replaces only these slots. Out of combat.", true)
            return y - h
        end, true)
    end

    if profile.keyLayout then
        local labels = profile.keyLayoutLabels or DEFAULT_LAYOUT_LABELS
        if db.keyLayoutView == nil then db.keyLayoutView = "both" end
        local view = db.keyLayoutView
        OffBeat:InvalidateKeybindCache() -- binds may have changed since the cache was built
        local rows = BuildLayoutRows(profile.keyLayout)
        local unknownCount = 0
        for _, row in ipairs(rows) do
            if not row.known and RowTier(row, view) then unknownCount = unknownCount + 1 end
        end

        L:Card("Key layout", function(p, y)
            y = Para(p, y, "How often you press each spell, from the guide. " .. labels.st .. " / "
                .. labels.aoe .. " badges: bright = core, dim = regular, grey = cooldown. Amber key = "
                .. "a core spell behind a modifier, red = not bound.")
            local _, h = W():Dropdown(p, "View", y,
                { both = labels.stLong .. " + " .. labels.aoeLong, st = labels.stLong, aoe = labels.aoeLong },
                function() return db.keyLayoutView end,
                function(v) db.keyLayoutView = v; Select("spec", "keys") end,
                { "both", "st", "aoe" })
            y = y - h
            _, h = W():Toggle(p, "Show Untalented (" .. unknownCount .. ")", y,
                function() return db.keyLayoutShowUntalented end,
                function(v) db.keyLayoutShowUntalented = v; Select("spec", "keys") end)
            y = y - h
            for _, t in ipairs(KEY_TIERS) do
                local ordered = {}
                for _, row in ipairs(rows) do
                    if RowTier(row, view) == t.tier and row.known then ordered[#ordered + 1] = row end
                end
                for _, row in ipairs(rows) do
                    if RowTier(row, view) == t.tier and not row.known and db.keyLayoutShowUntalented then
                        ordered[#ordered + 1] = row
                    end
                end
                if #ordered > 0 then
                    _, h = W():SectionHeader(p, string.upper(t.label), y); y = y - h
                    y = Para(p, y, t.hint)
                    for _, row in ipairs(ordered) do
                        local key = row.known and OffBeat:GetKeybindForSpell(row.spellId) or nil
                        local warn
                        if row.known and not key and t.tier <= 2 then warn = "unbound"
                        elseif key and t.tier == 1 and key:match("^[scam]%-") then warn = "modifier" end
                        row.key, row.keyWarn = key, warn
                        _, h = W():SpellRow(p, y, row, labels); y = y - h
                    end
                end
            end
            return y
        end, true)
    end
end

-- Spec: Gear

tabBuilders.gear = function(L)
    local check, recs = OffBeat:CheckGear()
    if not check then return end
    local GOOD, WARN, BAD, DIM = { 0.3, 0.9, 0.45 }, { 1, 0.82, 0.3 }, { 1, 0.35, 0.3 }, { 0.6, 0.6, 0.6 }

    L:Card("Enchants", function(p, y)
        y = Para(p, y, "What the top players of your spec use (" .. (recs.source or "")
            .. "), against what you have on. Percentages: how many of them use it.")
        for _, e in ipairs(check.enchants) do
            local opts = {}
            for i, o in ipairs(e.options) do
                if i > 3 then break end
                opts[#opts + 1] = string.format("%s %d%%", OffBeat:GearName("enchant", o[1], recs), o[2])
            end
            local status, color
            if e.status == "ok" then status, color = "OK", GOOD
            elseif e.status == "missing" then status, color = "MISSING", BAD
            elseif e.status == "empty" then status, color = "no item", DIM
            else status, color = "other: " .. OffBeat:GearName("enchant", e.have, recs), WARN end
            local slot
            for _, s in ipairs(OffBeat.GEAR_SLOTS) do if s[3] == e.label then slot = s[2] end end
            local _, h = W():GearRow(p, y, {
                icon = e.icon, title = e.label, sub = table.concat(opts, "  ·  "),
                status = status, color = color,
                tooltipLink = slot and GetInventoryItemLink("player", slot),
            })
            y = y - h
        end
        return y
    end, true)

    local g = check.gems
    L:Card("Gems", function(p, y)
        for i, r in ipairs(g.recommended) do
            if i > 6 then break end
            local _, h = W():GearRow(p, y, {
                icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(r[1]),
                title = OffBeat:GearName("gem", r[1]),
                sub = string.format("%d%% of top players use it", r[2]),
                tooltipLink = "item:" .. r[1],
            })
            y = y - h
        end
        local line = string.format("Your sockets: %d of %d filled.", g.filled, g.sockets)
        if #g.empty > 0 then line = line .. " Empty: " .. table.concat(g.empty, ", ") .. "." end
        if #g.odd > 0 then
            local odd = {}
            for _, o in ipairs(g.odd) do odd[#odd + 1] = o[1] .. " (" .. OffBeat:GearName("gem", o[2]) .. ")" end
            line = line .. " Not a common pick: " .. table.concat(odd, ", ") .. "."
        end
        return Para(p, y, line)
    end, true)
end

-- Panels: how each on-screen element looks (every spec)

navBuilders.panels = function(L)
    local db = DB()
    local profile = OffBeat.activeProfile
    local function history() OffBeat:SendMessage("OFFBEAT_HISTORY_UPDATED") end
    local function rd() return Module("RotationDisplay") end

    L:Card("Ability history", function(p, y)
        local _, h = W():Toggle(p, "Show Panel", y, function() return db.rotationShown end,
            function(v) db.rotationShown = v; local m = rd(); if m then m:UpdatePanelVisibility() end end)
        y = y - h
        _, h = W():Toggle(p, "Only in Combat", y, function() return db.rotationCombatOnly end,
            function(v) db.rotationCombatOnly = v; local m = rd(); if m then m:UpdatePanelVisibility() end end)
        y = y - h
        _, h = W():Slider(p, "Icons Shown", y, 2, 12, 1, function() return db.historyCount end,
            function(v) db.historyCount = v; history() end)
        y = y - h
        _, h = W():Dropdown(p, "Grows", y, { right = "Right", left = "Left", up = "Up", down = "Down" },
            function() return db.growDirection end, function(v) db.growDirection = v; history() end,
            { "right", "left", "up", "down" })
        y = y - h
        _, h = W():Slider(p, "Icon Size", y, 20, 64, 2, function() return db.iconSize end,
            function(v) db.iconSize = v; history() end)
        y = y - h
        _, h = W():Slider(p, "Newest Opacity", y, 0.2, 1.0, 0.05, function() return db.iconAlpha end,
            function(v) db.iconAlpha = v; history() end)
        y = y - h
        _, h = W():Slider(p, "Fade Per Icon", y, 0, 0.3, 0.02, function() return db.opacityStep end,
            function(v) db.opacityStep = v; history() end)
        y = y - h
        _, h = W():Slider(p, "Fade Floor", y, 0.1, 1.0, 0.05, function() return db.minOpacity end,
            function(v) db.minOpacity = v; history() end)
        y = y - h
        _, h = W():Slider(p, "Background", y, 0, 1.0, 0.05, function() return db.bgAlpha end,
            function(v) db.bgAlpha = v; OffBeat:ApplyAppearance() end)
        return y - h
    end)

    L:Card("Main cooldown icon", function(p, y)
        local _, h = W():Toggle(p, "Show Icon", y, function() return db.keyCdIconEnabled end,
            function(v) db.keyCdIconEnabled = v end)
        y = y - h
        _, h = W():Toggle(p, "Only in Combat", y, function() return db.keyCdCombatOnly end,
            function(v) db.keyCdCombatOnly = v end)
        y = y - h
        _, h = W():Slider(p, "Icon Size", y, 24, 80, 2, function() return db.keyCdIconSize end,
            function(v) db.keyCdIconSize = v; local m = rd(); if m then m:ResizeKeyCdIcon() end end)
        y = y - h
        _, h = W():Dropdown(p, "Glow", y, { glow = "Pulse", proc = "Proc", ants = "Ants", none = "None" },
            function() return db.keyCdGlowStyle end, function(v) db.keyCdGlowStyle = v end,
            { "glow", "proc", "ants", "none" })
        y = y - h
        _, h = W():Slider(p, "Glow Intensity", y, 0.2, 1.0, 0.05, function() return db.keyCdGlowIntensity end,
            function(v) db.keyCdGlowIntensity = v end)
        y = y - h
        _, h = W():ColorPicker(p, "Glow Color", y, function() return OffBeat:GetGlowColor() end,
            function(r, g, b)
                if r then db.keyCdGlowColor = { r = r, g = g, b = b } else db.keyCdGlowColor = nil end
            end, "Class Color")
        return y - h
    end)

    L:Card("Warning text", function(p, y)
        local _, h = W():Slider(p, "Background", y, 0, 1.0, 0.05, function() return db.warningBgAlpha end,
            function(v) db.warningBgAlpha = v end)
        y = y - h
        _, h = W():Slider(p, "Border", y, 0, 1.0, 0.05, function() return db.warningBorderAlpha end,
            function(v) db.warningBorderAlpha = v end)
        return y - h
    end)

    if C_AssistedCombat then
        L:Card("Next spell icon", function(p, y)
            local _, h = W():Toggle(p, "Only in Combat", y, function() return db.assistedCombatOnly end,
                function(v) db.assistedCombatOnly = v; local m = rd(); if m then m:UpdateAssistedVisibility() end end)
            y = y - h
            _, h = W():Slider(p, "Icon Size", y, 24, 80, 2, function() return db.assistedIconSize end,
                function(v) db.assistedIconSize = v; local m = rd(); if m then m:RefreshAssisted() end end)
            y = y - h
            _, h = W():Toggle(p, "Show Keybind", y, function() return db.assistedKeybindShown end,
                function(v) db.assistedKeybindShown = v; local m = rd(); if m then m:RefreshAssisted() end end)
            y = y - h
            _, h = W():Slider(p, "Keybind Size", y, 8, 20, 1, function() return db.assistedKeybindSize end,
                function(v) db.assistedKeybindSize = v; local m = rd(); if m then m:RefreshAssisted() end end)
            y = y - h
            return Para(p, y, "On or off per spec: Overview tab.")
        end)
    end

    L:Card("Timelines", function(p, y)
        local _, h = W():Toggle(p, "Rotation Timeline After Fights", y, function() return db.timelineAutoShow end,
            function(v) db.timelineAutoShow = v end)
        y = y - h
        _, h = W():Dropdown(p, "Buff Timeline After", y,
            { both = "Both", encounter = "Encounters", keystone = "Keystones", never = "Never" },
            function() return db.timelineShow end, function(v) db.timelineShow = v end,
            { "both", "encounter", "keystone", "never" })
        y = y - h
        _, h = W():Toggle(p, "Keystone Tracking", y, function() return db.keystoneTracking end,
            function(v) db.keystoneTracking = v end)
        y = y - h
        _, h = W():Slider(p, "Fights Kept", y, 1, 50, 1, function() return db.historySize end,
            function(v) db.historySize = v end)
        return y - h
    end)

    if profile and profile.trackedBuffs then
        local LSM = LibStub("LibSharedMedia-3.0")
        L:Card("Buff panel", function(p, y)
            local function refresh() OffBeat:SendMessage("OFFBEAT_DISPLAY_REFRESH") end
            local _, h = W():Toggle(p, "Show Panel", y, function() return db.buffPanelShown end,
                function(v)
                    db.buffPanelShown = v
                    local bd = Module("BuffDisplay")
                    if bd then if v then bd:GetFrame():Show(); bd:Refresh() else bd:GetFrame():Hide() end end
                end)
            y = y - h
            _, h = W():Dropdown(p, "Bar Texture", y, LSM:HashTable("statusbar"),
                function() return db.barTexture end, function(v) db.barTexture = v; refresh() end)
            y = y - h
            _, h = W():Dropdown(p, "Font", y, LSM:HashTable("font"),
                function() return db.font end, function(v) db.font = v; refresh() end)
            y = y - h
            _, h = W():Slider(p, "Font Size", y, 8, 16, 1, function() return db.fontSize end,
                function(v) db.fontSize = v; refresh() end)
            y = y - h
            _, h = W():Dropdown(p, "Outline", y, { NONE = "None", OUTLINE = "Thin", THICKOUTLINE = "Thick" },
                function() return db.fontOutline end, function(v) db.fontOutline = v; refresh() end,
                { "NONE", "OUTLINE", "THICKOUTLINE" })
            return y - h
        end)
    end

    L:Card("All panels", function(p, y)
        local LSM = LibStub("LibSharedMedia-3.0")
        local _, h = W():Slider(p, "Background", y, 0, 1.0, 0.05, function() return db.opacity end,
            function(v) db.opacity = v; OffBeat:ApplyAppearance() end)
        y = y - h
        local borders = { Flat = "Flat (1px line)", None = "None" }
        for k, v in pairs(LSM:HashTable("border")) do if k ~= "None" then borders[k] = k end end
        _, h = W():Dropdown(p, "Border", y, borders,
            function() return db.borderTexture end, function(v) db.borderTexture = v; OffBeat:ApplyAppearance() end)
        y = y - h
        _, h = W():Toggle(p, "Lock Frames", y, function() return db.locked end, function(v) OffBeat:SetLocked(v) end)
        y = y - h
        return Para(p, y, "Border and background apply to the ability, buff and report panels; "
            .. "a /reload applies a border change everywhere. Unlock to drag panels "
            .. "(or shift-drag while locked, out of combat).")
    end)
end

-- General

navBuilders.general = function(L)
    local db = DB()
    L:Card("Behaviour", function(p, y)
        local _, h = W():Toggle(p, "Lock Frames", y, function() return db.locked end,
            function(v) OffBeat:SetLocked(v) end)
        y = y - h
        _, h = W():Toggle(p, "Combat Report in Chat", y, function() return db.combatReport end,
            function(v) db.combatReport = v end)
        y = y - h
        _, h = W():Toggle(p, "Clear History After Combat", y, function() return db.clearOnCombatEnd end,
            function(v) db.clearOnCombatEnd = v end)
        y = y - h
        _, h = W():Toggle(p, "Debug Logging", y, function() return db.debug end, function(v) db.debug = v end)
        return y - h
    end)

    L:Card("Slash commands", function(p, y)
        return Para(p, y, "/ob — this window\n/ob training — coaching on/off\n/ob report — last training report\n"
            .. "/ob sheet — rotation sheet\n/ob bars [apply] — bar layout\n/ob gear — enchants and gems\n"
            .. "/ob lock — lock / unlock panels")
    end)

    L:Card("Import / export a profile", function(p, y)
        local box = CreateFrame("EditBox", nil, p)
        box:SetSize(p:GetWidth() - 32, 64)
        box:SetPoint("TOPLEFT", p, "TOPLEFT", 16, y - 6)
        box:SetMultiLine(true)
        box:SetAutoFocus(false)
        box:SetFont(FONT, 10, "")
        box:SetTextColor(0.9, 0.9, 0.9)
        local bg = box:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.10, 0.14, 0.9)
        W().FlatBorder(box, 1, 1, 1, 0.15)
        box:SetTextInsets(6, 6, 4, 4)
        box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        y = y - 78
        local _, h = W():Button(p, "Import", y, function()
            local str = box:GetText()
            if not str or str == "" then return end
            local imported, err = OffBeat:ImportProfile(str)
            if not imported then OffBeat:Print("Import failed: " .. (err or "unknown error")); return end
            OffBeat:SaveImportedProfile(imported)
            OffBeat:Print("Imported profile: " .. imported.meta.name)
            Select("general")
        end, "Paste a profile string above", true)
        y = y - h
        _, h = W():Button(p, "Export Current Profile", y, function()
            if not OffBeat.activeProfile then OffBeat:Print("No active profile to export."); return end
            box:SetText(OffBeat:ExportProfile(OffBeat.activeProfile))
            box:HighlightText()
            box:SetFocus()
        end)
        return y - h
    end, true)
end

-- Frame: sidebar, tabs, content

local function ClearContent()
    for _, child in ipairs({ scrollChild:GetChildren() }) do
        child:Hide()
        child:ClearAllPoints()
    end
    W():ResetRowCounters()
end

local function NavButton(parent, index, key)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(SIDEBAR_W - 16, 34)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -(HEADER_H + 10 + (index - 1) * 38))
    btn.hover = btn:CreateTexture(nil, "BACKGROUND")
    btn.hover:SetAllPoints()
    btn.indicator = btn:CreateTexture(nil, "OVERLAY")
    btn.indicator:SetSize(3, 22)
    btn.indicator:SetPoint("LEFT", btn, "LEFT", 0, 0)
    btn.label = btn:CreateFontString(nil, "OVERLAY")
    btn.label:SetFont(FONT, 12, "")
    btn.label:SetPoint("LEFT", btn, "LEFT", 14, 0)
    btn.label:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    btn.label:SetJustifyH("LEFT")
    btn.label:SetWordWrap(false)
    btn.key = key
    btn:SetScript("OnClick", function() Select(key) end)
    btn:SetScript("OnEnter", function() if activeNav ~= key then btn.hover:SetColorTexture(1, 1, 1, 0.04) end end)
    btn:SetScript("OnLeave", function() if activeNav ~= key then btn.hover:SetColorTexture(1, 1, 1, 0) end end)
    return btn
end

local function TabButton()
    local btn = CreateFrame("Button", nil, tabBar)
    btn:SetHeight(TABS_H)
    btn.label = btn:CreateFontString(nil, "OVERLAY")
    btn.label:SetFont(FONT, 11, "")
    btn.label:SetPoint("CENTER", 0, 2)
    btn.underline = btn:CreateTexture(nil, "OVERLAY")
    btn.underline:SetHeight(2)
    btn.underline:SetPoint("BOTTOMLEFT", 6, 0)
    btn.underline:SetPoint("BOTTOMRIGHT", -6, 0)
    btn:SetScript("OnClick", function() Select("spec", btn.key) end)
    btn:SetScript("OnEnter", function() if activeTab ~= btn.key then btn.label:SetTextColor(1, 1, 1, 0.9) end end)
    btn:SetScript("OnLeave", function() if activeTab ~= btn.key then btn.label:SetTextColor(1, 1, 1, 0.55) end end)
    return btn
end

local function VisibleTabs()
    local profile = OffBeat.activeProfile
    local list = {}
    for _, t in ipairs(TABS) do if t.show(profile) then list[#list + 1] = t end end
    return list
end

local function RefreshChrome()
    navButtons[1].label:SetText(SpecName())
    for _, btn in ipairs(navButtons) do
        local on = btn.key == activeNav
        btn.label:SetTextColor(1, 1, 1, on and 1 or 0.65)
        btn.indicator:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], on and 1 or 0)
        btn.hover:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], on and 0.10 or 0)
    end
    for _, b in ipairs(tabButtons) do b:Hide() end
    if activeNav == "spec" then
        tabBar:Show()
        local x = 0
        for i, t in ipairs(VisibleTabs()) do
            local b = tabButtons[i] or TabButton()
            tabButtons[i] = b
            b.key = t.key
            b.label:SetText(t.label)
            b:SetWidth(math.ceil(b.label:GetStringWidth()) + 28)
            b:ClearAllPoints()
            b:SetPoint("BOTTOMLEFT", tabBar, "BOTTOMLEFT", x, 0)
            x = x + b:GetWidth()
            local on = t.key == activeTab
            b.label:SetTextColor(1, 1, 1, on and 1 or 0.55)
            b.underline:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], on and 1 or 0)
            b:Show()
        end
    else
        tabBar:Hide()
    end
    local titles = { panels = "Panels", general = "General" }
    titleText:SetText(activeNav == "spec" and SpecName() or titles[activeNav])
end

Select = function(nav, tab)
    activeNav = nav or activeNav
    if activeNav == "spec" then
        local valid = false
        tab = tab or activeTab
        for _, t in ipairs(VisibleTabs()) do if t.key == tab then valid = true end end
        activeTab = valid and tab or "overview"
    end
    RefreshChrome()
    ClearContent()

    local top = HEADER_H + (activeNav == "spec" and TABS_H + 6 or 0)
    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", SIDEBAR_W + PAD, -top)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -SCROLLBAR - 6, 8)

    local width = PANEL_W - SIDEBAR_W - PAD - SCROLLBAR - 10
    scrollChild:SetWidth(width)
    local L = NewLayout(scrollChild, width)
    local build = activeNav == "spec" and tabBuilders[activeTab] or navBuilders[activeNav]
    build(L)
    scrollChild:SetHeight(L:Height() + PAD)
    scrollFrame:SetVerticalScroll(0)
end

local function CreatePanel()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "OffBeatSettings", UIParent)
    mainFrame:SetSize(PANEL_W, PANEL_H)
    mainFrame:SetPoint("CENTER")
    local bg = mainFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(BG_COLOR))
    -- border in your class color (soft grey if the class can't be read)
    local _, class = UnitClass("player")
    local cc = class and (C_ClassColor and C_ClassColor.GetClassColor(class) or RAID_CLASS_COLORS[class])
    if cc then
        W().FlatBorder(mainFrame, cc.r, cc.g, cc.b, 0.8)
    else
        W().FlatBorder(mainFrame, 1, 1, 1, 0.12)
    end
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetFrameLevel(100)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    mainFrame:Hide()
    tinsert(UISpecialFrames, "OffBeatSettings")

    sidebar = CreateFrame("Frame", nil, mainFrame)
    sidebar:SetPoint("TOPLEFT", 1, -1)
    sidebar:SetPoint("BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(SIDEBAR_W)
    local sbg = sidebar:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints()
    sbg:SetColorTexture(unpack(SIDEBAR_BG))
    local sep = sidebar:CreateTexture(nil, "ARTWORK")
    sep:SetWidth(1)
    sep:SetPoint("TOPRIGHT"); sep:SetPoint("BOTTOMRIGHT")
    sep:SetColorTexture(1, 1, 1, 0.06)

    local brand = sidebar:CreateFontString(nil, "OVERLAY")
    brand:SetFont(FONT, 15, "")
    brand:SetPoint("TOPLEFT", 18, -15)
    brand:SetText("OffBeat")
    brand:SetTextColor(1, 1, 1, 0.95)
    local version = sidebar:CreateFontString(nil, "OVERLAY")
    version:SetFont(FONT, 9, "")
    version:SetPoint("LEFT", brand, "RIGHT", 6, -1)
    version:SetText("v" .. OffBeat.VERSION)
    version:SetTextColor(1, 1, 1, 0.3)

    navButtons[1] = NavButton(sidebar, 1, "spec")
    navButtons[2] = NavButton(sidebar, 2, "panels")
    navButtons[2].label:SetText("Panels")
    navButtons[3] = NavButton(sidebar, 3, "general")
    navButtons[3].label:SetText("General")

    titleText = mainFrame:CreateFontString(nil, "OVERLAY")
    titleText:SetFont(FONT, 15, "")
    titleText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", SIDEBAR_W + PAD, -15)
    titleText:SetTextColor(1, 1, 1, 0.95)

    local close = CreateFrame("Button", nil, mainFrame)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -8, -8)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(FONT, 14, "")
    closeText:SetPoint("CENTER")
    closeText:SetText("x")
    closeText:SetTextColor(1, 1, 1, 0.5)
    close:SetScript("OnClick", function() mainFrame:Hide() end)
    close:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.35, 0.35) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(1, 1, 1, 0.5) end)

    tabBar = CreateFrame("Frame", nil, mainFrame)
    tabBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", SIDEBAR_W + PAD - 6, -HEADER_H + 2)
    tabBar:SetPoint("RIGHT", mainFrame, "RIGHT", -PAD, 0)
    tabBar:SetHeight(TABS_H)
    local tabLine = tabBar:CreateTexture(nil, "ARTWORK")
    tabLine:SetHeight(1)
    tabLine:SetPoint("BOTTOMLEFT", 6, 0); tabLine:SetPoint("BOTTOMRIGHT")
    tabLine:SetColorTexture(1, 1, 1, 0.08)

    scrollFrame = CreateFrame("ScrollFrame", "OffBeatSettingsScroll", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:EnableMouseWheel(true)
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(PANEL_W - SIDEBAR_W - PAD - SCROLLBAR - 10, 1)
    scrollFrame:SetScrollChild(scrollChild)

    return mainFrame
end

-- Public API

function OffBeat:OpenConfig()
    if InCombatLockdown() then
        self:Print("Cannot open settings during combat.")
        return
    end
    local panel = CreatePanel()
    if panel:IsShown() then
        panel:Hide()
        return
    end
    Select(activeNav, activeTab) -- rebuilt each time: the spec may have changed
    panel:Show()
end

-- Register with Blizzard's Settings panel

if Settings and Settings.RegisterCanvasLayoutCategory then
    local redirect = CreateFrame("Frame")
    redirect.name = "OffBeat"

    local btn = CreateFrame("Button", nil, redirect, "UIPanelButtonTemplate")
    btn:SetSize(200, 30)
    btn:SetPoint("CENTER")
    btn:SetText("Open OffBeat Settings")
    btn:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        C_Timer.After(0, function() OffBeat:OpenConfig() end)
    end)

    local category = Settings.RegisterCanvasLayoutCategory(redirect, "OffBeat")
    Settings.RegisterAddOnCategory(category)
end
