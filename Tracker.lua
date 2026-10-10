local OffBeat = _G.OffBeat
local Tracker = OffBeat:NewModule("Tracker", "AceEvent-3.0")

-- A small in-combat panel for specs whose feedback is mostly invisible
-- (profile.tracker):
--
--   tracker = {
--       power = { type = "SoulShards", max = 5, spendAt = 4, spend = "Unstable Affliction" },
--       dots = { { spellId = 980, name = "Agony", duration = 18, pandemic = 5.4 } },
--   }
--
-- Power shows as pips; from `spendAt` it says "SPEND: <spend>", except while
-- the prep countdown (profile.prep) says to hold, where only a full bar does.
-- Each DoT is a bar counting down on your current target, started from your
-- own casts (the game hides debuffs from addons in combat, so this is an
-- estimate): refreshing inside `pandemic` carries the rest over, like the
-- game does. Orange when it's time to refresh, red when it's gone.

local TICK = 0.1
local FONT = "Fonts\\FRIZQT__.TTF"
local WIDTH, PIP_H, BAR_H, PAD = 200, 12, 14, 6

local frame, ticker
local expiry = {}        -- dot spellId -> { [targetGUID] = GetTime() it runs out }

local function GetSpecSettings()
    local profile = OffBeat.activeProfile
    if not profile then return nil end
    local specs = OffBeat.db.profile.specSettings
    return specs and specs[profile.meta.specId]
end

local function GetSpecOr(key)
    local ss = GetSpecSettings()
    if ss and ss[key] ~= nil then return ss[key] end
    return OffBeat.db.profile[key]
end

local IsSecret = function(v) return OffBeat.Conditions.IsSecret(v) end

local function Num(ok, v)
    if not ok or v == nil or IsSecret(v) then return nil end
    local ok2, n = pcall(tonumber, v)
    if ok2 and n and not IsSecret(n) then return n end
    return nil
end

-- The current target's GUID, or "?" when the game won't say (then all DoTs
-- share one timer).
local function TargetKey()
    local ok, guid = pcall(UnitGUID, "target")
    if not ok or guid == nil or IsSecret(guid) then return "?" end
    return guid
end

local function Power(cfg)
    local pt = Enum and Enum.PowerType and Enum.PowerType[cfg.type]
    if type(pt) ~= "number" then return nil end
    return Num(pcall(UnitPower, "player", pt))
end

-- Is the prep countdown telling you to hold?
local function Pooling()
    local prep = OffBeat.activeProfile and OffBeat.activeProfile.prep
    local mod = prep and OffBeat:GetModule("Prep", true)
    if not mod or not mod:IsEnabled() or not GetSpecOr("prepEnabled") then return false end
    local lead = GetSpecOr("prepLead") or prep.lead or 5
    local left = mod:Remaining(prep.spellId, prep.cooldown)
    return left ~= nil and left > 0.05 and left <= lead
end

local function CreatePanel(cfg)
    local nPips = cfg.power and cfg.power.max or 0
    local nDots = cfg.dots and #cfg.dots or 0
    local height = PAD + (nPips > 0 and (PIP_H + 4 + 14) or 0) + nDots * (BAR_H + 4) + PAD - 4
    local f = OffBeat:CreateMovableFrame("OffBeatTracker", "trackerPosition", {
        width = WIDTH + PAD * 2, height = height,
        backdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        },
        backdropColor = { 0.05, 0.05, 0.05, 0.7 },
        borderColor = { 0.5, 0.5, 0.5, 0.8 },
        defaultY = -150,
    })
    local y = -PAD
    f.pips = {}
    if nPips > 0 then
        local gap = 4
        local w = (WIDTH - gap * (nPips - 1)) / nPips
        for i = 1, nPips do
            local p = f:CreateTexture(nil, "ARTWORK")
            p:SetSize(w, PIP_H)
            p:SetPoint("TOPLEFT", PAD + (i - 1) * (w + gap), y)
            p:SetColorTexture(0.2, 0.2, 0.2, 1)
            f.pips[i] = p
        end
        y = y - PIP_H - 2
        f.cue = f:CreateFontString(nil, "OVERLAY")
        f.cue:SetFont(FONT, 11, "OUTLINE")
        f.cue:SetPoint("TOP", f, "TOP", 0, y)
        y = y - 14 - 2
    end
    f.bars = {}
    for i = 1, nDots do
        local b = CreateFrame("StatusBar", nil, f)
        b:SetSize(WIDTH, BAR_H)
        b:SetPoint("TOPLEFT", PAD, y)
        b:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        b:SetMinMaxValues(0, 1)
        local bg = b:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        b.text = b:CreateFontString(nil, "OVERLAY")
        b.text:SetFont(FONT, 10, "OUTLINE")
        b.text:SetPoint("LEFT", 4, 0)
        b.time = b:CreateFontString(nil, "OVERLAY")
        b.time:SetFont(FONT, 10, "OUTLINE")
        b.time:SetPoint("RIGHT", -4, 0)
        f.bars[i] = b
        y = y - BAR_H - 4
    end
    f.overlay = OffBeat:CreateUnlockOverlay(f, "Shards / DoTs")
    f:Hide()
    return f
end

function Tracker:Refresh()
    local cfg = OffBeat.activeProfile and OffBeat.activeProfile.tracker
    if not cfg or not frame then return end
    local now = GetTime()

    if cfg.power then
        local v = Power(cfg.power)
        local full = v ~= nil and v >= cfg.power.max
        local spend = v ~= nil and v >= (cfg.power.spendAt or cfg.power.max) and (full or not Pooling())
        for i, p in ipairs(frame.pips) do
            if v == nil then
                p:SetColorTexture(0.3, 0.3, 0.3, 1)
            elseif i <= v then
                if spend then p:SetColorTexture(1, 0.75, 0.1, 1) else p:SetColorTexture(0.6, 0.3, 0.9, 1) end
            else
                p:SetColorTexture(0.2, 0.2, 0.2, 1)
            end
        end
        if v == nil then
            frame.cue:SetText("|cff999999?|r")
        elseif spend then
            frame.cue:SetText("|cffffc020SPEND: " .. (cfg.power.spend or "now") .. "|r")
        elseif Pooling() then
            frame.cue:SetText("|cff9999ffhold for " .. (OffBeat.activeProfile.prep.name or "the cooldown") .. "|r")
        else
            frame.cue:SetText("")
        end
    end

    local key = TargetKey()
    for i, d in ipairs(cfg.dots or {}) do
        local b = frame.bars[i]
        local t = expiry[d.spellId] and expiry[d.spellId][key]
        local left = t and math.max(0, t - now) or 0
        b:SetValue(left / d.duration)
        if left <= 0 then
            b:SetStatusBarColor(0.8, 0.15, 0.15)
            b:SetValue(1)
            b.text:SetText((d.name or "DoT") .. " missing")
            b.time:SetText("")
        else
            if left <= (d.pandemic or 0) then b:SetStatusBarColor(1, 0.55, 0.1)
            else b:SetStatusBarColor(0.25, 0.7, 0.3) end
            b.text:SetText(d.name or "DoT")
            b.time:SetText(string.format("%.0f", left))
        end
    end
end

function Tracker:OnEnable()
    expiry = {}
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "OnLockChanged")
    if not OffBeat.db.profile.locked then self:OnLockChanged(nil, false) end
end

function Tracker:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if ticker then ticker:Cancel(); ticker = nil end
    if frame then frame:Hide() end
end

function Tracker:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, spellId)
    if unit ~= "player" or spellId == nil or IsSecret(spellId) then return end
    local cfg = OffBeat.activeProfile and OffBeat.activeProfile.tracker
    for _, d in ipairs(cfg and cfg.dots or {}) do
        if d.spellId == spellId then
            local key, now = TargetKey(), GetTime()
            expiry[spellId] = expiry[spellId] or {}
            local old = expiry[spellId][key]
            local carry = old and math.min(math.max(0, old - now), d.pandemic or 0) or 0
            expiry[spellId][key] = now + d.duration + carry
        end
    end
end

function Tracker:PLAYER_REGEN_DISABLED()
    local cfg = OffBeat.activeProfile and OffBeat.activeProfile.tracker
    if not cfg or not GetSpecOr("trackerEnabled") then return end
    frame = frame or CreatePanel(cfg)
    if not OffBeat.db.profile.locked then return end
    frame:Show()
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(TICK, function() Tracker:Refresh() end)
    self:Refresh()
end

function Tracker:PLAYER_REGEN_ENABLED()
    if ticker then ticker:Cancel(); ticker = nil end
    if frame and OffBeat.db.profile.locked then frame:Hide() end
    expiry = {}
end

function Tracker:OnLockChanged(_, locked)
    local cfg = OffBeat.activeProfile and OffBeat.activeProfile.tracker
    if not cfg then return end
    frame = frame or CreatePanel(cfg)
    if locked then
        frame.overlay:Hide()
        if not InCombatLockdown() then frame:Hide() end
        return
    end
    frame:Show()
    frame.overlay:Show()
    self:Refresh()
end
