local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Havoc Demon Hunter",
        specId = 577,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method / Icy Veins / Wowhead",
    },

    rotationSpells = {
        { spellId = 162243 }, -- Demon's Bite
        { spellId = 162794 }, -- Chaos Strike
        { spellId = 201427 }, -- Annihilation (Chaos Strike during Meta)
        { spellId = 188499 }, -- Blade Dance
        { spellId = 210152 }, -- Death Sweep (Blade Dance during Meta)
        { spellId = 198013 }, -- Eye Beam
        { spellId = 258920 }, -- Immolation Aura
        { spellId = 258860 }, -- Essence Break
        { spellId = 370965 }, -- The Hunt
        { spellId = 185123 }, -- Throw Glaive
        { spellId = 342817 }, -- Glaive Tempest
        { spellId = 195072 }, -- Fel Rush
        { spellId = 198793 }, -- Vengeful Retreat
        { spellId = 204596 }, -- Sigil of Flame
    },

    trackedAuras = {
        { spellId = 162264, name = "Metamorphosis",  baseDuration = 24, stacks = false },
        { spellId = 347462, name = "Unbound Chaos",  baseDuration = 20, stacks = false },
        { spellId = 343312, name = "Furious Gaze",   baseDuration = 12, stacks = false },
    },

    keyCooldown = {
        spellId = 198013,
        name = "Eye Beam",
        duration = 2,
    },

    idleCooldowns = {
        { spellId = 198013, name = "Eye Beam" },
        { spellId = 258860, name = "Essence Break" },
        { spellId = 370965, name = "The Hunt" },
    },

    procTracking = {
        {
            procAura = 347462,
            consumeSpell = 195072,
            window = 0.5,
            name = "Unbound Chaos",
        },
    },
})
