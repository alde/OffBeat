local OffBeat = _G.OffBeat
local Config = OffBeat:NewModule("Config")
local LSM = LibStub("LibSharedMedia-3.0")

function OffBeat:GetDefaults()
    return {
        profile = {
            debug = false,
            locked = false,
            activeProfiles = {},
            importedProfiles = {},

            -- Shared display
            opacity = 0.85,
            borderTexture = "Blizzard Tooltip",
            barTexture = "Blizzard",
            font = "Friz Quadrata TT",
            fontSize = 10,
            fontOutline = "NONE",

            -- Buff panel (BuffDisplay)
            buffPanelShown = true,
            buffPanelPosition = nil,
            buffPanelWidth = nil,
            chatOutput = false,
            timelineShow = "both",
            keystoneTracking = true,
            historySize = 10,
            history = {},
            keystoneHistory = {},

            -- Rotation panel (RotationDisplay)
            rotationShown = true,
            rotationCombatOnly = false,
            historyCount = 6,
            growDirection = "right",
            iconSize = 40,
            iconAlpha = 1.0,
            opacityStep = 0.12,
            minOpacity = 0.3,
            bgAlpha = 0.8,
            rotationPosition = nil,

            -- Key cooldown icon
            keyCdAlert = true,
            keyCdSound = "talent_ready",
            keyCdSoundCustomId = "",
            keyCdDuration = 15,
            keyCdWasteAlert = true,
            keyCdWasteSound = "alarm1",
            keyCdWasteSoundCustomId = "",
            keyCdIconEnabled = true,
            keyCdCombatOnly = false,
            keyCdIconSize = 48,
            keyCdIconAlpha = 1.0,
            keyCdGlowStyle = "glow",
            keyCdGlowColor = nil,
            keyCdGlowIntensity = 0.9,
            keyCdIconPosition = nil,

            -- Next spell (Assisted Combat)
            assistedCombat = true,
            assistedCombatOnly = false,
            assistedIconSize = 48,
            assistedKeybindSize = 12,
            assistedPosition = nil,

            -- Alerts
            soundEnabled = true,
            mistakeSound = "raid_warning",
            mistakeSoundCustomId = "",
            castWarnings = true,
            idleCooldownAlert = true,
            idleCooldownNag = true,
            idleCooldownThreshold = 5,
            idleCooldownSound = "alarm1",
            idleCooldownSoundCustomId = "",
            procExpireAlert = true,
            procExpireSound = "alarm1",
            procExpireSoundCustomId = "",
            warningBgAlpha = 0.7,
            warningBorderAlpha = 0.6,
            warningPosition = nil,

            -- Behaviour
            combatReport = true,
            timelineAutoShow = false,
            clearOnCombatEnd = false,
            timelinePosition = nil,
            timelineWidth = nil,
        },
    }
end

-- LibSharedMedia helpers

function OffBeat:GetBarTexture()
    return LSM:Fetch("statusbar", self.db.profile.barTexture)
end

function OffBeat:GetFont(sizeOffset)
    local path = LSM:Fetch("font", self.db.profile.font)
    local size = self.db.profile.fontSize + (sizeOffset or 0)
    return path, size, self.db.profile.fontOutline
end

function OffBeat:GetBorderTexture()
    local name = self.db.profile.borderTexture
    if name == "None" then return nil end
    return LSM:Fetch("border", name)
end

function OffBeat:BuildBackdrop()
    local borderPath = self:GetBorderTexture()
    local backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 16,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    }
    if borderPath then
        backdrop.edgeFile = borderPath
        backdrop.edgeSize = 12
    end
    return backdrop
end

function OffBeat:ApplyAppearance()
    self:SendMessage("OFFBEAT_APPEARANCE_CHANGED")
end

function Config:OnEnable()
    -- Settings panel is added by the Settings module (Phase 4)
end
