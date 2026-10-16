local OffBeat = _G.OffBeat

-- Mistweaver Monk, Way of the Crane (Megasett, 12.1) and Method 12.1.5
-- (14 Oct 2026), checked against the top 40 heroic parses (by healing) on
-- every Venomous Abyss boss (Warcraft Logs, Oct 2026). All 360 of them
-- play Conduit of the Celestials (Method: best in all content) and 94%
-- take Invoke Yu'lon, so raid is Conduit / Yu'lon.
--
-- M+ is a different spec in practice, checked against the top 40 timed
-- runs per Season 2 dungeon (+20 to +22, 320 runs, 73 players): 98%
-- Conduit, all Chi-Ji, Rising Sun Kick (97%, not Rushing Wind Kick) and
-- Sheilun's Gift. They heal through damage (Rising Sun Kick ~16 a minute,
-- Spinning Crane Kick 9, Tiger Palm 7, Blackout Kick 6) and hardly cast
-- Vivify (under 8% of them) or Renewing Mist (1 a minute). Way of the Crane
-- says the same: Ancient Teachings through Rising Sun Kick is your heal.
-- Both builds share the profile: the content mode (/ob mode, auto by
-- instance) picks the sheet sections, idle alerts and dummy numbers, and
-- each window opens on its own cooldown (Yu'lon / Chi-Ji).
--
-- Healing is reactive, so there are no mistake rules. Even Thunder Focus
-- Tea on Renewing Mist, which both guides ask for, is only 80% of the top
-- players' Teas (a tenth of them use it on Renewing Mist under a third of
-- the time). In M+ Tea goes on Rising Sun Kick (84%). What's here is what
-- they all do the same way: the kick on cooldown, the Yu'lon ramp in raid,
-- the Chi-Ji window in M+, and casts per minute to compare against.
OffBeat:RegisterProfile({
    meta = {
        name = "Mistweaver Monk",
        specId = 270,
        version = 1,
        author = "OffBeat Defaults",
        source = "Way of the Crane 12.1 + Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Raid: pressed by 64%+ of the top players (Soothing Mist is the
    -- lowest); Restoral by 33%. M+: Rising Sun Kick, Chi-Ji, Sheilun's Gift
    -- and the damage buttons, pressed by 97%+ of the top players.
    rotationSpells = {
        { spellId = 116670 },  -- Vivify
        { spellId = 467307 },  -- Rushing Wind Kick
        { spellId = 107428 },  -- Rising Sun Kick (without Rushing Wind Kick)
        { spellId = 115151 },  -- Renewing Mist
        { spellId = 124682 },  -- Enveloping Mist
        { spellId = 116680 },  -- Thunder Focus Tea
        { spellId = 115294 },  -- Mana Tea
        { spellId = 115175 },  -- Soothing Mist
        { spellId = 116849 },  -- Life Cocoon
        { spellId = 443028 },  -- Celestial Conduit
        { spellId = 322118 },  -- Invoke Yu'lon, the Jade Serpent
        { spellId = 325197 },  -- Invoke Chi-Ji, the Red Crane
        { spellId = 115310 },  -- Revival
        { spellId = 388615 },  -- Restoral
        { spellId = 399491 },  -- Sheilun's Gift
        { spellId = 100780 },  -- Tiger Palm
        { spellId = 100784 },  -- Blackout Kick
        { spellId = 101546 },  -- Spinning Crane Kick
    },

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through.
    trackedAuras = {
        { spellId = 116680,  name = "Thunder Focus Tea",       baseDuration = 0,  stacks = true },
        { spellId = 392883,  name = "Vivacious Vivification", baseDuration = 0,  stacks = false },
        { spellId = 443112,  name = "Strength of the Black Ox", baseDuration = 0, stacks = false },
        { spellId = 1260565, name = "Spiritfont",              baseDuration = 0,  stacks = true },
        { spellId = 443421,  name = "Heart of the Jade Serpent", baseDuration = 8, stacks = false },
        { spellId = 115867,  name = "Mana Tea",                baseDuration = 0,  stacks = true },
        -- M+: Blackout Kick stacks (Rising Sun Kick resets), free Spinning
        -- Crane Kick, Sheilun's Gift charge
        { spellId = 202090,  name = "Teachings of the Monastery", baseDuration = 0, stacks = true },
        { spellId = 438443,  name = "Dance of Chi-Ji",         baseDuration = 0,  stacks = false },
        { spellId = 399497,  name = "Sheilun's Gift",          baseDuration = 0,  stacks = true },
    },

    keyCooldown = {
        spellId = 322118,
        name = "Invoke Yu'lon",
        duration = 25,
    },

    -- Vivify and Enveloping Mist are cast-time heals.
    failNudges = {
        { error = "moving", spells = { 116670, 124682 }, name = "Cast while moving",
          text = "Moving: Rushing Wind Kick, Renewing Mist, or channel Soothing Mist (Vivify / Enveloping Mist go instant)" },
    },

    -- On cooldown for every top player: Rushing Wind Kick every ~3.8s
    -- (median gap; 10s cooldown, reset by Rising Mist), Rising Sun Kick in
    -- M+ every ~2.6s, Celestial Conduit every ~96s in raid (90s cooldown),
    -- Yu'lon every ~127s (2 min). In M+ Conduit is held for damage (~127s
    -- apart), so its alert is raid only. Renewing Mist and Thunder Focus Tea
    -- have charges (they'd nag at one charge); Chi-Ji, Life Cocoon and
    -- Revival are held for damage.
    idleCooldowns = {
        { spellId = 467307, name = "Rushing Wind Kick", content = "raid" },
        { spellId = 107428, name = "Rising Sun Kick", content = "dungeon" },
        { spellId = 443028, name = "Celestial Conduit", content = "raid" },
        { spellId = 322118, name = "Invoke Yu'lon", content = "raid" },
    },

    -- Coaching: the Yu'lon ramp (Way of the Crane: spread Enveloping Mist,
    -- extend it and Renewing Mist with Rushing Wind Kick, finish on Vivify;
    -- Rushing Wind Kick and Renewing Mist on cooldown throughout). In the
    -- 25s of Yu'lon the top players cast 6 Enveloping Mists (median; 4 in
    -- the middle half's low end, 3 of them in the first 6s), 6 Rushing Wind
    -- Kicks, 4 Renewing Mists and 6 Vivifies.
    windows = {
        {
            name = "Yu'lon",
            trigger = 322118,
            duration = 25,
            note = "Thunder Focus Tea on Renewing Mist first, then Yu'lon: Enveloping Mist on 2-3 players, "
                .. "Rushing Wind Kick to extend, Vivify to finish. Top players: 6 Enveloping Mists, 6 kicks.",
            goals = {
                { name = "Enveloping Mist", spells = { 124682 }, min = 6 },
                { name = "Rushing Wind Kick", spells = { 467307, 107428 }, min = 6 },
            },
        },
        -- M+ (Method: Chi-Ji, Blackout Kick with its Teachings stacks, Rising
        -- Sun Kick again on a reset). 12s with Gift of the Celestials, which
        -- the top players take (Chi-Ji ~81s apart). In those 12s they cast
        -- 3 Rising Sun Kicks and 2 Blackout Kicks (median); 38% of Chi-Jis
        -- are followed straight by Blackout Kick.
        {
            name = "Chi-Ji",
            trigger = 325197,
            duration = 12,
            note = "Chi-Ji, Blackout Kick on the Teachings stacks, Rising Sun Kick on every reset, "
                .. "instant Enveloping Mist where it's needed. Top players: 3 Rising Sun Kicks, 2 Blackout Kicks.",
            goals = {
                { name = "Rising Sun Kick", spells = { 107428 }, min = 3 },
                { name = "Blackout Kick", spells = { 100784 }, min = 2 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Enveloping Mists per Yu'lon.
    -- Dungeons (by instance ID): the top 40 timed runs, per minute in combat
    -- (Warcraft Logs' pulls); window = median Rising Sun Kicks per Chi-Ji.
    -- Raid has no numbers for the last three rates, M+ none for Vivify.
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",     all = true },
            { name = "Vivify",             spells = { 116670 } },
            { name = "Rushing Wind Kick",  spells = { 467307, 107428 } },
            { name = "Renewing Mist",      spells = { 115151 } },
            { name = "Enveloping Mist",    spells = { 124682 } },
            { name = "Thunder Focus Tea",  spells = { 116680 } },
            { name = "Mana Tea",           spells = { 115294 } },
            { name = "Celestial Conduit",  spells = { 443028 } },
            { name = "Sheilun's Gift",     spells = { 399491 } },
            { name = "Spinning Crane Kick", spells = { 101546 } },
            { name = "Tiger Palm / Blackout Kick", spells = { 100780, 100784 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 8, values = {
                { 57.8, 59.7, 60.9 }, { 15.1, 16.1, 17.7 }, { 13.5, 14.2, 15.7 }, { 11.0, 11.7, 12.3 }, { 6.1, 7.9, 9.1 }, { 2.7, 2.8, 2.8 }, { 2.4, 2.8, 3.4 }, { 0.6, 0.7, 0.7 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 7, values = {
                { 57.1, 58.9, 60.3 }, { 13.4, 15.6, 17.9 }, { 13.5, 14.3, 15.5 }, { 10.8, 11.8, 12.2 }, { 6.3, 7.8, 9.1 }, { 2.6, 2.7, 2.8 }, { 2.1, 2.6, 2.9 }, { 0.6, 0.7, 0.7 } } },
            [3445] = { name = "Entombed Sentinels", window = 5, values = {
                { 54.0, 55.6, 58.6 }, { 13.2, 14.8, 16.9 }, { 13.0, 14.6, 15.7 }, { 10.2, 10.8, 11.7 }, { 4.8, 7.1, 8.6 }, { 2.6, 2.7, 2.8 }, { 1.7, 2.3, 2.8 }, { 0.6, 0.6, 0.7 } } },
            [3455] = { name = "Vashnik the Malignant", window = 6, values = {
                { 56.4, 58.0, 60.0 }, { 13.8, 15.3, 16.8 }, { 13.3, 14.9, 16.3 }, { 10.6, 11.6, 12.2 }, { 5.9, 7.1, 8.9 }, { 2.6, 2.7, 2.9 }, { 1.8, 2.2, 2.7 }, { 0.6, 0.7, 0.7 } } },
            [3497] = { name = "The Lost Explorers", window = 6, values = {
                { 55.7, 57.5, 61.2 }, { 12.8, 14.2, 15.7 }, { 13.3, 14.7, 16.0 }, { 11.1, 11.9, 12.8 }, { 6.7, 7.7, 8.8 }, { 2.6, 2.8, 2.9 }, { 1.6, 2.1, 3.1 }, { 0.6, 0.6, 0.7 } } },
            [3420] = { name = "Sszorak", window = 7, values = {
                { 56.1, 58.9, 62.5 }, { 13.9, 15.6, 17.9 }, { 12.6, 15.0, 16.3 }, { 10.9, 11.6, 12.3 }, { 5.8, 7.7, 9.3 }, { 2.6, 2.7, 2.9 }, { 2.0, 2.5, 3.4 }, { 0.6, 0.6, 0.7 } } },
            [3421] = { name = "The Twin Fangs", window = 6, values = {
                { 56.1, 58.0, 60.6 }, { 13.6, 15.4, 17.5 }, { 13.2, 14.7, 16.1 }, { 11.0, 11.6, 12.3 }, { 5.8, 7.5, 8.8 }, { 2.6, 2.7, 2.8 }, { 2.0, 2.7, 3.4 }, { 0.5, 0.6, 0.6 } } },
            [3429] = { name = "The Coiled Altar", window = 7, values = {
                { 59.8, 61.7, 64.2 }, { 15.5, 17.2, 18.3 }, { 13.8, 15.0, 16.3 }, { 11.1, 11.9, 12.5 }, { 6.6, 7.9, 10.4 }, { 2.6, 2.8, 2.9 }, { 2.5, 3.1, 3.8 }, { 0.6, 0.7, 0.7 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 6, values = {
                { 55.3, 56.9, 59.8 }, { 12.2, 13.5, 15.9 }, { 13.0, 14.1, 14.8 }, { 10.6, 11.2, 11.8 }, { 6.3, 7.5, 9.1 }, { 2.5, 2.6, 2.7 }, { 1.8, 2.5, 3.1 }, { 0.5, 0.6, 0.7 } } },
        },
        overall = { name = "all heroic bosses", window = 6, values = {
            { 55.9, 58.7, 61.3 }, { 13.6, 15.4, 17.6 }, { 13.3, 14.6, 15.9 }, { 10.8, 11.6, 12.3 }, { 6.0, 7.5, 9.1 }, { 2.6, 2.7, 2.8 }, { 1.9, 2.5, 3.3 }, { 0.6, 0.6, 0.7 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 4, values = {
                { 50.1, 52.0, 54.0 }, nil, { 13.6, 15.9, 17.4 }, { 0.5, 1.0, 1.8 }, { 2.5, 2.9, 3.7 }, { 2.1, 2.3, 2.4 }, { 0.7, 0.8, 1.2 }, { 0.3, 0.4, 0.5 }, { 1.4, 1.9, 2.6 }, { 8.5, 11.1, 15.2 }, { 10.3, 12.6, 14.2 } } },
            [2825] = { name = "Den of Nalorakk", window = 3, values = {
                { 47.4, 49.6, 52.4 }, nil, { 14.6, 15.6, 16.6 }, { 0.5, 1.0, 1.8 }, { 2.5, 3.0, 3.5 }, { 2.1, 2.3, 2.4 }, { 0.6, 0.9, 1.2 }, { 0.4, 0.4, 0.5 }, { 1.3, 1.8, 2.7 }, { 6.8, 9.0, 11.8 }, { 11.0, 12.2, 14.3 } } },
            [1762] = { name = "Kings' Rest", window = 3, values = {
                { 49.8, 52.0, 53.9 }, nil, { 14.6, 16.3, 17.2 }, { 0.8, 1.3, 1.9 }, { 2.9, 3.5, 3.7 }, { 2.1, 2.3, 2.5 }, { 0.7, 1.0, 1.2 }, { 0.3, 0.3, 0.4 }, { 1.8, 2.4, 3.0 }, { 6.0, 6.7, 8.5 }, { 13.4, 15.0, 17.4 } } },
            [2813] = { name = "Murder Row", window = 3, values = {
                { 49.8, 51.3, 53.6 }, nil, { 13.9, 16.1, 17.3 }, { 0.7, 1.3, 2.3 }, { 3.1, 3.5, 4.1 }, { 2.1, 2.3, 2.4 }, { 0.8, 1.1, 1.5 }, { 0.4, 0.5, 0.5 }, { 1.7, 2.2, 3.7 }, { 6.5, 8.4, 11.9 }, { 8.3, 11.7, 14.0 } } },
            [2521] = { name = "Ruby Life Pools", window = 4, values = {
                { 50.5, 51.9, 54.6 }, nil, { 14.5, 16.1, 17.5 }, { 0.6, 0.9, 1.7 }, { 2.5, 3.1, 3.5 }, { 2.0, 2.2, 2.4 }, { 0.8, 1.1, 1.6 }, { 0.4, 0.4, 0.5 }, { 2.0, 2.5, 3.2 }, { 6.0, 8.8, 14.2 }, { 9.2, 13.3, 15.9 } } },
            [1877] = { name = "Temple of Sethraliss", window = 4, values = {
                { 49.0, 50.7, 52.1 }, nil, { 14.5, 15.4, 16.6 }, { 0.6, 1.0, 1.5 }, { 2.9, 3.4, 3.7 }, { 2.0, 2.3, 2.4 }, { 0.9, 1.1, 1.4 }, { 0.4, 0.4, 0.5 }, { 2.2, 2.7, 3.4 }, { 7.1, 8.9, 12.2 }, { 9.7, 11.6, 14.1 } } },
            [2859] = { name = "The Blinding Vale", window = 3, values = {
                { 50.9, 52.2, 54.5 }, nil, { 13.8, 15.9, 17.4 }, { 0.5, 1.0, 1.9 }, { 2.8, 3.3, 3.9 }, { 2.0, 2.4, 2.5 }, { 0.9, 1.1, 1.5 }, { 0.3, 0.4, 0.4 }, { 1.7, 2.4, 3.1 }, { 7.0, 10.4, 13.5 }, { 9.2, 13.3, 14.9 } } },
            [2923] = { name = "Voidscar Arena", window = 3, values = {
                { 50.3, 51.9, 54.4 }, nil, { 14.4, 16.2, 17.3 }, { 0.5, 1.0, 1.4 }, { 2.8, 3.3, 3.6 }, { 2.1, 2.3, 2.4 }, { 0.7, 1.0, 1.4 }, { 0.3, 0.4, 0.5 }, { 1.8, 2.5, 3.1 }, { 6.5, 8.9, 11.8 }, { 10.5, 13.7, 16.1 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 3, values = {
            { 49.5, 51.6, 53.7 }, nil, { 14.0, 15.8, 17.2 }, { 0.6, 1.1, 1.7 }, { 2.7, 3.3, 3.7 }, { 2.0, 2.3, 2.4 }, { 0.8, 1.0, 1.4 }, { 0.4, 0.4, 0.5 }, { 1.7, 2.4, 3.1 }, { 6.5, 8.9, 12.3 }, { 9.9, 12.7, 15.3 } } },
    },

    -- Bars: same keys as the other OffBeat specs (1-5, Q, G, E, R, X, the
    -- Shift row, F, `), one layout for raid and one for M+ / delves, since
    -- the top players' busiest buttons barely overlap (raid: Vivify,
    -- Renewing Mist, Enveloping Mist; M+: Spinning Crane Kick, Tiger Palm,
    -- Blackout Kick). Heals are mouseover macros. Keys that hold the same
    -- spell in both stay put; the swap is offered when you enter a raid, a
    -- key or a delve (/ob mode). Talents swap Rushing Wind / Rising Sun
    -- Kick and Yu'lon / Chi-Ji on their own.
    barLayout = {
        -- both
        { slot = 1,  key = "1",       spellId = 467307, alt = { 107428 },
          note = "Rushing Wind Kick (raid) / Rising Sun Kick (M+): on cooldown, ~15 a minute" },
        { slot = 5,  key = "5",       spellId = 116680, note = "Thunder Focus Tea: Renewing Mist in raid, Rising Sun Kick in M+" },
        { slot = 6,  key = "Q",       spellId = 322118, alt = { 325197 }, note = "Yu'lon (raid) / Chi-Ji (M+)" },
        { slot = 7,  key = "G",       spellId = 443028, note = "Celestial Conduit" },
        { slot = 12, key = "X",       macro = { name = "OB Detox", spells = { 115450 }, mouseover = true }, note = "Detox (mouseover)" },
        { slot = 61, key = "Shift-1", macro = { name = "OB Cocoon", spells = { 116849 }, mouseover = true }, note = "Life Cocoon (mouseover)" },
        { slot = 62, key = "Shift-2", spellId = 115310, alt = { 388615 }, note = "Revival / Restoral" },
        { slot = 66, key = "Shift-Q", spellId = 119381, note = "Leg Sweep" },
        { slot = 50, key = "Shift-E", spellId = 115078, note = "Paralysis" },
        { slot = 70, key = "F",       spellId = 116841, note = "Tiger's Lust: movement (Roll stays on your Meta-Q)" },
        { slot = 55, key = "`",       spellId = 115203, note = "Fortifying Brew: defensive" },
        { slot = 56, key = "Shift-`", spellId = 122783, alt = { 122278 }, note = "Diffuse Magic / Dampen Harm" },

        -- raid: heal casts (top players: Vivify 15, Renewing Mist 12, Enveloping Mist 7.5 a minute)
        { slot = 2,  key = "2",       content = "raid", macro = { name = "OB Vivify", spells = { 116670 }, mouseover = true },
          note = "Vivify (mouseover): most pressed, after every kick" },
        { slot = 3,  key = "3",       content = "raid", macro = { name = "OB ReM", spells = { 115151 }, mouseover = true },
          note = "Renewing Mist (mouseover): on cooldown" },
        { slot = 4,  key = "4",       content = "raid", macro = { name = "OB EnvM", spells = { 124682 }, mouseover = true },
          note = "Enveloping Mist (mouseover): procs, Yu'lon ramp" },
        { slot = 8,  key = "E",       content = "raid", macro = { name = "OB Soothing", spells = { 115175 }, mouseover = true },
          note = "Soothing Mist (mouseover): while moving" },
        { slot = 67, key = "R",       content = "raid", spellId = 115294, note = "Mana Tea: when there's time" },
        { slot = 63, key = "Shift-3", content = "raid", macro = { name = "OB Sheilun", spells = { 399491 }, mouseover = true },
          note = "Sheilun's Gift (mouseover): spot-heal raid build only" },

        -- M+ / delves: damage is the heal (Rising Sun Kick 16, Crane Kick 9, Tiger Palm 7, Blackout Kick 6 a minute)
        { slot = 2,  key = "2",       content = "dungeon", spellId = 101546, note = "Spinning Crane Kick: packs" },
        { slot = 3,  key = "3",       content = "dungeon", spellId = 100780, note = "Tiger Palm: builds Teachings" },
        { slot = 4,  key = "4",       content = "dungeon", spellId = 100784, note = "Blackout Kick: resets Rising Sun Kick" },
        { slot = 8,  key = "E",       content = "dungeon", macro = { name = "OB EnvM", spells = { 124682 }, mouseover = true },
          note = "Enveloping Mist (mouseover): before damage" },
        { slot = 67, key = "R",       content = "dungeon", macro = { name = "OB Sheilun", spells = { 399491 }, mouseover = true },
          note = "Sheilun's Gift (mouseover): sudden damage" },
        { slot = 63, key = "Shift-3", content = "dungeon", spellId = 115294, note = "Mana Tea" },
        { slot = 64, key = "Shift-4", content = "dungeon", macro = { name = "OB ReM", spells = { 115151 }, mouseover = true },
          note = "Renewing Mist (mouseover): ~1 a minute" },
        { slot = 65, key = "Shift-5", content = "dungeon", macro = { name = "OB Soothing", spells = { 115175 }, mouseover = true },
          note = "Soothing Mist (mouseover)" },
    },

    -- The movable cheat sheet (/ob sheet). Raid: Way of the Crane + Method,
    -- checked against the top 40 heroic parses per boss. M+: Way of the
    -- Crane + Method, checked against the top 40 timed runs per dungeon.
    rotationSheet = {
        { title = "Pull", content = "raid", lines = {
            { spellId = 467307, alt = { 107428 }, text = "Rushing Wind Kick and Renewing Mist in the first seconds (87% / 83% of top players)" },
            { spellId = 116680, text = "Thunder Focus Tea on that Renewing Mist (about half do it in the first 5s)" },
        } },
        { title = "Raid: always", content = "raid", lines = {
            { spellId = 467307, alt = { 107428 }, text = "Rushing Wind Kick on cooldown (top players: every ~4s), extends your HoTs" },
            { spellId = 116670, text = "Vivify after it (55% of top kicks): instant from Vivacious Vivification" },
            { spellId = 115151, text = "Renewing Mist on cooldown, never sit on max charges" },
            { spellId = 116680, text = "Thunder Focus Tea on Renewing Mist (80% of top Teas): haste, Heart of the Jade Serpent" },
            { spellId = 124682, text = "Enveloping Mist on a Strength of the Black Ox or Spiritfont proc" },
            { spellId = 115294, text = "Mana Tea whenever there's time; don't sit at 20 stacks" },
        } },
        { title = "Raid: ramp", content = "raid", lines = {
            { spellId = 322118, alt = { 325197 }, text = "Yu'lon (2 min): Enveloping Mist on 2-3 players, ~6 in its 25s" },
            { spellId = 443028, text = "Celestial Conduit on cooldown (90s), then alternate kick and Renewing Mist" },
            { spellId = 116670, text = "Vivify to finish: heals everyone with Renewing Mist (6+ targets)" },
            { spellId = 115175, text = "Soothing Mist only while moving: Vivify / Enveloping Mist go instant" },
        } },
        { title = "M+: always", content = "dungeon", lines = {
            { spellId = 107428, alt = { 467307 }, text = "Rising Sun Kick on cooldown (~16 a minute): your heal is Ancient Teachings" },
            { spellId = 101546, text = "Packs: Spinning Crane Kick (Way of the Crane), ~9 a minute" },
            { spellId = 100780, text = "Tiger Palm / Blackout Kick between: Teachings stacks reset Rising Sun Kick" },
            { spellId = 116680, text = "Thunder Focus Tea on Rising Sun Kick (84% of top Teas)" },
            { spellId = 399491, text = "Sheilun's Gift: cast heal for sudden damage (~2.4 a minute)" },
            { text = "Vivify and Renewing Mist barely get pressed in top runs" },
        } },
        { title = "M+: damage coming", content = "dungeon", lines = {
            { spellId = 124682, text = "Enveloping Mist on 2-3 squishies first, then Rising Sun Kick" },
            { spellId = 325197, text = "Chi-Ji: Blackout Kick on the stacks, Rising Sun Kick on resets (3 in 12s)" },
            { spellId = 443028, alt = { 115310 }, text = "4+ injured: Conduit or Revival (held for damage, ~2 min apart)" },
            { text = "Stats in M+: Haste > Mastery > Crit >= Vers (raid: Haste > Crit > Vers >= Mastery)" },
        } },
        { title = "Cooldowns", lines = {
            { spellId = 116849, text = "Life Cocoon: stop a death on a DPS / healer (absorb, no damage reduction)" },
            { spellId = 115310, alt = { 388615 }, text = "Revival: raid dispel or top-off before a mechanic; Restoral if you can't dispel" },
        } },
    },

    -- Stats: Way of the Crane, checked against the ratings the top players
    -- actually wear (Warcraft Logs, ~190 raid parses and ~180 M+ runs).
    -- Raid: Haste > Crit > Vers >= Mastery (median 1600 / 1020 / 340 / 260;
    -- Haste first for 95%, Crit second for 92%). M+: Haste > Mastery > Crit
    -- >= Vers (1320 / 940 / 530 / 370; Mastery second for 61%). Method's
    -- one list for both (Haste > Crit = Vers > Mastery) fits neither.
    -- Statisfaction shows the one for the content you're in (/ob mode).
    statPriority = { HASTE = 1, CRIT = 2, VERS = 3, MASTERY = 3.5 },
    contentStatPriorities = {
        raid    = { HASTE = 1, CRIT = 2, VERS = 3, MASTERY = 3.5 },
        dungeon = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 3.5 },
    },

    keyLayoutLabels = { st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 116670,  st = 1, aoe = 1, note = "Most pressed (~15 a minute); group heal with Renewing Mist out" },
        { spellId = 467307,  st = 1, aoe = 1, note = "Raid: on cooldown (~15 a minute)" },
        { spellId = 115151,  st = 1, aoe = 1, note = "On cooldown (~12 a minute)" },
        { spellId = 124682,  st = 1, aoe = 1, note = "Black Ox / Spiritfont procs, Yu'lon ramp" },
        { spellId = 116680,  st = 2, aoe = 1, note = "On Renewing Mist" },
        { spellId = 115294,  st = 2, aoe = 2, note = "When there's time, not at 20 stacks" },
        { spellId = 115175,  st = 2, aoe = 2, note = "While moving" },
        { spellId = 399491,  st = 2, aoe = 2, note = "M+ cast heal, ~2.4 a minute" },
        { spellId = 115450,  st = 2, aoe = 2, note = "Dispel" },
        { spellId = 107428,  st = 1, aoe = 1, note = "M+: on cooldown, ~16 a minute" },
        { spellId = 101546,           aoe = 1, note = "M+ packs, ~9 a minute" },
        { spellId = 100780,  st = 1, aoe = 2, note = "M+: ~7 a minute, builds Teachings" },
        { spellId = 100784,  st = 1, aoe = 2, note = "M+: ~6 a minute, resets Rising Sun Kick" },
        { spellId = 116849,  st = 3,          note = "Save a DPS or healer" },
        { spellId = 322118,           aoe = 3, note = "Raid: 2 min ramp" },
        { spellId = 325197,           aoe = 3, note = "M+: ~80s apart, into damage" },
        { spellId = 443028,           aoe = 3, note = "On cooldown (90s)" },
        { spellId = 115310,           aoe = 3, alt = { 388615 }, note = "Raid dispel / top-off" },
        { spellId = 115203,  st = 3, aoe = 3, note = "Defensive" },
    },
})
