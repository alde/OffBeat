local OffBeat = _G.OffBeat

-- Conditions shared by mistake rules (bad_cast) and cooldown window setup
-- checks. A `when` is one condition or a list of them that must all hold:
--
--   { aura = id, [minStacks = n], [maxStacks = n], [absent = true] }
--   { power = "SoulShards" | Enum.PowerType value, [min = n], [max = n] }
--   { combat = true | false }
--   { hardcast = true | false }   the cast had a cast bar (not instant)
--   { moving = true | false }     you were moving when you pressed it
--
-- A value that can't be read (secret, missing) is "unknown": Check treats it
-- as not matching, so unreadable state can only hide a mistake, never invent
-- one; Status reports it as nil so callers can show "?" instead of a miss. That includes "aura not
-- up" (absent = true): while the game hides auras it never matches, since a
-- hidden aura would otherwise look like a missing one.
--
-- hardcast is only known once the cast has started, so it is "deferred":
-- callers judge the other conditions when the button is pressed and the
-- deferred ones when the cast completes (see Check's `only`).

local C = {}
OffBeat.Conditions = C

function C.IsSecret(val)
    if val == nil or not _G.issecretvalue then return false end
    local ok, secret = pcall(_G.issecretvalue, val)
    return ok and secret
end

local IsSecret = C.IsSecret

local function ReadNumber(val)
    if val == nil or IsSecret(val) then return nil end
    local ok, num = pcall(tonumber, val)
    if ok and num and not IsSecret(num) then return num end
    return nil
end

local function InRange(v, min, max)
    if min and v < min then return false end
    if max and v > max then return false end
    return true
end

local function AurasHidden()
    if not (C_Secrets and C_Secrets.ShouldAurasBeSecret) then return false end
    local ok, secret = pcall(C_Secrets.ShouldAurasBeSecret)
    return ok and secret and true or false
end

-- Each check returns true, false, or nil when the answer can't be known.
local CHECKS = {
    aura = function(c)
        local auras = OffBeat:GetModule("Auras", true)
        if not auras then return nil end
        if AurasHidden() and (c.absent or not auras:IsActive(c.aura)) then return nil end
        local active = auras:IsActive(c.aura)
        if c.absent then return not active end
        if not active then return false end
        if c.minStacks or c.maxStacks then
            local rec = auras:GetAura(c.aura)
            local stacks = rec and ReadNumber(rec.stacks)
            if not stacks or stacks == 0 then return nil end -- 0 = unreadable
            return InRange(stacks, c.minStacks, c.maxStacks)
        end
        return true
    end,
    power = function(c)
        local ok, v = pcall(UnitPower, "player", c.powerType)
        v = ok and ReadNumber(v)
        if not v then return nil end
        return InRange(v, c.min, c.max)
    end,
    combat = function(c)
        local ok, v = pcall(UnitAffectingCombat, "player")
        if not ok or IsSecret(v) then return nil end
        return (v and true or false) == c.combat
    end,
    moving = function(c)
        if not GetUnitSpeed then return nil end
        local ok, speed = pcall(GetUnitSpeed, "player")
        speed = ok and ReadNumber(speed)
        if not speed then return nil end
        return (speed > 0) == c.moving
    end,
    hardcast = function(c, ctx)
        if not ctx or ctx.hardcast == nil then return nil end
        return ctx.hardcast == c.hardcast
    end,
}

function C.Kind(c)
    if type(c) ~= "table" then return nil end
    if c.aura then return "aura" end
    if c.power then return "power" end
    if c.combat ~= nil then return "combat" end
    if c.hardcast ~= nil then return "hardcast" end
    if c.moving ~= nil then return "moving" end
end

local function NormalizeOne(c)
    local kind = C.Kind(c)
    if kind == "power" then
        local pt = c.power
        if type(pt) == "string" then pt = Enum and Enum.PowerType and Enum.PowerType[pt] end
        if type(pt) ~= "number" then return nil end
        return { kind = kind, powerType = pt, min = c.min, max = c.max }
    elseif kind == "aura" then
        return { kind = kind, aura = c.aura, minStacks = c.minStacks,
                 maxStacks = c.maxStacks, absent = c.absent }
    elseif kind == "combat" then
        return { kind = kind, combat = c.combat }
    elseif kind == "moving" then
        return { kind = kind, moving = c.moving }
    elseif kind == "hardcast" then
        return { kind = kind, hardcast = c.hardcast, deferred = true }
    end
end

--- Turn a profile `when` into a checkable list, or nil if any part is unusable
--- (unknown power type etc.), so a half-understood rule never runs.
function C.Normalize(when)
    if not when then return nil end
    if C.Kind(when) then when = { when } end
    local out = {}
    for _, c in ipairs(when) do
        local n = NormalizeOne(c)
        if not n then return nil end
        out[#out + 1] = n
    end
    if #out == 0 then return nil end
    return out
end

--- True when every condition in a normalized list holds.
--- ctx: facts about the cast ({ hardcast = bool }), or nil.
--- only: nil = all conditions, "immediate" = skip deferred ones (judged at
--- the button press), "deferred" = only deferred ones (at cast completion).
function C.Check(list, ctx, only)
    for _, c in ipairs(list) do
        local include = only == nil
            or (only == "immediate" and not c.deferred)
            or (only == "deferred" and c.deferred)
        if include and CHECKS[c.kind](c, ctx) ~= true then return false end -- unknown = no match
    end
    return true
end

--- true when every condition holds, false when any is known not to, nil
--- when none fail but at least one couldn't be read.
function C.Status(list, ctx)
    local unknown = false
    for _, c in ipairs(list) do
        local r = CHECKS[c.kind](c, ctx)
        if r == false then return false end
        if r == nil then unknown = true end
    end
    if unknown then return nil end
    return true
end
