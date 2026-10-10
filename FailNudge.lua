local OffBeat = _G.OffBeat
local FailNudge = OffBeat:NewModule("FailNudge", "AceEvent-3.0")

-- What to press instead when a press fails (profile.failNudges):
--
--   failNudges = {
--       { error = "runes", spells = { 49020, 207230 }, name = "Obliterate with no runes",
--         text = "No runes: Howling Blast on Rime, else Frost Strike" },
--       { error = "range", spells = { 49020, 49143 }, name = "Melee out of range",
--         text = "Out of range: Howling Blast on Rime, Glacial Advance" },
--   }
--
-- The game reports the failure as an error message (UI_ERROR_MESSAGE) and
-- the failed spell (UNIT_SPELLCAST_FAILED); the two are paired when they
-- arrive within a moment of each other, in either order. "runes" errors
-- only come from rune spells, so they also count when no spell arrives.
-- The hint flashes at most every few seconds while you keep pressing, and
-- each stretch of failed presses counts once in the training report.

local PAIR = 0.3      -- seconds between the error and the failed spell
local REPEAT = 2.5    -- seconds between flashes while it keeps failing
local BURST = 2.0     -- a gap this long starts a new stretch

local ERRORS = {
    runes = { "ERR_OUT_OF_RUNES", "SPELL_FAILED_NO_POWER_RUNES", text = { "Not enough runes" } },
    range = { "SPELL_FAILED_OUT_OF_RANGE", "ERR_OUT_OF_RANGE", text = { "Out of range" } },
}

local bySpellKind = {}   -- kind -> spellId -> nudge
local byKind = {}        -- kind -> nudges
local lastError          -- { kind, time }
local lastFailed         -- { spellId, time }
local lastShown, lastSeen = {}, {}

local IsSecret = function(v) return OffBeat.Conditions.IsSecret(v) end

local function GetSpecOr(key)
    local profile = OffBeat.activeProfile
    local specs = OffBeat.db.profile.specSettings
    local ss = profile and specs and specs[profile.meta.specId]
    if ss and ss[key] ~= nil then return ss[key] end
    return OffBeat.db.profile[key]
end

local function KindOf(message)
    if type(message) ~= "string" or IsSecret(message) then return nil end
    for kind, e in pairs(ERRORS) do
        for _, g in ipairs(e) do
            if _G[g] and _G[g] == message then return kind end
        end
        for _, t in ipairs(e.text) do
            if t == message then return kind end
        end
    end
end

function FailNudge:OnEnable()
    wipe(bySpellKind); wipe(byKind); wipe(lastShown); wipe(lastSeen)
    lastError, lastFailed = nil, nil
    for _, n in ipairs(OffBeat.activeProfile and OffBeat.activeProfile.failNudges or {}) do
        bySpellKind[n.error] = bySpellKind[n.error] or {}
        byKind[n.error] = byKind[n.error] or {}
        table.insert(byKind[n.error], n)
        for _, id in ipairs(n.spells or {}) do bySpellKind[n.error][id] = n end
    end
    self:RegisterEvent("UI_ERROR_MESSAGE")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
end

function FailNudge:OnDisable()
    self:UnregisterAllEvents()
end

function FailNudge:Fire(nudge, spellId)
    if not GetSpecOr("failNudge") then return end
    local now = GetTime()
    local key = nudge.name or nudge.text
    -- a new stretch of failed presses counts once (training report)
    if not lastSeen[key] or now - lastSeen[key] > BURST then
        if UnitAffectingCombat("player") then
            self:SendMessage("OFFBEAT_FAIL_STRETCH", spellId or 0, key)
        end
    end
    lastSeen[key] = now
    if lastShown[key] and now - lastShown[key] < REPEAT then return end
    lastShown[key] = now
    self:SendMessage("OFFBEAT_FAIL_NUDGE", nudge.text)
end

function FailNudge:Match(kind, spellId)
    local n = spellId and bySpellKind[kind] and bySpellKind[kind][spellId]
    if n then self:Fire(n, spellId) end
end

function FailNudge:UI_ERROR_MESSAGE(_, _, message)
    local kind = KindOf(message)
    if not kind or not byKind[kind] then return end
    local now = GetTime()
    if lastFailed and now - lastFailed.time <= PAIR then
        local spellId = lastFailed.spellId
        lastFailed = nil
        return self:Match(kind, spellId)
    end
    lastError = { kind = kind, time = now }
    if kind == "runes" then
        -- no spell yet: wait a moment for it, else take the first rune nudge
        local token = lastError
        C_Timer.After(PAIR, function()
            if lastError == token then
                lastError = nil
                FailNudge:Fire(byKind.runes[1])
            end
        end)
    end
end

function FailNudge:UNIT_SPELLCAST_FAILED(_, unit, _, spellId)
    if unit ~= "player" or spellId == nil or IsSecret(spellId) then return end
    local now = GetTime()
    if lastError and now - lastError.time <= PAIR then
        local kind = lastError.kind
        lastError = nil
        return self:Match(kind, spellId)
    end
    lastFailed = { spellId = spellId, time = now }
end
