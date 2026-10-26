local OffBeat = _G.OffBeat

-- Elemental Shaman, Method 12.1.5 (14 Oct 2026), checked against the top
-- 40 heroic parses on every Venomous Abyss boss (360) and the top 40 timed
-- runs per Season 2 dungeon (+23 / +24, 320 runs; Warcraft Logs, Oct 2026).
-- Every one of them is Farseer, the hero tree all of Method's builds use
-- (no Tempest in any log).
--
-- Raid splits by boss: on single-target bosses (Sszorak, Entombed
-- Sentinels, Nek'zali, The Coiled Altar) the top players take Flame Shock
-- and Master of the Elements (175 of 360 parses); on cleave bosses (The
-- Twin Fangs, The Lost Explorers, Nymrissa, Ula'tek, Vashnik) Voltaic
-- Blaze and Purging Flames (185). M+ is Voltaic Blaze in all 320 runs, with
-- Chain Lightning and Earthquake as the busiest buttons. Earth Shock and
-- Fire Elemental aren't pressed by anyone (Elemental Blast is the spender).
--
-- The cooldowns are the same everywhere: Ancestral Swiftness every ~32s,
-- Stormkeeper every ~45s, Ascendance every ~2:10 (First Ascendant or
-- Preeminence), Stormkeeper first.
OffBeat:RegisterProfile({
    meta = {
        name = "Elemental Shaman",
        specId = 262,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Pressed by the top players (Flame Shock / Voltaic Blaze and
    -- Earthquake depending on the boss). Flame Shock is logged twice per
    -- cast (188389 and 470411); only 188389 is counted.
    rotationSpells = {
        { spellId = 188196 }, -- Lightning Bolt
        { spellId = 51505 },  -- Lava Burst
        { spellId = 188443 }, -- Chain Lightning
        { spellId = 117014 }, -- Elemental Blast
        { spellId = 61882 },  -- Earthquake
        { spellId = 188389 }, -- Flame Shock
        { spellId = 470057 }, -- Voltaic Blaze
        { spellId = 114050 }, -- Ascendance
        { spellId = 191634 }, -- Stormkeeper
        { spellId = 443454 }, -- Ancestral Swiftness
    },

    -- No mistake rules: the old "Lava Burst with Master of the Elements up"
    -- needs an aura the game hides in combat, and the logs don't support a
    -- cast-order rule (back-to-back Lava Bursts are ~1% of the top players'
    -- casts in both builds, and they can't be told apart from a hasted
    -- Lightning Bolt in between by timing).

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through. The Ascendance buff is 1219480, not the spell's ID.
    trackedAuras = {
        { spellId = 77762,   name = "Lava Surge",             baseDuration = 10, stacks = false },
        { spellId = 260734,  name = "Master of the Elements", baseDuration = 15, stacks = false },
        { spellId = 191634,  name = "Stormkeeper",            baseDuration = 15, stacks = true },
        { spellId = 1219480, name = "Ascendance",             baseDuration = 15, stacks = false },
        { spellId = 1259491, name = "Purging Flames",         baseDuration = 0,  stacks = false },
        { spellId = 447244,  name = "Call of the Ancestors",  baseDuration = 0,  stacks = false },
    },

    keyCooldown = {
        spellId = 114050,
        name = "Ascendance",
        duration = 15,
    },

    -- Lightning Bolt, Chain Lightning, Lava Burst and Elemental Blast have
    -- cast times (top players: Spiritwalker's Grace in 98% of raid kills).
    failNudges = {
        { error = "moving", spells = { 188196, 188443, 51505, 117014 }, name = "Cast while moving",
          text = "Moving: Spiritwalker's Grace, Lava Burst on Lava Surge, Voltaic Blaze / Flame Shock, Earthquake" },
    },
    movingCasts = { { spellId = 51505, name = "Lava Burst" } },

    -- Countdown to Ascendance: Stormkeeper goes out first (61% of top raid
    -- Ascendances, 77% in M+, within 20s before it) and Ancestral Swiftness
    -- with it (72% within 10s). Method: never hold Stormkeeper more than
    -- 10s, and delay Ascendance to pair it with Stormkeeper unless that
    -- costs a cast.
    prep = {
        spellId = 114050, name = "Ascendance", cooldown = 120, lead = 5,
        hint = "Stormkeeper first, then Ancestral Swiftness and Ascendance; save a Lava Burst charge",
        checks = {
            { name = "Stormkeeper",         ready = 191634, cooldown = 45 },
            { name = "Ancestral Swiftness", ready = 443454, cooldown = 30 },
        },
    },

    -- On cooldown for every top player: Ancestral Swiftness every ~32s
    -- (Method: its Ancestor is a big part of your damage), Stormkeeper every
    -- ~45s, Ascendance every ~2:10, and Voltaic Blaze every ~8.5s when you
    -- have it (M+ and cleave bosses).
    idleCooldowns = {
        { spellId = 443454, name = "Ancestral Swiftness" },
        { spellId = 191634, name = "Stormkeeper" },
        { spellId = 114050, name = "Ascendance" },
        { spellId = 470057, name = "Voltaic Blaze" },
    },

    -- Coaching: Ascendance. Raid: the top players fit 5 Lava Bursts (median
    -- on most bosses, 4 on Ula'tek, Vashnik and Nymrissa) and 2 Elemental
    -- Blasts into its 15s. M+: 3 Lava Bursts and 2 Chain Lightnings (packs
    -- die or move inside it).
    windows = {
        {
            name = "Ascendance (raid)",
            trigger = 114050,
            duration = 15,
            content = "raid",
            note = "Stormkeeper and Ancestral Swiftness first, then Lava Burst on every charge and Elemental "
                .. "Blast at Maelstrom; Spiritwalker's Grace if you must move. Top players: 5 Lava Bursts.",
            goals = {
                { name = "Lava Burst", spells = { 51505 }, min = 5 },
                { name = "Elemental Blast", spells = { 117014 }, min = 2 },
            },
        },
        {
            name = "Ascendance (M+)",
            trigger = 114050,
            duration = 15,
            content = "dungeon",
            note = "Into a fresh pack after Stormkeeper and Voltaic Blaze: Lava Burst with Purging Flames, "
                .. "Earthquake and Chain Lightning. Top players: 3 Lava Bursts.",
            goals = {
                { name = "Lava Burst", spells = { 51505 }, min = 3 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Lava Bursts per Ascendance.
    -- Dungeons (by instance ID): the top 40 timed runs, per minute in combat
    -- (Warcraft Logs' pulls). Single-target bosses are Lightning Bolt and
    -- Flame Shock, cleave bosses Chain Lightning and Voltaic Blaze.
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",  all = true },
            { name = "Lava Burst",      spells = { 51505 } },
            { name = "Lightning Bolt",  spells = { 188196 } },
            { name = "Chain Lightning", spells = { 188443 } },
            { name = "Elemental Blast", spells = { 117014 } },
            { name = "Flame Shock / Voltaic Blaze", spells = { 188389, 470057 } },
            { name = "Earthquake",      spells = { 61882 } },
            { name = "Ascendance / Stormkeeper / Swiftness", spells = { 114050, 191634, 443454 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 4, values = {
                { 39.6, 41.4, 42.9 }, { 11.0, 11.4, 11.9 }, { 6.9, 8.1, 9.0 }, { 5.0, 5.8, 7.3 }, { 5.8, 6.1, 6.5 }, { 4.8, 5.6, 5.8 }, { 0.6, 1.2, 1.8 }, { 3.4, 3.5, 3.6 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 5, values = {
                { 50.2, 51.3, 52.1 }, { 12.7, 13.1, 13.5 }, { 19.2, 19.8, 22.1 }, { 2.1, 3.2, 4.4 }, { 7.1, 7.6, 7.9 }, { 2.7, 2.9, 3.1 }, nil, { 3.8, 3.9, 4.1 } } },
            [3445] = { name = "Entombed Sentinels", window = 5, values = {
                { 49.0, 50.6, 51.8 }, { 13.2, 13.6, 13.8 }, { 15.5, 17.4, 20.5 }, { 2.3, 3.8, 6.2 }, { 7.4, 7.7, 8.1 }, { 3.1, 3.4, 3.9 }, nil, { 3.7, 3.9, 4.0 } } },
            [3455] = { name = "Vashnik the Malignant", window = 4, values = {
                { 48.1, 50.5, 52.4 }, { 11.8, 12.7, 13.3 }, { 15.1, 16.8, 19.3 }, { 3.7, 4.6, 5.7 }, { 5.5, 6.4, 7.4 }, { 2.8, 3.5, 4.4 }, { 0.0, 1.5, 2.9 }, { 3.5, 3.7, 3.8 } } },
            [3497] = { name = "The Lost Explorers", window = 5, values = {
                { 50.0, 51.1, 52.3 }, { 14.1, 14.6, 15.0 }, { 0.6, 1.2, 3.3 }, { 14.5, 15.8, 16.6 }, { 8.2, 8.6, 8.9 }, { 6.6, 7.0, 7.2 }, nil, { 3.9, 4.1, 4.3 } } },
            [3420] = { name = "Sszorak", window = 5, values = {
                { 49.0, 50.4, 51.2 }, { 13.2, 13.6, 13.9 }, { 21.1, 21.9, 23.4 }, nil, { 7.7, 8.1, 8.3 }, { 2.5, 2.7, 3.0 }, nil, { 3.7, 3.9, 4.0 } } },
            [3421] = { name = "The Twin Fangs", window = 5, values = {
                { 49.2, 50.3, 51.7 }, { 12.5, 13.7, 14.2 }, { 1.2, 1.7, 2.2 }, { 15.7, 16.4, 17.6 }, { 7.0, 7.5, 7.8 }, { 6.6, 6.7, 7.0 }, nil, { 3.6, 3.8, 3.8 } } },
            [3429] = { name = "The Coiled Altar", window = 5, values = {
                { 47.6, 48.9, 50.1 }, { 12.5, 13.1, 13.4 }, { 12.8, 14.0, 16.0 }, { 5.4, 7.7, 8.4 }, { 7.0, 7.3, 7.5 }, { 3.2, 3.6, 4.0 }, nil, { 3.5, 3.6, 3.7 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 4, values = {
                { 43.9, 46.9, 48.7 }, { 11.4, 12.2, 13.2 }, { 7.7, 10.7, 12.6 }, { 4.9, 6.0, 7.0 }, { 4.3, 5.1, 6.5 }, { 5.0, 5.4, 6.0 }, { 0.0, 2.9, 5.1 }, { 3.6, 3.8, 4.0 } } },
        },
        overall = { name = "all heroic bosses", window = 5, values = {
            { 47.5, 49.7, 51.4 }, { 12.1, 13.2, 13.8 }, { 6.8, 13.5, 19.5 }, { 3.2, 5.7, 9.0 }, { 6.6, 7.4, 8.0 }, { 3.0, 4.2, 6.1 }, nil, { 3.6, 3.8, 4.0 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 3, values = {
                { 44.7, 45.9, 46.7 }, { 9.1, 9.4, 9.7 }, { 6.1, 6.4, 6.9 }, { 9.2, 9.6, 10.4 }, { 3.5, 3.7, 3.9 }, { 5.4, 5.8, 6.4 }, { 7.0, 7.5, 7.7 }, { 3.4, 3.5, 3.6 } } },
            [2825] = { name = "Den of Nalorakk", window = 3, values = {
                { 40.4, 42.1, 43.9 }, { 8.9, 9.4, 9.9 }, { 3.9, 4.7, 5.4 }, { 8.7, 9.2, 10.1 }, { 4.0, 4.2, 4.4 }, { 5.5, 5.8, 6.2 }, { 5.2, 5.6, 5.9 }, { 3.3, 3.4, 3.4 } } },
            [1762] = { name = "Kings' Rest", window = 3, values = {
                { 42.3, 44.2, 45.0 }, { 10.2, 10.9, 11.1 }, { 4.9, 5.4, 6.5 }, { 8.6, 9.5, 10.4 }, { 5.3, 5.7, 6.0 }, { 5.7, 6.2, 6.4 }, { 2.4, 2.9, 3.2 }, { 3.4, 3.5, 3.6 } } },
            [2813] = { name = "Murder Row", window = 3, values = {
                { 43.7, 44.7, 46.2 }, { 9.3, 9.7, 10.0 }, { 5.2, 5.6, 6.3 }, { 9.1, 10.1, 10.7 }, { 3.8, 4.1, 4.5 }, { 5.6, 5.8, 6.2 }, { 5.6, 6.2, 6.7 }, { 3.4, 3.5, 3.6 } } },
            [2521] = { name = "Ruby Life Pools", window = 3, values = {
                { 44.0, 45.2, 46.7 }, { 9.0, 9.4, 9.9 }, { 1.0, 1.5, 1.8 }, { 12.3, 13.3, 13.8 }, { 5.1, 5.3, 5.9 }, { 6.3, 6.6, 6.9 }, { 5.0, 5.7, 6.2 }, { 3.6, 3.6, 3.7 } } },
            [1877] = { name = "Temple of Sethraliss", window = 3, values = {
                { 42.0, 43.7, 45.8 }, { 9.1, 9.4, 9.8 }, { 3.9, 4.6, 5.3 }, { 9.2, 9.7, 10.7 }, { 4.1, 4.4, 4.7 }, { 5.9, 6.2, 6.4 }, { 5.6, 6.0, 6.4 }, { 3.4, 3.5, 3.6 } } },
            [2859] = { name = "The Blinding Vale", window = 3, values = {
                { 45.1, 46.6, 47.4 }, { 9.1, 9.4, 9.7 }, { 4.7, 5.2, 5.8 }, { 10.4, 11.0, 12.0 }, { 2.8, 3.0, 3.3 }, { 6.0, 6.2, 6.4 }, { 7.9, 8.4, 8.6 }, { 3.4, 3.6, 3.6 } } },
            [2923] = { name = "Voidscar Arena", window = 3, values = {
                { 43.1, 44.0, 45.3 }, { 10.1, 10.3, 10.8 }, { 5.7, 6.0, 6.7 }, { 8.1, 8.5, 9.0 }, { 5.0, 5.2, 5.5 }, { 5.5, 6.0, 6.3 }, { 4.4, 4.7, 5.0 }, { 3.4, 3.5, 3.6 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 3, values = {
            { 42.6, 44.7, 46.2 }, { 9.2, 9.7, 10.2 }, { 4.3, 5.3, 6.1 }, { 9.0, 10.0, 11.1 }, { 3.8, 4.4, 5.2 }, { 5.7, 6.2, 6.4 }, { 4.2, 5.7, 6.8 }, { 3.4, 3.5, 3.6 } } },
    },

    -- /ob bars: role for role on the keys your other specs use (binds are
    -- account-wide): filler on 1, AoE filler on 2, Lava Burst and the
    -- spender on 3-4, Flame Shock / Voltaic Blaze on 5 (one macro for both
    -- builds), Ancestral Swiftness (every ~32s) on Q, Stormkeeper (every
    -- ~45s) on G and Ascendance on Shift-1, Earthquake at the cursor on E,
    -- Spiritwalker's Grace on R. Interrupt Shift-E, Capacitor Totem
    -- Shift-Q, defensives on ` / Shift-`, Gust of Wind on F. Heroism /
    -- Bloodlust sits on F5, out of the way so you don't press it by
    -- accident. One layout for raid and M+. Hex, Ghost Wolf and anything
    -- not listed are left alone.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 188196, note = "Lightning Bolt: filler, ~14 a minute in raid (Stormkeeper boosts it)" },
        { slot = 2,  key = "2",       spellId = 188443, note = "Chain Lightning: 2+ targets, the top M+ players' most pressed spell" },
        { slot = 3,  key = "3",       spellId = 51505,  note = "Lava Burst: on every charge and Lava Surge, not twice in a row with Master of the Elements" },
        { slot = 4,  key = "4",       spellId = 117014, note = "Elemental Blast: the Maelstrom spender, before you cap" },
        { slot = 5,  key = "5",       macro = { name = "OB VBlaze/FShock", spells = { 470057, 188389 } },
          note = "Voltaic Blaze (cleave / M+, every ~8.5s) or Flame Shock (single-target build)" },
        { slot = 6,  key = "Q",       spellId = 443454, note = "Ancestral Swiftness: on cooldown (~32s), follow it with a cast-time spell" },
        { slot = 7,  key = "G",       spellId = 191634, note = "Stormkeeper: on cooldown (~45s), first before Ascendance" },
        { slot = 61, key = "Shift-1", spellId = 114050, note = "Ascendance: after Stormkeeper, every ~2 min" },
        { slot = 8,  key = "E",       macro = { name = "OB Earthquake", spells = { 61882 }, cursor = true },
          note = "Earthquake at your cursor: 3+ targets, ~6 a minute in M+" },
        { slot = 67, key = "R",       spellId = 79206,  note = "Spiritwalker's Grace: cast while moving (98% of top raid kills)" },
        { slot = 62, key = "Shift-2", macro = { name = "OB WindRush", spells = { 192077 }, cursor = true },
          note = "Wind Rush Totem at your cursor (95% of top M+ runs)" },
        { slot = 63, key = "Shift-3", spellId = 51490,  note = "Thunderstorm: knock a pack back (58% of top M+ runs)" },
        { slot = 64, key = "Shift-4", spellId = 383013, note = "Poison Cleansing Totem (60% of top M+ runs)" },
        { slot = 65, key = "Shift-5", spellId = 370,    note = "Purge: an enemy buff (M+)" },
        { slot = 50, key = "Shift-E", spellId = 57994,  note = "Wind Shear: interrupt" },
        { slot = 66, key = "Shift-Q", spellId = 192058, note = "Capacitor Totem: stun (92% of top M+ runs)" },
        { slot = 12, key = "X",       macro = { name = "OB CleanseSpirit", spells = { 51886 }, mouseover = true },
          note = "Cleanse Spirit (mouseover): curses" },
        { slot = 70, key = "F",       spellId = 192063, note = "Gust of Wind: movement, you can cast as you land" },
        { slot = 25, key = "F5",      spellId = 32182,  alt = { 2825 }, note = "Heroism / Bloodlust: out of the way on purpose" },
        { slot = 55, key = "`",       spellId = 108271, note = "Astral Shift: defensive" },
        { slot = 56, key = "Shift-`", spellId = 198103, note = "Earth Elemental: more health (Primordial Bond)" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Farseer), checked
    -- against the top parses and runs.
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 191634, text = "Stormkeeper at -3s, Lava Burst at -1.5s (lands on the pull)" },
            { spellId = 443454, text = "Ancestral Swiftness, then Ascendance with trinket and potion" },
            { spellId = 188196, text = "Lightning Bolt, Lava Burst, then the priority" },
            { text = "AoE: Stormkeeper, Swiftness, Voltaic Blaze, Ascendance, Lava Burst" },
        } },
        { title = "Cooldowns", lines = {
            { spellId = 443454, text = "Ancestral Swiftness on cooldown (~32s), then a cast-time spell" },
            { spellId = 191634, text = "Stormkeeper on cooldown (~45s); hold it 10s at most for adds" },
            { spellId = 114050, text = "Ascendance right after Stormkeeper (~2 min): 5 Lava Bursts in raid" },
        } },
        { title = "Single target (Flame Shock build)", unknown = { 470057 }, lines = {
            { spellId = 188389, text = "Flame Shock under 6s left (3s on Fire Elemental)" },
            { spellId = 117014, text = "Elemental Blast within 15 Maelstrom of cap" },
            { spellId = 51505,  text = "Lava Burst without Master of the Elements" },
            { spellId = 188196, text = "Stormkeeper Lightning Bolt with Master of the Elements" },
            { spellId = 117014, text = "Elemental Blast with Master of the Elements, else Lightning Bolt" },
        } },
        { title = "Single target (Voltaic Blaze)", known = { 470057 }, lines = {
            { spellId = 470057, text = "Voltaic Blaze under 6s of Flame Shock left, on cooldown at 2+" },
            { spellId = 117014, text = "Elemental Blast within 15 Maelstrom of cap" },
            { spellId = 51505,  text = "Lava Burst, Elemental Blast, Lightning Bolt (Chain Lightning at 2)" },
        } },
        { title = "AoE (3+) and M+", lines = {
            { spellId = 470057, text = "Voltaic Blaze on cooldown (~8.5s)" },
            { spellId = 51505,  text = "Lava Burst with Purging Flames, ideally on Lava Surge" },
            { spellId = 61882,  text = "Earthquake while Ancestors are up (always at 5+)" },
            { spellId = 117014, text = "Elemental Blast with no Ancestors up (3-5 targets)" },
            { spellId = 188443, text = "Chain Lightning as filler (top M+: ~10 a minute)" },
        } },
    },

    -- Stats: the ratings the top players actually wear (Warcraft Logs, 360
    -- raid parses and 296 M+ runs): Crit = Mastery > Haste > Vers in both
    -- (median raid 1092 / 1062 / 787 / 123, M+ 1154 / 1100 / 774 / 176;
    -- Crit first for 54% / 60%, Mastery for the rest). Method (Farseer):
    -- Mastery > Haste >= Crit > Vers.
    statPriority = { CRIT = 1, MASTERY = 1, HASTE = 3, VERS = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 188196, st = 1, aoe = 2, note = "Filler" },
        { spellId = 188443,          aoe = 1, note = "AoE filler, most pressed in M+" },
        { spellId = 51505,  st = 1, aoe = 1, note = "Every charge, Lava Surge" },
        { spellId = 117014, st = 1, aoe = 2, note = "Spender" },
        { spellId = 470057, st = 2, aoe = 1, alt = { 188389 }, note = "Voltaic Blaze / Flame Shock" },
        { spellId = 61882,           aoe = 1, note = "3+ targets" },
        { spellId = 443454, st = 2, aoe = 2, note = "Every ~32s" },
        { spellId = 191634, st = 2, aoe = 2, note = "Every ~45s" },
        { spellId = 114050, st = 3, aoe = 3, note = "Every ~2 min" },
        { spellId = 79206,  st = 3, aoe = 3, note = "Movement" },
        { spellId = 57994,  st = 2, aoe = 2, note = "Interrupt" },
    },
})
