local OffBeat = _G.OffBeat

-- Mistweaver Monk, Way of the Crane (Megasett, 12.1) and Method 12.1.5
-- (14 Oct 2026), checked against the top 40 heroic parses (by healing) on
-- every Venomous Abyss boss (Warcraft Logs, Oct 2026). All 360 of them
-- play Conduit of the Celestials (Method: best in all content) and 94%
-- take Invoke Yu'lon, so this is a Conduit / Yu'lon raid profile. The cheat
-- sheet has an M+ section from Way of the Crane (Megasett plays mostly M+).
--
-- Healing is reactive, so there are no mistake rules. Even Thunder Focus
-- Tea on Renewing Mist, which both guides ask for, is only 80% of the top
-- players' Teas (a tenth of them use it on Renewing Mist under a third of
-- the time). What's here is what they all do the same way: Rushing Wind
-- Kick on cooldown, Renewing Mist kept rolling, the Yu'lon ramp, and
-- casts per minute to compare against.
OffBeat:RegisterProfile({
    meta = {
        name = "Mistweaver Monk",
        specId = 270,
        version = 1,
        author = "OffBeat Defaults",
        source = "Way of the Crane 12.1 + Method 12.1.5 + top 40 heroic parses per boss (Oct 2026)",
    },

    -- Raid: pressed by 64%+ of the top players (Soothing Mist is the
    -- lowest). Chi-Ji, Restoral, Sheilun's Gift and the damage buttons are
    -- in for M+ and the builds that take them (Restoral: 33%, Chi-Ji: 6%).
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
    -- (median gap; 10s cooldown, reset by Rising Mist), Celestial Conduit
    -- every ~96s (90s cooldown), Yu'lon every ~127s (2 min). Renewing Mist
    -- and Thunder Focus Tea have charges (they'd nag at one charge); Life
    -- Cocoon and Revival are held for damage.
    idleCooldowns = {
        { spellId = 467307, name = "Rushing Wind Kick" },
        { spellId = 443028, name = "Celestial Conduit" },
        { spellId = 322118, name = "Invoke Yu'lon" },
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
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Enveloping Mists per Yu'lon.
    benchmarks = {
        source = "top 40 heroic parses per boss (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",     all = true },
            { name = "Vivify",             spells = { 116670 } },
            { name = "Rushing Wind Kick",  spells = { 467307, 107428 } },
            { name = "Renewing Mist",      spells = { 115151 } },
            { name = "Enveloping Mist",    spells = { 124682 } },
            { name = "Thunder Focus Tea",  spells = { 116680 } },
            { name = "Mana Tea",           spells = { 115294 } },
            { name = "Celestial Conduit",  spells = { 443028 } },
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
    },

    -- The movable cheat sheet (/ob sheet). Raid: Way of the Crane + Method,
    -- checked against the top 40 heroic parses per boss. M+: Way of the
    -- Crane.
    rotationSheet = {
        { title = "Pull", lines = {
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
        { title = "M+ (Way of the Crane)", content = "dungeon", lines = {
            { spellId = 107428, alt = { 467307 }, text = "DPS heals: Rising Sun Kick on cooldown (Ancient Teachings)" },
            { spellId = 101546, text = "Many enemies: Spinning Crane Kick (Way of the Crane)" },
            { spellId = 399491, text = "Sheilun's Gift: main cast heal, first answer to sudden damage" },
            { spellId = 116680, text = "Thunder Focus Tea: hold for 3-4 Rising Sun Kicks in a row, or force Spiritfont" },
            { spellId = 124682, text = "Before big damage: Enveloping Mist on 2-3 squishies, then Rising Sun Kick" },
            { spellId = 443028, alt = { 325197, 115310 }, text = "4+ injured with damage coming: Conduit, Chi-Ji or Revival" },
        } },
        { title = "Cooldowns", lines = {
            { spellId = 116849, text = "Life Cocoon: stop a death on a DPS / healer (absorb, no damage reduction)" },
            { spellId = 115310, alt = { 388615 }, text = "Revival: raid dispel or top-off before a mechanic; Restoral if you can't dispel" },
        } },
    },

    -- Way of the Crane raid: Haste > Crit > Vers > Mastery
    statPriority = { HASTE = 1, CRIT = 2, VERS = 3, MASTERY = 4 },

    keyLayoutLabels = { st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 116670,  st = 1, aoe = 1, note = "Most pressed (~15 a minute); group heal with Renewing Mist out" },
        { spellId = 467307,  st = 1, aoe = 1, alt = { 107428 }, note = "On cooldown (~15 a minute)" },
        { spellId = 115151,  st = 1, aoe = 1, note = "On cooldown (~12 a minute)" },
        { spellId = 124682,  st = 1, aoe = 1, note = "Black Ox / Spiritfont procs, Yu'lon ramp" },
        { spellId = 116680,  st = 2, aoe = 1, note = "On Renewing Mist" },
        { spellId = 115294,  st = 2, aoe = 2, note = "When there's time, not at 20 stacks" },
        { spellId = 115175,  st = 2, aoe = 2, note = "While moving" },
        { spellId = 399491,  st = 2, aoe = 2, note = "M+ main cast heal" },
        { spellId = 115450,  st = 2, aoe = 2, note = "Dispel" },
        { spellId = 100780,  st = 2, aoe = 2, note = "M+ damage (Ancient Teachings)" },
        { spellId = 100784,  st = 2, aoe = 2, note = "M+ damage, resets Rising Sun Kick" },
        { spellId = 101546,           aoe = 2, note = "M+ packs (Way of the Crane)" },
        { spellId = 116849,  st = 3,          note = "Save a DPS or healer" },
        { spellId = 322118,           aoe = 3, alt = { 325197 }, note = "2 min ramp" },
        { spellId = 443028,           aoe = 3, note = "On cooldown (90s)" },
        { spellId = 115310,           aoe = 3, alt = { 388615 }, note = "Raid dispel / top-off" },
        { spellId = 115203,  st = 3, aoe = 3, note = "Defensive" },
    },
})
