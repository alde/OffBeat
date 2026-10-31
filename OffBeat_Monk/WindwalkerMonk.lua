local OffBeat = _G.OffBeat

-- Windwalker Monk, Method 12.1.5 (14 Oct 2026), checked against the top 40
-- heroic parses on every Venomous Abyss boss (360) and the top 40 timed
-- runs per Season 2 dungeon (320 runs; Warcraft Logs, Oct 2026). The top
-- players are Conduit of the Celestials (Celestial Conduit in 98% of
-- parses and runs), so the sheet is Method's Conduit priority.
--
-- Invoke Xuen and Celestial Conduit every ~91s, Zenith on its charges
-- (~every 27s, ~1 a minute), Whirling Dragon Punch every ~22s, Touch of
-- Death every ~98s. Inside Zenith's 15s the top players fit 3 Fists of
-- Fury, 3 Rising Sun Kicks and 3 Spinning Crane Kicks. Combo Strikes:
-- only 0.47% of their casts repeat the one before.
OffBeat:RegisterProfile({
    meta = {
        name = "Windwalker Monk",
        specId = 269,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    rotationSpells = {
        { spellId = 100780 },  -- Tiger Palm
        { spellId = 100784 },  -- Blackout Kick
        { spellId = 107428 },  -- Rising Sun Kick
        { spellId = 113656 },  -- Fists of Fury
        { spellId = 101546 },  -- Spinning Crane Kick
        { spellId = 152175 },  -- Whirling Dragon Punch
        { spellId = 467307 },  -- Rushing Wind Kick
        { spellId = 443028 },  -- Celestial Conduit
        { spellId = 1249625 }, -- Zenith
        { spellId = 1272696 }, -- Zenith Stomp
        { spellId = 123904 },  -- Invoke Xuen, the White Tiger
        { spellId = 322109 },  -- Touch of Death
    },

    mistakes = {
        {
            type = "repeat_cast",
            name = "Mastery Break",
            description = "Same ability cast twice breaks Combo Strikes mastery",
        },
    },

    -- Your own buffs. 12.1 hides them in combat, so these show out of
    -- combat and whenever the game lets them through.
    trackedAuras = {
        { spellId = 1249625, name = "Zenith",          baseDuration = 15, stacks = false },
        { spellId = 116768,  name = "Blackout Kick!",  baseDuration = 15, stacks = true },
        { spellId = 220358,  name = "Dance of Chi-Ji", baseDuration = 15, stacks = true },
    },

    keyCooldown = {
        spellId = 1249625,
        name = "Zenith",
        duration = 15,
    },

    failNudges = {
        { error = "range", spells = { 100780, 100784, 107428, 113656 }, name = "Melee out of range",
          text = "Out of range: Roll / Flying Serpent Kick back in" },
    },

    -- Countdown to Invoke Xuen: Zenith goes out with it (the cast right
    -- before Zenith is Xuen 46% of the time).
    prep = {
        spellId = 123904, name = "Invoke Xuen", cooldown = 90, lead = 5,
        hint = "Tiger Palm, Invoke Xuen, Zenith with potion and trinket, then Fists of Fury",
        checks = {
            { name = "Zenith", ready = 1249625, cooldown = 30 },
        },
    },

    -- On cooldown for every top player.
    idleCooldowns = {
        { spellId = 123904,  name = "Invoke Xuen" },
        { spellId = 443028,  name = "Celestial Conduit" },
        { spellId = 152175,  name = "Whirling Dragon Punch" },
        { spellId = 322109,  name = "Touch of Death" },
    },

    -- Coaching: Zenith (15s). Raid: 3 Fists of Fury, 3 Rising Sun Kicks.
    -- M+: 3 Fists of Fury, 3 Spinning Crane Kicks.
    windows = {
        {
            name = "Zenith (raid)",
            trigger = 1249625,
            duration = 15,
            content = "raid",
            note = "Fists of Fury and Rising Sun Kick on cooldown, Zenith Stomp when low on Chi or as it ends. "
                .. "Top players: 3 Fists of Fury, 3 Rising Sun Kicks.",
            goals = {
                { name = "Fists of Fury", spells = { 113656 }, min = 3 },
                { name = "Rising Sun Kick", spells = { 107428 }, min = 3 },
            },
        },
        {
            name = "Zenith (M+)",
            trigger = 1249625,
            duration = 15,
            content = "dungeon",
            note = "Into a pack: Fists of Fury, Spinning Crane Kick with spare Chi (5+ targets). "
                .. "Top players: 3 Fists of Fury, 3 Spinning Crane Kicks.",
            goals = {
                { name = "Fists of Fury", spells = { 113656 }, min = 3 },
                { name = "Spinning Crane Kick", spells = { 101546 }, min = 3 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Fists of Fury per Zenith (top 20
    -- per boss). Dungeons (by instance ID): the top 40 timed runs, per
    -- minute in combat (Warcraft Logs' pulls).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",      all = true },
            { name = "Tiger Palm",          spells = { 100780 } },
            { name = "Spinning Crane Kick", spells = { 101546 } },
            { name = "Rising Sun Kick",     spells = { 107428 } },
            { name = "Fists of Fury",       spells = { 113656 } },
            { name = "Blackout Kick",       spells = { 100784 } },
            { name = "Rushing Wind Kick",   spells = { 467307 } },
            { name = "Whirling Dragon Punch", spells = { 152175 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 3, values = {
                { 41.6, 42.9, 43.9 }, { 9.6, 10.5, 11.0 }, { 7.9, 8.5, 9.2 }, { 5.8, 6.3, 6.7 }, { 5.6, 5.9, 6.0 }, { 4.7, 5.2, 5.9 }, { 1.8, 2.0, 2.2 }, { 1.8, 1.9, 2.0 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 3, values = {
                { 48.0, 49.4, 50.0 }, { 9.4, 10.1, 10.9 }, { 6.8, 8.0, 9.4 }, { 8.1, 8.4, 9.2 }, { 7.1, 7.3, 7.6 }, { 5.9, 6.7, 7.5 }, { 2.5, 2.8, 3.2 }, { 2.2, 2.4, 2.5 } } },
            [3445] = { name = "Entombed Sentinels", window = 3, values = {
                { 46.2, 47.7, 48.8 }, { 9.7, 10.4, 11.2 }, { 7.1, 8.0, 8.9 }, { 7.1, 7.8, 8.4 }, { 6.5, 6.8, 7.1 }, { 5.7, 6.3, 7.4 }, { 2.2, 2.4, 2.7 }, { 2.1, 2.4, 2.5 } } },
            [3455] = { name = "Vashnik the Malignant", window = 3, values = {
                { 49.1, 50.6, 51.9 }, { 10.2, 11.0, 11.7 }, { 8.1, 8.9, 11.0 }, { 7.2, 8.0, 8.7 }, { 6.8, 7.3, 7.5 }, { 5.9, 6.8, 7.8 }, { 2.3, 2.7, 3.0 }, { 2.2, 2.3, 2.5 } } },
            [3497] = { name = "The Lost Explorers", window = 3, values = {
                { 49.0, 50.0, 51.0 }, { 9.8, 10.4, 11.8 }, { 9.6, 10.4, 12.0 }, { 6.2, 7.2, 8.2 }, { 7.0, 7.3, 7.7 }, { 5.0, 5.9, 6.7 }, { 2.0, 2.5, 2.8 }, { 2.1, 2.4, 2.5 } } },
            [3420] = { name = "Sszorak", window = 3, values = {
                { 48.8, 49.8, 50.8 }, { 10.0, 10.9, 11.6 }, { 5.8, 7.7, 8.5 }, { 8.5, 8.8, 9.3 }, { 7.0, 7.3, 7.6 }, { 6.3, 6.9, 8.1 }, { 2.4, 3.0, 3.4 }, { 2.2, 2.4, 2.5 } } },
            [3421] = { name = "The Twin Fangs", window = 3, values = {
                { 48.9, 50.0, 51.0 }, { 10.8, 11.5, 12.1 }, { 10.1, 11.7, 13.2 }, { 5.4, 6.3, 7.3 }, { 6.7, 6.9, 7.2 }, { 5.0, 5.7, 6.5 }, { 2.1, 2.6, 2.9 }, { 2.2, 2.3, 2.4 } } },
            [3429] = { name = "The Coiled Altar", window = 3, values = {
                { 46.4, 47.5, 48.4 }, { 9.8, 10.4, 11.1 }, { 7.0, 8.5, 9.5 }, { 6.8, 7.7, 8.2 }, { 6.5, 6.8, 7.0 }, { 5.8, 6.4, 7.1 }, { 2.3, 2.4, 2.8 }, { 2.3, 2.4, 2.5 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 3, values = {
                { 45.4, 47.0, 49.3 }, { 8.8, 9.7, 10.6 }, { 7.3, 8.4, 9.1 }, { 6.7, 7.2, 8.4 }, { 6.4, 7.0, 7.3 }, { 5.4, 6.1, 7.0 }, { 2.0, 2.4, 2.8 }, { 2.1, 2.3, 2.5 } } },
        },
        overall = { name = "all heroic bosses", window = 3, values = {
            { 46.9, 48.7, 50.2 }, { 9.7, 10.6, 11.4 }, { 7.6, 8.8, 10.0 }, { 6.6, 7.6, 8.6 }, { 6.6, 7.0, 7.4 }, { 5.4, 6.3, 7.2 }, { 2.2, 2.5, 2.9 }, { 2.1, 2.3, 2.5 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 3, values = {
                { 43.3, 44.7, 45.6 }, { 10.0, 10.6, 11.4 }, { 8.6, 9.2, 9.9 }, { 5.2, 5.9, 6.5 }, { 5.8, 6.0, 6.2 }, { 4.3, 4.8, 5.6 }, { 1.9, 2.1, 2.3 }, { 1.9, 2.0, 2.0 } } },
            [2825] = { name = "Den of Nalorakk", window = 3, values = {
                { 41.6, 42.4, 43.9 }, { 9.2, 9.9, 10.4 }, { 7.7, 8.6, 9.3 }, { 5.1, 5.8, 6.1 }, { 5.5, 5.7, 5.9 }, { 4.0, 4.8, 5.4 }, { 1.7, 1.9, 2.2 }, { 1.8, 1.9, 2.0 } } },
            [1762] = { name = "Kings' Rest", window = 3, values = {
                { 44.2, 45.1, 46.1 }, { 10.0, 10.6, 11.3 }, { 8.3, 8.7, 9.2 }, { 5.7, 6.2, 6.8 }, { 5.7, 5.9, 6.2 }, { 4.9, 5.4, 5.8 }, { 2.1, 2.2, 2.3 }, { 2.0, 2.1, 2.1 } } },
            [2813] = { name = "Murder Row", window = 3, values = {
                { 42.9, 43.7, 44.3 }, { 9.7, 10.4, 11.0 }, { 8.4, 9.2, 9.8 }, { 4.6, 5.7, 6.2 }, { 5.6, 5.8, 6.2 }, { 4.2, 4.6, 5.3 }, { 1.9, 2.0, 2.2 }, { 1.9, 2.0, 2.0 } } },
            [2521] = { name = "Ruby Life Pools", window = 3, values = {
                { 44.4, 45.5, 46.9 }, { 10.6, 11.4, 11.9 }, { 8.4, 9.1, 10.1 }, { 5.3, 6.0, 6.7 }, { 5.8, 6.1, 6.4 }, { 4.3, 4.7, 5.4 }, { 1.9, 2.1, 2.3 }, { 1.9, 2.0, 2.1 } } },
            [1877] = { name = "Temple of Sethraliss", window = 2, values = {
                { 43.4, 44.4, 45.7 }, { 10.3, 11.2, 11.6 }, { 8.2, 8.9, 9.7 }, { 5.2, 5.8, 6.5 }, { 5.5, 5.8, 6.1 }, { 4.4, 4.6, 5.3 }, { 1.9, 2.1, 2.2 }, { 1.9, 2.0, 2.1 } } },
            [2859] = { name = "The Blinding Vale", window = 3, values = {
                { 44.4, 45.5, 46.6 }, { 10.6, 11.4, 12.0 }, { 9.0, 9.5, 10.0 }, { 5.0, 5.9, 6.4 }, { 5.9, 6.1, 6.3 }, { 4.5, 4.8, 5.5 }, { 1.8, 2.1, 2.4 }, { 1.9, 2.0, 2.1 } } },
            [2923] = { name = "Voidscar Arena", window = 3, values = {
                { 43.8, 44.8, 46.1 }, { 10.3, 10.9, 11.6 }, { 8.5, 8.9, 9.4 }, { 5.0, 5.9, 6.4 }, { 5.6, 6.0, 6.3 }, { 4.7, 5.4, 6.1 }, { 1.9, 2.2, 2.4 }, { 1.9, 2.0, 2.1 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 3, values = {
            { 43.3, 44.6, 45.9 }, { 10.0, 10.8, 11.5 }, { 8.4, 9.0, 9.8 }, { 5.2, 5.9, 6.5 }, { 5.6, 6.0, 6.2 }, { 4.4, 4.9, 5.6 }, { 1.9, 2.1, 2.3 }, { 1.9, 2.0, 2.1 } } },
    },

    -- /ob bars: role for role on the keys your other melee specs use
    -- (binds are account-wide): Rising Sun Kick on 1, Spinning Crane Kick
    -- on 2, Tiger Palm (most pressed) on 3, Blackout Kick on 4, Fists of
    -- Fury on 5, Whirling Dragon Punch on Q, Rushing Wind Kick on G, Zenith
    -- on Shift-1, Invoke Xuen on Shift-2, Celestial Conduit on Shift-3,
    -- Touch of Death on R. Interrupt Shift-E, stun Shift-Q, defensives on `
    -- / Shift-`, Roll on F, Tiger's Lust on Shift-F. One layout for raid
    -- and M+.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 107428, note = "Rising Sun Kick: on cooldown" },
        { slot = 2,  key = "2",       spellId = 101546, note = "Spinning Crane Kick: Dance of Chi-Ji, spare Chi in Zenith, packs" },
        { slot = 3,  key = "3",       spellId = 100780, note = "Tiger Palm: Chi, most pressed (~11 a minute); don't repeat it" },
        { slot = 4,  key = "4",       spellId = 100784, note = "Blackout Kick: Combo Breaker, filler" },
        { slot = 5,  key = "5",       spellId = 113656, note = "Fists of Fury: on cooldown, before Heart of the Jade Serpent ends" },
        { slot = 6,  key = "Q",       spellId = 152175, note = "Whirling Dragon Punch: every ~22s" },
        { slot = 7,  key = "G",       spellId = 467307, note = "Rushing Wind Kick: when it lights up" },
        { slot = 8,  key = "E",       spellId = 1272696, note = "Zenith Stomp: low on Chi, or as Zenith ends" },
        { slot = 61, key = "Shift-1", spellId = 1249625, note = "Zenith: on its charges (~1 a minute), after Xuen" },
        { slot = 62, key = "Shift-2", spellId = 123904, note = "Invoke Xuen: every ~91s, Zenith with it" },
        { slot = 63, key = "Shift-3", spellId = 443028, note = "Celestial Conduit: once Heart of the Jade Serpent has run out" },
        { slot = 67, key = "R",       spellId = 322109, note = "Touch of Death: on cooldown (~98s)" },
        { slot = 64, key = "Shift-4", spellId = 115078, note = "Paralysis (M+)" },
        { slot = 65, key = "Shift-5", spellId = 116844, note = "Ring of Peace (93% of top M+ runs)" },
        { slot = 66, key = "Shift-Q", spellId = 119381, note = "Leg Sweep: stun a pack" },
        { slot = 50, key = "Shift-E", spellId = 116705, note = "Spear Hand Strike: interrupt" },
        { slot = 12, key = "X",       macro = { name = "OB DetoxWW", spells = { 218164 }, mouseover = true },
          note = "Detox (mouseover): poison and disease" },
        { slot = 70, key = "F",       spellId = 109132, note = "Roll: movement" },
        { slot = 71, key = "Shift-F", spellId = 116841, note = "Tiger's Lust: movement, breaks roots" },
        { slot = 55, key = "`",       spellId = 115203, note = "Fortifying Brew: defensive" },
        { slot = 56, key = "Shift-`", spellId = 122470, note = "Touch of Karma: before burst damage" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Conduit of the
    -- Celestials), checked against the top parses and runs.
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 100780,  text = "Tiger Palm, Invoke Xuen" },
            { spellId = 1249625, text = "Zenith with potion, racial and trinket" },
            { spellId = 113656,  text = "Fists of Fury, Rising Sun Kick, Fists of Fury again if it reset" },
            { spellId = 443028,  text = "Hold Celestial Conduit until Heart of the Jade Serpent ends" },
        } },
        { title = "Single target", lines = {
            { spellId = 152175,  text = "Whirling Dragon Punch if Xuen is 10s+ away" },
            { spellId = 443028,  text = "Celestial Conduit with no Heart of the Jade Serpent" },
            { spellId = 1272696, text = "Zenith Stomp low on Chi or as Zenith ends" },
            { spellId = 113656,  text = "Fists of Fury (first if Heart has <1s left)" },
            { spellId = 467307,  text = "Rushing Wind Kick, Spinning Crane Kick with Unbroken Rhythm" },
            { spellId = 107428,  text = "Rising Sun Kick, Blackout Kick on Combo Breaker" },
            { spellId = 100780,  text = "Tiger Palm under 2 Chi or before Energy caps" },
            { spellId = 101546,  text = "Spinning Crane Kick with Dance of Chi-Ji, then Blackout Kick" },
        } },
        { title = "AoE", lines = {
            { spellId = 113656,  text = "Fists of Fury (tier: Spinning Crane Kick after it hits 2+)" },
            { spellId = 101546,  text = "Spinning Crane Kick with Unbroken Rhythm; any spare Chi" },
            { spellId = 107428,  text = "Rising Sun Kick to enable Whirling Dragon Punch" },
            { text = "Never the same spell twice in a row (Combo Strikes)" },
        } },
    },

    -- Stats: Method: Haste > Mastery = Crit >>> Versatility.
    statPriority = { HASTE = 1, MASTERY = 2, CRIT = 2, VERS = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 100780, st = 1, aoe = 1, note = "Chi, most pressed" },
        { spellId = 107428, st = 1, aoe = 1, note = "On cooldown" },
        { spellId = 113656, st = 1, aoe = 1, note = "On cooldown" },
        { spellId = 101546, st = 2, aoe = 1, note = "Dance of Chi-Ji, packs" },
        { spellId = 100784, st = 1, aoe = 2, note = "Combo Breaker, filler" },
        { spellId = 467307, st = 2, aoe = 2, note = "When it lights up" },
        { spellId = 152175, st = 2, aoe = 1, note = "Every ~22s" },
        { spellId = 1272696, st = 2, aoe = 2, note = "In Zenith" },
        { spellId = 1249625, st = 3, aoe = 3, note = "Charges" },
        { spellId = 123904, st = 3, aoe = 3, note = "Every ~91s" },
        { spellId = 443028, st = 3, aoe = 3, note = "Every ~91s" },
        { spellId = 116705, st = 2, aoe = 2, note = "Interrupt" },
    },
})
