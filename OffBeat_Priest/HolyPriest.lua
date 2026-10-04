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
        { spellId = 1262755 }, -- Benediction (upgraded Flash Heal)
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

    keyLayoutLabels = { st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Damage spells are listed in both contexts.
    keyLayout = {
        { spellId = 2061,    st = 1,          note = "Surge of Light (Oracle)" },
        { spellId = 1262755, st = 1,          note = "Right after a Holy Word" },
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
