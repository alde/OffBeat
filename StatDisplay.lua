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

-- True when the panel should dock to (and only show with) the Character panel.
local function IsAttached()
    return OffBeat.db.profile.statDisplayAttachCharacter and _G.CharacterFrame ~= nil
end

local cachedStats = {}

-- Stat Definitions
local STAT_ORDER = { "CRIT", "HASTE", "MASTERY", "VERS" }
local STATS_KEYS_UPPER = { CRIT = "CRIT", HASTE = "HASTE", MASTERY = "MASTERY", VERS = "VERS" }

local ICON_OK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"
local ICON_WARN = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t"

-- Stat priorities are rank maps: lower rank = higher priority.
--   { HASTE = 1, MASTERY = 1.5, CRIT = 2.5, VERS = 3.5 }  -> Haste >= Mastery > Crit > Vers
-- Equal ranks read as "=", a gap under 1 as ">=", a gap of 1 or more as ">".
-- Legacy strings ("Haste >= Mastery > Critical Strike > Versatility") are still
-- accepted and converted, so older exported profiles keep working.
local DR_RANK_PER_10_PERCENT = 0.5 -- each 10% DR penalty drops a stat half a rank

local STAT_NAME_ALIASES = {
    ["critical strike"] = "CRIT", ["crit"] = "CRIT",
    ["haste"] = "HASTE",
    ["mastery"] = "MASTERY",
    ["versatility"] = "VERS", ["vers"] = "VERS",
}
local RELATION_STEP = { [">"] = 1, [">="] = 0.5, ["="] = 0 }

local function ParsePriorityString(str)
    local ranks, rank, op = {}, 1, nil
    local rest = str
    while true do
        local s, e, found = rest:find("%s*([>=]+)%s*")
        local name = (s and rest:sub(1, s - 1) or rest):match("^%s*(.-)%s*$")
        local key = STAT_NAME_ALIASES[name:lower()]
        if not key or ranks[key] then return nil end
        if op then
            if not RELATION_STEP[op] then return nil end
            rank = rank + RELATION_STEP[op]
        end
        ranks[key] = rank
        if not s then break end
        op, rest = found, rest:sub(e + 1)
    end
    return ranks
end

--- Normalise a priority (rank map or legacy string) into a rank map, or nil if invalid.
local function NormalizePriority(value)
    if type(value) == "string" then
        local ranks = ParsePriorityString(value)
        if not ranks and OffBeat.Debug then OffBeat:Debug("Invalid stat priority:", value) end
        return ranks
    elseif type(value) == "table" then
        local ranks = {}
        for k, v in pairs(value) do
            local key = type(k) == "string" and (STATS_KEYS_UPPER[k:upper()] or STAT_NAME_ALIASES[k:lower()])
            if key and type(v) == "number" then ranks[key] = v end
        end
        return next(ranks) and ranks or nil
    end
    return nil
end

--- Stat keys sorted by rank (ties keep the default Crit/Haste/Mastery/Vers order).
--- Stats missing from the map go last.
local function OrderByRank(ranks)
    local order = {}
    for i, key in ipairs(STAT_ORDER) do order[i] = key end
    local index = {}
    for i, key in ipairs(STAT_ORDER) do index[key] = i end
    table.sort(order, function(a, b)
        local ra, rb = ranks[a] or math.huge, ranks[b] or math.huge
        if ra ~= rb then return ra < rb end
        return index[a] < index[b]
    end)
    return order
end

--- Copy of `ranks` with stats past diminishing returns pushed down.
local function ApplyDRToRanks(ranks, statData)
    local adjusted = {}
    for key, rank in pairs(ranks) do
        local d = statData and statData[key]
        local penalty = d and d.penalty or 0
        adjusted[key] = rank + (penalty / 10) * DR_RANK_PER_10_PERCENT
    end
    return adjusted
end

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
-- Entries marked "Method 12.1" were checked against Method's 12.1 guides
-- (Sep 2026); where Method splits raid / M+ or ST / AoE, the noted one is used.
-- Unmarked entries date from The War Within and have not been re-verified.
-- Values are rank maps (lower = higher priority); see NormalizePriority above.
local SPEC_STAT_PRIORITIES = {
    -- Death Knight
    [250] = { -- Blood (Method 12.1)
        specName = "Blood Death Knight",
        default = { CRIT = 1, MASTERY = 1, VERS = 1, HASTE = 2 },
        heroTrees = {
            ["Deathbringer"] = { CRIT = 1, MASTERY = 1, VERS = 1, HASTE = 2 },
            ["San'layn"]     = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 2 },
        },
    },
    [251] = { -- Frost (Method 12.1)
        specName = "Frost Death Knight",
        default = { CRIT = 1, MASTERY = 2, HASTE = 2.5, VERS = 3.5 },
    },
    [252] = { -- Unholy (Method 12.1)
        specName = "Unholy Death Knight",
        default = { CRIT = 1, MASTERY = 2, HASTE = 2.5, VERS = 3.5 },
    },

    -- Demon Hunter
    [577] = { -- Havoc
        specName = "Havoc Demon Hunter",
        default = { CRIT = 1, MASTERY = 2, HASTE = 3, VERS = 4 },
        heroTrees = {
            ["Aldrachi Reaver"] = { CRIT = 1, MASTERY = 2, HASTE = 3, VERS = 4 },
            ["Fel-Scarred"]     = { CRIT = 1, MASTERY = 2, VERS = 3, HASTE = 4 },
        },
    },
    [581] = { -- Vengeance
        specName = "Vengeance Demon Hunter",
        default = { HASTE = 1, CRIT = 2, VERS = 2.5, MASTERY = 3.5 },
        heroTrees = {
            ["Aldrachi Reaver"] = { HASTE = 1, CRIT = 2, VERS = 2.5, MASTERY = 3.5 },
            ["Fel-Scarred"]     = { HASTE = 1, VERS = 2, CRIT = 2.5, MASTERY = 3.5 },
        },
    },

    -- Paladin
    [65] = { -- Holy (Method 12.1)
        specName = "Holy Paladin",
        default = { MASTERY = 1, CRIT = 2, HASTE = 2, VERS = 3 },
    },
    [66] = { -- Protection
        specName = "Protection Paladin",
        default = { HASTE = 1, MASTERY = 2, VERS = 2.5, CRIT = 3.5 },
        heroTrees = {
            ["Templar"]    = { HASTE = 1, VERS = 2, MASTERY = 3, CRIT = 4 },
            ["Lightsmith"] = { HASTE = 1, MASTERY = 2, VERS = 3, CRIT = 4 },
        },
    },
    [70] = { -- Retribution
        specName = "Retribution Paladin",
        default = { MASTERY = 1, HASTE = 1.5, CRIT = 2.5, VERS = 3.5 },
        heroTrees = {
            ["Herald of the Sun"] = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
            ["Templar"]           = { HASTE = 1, MASTERY = 2, CRIT = 2.5, VERS = 3.5 },
        },
    },

    -- Evoker
    [1467] = { -- Devastation
        specName = "Devastation Evoker",
        default = { CRIT = 1, MASTERY = 1.5, HASTE = 2.5, VERS = 3.5 },
        heroTrees = {
            ["Flameshaper"]    = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
            ["Scalecommander"] = { CRIT = 1, MASTERY = 1.5, HASTE = 2.5, VERS = 3.5 },
        },
    },
    [1468] = { -- Preservation (Method 12.1, raid)
        specName = "Preservation Evoker",
        default = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 3 },
    },
    [1473] = { -- Augmentation
        specName = "Augmentation Evoker",
        default = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
        heroTrees = {
            ["Chronowarden"]   = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
            ["Scalecommander"] = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
        },
    },

    -- Monk
    [268] = { -- Brewmaster
        specName = "Brewmaster Monk",
        default = { VERS = 1, CRIT = 1.5, MASTERY = 2.5, HASTE = 3.5 },
        heroTrees = {
            ["Master of Harmony"] = { VERS = 1, CRIT = 1.5, MASTERY = 2.5, HASTE = 3.5 },
            ["Shado-Pan"]         = { CRIT = 1, VERS = 1.5, MASTERY = 2.5, HASTE = 3.5 },
        },
    },
    [269] = { -- Windwalker
        specName = "Windwalker Monk",
        default = { MASTERY = 1, CRIT = 1.5, VERS = 2.5, HASTE = 3.5 },
        heroTrees = {
            ["Conduit of the Celestials"] = { MASTERY = 1, CRIT = 1.5, VERS = 2.5, HASTE = 3.5 },
            ["Shado-Pan"]                 = { MASTERY = 1, CRIT = 1.5, HASTE = 2.5, VERS = 3.5 },
        },
    },
    [270] = { -- Mistweaver (Method 12.1)
        specName = "Mistweaver Monk",
        default = { HASTE = 1, CRIT = 2, VERS = 2, MASTERY = 3 },
    },

    -- Shaman
    [262] = { -- Elemental
        specName = "Elemental Shaman",
        default = { MASTERY = 1, HASTE = 1.5, CRIT = 2.5, VERS = 3.5 },
        heroTrees = {
            ["Stormbringer"] = { HASTE = 1, MASTERY = 1.5, CRIT = 2.5, VERS = 3.5 },
            ["Farseer"]      = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
        },
    },
    [263] = { -- Enhancement
        specName = "Enhancement Shaman",
        default = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
        heroTrees = {
            ["Stormbringer"] = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
            ["Totemic"]      = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
        },
    },
    [264] = { -- Restoration (Method 12.1, raid)
        specName = "Restoration Shaman",
        default = { CRIT = 1, HASTE = 2, VERS = 2, MASTERY = 3 },
    },

    -- Warlock
    [265] = { -- Affliction (Method 12.1, single target)
        specName = "Affliction Warlock",
        default = { CRIT = 1, HASTE = 2, MASTERY = 2, VERS = 3 },
    },
    [266] = { -- Demonology (Method 12.1)
        specName = "Demonology Warlock",
        default = { CRIT = 1, HASTE = 2, MASTERY = 2, VERS = 3 },
    },
    [267] = { -- Destruction
        specName = "Destruction Warlock",
        default = { HASTE = 1, MASTERY = 2, CRIT = 2.5, VERS = 3.5 },
        heroTrees = {
            ["Diabolist"]  = { HASTE = 1, CRIT = 2, MASTERY = 2.5, VERS = 3.5 },
            ["Hellcaller"] = { HASTE = 1, MASTERY = 2, CRIT = 2.5, VERS = 3.5 },
        },
    },

    -- Mage
    [62] = { -- Arcane
        specName = "Arcane Mage",
        default = { HASTE = 1, MASTERY = 2, VERS = 3, CRIT = 4 },
        heroTrees = {
            ["Spellslinger"] = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
            ["Sunfury"]      = { HASTE = 1, MASTERY = 2, VERS = 3, CRIT = 4 },
        },
    },
    [63] = { -- Fire
        specName = "Fire Mage",
        default = { HASTE = 1, MASTERY = 2, VERS = 3, CRIT = 4 },
        heroTrees = {
            ["Frostfire"] = { HASTE = 1, MASTERY = 2, VERS = 3, CRIT = 4 },
            ["Sunfury"]   = { HASTE = 1, MASTERY = 2, VERS = 3, CRIT = 4 },
        },
    },
    [64] = { -- Frost
        specName = "Frost Mage",
        default = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
        heroTrees = {
            ["Frostfire"]    = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
            ["Spellslinger"] = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
        },
    },

    -- Warrior
    [71] = { -- Arms
        specName = "Arms Warrior",
        default = { CRIT = 1, HASTE = 2, MASTERY = 3, VERS = 4 },
        heroTrees = {
            ["Colossus"] = { CRIT = 1, HASTE = 2, MASTERY = 3, VERS = 4 },
            ["Slayer"]   = { HASTE = 1, CRIT = 2, MASTERY = 3, VERS = 4 },
        },
    },
    [72] = { -- Fury
        specName = "Fury Warrior",
        default = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
        heroTrees = {
            ["Mountain Thane"] = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
            ["Slayer"]         = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
        },
    },
    [73] = { -- Protection
        specName = "Protection Warrior",
        default = { HASTE = 1, VERS = 2, MASTERY = 3, CRIT = 4 },
        heroTrees = {
            ["Colossus"]       = { HASTE = 1, VERS = 2, MASTERY = 3, CRIT = 4 },
            ["Mountain Thane"] = { HASTE = 1, CRIT = 2, VERS = 3, MASTERY = 4 },
        },
    },

    -- Hunter
    [253] = { -- Beast Mastery
        specName = "Beast Mastery Hunter",
        default = { HASTE = 1, CRIT = 2, MASTERY = 3, VERS = 4 },
        heroTrees = {
            ["Pack Leader"] = { HASTE = 1, CRIT = 2, MASTERY = 3, VERS = 4 },
            ["Dark Ranger"] = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
        },
    },
    [254] = { -- Marksmanship
        specName = "Marksmanship Hunter",
        default = { CRIT = 1, MASTERY = 2, HASTE = 3, VERS = 4 },
        heroTrees = {
            ["Dark Ranger"] = { CRIT = 1, MASTERY = 2, HASTE = 3, VERS = 4 },
            ["Sentinel"]    = { CRIT = 1, MASTERY = 2, HASTE = 3, VERS = 4 },
        },
    },
    [255] = { -- Survival
        specName = "Survival Hunter",
        default = { HASTE = 1, MASTERY = 2, CRIT = 2.5, VERS = 3.5 },
        heroTrees = {
            ["Pack Leader"] = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
            ["Sentinel"]    = { HASTE = 1, CRIT = 2, MASTERY = 3, VERS = 4 },
        },
    },

    -- Rogue
    [259] = { -- Assassination
        specName = "Assassination Rogue",
        default = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
        heroTrees = {
            ["Deathstalker"] = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
            ["Fatebound"]    = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
        },
    },
    [260] = { -- Outlaw
        specName = "Outlaw Rogue",
        default = { VERS = 1, HASTE = 1.5, CRIT = 2.5, MASTERY = 3.5 },
        heroTrees = {
            ["Fatebound"] = { VERS = 1, HASTE = 1.5, CRIT = 2.5, MASTERY = 3.5 },
            ["Trickster"] = { VERS = 1, HASTE = 1.5, CRIT = 2.5, MASTERY = 3.5 },
        },
    },
    [261] = { -- Subtlety
        specName = "Subtlety Rogue",
        default = { MASTERY = 1, VERS = 2, CRIT = 3, HASTE = 4 },
        heroTrees = {
            ["Deathstalker"] = { MASTERY = 1, VERS = 2, CRIT = 3, HASTE = 4 },
            ["Trickster"]    = { MASTERY = 1, VERS = 2, CRIT = 3, HASTE = 4 },
        },
    },

    -- Priest
    [256] = { -- Discipline (Method 12.1)
        specName = "Discipline Priest",
        default = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
    },
    [257] = { -- Holy (Method 12.1, raid)
        specName = "Holy Priest",
        default = { CRIT = 1, MASTERY = 2, VERS = 3, HASTE = 4 },
    },
    [258] = { -- Shadow
        specName = "Shadow Priest",
        default = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
        heroTrees = {
            ["Voidweaver"] = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
            ["Archon"]     = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
        },
    },

    -- Druid
    [102] = { -- Balance
        specName = "Balance Druid",
        default = { MASTERY = 1, HASTE = 2, VERS = 3, CRIT = 4 },
        heroTrees = {
            ["Elune's Chosen"]      = { MASTERY = 1, HASTE = 2, VERS = 3, CRIT = 4 },
            ["Keeper of the Grove"] = { MASTERY = 1, HASTE = 2, VERS = 3, CRIT = 4 },
        },
    },
    [103] = { -- Feral
        specName = "Feral Druid",
        default = { MASTERY = 1, CRIT = 2, VERS = 3, HASTE = 4 },
        heroTrees = {
            ["Druid of the Claw"] = { MASTERY = 1, CRIT = 2, VERS = 3, HASTE = 4 },
            ["Wildstalker"]       = { MASTERY = 1, CRIT = 2, VERS = 3, HASTE = 4 },
        },
    },
    [104] = { -- Guardian
        specName = "Guardian Druid",
        default = { HASTE = 1, VERS = 2, MASTERY = 3, CRIT = 4 },
        heroTrees = {
            ["Druid of the Claw"] = { HASTE = 1, VERS = 2, MASTERY = 3, CRIT = 4 },
            ["Elune's Chosen"]    = { HASTE = 1, VERS = 2, MASTERY = 3, CRIT = 4 },
        },
    },
    [105] = { -- Restoration (Method 12.1, raid)
        specName = "Restoration Druid",
        default = { HASTE = 1, MASTERY = 1, CRIT = 2, VERS = 2.5 },
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
        local hero = heroTree and profile.heroStatPriorities
            and NormalizePriority(profile.heroStatPriorities[heroTree])
        if hero then return hero, heroTree, profile.meta.name end
        local base = NormalizePriority(profile.statPriority)
        if base then return base, heroTree, profile.meta.name end
    end

    -- 2. Check built-in database
    if specId and SPEC_STAT_PRIORITIES[specId] then
        local entry = SPEC_STAT_PRIORITIES[specId]
        local hero = heroTree and entry.heroTrees and NormalizePriority(entry.heroTrees[heroTree])
        if hero then return hero, heroTree, entry.specName end
        return NormalizePriority(entry.default), heroTree, entry.specName
    end

    -- 3. Generic fallback
    local _, specName = nil, "Current Spec"
    if specIndex then
        _, specName = GetSpecializationInfo(specIndex)
    end
    return { HASTE = 1, CRIT = 2, MASTERY = 2.5, VERS = 3.5 }, heroTree, specName or "Unknown Spec"
end

--- Render a rank map as "Haste >= Mastery > Crit > Vers" with stat colours.
--- Stats with a DR penalty in `statData` get an orange asterisk.
local function FormatPriority(ranks, statData)
    if not ranks then return "" end
    local order = {}
    for _, key in ipairs(OrderByRank(ranks)) do
        if ranks[key] then order[#order + 1] = key end -- unlisted stats aren't shown
    end
    local parts = {}
    for i, key in ipairs(order) do
        local def = STATS[key]
        if i > 1 then
            local gap = ranks[key] - ranks[order[i - 1]]
            parts[#parts + 1] = gap <= 0 and " = " or (gap < 1 and " >= " or " > ")
        end
        local token = string.format("|cff%s%s|r", def.hex, def.short)
        local d = statData and statData[key]
        if d and SafeNumber(d.penalty, 0) > 0 then
            token = token .. "|cffff8800*|r"
        end
        parts[#parts + 1] = token
    end
    return table.concat(parts)
end

function StatDisplay:FormatPriority(ranks, statData)
    return FormatPriority(ranks, statData)
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

    self:HookCharacterFrame()
    self:ApplyAnchor()

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
        self.unlockOverlay:SetShown(not locked and not IsAttached())
    end
end

-- Character panel attachment
-- When enabled, the panel docks to the right edge of the Character panel and is
-- only visible while that panel is open, instead of floating on screen all the time.

function StatDisplay:HookCharacterFrame()
    if self.characterHooked or not _G.CharacterFrame then return end
    self.characterHooked = true
    local function onToggle()
        if StatDisplay:IsEnabled() and IsAttached() then
            StatDisplay:Refresh()
        end
    end
    _G.CharacterFrame:HookScript("OnShow", onToggle)
    _G.CharacterFrame:HookScript("OnHide", onToggle)
end

function StatDisplay:ApplyAnchor()
    local f = self:GetFrame()
    f:ClearAllPoints()
    -- Docked panels can't be dragged; detached panels drag when unlocked.
    if IsAttached() then f:RegisterForDrag() else f:RegisterForDrag("LeftButton") end
    if IsAttached() then
        f:SetFrameStrata(_G.CharacterFrame:GetFrameStrata())
        f:SetFrameLevel(_G.CharacterFrame:GetFrameLevel() + 5)
        f:SetPoint("TOPLEFT", _G.CharacterFrame, "TOPRIGHT", 4, 0)
    else
        f:SetFrameStrata("MEDIUM")
        local pos = OffBeat.db.profile.statDisplayPosition
        if pos then
            f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
        else
            f:SetPoint("CENTER", UIParent, "CENTER", 260, 100)
        end
    end
    if self.unlockOverlay then
        self.unlockOverlay:SetShown(not OffBeat.db.profile.locked and not IsAttached())
    end
end

function StatDisplay:SetAttachToCharacter(attached)
    OffBeat.db.profile.statDisplayAttachCharacter = attached
    self:HookCharacterFrame()
    self:ApplyAnchor()
    self:Refresh()
end

-- Toggle Command
function StatDisplay:Toggle()
    local f = self:GetFrame()
    if IsAttached() then
        -- In attached mode the panel follows the Character panel; toggle that instead.
        if _G.ToggleCharacter then ToggleCharacter("PaperDollFrame") end
        return
    end
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
    heroBadge:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    heroBadge:SetTextColor(1.0, 0.82, 0.0, 0.9)
    f.heroBadge = heroBadge


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

    if IsAttached() then
        if not _G.CharacterFrame:IsShown() then
            f:Hide()
            return
        end
    elseif db.statDisplayCombatOnly and not InCombatLockdown() then
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
    local baseRanks, heroTree, specName = self:GetRecommendedPriority()
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

    -- Effective priority: stats past diminishing returns drop down the order,
    -- so the banner and rows show what to aim for right now.
    local ranks = ApplyDRToRanks(baseRanks, statData)
    f.prioBanner:SetText(FormatPriority(ranks, statData))

    local isCompact = db.statDisplayCompact
    local order = OrderByRank(ranks)

    if isCompact then
        f:SetHeight(COMPACT_HEIGHT)
        f.sep:Hide()
        f.footer:Hide()
        for _, row in ipairs(f.rows) do row:Hide() end

        -- Format Compact Line
        local parts = {}
        for _, key in ipairs(order) do
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
        f.compactLine:Hide()
        f.sep:Show()
        f.footer:Show()

        -- Lay rows out in priority order (highest priority on top)
        local rowByKey = {}
        for _, r in ipairs(f.rows) do rowByKey[r.statKey] = r end
        for i, key in ipairs(order) do
            local row = rowByKey[key]
            local offset = -((i - 1) * (ROW_HEIGHT + 2) + 4)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.sep, "BOTTOMLEFT", 0, offset)
            row:SetPoint("TOPRIGHT", f.sep, "BOTTOMRIGHT", 0, offset)
            row:Show()
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
                f.footer:SetText(ICON_WARN .. " |cffffaa00DR active:|r " .. table.concat(penaltyDetails, ", "))
            else
                f.footer:SetText(ICON_OK .. " |cff55ff55Stats below 30% DR threshold (optimal returns)|r")
            end
        else
            f.footer:SetText("")
        end
    end

    if self.unlockOverlay then
        self.unlockOverlay:SetShown(not db.locked and not IsAttached())
    end
end
