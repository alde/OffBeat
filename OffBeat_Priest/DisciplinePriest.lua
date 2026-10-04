local OffBeat = _G.OffBeat

-- Method 12.1 (updated 17 Sep 2026). Covers both hero trees: Voidweaver
-- (Void Blast, Void Shield, Entropic Rift) and Oracle (double Penance).
-- Disc heals through Atonement, so the two contexts are everyday play and
-- ramps (Evangelism / Ultimate Penitence). No mistake rules: what to press
-- depends on when the next ramp is due. The one idle nag is Power Infusion.
OffBeat:RegisterProfile({
    meta = {
        name = "Discipline Priest",
        specId = 256,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method 12.1 (17 Sep 2026)",
    },

    rotationSpells = {
        { spellId = 17 },      -- Power Word: Shield
        { spellId = 194509 },  -- Power Word: Radiance
        { spellId = 2061 },    -- Flash Heal
        { spellId = 1253593 }, -- Void Shield (Voidweaver)
        { spellId = 47540 },   -- Penance
        { spellId = 8092 },    -- Mind Blast
        { spellId = 450405 },  -- Void Blast (Voidweaver)
        { spellId = 585 },     -- Smite
        { spellId = 589 },     -- Shadow Word: Pain
        { spellId = 32379 },   -- Shadow Word: Death
        { spellId = 472433 },  -- Evangelism
        { spellId = 421453 },  -- Ultimate Penitence
        { spellId = 34433 },   -- Shadowfiend
        { spellId = 62618 },   -- Power Word: Barrier
        { spellId = 33206 },   -- Pain Suppression
        { spellId = 10060 },   -- Power Infusion
    },

    keyCooldown = {
        spellId = 472433,
        name = "Evangelism",
        duration = 0,
    },

    idleCooldowns = {
        { spellId = 10060, name = "Power Infusion" },
    },

    keyLayoutLabels = { st = "Single", aoe = "Ramp", stLong = "Everyday", aoeLong = "Ramp" },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 17,      st = 1, aoe = 1, note = "Atonement, weave after Penance (Weal and Woe)" },
        { spellId = 47540,   st = 1, aoe = 1, note = "Cancel early into Void Blast" },
        { spellId = 8092,    st = 1, aoe = 1, note = "Buffs Ultimate Penitence (Void Infusion)" },
        { spellId = 450405,  st = 1, aoe = 1, note = "Voidweaver: chain it in Entropic Rift" },
        { spellId = 585,     st = 1, aoe = 2, note = "Filler" },
        { spellId = 194509,           aoe = 1, note = "2x in every ramp" },
        { spellId = 589,     st = 2, aoe = 2, note = "Keep it up, on several targets in M+" },
        { spellId = 32379,   st = 2, aoe = 2, note = "Execute, spawns Shadowfiends" },
        { spellId = 2061,    st = 2, aoe = 2, note = "Atonement at ramp start" },
        { spellId = 1253593,          aoe = 2, note = "Voidweaver, castable while airborne" },
        { spellId = 527,     st = 2, aoe = 2, note = "Dispel" },
        { spellId = 472433,           aoe = 3, note = "Ramp cooldown" },
        { spellId = 421453,           aoe = 3, note = "Ramp cooldown, after Mind Blast" },
        { spellId = 34433,   st = 3, aoe = 3, note = "With Shadow Word: Death snipes" },
        { spellId = 62618,            aoe = 3, note = "Raid cooldown" },
        { spellId = 33206,   st = 3,          note = "External, or on yourself if needed" },
        { spellId = 10060,   st = 3, aoe = 3, note = "On a DPS during their cooldowns" },
        { spellId = 19236,   st = 3, aoe = 3, note = "Self-heal" },
    },
})
