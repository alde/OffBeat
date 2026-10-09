local OffBeat = _G.OffBeat
local Moving = OffBeat:NewModule("Moving", "AceEvent-3.0")

-- A nudge for casting while you move (profile.movingCasts):
--
--   movingCasts = { { spellId = 264178, name = "Demonbolt" } }
--
-- When you've been moving for a moment without casting anything and one of
-- these spells is instant and usable right now (Demonbolt with a Demonic
-- Core), flash "Moving: Demonbolt is instant". Once per stretch of
-- movement. Anything the game won't reveal counts as "no" and stays quiet.

local TICK = 0.25

local ticker
local movingSince   -- GetTime() when the current stretch of movement began
local lastCast = 0  -- last successful cast or cast in progress
local nudged = false

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

local function Readable(ok, v)
    if not ok or v == nil or OffBeat.Conditions.IsSecret(v) then return nil end
    return v
end

local function IsMoving()
    if not GetUnitSpeed then return false end
    local speed = Readable(pcall(GetUnitSpeed, "player"))
    return speed ~= nil and tonumber(speed) > 0
end

local function IsCasting()
    local name = Readable(pcall(UnitCastingInfo, "player"))
    if name then return true end
    name = Readable(pcall(UnitChannelInfo, "player"))
    return name and true or false
end

-- Known, usable and instant right now.
local function InstantNow(spellId)
    local known = Readable(pcall(IsPlayerSpell, spellId))
    if not known then return false end
    local info = Readable(pcall(C_Spell.GetSpellInfo, spellId))
    local castTime = info and Readable(true, info.castTime)
    if castTime == nil or tonumber(castTime) ~= 0 then return false end
    local usable = Readable(pcall(C_Spell.IsSpellUsable, spellId))
    return usable and true or false
end

function Moving:OnEnable()
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function Moving:OnDisable()
    self:UnregisterAllEvents()
    if ticker then ticker:Cancel(); ticker = nil end
end

function Moving:UNIT_SPELLCAST_SUCCEEDED(_, unit)
    if unit == "player" then lastCast = GetTime() end
end

function Moving:PLAYER_REGEN_DISABLED()
    movingSince, nudged, lastCast = nil, false, GetTime()
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(TICK, function() Moving:Tick() end)
end

function Moving:PLAYER_REGEN_ENABLED()
    if ticker then ticker:Cancel(); ticker = nil end
    movingSince, nudged = nil, false
end

function Moving:Tick()
    if not GetSpecOr("movingNudge") then return end
    local now = GetTime()
    if IsCasting() then lastCast = now end
    if not IsMoving() then
        movingSince, nudged = nil, false
        return
    end
    movingSince = movingSince or now
    local delay = GetSpecOr("movingNudgeDelay") or 1.5
    if nudged or now - movingSince < delay or now - lastCast < delay then return end
    for _, entry in ipairs(OffBeat.activeProfile and OffBeat.activeProfile.movingCasts or {}) do
        if InstantNow(entry.spellId) then
            nudged = true
            local ss = GetSpecSettings()
            local key = ss and ss.movingNudgeSound
            if key then OffBeat:PlaySoundKey(key) else OffBeat:PlayConfigSound("movingNudgeSound") end
            self:SendMessage("OFFBEAT_MOVING_INSTANT", entry.spellId, entry.name)
            return
        end
    end
end
