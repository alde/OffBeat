local OffBeat = _G.OffBeat
local Prep = OffBeat:NewModule("Prep", "AceEvent-3.0")

-- A countdown to your main cooldown with what you should be holding when it
-- comes up (profile.prep):
--
--   prep = {
--       spellId = 51271, name = "Pillar of Frost", cooldown = 45, lead = 5,
--       hint = "Hold runes: Obliterate only on Killing Machine",
--       checks = {
--           { name = "Runes", power = "Runes", min = 3 },
--           -- only when this other cooldown comes up with it (Breath turns)
--           { name = "Runic Power", power = "RunicPower", min = 60,
--             with = { spellId = 1249658, name = "Breath", cooldown = 90 },
--             -- the macro casts Reaper's Mark (+20) before Breath
--             credit = { spellId = 439843, amount = 20, cooldown = 45 } },
--           -- a spell that should be off cooldown too: green when it will be
--           -- ready in time, red with how late it will be
--           { name = "Fire Breath", ready = 357208, cooldown = 30 },
--       },
--   }
--
-- In combat, from `lead` seconds before the spell is ready until you cast
-- it, a small panel shows "Pillar of Frost in 4" and each check against its
-- target (green when met, red when not, ? when the game won't say). The time
-- left comes from the spell's cooldown when the game reveals it, otherwise
-- from your last cast plus `cooldown`, so it keeps working while combat
-- information is hidden.

local TICK = 0.1
local FONT = "Fonts\\FRIZQT__.TTF"
local GREEN, RED, GREY, WHITE = "|cff40ff40", "|cffff4040", "|cff999999", "|cffffffff"

local frame, ticker
local lastCast = {}   -- spellId -> GetTime() of your last successful cast

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

local function Known(id)
    local ok, known = pcall(IsPlayerSpell, id)
    return ok and not IsSecret(known) and known and true or false
end

--- Seconds until `spellId` is ready (0 = ready), or nil if not known.
--- Reads the cooldown when the game reveals it; otherwise last cast + cd.
function Prep:Remaining(spellId, cooldown)
    if not Known(spellId) then return nil end
    local now = GetTime()
    local ok, left = pcall(function()
        local info = C_Spell.GetSpellCooldown(spellId)
        if not info then return nil end
        if not info.isActive or info.isOnGCD then return 0 end
        local r = info.startTime + info.duration - now
        if r <= 1.6 then -- the global cooldown, or about to be ready
            local gcd = C_Spell.GetSpellCooldown(61304)
            if gcd and gcd.isActive and info.startTime == gcd.startTime then return 0 end
        end
        return r > 0 and r or 0
    end)
    left = Num(ok, left)
    if left then return left end
    local t = lastCast[spellId]
    if not t or not cooldown then return 0 end
    return math.max(0, t + cooldown - now)
end

local function Power(powerName)
    local pt = Enum and Enum.PowerType and Enum.PowerType[powerName]
    if type(pt) ~= "number" then return nil end
    return Num(pcall(UnitPower, "player", pt))
end

local function CreatePanel()
    local f = OffBeat:CreateMovableFrame("OffBeatPrep", "prepPosition", {
        width = 260, height = 40,
        backdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        },
        backdropColor = { 0.05, 0.05, 0.05, 0.7 },
        borderColor = { 0.5, 0.5, 0.5, 0.8 },
        defaultY = 200,
    })
    f.line1 = f:CreateFontString(nil, "OVERLAY")
    f.line1:SetFont(FONT, 13, "OUTLINE")
    f.line1:SetPoint("TOP", 0, -5)
    f.line2 = f:CreateFontString(nil, "OVERLAY")
    f.line2:SetFont(FONT, 10, "OUTLINE")
    f.line2:SetPoint("TOP", f.line1, "BOTTOM", 0, -3)
    f.line2:SetTextColor(0.8, 0.8, 0.8)
    f.overlay = OffBeat:CreateUnlockOverlay(f, "Cooldown Prep")
    f:Hide()
    return f
end

function Prep:OnEnable()
    lastCast = {}
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "OnLockChanged")
    if not OffBeat.db.profile.locked then self:OnLockChanged(nil, false) end
end

function Prep:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if ticker then ticker:Cancel(); ticker = nil end
    if frame then frame:Hide() end
end

function Prep:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, spellId)
    if unit ~= "player" or spellId == nil or IsSecret(spellId) then return end
    lastCast[spellId] = GetTime()
    local prep = OffBeat.activeProfile and OffBeat.activeProfile.prep
    if prep and spellId == prep.spellId and frame and OffBeat.db.profile.locked then frame:Hide() end
end

function Prep:PLAYER_REGEN_DISABLED()
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(TICK, function() Prep:Tick() end)
end

function Prep:PLAYER_REGEN_ENABLED()
    if ticker then ticker:Cancel(); ticker = nil end
    if frame and OffBeat.db.profile.locked then frame:Hide() end
end

function Prep:OnLockChanged(_, locked)
    if locked then
        if frame then frame.overlay:Hide(); frame:Hide() end
        return
    end
    frame = frame or CreatePanel()
    local prep = OffBeat.activeProfile and OffBeat.activeProfile.prep
    frame.line1:SetText((prep and prep.name or "Cooldown") .. " in 4")
    frame.line2:SetText(prep and prep.hint or "")
    frame:Show()
    frame.overlay:Show()
end

--- The panel's text for this moment, or nil when it shouldn't show.
function Prep:Build(prep, lead)
    local left = self:Remaining(prep.spellId, prep.cooldown)
    if left == nil or left > lead then return nil end
    local parts = {}
    parts[1] = WHITE .. (prep.name or "Cooldown") .. "|r "
        .. (left > 0.05 and string.format("in %d", math.ceil(left)) or (GREEN .. "READY|r"))
    for _, c in ipairs(prep.checks or {}) do
        local applies = true
        if c.with then
            local wl = self:Remaining(c.with.spellId, c.with.cooldown)
            applies = wl ~= nil and wl <= left + 1
        end
        if applies and c.ready then
            -- a spell to have off cooldown when the main one comes up
            -- (Augmentation: Fire Breath and Upheaval for Breath of Eons);
            -- left out when you don't know it
            local rl = self:Remaining(c.ready, c.cooldown)
            if rl ~= nil then
                local label = c.name or tostring(c.ready)
                if rl <= left + 0.5 then
                    parts[#parts + 1] = GREEN .. label .. "|r"
                else
                    parts[#parts + 1] = RED .. label .. " " .. string.format("%d", math.ceil(rl - left)) .. "s late|r"
                end
            end
        elseif applies then
            local v = Power(c.power)
            local label = (c.with and c.with.name and (c.with.name .. ": ") or "") .. (c.name or c.power)
            -- a spell the same press casts first adds to it (Reaper's Mark
            -- in the cooldown macro gives 20 Runic Power before Breath)
            local bonus = 0
            if c.credit then
                local cl = self:Remaining(c.credit.spellId, c.credit.cooldown)
                if cl ~= nil and cl <= left + 1 then bonus = c.credit.amount or 0 end
            end
            local color = v == nil and GREY or (v + bonus >= c.min and GREEN or RED)
            local shown = v and string.format("%d", v) or "?"
            if bonus > 0 then shown = shown .. "+" .. bonus end
            parts[#parts + 1] = color .. label .. " " .. shown .. "/" .. c.min .. "|r"
        end
    end
    return table.concat(parts, "   "), prep.hint
end

function Prep:Tick()
    local prep = OffBeat.activeProfile and OffBeat.activeProfile.prep
    if not prep or not OffBeat.db.profile.locked then return end
    if not GetSpecOr("prepEnabled") then
        if frame then frame:Hide() end
        return
    end
    local lead = GetSpecOr("prepLead") or prep.lead or 5
    local text, hint = self:Build(prep, lead)
    if not text then
        if frame then frame:Hide() end
        return
    end
    frame = frame or CreatePanel()
    frame.line1:SetText(text)
    frame.line2:SetText(hint or "")
    frame:SetWidth(math.max(200, frame.line1:GetStringWidth() + 20, frame.line2:GetStringWidth() + 20))
    frame:SetHeight(hint and 38 or 24)
    frame:Show()
end
