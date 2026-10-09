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
        { spellId = 458128 },  -- Festering Scythe (the ID top logs show)
        { spellId = 1247378 }, -- Putrefy
        { spellId = 1242174 }, -- Necrotic Coil
        { spellId = 47541 },   -- Death Coil
        { spellId = 207317 },  -- Epidemic
        { spellId = 77575 },   -- Outbreak
        { spellId = 43265 },   -- Death and Decay
        { spellId = 343294 },  -- Soul Reaper
        { spellId = 383269 },  -- Graveyard
        { spellId = 1271974 }, -- Blightfall (San'layn)
        { spellId = 1271967 }, -- Blightfall (the ID top logs show)
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

    -- /ob bars: puts these on your bars, mapped role for role onto how the
    -- warlock is organised (binds are account-wide): spender on 1, short
    -- cooldown on 2, filler on 3, big cooldown on Q, debuffs on Shift-1/2,
    -- summon cooldown on Shift-3, interrupt on Shift-E, movement on F,
    -- combat rez on F5, long / short defensive on ` / Shift-`. E (potion)
    -- and F1/F2 (healthstone, health potion) are left as they are, and
    -- Shift-4/Shift-5 are free for M+ utility. Necrotic Coil and Festering
    -- Scythe aren't buttons of their own: they show up on Death Coil and
    -- Festering Strike.
    -- Slots: 1-12 main bar, 61-72 bottom left, 49-60 bottom right, 25-36 right.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 47541,   note = "Death Coil: main spender, Necrotic Coil shows up here (Hand of Gul'dan's spot)" },
        { slot = 2,  key = "2",       spellId = 1247378, note = "Putrefy: short cooldown, save for Dark Transformation (Dreadstalkers' spot)" },
        { slot = 3,  key = "3",       spellId = 55090,   note = "Scourge Strike / Vampiric Strike: filler, most pressed (Shadow Bolt's spot)" },
        { slot = 4,  key = "4",       spellId = 85948,   note = "Festering Strike, Festering Scythe shows up here" },
        { slot = 5,  key = "5",       spellId = 343294,  note = "Soul Reaper (Demonbolt's spot)" },
        { slot = 6,  key = "Q",       spellId = 1233448, note = "Dark Transformation: big cooldown (Tyrant's spot)" },
        { slot = 61, key = "Shift-1", spellId = 77575,   note = "Outbreak: diseases (curse spot)" },
        { slot = 62, key = "Shift-2", spellId = 1271967, alt = { 1271974 }, note = "Blightfall (second curse spot)" },
        { slot = 63, key = "Shift-3", spellId = 42650,   note = "Army of the Dead: summon cooldown (Imp Lord's spot)" },
        { slot = 50, key = "Shift-E", spellId = 47528,   note = "Mind Freeze: interrupt" },
        { slot = 70, key = "F",       spellId = 48265,   note = "Death's Advance: movement (Burning Rush's spot)" },
        { slot = 25, key = "F5",      spellId = 61999,   note = "Raise Ally: combat rez (soulstone's spot)" },
        { slot = 55, key = "`",       spellId = 48792,   note = "Icebound Fortitude: long defensive" },
        { slot = 56, key = "Shift-`", spellId = 48707,   note = "Anti-Magic Shell: short defensive, top players use it a lot" },
        { slot = 12, key = "X",       spellId = 51052,   note = "Anti-Magic Zone (swap in your macro)" },
        { slot = 7,  key = "G",       spellId = 207317,  note = "Epidemic: 3+ targets" },
        { slot = 67, key = "R",       spellId = 383269,  note = "Graveyard: 4+ targets" },
        { slot = 68, key = "T",       spellId = 49998,   note = "Death Strike: emergencies" },
    },

    -- Coaching: Method says to dump Putrefy inside Dark Transformation (and
    -- not to cap its charges). Across the top 40 heroic parses per boss
    -- (Oct 2026) the median 15s Dark Transformation holds 2 Putrefy on
    -- every boss: 7.3 a minute inside it vs 3.9 overall.
    windows = {
        {
            name = "Dark Transformation",
            trigger = 1233448,
            duration = 15,
            note = "Save Putrefy charges for Dark Transformation and spend them inside it. "
                .. "Top players' median: 2 per window.",
            goals = {
                { name = "Putrefy", spells = { 1247378 } , min = 2 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses; values follow the order of rates.
    -- window = top players' median Putrefy count per Dark Transformation.
    -- All 360 of those parses play San'layn (Vampiric Strike).
    benchmarks = {
        source = "top 40 heroic parses per boss (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",   all = true },
            { name = "Vampiric Strike",  spells = { 433895 } },
            { name = "Death Coil",       spells = { 47541 } },
            { name = "Necrotic Coil",    spells = { 1242174 } },
            { name = "Scourge Strike",   spells = { 55090 } },
            { name = "Putrefy",          spells = { 1247378 } },
            { name = "Festering Strike", spells = { 85948 } },
            { name = "Soul Reaper",      spells = { 343294 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 2, values = {
                { 51.5, 52.7, 54.9 }, { 12.3, 12.7, 13.5 }, { 8.7, 9.4, 10.2 }, { 5.6, 5.9, 6.4 }, { 5.9, 6.5, 6.9 }, { 3.0, 3.3, 3.5 }, { 2.8, 3.1, 3.2 }, { 1.9, 2.1, 2.4 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 2, values = {
                { 60.9, 62.6, 63.8 }, { 14.9, 15.7, 16.1 }, { 11.0, 11.6, 12.2 }, { 8.0, 8.7, 9.1 }, { 7.1, 7.7, 8.4 }, { 3.6, 3.8, 4.2 }, { 3.3, 3.5, 3.7 }, { 2.2, 2.4, 2.5 } } },
            [3445] = { name = "Entombed Sentinels", window = 2, values = {
                { 59.3, 61.2, 62.6 }, { 14.4, 14.9, 16.0 }, { 11.0, 11.6, 12.2 }, { 7.8, 8.4, 9.0 }, { 7.6, 8.2, 9.1 }, { 3.5, 3.9, 4.1 }, { 3.1, 3.5, 3.8 }, { 1.9, 2.1, 2.3 } } },
            [3455] = { name = "Vashnik the Malignant", window = 2, values = {
                { 59.4, 61.3, 62.7 }, { 14.4, 15.4, 16.1 }, { 11.6, 11.9, 12.6 }, { 4.8, 5.4, 6.6 }, { 7.3, 8.1, 8.4 }, { 3.4, 4.0, 4.3 }, { 3.2, 3.4, 3.7 }, { 2.1, 2.3, 2.4 } } },
            [3497] = { name = "The Lost Explorers", window = 2, values = {
                { 60.8, 62.3, 63.7 }, { 14.6, 15.9, 16.6 }, { 10.6, 11.5, 11.8 }, { 8.0, 8.8, 9.2 }, { 7.1, 7.8, 8.5 }, { 3.5, 3.9, 4.4 }, { 3.3, 3.6, 3.9 }, { 2.3, 2.5, 2.8 } } },
            [3420] = { name = "Sszorak", window = 2, values = {
                { 61.7, 62.8, 64.4 }, { 14.8, 15.6, 16.1 }, { 12.1, 12.6, 13.4 }, { 8.1, 8.5, 9.3 }, { 7.7, 8.4, 9.0 }, { 3.3, 3.9, 4.3 }, { 3.4, 3.6, 3.8 }, { 2.1, 2.3, 2.4 } } },
            [3421] = { name = "The Twin Fangs", window = 2, values = {
                { 60.3, 62.2, 63.0 }, { 14.4, 14.8, 16.1 }, { 11.9, 12.3, 12.9 }, { 8.0, 8.3, 8.8 }, { 7.7, 8.3, 8.8 }, { 3.2, 3.9, 4.1 }, { 3.4, 3.6, 3.8 }, { 2.1, 2.3, 2.4 } } },
            [3429] = { name = "The Coiled Altar", window = 2, values = {
                { 58.2, 60.3, 61.2 }, { 13.3, 13.8, 14.5 }, { 11.3, 12.0, 12.7 }, { 7.3, 7.9, 8.4 }, { 7.0, 7.6, 8.4 }, { 3.4, 3.8, 4.1 }, { 3.5, 3.6, 3.9 }, { 2.7, 2.9, 3.0 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 2, values = {
                { 61.1, 62.3, 63.9 }, { 14.9, 15.6, 16.4 }, { 10.6, 11.4, 12.1 }, { 8.2, 8.8, 9.2 }, { 7.7, 8.3, 8.7 }, { 3.5, 4.0, 4.3 }, { 3.3, 3.6, 3.8 }, { 2.2, 2.4, 2.5 } } },
        },
        overall = { name = "all heroic bosses", window = 2, values = {
            { 59.3, 61.4, 63.3 }, { 14.1, 15.0, 16.0 }, { 10.9, 11.8, 12.4 }, { 7.0, 8.2, 9.0 }, { 7.2, 7.9, 8.6 }, { 3.4, 3.8, 4.2 }, { 3.2, 3.5, 3.8 }, { 2.1, 2.3, 2.5 } } },
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
        { spellId = 77575,   st = 2, aoe = 2, note = "When Virulent Plague is missing" },
        { spellId = 343294,  st = 2, aoe = 2, note = "On cooldown" },
        { spellId = 43265,            aoe = 2, note = "2+ targets" },
        { spellId = 1233448, st = 3, aoe = 3, note = "Main cooldown" },
        { spellId = 42650,   st = 3, aoe = 3, note = "On cooldown" },
        { spellId = 383269,           aoe = 3, note = "4+ targets" },
        { spellId = 1271974, alt = { 1271967 }, st = 3, note = "San'layn: before Soul Reaper expires" },
    },
})
