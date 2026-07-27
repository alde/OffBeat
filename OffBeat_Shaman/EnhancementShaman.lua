local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Enhancement Shaman",
        specId = 263,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method / Icy Veins / Wowhead",
    },

    rotationSpells = {
        { spellId = 17364 },  -- Stormstrike
        { spellId = 115356 }, -- Windstrike (replaces Stormstrike during Ascendance)
        { spellId = 60103 },  -- Lava Lash
        { spellId = 187874 }, -- Crash Lightning
        { spellId = 188196 }, -- Lightning Bolt (MW spender)
        { spellId = 188443 }, -- Chain Lightning (MW spender, AoE)
        { spellId = 454009 }, -- Tempest (Stormbringer proc)
        { spellId = 384352 }, -- Doom Winds
        { spellId = 114049 }, -- Ascendance
        { spellId = 197214 }, -- Sundering
        { spellId = 470053 }, -- Voltaic Blaze
        { spellId = 333974 }, -- Fire Nova
        { spellId = 196840 }, -- Frost Shock
    },

    mistakes = {
        {
            type = "proc_waste",
            name = "Hot Hand Waste",
            description = "Non-Lava Lash melee while Hot Hand is active",
            procAura = 201900,
            wasteSpells = { 17364, 115356 },
        },
    },

    trackedAuras = {
        { spellId = 344179,  name = "Maelstrom Weapon",  baseDuration = 30, stacks = true },
        { spellId = 201900,  name = "Hot Hand",           baseDuration = 8,  stacks = false },
        { spellId = 384352,  name = "Doom Winds",         baseDuration = 8,  stacks = false },
        { spellId = 114049,  name = "Ascendance",         baseDuration = 15, stacks = false },
        { spellId = 201846,  name = "Stormsurge",         baseDuration = 5,  stacks = true },
    },

    keyCooldown = {
        spellId = 384352,
        name = "Doom Winds",
        duration = 8,
    },

    idleCooldowns = {
        { spellId = 384352, name = "Doom Winds" },
        { spellId = 114049, name = "Ascendance" },
        { spellId = 197214, name = "Sundering" },
    },

    procTracking = {
        {
            procAura = 201900,
            consumeSpell = 60103,
            window = 0.5,
            name = "Hot Hand",
        },
    },
})
