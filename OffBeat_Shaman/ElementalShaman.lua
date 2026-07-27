local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Elemental Shaman",
        specId = 262,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method / Icy Veins / Wowhead",
    },

    rotationSpells = {
        { spellId = 188196 }, -- Lightning Bolt
        { spellId = 51505 },  -- Lava Burst
        { spellId = 188443 }, -- Chain Lightning
        { spellId = 8042 },   -- Earth Shock
        { spellId = 117014 }, -- Elemental Blast
        { spellId = 61882 },  -- Earthquake
        { spellId = 188389 }, -- Flame Shock
        { spellId = 452201 }, -- Tempest (Stormbringer proc)
        { spellId = 114050 }, -- Ascendance
        { spellId = 191634 }, -- Stormkeeper
        { spellId = 470053 }, -- Voltaic Blaze
        { spellId = 196840 }, -- Frost Shock
    },

    mistakes = {
        {
            type = "proc_waste",
            name = "MotE Waste",
            description = "Lava Burst while Master of the Elements is active overwrites the buff",
            procAura = 16166,
            wasteSpells = { 51505 },
        },
    },

    trackedAuras = {
        { spellId = 77756,  name = "Lava Surge",              baseDuration = 10, stacks = false },
        { spellId = 16166,  name = "Master of the Elements",  baseDuration = 15, stacks = false },
        { spellId = 191634, name = "Stormkeeper",             baseDuration = 30, stacks = true },
        { spellId = 191861, name = "Power of the Maelstrom",  baseDuration = 30, stacks = true },
        { spellId = 114050, name = "Ascendance",              baseDuration = 15, stacks = false },
        { spellId = 452201, name = "Tempest",                 baseDuration = 30, stacks = true },
    },

    keyCooldown = {
        spellId = 114050,
        name = "Ascendance",
        duration = 15,
    },

    idleCooldowns = {
        { spellId = 114050, name = "Ascendance" },
        { spellId = 191634, name = "Stormkeeper" },
    },

    procTracking = {
        {
            procAura = 77756,
            consumeSpell = 51505,
            window = 0.5,
            name = "Lava Surge",
        },
    },
})
