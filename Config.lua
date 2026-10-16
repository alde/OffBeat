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
            borderTexture = "Flat",          -- 1px line; or any SharedMedia border, or "None"
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
            assistedKeybindShown = true,
            assistedKeybindSize = 12,
            assistedPosition = nil,

            -- Key Layout page
            keyLayoutView = "both",          -- both | st | aoe
            keyLayoutShowUntalented = false,

            -- Cooldown window coaching (Windows)
            windowLive = true,   -- live counter during the window
            windowChat = true,   -- scorecard in chat when it closes
            windowPosition = nil,
            lastTrainingReport = nil, -- shown again by /ob report
            trainingCombatLog = true, -- turn on combat logging while training
            trainingBossOnly = true,  -- in raids, only boss encounters count
            trainingReportPosition = nil,
            trainingResume = nil,     -- session parked across a /reload

            -- Alerts
            soundEnabled = true,
            mistakeSound = "raid_warning",
            mistakeSoundCustomId = "",
            castWarnings = true,
            specSettings = {},
            idleCooldownAlert = true,
            petAlert = true,             -- pet died / no pet at the pull
            petAlertSound = "raid_warning",
            petAlertSoundCustomId = "",
            petLowHealthAlert = true,    -- pet under 35% in combat
            movingNudge = true,          -- "Demonbolt is instant" while moving and not casting
            movingNudgeDelay = 1.5,
            movingNudgeSound = "map_ping",
            movingNudgeSoundCustomId = "",
            failNudge = true,            -- "No runes: ..." when a press fails (profiles with failNudges)
            prepEnabled = true,          -- countdown to the main cooldown with what to hold (profiles with prep)
            prepLead = nil,              -- seconds before; nil = the profile's lead
            showSheet = true,            -- rotation cheat sheet (profiles with rotationSheet)
            barSwapOffer = true,         -- offer the raid / M+ bar layout when the content changes
            sheetHideInCombat = false,
            sheetPosition = nil,
            idleCooldownNag = true,
            idleCooldownThreshold = 5,
            trackRacials = true, -- add offensive racials (Berserking, Blood Fury, ...) to idle tracking
            idleCooldownSound = "alarm1",
            idleCooldownSoundCustomId = "",
            procExpireAlert = true,
            procExpireSound = "alarm1",
            procExpireSoundCustomId = "",
            warningBgAlpha = 0.7,
            warningBorderAlpha = 0.6,
            warningPosition = nil,

            -- Behaviour
            contentMode = "auto",        -- auto | raid | mythic (OffBeat:ContentMode)
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
    local outline = self.db.profile.fontOutline
    if outline == "NONE" then outline = "" end
    return path, size, outline
end

function OffBeat:GetBorderTexture()
    local name = self.db.profile.borderTexture
    if name == "None" or name == "Flat" then return nil end
    return LSM:Fetch("border", name)
end

-- Panel backdrop: flat colour fill (callers set it with SetBackdropColor)
-- with the border from Panels > All panels: a 1px line ("Flat", the
-- default), a SharedMedia border, or none.
function OffBeat:BuildBackdrop()
    local name = self.db.profile.borderTexture
    if name == "Flat" then return OffBeat.FLAT_BACKDROP end
    local borderPath = self:GetBorderTexture()
    local backdrop = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    }
    if borderPath then
        backdrop.edgeFile = borderPath
        backdrop.edgeSize = 12
    else
        backdrop.insets = { left = 0, right = 0, top = 0, bottom = 0 }
    end
    return backdrop
end

function OffBeat:ApplyAppearance()
    self:SendMessage("OFFBEAT_APPEARANCE_CHANGED")
end

function Config:OnEnable()
    -- Settings panel is added by the Settings module (Phase 4)
end
