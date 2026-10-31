local OffBeat = _G.OffBeat

-- Discipline Priest, Method 12.1.5 (13 Oct 2026), checked against the top
-- 40 heroic parses on every Venomous Abyss boss (360, ranked by healing)
-- and the top 40 timed runs per Season 2 dungeon (320 runs; Warcraft
-- Logs, Oct 2026). Raid is Voidweaver (Void Blast in 79% of parses); M+ is
-- Oracle (Void Blast in 8% of runs), with Shadow Mend (~5 a minute) as the
-- single-target heal. The sheet and bars follow /ob mode.
--
-- Disc heals through Atonement, so what to press depends on when the next
-- ramp is due: no mistake rules. Evangelism every ~91s, right after a
-- Power Word: Radiance (100% of the top players' Evangelisms), Ultimate
-- Penitence every ~4 min, Void Shield ~6 a minute. Void Blast is logged
-- as Smite too (one for one), so only Smite (585) is counted.
OffBeat:RegisterProfile({
    meta = {
        name = "Discipline Priest",
        specId = 256,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    rotationSpells = {
        { spellId = 17 },      -- Power Word: Shield
        { spellId = 194509 },  -- Power Word: Radiance
        { spellId = 2061 },    -- Flash Heal
        { spellId = 186263 },  -- Shadow Mend
        { spellId = 1253593 }, -- Void Shield
        { spellId = 47540 },   -- Penance
        { spellId = 8092 },    -- Mind Blast
        { spellId = 585 },     -- Smite (and Void Blast, logged as both)
        { spellId = 589 },     -- Shadow Word: Pain
        { spellId = 32379 },   -- Shadow Word: Death
        { spellId = 472433 },  -- Evangelism
        { spellId = 421453 },  -- Ultimate Penitence
    },

    keyCooldown = {
        spellId = 472433,
        name = "Evangelism",
        duration = 0,
    },

    failNudges = {
        { error = "moving", spells = { 585, 194509, 2061, 186263, 8092 }, name = "Cast while moving",
          text = "Moving: Power Word: Shield, Penance, Shadow Word: Pain / Death, Void Shield" },
    },

    idleCooldowns = {
        { spellId = 10060,  name = "Power Infusion" },
        { spellId = 472433, name = "Evangelism", content = "raid" },
    },

    -- Coaching: Evangelism (10s after it). The top players: 2 Penances
    -- (1 Mind Blast, 1 Void Shield) in both contents.
    windows = {
        {
            name = "Evangelism ramp",
            trigger = 472433,
            duration = 10,
            note = "Shield and Flash Heal Atonement first, Radiance into Evangelism and Radiance again, "
                .. "then Mind Blast, Penance, Void Shield, Penance. Top players: 2 Penances.",
            goals = {
                { name = "Penance", spells = { 47540 }, min = 2 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Penances per Evangelism (top 20
    -- per boss). Dungeons (by instance ID): the top 40 timed runs, per
    -- minute in combat (Warcraft Logs' pulls).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts", all = true },
            { name = "Smite / Void Blast", spells = { 585 } },
            { name = "Penance",        spells = { 47540 } },
            { name = "Void Shield",    spells = { 1253593 } },
            { name = "Mind Blast",     spells = { 8092 } },
            { name = "Power Word: Radiance", spells = { 194509 } },
            { name = "Flash Heal / Shadow Mend", spells = { 2061, 186263 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 2, values = {
                { 48.9, 52.0, 53.9 }, { 18.0, 21.5, 24.1 }, { 8.0, 8.6, 9.1 }, { 5.6, 5.8, 6.0 }, { 3.5, 3.7, 3.9 }, { 3.5, 3.8, 4.0 }, { 3.1, 3.9, 4.6 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 2, values = {
                { 50.1, 55.8, 59.3 }, { 15.9, 24.9, 28.4 }, { 8.5, 9.0, 9.7 }, { 6.0, 6.3, 6.7 }, { 4.0, 4.2, 4.4 }, { 3.9, 4.1, 4.2 }, { 2.1, 3.1, 4.2 } } },
            [3445] = { name = "Entombed Sentinels", window = 2, values = {
                { 52.3, 56.8, 58.3 }, { 21.7, 25.7, 27.2 }, { 8.2, 9.0, 9.6 }, { 6.0, 6.3, 6.7 }, { 3.9, 4.2, 4.4 }, { 3.9, 4.1, 4.3 }, { 2.1, 2.9, 4.3 } } },
            [3455] = { name = "Vashnik the Malignant", window = 2, values = {
                { 53.9, 59.7, 62.1 }, { 23.2, 26.8, 31.6 }, { 8.4, 9.2, 9.5 }, { 6.2, 6.5, 6.8 }, { 4.2, 4.3, 4.6 }, { 4.1, 4.2, 4.4 }, { 2.8, 3.7, 5.2 } } },
            [3497] = { name = "The Lost Explorers", window = 2, values = {
                { 52.8, 58.1, 60.8 }, { 19.0, 25.2, 28.8 }, { 8.9, 9.2, 9.6 }, { 6.3, 6.6, 6.9 }, { 4.2, 4.4, 4.6 }, { 4.1, 4.2, 4.4 }, { 2.3, 3.1, 3.8 } } },
            [3420] = { name = "Sszorak", window = 2, values = {
                { 51.8, 55.0, 59.4 }, { 22.0, 24.8, 27.8 }, { 8.5, 9.0, 9.5 }, { 6.2, 6.5, 6.7 }, { 4.1, 4.3, 4.5 }, { 4.0, 4.2, 4.4 }, { 2.3, 3.2, 3.9 } } },
            [3421] = { name = "The Twin Fangs", window = 2, values = {
                { 51.4, 56.9, 59.4 }, { 22.1, 25.9, 28.4 }, { 8.6, 9.1, 9.6 }, { 6.1, 6.4, 6.7 }, { 4.0, 4.3, 4.5 }, { 3.9, 4.0, 4.2 }, { 2.4, 3.1, 4.1 } } },
            [3429] = { name = "The Coiled Altar", window = 2, values = {
                { 56.3, 58.2, 60.5 }, { 25.0, 26.8, 29.1 }, { 8.3, 8.7, 9.2 }, { 6.2, 6.3, 6.6 }, { 4.0, 4.2, 4.3 }, { 4.0, 4.1, 4.2 }, { 3.2, 4.1, 5.0 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 2, values = {
                { 49.8, 55.8, 60.6 }, { 16.4, 25.8, 30.9 }, { 8.5, 9.2, 10.2 }, { 6.1, 6.5, 6.7 }, { 3.9, 4.2, 4.4 }, { 3.6, 4.0, 4.2 }, { 2.3, 3.6, 4.4 } } },
        },
        overall = { name = "all heroic bosses", window = 2, values = {
            { 51.6, 56.3, 59.6 }, { 20.6, 25.2, 28.6 }, { 8.4, 9.0, 9.6 }, { 6.0, 6.4, 6.7 }, { 3.9, 4.2, 4.5 }, { 3.9, 4.1, 4.3 }, { 2.5, 3.4, 4.5 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 2, values = {
                { 42.8, 46.5, 47.9 }, { 11.2, 13.0, 14.8 }, { 9.2, 9.7, 9.9 }, { 5.5, 5.9, 6.1 }, { 3.3, 3.5, 3.7 }, { 0.5, 0.6, 1.5 }, { 4.5, 5.0, 6.4 } } },
            [2825] = { name = "Den of Nalorakk", window = 2, values = {
                { 40.4, 43.7, 45.8 }, { 11.5, 13.4, 15.0 }, { 9.1, 9.6, 9.9 }, { 5.5, 5.7, 5.9 }, { 3.2, 3.5, 3.6 }, { 0.5, 0.7, 1.3 }, { 3.4, 4.2, 4.7 } } },
            [1762] = { name = "Kings' Rest", window = 2, values = {
                { 42.4, 45.1, 47.0 }, { 11.1, 13.7, 15.4 }, { 9.7, 10.0, 10.2 }, { 5.7, 5.9, 6.1 }, { 3.3, 3.5, 3.7 }, { 0.4, 0.5, 1.0 }, { 4.1, 4.7, 5.3 } } },
            [2813] = { name = "Murder Row", window = 2, values = {
                { 43.4, 46.9, 49.6 }, { 10.5, 12.8, 15.4 }, { 9.2, 9.7, 10.1 }, { 5.6, 5.9, 6.1 }, { 3.3, 3.5, 3.8 }, { 0.5, 0.7, 1.6 }, { 4.9, 5.9, 6.7 } } },
            [2521] = { name = "Ruby Life Pools", window = 2, values = {
                { 41.9, 44.2, 47.9 }, { 10.9, 12.7, 13.9 }, { 9.3, 9.6, 10.0 }, { 5.6, 5.9, 6.1 }, { 3.2, 3.5, 3.7 }, { 0.5, 0.6, 1.6 }, { 4.1, 5.0, 5.3 } } },
            [1877] = { name = "Temple of Sethraliss", window = 2, values = {
                { 34.8, 38.0, 42.1 }, { 8.2, 9.4, 10.9 }, { 7.5, 7.7, 9.5 }, { 4.4, 4.7, 5.3 }, { 2.5, 2.8, 3.2 }, { 0.4, 0.7, 1.2 }, { 5.0, 5.4, 6.3 } } },
            [2859] = { name = "The Blinding Vale", window = 2, values = {
                { 43.9, 46.4, 48.7 }, { 11.8, 14.3, 15.9 }, { 9.4, 9.8, 10.1 }, { 5.6, 5.9, 6.1 }, { 3.2, 3.5, 3.8 }, { 0.5, 0.6, 1.3 }, { 4.4, 4.9, 5.5 } } },
            [2923] = { name = "Voidscar Arena", window = 2, values = {
                { 42.6, 44.0, 47.5 }, { 10.4, 12.8, 14.2 }, { 9.2, 9.7, 10.0 }, { 5.5, 5.8, 6.2 }, { 3.2, 3.5, 3.7 }, { 0.5, 1.1, 1.6 }, { 4.7, 5.2, 5.8 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 2, values = {
            { 41.2, 44.6, 47.6 }, { 10.5, 12.7, 14.8 }, { 9.1, 9.7, 10.0 }, { 5.4, 5.8, 6.1 }, { 3.1, 3.5, 3.7 }, { 0.5, 0.6, 1.4 }, { 4.2, 5.0, 5.9 } } },
    },

    -- /ob bars: the keys Holy Priest uses (binds are account-wide), heals
    -- as mouseover macros (the unit under the mouse, else your target).
    -- Shield on 1, Penance on 2, Smite on 3 (Void Blast in Entropic Rift),
    -- Mind Blast on 4, Shadow Word: Pain on 5, Evangelism on Q, Shadow
    -- Word: Death on G, Radiance on E, Void Shield on R; Flash Heal (raid)
    -- or Shadow Mend (M+) on Shift-1. Utility on the Shift keys, Fade on F,
    -- Angelic Feather on Shift-F.
    barLayout = {
        { slot = 1,  key = "1",       macro = { name = "OB PWShield", spells = { 17 }, mouseover = true },
          note = "Power Word: Shield (mouseover): Atonement, right after Penance (Weal and Woe)" },
        { slot = 2,  key = "2",       spellId = 47540, note = "Penance: on cooldown, cancel into Void Blast" },
        { slot = 3,  key = "3",       spellId = 585,   note = "Smite: filler, becomes Void Blast in Entropic Rift (raid ~25 a minute)" },
        { slot = 4,  key = "4",       spellId = 8092,  note = "Mind Blast: on cooldown, before Ultimate Penitence" },
        { slot = 5,  key = "5",       spellId = 589,   note = "Shadow Word: Pain: keep it up" },
        { slot = 6,  key = "Q",       spellId = 472433, note = "Evangelism: ramp, every ~91s, after a Radiance" },
        { slot = 7,  key = "G",       spellId = 32379, note = "Shadow Word: Death: execute, spawns Shadowfiends" },
        { slot = 8,  key = "E",       spellId = 194509, note = "Power Word: Radiance: 2 per ramp" },
        { slot = 67, key = "R",       macro = { name = "OB VoidShield", spells = { 1253593 }, mouseover = true },
          note = "Void Shield (mouseover): your big shield (~6 a minute)" },
        { slot = 61, key = "Shift-1", content = "raid", macro = { name = "OB FlashHeal", spells = { 2061 }, mouseover = true },
          note = "Flash Heal (mouseover): Atonement on yourself at ramp start" },
        { slot = 61, key = "Shift-1", content = "dungeon", macro = { name = "OB ShadowMend", spells = { 186263 }, mouseover = true },
          note = "Shadow Mend (mouseover): single-target heal (~5 a minute in M+)" },
        { slot = 63, key = "Shift-3", spellId = 421453, note = "Ultimate Penitence: every ~4 min, after Mind Blast" },
        { slot = 12, key = "X",       macro = { name = "OB Purify", spells = { 527 }, mouseover = true },
          note = "Purify (mouseover): magic and disease" },
        { slot = 62, key = "Shift-2", macro = { name = "OB PI", spells = { 10060 }, mouseover = true },
          note = "Power Infusion (mouseover): a DPS's cooldowns" },
        { slot = 64, key = "Shift-4", macro = { name = "OB PainSup", spells = { 33206 }, mouseover = true },
          note = "Pain Suppression (mouseover): a tank before a big hit" },
        { slot = 65, key = "Shift-5", spellId = 528,   note = "Dispel Magic: purge an enemy (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 8122,  note = "Psychic Scream (M+)" },
        { slot = 70, key = "F",       spellId = 586,   note = "Fade: 10% less damage with Translucent Image" },
        { slot = 71, key = "Shift-F", spellId = 121536, note = "Angelic Feather: movement" },
        { slot = 55, key = "`",       spellId = 19236, note = "Desperate Prayer: defensive" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5: Voidweaver in
    -- raid, Oracle in M+, as the top players play them.
    rotationSheet = {
        { title = "Evangelism ramp (Voidweaver)", content = "raid", lines = {
            { spellId = 589,     text = "Refresh Shadow Word: Pain" },
            { spellId = 17,      text = "Shield (or Void Shield), Flash Heal on yourself" },
            { spellId = 194509,  text = "Radiance, Evangelism, Radiance" },
            { spellId = 8092,    text = "Mind Blast, Penance, Void Shield" },
            { spellId = 585,     text = "Void Blast until the next Penance" },
        } },
        { title = "Ultimate Penitence ramp (Voidweaver)", content = "raid", lines = {
            { spellId = 194509,  text = "Shield, Flash Heal, 2x Radiance" },
            { spellId = 421453,  text = "Mind Blast, then Ultimate Penitence; Void Shield in the air" },
            { spellId = 47540,   text = "Penance, Void Blast, Shield, Void Blast" },
        } },
        { title = "Damage (raid)", content = "raid", lines = {
            { spellId = 589,   text = "Shadow Word: Pain, Mind Blast, Penance" },
            { spellId = 585,   text = "Void Blast in Entropic Rift (stand still), Smite outside" },
            { spellId = 32379, text = "Shadow Word: Death in execute" },
        } },
        { title = "Mythic+ (Oracle)", content = "dungeon", lines = {
            { spellId = 1253593, text = "Void Shield + Radiance as a mini-ramp before packs hit" },
            { spellId = 589,     text = "Shadow Word: Pain on everything, Mind Blast" },
            { spellId = 47540,   text = "Penance (defensive when someone's low)" },
            { spellId = 186263,  text = "Shadow Mend for heavy single-target damage" },
            { spellId = 32379,   text = "Shadow Word: Death in execute, then Smite" },
        } },
    },

    -- Stats: Method: Haste > Mastery > Crit > Versatility (Voidweaver wants
    -- Haste up to ~1800, Oracle ~1300).
    statPriority = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },

    keyLayoutLabels = { st = "Single", aoe = "Ramp", stLong = "Everyday", aoeLong = "Ramp" },
    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 17,      st = 1, aoe = 1, note = "Atonement, weave after Penance (Weal and Woe)" },
        { spellId = 47540,   st = 1, aoe = 1, note = "Cancel early into Void Blast" },
        { spellId = 8092,    st = 1, aoe = 1, note = "Buffs Ultimate Penitence (Void Infusion)" },
        { spellId = 585,     st = 1, aoe = 2, alt = { 450215 }, note = "Filler / Void Blast" },
        { spellId = 1253593, st = 2, aoe = 1, note = "Main shield, castable while airborne" },
        { spellId = 194509,           aoe = 1, note = "2x in every ramp" },
        { spellId = 589,     st = 2, aoe = 2, note = "Keep it up, on several targets in M+" },
        { spellId = 32379,   st = 2, aoe = 2, note = "Execute, spawns Shadowfiends" },
        { spellId = 2061,    st = 2, aoe = 2, note = "Atonement at ramp start" },
        { spellId = 186263,  st = 2,          note = "M+ single-target heal" },
        { spellId = 527,     st = 2, aoe = 2, note = "Dispel" },
        { spellId = 472433,           aoe = 3, note = "Every ~91s" },
        { spellId = 421453,           aoe = 3, note = "Every ~4 min, after Mind Blast" },
        { spellId = 33206,   st = 3,          note = "External, or on yourself if needed" },
        { spellId = 10060,   st = 3, aoe = 3, note = "On a DPS during their cooldowns" },
        { spellId = 19236,   st = 3, aoe = 3, note = "Self-heal" },
    },
})
