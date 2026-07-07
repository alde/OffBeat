local OffBeat = _G.OffBeat

local W = {}
OffBeat.Widgets = W

local ROW_H = 32
local SECTION_H = 30
local LABEL_PAD = 16
local CONTROL_PAD = 16
local ACCENT = { 0.35, 0.70, 1.0 }
local TEXT_DIM = { 1, 1, 1, 0.40 }
local BG_DARK = { 0.06, 0.08, 0.10 }
local FONT = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 11

local rowCounters = {}

local function RowBg(frame, parent)
    rowCounters[parent] = (rowCounters[parent] or 0) + 1
    if rowCounters[parent] % 2 == 0 then
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.15)
    end
end

local function MakeLabel(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, FONT_SIZE, "")
    fs:SetPoint("LEFT", parent, "LEFT", LABEL_PAD, 0)
    fs:SetTextColor(1, 1, 1, 0.9)
    fs:SetText(text)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs:SetMaxLines(1)
    return fs
end

local function MakeRow(parent, y, height)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(parent:GetWidth(), height or ROW_H)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    RowBg(f, parent)
    return f
end

-- Section header

function W:SectionHeader(parent, text, y)
    rowCounters[parent] = 0

    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(parent:GetWidth(), SECTION_H)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

    local label = f:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 10, "")
    label:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LABEL_PAD, 6)
    label:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], TEXT_DIM[4])
    label:SetText(text)

    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LABEL_PAD, 0)
    sep:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -LABEL_PAD, 0)
    sep:SetHeight(1)
    sep:SetColorTexture(1, 1, 1, 0.06)

    return f, SECTION_H
end

-- Toggle switch

function W:Toggle(parent, text, y, getValue, setValue, tooltip)
    local f = MakeRow(parent, y)
    MakeLabel(f, text)

    local TRACK_W, TRACK_H = 34, 18
    local KNOB_PAD = 2
    local KNOB_SZ = TRACK_H - KNOB_PAD * 2

    local track = CreateFrame("Button", nil, f)
    track:SetSize(TRACK_W, TRACK_H)
    track:SetPoint("RIGHT", f, "RIGHT", -CONTROL_PAD, 0)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0.25, 0.25, 0.25, 0.65)
    track.bg = trackBg

    local knob = track:CreateTexture(nil, "OVERLAY")
    knob:SetSize(KNOB_SZ, KNOB_SZ)
    track.knob = knob

    local function Snap()
        local on = getValue()
        if on then
            trackBg:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.75)
            knob:SetColorTexture(1, 1, 1, 1)
            knob:SetPoint("LEFT", track, "LEFT", TRACK_W - KNOB_SZ - KNOB_PAD, 0)
        else
            trackBg:SetColorTexture(0.25, 0.25, 0.25, 0.65)
            knob:SetColorTexture(1, 1, 1, 0.5)
            knob:SetPoint("LEFT", track, "LEFT", KNOB_PAD, 0)
        end
    end

    track:SetScript("OnClick", function()
        setValue(not getValue())
        Snap()
    end)

    Snap()
    f._refresh = Snap
    return f, ROW_H
end

-- Slider

function W:Slider(parent, text, y, minVal, maxVal, step, getValue, setValue, tooltip)
    local f = MakeRow(parent, y)
    MakeLabel(f, text)

    local TRACK_W, TRACK_H = 140, 4
    local THUMB_SZ = 12

    local valBox = f:CreateFontString(nil, "OVERLAY")
    valBox:SetFont(FONT, FONT_SIZE, "")
    valBox:SetPoint("RIGHT", f, "RIGHT", -CONTROL_PAD, 0)
    valBox:SetWidth(36)
    valBox:SetJustifyH("RIGHT")
    valBox:SetTextColor(1, 1, 1, 0.8)

    local trackFrame = CreateFrame("Frame", nil, f)
    trackFrame:SetSize(TRACK_W, TRACK_H + THUMB_SZ)
    trackFrame:SetPoint("RIGHT", valBox, "LEFT", -8, 0)

    local trackBg = trackFrame:CreateTexture(nil, "BACKGROUND")
    trackBg:SetPoint("LEFT", trackFrame, "LEFT", 0, 0)
    trackBg:SetSize(TRACK_W, TRACK_H)
    trackBg:SetColorTexture(1, 1, 1, 0.12)

    local fill = trackFrame:CreateTexture(nil, "BORDER")
    fill:SetPoint("LEFT", trackBg, "LEFT", 0, 0)
    fill:SetHeight(TRACK_H)
    fill:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.75)

    local thumb = CreateFrame("Button", nil, trackFrame)
    thumb:SetSize(THUMB_SZ, THUMB_SZ)
    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)

    local fmtStr = step >= 1 and "%d" or (step < 0.1 and "%.2f" or "%.1f")

    local function Snap()
        local val = getValue()
        local ratio = math.max(0, math.min(1, (val - minVal) / (maxVal - minVal)))
        fill:SetWidth(math.max(1, TRACK_W * ratio))
        thumb:SetPoint("CENTER", trackBg, "LEFT", TRACK_W * ratio, 0)
        valBox:SetText(string.format(fmtStr, val))
    end

    local dragging = false

    trackFrame:EnableMouse(true)
    thumb:EnableMouse(true)

    local function StartDrag()
        dragging = true
    end

    local function StopDrag()
        if not dragging then return end
        dragging = false
    end

    local function OnDrag()
        if not dragging then return end
        local cx = GetCursorPosition()
        local scale = trackFrame:GetEffectiveScale()
        local left = trackBg:GetLeft() * scale
        local right = trackBg:GetRight() * scale
        local ratio = math.max(0, math.min(1, (cx - left) / (right - left)))
        local raw = minVal + ratio * (maxVal - minVal)
        local snapped = math.floor(raw / step + 0.5) * step
        snapped = math.max(minVal, math.min(maxVal, snapped))
        setValue(snapped)
        Snap()
    end

    trackFrame:SetScript("OnMouseDown", function() StartDrag(); OnDrag() end)
    trackFrame:SetScript("OnMouseUp", StopDrag)
    thumb:SetScript("OnMouseDown", StartDrag)
    thumb:SetScript("OnMouseUp", StopDrag)
    f:SetScript("OnUpdate", function()
        if dragging then OnDrag() end
    end)

    Snap()
    f._refresh = Snap
    return f, ROW_H
end

-- Dropdown

function W:Dropdown(parent, text, y, values, getValue, setValue, order)
    local f = MakeRow(parent, y)
    MakeLabel(f, text)

    local DD_W, DD_H = 160, 24

    local btn = CreateFrame("Button", nil, f)
    btn:SetSize(DD_W, DD_H)
    btn:SetPoint("RIGHT", f, "RIGHT", -CONTROL_PAD, 0)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.10, 0.14, 0.9)

    local border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    border:SetBackdropBorderColor(1, 1, 1, 0.15)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, FONT_SIZE, "")
    label:SetPoint("LEFT", btn, "LEFT", 8, 0)
    label:SetPoint("RIGHT", btn, "RIGHT", -20, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetMaxLines(1)
    label:SetTextColor(1, 1, 1, 0.9)

    local arrow = btn:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(FONT, 10, "")
    arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    arrow:SetText("v")
    arrow:SetTextColor(1, 1, 1, 0.5)

    local displayOrder = order or {}
    if #displayOrder == 0 then
        for k in pairs(values) do displayOrder[#displayOrder + 1] = k end
        table.sort(displayOrder)
    end

    local function UpdateLabel()
        local key = getValue()
        label:SetText(values[key] or tostring(key))
    end

    local menu

    local function BuildMenu()
        menu = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        menu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        menu:SetBackdropColor(0.08, 0.10, 0.14, 0.95)
        menu:SetBackdropBorderColor(1, 1, 1, 0.2)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetWidth(DD_W)
        menu:SetClampedToScreen(true)

        local itemH = 22
        local totalH = #displayOrder * itemH + 4
        menu:SetHeight(math.min(totalH, 200))
        menu:SetPoint("TOP", btn, "BOTTOM", 0, -2)

        for i, key in ipairs(displayOrder) do
            local item = CreateFrame("Button", nil, menu)
            item:SetSize(DD_W - 4, itemH)
            item:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, -(2 + (i - 1) * itemH))

            local itemLabel = item:CreateFontString(nil, "OVERLAY")
            itemLabel:SetFont(FONT, FONT_SIZE, "")
            itemLabel:SetAllPoints()
            itemLabel:SetJustifyH("LEFT")
            itemLabel:SetText("  " .. (values[key] or key))
            itemLabel:SetTextColor(1, 1, 1, 0.85)

            item:SetScript("OnEnter", function()
                itemLabel:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
            end)
            item:SetScript("OnLeave", function()
                itemLabel:SetTextColor(1, 1, 1, 0.85)
            end)
            item:SetScript("OnClick", function()
                setValue(key)
                UpdateLabel()
                menu:Hide()
            end)
        end

        menu:Hide()
    end

    btn:SetScript("OnClick", function()
        if not menu then BuildMenu() end
        if menu:IsShown() then menu:Hide() else menu:Show() end
    end)

    btn:SetScript("OnEnter", function() border:SetBackdropBorderColor(1, 1, 1, 0.30) end)
    btn:SetScript("OnLeave", function() border:SetBackdropBorderColor(1, 1, 1, 0.15) end)

    UpdateLabel()
    f._refresh = UpdateLabel
    return f, ROW_H
end

-- Color picker (swatch that opens Blizzard's ColorPickerFrame)

function W:ColorPicker(parent, text, y, getValue, setValue, resetLabel)
    local f = MakeRow(parent, y)
    MakeLabel(f, text)

    local SWATCH_SZ = 18

    local swatch = CreateFrame("Button", nil, f)
    swatch:SetSize(SWATCH_SZ, SWATCH_SZ)
    swatch:SetPoint("RIGHT", f, "RIGHT", -CONTROL_PAD, 0)

    local swatchTex = swatch:CreateTexture(nil, "OVERLAY")
    swatchTex:SetAllPoints()

    local swatchBorder = swatch:CreateTexture(nil, "BORDER")
    swatchBorder:SetPoint("TOPLEFT", -1, 1)
    swatchBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    swatchBorder:SetColorTexture(1, 1, 1, 0.3)

    local function Snap()
        local r, g, b = getValue()
        swatchTex:SetColorTexture(r, g, b)
    end

    swatch:SetScript("OnClick", function()
        local r, g, b = getValue()
        local info = {
            swatchFunc = function()
                local cr, cg, cb = ColorPickerFrame:GetColorRGB()
                setValue(cr, cg, cb)
                Snap()
            end,
            cancelFunc = function(prev)
                setValue(prev.r, prev.g, prev.b)
                Snap()
            end,
            r = r, g = g, b = b,
            hasOpacity = false,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    if resetLabel then
        local resetBtn = CreateFrame("Button", nil, f)
        resetBtn:SetSize(60, 18)
        resetBtn:SetPoint("RIGHT", swatch, "LEFT", -8, 0)
        local resetText = resetBtn:CreateFontString(nil, "OVERLAY")
        resetText:SetFont(FONT, 10, "")
        resetText:SetAllPoints()
        resetText:SetText(resetLabel)
        resetText:SetTextColor(1, 1, 1, 0.5)
        resetBtn:SetScript("OnClick", function()
            setValue(nil)
            Snap()
        end)
        resetBtn:SetScript("OnEnter", function() resetText:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3]) end)
        resetBtn:SetScript("OnLeave", function() resetText:SetTextColor(1, 1, 1, 0.5) end)
    end

    Snap()
    f._refresh = Snap
    return f, ROW_H
end

-- Sound picker (dropdown + test button, built inline)

function W:SoundPicker(parent, text, y, settingKey)
    local getValue = function() return OffBeat.db.profile[settingKey] end
    local setValue = function(val) OffBeat.db.profile[settingKey] = val end

    local f, h = W:Dropdown(parent, text, y, OffBeat.SOUND_VALUES, getValue, setValue)

    local testBtn = CreateFrame("Button", nil, f)
    testBtn:SetSize(36, 20)
    testBtn:SetPoint("RIGHT", f, "RIGHT", -CONTROL_PAD, 0)
    local testLabel = testBtn:CreateFontString(nil, "OVERLAY")
    testLabel:SetFont(FONT, 10, "")
    testLabel:SetAllPoints()
    testLabel:SetText("Test")
    testLabel:SetTextColor(1, 1, 1, 0.6)
    testBtn:SetScript("OnClick", function() OffBeat:PlayConfigSound(settingKey) end)
    testBtn:SetScript("OnEnter", function() testLabel:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3]) end)
    testBtn:SetScript("OnLeave", function() testLabel:SetTextColor(1, 1, 1, 0.6) end)

    -- Shift the dropdown left to make room for the test button
    for _, child in ipairs({ f:GetChildren() }) do
        if child:IsObjectType("Button") and child ~= testBtn then
            child:ClearAllPoints()
            child:SetPoint("RIGHT", testBtn, "LEFT", -6, 0)
            break
        end
    end

    return f, h
end

-- Spacer

function W:Spacer(parent, y, height)
    height = height or 12
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(parent:GetWidth(), height)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    return f, height
end

-- Reset row counter (used when switching pages)

function W:ResetRowCounters()
    wipe(rowCounters)
end
