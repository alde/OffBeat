local OffBeat = _G.OffBeat
local Core = OffBeat:NewModule("Core", "AceEvent-3.0", "AceTimer-3.0")

function Core:OnEnable()
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("CHALLENGE_MODE_RESET")
    self:RegisterEvent("PLAYER_UNGHOST")

    self.refreshTimer = self:ScheduleRepeatingTimer("RefreshDisplay", 0.5)
    self:RebuildRoster()
end

function Core:OnDisable()
    if self.refreshTimer then
        self:CancelTimer(self.refreshTimer)
        self.refreshTimer = nil
    end
end

-- Roster management

function Core:RebuildRoster()
    local roster = {}

    self:AddUnitToRoster(roster, "player")

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            self:AddUnitToRoster(roster, "raid" .. i)
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            self:AddUnitToRoster(roster, "party" .. i)
        end
    end

    OffBeat.state.roster = roster
    self:SendMessage("OFFBEAT_ROSTER_UPDATED")
end

function Core:AddUnitToRoster(roster, unitId)
    local guid = UnitGUID(unitId)
    if not guid then return end

    roster[guid] = {
        name = UnitName(unitId) or "Unknown",
        unitId = unitId,
        class = select(2, UnitClass(unitId)) or "WARRIOR",
    }
end

function Core:GetName(guid)
    local entry = OffBeat.state.roster[guid]
    if entry then return entry.name end

    self:ResolveGUID(guid)
    entry = OffBeat.state.roster[guid]
    return entry and entry.name or "Unknown"
end

function Core:GetClass(guid)
    local entry = OffBeat.state.roster[guid]
    if entry then return entry.class end

    self:ResolveGUID(guid)
    entry = OffBeat.state.roster[guid]
    return entry and entry.class or "WARRIOR"
end

function Core:ResolveGUID(guid)
    local prefix, count
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        prefix, count = "party", GetNumGroupMembers() - 1
    else
        return
    end

    for i = 1, count do
        local unitId = prefix .. i
        if UnitGUID(unitId) == guid then
            self:AddUnitToRoster(OffBeat.state.roster, unitId)
            return
        end
    end
end

-- Combat events

function Core:GROUP_ROSTER_UPDATE()
    self:RebuildRoster()
    for guid in pairs(OffBeat.state.buffs) do
        if not OffBeat.state.roster[guid] then
            OffBeat.state.buffs[guid] = nil
        end
    end
end

function Core:PLAYER_REGEN_DISABLED()
    OffBeat:InvalidateKeybindCache()
    self:SendMessage("OFFBEAT_COMBAT_START")

    local encounters = OffBeat:GetModule("Encounters", true)
    if encounters and encounters:IsEnabled() then
        encounters:StartEncounter()
        encounters:KeystoneCombatStart()
    end
end

function Core:PLAYER_REGEN_ENABLED()
    local encounters = OffBeat:GetModule("Encounters", true)
    if encounters and encounters:IsEnabled() then
        encounters:KeystoneCombatEnd()
    end

    if UnitIsDeadOrGhost("player") then
        self.diedInCombat = true
        return
    end

    self:SendMessage("OFFBEAT_COMBAT_END")
    if encounters and encounters:IsEnabled() then
        encounters:EndEncounter()
    end
end

function Core:PLAYER_UNGHOST()
    if self.diedInCombat then
        self.diedInCombat = false
        self:SendMessage("OFFBEAT_COMBAT_END")
        local encounters = OffBeat:GetModule("Encounters", true)
        if encounters and encounters:IsEnabled() then
            encounters:EndEncounter()
        end
    end
end

function Core:PLAYER_ENTERING_WORLD()
    self:RebuildRoster()
    self.diedInCombat = false
    OffBeat:InvalidateKeybindCache()

    if OffBeat.db.profile.keystoneTracking
        and C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive()
        and not OffBeat.state.keystone then
        local encounters = OffBeat:GetModule("Encounters", true)
        if encounters and encounters:IsEnabled() then
            encounters:StartKeystone()
        end
    end
end

function Core:CHALLENGE_MODE_START()
    if not OffBeat.db.profile.keystoneTracking then return end
    local encounters = OffBeat:GetModule("Encounters", true)
    if encounters and encounters:IsEnabled() then
        encounters:StartKeystone()
    end
end

function Core:CHALLENGE_MODE_COMPLETED()
    local encounters = OffBeat:GetModule("Encounters", true)
    if encounters and encounters:IsEnabled() then
        encounters:EndKeystone()
    end
end

function Core:CHALLENGE_MODE_RESET()
    local encounters = OffBeat:GetModule("Encounters", true)
    if encounters and encounters:IsEnabled() then
        encounters:EndKeystone()
    end
end

function Core:RefreshDisplay()
    self:SendMessage("OFFBEAT_DISPLAY_REFRESH")
end
