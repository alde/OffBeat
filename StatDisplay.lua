local OffBeat = _G.OffBeat
local StatDisplay = OffBeat:NewModule("StatDisplay", "AceEvent-3.0", "AceTimer-3.0")

local PADDING = 8
local ROW_HEIGHT = 18
local BAR_HEIGHT = 10
local PANEL_WIDTH = 250
local COMPACT_HEIGHT = 52
local FULL_HEIGHT = 182

-- WoW Combat Rating constants fallback
local CR_CRIT = _G.CR_CRIT_MELEE or 9
local CR_HASTE = _G.CR_HASTE_MELEE or 18
local CR_MASTERY = _G.CR_MASTERY or 26
local CR_VERSATILITY = _G.CR_VERSATILITY_DAMAGE_DONE or 29


local function IsSecret(val)
    if val == nil then return false end
    if _G.issecretvalue then
        local ok, secret = pcall(_G.issecretvalue, val)
        return ok and secret
    end
    return false
end

local function SafeNumber(val, default)
    if val == nil or IsSecret(val) then return default or 0 end
    local ok, num = pcall(tonumber, val)
    if ok and num and not IsSecret(num) then
        return num
    end
    return default or 0
end

local function SafeIsPlayerSpell(spellId)
    if not spellId then return false end
    local ok, res = pcall(IsPlayerSpell, spellId)
    return ok and res and not IsSecret(res)
end

local cachedStats = {}

-- Stat Definitions
local STAT_ORDER = { "CRIT", "HASTE", "MASTERY", "VERS" }

local STATS = {
    CRIT = {
        key = "CRIT",
        name = "Critical Strike",
        short = "Crit",
        crIndex = CR_CRIT,
        color = { 1.0, 0.49, 0.04 },
        hex = "ff7d0a",
        getVal = function()
            local ok, val = pcall(GetCritChance)
            return (ok and not IsSecret(val) and val) or 0
        end,
    },
    HASTE = {
        key = "HASTE",
        name = "Haste",
        short = "Haste",
        crIndex = CR_HASTE,
        color = { 1.0, 0.82, 0.0 },
        hex = "ffd100",
        getVal = function()
            local ok, val = pcall(GetHaste)
            return (ok and not IsSecret(val) and val) or 0
        end,
    },
    MASTERY = {
        key = "MASTERY",
        name = "Mastery",
        short = "Mastery",
        crIndex = CR_MASTERY,
        color = { 0.70, 0.40, 1.0 },
        hex = "b366ff",
        getVal = function()
            local ok, val = pcall(GetMasteryEffect)
            return (ok and not IsSecret(val) and val) or 0
        end,
    },
    VERS = {
        key = "VERS",
        name = "Versatility",
        short = "Vers",
        crIndex = CR_VERSATILITY,
        color = { 0.20, 0.80, 0.95 },
        hex = "33ccf2",
        getVal = function()
            local okB, bonus = pcall(GetCombatRatingBonus, CR_VERSATILITY)
            if not okB or not bonus or IsSecret(bonus) then return 0 end
            local extra = 0
            if GetVersatilityBonus then
                local okE, e = pcall(GetVersatilityBonus, CR_VERSATILITY)
                if okE and e and not IsSecret(e) then extra = e end
            end
            local numB = SafeNumber(bonus, 0)
            local numE = SafeNumber(extra, 0)
            return numB + numE
        end,
    },
}


-- Comprehensive Stat Priority Database by Spec ID and Hero Talent Tree
-- Sourced from Method, Icy Veins, and Archon guides for The War Within / retail
local SPEC_STAT_PRIORITIES = {
    -- Death Knight
    [250] = { -- Blood
        specName = "Blood Death Knight",
        default = "Haste > Critical Strike >= Mastery > Versatility",
        heroTrees = {
            ["Deathbringer"] = "Haste > Critical Strike >= Mastery > Versatility",
            ["San'layn"]     = "Haste >= Mastery > Critical Strike > Versatility",
        },
    },
    [251] = { -- Frost
        specName = "Frost Death Knight",
        default = "Critical Strike >= Mastery > Haste > Versatility",
        heroTrees = {
            ["Deathbringer"]            = "Mastery > Haste > Critical Strike > Versatility",
            ["Rider of the Apocalypse"] = "Critical Strike >= Mastery > Haste > Versatility",
        },
    },
    [252] = { -- Unholy
        specName = "Unholy Death Knight",
        default = "Mastery > Haste > Critical Strike > Versatility",
        heroTrees = {
            ["Rider of the Apocalypse"] = "Mastery > Haste > Critical Strike > Versatility",
            ["San'layn"]                 = "Haste > Mastery > Critical Strike > Versatility",
        },
    },

    -- Demon Hunter
    [577] = { -- Havoc
        specName = "Havoc Demon Hunter",
        default = "Critical Strike > Mastery > Haste > Versatility",
        heroTrees = {
            ["Aldrachi Reaver"] = "Critical Strike > Mastery > Haste > Versatility",
            ["Fel-Scarred"]     = "Critical Strike > Mastery > Versatility > Haste",
        },
    },
    [581] = { -- Vengeance
        specName = "Vengeance Demon Hunter",
        default = "Haste > Critical Strike >= Versatility > Mastery",
        heroTrees = {
            ["Aldrachi Reaver"] = "Haste > Critical Strike >= Versatility > Mastery",
            ["Fel-Scarred"]     = "Haste > Versatility >= Critical Strike > Mastery",
        },
    },

    -- Paladin
    [65] = { -- Holy
        specName = "Holy Paladin",
        default = "Haste > Critical Strike >= Mastery > Versatility",
        heroTrees = {
            ["Herald of the Sun"] = "Critical Strike > Haste > Mastery > Versatility",
            ["Lightsmith"]        = "Haste > Critical Strike > Mastery > Versatility",
        },
    },
    [66] = { -- Protection
        specName = "Protection Paladin",
        default = "Haste > Mastery >= Versatility > Critical Strike",
        heroTrees = {
            ["Templar"]    = "Haste > Versatility > Mastery > Critical Strike",
            ["Lightsmith"] = "Haste > Mastery > Versatility > Critical Strike",
        },
    },
    [70] = { -- Retribution
        specName = "Retribution Paladin",
        default = "Mastery >= Haste > Critical Strike > Versatility",
        heroTrees = {
            ["Herald of the Sun"] = "Mastery > Haste > Critical Strike > Versatility",
            ["Templar"]           = "Haste > Mastery >= Critical Strike > Versatility",
        },
    },

    -- Evoker
    [1467] = { -- Devastation
        specName = "Devastation Evoker",
        default = "Critical Strike >= Mastery > Haste > Versatility",
        heroTrees = {
            ["Flameshaper"]    = "Mastery > Critical Strike > Haste > Versatility",
            ["Scalecommander"] = "Critical Strike >= Mastery > Haste > Versatility",
        },
    },
    [1468] = { -- Preservation
        specName = "Preservation Evoker",
        default = "Mastery > Critical Strike > Haste > Versatility",
        heroTrees = {
            ["Chronowarden"] = "Mastery > Haste > Critical Strike > Versatility",
            ["Flameshaper"]  = "Mastery > Critical Strike > Versatility > Haste",
        },
    },
    [1473] = { -- Augmentation
        specName = "Augmentation Evoker",
        default = "Mastery > Haste > Critical Strike > Versatility",
        heroTrees = {
            ["Chronowarden"]   = "Mastery > Haste > Critical Strike > Versatility",
            ["Scalecommander"] = "Mastery > Critical Strike > Haste > Versatility",
        },
    },

    -- Monk
    [268] = { -- Brewmaster
        specName = "Brewmaster Monk",
        default = "Versatility >= Critical Strike > Mastery > Haste",
        heroTrees = {
            ["Master of Harmony"] = "Versatility >= Critical Strike > Mastery > Haste",
            ["Shado-Pan"]         = "Critical Strike >= Versatility > Mastery > Haste",
        },
    },
    [269] = { -- Windwalker
        specName = "Windwalker Monk",
        default = "Mastery >= Critical Strike > Versatility > Haste",
        heroTrees = {
            ["Conduit of the Celestials"] = "Mastery >= Critical Strike > Versatility > Haste",
            ["Shado-Pan"]                 = "Mastery >= Critical Strike > Haste > Versatility",
        },
    },
    [270] = { -- Mistweaver
        specName = "Mistweaver Monk",
        default = "Haste >= Critical Strike > Versatility > Mastery",
        heroTrees = {
            ["Conduit of the Celestials"] = "Haste >= Critical Strike > Versatility > Mastery",
            ["Master of Harmony"]         = "Haste >= Mastery > Critical Strike > Versatility",
        },
    },

    -- Shaman
    [262] = { -- Elemental
        specName = "Elemental Shaman",
        default = "Mastery >= Haste > Critical Strike > Versatility",
        heroTrees = {
            ["Stormbringer"] = "Haste >= Mastery > Critical Strike > Versatility",
            ["Farseer"]      = "Mastery > Haste > Critical Strike > Versatility",
        },
    },
    [263] = { -- Enhancement
        specName = "Enhancement Shaman",
        default = "Mastery > Haste > Critical Strike > Versatility",
        heroTrees = {
            ["Stormbringer"] = "Mastery > Haste > Critical Strike > Versatility",
            ["Totemic"]      = "Haste > Mastery > Critical Strike > Versatility",
        },
    },
    [264] = { -- Restoration
        specName = "Restoration Shaman",
        default = "Critical Strike > Versatility >= Haste > Mastery",
        heroTrees = {
            ["Totemic"] = "Critical Strike > Haste >= Versatility > Mastery",
            ["Farseer"] = "Critical Strike > Versatility >= Mastery > Haste",
        },
    },

    -- Warlock
    [258] = { -- Affliction
        specName = "Affliction Warlock",
        default = "Mastery > Haste > Critical Strike > Versatility",
        heroTrees = {
            ["Hellcaller"]     = "Mastery > Haste > Critical Strike > Versatility",
            ["Soul Harvester"] = "Haste > Mastery > Critical Strike > Versatility",
        },
    },
    [259] = { -- Demonology
        specName = "Demonology Warlock",
        default = "Haste > Critical Strike > Mastery > Versatility",
        heroTrees = {
            ["Diabolist"]      = "Haste > Critical Strike > Mastery > Versatility",
            ["Soul Harvester"] = "Haste > Mastery > Critical Strike > Versatility",
        },
    },
    [267] = { -- Destruction
        specName = "Destruction Warlock",
        default = "Haste > Mastery >= Critical Strike > Versatility",
        heroTrees = {
            ["Diabolist"]  = "Haste > Critical Strike >= Mastery > Versatility",
            ["Hellcaller"] = "Haste > Mastery >= Critical Strike > Versatility",
        },
    },

    -- Mage
    [62] = { -- Arcane
        specName = "Arcane Mage",
        default = "Haste > Mastery > Versatility > Critical Strike",
        heroTrees = {
            ["Spellslinger"] = "Haste > Mastery > Critical Strike > Versatility",
            ["Sunfury"]      = "Haste > Mastery > Versatility > Critical Strike",
        },
    },
    [63] = { -- Fire
        specName = "Fire Mage",
        default = "Haste > Mastery > Versatility > Critical Strike",
        heroTrees = {
            ["Frostfire"] = "Haste > Mastery > Versatility > Critical Strike",
            ["Sunfury"]   = "Haste > Mastery > Versatility > Critical Strike",
        },
    },
    [64] = { -- Frost
        specName = "Frost Mage",
        default = "Mastery > Haste > Critical Strike > Versatility",
        heroTrees = {
            ["Frostfire"]    = "Mastery > Haste > Critical Strike > Versatility",
            ["Spellslinger"] = "Mastery > Critical Strike > Haste > Versatility",
        },
    },

    -- Warrior
    [71] = { -- Arms
        specName = "Arms Warrior",
        default = "Critical Strike > Haste > Mastery > Versatility",
        heroTrees = {
            ["Colossus"] = "Critical Strike > Haste > Mastery > Versatility",
            ["Slayer"]   = "Haste > Critical Strike > Mastery > Versatility",
        },
    },
    [72] = { -- Fury
        specName = "Fury Warrior",
        default = "Haste > Mastery > Critical Strike > Versatility",
        heroTrees = {
            ["Mountain Thane"] = "Haste > Mastery > Critical Strike > Versatility",
            ["Slayer"]         = "Haste > Mastery > Critical Strike > Versatility",
        },
    },
    [73] = { -- Protection
        specName = "Protection Warrior",
        default = "Haste > Versatility > Mastery > Critical Strike",
        heroTrees = {
            ["Colossus"]       = "Haste > Versatility > Mastery > Critical Strike",
            ["Mountain Thane"] = "Haste > Critical Strike > Versatility > Mastery",
        },
    },

    -- Hunter
    [253] = { -- Beast Mastery
        specName = "Beast Mastery Hunter",
        default = "Haste > Critical Strike > Mastery > Versatility",
        heroTrees = {
            ["Pack Leader"] = "Haste > Critical Strike > Mastery > Versatility",
            ["Dark Ranger"] = "Haste > Mastery > Critical Strike > Versatility",
        },
    },
    [254] = { -- Marksmanship
        specName = "Marksmanship Hunter",
        default = "Critical Strike > Mastery > Haste > Versatility",
        heroTrees = {
            ["Dark Ranger"] = "Critical Strike > Mastery > Haste > Versatility",
            ["Sentinel"]    = "Critical Strike > Mastery > Haste > Versatility",
        },
    },
    [255] = { -- Survival
        specName = "Survival Hunter",
        default = "Haste > Mastery >= Critical Strike > Versatility",
        heroTrees = {
            ["Pack Leader"] = "Haste > Mastery > Critical Strike > Versatility",
            ["Sentinel"]    = "Haste > Critical Strike > Mastery > Versatility",
        },
    },

    -- Rogue
    [259] = { -- Assassination (or 259)
        specName = "Assassination Rogue",
        default = "Mastery > Critical Strike > Haste > Versatility",
        heroTrees = {
            ["Deathstalker"] = "Mastery > Critical Strike > Haste > Versatility",
            ["Fatebound"]    = "Mastery > Critical Strike > Haste > Versatility",
        },
    },
    [260] = { -- Outlaw
        specName = "Outlaw Rogue",
        default = "Versatility >= Haste > Critical Strike > Mastery",
        heroTrees = {
            ["Fatebound"] = "Versatility >= Haste > Critical Strike > Mastery",
            ["Trickster"] = "Versatility >= Haste > Critical Strike > Mastery",
        },
    },
    [261] = { -- Subtlety
        specName = "Subtlety Rogue",
        default = "Mastery > Versatility > Critical Strike > Haste",
        heroTrees = {
            ["Deathstalker"] = "Mastery > Versatility > Critical Strike > Haste",
            ["Trickster"]    = "Mastery > Versatility > Critical Strike > Haste",
        },
    },

    -- Priest
    [256] = { -- Discipline
        specName = "Discipline Priest",
        default = "Haste > Critical Strike >= Mastery > Versatility",
        heroTrees = {
            ["Voidweaver"] = "Haste > Critical Strike >= Mastery > Versatility",
            ["Oracle"]     = "Haste > Critical Strike >= Mastery > Versatility",
        },
    },
    [257] = { -- Holy
        specName = "Holy Priest",
        default = "Critical Strike >= Mastery > Haste > Versatility",
        heroTrees = {
            ["Archon"] = "Critical Strike >= Mastery > Haste > Versatility",
            ["Oracle"] = "Critical Strike >= Mastery > Haste > Versatility",
        },
    },
    [258] = { -- Shadow (shared ID key fallback)
        specName = "Shadow Priest",
        default = "Haste > Mastery > Critical Strike > Versatility",
        heroTrees = {
            ["Voidweaver"] = "Haste > Mastery > Critical Strike > Versatility",
            ["Archon"]     = "Haste > Mastery > Critical Strike > Versatility",
        },
    },

    -- Druid
    [102] = { -- Balance
        specName = "Balance Druid",
        default = "Mastery > Haste > Versatility > Critical Strike",
        heroTrees = {
            ["Elune's Chosen"]      = "Mastery > Haste > Versatility > Critical Strike",
            ["Keeper of the Grove"] = "Mastery > Haste > Versatility > Critical Strike",
        },
    },
    [103] = { -- Feral
        specName = "Feral Druid",
        default = "Mastery > Critical Strike > Versatility > Haste",
        heroTrees = {
            ["Druid of the Claw"] = "Mastery > Critical Strike > Versatility > Haste",
            ["Wildstalker"]       = "Mastery > Critical Strike > Versatility > Haste",
        },
    },
    [104] = { -- Guardian
        specName = "Guardian Druid",
        default = "Haste > Versatility > Mastery > Critical Strike",
        heroTrees = {
            ["Druid of the Claw"] = "Haste > Versatility > Mastery > Critical Strike",
            ["Elune's Chosen"]    = "Haste > Versatility > Mastery > Critical Strike",
        },
    },
    [105] = { -- Restoration
        specName = "Restoration Druid",
        default = "Haste > Mastery >= Versatility > Critical Strike",
        heroTrees = {
            ["Keeper of the Grove"] = "Haste > Mastery >= Versatility > Critical Strike",
            ["Wildstalker"]         = "Haste > Mastery >= Versatility > Critical Strike",
        },
    },
}

-- Calculate Diminishing Returns tier and penalty from rating bonus %
local function CalculateDR(ratingBonus)
    local num = SafeNumber(ratingBonus, 0)
    if num >= 66 then
        return 50, 5, 126
    elseif num >= 54 then
        return 40, 4, 66
    elseif num >= 47 then
        return 30, 3, 54
    elseif num >= 39 then
        return 20, 2, 47
    elseif num >= 30 then
        return 10, 1, 39
    else
        return 0, 0, 30
    end
end

-- Active Hero Talent Tree Detection
function StatDisplay:GetActiveHeroTree()
    -- Method 1: C_ClassTalents & C_Traits APIs
    if C_ClassTalents and C_ClassTalents.GetActiveHeroTalentSpec then
        local ok, subTreeID = pcall(C_ClassTalents.GetActiveHeroTalentSpec)
        if ok and subTreeID and not IsSecret(subTreeID) and subTreeID > 0 then
            local configOk, configID = pcall(C_ClassTalents.GetActiveConfigID)
            if configOk and configID and not IsSecret(configID) and C_Traits and C_Traits.GetSubTreeInfo then
                local infoOk, info = pcall(C_Traits.GetSubTreeInfo, configID, subTreeID)
                if infoOk and info and not IsSecret(info) and info.name and not IsSecret(info.name) and info.name ~= "" then
                    return info.name
                end
            end
        end
    end

    -- Method 2: Keystone / signature talent spells fallback
    -- Death Knight
    if SafeIsPlayerSpell(439843) or SafeIsPlayerSpell(441378) or SafeIsPlayerSpell(444005) then
        return "Deathbringer"
    elseif SafeIsPlayerSpell(427907) or SafeIsPlayerSpell(444521) or SafeIsPlayerSpell(428135) or SafeIsPlayerSpell(444485) then
        return "Rider of the Apocalypse"
    elseif SafeIsPlayerSpell(433901) or SafeIsPlayerSpell(444040) or SafeIsPlayerSpell(444498) then
        return "San'layn"
    -- Demon Hunter
    elseif SafeIsPlayerSpell(442294) or SafeIsPlayerSpell(428784) or SafeIsPlayerSpell(444661) then
        return "Aldrachi Reaver"
    elseif SafeIsPlayerSpell(452402) or SafeIsPlayerSpell(442385) or SafeIsPlayerSpell(456640) then
        return "Fel-Scarred"
    -- Paladin
    elseif SafeIsPlayerSpell(428286) or SafeIsPlayerSpell(428287) then
        return "Herald of the Sun"
    elseif SafeIsPlayerSpell(428288) or SafeIsPlayerSpell(429826) then
        return "Templar"
    elseif SafeIsPlayerSpell(428289) or SafeIsPlayerSpell(431535) then
        return "Lightsmith"
    -- Shaman
    elseif SafeIsPlayerSpell(454009) or SafeIsPlayerSpell(454015) then
        return "Stormbringer"
    elseif SafeIsPlayerSpell(444995) or SafeIsPlayerSpell(1218047) then
        return "Totemic"
    elseif SafeIsPlayerSpell(445034) or SafeIsPlayerSpell(445037) then
        return "Farseer"
    -- Evoker
    elseif SafeIsPlayerSpell(431408) or SafeIsPlayerSpell(431877) then
        return "Chronowarden"
    elseif SafeIsPlayerSpell(431409) or SafeIsPlayerSpell(431102) then
        return "Flameshaper"
    elseif SafeIsPlayerSpell(443328) or SafeIsPlayerSpell(443337) then
        return "Scalecommander"
    -- Monk
    elseif SafeIsPlayerSpell(443421) or SafeIsPlayerSpell(443422) then
        return "Conduit of the Celestials"
    elseif SafeIsPlayerSpell(443423) or SafeIsPlayerSpell(443424) then
        return "Master of Harmony"
    elseif SafeIsPlayerSpell(443425) or SafeIsPlayerSpell(443426) then
        return "Shado-Pan"
    -- Mage
    elseif SafeIsPlayerSpell(444254) or SafeIsPlayerSpell(444255) then
        return "Spellslinger"
    elseif SafeIsPlayerSpell(444256) or SafeIsPlayerSpell(444257) then
        return "Sunfury"
    elseif SafeIsPlayerSpell(444258) or SafeIsPlayerSpell(444259) then
        return "Frostfire"
    -- Warlock
    elseif SafeIsPlayerSpell(428284) or SafeIsPlayerSpell(428285) then
        return "Diabolist"
    elseif SafeIsPlayerSpell(428282) or SafeIsPlayerSpell(428283) then
        return "Soul Harvester"
    elseif SafeIsPlayerSpell(428280) or SafeIsPlayerSpell(428281) then
        return "Hellcaller"
    -- Warrior
    elseif SafeIsPlayerSpell(430686) or SafeIsPlayerSpell(430687) then
        return "Colossus"
    elseif SafeIsPlayerSpell(430688) or SafeIsPlayerSpell(430689) then
        return "Mountain Thane"
    elseif SafeIsPlayerSpell(430690) or SafeIsPlayerSpell(430691) then
        return "Slayer"
    -- Hunter
    elseif SafeIsPlayerSpell(431525) or SafeIsPlayerSpell(431526) then
        return "Pack Leader"
    elseif SafeIsPlayerSpell(431527) or SafeIsPlayerSpell(431528) then
        return "Dark Ranger"
    elseif SafeIsPlayerSpell(431529) or SafeIsPlayerSpell(431530) then
        return "Sentinel"
    end

    return nil
end


--- Get recommended stat priority for the current spec & hero tree
function StatDisplay:GetRecommendedPriority()
    local specIndex = GetSpecialization()
    local specId = specIndex and GetSpecializationInfo(specIndex)
    local heroTree = self:GetActiveHeroTree()

    -- 1. Check active profile overrides first
    local profile = OffBeat.activeProfile
    if profile then
        if heroTree and profile.heroStatPriorities and profile.heroStatPriorities[heroTree] then
            return profile.heroStatPriorities[heroTree], heroTree, profile.meta.name
        end
        if profile.statPriority then
            return profile.statPriority, heroTree, profile.meta.name
        end
    end

    -- 2. Check built-in database
    if specId and SPEC_STAT_PRIORITIES[specId] then
        local entry = SPEC_STAT_PRIORITIES[specId]
        if heroTree and entry.heroTrees and entry.heroTrees[heroTree] then
            return entry.heroTrees[heroTree], heroTree, entry.specName
        end
        return entry.default, heroTree, entry.specName
    end

    -- 3. Generic fallback
    local _, specName = nil, "Current Spec"
    if specIndex then
        _, specName = GetSpecializationInfo(specIndex)
    end
    return "Haste > Critical Strike >= Mastery > Versatility", heroTree, specName or "Unknown Spec"
end

-- Format priority string with stat-specific colors
local function FormatPriorityString(prioStr, drStats)
    if not prioStr then return "" end
    local formatted = prioStr

    -- Highlight each stat with its theme color
    formatted = formatted:gsub("Critical Strike", "|cffff7d0aCrit|r")
    formatted = formatted:gsub("Crit", "|cffff7d0aCrit|r")
    formatted = formatted:gsub("Haste", "|cffffd100Haste|r")
    formatted = formatted:gsub("Mastery", "|cffb366ffMastery|r")
    formatted = formatted:gsub("Versatility", "|cff33ccf2Vers|r")
    formatted = formatted:gsub("Vers", "|cff33ccf2Vers|r")

    -- If a stat in the priority has DR, annotate it
    if drStats then
        for statKey, drInfo in pairs(drStats) do
            local penalty = SafeNumber(drInfo.penalty, 0)
            if penalty > 0 then
                local shortName = STATS[statKey].short
                -- Match colored token
                formatted = formatted:gsub("(|cff%x+" .. shortName .. "|r)", "%1|cffff8800*|r")
            end
        end
    end


    return formatted
end

-- Module Lifecycle
function StatDisplay:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("UNIT_STATS")
    self:RegisterEvent("COMBAT_RATING_UPDATE")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")

    self:RegisterMessage("OFFBEAT_APPEARANCE_CHANGED", "OnAppearanceChanged")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "OnLockChanged")

    -- Throttle updates to 0.3s during rapid events
    self.updateTimer = self:ScheduleRepeatingTimer("ThrottledRefresh", 0.5)

    if OffBeat.db.profile.statDisplayShown then
        self:GetFrame():Show()
        self:Refresh()
    else
        if self.frame then self.frame:Hide() end
    end
end

function StatDisplay:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end
    if self.frame then self.frame:Hide() end
end

function StatDisplay:PLAYER_ENTERING_WORLD()
    self:Refresh()
end

function StatDisplay:PLAYER_SPECIALIZATION_CHANGED(_, unit)
    if unit and unit ~= "player" then return end
    self:Refresh()
end

function StatDisplay:TRAIT_CONFIG_UPDATED()
    self:Refresh()
end

function StatDisplay:TRAIT_CONFIG_LIST_UPDATED()
    self:Refresh()
end

function StatDisplay:PLAYER_EQUIPMENT_CHANGED()
    self.isDirty = true
end

function StatDisplay:COMBAT_RATING_UPDATE()
    self.isDirty = true
end

function StatDisplay:UNIT_STATS(_, unit)
    if unit and unit ~= "player" then return end
    self.isDirty = true
end

function StatDisplay:PLAYER_REGEN_DISABLED()
    if OffBeat.db.profile.statDisplayCombatOnly and not OffBeat.db.profile.statDisplayShown then
        return
    end
    self:Refresh()
end

function StatDisplay:PLAYER_REGEN_ENABLED()
    self:Refresh()
end

function StatDisplay:ThrottledRefresh()
    if self.isDirty then
        self.isDirty = false
        self:Refresh()
    end
end

function StatDisplay:OnAppearanceChanged()
    if not self.frame then return end
    self.frame:SetBackdrop(OffBeat:BuildBackdrop())
    self.frame:SetBackdropColor(0.05, 0.05, 0.05, OffBeat.db.profile.opacity)
    self.frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    self:Refresh()
end

function StatDisplay:OnLockChanged(_, locked)
    if self.unlockOverlay then
        self.unlockOverlay:SetShown(not locked)
    end
end

-- Toggle Command
function StatDisplay:Toggle()
    local f = self:GetFrame()
    if f:IsShown() then
        f:Hide()
        OffBeat.db.profile.statDisplayShown = false
        OffBeat:Print("Stat Priority display |cffff5555hidden|r.")
    else
        f:Show()
        OffBeat.db.profile.statDisplayShown = true
        self:Refresh()
        OffBeat:Print("Stat Priority display |cff55ff55shown|r.")
    end
end

-- Override in OffBeat
function OffBeat:ToggleStatDisplay()
    local sd = OffBeat:GetModule("StatDisplay", true)
    if sd then sd:Toggle() end
end

-- Frame Construction
function StatDisplay:GetFrame()
    if self.frame then return self.frame end

    local f = OffBeat:CreateMovableFrame("OffBeatStatPanel", "statDisplayPosition", {
        width = PANEL_WIDTH,
        height = FULL_HEIGHT,
        defaultX = 260,
        defaultY = 100,
        backdrop = OffBeat:BuildBackdrop(),
        backdropColor = { 0.05, 0.05, 0.05, OffBeat.db.profile.opacity },
        borderColor = { 0.3, 0.3, 0.3, 0.8 },
    })

    -- Header container
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", PADDING, -PADDING)
    header:SetPoint("TOPRIGHT", -PADDING, -PADDING)
    header:SetHeight(20)
    f.header = header

    -- Spec title
    local specLabel = header:CreateFontString(nil, "OVERLAY")
    specLabel:SetFont(OffBeat:GetFont(1))
    specLabel:SetPoint("LEFT", header, "LEFT", 0, 0)
    specLabel:SetText("Spec")
    f.specLabel = specLabel

    -- Hero tree badge
    local heroBadge = header:CreateFontString(nil, "OVERLAY")
    heroBadge:SetFont(OffBeat:GetFont(-1))
    heroBadge:SetPoint("RIGHT", header, "RIGHT", -18, 0)
    heroBadge:SetTextColor(1.0, 0.82, 0.0, 0.9)
    f.heroBadge = heroBadge

    -- Compact toggle button
    local toggleBtn = CreateFrame("Button", nil, header)
    toggleBtn:SetSize(14, 14)
    toggleBtn:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    local toggleTex = toggleBtn:CreateFontString(nil, "OVERLAY")
    toggleTex:SetFont(OffBeat:GetFont(-2))
    toggleTex:SetPoint("CENTER")
    toggleTex:SetText("▼")
    toggleTex:SetTextColor(0.7, 0.7, 0.7)
    toggleBtn.text = toggleTex
    toggleBtn:SetScript("OnClick", function()
        OffBeat.db.profile.statDisplayCompact = not OffBeat.db.profile.statDisplayCompact
        StatDisplay:Refresh()
    end)
    toggleBtn:SetScript("OnEnter", function() toggleTex:SetTextColor(1, 1, 1) end)
    toggleBtn:SetScript("OnLeave", function() toggleTex:SetTextColor(0.7, 0.7, 0.7) end)
    f.toggleBtn = toggleBtn

    -- Priority string banner
    local prioBanner = f:CreateFontString(nil, "OVERLAY")
    prioBanner:SetFont(OffBeat:GetFont(0))
    prioBanner:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    prioBanner:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -3)
    prioBanner:SetJustifyH("LEFT")
    prioBanner:SetWordWrap(false)
    f.prioBanner = prioBanner

    -- Separator line
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", prioBanner, "BOTTOMLEFT", 0, -4)
    sep:SetPoint("TOPRIGHT", prioBanner, "BOTTOMRIGHT", 0, -4)
    sep:SetColorTexture(1, 1, 1, 0.08)
    f.sep = sep

    -- Stat Rows
    f.rows = {}
    for i, statKey in ipairs(STAT_ORDER) do
        local def = STATS[statKey]
        local row = CreateFrame("Frame", nil, f)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", sep, "BOTTOMLEFT", 0, -((i - 1) * (ROW_HEIGHT + 2) + 4))
        row:SetPoint("TOPRIGHT", sep, "BOTTOMRIGHT", 0, -((i - 1) * (ROW_HEIGHT + 2) + 4))

        -- Stat name
        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont(OffBeat:GetFont(-1))
        name:SetPoint("LEFT", row, "LEFT", 0, 0)
        name:SetWidth(42)
        name:SetJustifyH("LEFT")
        name:SetText(def.short)
        name:SetTextColor(def.color[1], def.color[2], def.color[3])
        row.name = name

        -- Value (percentage & rating)
        local val = row:CreateFontString(nil, "OVERLAY")
        val:SetFont(OffBeat:GetFont(-1))
        val:SetPoint("LEFT", name, "RIGHT", 4, 0)
        val:SetWidth(76)
        val:SetJustifyH("LEFT")
        val:SetTextColor(1, 1, 1, 0.9)
        row.val = val

        -- DR badge
        local drBadge = row:CreateFontString(nil, "OVERLAY")
        drBadge:SetFont(OffBeat:GetFont(-2))
        drBadge:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        drBadge:SetWidth(48)
        drBadge:SetJustifyH("RIGHT")
        row.drBadge = drBadge

        -- Mini Progress Bar
        local bar = CreateFrame("StatusBar", nil, row)
        bar:SetPoint("LEFT", val, "RIGHT", 4, 0)
        bar:SetPoint("RIGHT", drBadge, "LEFT", -4, 0)
        bar:SetHeight(BAR_HEIGHT)
        bar:SetStatusBarTexture(OffBeat:GetBarTexture())
        bar:SetMinMaxValues(0, 30)

        local barBg = bar:CreateTexture(nil, "BACKGROUND")
        barBg:SetAllPoints()
        barBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
        row.barBg = barBg

        row.bar = bar
        row.statKey = statKey
        f.rows[i] = row
    end

    -- Advisory / DR Footer note
    local footer = f:CreateFontString(nil, "OVERLAY")
    footer:SetFont(OffBeat:GetFont(-2))
    footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PADDING, PADDING)
    footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, PADDING)
    footer:SetJustifyH("LEFT")
    footer:SetWordWrap(true)
    f.footer = footer

    -- Compact View string
    local compactLine = f:CreateFontString(nil, "OVERLAY")
    compactLine:SetFont(OffBeat:GetFont(-1))
    compactLine:SetPoint("TOPLEFT", prioBanner, "BOTTOMLEFT", 0, -2)
    compactLine:SetPoint("TOPRIGHT", prioBanner, "BOTTOMRIGHT", 0, -2)
    compactLine:SetJustifyH("LEFT")
    f.compactLine = compactLine

    -- Unlock overlay for dragging
    self.unlockOverlay = OffBeat:CreateUnlockOverlay(f, "Stat Priority")
    self.unlockOverlay:SetShown(not OffBeat.db.profile.locked)

    self.frame = f
    return f
end

-- Refresh display contents
function StatDisplay:Refresh()
    local f = self:GetFrame()
    local db = OffBeat.db.profile

    if not db.statDisplayShown then
        f:Hide()
        return
    end

    if db.statDisplayCombatOnly and not InCombatLockdown() then
        f:Hide()
        return
    end

    f:Show()

    -- Appearance updates
    local fontPath, fontSize, fontFlags = OffBeat:GetFont()
    local barTex = OffBeat:GetBarTexture()
    local classR, classG, classB = OffBeat:GetClassColor()

    f:SetBackdrop(OffBeat:BuildBackdrop())
    f:SetBackdropColor(0.05, 0.05, 0.05, db.opacity or 0.85)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Retrieve priority & hero tree info
    local prioStr, heroTree, specName = self:GetRecommendedPriority()
    f.specLabel:SetText(specName or "Death Knight")
    f.specLabel:SetTextColor(classR, classG, classB)

    if heroTree and heroTree ~= "" then
        f.heroBadge:SetText("[" .. heroTree .. "]")
    else
        f.heroBadge:SetText("")
    end

    -- Collect live stat stats & DR info
    local statData = {}
    local anyPenalty = false
    local penaltyDetails = {}

    for _, key in ipairs(STAT_ORDER) do
        local def = STATS[key]
        -- Combat ratings can come back as secret values (e.g. in combat / restricted
        -- content). Secrets can't be used in arithmetic, comparisons or math.*, so
        -- sanitize them here and fall back to the last known readable values.
        local okB, rawBonus = pcall(GetCombatRatingBonus, def.crIndex)
        local okR, rawRating = pcall(GetCombatRating, def.crIndex)
        local cache = cachedStats[key]
        local ratingBonus, rating, totalPercent
        if not okB or not okR or IsSecret(rawBonus) or IsSecret(rawRating) then
            ratingBonus = cache and cache.ratingBonus or 0
            rating = cache and cache.rating or 0
            totalPercent = cache and cache.totalPercent or 0
        else
            ratingBonus = SafeNumber(rawBonus, 0)
            rating = SafeNumber(rawRating, 0)
            totalPercent = SafeNumber(def.getVal(), 0)
            cachedStats[key] = { ratingBonus = ratingBonus, rating = rating, totalPercent = totalPercent }
        end
        local penalty, tier, nextCap = CalculateDR(ratingBonus)

        if penalty > 0 then
            anyPenalty = true
            table.insert(penaltyDetails, string.format("%s (%.1f%%, -%d%% DR)", def.short, ratingBonus, penalty))
        end

        statData[key] = {
            rating = rating,
            ratingBonus = ratingBonus,
            totalPercent = totalPercent,
            penalty = penalty,
            tier = tier,
            nextCap = nextCap,
        }
    end

    -- Format Banner with DR hints
    local formattedPrio = FormatPriorityString(prioStr, statData)
    f.prioBanner:SetText(formattedPrio)

    local isCompact = db.statDisplayCompact

    if isCompact then
        f:SetHeight(COMPACT_HEIGHT)
        f.toggleBtn.text:SetText("▲")
        f.sep:Hide()
        f.footer:Hide()
        for _, row in ipairs(f.rows) do row:Hide() end

        -- Format Compact Line
        local parts = {}
        for _, key in ipairs(STAT_ORDER) do
            local def = STATS[key]
            local d = statData[key]
            local drMarker = ""
            if db.statDisplayShowDR and d.penalty > 0 then
                drMarker = string.format(" |cffff8800-%d%%|r", d.penalty)
            end
            table.insert(parts, string.format("|cff%s%s:|r %.1f%%%s", def.hex, def.short, d.totalPercent, drMarker))
        end
        f.compactLine:SetText(table.concat(parts, "  "))
        f.compactLine:Show()
    else
        f:SetHeight(FULL_HEIGHT)
        f.toggleBtn.text:SetText("▼")
        f.compactLine:Hide()
        f.sep:Show()
        f.footer:Show()

        for i, row in ipairs(f.rows) do
            row:Show()
            local key = row.statKey
            local def = STATS[key]
            local d = statData[key]

            row.bar:SetStatusBarTexture(barTex)

            if db.statDisplayShowValues then
                row.val:SetText(string.format("%.1f%% |cff888888(%d)|r", d.totalPercent, d.rating))
            else
                row.val:SetText(string.format("%.1f%%", d.totalPercent))
            end

            -- Update Status Bar: shows progress towards 30% DR cap
            row.bar:SetMinMaxValues(0, 30)
            row.bar:SetValue(math.min(d.ratingBonus, 30))

            if d.penalty == 0 then
                -- Optimal (below 30% rating bonus)
                row.bar:SetStatusBarColor(def.color[1], def.color[2], def.color[3], 0.85)
                if db.statDisplayShowDR then
                    row.drBadge:SetText("|cff55ff55OK|r")
                else
                    row.drBadge:SetText("")
                end
            elseif d.penalty == 10 then
                row.bar:SetStatusBarColor(1.0, 0.8, 0.0, 0.9) -- Yellow
                row.drBadge:SetText("|cffffcc00-10%|r")
            elseif d.penalty == 20 then
                row.bar:SetStatusBarColor(1.0, 0.5, 0.0, 0.9) -- Orange
                row.drBadge:SetText("|cffff8800-20%|r")
            else
                row.bar:SetStatusBarColor(1.0, 0.2, 0.2, 0.9) -- Red
                row.drBadge:SetText(string.format("|cffff3333-%d%%|r", d.penalty))
            end
        end

        -- Update Advisory Footer
        if db.statDisplayShowDR then
            if anyPenalty then
                f.footer:SetText("|cffffaa00⚠️ DR active:|r " .. table.concat(penaltyDetails, ", "))
            else
                f.footer:SetText("|cff55ff55✓ Stats below 30% DR threshold (optimal returns)|r")
            end
        else
            f.footer:SetText("")
        end
    end

    if self.unlockOverlay then
        self.unlockOverlay:SetShown(not db.locked)
    end
end
