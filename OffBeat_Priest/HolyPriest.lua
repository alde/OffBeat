local OffBeat = _G.OffBeat

-- Holy Priest, Method 12.1.5 (13 Oct 2026), checked against the top 40
-- heroic parses on every Venomous Abyss boss (357, ranked by healing) and
-- the top 40 timed runs per Season 2 dungeon (320 runs; Warcraft Logs,
-- Oct 2026). Every top player is Oracle (nobody casts Prayer of Healing or
-- Halo); Archon rows stay in the Key Layout for those who play it.
-- Apotheosis every ~2 min, Divine Hymn ~2:05. Healing is reactive, so
-- there are no mistake rules.
OffBeat:RegisterProfile({
    meta = {
        name = "Holy Priest",
        specId = 257,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    failNudges = {
        { error = "moving", spells = { 2061, 1262763, 585, 14914 }, name = "Cast while moving",
          text = "Moving: Holy Words, Prayer of Mending, Holy Nova, Angelic Feather" },
    },

    rotationSpells = {
        { spellId = 2061 },    -- Flash Heal
        { spellId = 1262763 }, -- Benediction (Flash Heal after a Holy Word; the ID it's cast as in logs)
        { spellId = 33076 },   -- Prayer of Mending
        { spellId = 2050 },    -- Holy Word: Serenity
        { spellId = 34861 },   -- Holy Word: Sanctify (replaced by Ultimate Serenity)
        { spellId = 596 },     -- Prayer of Healing
        { spellId = 120517 },  -- Halo
        { spellId = 132157 },  -- Holy Nova
        { spellId = 88625 },   -- Holy Word: Chastise
        { spellId = 14914 },   -- Holy Fire
        { spellId = 585 },     -- Smite
        { spellId = 589 },     -- Shadow Word: Pain
        { spellId = 200183 },  -- Apotheosis
        { spellId = 64843 },   -- Divine Hymn
        { spellId = 47788 },   -- Guardian Spirit
        { spellId = 10060 },   -- Power Infusion
    },

    trackedAuras = {
        -- Oracle: spend on Flash Heal. Archon: spend on Prayer of Healing.
        { spellId = 114255, name = "Surge of Light", baseDuration = 20, stacks = true },
        { spellId = 200183, name = "Apotheosis",     baseDuration = 20, stacks = false },
    },

    keyCooldown = {
        spellId = 200183,
        name = "Apotheosis",
        duration = 20,
    },

    -- Power Infusion sitting unused is the costliest idle cooldown in a
    -- group; Halo (Archon) goes "on cooldown as often as possible". Charge
    -- spells (Prayer of Mending, Holy Words) are left out: they'd nag every
    -- time they sit at one charge.
    idleCooldowns = {
        { spellId = 10060,  name = "Power Infusion" },
        { spellId = 120517, name = "Halo" },
    },

    procTracking = {
        { procAura = 114255, consumeSpells = { 2061, 1262755, 596 }, window = 0.5, name = "Surge of Light" },
    },

    -- Bars: same keys as the other OffBeat specs; heals are mouseover macros.
    -- One layout for raid and M+: the top players press the same buttons in
    -- both, only how often differs (Warcraft Logs, Oct 2026: 360 heroic raid
    -- parses, 263 timed +21 runs; per minute raid / M+): Flash Heal and
    -- Benediction 24 / 14, Serenity 8.3 / 5.3, Prayer of Mending 7.4 / 8.8,
    -- Holy Fire 0.5 / 7.1, Smite 1.2 / 3.4, Chastise 0.5 / 2.6. Nobody casts
    -- Prayer of Healing or Halo. The damage keys matter more in keys.
    barLayout = {
        { slot = 1,  key = "1",       macro = { name = "OB Flash Heal", spells = { 2061 }, mouseover = true },
          note = "Flash Heal (mouseover): most pressed; Benediction right after a Holy Word" },
        { slot = 2,  key = "2",       macro = { name = "OB Serenity", spells = { 2050 }, mouseover = true },
          note = "Holy Word: Serenity (mouseover): don't sit on 2 charges" },
        { slot = 3,  key = "3",       macro = { name = "OB PoM", spells = { 33076 }, mouseover = true },
          note = "Prayer of Mending (mouseover): on cooldown" },
        { slot = 4,  key = "4",       spellId = 14914, note = "Holy Fire: M+ damage, ~7 a minute" },
        { slot = 5,  key = "5",       spellId = 585,   note = "Smite: filler" },
        { slot = 6,  key = "Q",       spellId = 200183, note = "Apotheosis" },
        { slot = 7,  key = "G",       spellId = 132157, note = "Holy Nova: packs" },
        { slot = 8,  key = "E",       spellId = 88625, note = "Holy Word: Chastise: M+ damage, ~2.6 a minute" },
        { slot = 67, key = "R",       spellId = 64843, note = "Divine Hymn: raid cooldown" },
        { slot = 12, key = "X",       macro = { name = "OB Purify", spells = { 527 }, mouseover = true }, note = "Purify (mouseover)" },
        { slot = 62, key = "Shift-2", macro = { name = "OB PI", spells = { 10060 }, mouseover = true },
          note = "Power Infusion (mouseover): on a DPS with their cooldowns, every 2 min" },
        { slot = 63, key = "Shift-3", macro = { name = "OB MassDispel", spells = { 32375 }, cursor = true },
          note = "Mass Dispel at your cursor: 3 in 4 top M+ priests use it" },
        { slot = 64, key = "Shift-4", macro = { name = "OB Leap", spells = { 73325 }, mouseover = true },
          note = "Leap of Faith (mouseover)" },
        { slot = 65, key = "Shift-5", spellId = 528,   note = "Dispel Magic: purge an enemy (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 8122,  note = "Psychic Scream: M+ (64% of top runs)" },
        { slot = 70, key = "F",       spellId = 586,   note = "Fade" },
        { slot = 71, key = "Shift-F", spellId = 121536, note = "Angelic Feather: movement" },
        { slot = 55, key = "`",       spellId = 19236, note = "Desperate Prayer: defensive" },
    },

    -- Coaching: Apotheosis (20s). Raid: 5 Holy Word: Serenity and 6
    -- Benedictions; M+: 3 and 4 (top 20 per boss, 4 runs per dungeon).
    windows = {
        {
            name = "Apotheosis (raid)",
            trigger = 200183,
            duration = 20,
            content = "raid",
            note = "Into raid damage with Holy Words below 2 charges: Serenity, Benediction, Flash Heal, "
                .. "Prayer of Mending, Serenity again. Top players: 5 Serenity, 6 Benedictions.",
            goals = {
                { name = "Holy Word: Serenity", spells = { 2050 }, min = 5 },
                { name = "Benediction", spells = { 1262763 }, min = 6 },
            },
        },
        {
            name = "Apotheosis (M+)",
            trigger = 200183,
            duration = 20,
            content = "dungeon",
            note = "Into group damage: Serenity, Benediction, Prayer of Mending. "
                .. "Top players: 3 Serenity, 4 Benedictions.",
            goals = {
                { name = "Holy Word: Serenity", spells = { 2050 }, min = 3 },
                { name = "Benediction", spells = { 1262763 }, min = 4 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses ranked by healing (low/high = middle
    -- half); values follow the order of rates. window = median Serenity
    -- per Apotheosis. The damage spells only count in M+ (and where a boss
    -- leaves room). Dungeons (by instance ID): the top 40 timed runs, per
    -- minute in combat (Warcraft Logs' pulls).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",      all = true },
            { name = "Benediction",         spells = { 1262763 } },
            { name = "Flash Heal",          spells = { 2061 } },
            { name = "Holy Word: Serenity", spells = { 2050 } },
            { name = "Prayer of Mending",   spells = { 33076 } },
            { name = "Holy Fire",           spells = { 14914 } },
            { name = "Holy Word: Chastise", spells = { 88625 } },
            { name = "Holy Nova",           spells = { 132157 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 5, values = {
                { 39.6, 41.9, 42.7 }, { 12.6, 13.2, 14.1 }, { 10.2, 10.7, 11.6 }, { 7.6, 7.9, 8.3 }, { 7.0, 7.2, 7.3 }, { 0.0, 0.1, 0.5 }, nil, { 0.0, 0.3, 0.5 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 5, values = {
                { 41.1, 42.4, 44.6 }, { 12.4, 13.2, 14.2 }, { 10.6, 11.7, 12.6 }, { 7.7, 8.2, 8.8 }, { 7.2, 7.3, 7.6 }, { 0.0, 0.1, 0.3 }, { 0.0, 0.2, 0.4 }, nil } },
            [3445] = { name = "Entombed Sentinels", window = 5, values = {
                { 40.4, 42.0, 44.9 }, { 12.8, 13.5, 14.7 }, { 9.2, 10.3, 11.4 }, { 7.9, 8.2, 9.0 }, { 7.2, 7.5, 8.0 }, nil, nil, nil } },
            [3455] = { name = "Vashnik the Malignant", window = 5, values = {
                { 42.0, 44.2, 46.6 }, { 13.3, 14.1, 14.9 }, { 9.8, 11.1, 13.4 }, { 8.1, 8.6, 8.8 }, { 7.1, 7.4, 7.7 }, nil, nil, nil } },
            [3497] = { name = "The Lost Explorers", window = 5, values = {
                { 41.7, 43.9, 46.3 }, { 13.1, 14.5, 15.2 }, { 8.8, 10.7, 12.1 }, { 8.3, 8.7, 9.4 }, { 7.4, 7.6, 8.0 }, nil, nil, nil } },
            [3420] = { name = "Sszorak", window = 5, values = {
                { 40.3, 43.3, 45.8 }, { 13.4, 14.4, 14.9 }, { 8.5, 9.2, 10.4 }, { 8.5, 8.8, 9.5 }, { 7.3, 7.5, 7.9 }, { 0.0, 0.3, 0.5 }, { 0.0, 0.2, 0.6 }, { 0.0, 0.2, 0.9 } } },
            [3421] = { name = "The Twin Fangs", window = 5, values = {
                { 40.6, 42.4, 44.2 }, { 12.8, 13.2, 14.1 }, { 10.1, 10.9, 11.9 }, { 7.9, 8.1, 8.6 }, { 7.1, 7.3, 7.5 }, nil, nil, nil } },
            [3429] = { name = "The Coiled Altar", window = 5, values = {
                { 42.4, 44.2, 46.0 }, { 13.1, 13.6, 14.8 }, { 11.1, 11.9, 13.0 }, { 8.5, 8.7, 9.0 }, { 7.1, 7.3, 7.7 }, nil, nil, { 0.0, 0.4, 0.8 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 5, values = {
                { 41.3, 43.7, 46.2 }, { 11.2, 12.1, 13.0 }, { 9.4, 11.9, 14.0 }, { 6.9, 7.6, 8.3 }, { 7.1, 7.4, 7.7 }, { 0.0, 0.6, 1.2 }, { 0.0, 0.3, 1.0 }, nil } },
        },
        overall = { name = "all heroic bosses", window = 5, values = {
            { 41.1, 43.2, 45.2 }, { 12.7, 13.5, 14.5 }, { 9.5, 10.9, 12.4 }, { 7.8, 8.4, 8.9 }, { 7.2, 7.4, 7.7 }, nil, nil, nil } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 3, values = {
                { 42.5, 45.5, 47.6 }, { 7.8, 8.7, 9.3 }, { 4.2, 6.2, 7.4 }, { 4.6, 5.1, 5.4 }, { 7.9, 8.3, 9.2 }, { 5.6, 8.2, 9.4 }, { 2.0, 2.7, 3.4 }, { 0.2, 1.5, 3.3 } } },
            [2825] = { name = "Den of Nalorakk", window = 3, values = {
                { 40.3, 41.8, 44.5 }, { 6.5, 7.1, 7.8 }, { 2.8, 4.0, 5.7 }, { 4.0, 4.5, 4.9 }, { 7.6, 8.1, 9.0 }, { 5.9, 7.4, 9.7 }, { 2.1, 2.7, 3.4 }, { 0.0, 1.1, 2.6 } } },
            [1762] = { name = "Kings' Rest", window = 2, values = {
                { 39.8, 43.3, 47.0 }, { 6.9, 7.5, 8.0 }, { 3.4, 4.5, 5.6 }, { 4.1, 4.6, 4.9 }, { 7.9, 8.7, 9.4 }, { 5.9, 8.5, 9.3 }, { 2.2, 2.9, 3.3 }, { 0.0, 0.8, 1.9 } } },
            [2813] = { name = "Murder Row", window = 4, values = {
                { 42.0, 44.9, 47.5 }, { 8.8, 9.6, 10.3 }, { 4.9, 6.0, 8.0 }, { 5.2, 5.7, 6.1 }, { 8.4, 8.9, 9.5 }, { 5.3, 6.9, 8.4 }, { 1.9, 2.5, 2.9 }, { 0.0, 0.7, 1.8 } } },
            [2521] = { name = "Ruby Life Pools", window = 3, values = {
                { 41.7, 44.2, 46.4 }, { 8.0, 8.7, 9.3 }, { 3.8, 4.9, 6.6 }, { 4.8, 5.1, 5.4 }, { 8.1, 8.7, 9.0 }, { 6.3, 7.7, 9.2 }, { 2.1, 2.8, 3.3 }, { 0.0, 0.4, 1.4 } } },
            [1877] = { name = "Temple of Sethraliss", window = 3, values = {
                { 41.1, 43.4, 45.6 }, { 8.0, 8.7, 9.4 }, { 4.8, 5.8, 6.9 }, { 5.0, 5.3, 5.8 }, { 8.3, 8.8, 9.3 }, { 5.2, 7.0, 7.7 }, { 1.8, 2.4, 2.8 }, { 0.1, 0.9, 2.4 } } },
            [2859] = { name = "The Blinding Vale", window = 3, values = {
                { 42.4, 45.3, 47.6 }, { 8.3, 8.7, 9.3 }, { 4.0, 5.7, 7.5 }, { 4.6, 5.0, 5.4 }, { 7.6, 8.3, 9.0 }, { 5.1, 7.3, 9.5 }, { 1.9, 2.7, 3.4 }, { 0.1, 1.3, 2.7 } } },
            [2923] = { name = "Voidscar Arena", window = 4, values = {
                { 42.0, 43.9, 46.5 }, { 7.7, 8.4, 9.0 }, { 4.0, 5.7, 6.3 }, { 4.6, 5.1, 5.4 }, { 8.0, 8.4, 9.3 }, { 6.0, 7.6, 8.6 }, { 2.0, 2.7, 3.2 }, { 0.0, 1.0, 2.1 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 3, values = {
            { 41.2, 44.2, 46.6 }, { 7.6, 8.4, 9.3 }, { 3.9, 5.4, 6.7 }, { 4.6, 5.0, 5.5 }, { 7.9, 8.5, 9.2 }, { 5.6, 7.5, 9.1 }, { 2.0, 2.7, 3.2 }, { 0.0, 0.9, 2.2 } } },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Oracle: every
    -- top player, raid and M+).
    rotationSheet = {
        { title = "Raid healing", content = "raid", lines = {
            { spellId = 33076,   text = "Prayer of Mending at 2 charges" },
            { spellId = 2050,    text = "Holy Words before they reach 2 charges" },
            { spellId = 1262763, text = "Benediction right after a Holy Word" },
            { spellId = 33076,   text = "Prayer of Mending, then Holy Words" },
            { spellId = 2061,    text = "Flash Heal (Surge of Light procs)" },
        } },
        { title = "Mythic+ healing", content = "dungeon", lines = {
            { spellId = 33076,   text = "Prayer of Mending at 2 charges" },
            { spellId = 2050,    text = "Serenity at 2 charges, then Benediction" },
            { spellId = 33076,   text = "Prayer of Mending, Serenity" },
            { spellId = 2061,    text = "Flash Heal" },
        } },
        { title = "Damage", lines = {
            { spellId = 88625,  text = "Holy Word: Chastise" },
            { spellId = 14914,  text = "Holy Fire on cooldown (M+: ~7.5 a minute)" },
            { spellId = 585,    text = "Smite, or Holy Nova on 4+ targets" },
        } },
        { title = "Cooldowns", lines = {
            { spellId = 200183, text = "Apotheosis with Holy Words below 2 charges (~every 2 min)" },
            { spellId = 64843,  text = "Divine Hymn into big group damage" },
            { spellId = 47788,  text = "Guardian Spirit on a tank about to die" },
        } },
    },

    -- Stats: Method: raid Crit > Mastery > Versatility > Haste; M+ Haste >
    -- Versatility = Crit > Mastery.
    statPriority = { CRIT = 1, MASTERY = 2, VERS = 3, HASTE = 4 },
    contentStatPriorities = {
        raid = { CRIT = 1, MASTERY = 2, VERS = 3, HASTE = 4 },
        dungeon = { HASTE = 1, VERS = 2, CRIT = 2, MASTERY = 4 },
    },

    keyLayoutLabels = { st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Damage spells are listed in both contexts.
    keyLayout = {
        { spellId = 2061,    st = 1,          note = "Surge of Light (Oracle)" },
        { spellId = 1262763, st = 1,          note = "Right after a Holy Word" },
        { spellId = 33076,   st = 1, aoe = 1, note = "Never sit on 2 charges" },
        { spellId = 2050,    st = 1, aoe = 1, note = "Group heal too with Ultimate Serenity, no 2 charges" },
        { spellId = 34861,            aoe = 1, note = "Only without Ultimate Serenity" },
        { spellId = 596,              aoe = 1, note = "Archon spam, Surge of Light. Mana heavy" },
        { spellId = 120517,  st = 2, aoe = 2, note = "Archon: on cooldown" },
        { spellId = 132157,           aoe = 2, note = "Lightburst, or 4+ targets for damage" },
        { spellId = 527,     st = 2, aoe = 2, note = "Dispel" },
        { spellId = 88625,   st = 2, aoe = 2, note = "Damage, triggers Empyreal Blaze" },
        { spellId = 14914,   st = 2, aoe = 2, note = "Damage, on cooldown if talented" },
        { spellId = 585,     st = 2, aoe = 2, note = "Damage filler" },
        { spellId = 589,     st = 2, aoe = 2, note = "Damage, keep up without Holy Fire" },
        { spellId = 47788,   st = 3,          note = "External cheat death" },
        { spellId = 200183,  st = 3, aoe = 3, note = "Not with Holy Words on 2 charges" },
        { spellId = 64843,            aoe = 3, note = "Raid cooldown" },
        { spellId = 10060,   st = 3, aoe = 3, note = "On a DPS during their cooldowns" },
        { spellId = 19236,   st = 3, aoe = 3, note = "Self-heal" },
    },
})
