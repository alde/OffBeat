local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Blood Death Knight",
        specId = 250,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method",
    },

    rotationSpells = {
        { spellId = 195182 }, -- Marrowrend
        { spellId = 206930 }, -- Heart Strike
        { spellId = 433901 }, -- Vampiric Strike (San'layn)
        { spellId = 49998 },  -- Death Strike
        { spellId = 50842 },  -- Blood Boil
        { spellId = 43265 },  -- Death and Decay
        { spellId = 49028 },  -- Dancing Rune Weapon
        { spellId = 219809 }, -- Tombstone
        { spellId = 194844 }, -- Bonestorm
        { spellId = 383269 }, -- Abomination Limb
        { spellId = 274156 }, -- Consumption
        { spellId = 343294 }, -- Soul Reaper
        { spellId = 439843 }, -- Reaper's Mark (Deathbringer)
        { spellId = 441378 }, -- Exterminate (Deathbringer)
        { spellId = 55233 },  -- Vampiric Blood
        { spellId = 195292 }, -- Death's Caress
        { spellId = 48707 },  -- Anti-Magic Shell
        { spellId = 48792 },  -- Icebound Fortitude
        { spellId = 46585 },  -- Raise Dead
    },


    trackedAuras = {
        { spellId = 195181, name = "Bone Shield",               baseDuration = 30, stacks = true },
        { spellId = 81256,  name = "Dancing Rune Weapon",       baseDuration = 8,  stacks = false },
        { spellId = 55233,  name = "Vampiric Blood",            baseDuration = 10, stacks = false },
        { spellId = 81141,  name = "Crimson Scourge",           baseDuration = 15, stacks = false },
        { spellId = 273947, name = "Hemostasis",                baseDuration = 15, stacks = true },
        { spellId = 390268, name = "Coagulopathy",              baseDuration = 10, stacks = true },
        { spellId = 444040, name = "Essence of the Blood Queen", baseDuration = 20, stacks = true },
        { spellId = 439843, name = "Reaper's Mark",             baseDuration = 12, stacks = true },
    },

    keyCooldown = {
        spellId = 49028,
        name = "Dancing Rune Weapon",
        duration = 8,
    },

    idleCooldowns = {
        { spellId = 49028,  name = "Dancing Rune Weapon" },
        { spellId = 55233,  name = "Vampiric Blood" },
        { spellId = 383269, name = "Abomination Limb" },
        { spellId = 219809, name = "Tombstone" },
        { spellId = 194844, name = "Bonestorm" },
    },

    procTracking = {
        {
            procAura = 81141,
            consumeSpell = 43265,
            window = 0.5,
            name = "Crimson Scourge",
        },
    },

    statPriority = { HASTE = 1, CRIT = 2, MASTERY = 2.5, VERS = 3.5 },
    heroStatPriorities = {
        ["Deathbringer"] = { HASTE = 1, CRIT = 2, MASTERY = 2.5, VERS = 3.5 },
        ["San'layn"] = { HASTE = 1, MASTERY = 1.5, CRIT = 2.5, VERS = 3.5 },
    },
})
