local OffBeat = _G.OffBeat

-- Frost Mage, Method 12.1.5 (16 Oct 2026), checked against the top 40
-- heroic parses on every Venomous Abyss boss (360) and the top 40 timed
-- runs per Season 2 dungeon (319 runs; Warcraft Logs, Oct 2026).
--
-- The hero tree splits by fight: Spellslinger (Frostbolt) on single-target
-- bosses (256 of 360 parses), Frostfire (Frostfire Bolt) on The Twin Fangs
-- and The Lost Explorers, half of Nymrissa, and 74% of M+ runs. Frostfire
-- in raid mostly skips Ray of Frost and Comet Storm (3 in 4 cast neither);
-- Frostfire in M+ takes both. The sheet switches on Frostfire Bolt.
--
-- Frozen Orb every ~26s in raid (Spellfrost Teachings) and Ray of Frost
-- every ~26-40s, both on cooldown; Ice Lance is the most pressed spell
-- (~24 a minute on single-target bosses). Icy Veins isn't pressed by
-- anyone.
OffBeat:RegisterProfile({
    meta = {
        name = "Frost Mage",
        specId = 64,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Pressed by the top players (Frostbolt or Frostfire Bolt by hero tree,
    -- Comet Storm and Blizzard mostly in M+). Blizzard is logged as 190356
    -- and 1248829 (Freezing Rain); both count.
    rotationSpells = {
        { spellId = 30455 },   -- Ice Lance
        { spellId = 44614 },   -- Flurry
        { spellId = 84714 },   -- Frozen Orb
        { spellId = 199786 },  -- Glacial Spike
        { spellId = 205021 },  -- Ray of Frost
        { spellId = 116 },     -- Frostbolt
        { spellId = 431044 },  -- Frostfire Bolt
        { spellId = 153595 },  -- Comet Storm
        { spellId = 190356 },  -- Blizzard
        { spellId = 1248829 }, -- Blizzard (Freezing Rain)
    },

    -- No mistake rules: the priority runs on Freezing stacks, Fingers of
    -- Frost and Brain Freeze, which the game hides in combat, and Method's
    -- "Comet Storm right after Glacial Spike" isn't what the top Frostfire
    -- players do (4-15% of their Comet Storms).

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through.
    trackedAuras = {
        { spellId = 44544,   name = "Fingers of Frost",      baseDuration = 15, stacks = true },
        { spellId = 190446,  name = "Brain Freeze",          baseDuration = 15, stacks = false },
        { spellId = 1247730, name = "Thermal Void",          baseDuration = 0,  stacks = false },
        { spellId = 1222865, name = "Glacial Spike!",        baseDuration = 0,  stacks = false },
        { spellId = 431177,  name = "Frostfire Empowerment", baseDuration = 0,  stacks = false },
        { spellId = 1247908, name = "Splinterstorm",         baseDuration = 0,  stacks = false },
    },

    keyCooldown = {
        spellId = 205021,
        name = "Ray of Frost",
        duration = 4,
    },

    failNudges = {
        { error = "moving", spells = { 116, 431044, 199786, 205021 }, name = "Cast while moving",
          text = "Moving: Ice Lance, Flurry, Frozen Orb; Frostfire Bolt on Frostfire Empowerment" },
    },
    movingCasts = { { spellId = 431044, name = "Frostfire Bolt" } },

    -- On cooldown for every top player: Frozen Orb every ~26s (raid) and
    -- Ray of Frost; Comet Storm every ~43-54s when you have it (Frostfire,
    -- M+). Idle alerts skip spells you haven't talented.
    idleCooldowns = {
        { spellId = 84714,  name = "Frozen Orb" },
        { spellId = 205021, name = "Ray of Frost" },
        { spellId = 153595, name = "Comet Storm" },
    },

    -- Coaching: Frozen Orb (10s). It hands out Fingers of Frost and
    -- Freezing; the top players spend them on 4-5 Ice Lances in raid
    -- (Spellslinger 5, Frostfire 3) and 3 in M+.
    windows = {
        {
            name = "Frozen Orb (raid)",
            trigger = 84714,
            duration = 10,
            content = "raid",
            note = "Spend what the Orb gives you: Ice Lance on Fingers of Frost and 6+ Freezing "
                .. "(12+ for Frostfire), Flurry on Brain Freeze. Top players: 4 Ice Lances.",
            goals = {
                { name = "Ice Lance", spells = { 30455 }, min = 4 },
            },
        },
        {
            name = "Frozen Orb (M+)",
            trigger = 84714,
            duration = 10,
            content = "dungeon",
            note = "Into a pack after Glacial Spike / Comet Storm: Ice Lance on Fingers of Frost, "
                .. "Flurry on Brain Freeze. Top players: 3 Ice Lances.",
            goals = {
                { name = "Ice Lance", spells = { 30455 }, min = 3 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Ice Lances per Frozen Orb.
    -- Dungeons (by instance ID): the top 40 timed runs, per minute in combat
    -- (Warcraft Logs' pulls). The filler is Frostbolt or Frostfire Bolt;
    -- Frostfire bosses (Twin Fangs, Lost Explorers) and M+ have more of it
    -- and fewer Ice Lances.
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts", all = true },
            { name = "Ice Lance",      spells = { 30455 } },
            { name = "Flurry",         spells = { 44614 } },
            { name = "Glacial Spike",  spells = { 199786 } },
            { name = "Frostbolt / Frostfire Bolt", spells = { 116, 431044 } },
            { name = "Frozen Orb",     spells = { 84714 } },
            { name = "Ray of Frost / Comet Storm", spells = { 205021, 153595 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 4, values = {
                { 37.6, 38.7, 40.1 }, { 19.0, 20.2, 21.6 }, { 6.1, 6.5, 6.9 }, { 3.8, 4.1, 4.3 }, { 3.5, 4.3, 5.1 }, { 1.6, 1.7, 1.8 }, { 1.4, 1.5, 1.5 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 5, values = {
                { 45.9, 47.0, 47.6 }, { 25.7, 26.9, 27.7 }, { 6.9, 7.5, 8.1 }, { 4.2, 4.4, 4.7 }, { 3.5, 4.1, 5.0 }, { 2.1, 2.2, 2.3 }, { 1.7, 1.7, 1.8 } } },
            [3445] = { name = "Entombed Sentinels", window = 4, values = {
                { 43.8, 44.9, 46.8 }, { 23.1, 24.1, 25.3 }, { 6.9, 7.5, 8.1 }, { 4.4, 4.8, 5.1 }, { 3.6, 4.3, 5.4 }, { 2.0, 2.1, 2.2 }, { 1.8, 1.9, 2.0 } } },
            [3455] = { name = "Vashnik the Malignant", window = 5, values = {
                { 46.1, 47.1, 48.0 }, { 25.4, 26.6, 27.8 }, { 6.8, 7.3, 7.8 }, { 4.1, 4.5, 4.6 }, { 4.0, 4.8, 5.8 }, { 1.9, 2.1, 2.3 }, { 1.7, 1.7, 1.9 } } },
            [3497] = { name = "The Lost Explorers", window = 4, values = {
                { 49.9, 52.0, 53.3 }, { 18.8, 19.7, 21.3 }, { 8.6, 10.0, 11.1 }, { 5.4, 6.0, 6.4 }, { 9.8, 14.6, 16.2 }, { 1.0, 1.1, 1.3 }, nil } },
            [3420] = { name = "Sszorak", window = 5, values = {
                { 45.4, 46.8, 47.8 }, { 24.4, 26.1, 27.1 }, { 7.0, 7.6, 8.0 }, { 4.2, 4.6, 4.8 }, { 4.1, 4.6, 5.5 }, { 2.1, 2.2, 2.3 }, { 1.6, 1.8, 1.8 } } },
            [3421] = { name = "The Twin Fangs", window = 4, values = {
                { 50.0, 51.2, 53.3 }, { 18.6, 19.7, 20.2 }, { 9.5, 10.4, 10.6 }, { 5.8, 6.1, 6.4 }, { 13.6, 14.7, 15.8 }, { 1.0, 1.1, 1.1 }, nil } },
            [3429] = { name = "The Coiled Altar", window = 5, values = {
                { 43.3, 44.4, 45.6 }, { 23.8, 25.6, 26.3 }, { 6.4, 7.1, 7.6 }, { 4.5, 4.8, 5.1 }, { 2.6, 3.5, 4.7 }, { 2.0, 2.1, 2.2 }, { 1.6, 1.7, 1.8 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 4, values = {
                { 43.2, 44.6, 45.5 }, { 14.3, 21.8, 24.5 }, { 7.1, 7.9, 8.3 }, { 4.1, 4.6, 5.1 }, { 5.1, 6.1, 12.9 }, { 1.1, 1.7, 1.9 }, { 1.7, 1.9, 2.4 } } },
        },
        overall = { name = "all heroic bosses", window = 4, values = {
            { 43.7, 46.1, 48.5 }, { 20.0, 23.6, 26.3 }, { 6.8, 7.6, 8.5 }, { 4.2, 4.7, 5.3 }, { 3.7, 4.9, 11.9 }, { 1.2, 2.0, 2.2 }, { 1.4, 1.7, 1.8 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 3, values = {
                { 38.6, 40.9, 42.2 }, { 13.6, 14.3, 21.5 }, { 6.1, 7.3, 7.8 }, { 3.8, 4.7, 4.9 }, { 3.7, 10.9, 12.3 }, { 1.0, 1.2, 1.7 }, { 1.5, 2.0, 2.3 } } },
            [2825] = { name = "Den of Nalorakk", window = 3, values = {
                { 39.4, 40.2, 41.9 }, { 13.2, 14.1, 15.2 }, { 6.8, 7.4, 7.9 }, { 4.4, 4.6, 4.8 }, { 9.7, 10.9, 11.9 }, { 0.9, 1.0, 1.3 }, { 2.0, 2.2, 2.3 } } },
            [1762] = { name = "Kings' Rest", window = 3, values = {
                { 39.9, 41.2, 43.1 }, { 13.6, 14.7, 16.1 }, { 6.9, 7.4, 8.1 }, { 4.5, 4.7, 5.0 }, { 9.9, 11.0, 11.9 }, { 1.0, 1.1, 1.4 }, { 2.0, 2.2, 2.3 } } },
            [2813] = { name = "Murder Row", window = 3, values = {
                { 40.1, 41.7, 43.5 }, { 13.6, 14.6, 21.5 }, { 6.5, 7.5, 7.9 }, { 4.2, 4.8, 5.1 }, { 4.2, 11.0, 12.4 }, { 0.9, 1.3, 1.7 }, { 1.6, 2.3, 2.4 } } },
            [2521] = { name = "Ruby Life Pools", window = 3, values = {
                { 39.5, 42.1, 43.8 }, { 14.0, 15.0, 17.1 }, { 6.2, 7.2, 7.9 }, { 4.4, 5.0, 5.5 }, { 3.8, 11.0, 12.2 }, { 1.0, 1.3, 1.5 }, { 1.6, 2.3, 2.4 } } },
            [1877] = { name = "Temple of Sethraliss", window = 3, values = {
                { 37.1, 39.3, 41.7 }, { 12.2, 13.5, 16.2 }, { 5.9, 6.9, 7.8 }, { 4.0, 4.5, 4.9 }, { 3.7, 10.7, 12.3 }, { 0.9, 1.1, 1.4 }, { 1.4, 2.1, 2.2 } } },
            [2859] = { name = "The Blinding Vale", window = 3, values = {
                { 39.7, 42.2, 43.4 }, { 13.1, 14.3, 16.8 }, { 6.1, 7.4, 8.0 }, { 3.5, 4.8, 5.0 }, { 3.3, 11.5, 12.4 }, { 0.9, 1.3, 1.4 }, { 1.5, 2.2, 2.3 } } },
            [2923] = { name = "Voidscar Arena", window = 3, values = {
                { 40.0, 42.5, 44.0 }, { 13.7, 14.7, 16.7 }, { 6.6, 7.6, 7.8 }, { 4.1, 4.7, 5.0 }, { 3.6, 11.5, 12.3 }, { 1.0, 1.2, 1.4 }, { 1.5, 2.1, 2.3 } } },
        },
        -- Dummies with /ob mode mythic: all 319 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 3, values = {
            { 39.3, 41.1, 43.0 }, { 13.3, 14.4, 17.2 }, { 6.3, 7.4, 7.9 }, { 4.2, 4.7, 5.0 }, { 3.9, 11.0, 12.2 }, { 0.9, 1.2, 1.4 }, { 1.5, 2.2, 2.3 } } },
    },

    -- /ob bars: role for role on the keys your other specs use (binds are
    -- account-wide): Ice Lance (most pressed) on 1, Flurry on 2, the filler
    -- on 3 (Frostbolt, or Frostfire Bolt which replaces it), Glacial Spike
    -- on 4, Ray of Frost on Q, Frozen Orb (every ~26s) on G, Comet Storm on
    -- Shift-1, Blizzard at the cursor on E. Interrupt Shift-E, knockback
    -- Shift-Q, defensives on ` / Shift-`, Shimmer on F. Time Warp sits on
    -- F5, out of the way so you don't press it by accident. One layout for
    -- both hero trees, raid and M+. Polymorph, Arcane Intellect and
    -- anything not listed are left alone.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 30455,  note = "Ice Lance: Fingers of Frost and Freezing stacks, your most pressed spell" },
        { slot = 2,  key = "2",       spellId = 44614,  note = "Flurry: on Brain Freeze (Thermal Void down), builds Freezing" },
        { slot = 3,  key = "3",       spellId = 116,    note = "Frostbolt / Frostfire Bolt: filler" },
        { slot = 4,  key = "4",       spellId = 199786, note = "Glacial Spike: whenever it's ready" },
        { slot = 6,  key = "Q",       spellId = 205021, note = "Ray of Frost: on cooldown, after your Flurries and Ice Lances" },
        { slot = 7,  key = "G",       spellId = 84714,  note = "Frozen Orb: on cooldown (~26s in raid)" },
        { slot = 61, key = "Shift-1", spellId = 153595, note = "Comet Storm (Frostfire): right after Glacial Spike, every pack in M+" },
        { slot = 8,  key = "E",       macro = { name = "OB Blizzard", spells = { 190356 }, cursor = true },
          note = "Blizzard at your cursor: Freezing Rain in M+ (Spellslinger)" },
        { slot = 67, key = "R",       spellId = 55342,  note = "Mirror Image: on cooldown in M+ (81% of top runs)" },
        { slot = 62, key = "Shift-2", spellId = 342245, note = "Alter Time: press again to go back (90% of top M+ runs)" },
        { slot = 63, key = "Shift-3", spellId = 31661,  note = "Dragon's Breath: disorient a pack (M+)" },
        { slot = 64, key = "Shift-4", spellId = 122,    note = "Frost Nova: root a pack (M+)" },
        { slot = 65, key = "Shift-5", spellId = 30449,  note = "Spellsteal: an enemy buff (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 157980, note = "Supernova: knock a pack up (M+)" },
        { slot = 50, key = "Shift-E", spellId = 2139,   note = "Counterspell: interrupt" },
        { slot = 12, key = "X",       macro = { name = "OB RemoveCurse", spells = { 475 }, mouseover = true },
          note = "Remove Curse (mouseover): curses" },
        { slot = 70, key = "F",       spellId = 212653, alt = { 1953 }, note = "Shimmer / Blink: movement, you keep casting" },
        { slot = 71, key = "Shift-F", spellId = 110959, note = "Greater Invisibility: drops threat, less damage taken (87% of top M+ runs)" },
        { slot = 25, key = "F5",      spellId = 80353,  note = "Time Warp: out of the way on purpose" },
        { slot = 55, key = "`",       spellId = 414658, alt = { 45438 }, note = "Ice Cold (Ice Block): long defensive, you keep casting" },
        { slot = 56, key = "Shift-`", spellId = 11426,  note = "Ice Barrier: on cooldown in M+ (~1.9 a minute)" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5, one priority per
    -- hero tree (Frostfire when you know Frostfire Bolt).
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 116,    alt = { 431044 }, text = "Precast Frostbolt, potion and trinket" },
            { spellId = 205021, text = "Ray of Frost, then the priority" },
        } },
        { title = "Spellslinger", unknown = { 431044 }, lines = {
            { spellId = 190356, text = "AoE: Blizzard on Freezing Rain first" },
            { spellId = 44614,  text = "Flurry on Brain Freeze with Thermal Void down" },
            { spellId = 30455,  text = "Ice Lance at 2 Fingers of Frost" },
            { spellId = 84714,  text = "Frozen Orb, then Glacial Spike" },
            { spellId = 30455,  text = "Ice Lance at 6+ Freezing or with Fingers of Frost" },
            { spellId = 44614,  text = "Flurry, then Ray of Frost" },
            { spellId = 116,    text = "Frostbolt" },
        } },
        { title = "Frostfire", known = { 431044 }, lines = {
            { spellId = 199786, text = "Glacial Spike, then Comet Storm" },
            { spellId = 44614,  text = "Flurry on Brain Freeze with Thermal Void down" },
            { spellId = 30455,  text = "Ice Lance at 2 Fingers of Frost" },
            { spellId = 84714,  text = "Frozen Orb" },
            { spellId = 30455,  text = "Ice Lance: Fingers of Frost with Thermal Void, or 12+ Freezing" },
            { spellId = 205021, text = "AoE: Ray of Frost without Frostfire Empowerment" },
            { spellId = 44614,  text = "Flurry, then Frostfire Bolt" },
        } },
        { title = "Loop", lines = {
            { text = "Cooldowns first (Frozen Orb, Glacial Spike; Blizzard in AoE)" },
            { text = "Then spend Freezing with Ice Lance, rebuild it with Flurry, the filler and Ray of Frost" },
            { text = "Which tree: Spellslinger on single-target bosses, Frostfire on cleave bosses and in M+" },
        } },
    },

    -- Stats: Method: Mastery = Crit > Haste > Versatility.
    statPriority = { MASTERY = 1, CRIT = 1, HASTE = 3, VERS = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 30455,  st = 1, aoe = 1, note = "Most pressed" },
        { spellId = 44614,  st = 1, aoe = 1, note = "Brain Freeze" },
        { spellId = 116,    st = 1, aoe = 1, alt = { 431044 }, note = "Filler" },
        { spellId = 199786, st = 1, aoe = 1, note = "On cooldown" },
        { spellId = 84714,  st = 2, aoe = 2, note = "Every ~26s" },
        { spellId = 205021, st = 2, aoe = 2, note = "On cooldown" },
        { spellId = 153595, st = 2, aoe = 2, note = "Frostfire, after Glacial Spike" },
        { spellId = 190356,          aoe = 2, alt = { 1248829 }, note = "Freezing Rain" },
        { spellId = 212653, st = 3, aoe = 3, alt = { 1953 }, note = "Movement" },
        { spellId = 2139,   st = 2, aoe = 2, note = "Interrupt" },
    },
})
