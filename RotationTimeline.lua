local OffBeat = _G.OffBeat
local RotationTimeline = OffBeat:NewModule("RotationTimeline", "AceEvent-3.0")

local ROW_HEIGHT = 22
local ICON_SIZE = 18
local PADDING = 10
local HEADER_HEIGHT = 22
local DEFAULT_WIDTH = 360
local MIN_WIDTH = 260
local MAX_WIDTH = 600

function RotationTimeline:OnEnable()
    self:RegisterMessage("OFFBEAT_ENCOUNTER_END", "OnEncounterEnd")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "OnLockChanged")
end

function RotationTimeline:OnDisable()
    self:UnregisterAllMessages()
    if self.frame then self.frame:Hide() end
    if self.exportFrame then self.exportFrame:Hide() end
end

function RotationTimeline:OnEncounterEnd(_, encounter)
    if not OffBeat.db.profile.timelineAutoShow then return end
    if encounter.casts then
        self:Show(encounter)
    end
end

function RotationTimeline:OnLockChanged(_, locked)
    if not self.frame then return end
    self.frame.resizeGrip:SetShown(not locked)
    self.frame:SetMovable(not locked)
end

function RotationTimeline:Toggle()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    else
        local enc = OffBeat.state.lastEncounter
        if enc and enc.casts then
            self:Show(enc)
        else
            OffBeat:Print("No encounter data to show.")
        end
    end
end

function RotationTimeline:Show(enc)
    if not enc or not enc.casts or #enc.casts == 0 then return end

    local f = self:GetFrame()
    self.currentEncounter = enc
    self:Render(f, enc)
    f:Show()
end

function RotationTimeline:GetFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "OffBeatRotationTimeline", UIParent, "BackdropTemplate")
    f:SetBackdrop(OffBeat:BuildBackdrop())
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    f:SetSize(DEFAULT_WIDTH, 300)
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
    end)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetPoint("TOPLEFT", PADDING, -PADDING)
    title:SetTextColor(0.6, 0.8, 1.0)
    f.title = title

    local close = CreateFrame("Button", nil, f)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", -PADDING, -PADDING)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeText:SetTextColor(0.85, 0.85, 0.85)
    close:SetScript("OnClick", function() f:Hide() end)
    close:SetScript("OnEnter", function() closeText:SetTextColor(1.0, 0.82, 0.3) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(0.85, 0.85, 0.85) end)

    local export = CreateFrame("Button", nil, f)
    export:SetSize(50, 18)
    export:SetPoint("RIGHT", close, "LEFT", -8, 0)
    local exportText = export:CreateFontString(nil, "OVERLAY")
    exportText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    exportText:SetPoint("CENTER")
    exportText:SetText("Export")
    exportText:SetTextColor(0.85, 0.85, 0.85)
    export:SetScript("OnClick", function() RotationTimeline:ShowExport() end)
    export:SetScript("OnEnter", function() exportText:SetTextColor(1.0, 0.82, 0.3) end)
    export:SetScript("OnLeave", function() exportText:SetTextColor(0.85, 0.85, 0.85) end)

    local scroll = CreateFrame("ScrollFrame", "OffBeatRotationTimelineScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING, -(PADDING + HEADER_HEIGHT + 4))
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(PADDING + 20), PADDING)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(DEFAULT_WIDTH - PADDING * 2 - 20, 1)
    scroll:SetScrollChild(content)
    f.scrollContent = content

    f.rows = {}
    self.frame = f

    local pos = OffBeat.db.profile.timelinePosition
    if pos then
        f:ClearAllPoints()
        f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    end

    return f
end

function RotationTimeline:GetRow(parent, index)
    local f = self.frame
    if f.rows[index] then return f.rows[index] end

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    local timestamp = row:CreateFontString(nil, "OVERLAY")
    timestamp:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    timestamp:SetPoint("LEFT", 0, 0)
    timestamp:SetWidth(42)
    timestamp:SetJustifyH("RIGHT")
    timestamp:SetTextColor(0.5, 0.5, 0.5)
    row.timestamp = timestamp

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", timestamp, "RIGHT", 6, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    name:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    name:SetMaxLines(1)
    row.name = name

    local marker = row:CreateTexture(nil, "OVERLAY")
    marker:SetSize(ROW_HEIGHT, ROW_HEIGHT)
    marker:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    marker:SetColorTexture(0.9, 0.1, 0.1, 0.15)
    row.mistakeMarker = marker

    f.rows[index] = row
    return row
end

function RotationTimeline:Render(f, enc)
    local duration = enc.endTime - enc.startTime
    local mins = math.floor(duration / 60)
    local secs = duration - mins * 60
    local pct = enc.totalCasts > 0
        and (1 - enc.mistakes / enc.totalCasts) * 100 or 100

    f.title:SetText(string.format("OffBeat — %dm %02ds — %.1f%% accuracy",
        mins, secs, pct))

    local content = f.scrollContent

    for _, row in ipairs(f.rows) do row:Hide() end

    for i, cast in ipairs(enc.casts) do
        local row = self:GetRow(content, i)
        local offset = cast.time - enc.startTime

        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", content, "RIGHT", 0, 0)

        local m = math.floor(offset / 60)
        local s = offset - m * 60
        row.timestamp:SetText(string.format("%d:%04.1f", m, s))

        local spellInfo = C_Spell.GetSpellInfo(cast.spellId)
        row.icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")

        local spellName = spellInfo and spellInfo.name or tostring(cast.spellId)
        row.name:SetText(spellName)

        if cast.mistake then
            row.name:SetTextColor(1.0, 0.3, 0.3)
            row.mistakeMarker:Show()
        else
            row.name:SetTextColor(0.9, 0.9, 0.9)
            row.mistakeMarker:Hide()
        end

        row:Show()
    end

    content:SetHeight(#enc.casts * ROW_HEIGHT)
end

-- Export

function RotationTimeline:ShowExport()
    local enc = self.currentEncounter
    if not enc then return end

    local ef = self:GetExportFrame()
    ef.editBox:SetText(self:FormatExport(enc))
    ef:Show()
    ef.editBox:HighlightText()
    ef.editBox:SetFocus()
end

function RotationTimeline:GetExportFrame()
    if self.exportFrame then return self.exportFrame end

    local ef = CreateFrame("Frame", "OffBeatRotationExport", UIParent, "BackdropTemplate")
    ef:SetBackdrop(OffBeat:BuildBackdrop())
    ef:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    ef:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    ef:SetSize(500, 400)
    ef:SetPoint("CENTER")
    ef:SetFrameStrata("DIALOG")
    ef:SetMovable(true)
    ef:EnableMouse(true)
    ef:RegisterForDrag("LeftButton")
    ef:SetScript("OnDragStart", function(self) self:StartMoving() end)
    ef:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local title = ef:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetPoint("TOPLEFT", PADDING, -PADDING)
    title:SetText("OffBeat — Export (Ctrl+A, Ctrl+C to copy)")
    title:SetTextColor(0.6, 0.8, 1.0)

    local close = CreateFrame("Button", nil, ef)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", -PADDING, -PADDING)
    local closeText = close:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeText:SetTextColor(0.85, 0.85, 0.85)
    close:SetScript("OnClick", function() ef:Hide() end)
    close:SetScript("OnEnter", function() closeText:SetTextColor(1.0, 0.82, 0.3) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(0.85, 0.85, 0.85) end)

    local scroll = CreateFrame("ScrollFrame", "OffBeatRotationExportScroll", ef, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", ef, "TOPLEFT", PADDING, -(PADDING + HEADER_HEIGHT + 4))
    scroll:SetPoint("BOTTOMRIGHT", ef, "BOTTOMRIGHT", -(PADDING + 20), PADDING)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    editBox:SetWidth(460)
    editBox:SetTextColor(0.9, 0.9, 0.9)
    editBox:SetScript("OnEscapePressed", function() ef:Hide() end)
    scroll:SetScrollChild(editBox)
    ef.editBox = editBox

    self.exportFrame = ef
    return ef
end

function RotationTimeline:FormatExport(enc)
    local duration = enc.endTime - enc.startTime
    local mins = math.floor(duration / 60)
    local secs = duration - mins * 60
    local pct = enc.totalCasts > 0
        and (1 - enc.mistakes / enc.totalCasts) * 100 or 100

    local lines = {}
    lines[1] = string.format("# OffBeat Export — %dm %02ds — %.1f%% accuracy (%d casts, %d mistakes)",
        mins, secs, pct, enc.totalCasts, enc.mistakes)
    lines[2] = "# time,spell,flag"

    for _, cast in ipairs(enc.casts) do
        local offset = cast.time - enc.startTime
        local spellInfo = C_Spell.GetSpellInfo(cast.spellId)
        local name = spellInfo and spellInfo.name or tostring(cast.spellId)
        local flag = cast.mistake and ("," .. cast.mistake:upper():gsub(" ", "_")) or ""
        lines[#lines + 1] = string.format("%.1f,%s%s", offset, name, flag)
    end

    return table.concat(lines, "\n")
end
