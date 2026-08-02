local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Vengeance Demon Hunter",
        specId = 581,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method / Icy Veins / Wowhead",
    },

    rotationSpells = {
        { spellId = 263642 }, -- Fracture
        { spellId = 228477 }, -- Soul Cleave
        { spellId = 247454 }, -- Spirit Bomb
        { spellId = 204596 }, -- Sigil of Flame
        { spellId = 258920 }, -- Immolation Aura
        { spellId = 212084 }, -- Fel Devastation
        { spellId = 204021 }, -- Fiery Brand
        { spellId = 390163 }, -- Sigil of Spite
        { spellId = 207407 }, -- Soul Carver
        { spellId = 232893 }, -- Felblade
        { spellId = 187827 }, -- Metamorphosis
        { spellId = 185123 }, -- Throw Glaive
        { spellId = 442294 }, -- Reaver's Glaive (Aldrachi Reaver)
    },

    trackedAuras = {
        { spellId = 203819,  name = "Demon Spikes",      baseDuration = 6,  stacks = false },
        { spellId = 187827,  name = "Metamorphosis",      baseDuration = 15, stacks = false },
        { spellId = 391166,  name = "Soul Furnace",       baseDuration = 30, stacks = true },
        { spellId = 1270444, name = "Untethered Rage",    baseDuration = 12, stacks = false },
        { spellId = 1270547, name = "Seething Anger",     baseDuration = 12, stacks = true },
        { spellId = 444661,  name = "Art of the Glaive",  baseDuration = 30, stacks = false },
        { spellId = 1253304, name = "Voidfall",           baseDuration = 30, stacks = true },
    },

    keyCooldown = {
        spellId = 187827,
        name = "Metamorphosis",
        duration = 15,
    },

    idleCooldowns = {
        { spellId = 212084, name = "Fel Devastation" },
        { spellId = 204021, name = "Fiery Brand" },
        { spellId = 207407, name = "Soul Carver" },
        { spellId = 390163, name = "Sigil of Spite" },
        { spellId = 204596, name = "Sigil of Flame" },
    },

    procTracking = {
        {
            procAura = 1270444,
            consumeSpell = 187827,
            window = 0.5,
            name = "Untethered Rage",
        },
    },

    castAnnouncements = {
        {
            spellId = 196718,
            name = "Darkness",
            message = "Embrace the darkness!",
            channel = "SAY",
        },
    },
})
