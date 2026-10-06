local OffBeat = _G.OffBeat

-- Conditions shared by mistake rules (bad_cast) and cooldown window setup
-- checks. A `when` is one condition or a list of them that must all hold:
--
--   { aura = id, [minStacks = n], [maxStacks = n], [absent = true] }
--   { power = "SoulShards" | Enum.PowerType value, [min = n], [max = n] }
--   { combat = true | false }
--   { hardcast = true | false }   the cast had a cast bar (not instant)
--
-- A value that can't be read (secret, missing) never matches, so unreadable
-- state can only hide a result, never invent one. That includes "aura not
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

local CHECKS = {
    aura = function(c)
        local auras = OffBeat:GetModule("Auras", true)
        if not auras then return false end
        if c.absent and AurasHidden() then return false end
        local active = auras:IsActive(c.aura)
        if c.absent then return not active end
        if not active then return false end
        if c.minStacks or c.maxStacks then
            local rec = auras:GetAura(c.aura)
            local stacks = rec and ReadNumber(rec.stacks)
            if not stacks or stacks == 0 then return false end -- 0 = unreadable
            return InRange(stacks, c.minStacks, c.maxStacks)
        end
        return true
    end,
    power = function(c)
        local ok, v = pcall(UnitPower, "player", c.powerType)
        v = ok and ReadNumber(v)
        if not v then return false end
        return InRange(v, c.min, c.max)
    end,
    combat = function(c)
        local ok, v = pcall(UnitAffectingCombat, "player")
        if not ok or IsSecret(v) then return false end
        return (v and true or false) == c.combat
    end,
    hardcast = function(c, ctx)
        if not ctx or ctx.hardcast == nil then return false end -- unknown
        return ctx.hardcast == c.hardcast
    end,
}

function C.Kind(c)
    if type(c) ~= "table" then return nil end
    if c.aura then return "aura" end
    if c.power then return "power" end
    if c.combat ~= nil then return "combat" end
    if c.hardcast ~= nil then return "hardcast" end
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
        if include and not CHECKS[c.kind](c, ctx) then return false end
    end
    return true
end
