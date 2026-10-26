local OffBeat = _G.OffBeat

-- Enhancement Shaman, Method 12.1.5 (13 Oct 2026), checked against the top
-- 40 heroic parses on every Venomous Abyss boss (360) and the top 40 timed
-- runs per Season 2 dungeon (+23 / +24, 320 runs; Warcraft Logs, Oct
-- 2026). All 680 are Stormbringer, the build Method recommends for all
-- content (it calls Totemic undertuned: no Surging Totem, Sundering or
-- Primordial Storm in any log). All of them take Ascendance over Doom
-- Winds as the button: Doom Winds only comes as a proc (the logs show it
-- ~11 times a minute, cast by itself) and isn't pressed.
--
-- The rotation is the same in raid and M+: Stormstrike (Windstrike in
-- Ascendance), Crash Lightning every ~6s, Voltaic Blaze every ~11s, and
-- Maelstrom Weapon on Lightning Bolt (raid) or Chain Lightning (M+), with
-- Tempest replacing Lightning Bolt when it procs. Lava Lash is a filler
-- (~1.8 a minute) and Ascendance goes out every ~2:05.
OffBeat:RegisterProfile({
    meta = {
        name = "Enhancement Shaman",
        specId = 263,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Every spell here is pressed by all of the top players, raid and M+.
    rotationSpells = {
        { spellId = 17364 },  -- Stormstrike
        { spellId = 115356 }, -- Windstrike (Stormstrike during Ascendance)
        { spellId = 187874 }, -- Crash Lightning
        { spellId = 188196 }, -- Lightning Bolt (Maelstrom Weapon spender)
        { spellId = 188443 }, -- Chain Lightning (Maelstrom Weapon spender, 2+ targets)
        { spellId = 452201 }, -- Tempest (replaces Lightning Bolt, Stormbringer)
        { spellId = 470057 }, -- Voltaic Blaze
        { spellId = 60103 },  -- Lava Lash
        { spellId = 114051 }, -- Ascendance
    },

    -- Lava Lash inside Ascendance: 0.2% of the top raid players' Lava
    -- Lashes (3,202) and 0.1% in M+ (11,889) land in its 15s; Windstrike,
    -- Crash Lightning and Maelstrom spenders fill it. Read from your casts,
    -- so it works while the game hides auras.
    mistakes = {
        {
            type = "bad_cast",
            name = "Lava Lash in Ascendance",
            description = "Inside Ascendance press Windstrike, Crash Lightning and Lightning Bolt / Tempest, not Lava Lash",
            spells = { 60103 },
            when = { recent = 114051, within = 15 },
        },
    },

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through.
    trackedAuras = {
        { spellId = 344179,  name = "Maelstrom Weapon", baseDuration = 30, stacks = true },
        { spellId = 114051,  name = "Ascendance",       baseDuration = 15, stacks = false },
        { spellId = 466772,  name = "Doom Winds",       baseDuration = 8,  stacks = false },
        { spellId = 454015,  name = "Tempest",          baseDuration = 30, stacks = true },
        { spellId = 201846,  name = "Stormsurge",       baseDuration = 12, stacks = true },
        { spellId = 198300,  name = "Converging Storms", baseDuration = 12, stacks = true },
        { spellId = 1252415, name = "Crash Lightning",  baseDuration = 12, stacks = false },
    },

    keyCooldown = {
        spellId = 114051,
        name = "Ascendance",
        duration = 15,
    },

    failNudges = {
        { error = "range", spells = { 17364, 115356, 187874, 60103 }, name = "Melee out of range",
          text = "Out of range: Lightning Bolt / Chain Lightning on Maelstrom, Voltaic Blaze, Feral Lunge back in" },
    },

    -- On cooldown for every top player: Crash Lightning every ~6s (Method:
    -- keep it, Stormstrike and Lava Lash cycling for Elemental Tempo),
    -- Voltaic Blaze every ~11s and Ascendance every ~2:05.
    idleCooldowns = {
        { spellId = 114051, name = "Ascendance" },
        { spellId = 187874, name = "Crash Lightning" },
        { spellId = 470057, name = "Voltaic Blaze" },
    },

    -- Coaching: Ascendance. In its 15s the top raid players cast 10
    -- Windstrikes (median on every boss, 11 on Nek'zali and The Lost
    -- Explorers), 10 Lightning Bolts / Chain Lightnings, 4 Crash Lightnings
    -- and 3 Tempests (13 spenders with Tempest); Tempest is the first press
    -- after Ascendance 71% of the time. M+: 9 Windstrikes, 11 spenders.
    windows = {
        {
            name = "Ascendance (raid)",
            trigger = 114051,
            duration = 15,
            content = "raid",
            note = "Tempest first, then Windstrike on cooldown, Crash Lightning and every Maelstrom Weapon on "
                .. "Lightning Bolt. Top players: 10 Windstrikes, 13 Lightning Bolts / Tempests.",
            goals = {
                { name = "Windstrike", spells = { 115356 }, min = 10 },
                { name = "Lightning Bolt / Chain Lightning / Tempest", spells = { 188196, 188443, 452201 }, min = 13 },
            },
        },
        {
            name = "Ascendance (M+)",
            trigger = 114051,
            duration = 15,
            content = "dungeon",
            note = "Into a pack: Tempest, Crash Lightning, Windstrike on cooldown and Maelstrom Weapon on "
                .. "Chain Lightning. Top players: 9 Windstrikes, 11 spenders.",
            goals = {
                { name = "Windstrike", spells = { 115356 }, min = 9 },
                { name = "Lightning Bolt / Chain Lightning / Tempest", spells = { 188196, 188443, 452201 }, min = 11 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Windstrikes per Ascendance.
    -- Dungeons (by instance ID): the top 40 timed runs, per minute in combat
    -- (Warcraft Logs' pulls). Raid spends Maelstrom on Lightning Bolt, M+ on
    -- Chain Lightning.
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",  all = true },
            { name = "Stormstrike / Windstrike", spells = { 17364, 115356 } },
            { name = "Crash Lightning", spells = { 187874 } },
            { name = "Lightning Bolt / Chain Lightning", spells = { 188196, 188443 } },
            { name = "Tempest",         spells = { 452201 } },
            { name = "Voltaic Blaze",   spells = { 470057 } },
            { name = "Lava Lash",       spells = { 60103 } },
            { name = "Ascendance",      spells = { 114051 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 10, values = {
                { 51.8, 53.1, 54.2 }, { 18.5, 19.4, 20.1 }, { 8.2, 8.9, 9.3 }, { 12.7, 13.4, 13.8 }, { 4.3, 4.5, 4.8 }, { 4.8, 5.0, 5.2 }, { 1.2, 1.5, 1.9 }, { 0.5, 0.5, 0.5 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 11, values = {
                { 62.5, 64.4, 66.1 }, { 23.5, 24.4, 25.1 }, { 9.9, 10.5, 11.1 }, { 15.1, 16.4, 17.3 }, { 5.2, 5.6, 6.1 }, { 5.3, 5.5, 5.7 }, { 1.3, 1.7, 2.3 }, { 0.6, 0.6, 0.6 } } },
            [3445] = { name = "Entombed Sentinels", window = 10, values = {
                { 60.0, 61.3, 63.4 }, { 21.8, 22.8, 24.3 }, { 9.5, 10.1, 10.6 }, { 14.6, 15.5, 16.3 }, { 4.9, 5.2, 5.5 }, { 5.2, 5.4, 5.5 }, { 1.3, 1.8, 2.5 }, { 0.5, 0.6, 0.6 } } },
            [3455] = { name = "Vashnik the Malignant", window = 10, values = {
                { 62.6, 64.0, 65.7 }, { 23.6, 24.5, 25.8 }, { 9.7, 10.0, 10.6 }, { 15.4, 16.0, 16.9 }, { 5.1, 5.5, 6.0 }, { 4.9, 5.3, 5.5 }, { 1.6, 2.0, 2.9 }, { 0.5, 0.6, 0.6 } } },
            [3497] = { name = "The Lost Explorers", window = 11, values = {
                { 64.8, 66.1, 68.9 }, { 23.2, 24.8, 27.2 }, { 10.0, 10.6, 11.1 }, { 15.7, 17.0, 18.7 }, { 5.3, 6.0, 6.6 }, { 5.1, 5.5, 5.6 }, { 1.1, 1.8, 2.5 }, { 0.7, 0.7, 0.8 } } },
            [3420] = { name = "Sszorak", window = 10, values = {
                { 64.2, 65.3, 67.3 }, { 23.7, 24.8, 25.4 }, { 10.2, 10.7, 11.1 }, { 15.2, 16.3, 17.1 }, { 5.3, 5.6, 6.2 }, { 5.3, 5.6, 5.8 }, { 1.6, 2.1, 2.8 }, { 0.6, 0.6, 0.7 } } },
            [3421] = { name = "The Twin Fangs", window = 10, values = {
                { 63.3, 64.8, 66.1 }, { 23.0, 24.0, 24.7 }, { 9.9, 10.6, 11.1 }, { 15.4, 16.3, 17.4 }, { 5.3, 5.5, 5.9 }, { 5.4, 5.5, 5.6 }, { 1.6, 1.9, 2.4 }, { 0.6, 0.7, 0.7 } } },
            [3429] = { name = "The Coiled Altar", window = 10, values = {
                { 59.2, 60.4, 62.0 }, { 21.7, 22.5, 23.4 }, { 9.9, 10.3, 10.7 }, { 14.0, 14.7, 15.7 }, { 4.8, 5.2, 5.5 }, { 5.3, 5.4, 5.6 }, { 1.4, 1.7, 2.3 }, { 0.5, 0.6, 0.6 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 10, values = {
                { 62.1, 65.0, 66.9 }, { 22.6, 24.1, 25.0 }, { 9.9, 10.4, 11.0 }, { 15.5, 16.8, 17.4 }, { 5.2, 5.6, 6.2 }, { 5.3, 5.5, 5.7 }, { 1.3, 1.8, 2.3 }, { 0.6, 0.7, 0.7 } } },
        },
        overall = { name = "all heroic bosses", window = 10, values = {
            { 60.4, 63.4, 66.0 }, { 22.2, 23.7, 24.9 }, { 9.6, 10.3, 10.9 }, { 14.6, 15.8, 17.1 }, { 4.9, 5.4, 5.9 }, { 5.1, 5.4, 5.6 }, { 1.4, 1.8, 2.4 }, { 0.5, 0.6, 0.7 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 9, values = {
                { 52.4, 54.4, 55.7 }, { 18.7, 19.3, 19.9 }, { 9.0, 9.6, 9.9 }, { 13.0, 14.0, 14.9 }, { 4.7, 4.9, 5.1 }, { 4.8, 5.0, 5.2 }, { 1.0, 1.3, 1.7 }, { 0.5, 0.5, 0.5 } } },
            [2825] = { name = "Den of Nalorakk", window = 9, values = {
                { 51.4, 52.7, 54.4 }, { 18.1, 19.1, 19.9 }, { 8.4, 8.9, 9.6 }, { 12.5, 13.4, 14.4 }, { 4.4, 4.8, 4.9 }, { 4.6, 4.9, 5.1 }, { 0.9, 1.2, 1.9 }, { 0.5, 0.5, 0.5 } } },
            [1762] = { name = "Kings' Rest", window = 9, values = {
                { 52.9, 54.1, 55.2 }, { 18.9, 19.5, 20.2 }, { 8.5, 9.2, 9.7 }, { 12.6, 13.4, 14.3 }, { 4.5, 4.6, 4.8 }, { 4.8, 5.1, 5.3 }, { 1.0, 1.4, 1.6 }, { 0.5, 0.5, 0.5 } } },
            [2813] = { name = "Murder Row", window = 9, values = {
                { 52.6, 53.7, 55.4 }, { 18.2, 19.1, 20.1 }, { 8.7, 9.3, 9.7 }, { 13.2, 14.3, 14.7 }, { 4.6, 4.8, 5.0 }, { 4.6, 4.9, 5.2 }, { 0.9, 1.1, 1.5 }, { 0.5, 0.5, 0.5 } } },
            [2521] = { name = "Ruby Life Pools", window = 9, values = {
                { 54.4, 55.8, 57.2 }, { 19.2, 19.6, 20.5 }, { 9.3, 9.7, 10.2 }, { 13.8, 14.9, 15.3 }, { 4.9, 5.1, 5.2 }, { 4.8, 5.1, 5.3 }, { 0.9, 1.2, 1.6 }, { 0.5, 0.5, 0.5 } } },
            [1877] = { name = "Temple of Sethraliss", window = 9, values = {
                { 51.5, 53.3, 54.6 }, { 18.2, 19.1, 19.6 }, { 8.4, 9.4, 9.8 }, { 13.0, 13.6, 14.1 }, { 4.5, 4.7, 4.9 }, { 4.7, 5.0, 5.3 }, { 0.9, 1.1, 1.5 }, { 0.4, 0.5, 0.5 } } },
            [2859] = { name = "The Blinding Vale", window = 9, values = {
                { 55.0, 55.9, 57.4 }, { 19.2, 19.9, 20.9 }, { 9.0, 9.8, 10.1 }, { 13.4, 14.3, 15.4 }, { 4.8, 5.0, 5.2 }, { 4.9, 5.1, 5.3 }, { 1.1, 1.4, 1.9 }, { 0.5, 0.5, 0.5 } } },
            [2923] = { name = "Voidscar Arena", window = 9, values = {
                { 52.9, 54.1, 56.1 }, { 19.2, 19.7, 20.5 }, { 8.7, 9.3, 9.7 }, { 12.8, 13.8, 14.5 }, { 4.6, 4.8, 5.0 }, { 4.8, 5.1, 5.3 }, { 1.0, 1.1, 1.6 }, { 0.5, 0.5, 0.5 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 9, values = {
            { 52.6, 54.3, 55.8 }, { 18.7, 19.4, 20.2 }, { 8.7, 9.4, 9.9 }, { 13.0, 13.9, 14.7 }, { 4.6, 4.8, 5.1 }, { 4.7, 5.0, 5.2 }, { 1.0, 1.2, 1.6 }, { 0.5, 0.5, 0.5 } } },
    },

    -- /ob bars: role for role on the keys your other specs use (binds are
    -- account-wide): Stormstrike on 1 (Windstrike shows up there during
    -- Ascendance), Crash Lightning on 2, the Maelstrom spenders on 3-4
    -- (Tempest shows up on Lightning Bolt's button), Lava Lash on 5,
    -- Voltaic Blaze (every ~11s) on Q, Ascendance on Shift-1. Feral Lunge
    -- on G, Spirit Walk on F, interrupt Shift-E, Capacitor Totem Shift-Q,
    -- defensives on ` / Shift-`. Heroism / Bloodlust sits on F5, out of the
    -- way so you don't press it by accident. One layout for raid and M+.
    -- Hex, Ghost Wolf and anything not listed are left alone.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 17364,  note = "Stormstrike: most pressed; Windstrike during Ascendance" },
        { slot = 2,  key = "2",       spellId = 187874, note = "Crash Lightning: on cooldown (~6s), 2+ targets first" },
        { slot = 3,  key = "3",       spellId = 188196, note = "Lightning Bolt: Maelstrom Weapon spender (raid); Tempest shows up here" },
        { slot = 4,  key = "4",       spellId = 188443, note = "Chain Lightning: Maelstrom Weapon at 2+ targets (M+)" },
        { slot = 5,  key = "5",       spellId = 60103,  note = "Lava Lash: filler, never in Ascendance" },
        { slot = 6,  key = "Q",       spellId = 470057, note = "Voltaic Blaze: every ~11s, after the melee strikes" },
        { slot = 61, key = "Shift-1", spellId = 114051, note = "Ascendance: every ~2 min, Tempest right after" },
        { slot = 7,  key = "G",       spellId = 196884, note = "Feral Lunge: back to the target (96% of top M+ runs)" },
        { slot = 62, key = "Shift-2", macro = { name = "OB WindRush", spells = { 192077 }, cursor = true },
          note = "Wind Rush Totem at your cursor (89% of top M+ runs)" },
        { slot = 63, key = "Shift-3", spellId = 8004,   note = "Healing Surge: self heal (80% of top M+ runs)" },
        { slot = 64, key = "Shift-4", spellId = 383013, note = "Poison Cleansing Totem (58% of top M+ runs)" },
        { slot = 65, key = "Shift-5", spellId = 370,    note = "Purge: an enemy buff (M+)" },
        { slot = 50, key = "Shift-E", spellId = 57994,  note = "Wind Shear: interrupt" },
        { slot = 66, key = "Shift-Q", spellId = 192058, note = "Capacitor Totem: stun (95% of top M+ runs)" },
        { slot = 12, key = "X",       macro = { name = "OB CleanseSpirit", spells = { 51886 }, mouseover = true },
          note = "Cleanse Spirit (mouseover): curses" },
        { slot = 70, key = "F",       spellId = 58875,  note = "Spirit Walk: movement, breaks roots" },
        { slot = 25, key = "F5",      spellId = 32182,  alt = { 2825 }, note = "Heroism / Bloodlust: out of the way on purpose" },
        { slot = 55, key = "`",       spellId = 108271, note = "Astral Shift: defensive" },
        { slot = 56, key = "Shift-`", spellId = 198103, note = "Earth Elemental: more health (Primordial Bond)" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Stormbringer),
    -- checked against the top parses and runs.
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 470057, text = "Voltaic Blaze, Ascendance" },
            { spellId = 452201, text = "Tempest right after Ascendance (71% of top players)" },
            { spellId = 187874, text = "Crash Lightning, then Windstrike" },
        } },
        { title = "Ascendance (~2 min)", lines = {
            { spellId = 115356, text = "Windstrike on cooldown: 10 in 15s for top players" },
            { spellId = 188196, text = "Every Maelstrom Weapon on Lightning Bolt / Tempest (Chain Lightning at 2+)" },
            { spellId = 60103,  text = "No Lava Lash inside it" },
        } },
        { title = "Single target", lines = {
            { spellId = 470057, text = "Voltaic Blaze (filler after the strikes, ~5 a minute)" },
            { spellId = 187874, text = "Crash Lightning on cooldown" },
            { spellId = 452201, text = "Tempest at 10 Maelstrom Weapon, else Lightning Bolt at 10" },
            { spellId = 17364,  text = "Stormstrike, then Lava Lash" },
            { spellId = 188196, text = "Lightning Bolt at 5+ only with nothing else to press" },
            { text = "Spend late: every stack spent refunds cooldowns (Elemental Tempo)" },
        } },
        { title = "AoE (2+) and M+", lines = {
            { spellId = 188443, text = "Chain Lightning instead of Lightning Bolt (top M+: ~9 a minute)" },
            { spellId = 187874, text = "Crash Lightning first on every pack" },
        } },
    },

    -- Stats: the ratings the top players actually wear (Warcraft Logs, 360
    -- raid parses and 302 M+ runs): Mastery > Crit = Haste > Vers (median
    -- raid 1158 / 998 / 947 / 105, M+ 1194 / 951 / 961 / 107; Mastery first
    -- for 66% / 79%), matching Method (Mastery >= Haste > Crit >= Vers).
    statPriority = { MASTERY = 1, HASTE = 2, CRIT = 2, VERS = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 17364,  st = 1, aoe = 1, alt = { 115356 }, note = "Most pressed; Windstrike in Ascendance" },
        { spellId = 187874, st = 1, aoe = 1, note = "Every ~6s" },
        { spellId = 188196, st = 1, aoe = 2, alt = { 452201 }, note = "Maelstrom spender; Tempest" },
        { spellId = 188443, st = 2, aoe = 1, note = "Maelstrom spender at 2+" },
        { spellId = 470057, st = 2, aoe = 2, note = "Every ~11s" },
        { spellId = 60103,  st = 2, aoe = 2, note = "Filler" },
        { spellId = 114051, st = 3, aoe = 3, note = "Every ~2 min" },
        { spellId = 196884, st = 3, aoe = 3, note = "Gap closer" },
        { spellId = 57994,  st = 2, aoe = 2, note = "Interrupt" },
    },
})
