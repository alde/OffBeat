local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Devourer Demon Hunter",
        specId = 1480,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method / Icy Veins / Wowhead",
    },

    rotationSpells = {
        { spellId = 473662 },  -- Consume
        { spellId = 1217610 }, -- Devour (Consume during Void Meta)
        { spellId = 473728 },  -- Void Ray
        { spellId = 1226019 }, -- Reap
        { spellId = 1245453 }, -- Cull (Reap during Void Meta)
        { spellId = 1225826 }, -- Eradicate (replaces Reap when talented)
        { spellId = 1217605 }, -- Void Metamorphosis
        { spellId = 1221150 }, -- Collapsing Star
        { spellId = 1241937 }, -- Soul Immolation
        { spellId = 1245412 }, -- Voidblade
        { spellId = 1239519 }, -- Hungering Slash
        { spellId = 1246167 }, -- The Hunt (Devourer)
        { spellId = 1234796 }, -- Shift
        { spellId = 198793 },  -- Vengeful Retreat
        { spellId = 258920 },  -- Immolation Aura
        { spellId = 185123 },  -- Throw Glaive
        { spellId = 204596 },  -- Sigil of Flame
    },

    trackedAuras = {
        { spellId = 1217605, name = "Void Metamorphosis",  baseDuration = 30, stacks = false },
        { spellId = 1253304, name = "Voidfall",            baseDuration = 30, stacks = true },
        { spellId = 1238488, name = "Moment of Craving",   baseDuration = 8,  stacks = false },
    },

    keyCooldown = {
        spellId = 1241937,
        name = "Soul Immolation",
        duration = 3,
    },

    idleCooldowns = {
        { spellId = 1241937, name = "Soul Immolation" },
        { spellId = 1245412, name = "Voidblade" },
        { spellId = 1246167, name = "The Hunt" },
    },

    procTracking = {
        {
            procAura = 1238488,
            consumeSpell = 1226019,
            window = 0.5,
            name = "Moment of Craving",
        },
    },
})
