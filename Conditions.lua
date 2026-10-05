local OffBeat = _G.OffBeat

-- Conditions shared by mistake rules (bad_cast) and cooldown window setup
-- checks. A `when` is one condition or a list of them that must all hold:
--
--   { aura = id, [minStacks = n], [maxStacks = n], [absent = true] }
--   { power = "SoulShards" | Enum.PowerType value, [min = n], [max = n] }
--   { combat = true | false }
--
-- A value that can't be read (secret, missing) never matches, so unreadable
-- state can only hide a result, never invent one.

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

local CHECKS = {
    aura = function(c)
        local auras = OffBeat:GetModule("Auras", true)
        if not auras then return false end
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
}

function C.Kind(c)
    if type(c) ~= "table" then return nil end
    if c.aura then return "aura" end
    if c.power then return "power" end
    if c.combat ~= nil then return "combat" end
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

--- True when every condition in a normalized list holds right now.
function C.Check(list)
    for _, c in ipairs(list) do
        if not CHECKS[c.kind](c) then return false end
    end
    return true
end
