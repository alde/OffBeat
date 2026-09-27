local OffBeat = _G.OffBeat
local Encounters = OffBeat:NewModule("Encounters", "AceEvent-3.0")

local MIN_ENCOUNTER_DURATION = 10
local DEFAULT_HISTORY_SIZE = 10
local MAX_HISTORY_SIZE = 50
local KEYSTONE_HISTORY_SIZE = 10

function Encounters:OnEnable()
    self:RegisterMessage("OFFBEAT_BUFF_APPLIED", "OnBuffApplied")
    self:RegisterMessage("OFFBEAT_BUFF_REMOVED", "OnBuffRemoved")
end

function Encounters:OnDisable()
    self:UnregisterAllMessages()
    self.previousEncounter = nil
end

-- Helpers

local function FormatDuration(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds - mins * 60
    return string.format("%dm %02ds", mins, secs)
end

local function CloseOpenIntervals(enc)
    local offset = enc.endTime - enc.startTime
    for _, targets in pairs(enc.uptimes) do
        for _, data in pairs(targets) do
            local intervals = data.intervals
            if #intervals > 0 and not intervals[#intervals].stop then
                intervals[#intervals].stop = offset
            end
        end
    end
end

local function OpenInterval(enc, guid, spellId, time)
    local offset = time - enc.startTime
    local core = OffBeat:GetModule("Core")

    if not enc.uptimes[spellId] then enc.uptimes[spellId] = {} end
    if not enc.uptimes[spellId][guid] then
        enc.uptimes[spellId][guid] = {
            name = core:GetName(guid),
            class = core:GetClass(guid),
            intervals = {},
        }
    end

    local intervals = enc.uptimes[spellId][guid].intervals
    if #intervals == 0 or intervals[#intervals].stop then
        intervals[#intervals + 1] = { start = offset }
    end
end

local function CloseInterval(enc, guid, spellId, time)
    local offset = time - enc.startTime
    if enc.uptimes[spellId] and enc.uptimes[spellId][guid] then
        local intervals = enc.uptimes[spellId][guid].intervals
        if #intervals > 0 and not intervals[#intervals].stop then
            intervals[#intervals].stop = offset
        end
    end
end

local function SnapshotBuffs(enc)
    for guid, spells in pairs(OffBeat.state.buffs) do
        for spellId in pairs(spells) do
            OpenInterval(enc, guid, spellId, enc.startTime)
        end
    end
end

local function PushHistory(enc)
    local key = enc.isKeystone and "keystoneHistory" or "history"
    local cap = enc.isKeystone and KEYSTONE_HISTORY_SIZE
        or math.min(OffBeat.db.profile.historySize or DEFAULT_HISTORY_SIZE, MAX_HISTORY_SIZE)

    local list = OffBeat.db.profile[key]
    list[#list + 1] = enc
    while #list > cap do
        table.remove(list, 1)
    end
end

local function NewEncounterData(now)
    return {
        active = true,
        startTime = now,
        endTime = 0,
        uptimes = {},
        timeline = {},
    }
end

-- Per-pull encounter tracking

function Encounters:StartEncounter()
    if OffBeat.state.encounter and not OffBeat.state.encounter.active then
        self.previousEncounter = OffBeat.state.encounter
    end

    local now = GetTime()
    OffBeat.state.encounter = NewEncounterData(now)
    SnapshotBuffs(OffBeat.state.encounter)
end

function Encounters:EndEncounter()
    local enc = OffBeat.state.encounter
    if not enc or not enc.active then return end

    enc.active = false
    enc.endTime = GetTime()
    CloseOpenIntervals(enc)

    if (enc.endTime - enc.startTime) < MIN_ENCOUNTER_DURATION then
        OffBeat.state.encounter = self.previousEncounter
        self.previousEncounter = nil
        return
    end
    self.previousEncounter = nil

    PushHistory(enc)
    self:SendMessage("OFFBEAT_ENCOUNTER_END", enc)
    if OffBeat.db.profile.chatOutput then
        self:PrintSummary(enc)
    end
end

function Encounters:IsActive()
    local enc = OffBeat.state.encounter
    return enc and enc.active
end

function Encounters:RecordApply(guid, spellId, time)
    local enc = OffBeat.state.encounter
    if not enc or not enc.active then return end

    local core = OffBeat:GetModule("Core")
    enc.timeline[#enc.timeline + 1] = {
        time = time - enc.startTime,
        spellId = spellId,
        guid = guid,
        name = core:GetName(guid),
        event = "APPLIED",
    }
    OpenInterval(enc, guid, spellId, time)
end

function Encounters:RecordRemove(guid, spellId, time)
    local enc = OffBeat.state.encounter
    if not enc or not enc.active then return end

    local core = OffBeat:GetModule("Core")
    enc.timeline[#enc.timeline + 1] = {
        time = time - enc.startTime,
        spellId = spellId,
        guid = guid,
        name = core:GetName(guid),
        event = "REMOVED",
    }
    CloseInterval(enc, guid, spellId, time)
end

function Encounters:OnBuffApplied(_, guid, spellId, aura, time)
    self:RecordApply(guid, spellId, time)
    local ks = OffBeat.state.keystone
    if ks and ks.active then OpenInterval(ks, guid, spellId, time) end
end

function Encounters:OnBuffRemoved(_, guid, spellId, time)
    self:RecordRemove(guid, spellId, time)
    local ks = OffBeat.state.keystone
    if ks and ks.active then CloseInterval(ks, guid, spellId, time) end
end

-- Uptime calculation

function Encounters:CalcUptime(enc, spellId)
    if not enc.uptimes[spellId] then return 0 end

    local duration = enc.endTime - enc.startTime
    if duration <= 0 then return 0 end

    local events = {}
    for _, data in pairs(enc.uptimes[spellId]) do
        for _, iv in ipairs(data.intervals) do
            events[#events + 1] = { time = iv.start, delta = 1 }
            events[#events + 1] = { time = iv.stop or duration, delta = -1 }
        end
    end
    table.sort(events, function(a, b)
        if a.time == b.time then return a.delta > b.delta end
        return a.time < b.time
    end)

    local covered, depth, lastTime = 0, 0, 0
    for _, ev in ipairs(events) do
        if depth > 0 then covered = covered + (ev.time - lastTime) end
        depth = depth + ev.delta
        lastTime = ev.time
    end
    return (covered / duration) * 100
end

function Encounters:CalcCombatUptime(enc, spellId)
    if not enc.uptimes[spellId] then return 0 end
    local ci = enc.combatIntervals
    if not ci or #ci == 0 then return 0 end

    local encDuration = enc.endTime - enc.startTime
    if encDuration <= 0 then return 0 end

    local totalCombat = 0
    for _, w in ipairs(ci) do
        totalCombat = totalCombat + ((w.stop or encDuration) - w.start)
    end
    if totalCombat <= 0 then return 0 end

    local events = {}
    for _, data in pairs(enc.uptimes[spellId]) do
        for _, iv in ipairs(data.intervals) do
            events[#events + 1] = { time = iv.start, delta = 1 }
            events[#events + 1] = { time = iv.stop or encDuration, delta = -1 }
        end
    end
    table.sort(events, function(a, b)
        if a.time == b.time then return a.delta > b.delta end
        return a.time < b.time
    end)

    local covered, depth, segStart = 0, 0, 0
    for _, ev in ipairs(events) do
        if depth > 0 and ev.time > segStart then
            for _, w in ipairs(ci) do
                local wStop = w.stop or encDuration
                local lo = math.max(segStart, w.start)
                local hi = math.min(ev.time, wStop)
                if hi > lo then covered = covered + (hi - lo) end
            end
        end
        depth = depth + ev.delta
        segStart = ev.time
    end

    return (covered / totalCombat) * 100
end

function Encounters:GetCurrentUptime(spellId)
    local enc = OffBeat.state.encounter
    if not enc or not enc.active then return nil end

    return self:CalcUptime({
        startTime = enc.startTime,
        endTime = GetTime(),
        uptimes = enc.uptimes,
    }, spellId)
end

-- Chat output

function Encounters:PrintSummary(enc)
    local label
    if enc.isKeystone then
        label = enc.keystoneName and enc.keystoneLevel
            and string.format("Keystone (%s +%d)", enc.keystoneName, enc.keystoneLevel)
            or "Keystone"
    else
        label = "Encounter"
    end
    OffBeat:Print(string.format("%s: %s", label, FormatDuration(enc.endTime - enc.startTime)))

    local buffs = OffBeat:GetModule("Buffs", true)
    local sortedSpells = buffs and buffs:GetSortedSpells() or {}
    for _, spellId in ipairs(sortedSpells) do
        if enc.uptimes[spellId] then
            local info = buffs:GetTrackedBuff(spellId)
            local name = info and info.name or tostring(spellId)
            local pct = self:CalcUptime(enc, spellId)
            if enc.isKeystone then
                local combat = self:CalcCombatUptime(enc, spellId)
                OffBeat:Print(string.format("  %s: %.1f%% overall / %.1f%% combat", name, pct, combat))
            else
                OffBeat:Print(string.format("  %s: %.1f%%", name, pct))
            end
        end
    end
end

-- Keystone tracking

function Encounters:StartKeystone()
    local now = GetTime()
    local ks = NewEncounterData(now)
    ks.combatIntervals = {}

    if C_ChallengeMode then
        local mapID = C_ChallengeMode.GetActiveChallengeMapID
            and C_ChallengeMode.GetActiveChallengeMapID()
        if mapID and C_ChallengeMode.GetMapUIInfo then
            ks.keystoneName = (C_ChallengeMode.GetMapUIInfo(mapID))
        end
        if C_ChallengeMode.GetActiveKeystoneInfo then
            ks.keystoneLevel = (C_ChallengeMode.GetActiveKeystoneInfo())
        end
    end

    OffBeat.state.keystone = ks
    SnapshotBuffs(ks)

    local label = ks.keystoneName and ks.keystoneLevel
        and string.format("%s +%d", ks.keystoneName, ks.keystoneLevel)
        or "keystone"
    OffBeat:Print(string.format("Tracking %s.", label))
end

function Encounters:EndKeystone()
    local ks = OffBeat.state.keystone
    if not ks or not ks.active then return end

    ks.active = false
    ks.endTime = GetTime()
    ks.isKeystone = true
    CloseOpenIntervals(ks)

    local ci = ks.combatIntervals
    if #ci > 0 and not ci[#ci].stop then
        ci[#ci].stop = ks.endTime - ks.startTime
    end

    PushHistory(ks)
    self:SendMessage("OFFBEAT_ENCOUNTER_END", ks)
    if OffBeat.db.profile.chatOutput then
        self:PrintSummary(ks)
    end
end

function Encounters:KeystoneCombatStart()
    local ks = OffBeat.state.keystone
    if not ks or not ks.active then return end

    local ci = ks.combatIntervals
    local offset = GetTime() - ks.startTime
    if #ci == 0 or ci[#ci].stop then
        ci[#ci + 1] = { start = offset }
    end
end

function Encounters:KeystoneCombatEnd()
    local ks = OffBeat.state.keystone
    if not ks or not ks.active then return end

    local ci = ks.combatIntervals
    if #ci > 0 and not ci[#ci].stop then
        ci[#ci].stop = GetTime() - ks.startTime
    end
end

function OffBeat:ResetEncounterData()
    OffBeat.state.encounter = nil
    OffBeat.state.keystone = nil
end
