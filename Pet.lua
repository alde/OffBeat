local OffBeat = _G.OffBeat
local Pet = OffBeat:NewModule("Pet", "AceEvent-3.0")

-- Keeps your permanent pet alive and out (profile.pet):
--
--   pet = { quickSummon = 333889 }   -- optional: makes the next summon instant
--
-- Warns when the pet dies (or is missing when a pull starts) and when it
-- drops low, so you can pull it back or heal it. Training counts deaths and
-- time without a pet per fight (OFFBEAT_PET_LOST / OFFBEAT_PET_BACK).
-- Anything the game won't reveal counts as "don't know" and stays quiet.

local LOW, RECOVERED = 0.35, 0.60 -- warn at 35%, warn again after it's back over 60%

local ticker
local alive       -- true / false / nil (unknown) as of the last check
local lowWarned = false

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

local function Bool(fn, ...)
    if not fn then return nil end
    local ok, v = pcall(fn, ...)
    if not ok or OffBeat.Conditions.IsSecret(v) then return nil end
    return v and true or false
end

local function Number(fn, ...)
    if not fn then return nil end
    local ok, v = pcall(fn, ...)
    if not ok or v == nil or OffBeat.Conditions.IsSecret(v) then return nil end
    return tonumber(v)
end

-- true / false, or nil when the game won't say.
local function PetAlive()
    local exists = Bool(UnitExists, "pet")
    if exists == nil then return nil end
    if not exists then return false end
    local dead = Bool(UnitIsDead, "pet")
    if dead == nil then return nil end
    return not dead
end

local function PetHealth()
    local hp, max = Number(UnitHealth, "pet"), Number(UnitHealthMax, "pet")
    if not hp or not max or max <= 0 then return nil end
    return hp / max
end

-- No point nagging while you're dead, on a taxi or mounted.
local function CanAct()
    if Bool(UnitIsDeadOrGhost, "player") then return false end
    if Bool(UnitOnTaxi, "player") then return false end
    if Bool(IsMounted) then return false end
    return true
end

local function Warn(msg)
    if not GetSpecOr("petAlert") then return end
    local ss = GetSpecSettings()
    local key = ss and ss.petAlertSound
    if key then OffBeat:PlaySoundKey(key) else OffBeat:PlayConfigSound("petAlertSound") end
    OffBeat:Print("|cffff8800" .. msg .. "|r")
end

local function ResummonHint()
    local quick = OffBeat.activeProfile and OffBeat.activeProfile.pet and OffBeat.activeProfile.pet.quickSummon
    if quick and Bool(IsPlayerSpell, quick) then
        local info = C_Spell.GetSpellInfo(quick)
        return string.format(": %s, then resummon it", info and info.name or "instant summon")
    end
    return ": resummon it"
end

function Pet:OnEnable()
    alive, lowWarned = PetAlive(), false
    self:RegisterEvent("UNIT_PET")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function Pet:OnDisable()
    self:UnregisterAllEvents()
    if ticker then ticker:Cancel(); ticker = nil end
end

-- Compare with the last known state and report changes. Deaths are
-- reported in combat only; out of combat the pet just quietly comes back.
function Pet:Check()
    local now = PetAlive()
    if now == nil then return end
    local was = alive
    alive = now
    if was == true and now == false and UnitAffectingCombat("player") then
        self:SendMessage("OFFBEAT_PET_LOST", "died")
        if CanAct() then Warn("Your pet died" .. ResummonHint()) end
    elseif was == false and now == true then
        lowWarned = false
        self:SendMessage("OFFBEAT_PET_BACK")
    end
end

function Pet:UNIT_PET(_, unit)
    if unit == "player" then self:Check() end
end

function Pet:UNIT_HEALTH(_, unit)
    if unit ~= "pet" then return end
    self:Check()
    if not alive or not GetSpecOr("petLowHealthAlert") or not UnitAffectingCombat("player") then return end
    local pct = PetHealth()
    if not pct then return end
    if pct <= LOW and not lowWarned then
        lowWarned = true
        Warn(string.format("Pet at %d%% health: pull it back or heal it", math.floor(pct * 100 + 0.5)))
    elseif pct >= RECOVERED then
        lowWarned = false
    end
end

function Pet:PLAYER_REGEN_DISABLED()
    -- A beat later, so training has opened its fight first.
    C_Timer.After(0.2, function()
        alive = PetAlive()
        if alive == false and CanAct() then
            self:SendMessage("OFFBEAT_PET_LOST", "missing")
            Warn("No pet out" .. ResummonHint())
        end
    end)
    -- Deaths don't always come with an event the addon can see; look twice a second.
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(0.5, function() Pet:Check() end)
end

function Pet:PLAYER_REGEN_ENABLED()
    if ticker then ticker:Cancel(); ticker = nil end
    lowWarned = false
end
