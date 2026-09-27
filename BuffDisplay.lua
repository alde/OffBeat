local OffBeat = _G.OffBeat
local BuffDisplay = OffBeat:NewModule("BuffDisplay", "AceEvent-3.0")

local PANEL_WIDTH = 220
local ROW_HEIGHT = 16
local BAR_HEIGHT = 12
local SECTION_PADDING = 4
local HEADER_HEIGHT = 20
local PADDING = 8

local function ClassColor(class)
    local c = RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 0.8, 0.8, 0.8
end

function BuffDisplay:OnEnable()
    self:RegisterMessage("OFFBEAT_BUFFS_UPDATED", "Refresh")
    self:RegisterMessage("OFFBEAT_DISPLAY_REFRESH", "Refresh")
    self:RegisterMessage("OFFBEAT_ROSTER_UPDATED", "Refresh")
    self:RegisterMessage("OFFBEAT_APPEARANCE_CHANGED", "OnAppearanceChanged")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "OnLockChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function BuffDisplay:OnDisable()
    self:UnregisterAllMessages()
    if self.frame then self.frame:Hide() end
end

function BuffDisplay:OnAppearanceChanged()
    if not self.frame then return end
    self.frame:SetBackdrop(OffBeat:BuildBackdrop())
    self.frame:SetBackdropColor(0.05, 0.05, 0.05, OffBeat.db.profile.opacity)
    self.frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
end

function BuffDisplay:OnLockChanged(_, locked)
    if self.frame and self.frame.resizeGrip then
        self.frame.resizeGrip:SetShown(not locked)
    end
end

function BuffDisplay:GetFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "OffBeatBuffPanel", UIParent, "BackdropTemplate")
    f:SetBackdrop(OffBeat:BuildBackdrop())
    f:SetBackdropColor(0.05, 0.05, 0.05, OffBeat.db.profile.opacity)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    f:SetSize(PANEL_WIDTH, 100)
    f:SetFrameStrata("LOW")
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
        OffBeat.db.profile.buffPanelPosition = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    f:SetResizable(true)
    f:SetResizeBounds(150, 60, 500, 600)
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
        OffBeat.db.profile.buffPanelWidth = f:GetWidth()
    end)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", PADDING, -PADDING)
    title:SetFont(OffBeat:GetFont(1))
    title:SetText("OffBeat")
    title:SetTextColor(0.6, 0.8, 1.0)
    f.title = title

    f.rows = {}
    self.frame = f
    self:RestorePosition()

    local savedWidth = OffBeat.db.profile.buffPanelWidth
    if savedWidth then f:SetWidth(savedWidth) end
    f.resizeGrip:SetShown(not OffBeat.db.profile.locked)

    return f
end

function BuffDisplay:RestorePosition()
    local pos = OffBeat.db.profile.buffPanelPosition
    if pos then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
end

function BuffDisplay:Toggle()
    local f = self:GetFrame()
    if f:IsShown() then
        f:Hide()
        OffBeat.db.profile.buffPanelShown = false
    else
        f:Show()
        OffBeat.db.profile.buffPanelShown = true
        self:Refresh()
    end
end

function BuffDisplay:Refresh()
    local f = self:GetFrame()
    if not f:IsShown() then return end

    local fontPath, fontSize, fontFlags = OffBeat:GetFont()
    local barTex = OffBeat:GetBarTexture()
    for _, row in ipairs(f.rows) do
        row:Hide()
        row.label:SetFont(fontPath, fontSize, fontFlags)
        row.duration:SetFont(fontPath, fontSize, fontFlags)
        row.bar:SetStatusBarTexture(barTex)
    end
    f.title:SetFont(OffBeat:GetFont(1))

    local buffs = OffBeat:GetModule("Buffs", true)
    if not buffs then return end

    local sortedSpells = buffs:GetSortedSpells()
    local yOffset = -(HEADER_HEIGHT + PADDING)
    local rowIndex = 0
    local now = GetTime()

    for _, spellId in ipairs(sortedSpells) do
        yOffset, rowIndex = self:RenderSpellSection(f, spellId, yOffset, rowIndex, now)
    end
    yOffset, rowIndex = self:RenderAlerts(f, yOffset, rowIndex)

    f:SetHeight(math.max(-yOffset + PADDING, HEADER_HEIGHT + PADDING * 2))
end

function BuffDisplay:RenderSpellSection(f, spellId, yOffset, rowIndex, now)
    local buffs = OffBeat:GetModule("Buffs")
    local spellInfo = buffs:GetTrackedBuff(spellId)
    if not spellInfo then return yOffset, rowIndex end

    local targets = self:GetTargetsForSpell(spellId)
    if #targets == 0 then return yOffset, rowIndex end

    local encounters = OffBeat:GetModule("Encounters", true)
    local core = OffBeat:GetModule("Core")
    local color = spellInfo.color or { 0.7, 0.7, 0.7 }

    rowIndex = rowIndex + 1
    local header = self:GetRow(f, rowIndex)
    local uptimeText = ""
    if encounters and encounters:IsActive() then
        local pct = encounters:GetCurrentUptime(spellId)
        if pct then uptimeText = string.format(" (%.1f%%)", pct) end
    end
    header.label:SetText(spellInfo.name .. uptimeText)
    header.label:SetTextColor(color[1], color[2], color[3])
    header.bar:Hide()
    header.duration:SetText("")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING, yOffset)
    header:Show()
    yOffset = yOffset - ROW_HEIGHT

    for _, target in ipairs(targets) do
        rowIndex = rowIndex + 1
        local row = self:GetRow(f, rowIndex)
        local r, g, b = ClassColor(core:GetClass(target.guid))

        row.label:SetText("  " .. core:GetName(target.guid))
        row.label:SetTextColor(r, g, b)

        local remaining = target.expirationTime - now
        local fraction = target.duration > 0
            and math.max(0, math.min(1, remaining / target.duration)) or 0

        row.bar:SetMinMaxValues(0, 1)
        row.bar:SetValue(fraction)
        row.bar:SetStatusBarColor(color[1], color[2], color[3], 0.7)
        row.bar:Show()
        row.duration:SetText(remaining > 0 and string.format("%.0fs", remaining) or "0s")
        row:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING, yOffset)
        row:Show()
        yOffset = yOffset - ROW_HEIGHT
    end

    return yOffset - SECTION_PADDING, rowIndex
end

function BuffDisplay:RenderAlerts(f, yOffset, rowIndex)
    if not IsInGroup() then return yOffset, rowIndex end

    for _, alert in ipairs(self:GetMissingBuffAlerts()) do
        rowIndex = rowIndex + 1
        local row = self:GetRow(f, rowIndex)
        row.label:SetText(alert)
        row.label:SetTextColor(1.0, 0.4, 0.4)
        row.bar:Hide()
        row.duration:SetText("")
        row:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING, yOffset)
        row:Show()
        yOffset = yOffset - ROW_HEIGHT
    end
    return yOffset, rowIndex
end

function BuffDisplay:GetMissingBuffAlerts()
    local alerts_list = {}
    local profile = OffBeat.activeProfile
    if not profile or not profile.alerts then return alerts_list end

    local buffState = OffBeat.state.buffs

    for _, alert in ipairs(profile.alerts) do
        if alert.type == "missing_buff" then
            local found = false
            for _, spells in pairs(buffState) do
                if spells[alert.spellId] then found = true; break end
            end
            if not found then
                if alert.condition == "group_has_healer" then
                    if self:GroupHasHealer() then
                        alerts_list[#alerts_list + 1] = "! " .. (alert.name or tostring(alert.spellId))
                    end
                else
                    alerts_list[#alerts_list + 1] = "! " .. (alert.name or tostring(alert.spellId))
                end
            end
        end
    end

    return alerts_list
end

function BuffDisplay:GroupHasHealer()
    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or (GetNumGroupMembers() - 1)
    for i = 1, count do
        if UnitGroupRolesAssigned(prefix .. i) == "HEALER" then
            return true
        end
    end
    return false
end

function BuffDisplay:GetTargetsForSpell(spellId)
    local targets = {}
    for guid, spells in pairs(OffBeat.state.buffs) do
        local aura = spells[spellId]
        if aura then
            targets[#targets + 1] = {
                guid = guid,
                expirationTime = aura.expirationTime,
                duration = aura.duration,
            }
        end
    end
    table.sort(targets, function(a, b)
        return a.expirationTime > b.expirationTime
    end)
    return targets
end

function BuffDisplay:GetRow(parent, index)
    if parent.rows[index] then return parent.rows[index] end

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("RIGHT", parent, "RIGHT", -PADDING, 0)

    local fontPath, fontSize, fontFlags = OffBeat:GetFont()

    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, fontSize, fontFlags)
    label:SetPoint("LEFT", 0, 0)
    label:SetPoint("RIGHT", row, "CENTER", -10, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetMaxLines(1)
    row.label = label

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("LEFT", row, "CENTER", -6, 0)
    bar:SetPoint("RIGHT", row, "RIGHT", -30, 0)
    bar:SetHeight(BAR_HEIGHT)
    bar:SetStatusBarTexture(OffBeat:GetBarTexture())
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.6)
    row.bar = bar

    local dur = row:CreateFontString(nil, "OVERLAY")
    dur:SetFont(fontPath, fontSize, fontFlags)
    dur:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    dur:SetWidth(28)
    dur:SetJustifyH("RIGHT")
    row.duration = dur

    parent.rows[index] = row
    return row
end

function BuffDisplay:PLAYER_ENTERING_WORLD()
    if OffBeat.db.profile.buffPanelShown then
        self:GetFrame():Show()
        self:Refresh()
    end
end

-- Wire up addon-level toggle
function OffBeat:ToggleDisplay()
    local bd = self:GetModule("BuffDisplay", true)
    if bd and bd:IsEnabled() then
        bd:Toggle()
        return
    end
    local rd = self:GetModule("RotationDisplay", true)
    if rd and rd:IsEnabled() then
        rd:Toggle()
    end
end
