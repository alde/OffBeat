local OffBeat = _G.OffBeat

-- Holy Paladin, Method 12.1.5 (13 Oct 2026), checked against the top 40
-- heroic parses (by healing) on every Venomous Abyss boss and the top 40
-- timed runs per Season 2 dungeon (+22 to +24, 320 runs; Warcraft Logs,
-- Oct 2026).
--
-- Raid: all 360 top parses play Herald of the Sun, with Beacon of Virtue
-- (every ~16s), Divine Toll (every ~33s) and Eternal Flame as the spender.
-- M+ is a different build: 94% Lightsmith (Method suggests Herald), Word of
-- Glory instead of Eternal Flame, Holy Armaments, and no Beacon of Virtue
-- or Divine Toll at all. Shield of the Righteous is their most pressed
-- button (~10 a minute in combat), then Flash of Light, Word of Glory,
-- Judgment and Holy Shock. The content mode (/ob mode, auto by instance)
-- picks the bars, sheet sections, idle alerts, wings window and dummy
-- numbers.
--
-- Healing is reactive, so there are no mistake rules. Even Method's Divine
-- Toll with Beacon of Virtue is only 78% of the top raid players' Tolls.
OffBeat:RegisterProfile({
    meta = {
        name = "Holy Paladin",
        specId = 65,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Raid: pressed by 76%+ of the top players (Hammer of Wrath lowest),
    -- Holy Light by 55%. M+: Shield of the Righteous, Word of Glory and Holy
    -- Armaments by all of them. Reclamation (37 a minute in raid logs)
    -- fires off Holy Shock by itself and is left out.
    rotationSpells = {
        { spellId = 20473 },   -- Holy Shock
        { spellId = 156322 },  -- Eternal Flame (Herald; replaces Word of Glory)
        { spellId = 85673 },   -- Word of Glory
        { spellId = 19750 },   -- Flash of Light
        { spellId = 200025 },  -- Beacon of Virtue
        { spellId = 275773 },  -- Judgment
        { spellId = 375576 },  -- Divine Toll
        { spellId = 85222 },   -- Light of Dawn
        { spellId = 31884 },   -- Avenging Wrath
        { spellId = 31821 },   -- Aura Mastery
        { spellId = 82326 },   -- Holy Light
        { spellId = 415091 },  -- Shield of the Righteous
        { spellId = 1241413 }, -- Hammer of Wrath (cast ID in the logs)
        { spellId = 24275 },   -- Hammer of Wrath (spellbook)
        { spellId = 432459 },  -- Holy Bulwark (Holy Armaments, Lightsmith)
        { spellId = 432472 },  -- Sacred Weapon (Holy Armaments, Lightsmith)
    },

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through.
    trackedAuras = {
        { spellId = 54149,  name = "Infusion of Light", baseDuration = 15, stacks = true },
        { spellId = 223819, name = "Divine Purpose",    baseDuration = 12, stacks = false },
        { spellId = 31884,  name = "Avenging Wrath",    baseDuration = 20, stacks = false },
        { spellId = 431907, name = "Sun's Avatar",      baseDuration = 0,  stacks = false },
    },

    keyCooldown = {
        spellId = 31884,
        name = "Avenging Wrath",
        duration = 20,
    },

    -- Flash of Light and Holy Light have cast times.
    failNudges = {
        { error = "moving", spells = { 19750, 82326 }, name = "Cast while moving",
          text = "Moving: Holy Shock, Eternal Flame / Word of Glory and Judgment are instant" },
    },

    -- On cooldown for the top players: Beacon of Virtue every ~16s and
    -- Divine Toll every ~33s in raid, Avenging Wrath every ~124s in raid
    -- (2 min) and ~96s in M+, Judgment every ~6s in M+ (Method: on cooldown,
    -- it procs Consecration). Holy Shock and Holy Armaments have charges
    -- (they'd nag at one charge); Aura Mastery and the externals are held.
    idleCooldowns = {
        { spellId = 200025, name = "Beacon of Virtue", content = "raid" },
        { spellId = 375576, name = "Divine Toll", content = "raid" },
        { spellId = 31884,  name = "Avenging Wrath" },
        { spellId = 275773, name = "Judgment", content = "dungeon" },
    },

    -- Coaching: wings. Raid (Herald): in the 20s of Avenging Wrath the top
    -- players cast 4 Holy Shocks and 4 Eternal Flames (median), a Beacon of
    -- Virtue in 93% of them and Divine Toll in 64%. M+ (Lightsmith): 7
    -- Holy Power spenders (Shield of the Righteous / Word of Glory, middle
    -- half 6-8) and 2 Holy Shocks, from 64 of the top runs.
    windows = {
        {
            name = "Avenging Wrath (raid)",
            trigger = 31884,
            duration = 20,
            content = "raid",
            note = "Wings with Beacon of Virtue out, then Divine Toll; Holy Shock on every charge and "
                .. "Eternal Flame on every 3+ Holy Power. Top players: 4 Holy Shocks, 4 Eternal Flames.",
            goals = {
                { name = "Eternal Flame", spells = { 156322, 85673 }, min = 4 },
                { name = "Holy Shock", spells = { 20473 }, min = 4 },
            },
        },
        {
            name = "Avenging Wrath (M+)",
            trigger = 31884,
            duration = 20,
            content = "dungeon",
            note = "Wings when the group needs it: spend every Holy Power on Shield of the Righteous, "
                .. "Word of Glory where it's needed. Top players: 7 spenders, 2 Holy Shocks.",
            goals = {
                { name = "Shield of the Righteous / Word of Glory", spells = { 415091, 85673 }, min = 7 },
                { name = "Holy Shock", spells = { 20473 }, min = 2 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Eternal Flames per Avenging Wrath.
    -- Dungeons (by instance ID): the top 40 timed runs, per minute in combat
    -- (Warcraft Logs' pulls); window = median spenders per Avenging Wrath.
    -- Raid has no numbers for Shield of the Righteous, Holy Light, Hammer of
    -- Wrath (the top players barely press them) or Holy Armaments; M+ none
    -- for Beacon of Virtue, Divine Toll and Light of Dawn.
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",          all = true },
            { name = "Holy Shock",              spells = { 20473 } },
            { name = "Eternal Flame / Word of Glory", spells = { 156322, 85673 } },
            { name = "Flash of Light",          spells = { 19750 } },
            { name = "Judgment",                spells = { 275773 } },
            { name = "Shield of the Righteous", spells = { 415091 } },
            { name = "Holy Light",              spells = { 82326 } },
            { name = "Hammer of Wrath",         spells = { 1241413, 24275 } },
            { name = "Beacon of Virtue",        spells = { 200025 } },
            { name = "Divine Toll",             spells = { 375576 } },
            { name = "Light of Dawn",           spells = { 85222 } },
            { name = "Holy Armaments",          spells = { 432459, 432472 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 5, values = {
                { 45.1, 46.4, 47.8 }, { 12.2, 13.2, 14.0 }, { 11.7, 13.0, 14.2 }, { 8.7, 9.8, 10.2 }, { 1.8, 2.4, 3.1 }, nil, nil, nil, { 3.1, 3.4, 3.6 }, { 1.6, 1.7, 1.8 }, { 0.4, 1.7, 2.7 }, nil } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 4, values = {
                { 46.1, 47.1, 48.4 }, { 12.1, 13.4, 14.4 }, { 7.1, 11.4, 13.5 }, { 8.3, 9.5, 10.4 }, { 1.4, 2.4, 3.4 }, nil, nil, nil, { 3.1, 3.4, 3.6 }, { 1.6, 1.8, 1.8 }, { 0.6, 2.7, 6.9 }, nil } },
            [3445] = { name = "Entombed Sentinels", window = 4, values = {
                { 45.0, 46.8, 50.4 }, { 12.2, 13.4, 14.7 }, { 10.3, 12.1, 14.0 }, { 8.6, 9.5, 10.3 }, { 1.4, 2.7, 3.5 }, nil, nil, nil, { 3.2, 3.4, 3.5 }, { 1.5, 1.7, 1.8 }, { 0.0, 1.6, 3.7 }, nil } },
            [3455] = { name = "Vashnik the Malignant", window = 4, values = {
                { 44.6, 47.3, 49.3 }, { 11.9, 13.3, 15.0 }, { 8.0, 10.7, 12.8 }, { 8.1, 9.4, 10.1 }, { 2.1, 3.1, 3.9 }, nil, nil, nil, { 3.2, 3.4, 3.6 }, { 1.6, 1.7, 1.8 }, { 1.3, 3.0, 6.3 }, nil } },
            [3497] = { name = "The Lost Explorers", window = 4, values = {
                { 45.6, 47.2, 49.3 }, { 12.8, 14.2, 15.2 }, { 10.0, 12.0, 13.4 }, { 8.8, 9.9, 10.6 }, { 1.2, 1.8, 2.2 }, nil, nil, nil, { 3.3, 3.5, 3.8 }, { 1.6, 1.8, 1.9 }, { 0.8, 2.1, 4.0 }, nil } },
            [3420] = { name = "Sszorak", window = 5, values = {
                { 45.2, 46.5, 48.1 }, { 12.0, 13.1, 14.3 }, { 11.1, 13.3, 14.4 }, { 8.8, 9.6, 10.2 }, { 1.1, 2.1, 2.7 }, nil, nil, nil, { 3.4, 3.6, 3.7 }, { 1.7, 1.8, 1.9 }, { 0.0, 1.1, 2.8 }, nil } },
            [3421] = { name = "The Twin Fangs", window = 4, values = {
                { 46.7, 48.2, 49.5 }, { 12.9, 13.7, 14.9 }, { 9.3, 11.8, 13.6 }, { 8.6, 9.6, 10.9 }, { 1.7, 2.4, 3.0 }, nil, nil, nil, { 3.1, 3.4, 3.6 }, { 1.6, 1.8, 1.9 }, { 1.0, 3.1, 6.1 }, nil } },
            [3429] = { name = "The Coiled Altar", window = 4, values = {
                { 46.6, 48.0, 49.3 }, { 12.1, 12.9, 13.5 }, { 10.8, 12.7, 14.4 }, { 9.1, 9.9, 11.1 }, { 1.8, 2.5, 3.1 }, nil, nil, nil, { 3.4, 3.6, 3.7 }, { 1.7, 1.8, 1.9 }, { 0.5, 2.5, 4.0 }, nil } },
            [3379] = { name = "Nymrissa Wavecaller", window = 4, values = {
                { 45.4, 48.1, 49.9 }, { 12.5, 13.2, 14.1 }, { 8.4, 10.8, 13.0 }, { 7.7, 9.1, 9.8 }, { 3.1, 3.6, 4.6 }, nil, nil, nil, { 2.7, 3.0, 3.2 }, { 1.6, 1.7, 1.7 }, { 0.8, 2.9, 5.9 }, nil } },
        },
        overall = { name = "all heroic bosses", window = 4, values = {
            { 45.5, 47.2, 49.3 }, { 12.2, 13.4, 14.6 }, { 9.3, 12.1, 13.9 }, { 8.5, 9.6, 10.4 }, { 1.7, 2.4, 3.4 }, nil, nil, nil, { 3.2, 3.4, 3.6 }, { 1.6, 1.7, 1.8 }, { 0.5, 2.2, 4.7 }, nil } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 7, values = {
                { 45.8, 46.9, 48.0 }, { 4.7, 5.8, 6.9 }, { 5.9, 6.9, 7.7 }, { 8.4, 8.9, 9.8 }, { 6.0, 6.5, 7.0 }, { 9.2, 10.3, 11.4 }, { 3.2, 3.4, 3.9 }, { 1.5, 1.7, 1.8 }, nil, nil, nil, { 2.1, 2.3, 2.3 } } },
            [2825] = { name = "Den of Nalorakk", window = 7, values = {
                { 42.6, 44.1, 45.6 }, { 5.7, 6.5, 7.6 }, { 4.7, 5.3, 6.5 }, { 6.6, 7.0, 7.5 }, { 6.1, 6.6, 7.2 }, { 10.0, 10.9, 12.0 }, { 2.3, 2.7, 3.0 }, { 1.6, 1.8, 2.2 }, nil, nil, nil, { 2.1, 2.2, 2.3 } } },
            [1762] = { name = "Kings' Rest", window = 7, values = {
                { 46.2, 47.3, 48.6 }, { 6.5, 7.2, 8.3 }, { 5.4, 6.1, 6.7 }, { 6.8, 7.8, 8.3 }, { 6.6, 7.2, 7.8 }, { 9.8, 10.8, 12.7 }, { 2.5, 2.8, 3.1 }, { 1.5, 1.9, 2.1 }, nil, nil, nil, { 2.1, 2.2, 2.3 } } },
            [2813] = { name = "Murder Row", window = 6, values = {
                { 46.1, 47.3, 48.4 }, { 4.7, 5.5, 6.2 }, { 7.1, 7.9, 8.6 }, { 9.4, 10.5, 11.4 }, { 5.6, 6.2, 6.6 }, { 8.0, 8.7, 9.8 }, { 3.5, 3.7, 4.2 }, { 1.3, 1.5, 1.9 }, nil, nil, nil, { 2.1, 2.3, 2.4 } } },
            [2521] = { name = "Ruby Life Pools", window = 7, values = {
                { 46.0, 47.3, 48.6 }, { 4.3, 5.4, 6.7 }, { 6.1, 6.9, 7.9 }, { 9.1, 9.9, 10.4 }, { 5.8, 6.4, 6.8 }, { 9.1, 9.7, 11.0 }, { 3.4, 3.9, 4.3 }, { 1.3, 1.5, 1.7 }, nil, nil, nil, { 2.1, 2.3, 2.4 } } },
            [1877] = { name = "Temple of Sethraliss", window = 7, values = {
                { 45.8, 46.9, 48.2 }, { 5.3, 6.0, 6.8 }, { 7.2, 8.1, 8.6 }, { 8.8, 9.6, 10.4 }, { 5.9, 6.4, 7.1 }, { 8.3, 8.9, 9.8 }, { 3.0, 3.3, 3.7 }, { 1.3, 1.4, 1.6 }, nil, nil, nil, { 2.1, 2.3, 2.3 } } },
            [2859] = { name = "The Blinding Vale", window = 7, values = {
                { 46.5, 47.4, 48.3 }, { 5.2, 6.1, 7.4 }, { 6.0, 6.6, 7.4 }, { 8.5, 9.0, 9.6 }, { 6.2, 6.8, 7.3 }, { 9.5, 10.5, 11.4 }, { 3.0, 3.3, 3.6 }, { 1.3, 1.7, 1.8 }, nil, nil, nil, { 2.1, 2.2, 2.3 } } },
            [2923] = { name = "Voidscar Arena", window = 7, values = {
                { 47.1, 47.8, 48.8 }, { 5.7, 6.5, 7.5 }, { 5.5, 6.8, 7.8 }, { 8.5, 9.0, 9.7 }, { 6.4, 7.0, 7.6 }, { 9.6, 10.4, 11.8 }, { 2.9, 3.2, 3.5 }, { 1.3, 1.5, 1.7 }, nil, nil, nil, { 2.2, 2.3, 2.3 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 7, values = {
            { 45.7, 47.0, 48.2 }, { 5.1, 6.2, 7.2 }, { 5.7, 6.8, 7.9 }, { 8.0, 9.0, 10.0 }, { 6.1, 6.6, 7.2 }, { 8.9, 10.0, 11.3 }, { 2.8, 3.3, 3.8 }, { 1.3, 1.6, 1.9 }, nil, nil, nil, { 2.1, 2.3, 2.3 } } },
    },

    -- Bars: same keys as the other OffBeat specs (1-5, Q, G, E, R, X, the
    -- Shift row, F, `), one layout for raid and one for M+ / delves like
    -- Mistweaver, since the builds' busiest buttons differ (raid: Holy
    -- Shock 13, Eternal Flame 12, Flash of Light 10 a minute; M+: Shield of
    -- the Righteous 10, Flash of Light 9, Word of Glory 7, Judgment 7).
    -- Heals and externals are mouseover macros. Keys that hold the same
    -- spell in both stay put; the swap is offered when you enter a raid, a
    -- key or a delve (/ob mode). F is Blessing of Freedom; Divine Steed
    -- stays on your Meta-Q and isn't touched.
    barLayout = {
        -- both
        { slot = 1,  key = "1",       macro = { name = "OB HShock", spells = { 20473 }, mouseover = true },
          note = "Holy Shock (mouseover): most pressed in raid, on every charge" },
        { slot = 3,  key = "3",       macro = { name = "OB FoL", spells = { 19750 }, mouseover = true },
          note = "Flash of Light (mouseover): Infusion of Light procs" },
        { slot = 4,  key = "4",       spellId = 275773, note = "Judgment: builds Holy Power, on cooldown in M+" },
        { slot = 6,  key = "Q",       spellId = 31884, note = "Avenging Wrath: on cooldown in raid (2 min)" },
        { slot = 12, key = "X",       macro = { name = "OB Cleanse", spells = { 4987 }, mouseover = true }, note = "Cleanse (mouseover)" },
        { slot = 61, key = "Shift-1", macro = { name = "OB Sacrifice", spells = { 6940 }, mouseover = true },
          note = "Blessing of Sacrifice (mouseover): external" },
        { slot = 62, key = "Shift-2", spellId = 31821, note = "Aura Mastery: before raid-wide damage" },
        { slot = 63, key = "Shift-3", macro = { name = "OB LoH", spells = { 633 }, mouseover = true },
          note = "Lay on Hands (mouseover)" },
        { slot = 64, key = "Shift-4", macro = { name = "OB BoP", spells = { 1022 }, mouseover = true },
          note = "Blessing of Protection (mouseover): not on the tank" },
        { slot = 66, key = "Shift-Q", spellId = 853, note = "Hammer of Justice: stun" },
        { slot = 50, key = "Shift-E", spellId = 115750, note = "Blinding Light: AoE disorient" },
        { slot = 70, key = "F",       macro = { name = "OB Freedom", spells = { 1044 }, mouseover = true },
          note = "Blessing of Freedom (mouseover); Divine Steed stays on your Meta-Q" },
        { slot = 55, key = "`",       spellId = 498, note = "Divine Protection: defensive" },
        { slot = 56, key = "Shift-`", spellId = 642, note = "Divine Shield" },

        -- raid (Herald): Eternal Flame, Beacon of Virtue, Divine Toll, Light of Dawn
        { slot = 2,  key = "2",       content = "raid", macro = { name = "OB EFlame", spells = { 156322 }, mouseover = true },
          note = "Eternal Flame (mouseover): the spender, ~12 a minute" },
        { slot = 5,  key = "5",       content = "raid", macro = { name = "OB BoV", spells = { 200025 }, mouseover = true },
          note = "Beacon of Virtue (mouseover): on cooldown, every ~16s" },
        { slot = 8,  key = "E",       content = "raid", spellId = 375576, note = "Divine Toll: right after Beacon of Virtue, every ~33s" },
        { slot = 7,  key = "G",       content = "raid", spellId = 85222, note = "Light of Dawn: when Eternal Flame would overheal" },
        { slot = 67, key = "R",       content = "raid", spellId = 24275, alt = { 1241413 }, note = "Hammer of Wrath: when it lights up" },

        -- M+ / delves (Lightsmith): Shield of the Righteous, Word of Glory, Holy Light, Armaments
        { slot = 2,  key = "2",       content = "dungeon", spellId = 415091,
          note = "Shield of the Righteous: the top M+ players' most pressed button, Holy Power on damage" },
        { slot = 5,  key = "5",       content = "dungeon", macro = { name = "OB WoG", spells = { 85673 }, mouseover = true },
          note = "Word of Glory (mouseover): Holy Power where it's needed" },
        { slot = 8,  key = "E",       content = "dungeon", macro = { name = "OB HLight", spells = { 82326 }, mouseover = true },
          note = "Holy Light (mouseover): ~3 a minute, when there's no Holy Power or Infusion" },
        { slot = 7,  key = "G",       content = "dungeon", spellId = 24275, alt = { 1241413 }, note = "Hammer of Wrath: on cooldown (~every 6s)" },
        { slot = 67, key = "R",       content = "dungeon", spellId = 432459, alt = { 432472 },
          note = "Holy Armaments: Holy Bulwark / Sacred Weapon, ~2 a minute" },
    },

    -- The movable cheat sheet (/ob sheet). Raid: Method, checked against the
    -- top 40 heroic parses per boss. M+: Method, checked against the top 40
    -- timed runs per dungeon.
    rotationSheet = {
        { title = "Priority (Method)", lines = {
            { text = "Spend at 5 Holy Power first, then Divine Toll" },
            { spellId = 19750, text = "Flash of Light on Infusion of Light" },
            { spellId = 20473, text = "Holy Shock, then spend Holy Power, then Judgment" },
            { spellId = 82326, text = "Holy Light only with no Holy Power and no Infusion (very mana heavy)" },
        } },
        { title = "Raid (Herald)", content = "raid", lines = {
            { spellId = 200025, text = "Beacon of Virtue on cooldown, into damage (top players: every ~16s)" },
            { spellId = 375576, text = "Divine Toll right after Beacon of Virtue (78% of top Tolls)" },
            { spellId = 156322, text = "Eternal Flame: the spender, ~12 a minute" },
            { spellId = 85222, text = "Light of Dawn when Eternal Flame would overheal" },
            { spellId = 31884, text = "Avenging Wrath on cooldown: 4 Holy Shocks, 4 Eternal Flames in it" },
            { spellId = 31821, text = "Aura Mastery on assignment or before raid damage" },
        } },
        { title = "M+ (Lightsmith)", content = "dungeon", lines = {
            { spellId = 415091, text = "Shield of the Righteous: most pressed (~10 a minute), spend Holy Power on damage" },
            { spellId = 85673, text = "Word of Glory where healing is needed (~7 a minute)" },
            { spellId = 275773, text = "Judgment and Hammer of Wrath on cooldown (every ~6s)" },
            { spellId = 432459, alt = { 432472 }, text = "Holy Armaments: Holy Bulwark on the tank, Sacred Weapon on a DPS" },
            { spellId = 31884, text = "Avenging Wrath for group damage (~every 96s): 7 spenders in it" },
            { text = "Top M+ runs don't take Beacon of Virtue or Divine Toll" },
        } },
        { title = "Cooldowns", lines = {
            { spellId = 6940, text = "Blessing of Sacrifice: 30% off an ally, not if you'd die yourself" },
            { spellId = 1022, text = "Blessing of Protection: physical, never on the tank" },
            { spellId = 642, text = "Divine Shield: emergency, skip a mechanic, or 8s of safe healing" },
        } },
    },

    -- Which build is which, for /ob mode auto outside instances: Beacon of
    -- Virtue or Eternal Flame is the raid build (all top raid parses), Holy
    -- Armaments the M+ one (94% of top runs).
    contentTalents = { raid = { 200025, 156322 }, dungeon = { 432459 } },

    -- Stats: the ratings the top players actually wear (Warcraft Logs, 198
    -- raid parses and 164 M+ runs). Raid: Mastery > Haste > Crit > Vers
    -- (median 1280 / 905 / 761 / 130; Mastery first for 83%, Haste second
    -- for 67%), matching Method. M+: Haste > Crit >= Vers > Mastery (1176 /
    -- 949 / 891 / 401; Haste first for 76%); Method: Vers over Mastery in M+.
    statPriority = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
    contentStatPriorities = {
        raid    = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
        dungeon = { HASTE = 1, CRIT = 2, VERS = 2.5, MASTERY = 3.5 },
    },

    keyLayoutLabels = { st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 20473,   st = 1, aoe = 1, note = "Most pressed in raid, on every charge" },
        { spellId = 156322,  st = 1, aoe = 1, alt = { 85673 }, note = "Spender (Word of Glory in M+)" },
        { spellId = 19750,   st = 1, aoe = 1, note = "Infusion of Light procs" },
        { spellId = 415091,  st = 1, aoe = 1, note = "M+: most pressed, spend on damage" },
        { spellId = 200025,           aoe = 1, note = "Raid: on cooldown" },
        { spellId = 275773,  st = 2, aoe = 2, note = "Holy Power; on cooldown in M+" },
        { spellId = 375576,           aoe = 2, note = "Raid: after Beacon of Virtue" },
        { spellId = 85222,            aoe = 2, note = "Raid: when Eternal Flame overheals" },
        { spellId = 24275,   st = 2, aoe = 2, alt = { 1241413 }, note = "When it lights up" },
        { spellId = 82326,   st = 2,          note = "No Holy Power, no Infusion" },
        { spellId = 4987,    st = 2, aoe = 2, note = "Dispel" },
        { spellId = 432459,  st = 2, aoe = 2, alt = { 432472 }, note = "M+: Holy Armaments" },
        { spellId = 31884,   st = 3, aoe = 3, note = "Wings" },
        { spellId = 31821,            aoe = 3, note = "Raid cooldown" },
        { spellId = 6940,    st = 3,          note = "External" },
        { spellId = 633,     st = 3,          note = "Emergency" },
        { spellId = 1022,    st = 3,          note = "Physical immunity" },
        { spellId = 498,     st = 3, aoe = 3, note = "Defensive" },
    },
})
