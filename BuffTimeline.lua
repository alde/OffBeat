local OffBeat = _G.OffBeat
local BuffTimeline = OffBeat:NewModule("BuffTimeline", "AceEvent-3.0")

local ROW_HEIGHT = 14
local LABEL_WIDTH = 110
local HEADER_HEIGHT = 18
local NAV_HEIGHT = 18
local NAV_GAP = 4
local PADDING = 10
local SECTION_GAP = 6
local TICK_HEIGHT = 30
local DEFAULT_WIDTH = 440
local MIN_WIDTH = 300
local MAX_WIDTH = 900
local OVERRIDE_GUARD_SECONDS = 2

local NAV_COLOR_NORMAL   = { 0.85, 0.85, 0.85 }
local NAV_COLOR_HOVER    = { 1.00, 0.82, 0.30 }
local NAV_COLOR_DISABLED = { 0.40, 0.40, 0.40 }

function BuffTimeline:OnEnable()
    self:RegisterMessage("OFFBEAT_ENCOUNTER_END", "OnEncounterEnd")
    self:RegisterMessage("OFFBEAT_APPEARANCE_CHANGED", "OnAppearanceChanged")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "OnLockChanged")
end

function BuffTimeline:OnDisable()
    self:UnregisterAllMessages()
end

function BuffTimeline:OnAppearanceChanged()
    if not self.frame then return end
    self.frame:SetBackdrop(OffBeat:BuildBackdrop())
    self.frame:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    self.frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
end

function BuffTimeline:OnLockChanged(_, locked)
    if self.frame then self:ApplyLockState(self.frame) end
end

function BuffTimeline:OnEncounterEnd(_, enc)
    if enc.isKeystone then
        self.viewSource = "keystone"
        self.viewIndex = #(OffBeat.db.profile.keystoneHistory or {})
        self.lastKeystoneAutoShowAt = GetTime()
    else
        if self.lastKeystoneAutoShowAt
            and GetTime() - self.lastKeystoneAutoShowAt < OVERRIDE_GUARD_SECONDS then
            return
        end
        self.viewSource = "history"
        self.viewIndex = #(OffBeat.db.profile.history or {})
    end

    local pref = OffBeat.db.profile.timelineShow
    if pref == "never" then return end

    local isKeystone = enc.isKeystone
    if pref == "both"
        or (pref == "encounter" and not isKeystone)
        or (pref == "keystone" and isKeystone) then
        self:Show(enc)
    end
end

function BuffTimeline:Toggle()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    else
        self:Show()
    end
end

function BuffTimeline:Show(enc)
    if not enc then
        local list = self:GetSourceList()
        if list and #list > 0 then
            self.viewIndex = self.viewIndex or #list
            if self.viewIndex > #list then self.viewIndex = #list end
            enc = list[self.viewIndex]
        end
    end
    if not enc then
        OffBeat:Print("No encounter data to show.")
        return
    end

    local f = self:GetFrame()
    self.currentEncounter = enc
    self:Render(f, enc)
    self:UpdateNav(f)
    self:ApplyLockState(f)
    f:Show()
end

function BuffTimeline:GetSourceList()
    local key = self.viewSource == "keystone" and "keystoneHistory" or "history"
    return OffBeat.db.profile[key]
end

function BuffTimeline:Navigate(delta)
    local list = self:GetSourceList()
    if not list or #list == 0 then return end
    local newIdx = (self.viewIndex or #list) + delta
    newIdx = math.max(1, math.min(newIdx, #list))
    if newIdx == self.viewIndex then return end
    self.viewIndex = newIdx
    self:Show(list[newIdx])
end

function BuffTimeline:JumpToKeystones()
    local list = OffBeat.db.profile.keystoneHistory
    if not list or #list == 0 then return end
    self.viewSource = "keystone"
    self.viewIndex = #list
    self:Show(list[#list])
end

function BuffTimeline:JumpToEncounters()
    local list = OffBeat.db.profile.history
    if not list or #list == 0 then return end
    self.viewSource = "history"
    self.viewIndex = #list
    self:Show(list[#list])
end

function BuffTimeline:UpdateNav(f)
    local list = self:GetSourceList()
    local total = list and #list or 0
    local idx = self.viewIndex or total
    if total == 0 then idx = 0 end
    f.navPos:SetText(string.format("%d / %d", idx, total))
    f.navPrev:SetEnabled(idx > 1)
    f.navNext:SetEnabled(idx < total)
    f.navKeystones:SetEnabled(#(OffBeat.db.profile.keystoneHistory or {}) > 0)
    f.navEncounters:SetEnabled(#(OffBeat.db.profile.history or {}) > 0)
end

function BuffTimeline:ApplyLockState(f)
    local locked = OffBeat.db.profile.locked
    f.closeButton:SetShown(not locked)
    f.resizeGrip:SetShown(not locked)
    f:SetMovable(not locked)
end

function BuffTimeline:GetFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "OffBeatBuffTimeline", UIParent, "BackdropTemplate")
    f:SetBackdrop(OffBeat:BuildBackdrop())
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    f:SetSize(OffBeat.db.profile.timelineWidth or DEFAULT_WIDTH, 300)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not OffBeat.db.profile.locked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        OffBeat.db.profile.timelinePosition = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    f:SetResizable(true)
    f:SetResizeBounds(MIN_WIDTH, 120, MAX_WIDTH, 800)
    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    f.resizeGrip = grip
    grip:SetScript("OnMouseDown", function()
        if not OffBeat.db.profile.locked then f:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        OffBeat.db.profile.timelineWidth = f:GetWidth()
        if BuffTimeline.currentEncounter then
            BuffTimeline:Render(f, BuffTimeline.currentEncounter)
        end
    end)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", PADDING, -PADDING)
    title:SetFont(OffBeat:GetFont(2))
    title:SetTextColor(0.6, 0.8, 1.0)
    f.title = title

    local function makeBtn(label, width)
        local b = CreateFrame("Button", nil, f)
        b:SetSize(width, NAV_HEIGHT)
        local fs = b:CreateFontString(nil, "OVERLAY")
        fs:SetFont(OffBeat:GetFont())
        fs:SetAllPoints(b)
        fs:SetText(label)
        fs:SetTextColor(unpack(NAV_COLOR_NORMAL))
        b:SetFontString(fs)
        b.label = fs
        b:SetScript("OnEnter", function(self)
            if self:IsEnabled() then self.label:SetTextColor(unpack(NAV_COLOR_HOVER)) end
        end)
        b:SetScript("OnLeave", function(self)
            self.label:SetTextColor(unpack(self:IsEnabled() and NAV_COLOR_NORMAL or NAV_COLOR_DISABLED))
        end)
        b:SetScript("OnEnable", function(self) self.label:SetTextColor(unpack(NAV_COLOR_NORMAL)) end)
        b:SetScript("OnDisable", function(self) self.label:SetTextColor(unpack(NAV_COLOR_DISABLED)) end)
        return b
    end

    local prevBtn = makeBtn("<", 14)
    prevBtn:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING, -(PADDING + HEADER_HEIGHT))
    prevBtn:SetScript("OnClick", function() BuffTimeline:Navigate(-1) end)
    f.navPrev = prevBtn

    local navPos = f:CreateFontString(nil, "OVERLAY")
    navPos:SetFont(OffBeat:GetFont())
    navPos:SetPoint("LEFT", prevBtn, "RIGHT", 6, 0)
    navPos:SetTextColor(0.65, 0.65, 0.65)
    navPos:SetText("0 / 0")
    f.navPos = navPos

    local nextBtn = makeBtn(">", 14)
    nextBtn:SetPoint("LEFT", navPos, "RIGHT", 6, 0)
    nextBtn:SetScript("OnClick", function() BuffTimeline:Navigate(1) end)
    f.navNext = nextBtn

    local sep = f:CreateFontString(nil, "OVERLAY")
    sep:SetFont(OffBeat:GetFont())
    sep:SetPoint("LEFT", nextBtn, "RIGHT", 10, 0)
    sep:SetTextColor(0.4, 0.4, 0.4)
    sep:SetText("|")

    local keystonesBtn = makeBtn("Keystones", 64)
    keystonesBtn:SetPoint("LEFT", sep, "RIGHT", 10, 0)
    keystonesBtn:SetScript("OnClick", function() BuffTimeline:JumpToKeystones() end)
    f.navKeystones = keystonesBtn

    local encountersBtn = makeBtn("Encounters", 70)
    encountersBtn:SetPoint("LEFT", keystonesBtn, "RIGHT", 12, 0)
    encountersBtn:SetScript("OnClick", function() BuffTimeline:JumpToEncounters() end)
    f.navEncounters = encountersBtn

    local close = CreateFrame("Button", nil, f)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, -PADDING)
    close:EnableMouse(true)
    close:RegisterForClicks("LeftButtonUp")
    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(OffBeat:GetFont(1))
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeText:SetTextColor(unpack(NAV_COLOR_NORMAL))
    close:SetScript("OnClick", function() f:Hide() end)
    close:SetScript("OnEnter", function() closeText:SetTextColor(unpack(NAV_COLOR_HOVER)) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(unpack(NAV_COLOR_NORMAL)) end)
    f.closeButton = close

    local function syncClose()
        if not OffBeat.db.profile.locked then return end
        close:SetShown(f:IsMouseOver() or close:IsMouseOver())
    end
    f:SetScript("OnEnter", syncClose)
    f:SetScript("OnLeave", syncClose)
    close:HookScript("OnEnter", syncClose)
    close:HookScript("OnLeave", syncClose)

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT",
        PADDING, -(PADDING + HEADER_HEIGHT + NAV_HEIGHT + NAV_GAP))
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, PADDING)
    f.content:SetClipsChildren(true)

    f.elements = {}
    self.frame = f

    local pos = OffBeat.db.profile.timelinePosition
    if pos then
        f:ClearAllPoints()
        f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    return f
end

function BuffTimeline:Render(f, enc)
    for i = 1, #f.elements do f.elements[i]:Hide() end
    for i = #f.elements, 1, -1 do f.elements[i] = nil end

    local duration = enc.endTime - enc.startTime
    if duration <= 0 then return end

    f.title:SetFont(OffBeat:GetFont(2))
    local mins = math.floor(duration / 60)
    local secs = duration - mins * 60
    local titleLabel
    if enc.isKeystone then
        titleLabel = enc.keystoneName and enc.keystoneLevel
            and string.format("Keystone — %s +%d", enc.keystoneName, enc.keystoneLevel)
            or "Keystone"
    else
        titleLabel = "Encounter"
    end
    f.title:SetText(string.format("OffBeat — %s (%dm %02ds)", titleLabel, mins, secs))

    local barWidth = f:GetWidth() - LABEL_WIDTH - PADDING * 2
    local yOffset, elementIdx = 0, 0

    local buffs = OffBeat:GetModule("Buffs", true)
    local sortedSpells = buffs and buffs:GetSortedSpells() or {}

    for _, spellId in ipairs(sortedSpells) do
        if enc.uptimes[spellId] then
            yOffset, elementIdx = self:RenderSpellSection(
                f.content, enc, spellId, barWidth, duration, yOffset, elementIdx)
        end
    end

    yOffset = yOffset - 4
    self:RenderTimeAxis(f.content, yOffset, duration, elementIdx, barWidth)

    local totalHeight = -(yOffset - TICK_HEIGHT)
        + PADDING * 2 + HEADER_HEIGHT + NAV_HEIGHT + NAV_GAP
    f:SetHeight(math.max(totalHeight, 120))
end

function BuffTimeline:RenderSpellSection(content, enc, spellId, barWidth, duration, yOffset, elementIdx)
    local buffs = OffBeat:GetModule("Buffs")
    local spellInfo = buffs:GetTrackedBuff(spellId)
    if not spellInfo then return yOffset, elementIdx end

    local encounters = OffBeat:GetModule("Encounters")
    local core = OffBeat:GetModule("Core")
    local uptime = encounters:CalcUptime(enc, spellId)
    local color = spellInfo.color or { 0.7, 0.7, 0.7 }

    local headerText
    if enc.isKeystone then
        headerText = string.format("%s (%.1f%% overall / %.1f%% combat)",
            spellInfo.name, uptime, encounters:CalcCombatUptime(enc, spellId))
    else
        headerText = string.format("%s (%.1f%%)", spellInfo.name, uptime)
    end

    elementIdx = elementIdx + 1
    local header = self:GetFontString(content, elementIdx)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    header:SetFont(OffBeat:GetFont(1))
    header:SetText(headerText)
    header:SetTextColor(color[1], color[2], color[3])
    header:Show()
    yOffset = yOffset - HEADER_HEIGHT

    local sortedTargets = {}
    for guid, data in pairs(enc.uptimes[spellId]) do
        sortedTargets[#sortedTargets + 1] = { guid = guid, data = data }
    end
    table.sort(sortedTargets, function(a, b) return a.data.name < b.data.name end)

    local barTexture = OffBeat:GetBarTexture()

    for _, entry in ipairs(sortedTargets) do
        local class = entry.data.class or core:GetClass(entry.guid)

        elementIdx = elementIdx + 1
        local labelBg = self:GetTexture(content, elementIdx)
        labelBg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        labelBg:SetSize(LABEL_WIDTH, ROW_HEIGHT)
        labelBg:SetColorTexture(0.05, 0.05, 0.05, OffBeat.db.profile.opacity)
        labelBg:Show()

        elementIdx = elementIdx + 1
        local label = self:GetFontString(content, elementIdx)
        label:SetPoint("TOPLEFT", content, "TOPLEFT", 4, yOffset)
        label:SetFont(OffBeat:GetFont())
        label:SetWidth(LABEL_WIDTH - 8)
        label:SetWordWrap(false)
        label:SetMaxLines(1)
        label:SetText(entry.data.name or core:GetName(entry.guid))
        local cc = RAID_CLASS_COLORS[class]
        label:SetTextColor(cc and cc.r or 0.8, cc and cc.g or 0.8, cc and cc.b or 0.8)
        label:Show()

        elementIdx = elementIdx + 1
        local bg = self:GetTexture(content, elementIdx)
        bg:SetPoint("TOPLEFT", content, "TOPLEFT", LABEL_WIDTH, yOffset - 1)
        bg:SetSize(barWidth, ROW_HEIGHT - 2)
        bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
        bg:Show()

        for _, iv in ipairs(entry.data.intervals) do
            local x = LABEL_WIDTH + (iv.start / duration) * barWidth
            local w = math.max(1, ((iv.stop or duration) - iv.start) / duration * barWidth)

            elementIdx = elementIdx + 1
            local seg = self:GetTexture(content, elementIdx)
            seg:SetPoint("TOPLEFT", content, "TOPLEFT", x, yOffset - 1)
            seg:SetSize(w, ROW_HEIGHT - 2)
            seg:SetTexture(barTexture)
            seg:SetVertexColor(color[1], color[2], color[3], 0.8)
            seg:Show()
        end

        yOffset = yOffset - ROW_HEIGHT
    end

    return yOffset - SECTION_GAP, elementIdx
end

function BuffTimeline:RenderTimeAxis(content, yOffset, duration, startIdx, barWidth)
    local idx = startIdx
    local tickInterval
    if duration <= 30 then tickInterval = 5
    elseif duration <= 120 then tickInterval = 15
    elseif duration <= 300 then tickInterval = 30
    else tickInterval = 60 end

    idx = idx + 1
    local line = self:GetTexture(content, idx)
    line:SetPoint("TOPLEFT", content, "TOPLEFT", LABEL_WIDTH, yOffset)
    line:SetSize(barWidth, 1)
    line:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    line:Show()

    local t = 0
    while t <= duration do
        local x = LABEL_WIDTH + (t / duration) * barWidth

        idx = idx + 1
        local tick = self:GetTexture(content, idx)
        tick:SetPoint("TOPLEFT", content, "TOPLEFT", x, yOffset)
        tick:SetSize(1, 6)
        tick:SetColorTexture(0.4, 0.4, 0.4, 0.6)
        tick:Show()

        idx = idx + 1
        local label = self:GetFontString(content, idx)
        label:SetPoint("TOP", content, "TOPLEFT", x, yOffset - 8)
        label:SetFont(OffBeat:GetFont(-1))
        label:SetTextColor(0.5, 0.5, 0.5)
        if t < 60 then
            label:SetText(string.format("%ds", t))
        else
            label:SetText(string.format("%dm", t / 60))
        end
        label:Show()

        t = t + tickInterval
    end
end

function BuffTimeline:GetFontString(parent, index)
    local key = "fs" .. index
    local f = self.frame
    if not f.elements[key] then
        f.elements[key] = parent:CreateFontString(nil, "OVERLAY")
    end
    f.elements[#f.elements + 1] = f.elements[key]
    return f.elements[key]
end

function BuffTimeline:GetTexture(parent, index)
    local key = "tx" .. index
    local f = self.frame
    if not f.elements[key] then
        f.elements[key] = parent:CreateTexture(nil, "ARTWORK")
    end
    f.elements[#f.elements + 1] = f.elements[key]
    return f.elements[key]
end

function OffBeat:ToggleTimeline()
    local bt = self:GetModule("BuffTimeline", true)
    if bt and bt:IsEnabled() then
        bt:Toggle()
        return
    end
    local rt = self:GetModule("RotationTimeline", true)
    if rt and rt:IsEnabled() then
        rt:Toggle()
    end
end
