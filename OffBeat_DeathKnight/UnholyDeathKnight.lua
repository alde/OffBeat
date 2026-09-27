local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Unholy Death Knight",
        specId = 252,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method",
    },

    rotationSpells = {
        { spellId = 85948 },  -- Festering Strike
        { spellId = 55090 },  -- Scourge Strike
        { spellId = 139736 }, -- Clawing Shadows
        { spellId = 433901 }, -- Vampiric Strike (San'layn)
        { spellId = 47541 },  -- Death Coil
        { spellId = 207317 }, -- Epidemic
        { spellId = 77575 },  -- Outbreak
        { spellId = 43265 },  -- Death and Decay
        { spellId = 152280 }, -- Defile
        { spellId = 63560 },  -- Dark Transformation
        { spellId = 275699 }, -- Apocalypse
        { spellId = 42650 },  -- Army of the Dead
        { spellId = 455395 }, -- Raise Abomination
        { spellId = 49206 },  -- Summon Gargoyle
        { spellId = 343294 }, -- Soul Reaper
        { spellId = 383269 }, -- Abomination Limb
        { spellId = 390279 }, -- Vile Contagion
        { spellId = 49998 },  -- Death Strike
        { spellId = 439843 }, -- Reaper's Mark (Deathbringer)
        { spellId = 441378 }, -- Exterminate (Deathbringer)
        { spellId = 48707 },  -- Anti-Magic Shell
        { spellId = 48792 },  -- Icebound Fortitude
    },


    trackedAuras = {
        { spellId = 81340,  name = "Sudden Doom",               baseDuration = 10, stacks = false },
        { spellId = 63560,  name = "Dark Transformation",       baseDuration = 15, stacks = false },
        { spellId = 377590, name = "Festermight",               baseDuration = 20, stacks = true },
        { spellId = 207289, name = "Unholy Assault",            baseDuration = 12, stacks = false },
        { spellId = 194879, name = "Icy Talons",                baseDuration = 6,  stacks = true },
        { spellId = 390259, name = "Commander of the Dead",     baseDuration = 30, stacks = false },
        { spellId = 444040, name = "Essence of the Blood Queen", baseDuration = 20, stacks = true },
        { spellId = 439843, name = "Reaper's Mark",             baseDuration = 12, stacks = true },
    },

    keyCooldown = {
        spellId = 275699,
        name = "Apocalypse",
        duration = 15,
    },

    idleCooldowns = {
        { spellId = 275699, name = "Apocalypse" },
        { spellId = 63560,  name = "Dark Transformation" },
        { spellId = 383269, name = "Abomination Limb" },
        { spellId = 390279, name = "Vile Contagion" },
        { spellId = 455395, name = "Raise Abomination" },
        { spellId = 49206,  name = "Summon Gargoyle" },
        { spellId = 42650,  name = "Army of the Dead" },
    },

    procTracking = {
        {
            procAura = 81340,
            consumeSpell = 47541,
            window = 0.5,
            name = "Sudden Doom",
        },
    },

    statPriority = "Mastery > Haste > Critical Strike > Versatility",
    heroStatPriorities = {
        ["Rider of the Apocalypse"] = "Mastery > Haste > Critical Strike > Versatility",
        ["San'layn"] = "Haste > Mastery > Critical Strike > Versatility",
    },
})
