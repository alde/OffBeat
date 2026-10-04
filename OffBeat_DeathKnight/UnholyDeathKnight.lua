local OffBeat = _G.OffBeat

-- Method 12.1 (updated 24 Sep 2026). Hero trees: Riders of the Apocalypse and
-- San'layn. 12.1 reworked the spec: Festering Wounds became Lesser Ghouls,
-- Apocalypse / Gargoyle / Raise Abomination left the builds, and Putrefy,
-- Festering Scythe, Necrotic Coil and a new Dark Transformation came in.
-- Talents you don't have are ignored.
OffBeat:RegisterProfile({
    meta = {
        name = "Unholy Death Knight",
        specId = 252,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1 (24 Sep 2026)",
    },

    rotationSpells = {
        { spellId = 85948 },   -- Festering Strike
        { spellId = 55090 },   -- Scourge Strike
        { spellId = 433895 },  -- Vampiric Strike (San'layn)
        { spellId = 455397 },  -- Festering Scythe
        { spellId = 1247378 }, -- Putrefy
        { spellId = 1242174 }, -- Necrotic Coil
        { spellId = 47541 },   -- Death Coil
        { spellId = 207317 },  -- Epidemic
        { spellId = 77575 },   -- Outbreak
        { spellId = 43265 },   -- Death and Decay
        { spellId = 343294 },  -- Soul Reaper
        { spellId = 383269 },  -- Graveyard
        { spellId = 1271974 }, -- Blightfall (San'layn)
        { spellId = 1233448 }, -- Dark Transformation
        { spellId = 42650 },   -- Army of the Dead
        { spellId = 49998 },   -- Death Strike
        { spellId = 48707 },   -- Anti-Magic Shell
        { spellId = 48792 },   -- Icebound Fortitude
    },

    trackedAuras = {
        { spellId = 81340,   name = "Sudden Doom",                baseDuration = 10, stacks = false },
        { spellId = 1233448, name = "Dark Transformation",        baseDuration = 15, stacks = false },
        -- Festering Strike at 0, Scourge Strike with stacks
        { spellId = 1254252, name = "Lesser Ghoul",               baseDuration = 0,  stacks = true },
        { spellId = 194879,  name = "Icy Talons",                 baseDuration = 6,  stacks = true },
        { spellId = 444040,  name = "Essence of the Blood Queen", baseDuration = 20, stacks = true },
    },

    keyCooldown = {
        spellId = 1233448,
        name = "Dark Transformation",
        duration = 15,
    },

    -- Method: Army, Dark Transformation and Soul Reaper all go on cooldown.
    idleCooldowns = {
        { spellId = 42650,   name = "Army of the Dead" },
        { spellId = 1233448, name = "Dark Transformation" },
        { spellId = 343294,  name = "Soul Reaper" },
    },

    -- Sudden Doom is spent on Death Coil in single target; at 3+ targets
    -- Method spends on Epidemic instead, so an expiry there is expected.
    procTracking = {
        {
            procAura = 81340,
            consumeSpells = { 47541 },
            window = 0.5,
            name = "Sudden Doom",
        },
    },

    -- Method 12.1 (same for both hero trees): Crit > Mastery >= Haste > Vers
    statPriority = { CRIT = 1, MASTERY = 2, HASTE = 2.5, VERS = 3.5 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Rows you don't have talented are hidden.
    keyLayout = {
        { spellId = 55090,   st = 1, aoe = 1, note = "With Lesser Ghoul stacks" },
        { spellId = 433895,  st = 1, aoe = 1, note = "San'layn: under 7 Essence of the Blood Queen" },
        { spellId = 85948,   st = 1, aoe = 1, note = "At 0 Lesser Ghoul stacks" },
        { spellId = 47541,   st = 1, aoe = 2, note = "Sudden Doom, RP dump. AoE: 2 targets or fewer" },
        { spellId = 207317,           aoe = 1, note = "3+ targets" },
        { spellId = 1247378, st = 2, aoe = 1, note = "Don't cap charges, dump in Dark Transformation" },
        { spellId = 1242174, st = 2, aoe = 2, note = "3 targets or fewer" },
        { spellId = 455397,  st = 2, aoe = 2, note = "Refresh the debuff" },
        { spellId = 77575,   st = 2, aoe = 2, note = "When Virulent Plague is missing" },
        { spellId = 343294,  st = 2, aoe = 2, note = "On cooldown" },
        { spellId = 43265,            aoe = 2, note = "2+ targets" },
        { spellId = 1233448, st = 3, aoe = 3, note = "Main cooldown" },
        { spellId = 42650,   st = 3, aoe = 3, note = "On cooldown" },
        { spellId = 383269,           aoe = 3, note = "4+ targets" },
        { spellId = 1271974, st = 3,          note = "San'layn: before Soul Reaper expires" },
    },
})
