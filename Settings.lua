local OffBeat = _G.OffBeat

local PANEL_W = 620
local PANEL_H = 500
local SIDEBAR_W = 160
local HEADER_H = 36
local CONTENT_PAD = 12

local ACCENT = { 0.35, 0.70, 1.0 }
local BG_COLOR = { 0.05, 0.07, 0.09, 0.95 }
local SIDEBAR_BG = { 0.04, 0.05, 0.07, 0.95 }
local FONT = "Fonts\\FRIZQT__.TTF"

local mainFrame, sidebar, scrollFrame, scrollChild
local sidebarButtons = {}
local activeCategory = nil
local pageBuilders = {}

-- Category definitions (order matters for sidebar)

local CATEGORIES = {
    { key = "general",    label = "General" },
    { key = "buffPanel",  label = "Buff Panel",   requires = "trackedBuffs" },
    { key = "rotation",   label = "Rotation",     requires = "rotationSpells" },
    { key = "alerts",     label = "Alerts" },
    { key = "appearance", label = "Appearance" },
    { key = "profiles",   label = "Profiles" },
}

-- Sidebar button

local BUTTON_H = 28
local BUTTON_PAD = 2

local function CreateSidebarButton(parent, catDef, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(SIDEBAR_W - 8, BUTTON_H)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -(HEADER_H + 8 + (index - 1) * (BUTTON_H + BUTTON_PAD)))

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "")
    label:SetPoint("LEFT", btn, "LEFT", 12, 0)
    label:SetText(catDef.label)
    label:SetTextColor(1, 1, 1, 0.7)
    btn.label = label

    local indicator = btn:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(3, BUTTON_H - 4)
    indicator:SetPoint("LEFT", btn, "LEFT", 0, 0)
    indicator:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0)
    btn.indicator = indicator

    local hover = btn:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0)
    btn.hover = hover

    btn:SetScript("OnEnter", function()
        if activeCategory ~= catDef.key then
            hover:SetColorTexture(1, 1, 1, 0.04)
        end
    end)
    btn:SetScript("OnLeave", function()
        if activeCategory ~= catDef.key then
            hover:SetColorTexture(1, 1, 1, 0)
        end
    end)

    btn:SetScript("OnClick", function()
        SelectCategory(catDef.key)
    end)

    btn.catKey = catDef.key
    btn.requires = catDef.requires
    return btn
end

local function UpdateSidebarHighlight()
    for _, btn in ipairs(sidebarButtons) do
        if btn.catKey == activeCategory then
            btn.label:SetTextColor(1, 1, 1, 1)
            btn.indicator:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
            btn.hover:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.08)
        else
            btn.label:SetTextColor(1, 1, 1, 0.7)
            btn.indicator:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0)
            btn.hover:SetColorTexture(1, 1, 1, 0)
        end
    end
end

local function UpdateSidebarVisibility()
    local profile = OffBeat.activeProfile
    local visibleIndex = 0
    for _, btn in ipairs(sidebarButtons) do
        local visible = true
        if btn.requires then
            visible = profile and profile[btn.requires] ~= nil
        end
        if visible then
            btn:Show()
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 4,
                -(HEADER_H + 8 + visibleIndex * (BUTTON_H + BUTTON_PAD)))
            visibleIndex = visibleIndex + 1
        else
            btn:Hide()
        end
    end
end

-- Content area

local function ClearContent()
    if not scrollChild then return end
    for _, child in ipairs({ scrollChild:GetChildren() }) do
        child:Hide()
        child:ClearAllPoints()
    end
    OffBeat.Widgets:ResetRowCounters()
end

function SelectCategory(key)
    if not pageBuilders[key] then return end

    activeCategory = key
    ClearContent()
    UpdateSidebarHighlight()

    local contentW = PANEL_W - SIDEBAR_W - CONTENT_PAD * 2
    scrollChild:SetWidth(contentW)

    local y = -CONTENT_PAD
    y = pageBuilders[key](scrollChild, y)

    scrollChild:SetHeight(math.abs(y) + CONTENT_PAD)
    scrollFrame:SetVerticalScroll(0)
end

-- Main panel creation

local function CreatePanel()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "OffBeatSettings", UIParent, "BackdropTemplate")
    mainFrame:SetSize(PANEL_W, PANEL_H)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    mainFrame:SetBackdropColor(unpack(BG_COLOR))
    mainFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
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

    -- Title bar
    local title = mainFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 14, "")
    title:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", SIDEBAR_W + CONTENT_PAD, -10)
    title:SetText("OffBeat Settings")
    title:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])

    -- Close button
    local close = CreateFrame("Button", nil, mainFrame)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -8, -8)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(FONT, 14, "")
    closeText:SetPoint("CENTER")
    closeText:SetText("x")
    closeText:SetTextColor(1, 1, 1, 0.5)
    close:SetScript("OnClick", function() mainFrame:Hide() end)
    close:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.3, 0.3) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(1, 1, 1, 0.5) end)

    -- Sidebar
    sidebar = CreateFrame("Frame", nil, mainFrame)
    sidebar:SetSize(SIDEBAR_W, PANEL_H)
    sidebar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetColorTexture(unpack(SIDEBAR_BG))

    local sidebarTitle = sidebar:CreateFontString(nil, "OVERLAY")
    sidebarTitle:SetFont(FONT, 13, "")
    sidebarTitle:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 16, -12)
    sidebarTitle:SetText("OffBeat")
    sidebarTitle:SetTextColor(1, 1, 1, 0.9)

    local version = sidebar:CreateFontString(nil, "OVERLAY")
    version:SetFont(FONT, 9, "")
    version:SetPoint("LEFT", sidebarTitle, "RIGHT", 6, -1)
    version:SetText("v" .. OffBeat.VERSION)
    version:SetTextColor(1, 1, 1, 0.3)

    -- Sidebar separator
    local sidebarSep = sidebar:CreateTexture(nil, "ARTWORK")
    sidebarSep:SetSize(1, PANEL_H)
    sidebarSep:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
    sidebarSep:SetColorTexture(1, 1, 1, 0.06)

    -- Sidebar buttons
    for i, catDef in ipairs(CATEGORIES) do
        sidebarButtons[i] = CreateSidebarButton(sidebar, catDef, i)
    end

    -- Scroll frame (content area)
    scrollFrame = CreateFrame("ScrollFrame", "OffBeatSettingsScroll", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", SIDEBAR_W + 1, -(HEADER_H + 2))
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -22, 6)
    scrollFrame:EnableMouseWheel(true)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    local contentW = PANEL_W - SIDEBAR_W - CONTENT_PAD * 2
    scrollChild:SetSize(contentW, 1)
    scrollFrame:SetScrollChild(scrollChild)

    return mainFrame
end

-- Page builders

pageBuilders.general = function(parent, y)
    local W = OffBeat.Widgets
    local db = OffBeat.db.profile
    local _, h

    _, h = W:SectionHeader(parent, "BEHAVIOUR", y); y = y - h
    _, h = W:Toggle(parent, "Lock Frames", y,
        function() return db.locked end,
        function(v) OffBeat:SetLocked(v) end); y = y - h
    _, h = W:Toggle(parent, "Combat Report", y,
        function() return db.combatReport end,
        function(v) db.combatReport = v end); y = y - h
    _, h = W:Toggle(parent, "Clear on Combat End", y,
        function() return db.clearOnCombatEnd end,
        function(v) db.clearOnCombatEnd = v end); y = y - h
    _, h = W:Toggle(parent, "Debug Logging", y,
        function() return db.debug end,
        function(v) db.debug = v end); y = y - h

    return y
end

pageBuilders.buffPanel = function(parent, y)
    local W = OffBeat.Widgets
    local db = OffBeat.db.profile
    local _, h

    _, h = W:SectionHeader(parent, "DISPLAY", y); y = y - h
    _, h = W:Toggle(parent, "Show Panel", y,
        function() return db.buffPanelShown end,
        function(v)
            db.buffPanelShown = v
            local bd = OffBeat:GetModule("BuffDisplay", true)
            if bd and bd:IsEnabled() then
                if v then bd:GetFrame():Show(); bd:Refresh()
                else bd:GetFrame():Hide() end
            end
        end); y = y - h
    _, h = W:Toggle(parent, "Chat Output", y,
        function() return db.chatOutput end,
        function(v) db.chatOutput = v end); y = y - h

    _, h = W:SectionHeader(parent, "TIMELINE", y); y = y - h
    _, h = W:Dropdown(parent, "Auto-show", y,
        { both = "Both", encounter = "Encounters", keystone = "Keystones", never = "Never" },
        function() return db.timelineShow end,
        function(v) db.timelineShow = v end,
        { "both", "encounter", "keystone", "never" }); y = y - h
    _, h = W:Toggle(parent, "Keystone Tracking", y,
        function() return db.keystoneTracking end,
        function(v) db.keystoneTracking = v end); y = y - h
    _, h = W:Slider(parent, "History Size", y, 1, 50, 1,
        function() return db.historySize end,
        function(v) db.historySize = v end); y = y - h

    _, h = W:SectionHeader(parent, "CAST WARNINGS", y); y = y - h
    _, h = W:Toggle(parent, "Enable Cast Warnings", y,
        function() return db.castWarnings end,
        function(v) db.castWarnings = v end); y = y - h

    return y
end

pageBuilders.rotation = function(parent, y)
    local W = OffBeat.Widgets
    local db = OffBeat.db.profile
    local _, h

    _, h = W:SectionHeader(parent, "ABILITY PANEL", y); y = y - h
    _, h = W:Toggle(parent, "Show Panel", y,
        function() return db.rotationShown end,
        function(v)
            db.rotationShown = v
            local rd = OffBeat:GetModule("RotationDisplay", true)
            if rd and rd:IsEnabled() then rd:UpdatePanelVisibility() end
        end); y = y - h
    _, h = W:Toggle(parent, "Only in Combat", y,
        function() return db.rotationCombatOnly end,
        function(v)
            db.rotationCombatOnly = v
            local rd = OffBeat:GetModule("RotationDisplay", true)
            if rd and rd:IsEnabled() then rd:UpdatePanelVisibility() end
        end); y = y - h
    _, h = W:Slider(parent, "History Length", y, 2, 12, 1,
        function() return db.historyCount end,
        function(v) db.historyCount = v; OffBeat:SendMessage("OFFBEAT_HISTORY_UPDATED") end); y = y - h
    _, h = W:Dropdown(parent, "Growth Direction", y,
        { right = "Right", left = "Left", up = "Up", down = "Down" },
        function() return db.growDirection end,
        function(v) db.growDirection = v; OffBeat:SendMessage("OFFBEAT_HISTORY_UPDATED") end,
        { "right", "left", "up", "down" }); y = y - h
    _, h = W:Slider(parent, "Icon Size", y, 20, 64, 2,
        function() return db.iconSize end,
        function(v) db.iconSize = v; OffBeat:SendMessage("OFFBEAT_HISTORY_UPDATED") end); y = y - h

    _, h = W:SectionHeader(parent, "ICON FADING", y); y = y - h
    _, h = W:Slider(parent, "Base Opacity", y, 0.2, 1.0, 0.05,
        function() return db.iconAlpha end,
        function(v) db.iconAlpha = v; OffBeat:SendMessage("OFFBEAT_HISTORY_UPDATED") end); y = y - h
    _, h = W:Slider(parent, "Fade Per Icon", y, 0, 0.3, 0.02,
        function() return db.opacityStep end,
        function(v) db.opacityStep = v; OffBeat:SendMessage("OFFBEAT_HISTORY_UPDATED") end); y = y - h
    _, h = W:Slider(parent, "Fade Floor", y, 0.1, 1.0, 0.05,
        function() return db.minOpacity end,
        function(v) db.minOpacity = v; OffBeat:SendMessage("OFFBEAT_HISTORY_UPDATED") end); y = y - h

    _, h = W:SectionHeader(parent, "KEY COOLDOWN ICON", y); y = y - h
    _, h = W:Toggle(parent, "Show Icon", y,
        function() return db.keyCdIconEnabled end,
        function(v) db.keyCdIconEnabled = v end); y = y - h
    _, h = W:Toggle(parent, "Only in Combat", y,
        function() return db.keyCdCombatOnly end,
        function(v) db.keyCdCombatOnly = v end); y = y - h
    _, h = W:Slider(parent, "Icon Size", y, 24, 80, 2,
        function() return db.keyCdIconSize end,
        function(v) db.keyCdIconSize = v end); y = y - h
    _, h = W:Dropdown(parent, "Glow Style", y,
        { glow = "Pulse", proc = "Proc", ants = "Ants", none = "None" },
        function() return db.keyCdGlowStyle end,
        function(v) db.keyCdGlowStyle = v end,
        { "glow", "proc", "ants", "none" }); y = y - h
    _, h = W:Slider(parent, "Glow Intensity", y, 0.2, 1.0, 0.05,
        function() return db.keyCdGlowIntensity end,
        function(v) db.keyCdGlowIntensity = v end); y = y - h
    _, h = W:ColorPicker(parent, "Glow Color", y,
        function() return OffBeat:GetGlowColor() end,
        function(r, g, b)
            if r then db.keyCdGlowColor = { r = r, g = g, b = b }
            else db.keyCdGlowColor = nil end
        end, "Class Color"); y = y - h

    if C_AssistedCombat then
        _, h = W:SectionHeader(parent, "NEXT SPELL", y); y = y - h
        _, h = W:Toggle(parent, "Show Next Spell", y,
            function() return db.assistedCombat end,
            function(v) db.assistedCombat = v; OffBeat:SendMessage("OFFBEAT_HISTORY_UPDATED") end); y = y - h
        _, h = W:Toggle(parent, "Only in Combat", y,
            function() return db.assistedCombatOnly end,
            function(v)
                db.assistedCombatOnly = v
                local rd = OffBeat:GetModule("RotationDisplay", true)
                if rd and rd:IsEnabled() then rd:UpdateAssistedVisibility() end
            end); y = y - h
        _, h = W:Slider(parent, "Icon Size", y, 24, 80, 2,
            function() return db.assistedIconSize end,
            function(v)
                db.assistedIconSize = v
                local rd = OffBeat:GetModule("RotationDisplay", true)
                if rd and rd:IsEnabled() then rd:RefreshAssisted() end
            end); y = y - h
        _, h = W:Slider(parent, "Keybind Font Size", y, 8, 20, 1,
            function() return db.assistedKeybindSize end,
            function(v)
                db.assistedKeybindSize = v
                local rd = OffBeat:GetModule("RotationDisplay", true)
                if rd and rd:IsEnabled() then rd:RefreshAssisted() end
            end); y = y - h
    end

    _, h = W:SectionHeader(parent, "TIMELINE", y); y = y - h
    _, h = W:Toggle(parent, "Auto-show Timeline", y,
        function() return db.timelineAutoShow end,
        function(v) db.timelineAutoShow = v end); y = y - h

    return y
end

pageBuilders.alerts = function(parent, y)
    local W = OffBeat.Widgets
    local db = OffBeat.db.profile
    local profile = OffBeat.activeProfile
    local _, h

    if profile and profile.rotationSpells then
        _, h = W:SectionHeader(parent, "MISTAKE SOUND", y); y = y - h
        _, h = W:Toggle(parent, "Enable Sound", y,
            function() return db.soundEnabled end,
            function(v) db.soundEnabled = v end); y = y - h
        _, h = W:SoundPicker(parent, "Sound", y, "mistakeSound"); y = y - h
    end

    if profile and profile.keyCooldown then
        _, h = W:SectionHeader(parent, "KEY COOLDOWN", y); y = y - h
        _, h = W:Toggle(parent, "Ready Alert", y,
            function() return db.keyCdAlert end,
            function(v) db.keyCdAlert = v end); y = y - h
        _, h = W:SoundPicker(parent, "Ready Sound", y, "keyCdSound"); y = y - h
        _, h = W:Toggle(parent, "Waste Warning", y,
            function() return db.keyCdWasteAlert end,
            function(v) db.keyCdWasteAlert = v end); y = y - h
        _, h = W:SoundPicker(parent, "Waste Sound", y, "keyCdWasteSound"); y = y - h
    end

    if profile and profile.procTracking and #profile.procTracking > 0 then
        _, h = W:SectionHeader(parent, "PROC EXPIRY", y); y = y - h
        _, h = W:Toggle(parent, "Expire Warning", y,
            function() return db.procExpireAlert end,
            function(v) db.procExpireAlert = v end); y = y - h
        _, h = W:SoundPicker(parent, "Expire Sound", y, "procExpireSound"); y = y - h
    end

    _, h = W:SectionHeader(parent, "COOLDOWN IDLE", y); y = y - h
    _, h = W:Toggle(parent, "Idle Warning", y,
        function() return db.idleCooldownAlert end,
        function(v) db.idleCooldownAlert = v end); y = y - h
    _, h = W:Toggle(parent, "Visual Nag", y,
        function() return db.idleCooldownNag end,
        function(v) db.idleCooldownNag = v end); y = y - h
    _, h = W:Slider(parent, "Delay (seconds)", y, 2, 15, 1,
        function() return db.idleCooldownThreshold end,
        function(v) db.idleCooldownThreshold = v end); y = y - h
    _, h = W:SoundPicker(parent, "Sound", y, "idleCooldownSound"); y = y - h

    _, h = W:SectionHeader(parent, "WARNING FRAME", y); y = y - h
    _, h = W:Slider(parent, "Background Opacity", y, 0, 1.0, 0.05,
        function() return db.warningBgAlpha end,
        function(v) db.warningBgAlpha = v end); y = y - h
    _, h = W:Slider(parent, "Border Opacity", y, 0, 1.0, 0.05,
        function() return db.warningBorderAlpha end,
        function(v) db.warningBorderAlpha = v end); y = y - h

    return y
end

pageBuilders.appearance = function(parent, y)
    local W = OffBeat.Widgets
    local db = OffBeat.db.profile
    local LSM = LibStub("LibSharedMedia-3.0")
    local _, h

    _, h = W:SectionHeader(parent, "PANEL", y); y = y - h
    _, h = W:Slider(parent, "Background Opacity", y, 0, 1.0, 0.05,
        function() return db.opacity end,
        function(v) db.opacity = v; OffBeat:ApplyAppearance() end); y = y - h

    local borders = LSM:HashTable("border")
    _, h = W:Dropdown(parent, "Border", y, borders,
        function() return db.borderTexture end,
        function(v) db.borderTexture = v; OffBeat:ApplyAppearance() end); y = y - h

    if OffBeat.activeProfile and OffBeat.activeProfile.trackedBuffs then
        _, h = W:SectionHeader(parent, "BUFF PANEL", y); y = y - h

        local barTextures = LSM:HashTable("statusbar")
        _, h = W:Dropdown(parent, "Bar Texture", y, barTextures,
            function() return db.barTexture end,
            function(v) db.barTexture = v; OffBeat:SendMessage("OFFBEAT_DISPLAY_REFRESH") end); y = y - h

        local fonts = LSM:HashTable("font")
        _, h = W:Dropdown(parent, "Font", y, fonts,
            function() return db.font end,
            function(v) db.font = v; OffBeat:SendMessage("OFFBEAT_DISPLAY_REFRESH") end); y = y - h
        _, h = W:Slider(parent, "Font Size", y, 8, 16, 1,
            function() return db.fontSize end,
            function(v) db.fontSize = v; OffBeat:SendMessage("OFFBEAT_DISPLAY_REFRESH") end); y = y - h

        _, h = W:Dropdown(parent, "Font Outline", y,
            { NONE = "None", OUTLINE = "Thin", THICKOUTLINE = "Thick" },
            function() return db.fontOutline end,
            function(v) db.fontOutline = v; OffBeat:SendMessage("OFFBEAT_DISPLAY_REFRESH") end,
            { "NONE", "OUTLINE", "THICKOUTLINE" }); y = y - h
    end

    _, h = W:SectionHeader(parent, "ROTATION PANEL", y); y = y - h
    _, h = W:Slider(parent, "Background Opacity", y, 0, 1.0, 0.05,
        function() return db.bgAlpha end,
        function(v) db.bgAlpha = v; OffBeat:ApplyAppearance() end); y = y - h

    return y
end

pageBuilders.profiles = function(parent, y)
    local W = OffBeat.Widgets
    local _, h

    _, h = W:SectionHeader(parent, "ACTIVE PROFILE", y); y = y - h

    local specId = OffBeat.activeSpecId
    local available = specId and OffBeat.profiles[specId]
    if available and #available > 0 then
        local vals, order = {}, {}
        for _, p in ipairs(available) do
            vals[p.meta.name] = p.meta.name
            order[#order + 1] = p.meta.name
        end

        _, h = W:Dropdown(parent, "Profile", y, vals,
            function()
                return OffBeat.activeProfile and OffBeat.activeProfile.meta.name or order[1]
            end,
            function(name) OffBeat:SwitchProfile(name) end,
            order); y = y - h
    else
        local info = parent:CreateFontString(nil, "OVERLAY")
        info:SetFont(FONT, 11, "")
        info:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
        info:SetText("No profiles available for current spec.")
        info:SetTextColor(1, 1, 1, 0.5)
        y = y - 24
    end

    _, h = W:SectionHeader(parent, "IMPORT", y); y = y - h

    local importBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    importBox:SetSize(parent:GetWidth() - 32, 60)
    importBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    importBox:SetMultiLine(true)
    importBox:SetAutoFocus(false)
    importBox:SetFont(FONT, 10, "")
    importBox:SetTextColor(0.9, 0.9, 0.9)
    importBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    importBox:SetBackdropColor(0.08, 0.10, 0.14, 0.9)
    importBox:SetBackdropBorderColor(1, 1, 1, 0.15)
    importBox:SetTextInsets(6, 6, 4, 4)
    importBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    y = y - 68

    local importBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    importBtn:SetSize(80, 24)
    importBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    importBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    importBtn:SetBackdropColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.3)
    importBtn:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.5)
    local importLabel = importBtn:CreateFontString(nil, "OVERLAY")
    importLabel:SetFont(FONT, 11, "")
    importLabel:SetAllPoints()
    importLabel:SetText("Import")
    importLabel:SetTextColor(1, 1, 1, 0.9)
    importBtn:SetScript("OnClick", function()
        local str = importBox:GetText()
        if not str or str == "" then return end
        local profile, err = OffBeat:ImportProfile(str)
        if not profile then
            OffBeat:Print("Import failed: " .. (err or "unknown error"))
            return
        end
        OffBeat:SaveImportedProfile(profile)
        OffBeat:Print("Imported profile: " .. profile.meta.name)
        importBox:SetText("")
        importBox:ClearFocus()
        SelectCategory("profiles")
    end)
    y = y - 32

    _, h = W:SectionHeader(parent, "EXPORT", y); y = y - h

    local exportBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    exportBtn:SetSize(120, 24)
    exportBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    exportBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    exportBtn:SetBackdropColor(0.08, 0.10, 0.14, 0.9)
    exportBtn:SetBackdropBorderColor(1, 1, 1, 0.2)
    local exportLabel = exportBtn:CreateFontString(nil, "OVERLAY")
    exportLabel:SetFont(FONT, 11, "")
    exportLabel:SetAllPoints()
    exportLabel:SetText("Export Current")
    exportLabel:SetTextColor(1, 1, 1, 0.9)
    exportBtn:SetScript("OnClick", function()
        if not OffBeat.activeProfile then
            OffBeat:Print("No active profile to export.")
            return
        end
        local str = OffBeat:ExportProfile(OffBeat.activeProfile)
        importBox:SetText(str)
        importBox:HighlightText()
        importBox:SetFocus()
    end)
    y = y - 32

    return y
end

-- Public API

function OffBeat:OpenConfig()
    if InCombatLockdown() then
        self:Print("Cannot open settings during combat.")
        return
    end

    local panel = CreatePanel()
    UpdateSidebarVisibility()

    if not activeCategory then
        SelectCategory("general")
    end

    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
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
