local OffBeat = _G.OffBeat

-- Restoration Shaman, Method 12.1.5 (16 Oct 2026), checked against the
-- top 40 heroic parses (by healing) on every Venomous Abyss boss (360) and
-- the top 40 timed runs per Season 2 dungeon (+23 / +24, 320 runs; Warcraft
-- Logs, Oct 2026).
--
-- Every top player is Totemic, as Method recommends: Surging Totem every
-- ~27s, Healing Stream Totem every ~17s (Stormstream Totem shows up on its
-- button, ~44% of the time right after Nature's Swiftness), Riptide on
-- every charge. Farseer is 1 parse in 680 (Ancestral Swiftness, Healing
-- Rain); the bars and sheet take either tree's spell on the same key.
-- Healing Surge isn't pressed by anyone; Healing Wave still is (82% of raid
-- parses, every M+ run).
--
-- Raid and M+ differ: raid is Chain Heal (~19 a minute) with Ascendance
-- (every ~3 min); M+ takes Healing Tide Totem instead of Ascendance (98%
-- of runs), adds Unleash Life (~every 26s) and Earth Shield, and does
-- damage (Lava Burst, Flame Shock, Chain Lightning: ~7.6 a minute). The
-- content mode (/ob mode, auto by instance) picks the bars, sheet sections,
-- idle alerts, the cooldown window and dummy numbers.
--
-- Healing is reactive, so there are no mistake rules.
OffBeat:RegisterProfile({
    meta = {
        name = "Restoration Shaman",
        specId = 264,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Raid: pressed by 80%+ of the top players (Healing Wave 82%). M+: all
    -- of these by 87%+ of them (Unleash Life lowest). Flame Shock is logged
    -- twice per cast (188389 and 470411); only 188389 is counted.
    rotationSpells = {
        { spellId = 61295 },   -- Riptide
        { spellId = 1064 },    -- Chain Heal
        { spellId = 77472 },   -- Healing Wave
        { spellId = 5394 },    -- Healing Stream Totem
        { spellId = 1267068 }, -- Stormstream Totem (on Healing Stream Totem's button)
        { spellId = 444995 },  -- Surging Totem (Totemic; replaces Healing Rain)
        { spellId = 73920 },   -- Healing Rain (Farseer)
        { spellId = 378081 },  -- Nature's Swiftness
        { spellId = 443454 },  -- Ancestral Swiftness (Farseer)
        { spellId = 73685 },   -- Unleash Life (M+)
        { spellId = 114052 },  -- Ascendance (raid)
        { spellId = 108280 },  -- Healing Tide Totem (M+)
        { spellId = 98008 },   -- Spirit Link Totem
        { spellId = 51505 },   -- Lava Burst
        { spellId = 188389 },  -- Flame Shock
        { spellId = 188443 },  -- Chain Lightning
        { spellId = 188196 },  -- Lightning Bolt
    },

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through.
    trackedAuras = {
        { spellId = 53390,   name = "Tidal Waves",         baseDuration = 15, stacks = true },
        { spellId = 378081,  name = "Nature's Swiftness",  baseDuration = 0,  stacks = false },
        { spellId = 114052,  name = "Ascendance",          baseDuration = 15, stacks = false },
        { spellId = 77762,   name = "Lava Surge",          baseDuration = 10, stacks = false },
        { spellId = 1307888, name = "Healing Rain",        baseDuration = 24, stacks = false },
        { spellId = 453407,  name = "Whirling Water",      baseDuration = 0,  stacks = false },
    },

    keyCooldown = {
        spellId = 114052,
        name = "Ascendance",
        duration = 15,
    },

    -- Chain Heal and Healing Wave have cast times (Spiritwalker's Grace in
    -- 83% of top raid kills).
    failNudges = {
        { error = "moving", spells = { 1064, 77472 }, name = "Cast while moving",
          text = "Moving: Riptide, Healing Stream / Surging Totem, Unleash Life, or Spiritwalker's Grace" },
    },
    movingCasts = {
        { spellId = 61295, name = "Riptide" },
        { spellId = 51505, name = "Lava Burst" },
    },

    -- On cooldown for the top players: Surging Totem every ~27s (Method:
    -- keep it up, it is your Healing Rain), Nature's Swiftness every ~64s,
    -- Unleash Life every ~26s in M+. Riptide and Healing Stream Totem have
    -- charges (they'd nag at one charge); Ascendance, Healing Tide and Spirit
    -- Link are held for damage.
    idleCooldowns = {
        { spellId = 444995, name = "Surging Totem" },
        { spellId = 378081, name = "Nature's Swiftness" },
        { spellId = 443454, name = "Ancestral Swiftness" },
        { spellId = 73685,  name = "Unleash Life", content = "dungeon" },
    },

    -- Coaching. Raid: in the 15s of Ascendance the top players cast 7 Chain
    -- Heals (median; 6-8 by boss) and 3 Riptides. M+: in the 10s of Healing
    -- Tide Totem, 4 Chain Heals / Healing Waves and 2 Riptides.
    windows = {
        {
            name = "Ascendance (raid)",
            trigger = 114052,
            duration = 15,
            content = "raid",
            note = "Into raid damage (on assignment): Chain Heal through it, Riptide on every charge. "
                .. "Top players: 7 Chain Heals, 3 Riptides.",
            goals = {
                { name = "Chain Heal", spells = { 1064 }, min = 7 },
                { name = "Riptide", spells = { 61295 }, min = 3 },
            },
        },
        {
            name = "Healing Tide Totem (M+)",
            trigger = 108280,
            duration = 10,
            content = "dungeon",
            note = "Into group damage: keep casting while the totem ticks. Top players: 4 Chain Heals / "
                .. "Healing Waves, 2 Riptides.",
            goals = {
                { name = "Chain Heal / Healing Wave", spells = { 1064, 77472 }, min = 4 },
                { name = "Riptide", spells = { 61295 }, min = 2 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Chain Heals per Ascendance.
    -- Dungeons (by instance ID): the top 40 timed runs, per minute in combat
    -- (Warcraft Logs' pulls); window = median Chain Heals / Healing Waves per
    -- Healing Tide Totem. Raid has no number for Unleash Life (3 of 360 take
    -- it).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",       all = true },
            { name = "Chain Heal",           spells = { 1064 } },
            { name = "Riptide",              spells = { 61295 } },
            { name = "Healing Wave",         spells = { 77472 } },
            { name = "Healing Stream / Stormstream Totem", spells = { 5394, 1267068 } },
            { name = "Surging Totem / Healing Rain", spells = { 444995, 73920 } },
            { name = "Nature's / Ancestral Swiftness", spells = { 378081, 443454 } },
            { name = "Damage (Lava Burst, Flame Shock, Lightning)", spells = { 51505, 188389, 188196, 188443 } },
            { name = "Unleash Life",         spells = { 73685 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 8, values = {
                { 41.4, 42.6, 44.1 }, { 15.5, 17.6, 18.7 }, { 11.3, 11.6, 11.9 }, { 1.2, 3.1, 4.8 }, { 5.0, 5.1, 5.2 }, { 2.1, 2.1, 2.2 }, { 0.9, 0.9, 1.0 }, { 0.1, 1.0, 2.3 }, nil } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 7, values = {
                { 42.2, 43.8, 46.9 }, { 16.9, 19.1, 20.3 }, { 11.2, 11.7, 11.9 }, { 0.6, 1.6, 3.6 }, { 5.1, 5.2, 5.4 }, { 2.1, 2.2, 2.3 }, { 0.9, 1.0, 1.0 }, { 0.3, 1.5, 4.1 }, nil } },
            [3445] = { name = "Entombed Sentinels", window = 6, values = {
                { 41.0, 43.6, 45.3 }, { 16.0, 18.6, 19.7 }, { 11.0, 11.4, 11.8 }, { 0.7, 1.9, 4.0 }, { 5.0, 5.1, 5.4 }, { 2.1, 2.2, 2.3 }, { 0.9, 0.9, 1.0 }, { 0.6, 2.0, 3.5 }, nil } },
            [3455] = { name = "Vashnik the Malignant", window = 8, values = {
                { 43.4, 44.5, 46.9 }, { 19.1, 20.3, 21.8 }, { 11.0, 11.5, 11.6 }, { 0.4, 1.4, 2.4 }, { 5.1, 5.3, 5.4 }, { 2.1, 2.2, 2.3 }, { 0.9, 0.9, 1.0 }, { 0.6, 1.8, 3.0 }, nil } },
            [3497] = { name = "The Lost Explorers", window = 6.5, values = {
                { 41.1, 43.1, 45.9 }, { 18.6, 20.4, 21.9 }, { 10.6, 11.5, 11.8 }, { 0.0, 0.6, 1.9 }, { 5.0, 5.3, 5.5 }, { 2.1, 2.3, 2.4 }, { 0.9, 1.0, 1.1 }, { 0.0, 0.7, 2.0 }, nil } },
            [3420] = { name = "Sszorak", window = 7, values = {
                { 42.7, 44.7, 47.0 }, { 20.2, 21.5, 22.5 }, { 10.9, 11.4, 11.8 }, { 0.0, 1.0, 2.0 }, { 5.2, 5.3, 5.5 }, { 2.2, 2.3, 2.4 }, { 1.0, 1.0, 1.1 }, { 0.3, 0.8, 1.9 }, nil } },
            [3421] = { name = "The Twin Fangs", window = 7, values = {
                { 41.7, 44.0, 45.6 }, { 18.1, 19.9, 21.5 }, { 11.0, 11.6, 11.9 }, { 0.4, 1.4, 3.2 }, { 5.0, 5.2, 5.4 }, { 2.1, 2.2, 2.3 }, { 0.9, 1.0, 1.0 }, { 0.2, 0.9, 2.7 }, nil } },
            [3429] = { name = "The Coiled Altar", window = 8, values = {
                { 43.4, 44.3, 46.3 }, { 17.9, 19.2, 21.3 }, { 11.1, 11.5, 11.8 }, { 0.6, 1.6, 5.2 }, { 5.1, 5.3, 5.5 }, { 2.1, 2.3, 2.3 }, { 1.0, 1.0, 1.1 }, { 0.4, 0.9, 2.9 }, nil } },
            [3379] = { name = "Nymrissa Wavecaller", window = 7, values = {
                { 42.4, 44.7, 46.8 }, { 16.0, 17.6, 19.7 }, { 10.2, 11.0, 11.8 }, { 0.5, 1.9, 4.4 }, { 4.8, 5.1, 5.4 }, { 2.2, 2.3, 2.3 }, { 0.9, 1.0, 1.1 }, { 0.4, 3.3, 5.7 }, nil } },
        },
        overall = { name = "all heroic bosses", window = 7, values = {
            { 41.9, 43.9, 46.1 }, { 17.5, 19.3, 21.2 }, { 11.0, 11.5, 11.8 }, { 0.3, 1.5, 3.7 }, { 5.0, 5.2, 5.4 }, { 2.1, 2.2, 2.3 }, { 0.9, 1.0, 1.0 }, { 0.3, 1.2, 3.0 }, nil } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 4, values = {
                { 39.5, 41.1, 42.4 }, { 7.1, 8.6, 9.4 }, { 8.4, 8.9, 9.4 }, { 5.3, 5.9, 7.2 }, { 4.0, 4.4, 4.7 }, { 2.1, 2.2, 2.2 }, { 0.8, 0.9, 1.0 }, { 6.1, 8.2, 9.1 }, { 1.9, 2.0, 2.2 } } },
            [2825] = { name = "Den of Nalorakk", window = 3, values = {
                { 36.9, 38.7, 39.9 }, { 7.2, 8.2, 9.4 }, { 7.3, 8.2, 9.1 }, { 3.7, 4.2, 5.5 }, { 3.9, 4.2, 4.5 }, { 2.0, 2.1, 2.2 }, { 0.8, 0.9, 1.0 }, { 6.5, 7.5, 9.3 }, { 1.6, 1.8, 2.1 } } },
            [1762] = { name = "Kings' Rest", window = 3, values = {
                { 39.1, 41.3, 42.8 }, { 6.8, 7.7, 8.3 }, { 7.9, 8.6, 9.3 }, { 4.7, 5.5, 6.7 }, { 3.8, 4.2, 4.6 }, { 2.2, 2.2, 2.2 }, { 0.7, 0.8, 0.9 }, { 8.1, 9.4, 11.3 }, { 1.5, 1.9, 2.1 } } },
            [2813] = { name = "Murder Row", window = 4, values = {
                { 40.1, 41.8, 43.5 }, { 7.7, 9.1, 9.9 }, { 8.5, 9.2, 9.7 }, { 5.6, 6.9, 7.8 }, { 4.3, 4.5, 4.9 }, { 2.1, 2.2, 2.3 }, { 0.8, 0.9, 1.0 }, { 5.4, 6.4, 8.1 }, { 1.7, 2.1, 2.4 } } },
            [2521] = { name = "Ruby Life Pools", window = 3, values = {
                { 38.6, 40.3, 41.6 }, { 7.6, 8.8, 9.5 }, { 8.1, 8.6, 9.3 }, { 4.4, 5.4, 6.4 }, { 4.0, 4.2, 4.6 }, { 2.1, 2.2, 2.2 }, { 0.7, 0.8, 0.9 }, { 6.2, 7.4, 9.2 }, { 1.6, 2.0, 2.2 } } },
            [1877] = { name = "Temple of Sethraliss", window = 4, values = {
                { 37.6, 39.2, 40.8 }, { 6.6, 7.1, 8.1 }, { 8.3, 8.9, 9.5 }, { 6.6, 7.5, 8.9 }, { 3.8, 4.2, 4.6 }, { 2.1, 2.1, 2.2 }, { 0.8, 0.8, 0.9 }, { 4.4, 5.4, 7.3 }, { 1.7, 2.1, 2.2 } } },
            [2859] = { name = "The Blinding Vale", window = 4, values = {
                { 39.3, 40.6, 42.5 }, { 6.7, 7.7, 9.3 }, { 8.0, 8.5, 9.4 }, { 5.5, 6.2, 7.8 }, { 3.7, 4.1, 4.5 }, { 2.1, 2.2, 2.3 }, { 0.8, 0.8, 0.9 }, { 6.4, 8.1, 9.1 }, { 1.6, 2.0, 2.2 } } },
            [2923] = { name = "Voidscar Arena", window = 4, values = {
                { 39.2, 40.0, 41.7 }, { 7.2, 8.2, 9.4 }, { 8.0, 8.7, 9.2 }, { 4.5, 5.6, 6.8 }, { 3.8, 4.2, 4.5 }, { 2.1, 2.2, 2.3 }, { 0.7, 0.8, 0.9 }, { 6.8, 8.1, 9.3 }, { 1.6, 1.9, 2.1 } } },
        },
        dungeonOverall = { name = "all M+ dungeons", window = 4, values = {
            { 38.7, 40.2, 42.1 }, { 7.0, 8.1, 9.2 }, { 8.0, 8.7, 9.4 }, { 4.8, 5.9, 7.2 }, { 3.9, 4.3, 4.6 }, { 2.1, 2.2, 2.2 }, { 0.8, 0.8, 0.9 }, { 6.1, 7.6, 9.2 }, { 1.6, 2.0, 2.2 } } },
    },

    -- Bars: same keys as the other OffBeat specs (1-5, Q, G, E, R, X, the
    -- Shift row, F, `). Riptide stays on 1; Chain Heal (the most pressed
    -- heal) takes 2, where Healing Surge used to be (no top Resto presses
    -- it any more), Healing Wave stays on 3, Healing Stream Totem on 4
    -- (Stormstream Totem shows up on that button). Heals and Earth Shield
    -- are mouseover macros; Surging Totem / Healing Rain, Spirit Link,
    -- Totemic Projection and Wind Rush go at the cursor. Both hero trees
    -- work: the Surging Totem key casts Healing Rain on Farseer, Nature's
    -- Swiftness is Ancestral Swiftness. One layout for raid and one for M+
    -- / delves: Ascendance becomes Healing Tide Totem on Shift-1, and M+
    -- puts the damage spells on R and G. Heroism / Bloodlust sits on F5, out
    -- of the way so you don't press it by accident.
    barLayout = {
        -- both
        { slot = 1,  key = "1",       macro = { name = "OB Riptide", spells = { 61295 }, mouseover = true },
          note = "Riptide (mouseover): on every charge, players without it first" },
        { slot = 2,  key = "2",       macro = { name = "OB ChainHeal", spells = { 1064 }, mouseover = true },
          note = "Chain Heal (mouseover): most pressed in raid, ~19 a minute" },
        { slot = 3,  key = "3",       macro = { name = "OB HWave", spells = { 77472 }, mouseover = true },
          note = "Healing Wave (mouseover): single target, ~6 a minute in M+" },
        { slot = 4,  key = "4",       spellId = 5394,   note = "Healing Stream Totem: on cooldown; Stormstream Totem shows up here" },
        { slot = 5,  key = "5",       macro = { name = "OB Surging/Rain", spells = { 444995, 73920 }, cursor = true },
          note = "Surging Totem at your cursor, every ~27s (Healing Rain on Farseer)" },
        { slot = 6,  key = "Q",       spellId = 378081, alt = { 443454 },
          note = "Nature's Swiftness (Ancestral Swiftness on Farseer): every ~64s, then Chain Heal" },
        { slot = 8,  key = "E",       spellId = 188389, note = "Flame Shock: damage between heals (M+ ~2 a minute)" },
        { slot = 12, key = "X",       macro = { name = "OB PurifySpirit", spells = { 77130 }, mouseover = true },
          note = "Purify Spirit (mouseover): magic and curses" },
        { slot = 62, key = "Shift-2", macro = { name = "OB SLT", spells = { 98008 }, cursor = true },
          note = "Spirit Link Totem at your cursor: a tight group about to take damage" },
        { slot = 63, key = "Shift-3", spellId = 73685,  note = "Unleash Life: on cooldown in M+ (every ~26s), raid builds skip it" },
        { slot = 64, key = "Shift-4", macro = { name = "OB TotemProj", spells = { 108287 }, cursor = true },
          note = "Totemic Projection at your cursor: move your totems to the group" },
        { slot = 65, key = "Shift-5", macro = { name = "OB WindRush", spells = { 192077 }, cursor = true },
          note = "Wind Rush Totem at your cursor (83% of top M+ runs)" },
        { slot = 71, key = "Shift-F", macro = { name = "OB EarthShield", spells = { 974 }, mouseover = true },
          note = "Earth Shield (mouseover): on the tank (81% of top M+ runs)" },
        { slot = 50, key = "Shift-E", spellId = 57994,  note = "Wind Shear: interrupt" },
        { slot = 66, key = "Shift-Q", spellId = 192058, note = "Capacitor Totem: stun (93% of top M+ runs)" },
        { slot = 70, key = "F",       macro = { name = "OB SWalk/Gust", spells = { 58875, 192063 } },
          note = "Spirit Walk (Gust of Wind if you took that): movement" },
        { slot = 25, key = "F5",      spellId = 32182,  alt = { 2825 }, note = "Heroism / Bloodlust: out of the way on purpose" },
        { slot = 55, key = "`",       spellId = 108271, note = "Astral Shift: defensive" },
        { slot = 56, key = "Shift-`", spellId = 198103, note = "Earth Elemental: more health (Primordial Bond)" },

        -- raid: Ascendance, Spiritwalker's Grace, Lava Burst
        { slot = 61, key = "Shift-1", content = "raid", spellId = 114052,
          note = "Ascendance: raid damage on assignment (~every 3 min), 7 Chain Heals in it" },
        { slot = 67, key = "R",       content = "raid", spellId = 79206,
          note = "Spiritwalker's Grace: Chain Heal while moving (83% of top raid kills)" },
        { slot = 7,  key = "G",       content = "raid", spellId = 51505,
          note = "Lava Burst: on Lava Surge when nobody needs healing" },

        -- M+ / delves: Healing Tide Totem, damage
        { slot = 61, key = "Shift-1", content = "dungeon", spellId = 108280,
          note = "Healing Tide Totem: group damage (98% of top M+ runs take it over Ascendance)" },
        { slot = 67, key = "R",       content = "dungeon", spellId = 51505,
          note = "Lava Burst: the top M+ players' damage button, ~2.5 a minute" },
        { slot = 7,  key = "G",       content = "dungeon", spellId = 188443,
          note = "Chain Lightning: packs, ~2 a minute" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Totemic), checked
    -- against the top 40 heroic parses per boss and top 40 timed runs per
    -- dungeon.
    rotationSheet = {
        { title = "Priority (Method)", lines = {
            { spellId = 444995, alt = { 73920 }, text = "Keep Surging Totem out (Healing Rain on Farseer), every ~27s" },
            { spellId = 5394,   text = "Healing Stream Totem on cooldown; Stormstream Totem when it shows up" },
            { spellId = 61295,  text = "Riptide on every charge, players without it first, never at full charges" },
            { spellId = 1064,   text = "Chain Heal with several hurt, Healing Wave for one" },
            { spellId = 378081, alt = { 443454 }, text = "Nature's Swiftness on cooldown (~64s) into a Chain Heal" },
        } },
        { title = "Raid", content = "raid", lines = {
            { spellId = 1064,   text = "Chain Heal is most of it: ~19 a minute for top players" },
            { spellId = 114052, text = "Ascendance on assignment: 7 Chain Heals, 3 Riptides in it" },
            { spellId = 98008,  text = "Spirit Link Totem on a stacked raid before damage" },
            { spellId = 79206,  text = "Spiritwalker's Grace to keep casting through movement" },
        } },
        { title = "M+", content = "dungeon", lines = {
            { spellId = 73685,  text = "Unleash Life on cooldown (~26s), into the next heal" },
            { spellId = 108280, text = "Healing Tide Totem for group damage (instead of Ascendance)" },
            { spellId = 188389, text = "Damage in between: Flame Shock, Lava Burst, Chain Lightning (~7.6 a minute)" },
            { spellId = 974,    text = "Earth Shield on the tank" },
            { spellId = 108287, text = "Totemic Projection when the group moves away from your totems" },
        } },
        { title = "Opener (damage)", lines = {
            { spellId = 51505,  text = "Lava Burst at -2s, Flame Shock on the pull" },
            { spellId = 444995, text = "Surging Totem, then Lava Burst on cooldown" },
            { spellId = 188196, text = "Lightning Bolt, or Chain Lightning on packs" },
        } },
    },

    -- Which build is which, for /ob mode auto outside instances: Ascendance
    -- is the raid build (98% of top raid parses), Healing Tide Totem the M+
    -- one (98% of top runs).
    contentTalents = { raid = { 114052 }, dungeon = { 108280 } },

    -- Stats: the ratings the top players actually wear (Warcraft Logs, 360
    -- raid parses and 313 M+ runs). Raid: Crit > Haste > Vers > Mastery
    -- (median 1424 / 763 / 555 / 314; Crit first for 99%). M+: Crit > Vers >
    -- Haste > Mastery (1243 / 972 / 721 / 306; Crit first for 80%, Vers
    -- second for 61%). Method: Crit > Vers = Haste > Mastery in raid, Crit =
    -- Vers = Haste > Mastery in M+.
    statPriority = { CRIT = 1, HASTE = 2, VERS = 3, MASTERY = 4 },
    contentStatPriorities = {
        raid    = { CRIT = 1, HASTE = 2, VERS = 3, MASTERY = 4 },
        dungeon = { CRIT = 1, VERS = 2, HASTE = 3, MASTERY = 4 },
    },

    keyLayoutLabels = { st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 61295,  st = 1, aoe = 1, note = "Every charge" },
        { spellId = 1064,            aoe = 1, note = "Most pressed in raid" },
        { spellId = 77472,  st = 1,          note = "Single target" },
        { spellId = 5394,   st = 1, aoe = 1, alt = { 1267068 }, note = "On cooldown; Stormstream" },
        { spellId = 444995,          aoe = 1, alt = { 73920 }, note = "Every ~27s" },
        { spellId = 378081, st = 2, aoe = 2, alt = { 443454 }, note = "Every ~64s" },
        { spellId = 73685,  st = 2, aoe = 2, note = "M+: every ~26s" },
        { spellId = 51505,  st = 2, aoe = 2, note = "Damage, Lava Surge" },
        { spellId = 188389, st = 2, aoe = 2, note = "Damage" },
        { spellId = 77130,  st = 2, aoe = 2, note = "Dispel" },
        { spellId = 57994,  st = 2, aoe = 2, note = "Interrupt" },
        { spellId = 114052,          aoe = 3, note = "Raid cooldown" },
        { spellId = 108280,          aoe = 3, note = "M+ cooldown" },
        { spellId = 98008,           aoe = 3, note = "Raid / group cooldown" },
        { spellId = 79206,  st = 3, aoe = 3, note = "Movement" },
        { spellId = 108271, st = 3, aoe = 3, note = "Defensive" },
    },
})
