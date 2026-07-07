local OffBeat = LibStub("AceAddon-3.0"):NewAddon("OffBeat", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
_G.OffBeat = OffBeat

OffBeat:SetDefaultModuleState(false)

OffBeat.VERSION = "1.0.0"

OffBeat.profiles = {}
OffBeat.activeProfile = nil
OffBeat.activeSpecId = nil

OffBeat.state = {
    buffs = {},
    roster = {},
    encounter = nil,
    keystone = nil,
    history = {},
    lastSpellId = nil,
    auras = {},
    combat = nil,
}

local FEATURE_MODULES = {
    trackedBuffs   = { "Buffs", "BuffDisplay", "BuffTimeline" },
    castWarnings   = { "Warnings" },
    trackedAuras   = { "Auras" },
    rotationSpells = { "Rotation", "RotationDisplay", "RotationTimeline" },
}

local ALL_FEATURE_MODULE_NAMES = {}
do
    local seen = {}
    for _, modules in pairs(FEATURE_MODULES) do
        for _, name in ipairs(modules) do
            if not seen[name] then
                seen[name] = true
                ALL_FEATURE_MODULE_NAMES[#ALL_FEATURE_MODULE_NAMES + 1] = name
            end
        end
    end
end

local ALWAYS_ON_MODULES = { "Core", "Encounters" }

-- Debug logging (deduped)

local lastDebugMsg = ""

function OffBeat:Debug(...)
    if not (self.db and self.db.profile.debug) then return end
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    local msg = table.concat(parts, " ")
    if msg == lastDebugMsg then return end
    lastDebugMsg = msg
    self:Print("|cff888888[debug]|r", msg)
end

-- Profile registry

function OffBeat:RegisterProfile(profile)
    if not profile or not profile.meta then
        error("OffBeat:RegisterProfile requires a profile with a meta table", 2)
    end
    local meta = profile.meta
    if not meta.specId or not meta.name then
        error("OffBeat:RegisterProfile requires meta.specId and meta.name", 2)
    end

    local valid, err = self:ValidateProfile(profile)
    if not valid then
        error("OffBeat:RegisterProfile validation failed: " .. err, 2)
    end

    self.profiles[meta.specId] = self.profiles[meta.specId] or {}
    table.insert(self.profiles[meta.specId], profile)
end

-- Class colour helpers

function OffBeat:GetClassColor()
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return 0.6, 0.6, 0.6
end

function OffBeat:GetGlowColor()
    local c = self.db.profile.keyCdGlowColor
    if c then return c.r, c.g, c.b end
    return self:GetClassColor()
end

-- Lifecycle

function OffBeat:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("OffBeatDB", self:GetDefaults(), true)
    self:MergeImportedProfiles()

    self:RegisterChatCommand("offbeat", "OnSlashCommand")
    self:RegisterChatCommand("ob", "OnSlashCommand")
end

function OffBeat:OnEnable()
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    local config = self:GetModule("Config", true)
    if config then config:Enable() end

    self:LoadForCurrentSpec()
end

function OffBeat:PLAYER_SPECIALIZATION_CHANGED(_, unit)
    if unit and unit ~= "player" then return end
    self:LoadForCurrentSpec()
end

function OffBeat:LoadForCurrentSpec()
    local spec = GetSpecialization()
    local specId = spec and GetSpecializationInfo(spec)

    if specId == self.activeSpecId then return end

    if self.activeProfile then
        self:DisableFeatureModules()
    end

    self:WipeState()
    self.activeSpecId = specId
    self.activeProfile = nil

    if not specId then return end

    local available = self.profiles[specId]
    if not available or #available == 0 then return end

    local savedName = self.db.profile.activeProfiles and self.db.profile.activeProfiles[specId]
    local profile = available[1]
    if savedName then
        for _, p in ipairs(available) do
            if p.meta.name == savedName then
                profile = p
                break
            end
        end
    end

    self.activeProfile = profile
    self:EnableModulesForProfile(profile)
    self:Debug("Loaded profile:", profile.meta.name)
end

function OffBeat:EnableModulesForProfile(profile)
    for _, name in ipairs(ALWAYS_ON_MODULES) do
        local mod = self:GetModule(name, true)
        if mod and not mod:IsEnabled() then mod:Enable() end
    end

    for section, modules in pairs(FEATURE_MODULES) do
        if profile[section] then
            for _, name in ipairs(modules) do
                local mod = self:GetModule(name, true)
                if mod and not mod:IsEnabled() then mod:Enable() end
            end
        end
    end
end

function OffBeat:DisableFeatureModules()
    for i = #ALL_FEATURE_MODULE_NAMES, 1, -1 do
        local mod = self:GetModule(ALL_FEATURE_MODULE_NAMES[i], true)
        if mod and mod:IsEnabled() then mod:Disable() end
    end

    for i = #ALWAYS_ON_MODULES, 1, -1 do
        local mod = self:GetModule(ALWAYS_ON_MODULES[i], true)
        if mod and mod:IsEnabled() then mod:Disable() end
    end
end

function OffBeat:WipeState()
    wipe(self.state.buffs)
    wipe(self.state.roster)
    wipe(self.state.history)
    wipe(self.state.auras)
    self.state.encounter = nil
    self.state.keystone = nil
    self.state.rotationKeystone = nil
    self.state.combat = nil
    self.state.lastSpellId = nil
end

-- Merge imported profiles from SavedVariables into the registry

function OffBeat:MergeImportedProfiles()
    local imported = self.db.profile.importedProfiles
    if not imported then return end

    for _, profile in pairs(imported) do
        local valid = self:ValidateProfile(profile)
        if valid then
            local specId = profile.meta.specId
            self.profiles[specId] = self.profiles[specId] or {}
            table.insert(self.profiles[specId], profile)
        end
    end
end

-- Slash commands

function OffBeat:OnSlashCommand(input)
    local cmd = self:GetArgs(input, 1)
    cmd = cmd and cmd:lower() or ""

    if cmd == "" then
        self:ToggleDisplay()
    elseif cmd == "config" or cmd == "options" then
        self:OpenConfig()
    elseif cmd == "timeline" or cmd == "tl" then
        self:ToggleTimeline()
    elseif cmd == "lock" then
        self:ToggleLock()
    elseif cmd == "reset" then
        self:ResetEncounterData()
        self:Print("Encounter data reset.")
    elseif cmd == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        self:Print("Debug " .. (self.db.profile.debug and "enabled" or "disabled") .. ".")
    elseif cmd == "test" then
        self:InjectTestData()
    elseif cmd == "profile" then
        local _, name = self:GetArgs(input, 2)
        if name then
            self:SwitchProfile(name)
        else
            self:PrintAvailableProfiles()
        end
    else
        self:Print("OffBeat v" .. self.VERSION)
        self:Print("  /ob              — Toggle display")
        self:Print("  /ob config       — Open settings")
        self:Print("  /ob timeline     — Toggle timeline")
        self:Print("  /ob lock         — Lock/unlock frames")
        self:Print("  /ob reset        — Reset encounter data")
        self:Print("  /ob profile      — List/switch profiles")
        self:Print("  /ob debug        — Toggle debug logging")
        self:Print("  /ob test         — Inject test data")
    end
end

function OffBeat:SwitchProfile(name)
    if not self.activeSpecId then
        self:Print("No spec detected.")
        return
    end

    local available = self.profiles[self.activeSpecId]
    if not available then
        self:Print("No profiles for current spec.")
        return
    end

    for _, p in ipairs(available) do
        if p.meta.name:lower():find(name:lower(), 1, true) then
            self.db.profile.activeProfiles = self.db.profile.activeProfiles or {}
            self.db.profile.activeProfiles[self.activeSpecId] = p.meta.name

            self:DisableFeatureModules()
            self:WipeState()
            self.activeProfile = p
            self:EnableModulesForProfile(p)

            self:Print("Switched to: " .. p.meta.name)
            return
        end
    end

    self:Print("No profile matching '" .. name .. "' found.")
    self:PrintAvailableProfiles()
end

function OffBeat:PrintAvailableProfiles()
    if not self.activeSpecId then
        self:Print("No spec detected.")
        return
    end

    local available = self.profiles[self.activeSpecId]
    if not available or #available == 0 then
        self:Print("No profiles for current spec.")
        return
    end

    self:Print("Available profiles:")
    for _, p in ipairs(available) do
        local marker = (self.activeProfile == p) and " |cff00ff00(active)|r" or ""
        self:Print("  " .. p.meta.name .. marker)
    end
end

-- Stub methods overridden by display/timeline modules
function OffBeat:ToggleDisplay() end
function OffBeat:OpenConfig() end
function OffBeat:ToggleTimeline() end
function OffBeat:ResetEncounterData() end
function OffBeat:InjectTestData() end

function OffBeat:SetLocked(locked)
    self.db.profile.locked = locked
    self:SendMessage("OFFBEAT_LOCK_CHANGED", locked)
end

function OffBeat:ToggleLock()
    self:SetLocked(not self.db.profile.locked)
    self:Print("Frames " .. (self.db.profile.locked and "locked" or "unlocked") .. ".")
end
