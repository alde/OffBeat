local OffBeat = _G.OffBeat

-- Method 12.1 (updated 17 Sep 2026). Covers both hero trees: Oracle (Flash
-- Heal / Prayer of Mending focus) and Archon (Prayer of Healing, Halo).
-- Healing is reactive, so there are no mistake rules: the profile is a Key
-- Layout, a few "use on cooldown" nags and Surge of Light tracking.
OffBeat:RegisterProfile({
    meta = {
        name = "Holy Priest",
        specId = 257,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method 12.1 (17 Sep 2026)",
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
        { slot = 61, key = "Shift-1", macro = { name = "OB GSpirit", spells = { 47788 }, mouseover = true },
          note = "Guardian Spirit (mouseover): external" },
        { slot = 62, key = "Shift-2", macro = { name = "OB PI", spells = { 10060 }, mouseover = true },
          note = "Power Infusion (mouseover): on a DPS with their cooldowns, every 2 min" },
        { slot = 63, key = "Shift-3", macro = { name = "OB MassDispel", spells = { 32375 }, cursor = true },
          note = "Mass Dispel at your cursor: 3 in 4 top M+ priests use it" },
        { slot = 64, key = "Shift-4", macro = { name = "OB Leap", spells = { 73325 }, mouseover = true },
          note = "Leap of Faith (mouseover)" },
        { slot = 65, key = "Shift-5", spellId = 528,   note = "Dispel Magic: purge an enemy (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 8122,  note = "Psychic Scream: M+ (64% of top runs)" },
        { slot = 70, key = "F",       spellId = 586,   note = "Fade (Angelic Feather goes on your Shift-F)" },
        { slot = 55, key = "`",       spellId = 19236, note = "Desperate Prayer: defensive" },
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
