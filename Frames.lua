local OffBeat = _G.OffBeat

--- Resolve an aura spell ID to a canonical tracked spell ID.
--- Uses a two-tier lookup: direct ID match, then name-based fallback.
--- Results are cached per auraIdCache instance for performance.
---@param auraSpellId number The spell ID from the aura data
---@param trackedById table Map of canonical spell ID -> info table
---@param nameToId table Map of spell name -> canonical spell ID
---@param auraIdCache table Cache of aura spell ID -> canonical ID (or false)
---@return number|false The canonical spell ID, or false if not tracked
function OffBeat.ResolveSpellId(auraSpellId, trackedById, nameToId, auraIdCache)
    if auraIdCache[auraSpellId] ~= nil then
        return auraIdCache[auraSpellId]
    end

    if trackedById[auraSpellId] then
        auraIdCache[auraSpellId] = auraSpellId
        return auraSpellId
    end

    local name = C_Spell.GetSpellName(auraSpellId)
    if name and nameToId[name] then
        auraIdCache[auraSpellId] = nameToId[name]
        return nameToId[name]
    end

    auraIdCache[auraSpellId] = false
    return false
end

--- Create a movable, position-saving frame.
---@param name string Global frame name
---@param positionKey string Key in db.profile for saving position
---@param defaults table { width, height, backdrop, backdropColor, borderColor, strata, defaultPoint, defaultRelPoint, defaultX, defaultY }
function OffBeat:CreateMovableFrame(name, positionKey, defaults)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetSize(defaults.width or 48, defaults.height or 48)
    if defaults.backdrop then
        f:SetBackdrop(defaults.backdrop)
        if defaults.backdropColor then
            f:SetBackdropColor(unpack(defaults.backdropColor))
        end
        if defaults.borderColor then
            f:SetBackdropBorderColor(unpack(defaults.borderColor))
        end
    end
    f:SetFrameStrata(defaults.strata or "MEDIUM")
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
        OffBeat.db.profile[positionKey] = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    local pos = OffBeat.db.profile[positionKey]
    if pos then
        f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        f:SetPoint(defaults.defaultPoint or "CENTER", UIParent,
            defaults.defaultRelPoint or "CENTER",
            defaults.defaultX or 0, defaults.defaultY or 0)
    end

    return f
end

--- Create a semi-transparent unlock overlay with a label.
---@param parent Frame The frame to overlay
---@param label string Label text (e.g. "Buff Panel")
function OffBeat:CreateUnlockOverlay(parent, label)
    local overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(parent:GetFrameLevel() + 10)

    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.4, 0.8, 0.3)

    local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText(label)
    text:SetTextColor(1, 1, 1, 0.9)

    overlay:Hide()
    return overlay
end

-- Glow animation styles for key cooldown icons

local FLIPBOOK_SPECS = {
    proc = {
        atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook",
        rows = 5, cols = 6, frames = 30, duration = 1.0,
    },
    ants = {
        file = "Interface\\Cooldown\\IconAlertAnts",
        rows = 5, cols = 5, frames = 22, duration = 0.3,
    },
}

--- Apply a glow effect to a frame's glow texture and animation group.
---@param icon Frame The icon frame with .glow texture and .glowAnim animation group
---@param style string "glow", "proc", "ants", or "none"
---@param r number Red
---@param g number Green
---@param b number Blue
---@param intensity number Alpha intensity (0-1)
function OffBeat:ApplyGlowStyle(icon, style, r, g, b, intensity)
    if not icon.glow then return end
    local glow = icon.glow

    if icon.glowAnim then
        icon.glowAnim:Stop()
    end

    if icon.flipbookAnim then
        icon.flipbookAnim:Stop()
        icon.flipbook:Hide()
    end

    if style == "none" then
        glow:Hide()
        return
    end

    local spec = FLIPBOOK_SPECS[style]
    if spec then
        glow:Hide()
        if not icon.flipbook then
            icon.flipbook = icon:CreateTexture(nil, "OVERLAY")
            icon.flipbook:SetAllPoints()
            icon.flipbookAnim = icon.flipbook:CreateAnimationGroup()
            icon.flipbookAnim:SetLooping("REPEAT")
            local fb = icon.flipbookAnim:CreateAnimation("FlipBook")
            icon.flipbookFB = fb
        end

        local fb = icon.flipbookFB
        if spec.atlas then
            icon.flipbook:SetAtlas(spec.atlas)
        else
            icon.flipbook:SetTexture(spec.file)
        end
        icon.flipbook:SetVertexColor(r, g, b, intensity)
        fb:SetFlipBookRows(spec.rows)
        fb:SetFlipBookColumns(spec.cols)
        fb:SetFlipBookFrames(spec.frames)
        fb:SetDuration(spec.duration)
        icon.flipbook:Show()
        icon.flipbookAnim:Play()
        return
    end

    -- Default: pulsing glow
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(r, g, b, intensity)
    glow:Show()

    if not icon.glowAnim then
        icon.glowAnim = glow:CreateAnimationGroup()
        icon.glowAnim:SetLooping("BOUNCE")
        local fade = icon.glowAnim:CreateAnimation("Alpha")
        fade:SetFromAlpha(intensity * 0.3)
        fade:SetToAlpha(intensity)
        fade:SetDuration(0.8)
        fade:SetSmoothing("IN_OUT")
        icon.glowFade = fade
    end

    icon.glowFade:SetFromAlpha(intensity * 0.3)
    icon.glowFade:SetToAlpha(intensity)
    icon.glowAnim:Play()
end

-- Keybind cache for action bar spell lookups

local keybindCache = {}
local keybindCacheDirty = true

local KEY_SHORTEN = {
    ["SHIFT%-"] = "s-",
    ["CTRL%-"] = "c-",
    ["ALT%-"] = "a-",
    ["META%-"] = "m-",
    ["NUMPAD"] = "n",
    ["BUTTON"] = "m",
}

local function ShortenKey(key)
    for pattern, short in pairs(KEY_SHORTEN) do
        key = key:gsub(pattern, short)
    end
    return key
end

function OffBeat:InvalidateKeybindCache()
    keybindCacheDirty = true
end

function OffBeat:GetKeybindForSpell(spellId)
    if keybindCacheDirty then
        wipe(keybindCache)
        for bar = 1, 8 do
            for slot = 1, 12 do
                local realSlot = (bar - 1) * 12 + slot
                local actionType, id = GetActionInfo(realSlot)
                local resolvedSpell
                if actionType == "spell" then
                    resolvedSpell = id
                elseif actionType == "macro" then
                    resolvedSpell = GetMacroSpell(id)
                end
                if resolvedSpell and not keybindCache[resolvedSpell] then
                    local key = GetBindingKey("ACTIONBUTTON" .. slot)
                        or GetBindingKey("MULTIACTIONBAR1BUTTON" .. slot)
                        or GetBindingKey("MULTIACTIONBAR2BUTTON" .. slot)
                        or GetBindingKey("MULTIACTIONBAR3BUTTON" .. slot)
                        or GetBindingKey("MULTIACTIONBAR4BUTTON" .. slot)
                    if key then
                        keybindCache[resolvedSpell] = ShortenKey(key)
                    end
                end
            end
        end
        keybindCacheDirty = false
    end
    return keybindCache[spellId]
end

