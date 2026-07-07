local OffBeat = _G.OffBeat
local RotationDisplay = OffBeat:NewModule("RotationDisplay", "AceEvent-3.0")
local MSQ = LibStub("Masque", true)

local PADDING = 4
local BORDER_SIZE = 2
local KEY_CD_FLASH_DURATION = 3.0
local ASSISTED_COMBAT_POLL = 0.1
local ICON_SCALE_DECAY = 0.06
local ICON_MIN_SCALE = 0.6
local GLOW_SIZE_MULTIPLIER = 1.7

local msqHistory, msqKeyCd, msqAssisted
if MSQ then
    msqHistory = MSQ:Group("OffBeat", "Ability History")
    msqKeyCd = MSQ:Group("OffBeat", "Key Cooldown")
    msqAssisted = MSQ:Group("OffBeat", "Next Spell")
end

local MASQUE_DISABLED = {
    Normal = false, Pushed = false, Highlight = false,
    Checked = false, Flash = false, Disabled = false,
    AutoCastable = false,
}

local function MasqueRegister(group, frame, icon, extras)
    if not group then return end
    local regions = { Icon = icon }
    for k, v in pairs(MASQUE_DISABLED) do regions[k] = v end
    if extras then for k, v in pairs(extras) do regions[k] = v end end
    group:AddButton(frame, regions)
end

local ICON_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

function RotationDisplay:OnEnable()
    self:RegisterMessage("OFFBEAT_HISTORY_UPDATED", "Refresh")
    self:RegisterMessage("OFFBEAT_KEY_CD_READY", "OnKeyCdReady")
    self:RegisterMessage("OFFBEAT_KEY_CD_USED", "OnKeyCdUsed")
    self:RegisterMessage("OFFBEAT_COOLDOWN_IDLE", "OnCooldownIdle")
    self:RegisterMessage("OFFBEAT_PROC_WASTE", "OnProcWaste")
    self:RegisterMessage("OFFBEAT_MISTAKE", "OnMistake")
    self:RegisterMessage("OFFBEAT_PROC_EXPIRED", "OnProcExpired")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "OnLockChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function RotationDisplay:OnDisable()
    self:UnregisterAllMessages()
    self:UnregisterAllEvents()
    if self.assistedFrame then self.assistedFrame:Hide() end
    self:HideKeyCdIcon()
    self:HideWarning()
end

-- Main ability panel

function RotationDisplay:GetFrame()
    if self.frame then return self.frame end

    local f = OffBeat:CreateMovableFrame("OffBeatRotationPanel", "rotationPosition", {
        defaultY = 200,
    })
    f.icons = {}
    self.frame = f
    self.unlockOverlay = OffBeat:CreateUnlockOverlay(f, "Ability Panel")
    OffBeat:ApplyAppearance()
    self:ApplyLock()
    self:LayoutFrame()
    return f
end

local function IsVertical(dir)
    return dir == "up" or dir == "down"
end

function RotationDisplay:LayoutFrame()
    local f = self:GetFrame()
    local db = OffBeat.db.profile
    local iconSize = db.iconSize
    local visible = math.min(#OffBeat.state.history, db.historyCount)
    if visible == 0 then visible = 1 end

    local span = (iconSize * visible) + (PADDING * (visible - 1)) + (BORDER_SIZE * 2) + 8

    if IsVertical(db.growDirection) then
        f:SetSize(iconSize + (BORDER_SIZE * 2) + 8, span)
    else
        f:SetSize(span, iconSize + (BORDER_SIZE * 2) + 8)
    end
end

function RotationDisplay:GetIcon(index)
    local f = self.frame
    if f.icons[index] then return f.icons[index] end

    local container = CreateFrame("Frame", nil, f)

    local border = container:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    if msqHistory then border:Hide() end
    container.border = border

    local icon = container:CreateTexture(nil, "ARTWORK")
    if msqHistory then
        icon:SetAllPoints()
    else
        icon:SetPoint("TOPLEFT", BORDER_SIZE, -BORDER_SIZE)
        icon:SetPoint("BOTTOMRIGHT", -BORDER_SIZE, BORDER_SIZE)
    end
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    container.icon = icon

    local glow = container:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("CENTER")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0)
    container.glow = glow

    MasqueRegister(msqHistory, container, icon, { Border = glow })

    f.icons[index] = container
    return container
end

local GROW_CONFIG = {
    right = { anchor = "BOTTOMLEFT", xMul = 1,  yMul = 0 },
    left  = { anchor = "BOTTOMRIGHT", xMul = -1, yMul = 0 },
    up    = { anchor = "BOTTOMLEFT", xMul = 0,  yMul = 1 },
    down  = { anchor = "TOPLEFT",    xMul = 0,  yMul = -1 },
}

function RotationDisplay:Refresh()
    local f = self:GetFrame()
    if not f:IsShown() then return end

    local db = OffBeat.db.profile
    local history = OffBeat.state.history
    local count = db.historyCount
    local baseSize = db.iconSize
    local grow = GROW_CONFIG[db.growDirection] or GROW_CONFIG.right

    self:LayoutFrame()

    local offset = BORDER_SIZE + 4
    for i = 1, count do
        local container = self:GetIcon(i)
        local entry = history[i]

        if entry then
            local age = i - 1
            local scale = math.max(ICON_MIN_SCALE, 1.0 - (age * ICON_SCALE_DECAY))
            local alpha = db.iconAlpha * math.max(db.minOpacity, 1.0 - (age * db.opacityStep))
            local iconPixels = math.floor(baseSize * scale)

            container:SetSize(iconPixels, iconPixels)
            container.glow:SetSize(iconPixels * GLOW_SIZE_MULTIPLIER, iconPixels * GLOW_SIZE_MULTIPLIER)
            container:ClearAllPoints()
            container:SetPoint(grow.anchor, f, grow.anchor,
                offset * grow.xMul + (grow.xMul == 0 and (BORDER_SIZE + 4) or 0),
                offset * grow.yMul + (grow.yMul == 0 and (4 + BORDER_SIZE) or 0))
            container:SetAlpha(alpha)

            local spellInfo = C_Spell.GetSpellInfo(entry.spellId)
            container.icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")

            if entry.mistake then
                if not msqHistory then
                    container.border:SetColorTexture(0.9, 0.1, 0.1, 1.0)
                end
                container.glow:SetVertexColor(1, 0, 0)
                container.glow:SetAlpha(0.6)
            else
                if not msqHistory then
                    container.border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
                end
                container.glow:SetAlpha(0)
            end

            container:Show()
            offset = offset + iconPixels + PADDING
        else
            container:Hide()
        end
    end

    for i = count + 1, #f.icons do
        f.icons[i]:Hide()
    end

    if msqHistory then msqHistory:ReSkin() end
    self:RefreshAssisted()
end

-- Visibility

function RotationDisplay:UpdatePanelVisibility()
    local f = self:GetFrame()
    local db = OffBeat.db.profile
    if db.rotationShown then
        f:Show()
        local inCombat = not db.rotationCombatOnly or UnitAffectingCombat("player")
        f:SetAlpha(inCombat and 1 or 0)
    else
        f:SetAlpha(0)
    end
end

function RotationDisplay:Toggle()
    local db = OffBeat.db.profile
    db.rotationShown = not db.rotationShown
    self:UpdatePanelVisibility()
    if db.rotationShown then self:Refresh() end
end

function RotationDisplay:ApplyLock()
    local locked = OffBeat.db.profile.locked
    if not locked then
        self:GetWarningFrame()
        self:GetAssistedFrame()
        self:GetKeyCdIcon()
    end
    local frames = { self.frame, self.keyCdIcon, self.assistedFrame, self.warningFrame }
    for _, f in ipairs(frames) do
        if f then
            f:EnableMouse(not locked)
            local overlay = f == self.frame and self.unlockOverlay or (f.unlockOverlay)
            if overlay then
                if locked then overlay:Hide()
                else f:Show(); f:SetAlpha(1); overlay:Show() end
            end
        end
    end

    if locked then
        self:UpdatePanelVisibility()
        self:RefreshAssisted()
        if self.keyCdIcon then
            local rot = OffBeat:GetModule("Rotation", true)
            if rot and rot.keyCdReady then
                self.keyCdIcon:SetAlpha(OffBeat.db.profile.keyCdIconAlpha)
            else
                self.keyCdIcon:SetAlpha(0)
            end
        end
        self:HideWarning()
    end
end

function RotationDisplay:OnLockChanged(_, locked)
    self:ApplyLock()
end

function RotationDisplay:PLAYER_ENTERING_WORLD()
    self:UpdatePanelVisibility()
    if OffBeat.db.profile.rotationShown then self:Refresh() end
end

function RotationDisplay:PLAYER_REGEN_DISABLED()
    self:UpdatePanelVisibility()
    local db = OffBeat.db.profile
    if db.keyCdCombatOnly and self.keyCdIcon and self.keyCdIcon:IsShown() then
        self:SetKeyCdIconAlpha(db.keyCdIconAlpha)
    end
end

function RotationDisplay:PLAYER_REGEN_ENABLED()
    self:UpdatePanelVisibility()
    self:HideWarning()
    if OffBeat.db.profile.keyCdCombatOnly then
        self:SetKeyCdIconAlpha(0)
    end
end

-- Assisted Combat (Next Spell)

function RotationDisplay:ShouldShowAssisted()
    return OffBeat.db.profile.assistedCombat
        and C_AssistedCombat ~= nil
        and C_AssistedCombat.GetNextCastSpell ~= nil
end

function RotationDisplay:GetAssistedFrame()
    if self.assistedFrame then return self.assistedFrame end

    local size = OffBeat.db.profile.assistedIconSize or OffBeat.db.profile.iconSize
    local af = OffBeat:CreateMovableFrame("OffBeatAssistedIcon", "assistedPosition", {
        width = size, height = size,
        backdrop = not MSQ and ICON_BACKDROP or nil,
        backdropColor = { 0.05, 0.05, 0.1, 0.8 },
        borderColor = { 0.1, 0.5, 0.8, 0.8 },
        defaultX = 60, defaultY = 200,
    })

    local icon = af:CreateTexture(nil, "ARTWORK")
    if MSQ then icon:SetAllPoints()
    else icon:SetPoint("TOPLEFT", 3, -3); icon:SetPoint("BOTTOMRIGHT", -3, 3) end
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    af.icon = icon

    local keybind = af:CreateFontString(nil, "OVERLAY")
    local kbSize = OffBeat.db.profile.assistedKeybindSize or 12
    keybind:SetFont("Fonts\\FRIZQT__.TTF", kbSize, "OUTLINE")
    keybind:SetPoint("TOPLEFT", 4, -3)
    keybind:SetTextColor(1, 1, 1)
    af.keybind = keybind

    MasqueRegister(msqAssisted, af, icon, { HotKey = keybind })

    af.elapsed = 0
    af:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed < ASSISTED_COMBAT_POLL then return end
        self.elapsed = 0
        RotationDisplay:UpdateAssisted()
    end)

    af.unlockOverlay = OffBeat:CreateUnlockOverlay(af, "Next Spell")
    af:Hide()
    self.assistedFrame = af
    self:ApplyLock()
    return af
end

function RotationDisplay:RefreshAssisted()
    if not self:ShouldShowAssisted() then
        if self.assistedFrame then self.assistedFrame:Hide() end
        return
    end
    local af = self:GetAssistedFrame()
    local size = OffBeat.db.profile.assistedIconSize or OffBeat.db.profile.iconSize
    af:SetSize(size, size)
    af:Show()
    self:UpdateAssisted()
end

function RotationDisplay:UpdateAssisted()
    local af = self.assistedFrame
    if not af or not af:IsShown() or not C_AssistedCombat then return end

    local spellId = C_AssistedCombat.GetNextCastSpell()
    if not spellId then
        af.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        af.icon:SetDesaturated(true)
        af.keybind:SetText("")
        return
    end

    local spellInfo = C_Spell.GetSpellInfo(spellId)
    af.icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
    af.icon:SetDesaturated(false)
    af.keybind:SetText(OffBeat:GetKeybindForSpell(spellId) or "")
end

-- Key Cooldown icon

function RotationDisplay:GetKeyCdIcon()
    if self.keyCdIcon then return self.keyCdIcon end

    local db = OffBeat.db.profile
    local size = db.keyCdIconSize
    local gr, gg, gb = OffBeat:GetGlowColor()

    local f = OffBeat:CreateMovableFrame("OffBeatKeyCdIcon", "keyCdIconPosition", {
        width = size, height = size,
        backdrop = not MSQ and ICON_BACKDROP or nil,
        backdropColor = { 0.05, 0.05, 0.05, 0.8 },
        borderColor = { gr, gg, gb, 0.9 },
        defaultY = 250,
    })

    local icon = f:CreateTexture(nil, "ARTWORK")
    if MSQ then icon:SetAllPoints()
    else icon:SetPoint("TOPLEFT", 3, -3); icon:SetPoint("BOTTOMRIGHT", -3, 3) end
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon = icon

    MasqueRegister(msqKeyCd, f, icon)

    local glow = f:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("CENTER")
    glow:SetSize(size * 1.7, size * 1.7)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    f.glow = glow

    local ag = glow:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local pulse = ag:CreateAnimation("Alpha")
    pulse:SetFromAlpha(0.3)
    pulse:SetToAlpha(0.9)
    pulse:SetDuration(0.8)
    pulse:SetSmoothing("IN_OUT")
    f.glowAnim = ag
    f.glowFade = pulse

    f.unlockOverlay = OffBeat:CreateUnlockOverlay(f, "Key Cooldown")
    f:Hide()
    self.keyCdIcon = f
    self:ApplyLock()
    return f
end

function RotationDisplay:ShowKeyCdIcon(keyCd)
    if not OffBeat.db.profile.keyCdIconEnabled then return end

    local f = self:GetKeyCdIcon()
    local db = OffBeat.db.profile
    f:SetSize(db.keyCdIconSize, db.keyCdIconSize)
    if db.keyCdCombatOnly and not UnitAffectingCombat("player") then
        f:SetAlpha(0)
    else
        f:SetAlpha(db.keyCdIconAlpha)
    end

    local spellInfo = C_Spell.GetSpellInfo(keyCd.spellId)
    f.icon:SetTexture(spellInfo and spellInfo.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
    f:Show()

    local r, g, b = OffBeat:GetGlowColor()
    OffBeat:ApplyGlowStyle(f, db.keyCdGlowStyle, r, g, b, db.keyCdGlowIntensity)
end

function RotationDisplay:HideKeyCdIcon()
    if not self.keyCdIcon then return end
    if self.keyCdIcon.glowAnim then self.keyCdIcon.glowAnim:Stop() end
    if self.keyCdIcon.flipbookAnim then self.keyCdIcon.flipbookAnim:Stop() end
    self.keyCdIcon:SetAlpha(0)
end

function RotationDisplay:SetKeyCdIconAlpha(alpha)
    if self.keyCdIcon then self.keyCdIcon:SetAlpha(alpha) end
end

-- Text Warning frame

local WARNING_COLORS = {
    info    = { text = { 0.2, 1.0, 0.4 },  border = { 0.2, 0.8, 0.4, 0.6 } },
    warning = { text = { 1.0, 0.8, 0.2 },  border = { 1.0, 0.7, 0.1, 0.6 } },
    mistake = { text = { 1.0, 0.3, 0.3 },  border = { 0.9, 0.1, 0.1, 0.6 } },
}

function RotationDisplay:GetWarningFrame()
    if self.warningFrame then return self.warningFrame end

    local db = OffBeat.db.profile
    local wf = OffBeat:CreateMovableFrame("OffBeatWarning", "warningPosition", {
        width = 250, height = 28,
        backdrop = ICON_BACKDROP,
        backdropColor = { 0.05, 0.05, 0.05, db.warningBgAlpha },
        borderColor = { 0.5, 0.5, 0.5, db.warningBorderAlpha },
        defaultY = 160,
    })

    local label = wf:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    label:SetPoint("CENTER")
    wf.label = label

    local ag = wf:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local pulse = ag:CreateAnimation("Alpha")
    pulse:SetFromAlpha(0.5)
    pulse:SetToAlpha(1.0)
    pulse:SetDuration(0.6)
    pulse:SetSmoothing("IN_OUT")
    wf.ag = ag

    wf.unlockOverlay = OffBeat:CreateUnlockOverlay(wf, "Text Warnings")
    wf:Hide()
    self.warningFrame = wf
    self:ApplyLock()
    return wf
end

function RotationDisplay:ShowWarning(text, severity, duration, onUpdate)
    local wf = self:GetWarningFrame()
    local colors = WARNING_COLORS[severity] or WARNING_COLORS.warning

    wf.label:SetText(text)
    wf.label:SetTextColor(unpack(colors.text))
    wf:SetBackdropBorderColor(colors.border[1], colors.border[2], colors.border[3],
        OffBeat.db.profile.warningBorderAlpha)

    wf.ag:Stop()
    wf:SetScript("OnUpdate", onUpdate)
    wf:Show()
    wf:SetAlpha(1)
    wf.ag:Play()

    if duration then
        C_Timer.After(duration, function()
            if wf:IsShown() and wf.label:GetText() == text then
                RotationDisplay:HideWarning()
            end
        end)
    end
end

function RotationDisplay:HideWarning()
    if not self.warningFrame then return end
    self.warningFrame.ag:Stop()
    self.warningFrame:SetScript("OnUpdate", nil)
    self.warningFrame:SetAlpha(0)
end

-- Message handlers

function RotationDisplay:OnKeyCdReady(_, keyCd)
    self:ShowWarning((keyCd.name or "Cooldown") .. " READY", "info", KEY_CD_FLASH_DURATION)
    self:ShowKeyCdIcon(keyCd)
end

function RotationDisplay:OnKeyCdUsed()
    self:HideKeyCdIcon()
end

function RotationDisplay:OnProcWaste(_, spellId, wasteName)
    local text = wasteName and (wasteName .. " wasted!") or "Proc wasted!"
    self:ShowWarning(text, "warning", 2)
end

function RotationDisplay:OnMistake(_, spellId, mistakeName)
    local info = C_Spell.GetSpellInfo(spellId)
    local name = info and info.name or "?"
    self:ShowWarning(mistakeName .. ": " .. name, "mistake", 2)
end

function RotationDisplay:OnProcExpired(_, spellId, procName)
    self:ShowWarning((procName or "Proc") .. " expired!", "warning", 2)
end

function RotationDisplay:OnCooldownIdle(_, spellId, spellName)
    if not OffBeat.db.profile.idleCooldownNag then return end

    local idleSince = GetTime() - OffBeat.db.profile.idleCooldownThreshold

    self:ShowWarning(spellName .. " available", "warning", nil, function()
        local elapsed = GetTime() - idleSince
        local wf = RotationDisplay.warningFrame
        wf.label:SetText(string.format("%s available for %ds", spellName, elapsed))
        local info = C_Spell.GetSpellCooldown(spellId)
        if info and info.isActive then
            RotationDisplay:HideWarning()
        end
    end)
end
