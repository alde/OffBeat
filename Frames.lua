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

local ACTION_BAR_BINDINGS = {
    { prefix = "ACTIONBUTTON",          offset = 0 },
    { prefix = "MULTIACTIONBAR1BUTTON", offset = 60 },
    { prefix = "MULTIACTIONBAR2BUTTON", offset = 48 },
    { prefix = "MULTIACTIONBAR3BUTTON", offset = 24 },
    { prefix = "MULTIACTIONBAR4BUTTON", offset = 36 },
    { prefix = "MULTIACTIONBAR5BUTTON", offset = 72 },
    { prefix = "MULTIACTIONBAR6BUTTON", offset = 84 },
    { prefix = "MULTIACTIONBAR7BUTTON", offset = 96 },
    { prefix = "MULTIACTIONBAR8BUTTON", offset = 108 },
}

local keybindNameCache = {}

local function CacheKey(spellId, key)
    if not spellId then return end
    local short = ShortenKey(key)
    if keybindCache[spellId] and #keybindCache[spellId] <= #short then return end
    keybindCache[spellId] = short
    local info = C_Spell.GetSpellInfo(spellId)
    if info and info.name then
        local existing = keybindNameCache[info.name]
        if not existing or #short < #existing then
            keybindNameCache[info.name] = short
        end
    end
end

function OffBeat:GetKeybindForSpell(spellId)
    if keybindCacheDirty then
        wipe(keybindCache)
        wipe(keybindNameCache)
        for _, bar in ipairs(ACTION_BAR_BINDINGS) do
            for i = 1, 12 do
                local key = GetBindingKey(bar.prefix .. i)
                if key then
                    local slot = bar.offset + i
                    local actionType, id = GetActionInfo(slot)
                    if actionType == "spell" then
                        CacheKey(id, key)
                    elseif actionType == "macro" then
                        local macroSpell = GetMacroSpell(id)
                        if macroSpell then CacheKey(macroSpell, key) end
                    end
                end
            end
        end
        keybindCacheDirty = false
    end
    if keybindCache[spellId] then return keybindCache[spellId] end
    local info = C_Spell.GetSpellInfo(spellId)
    if info and info.name then return keybindNameCache[info.name] end
    return nil
end

