local OffBeat = _G.OffBeat

-- Augmentation Evoker, Method 12.1 (25 Aug 2026), checked against the top 40
-- heroic parses on every Venomous Abyss boss (Warcraft Logs, Oct 2026,
-- ranked by damage including what Aug adds to others). All of them play
-- Chronowarden, which Method also recommends for raid and high keys, so
-- this is a Chronowarden profile; talents you don't have are ignored.
--
-- Augmentation's damage is mostly the buffs: Ebon Might (the top players
-- keep it up 85% of the fight) and Prescience on two DPS. Fire Breath,
-- Upheaval and Eruption extend Ebon Might, so they belong inside it.
OffBeat:RegisterProfile({
    meta = {
        name = "Augmentation Evoker",
        specId = 1473,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1 + top 40 heroic parses per boss (Oct 2026)",
    },

    -- Buff panel. Ebon Might on yourself is aura 395296 (395152 is the cast
    -- and the copy on allies); Prescience on allies is aura 410089. Both
    -- are also matched by name.
    trackedBuffs = {
        {
            spellId = 395296,
            alt = { 395152 },
            name = "Ebon Might",
            color = { 0.20, 0.80, 0.35 },
            maxTargets = 1,
            category = "primary",
            baseDuration = 10,
            selfBuff = true,
        },
        {
            spellId = 410089,
            name = "Prescience",
            color = { 0.90, 0.80, 0.20 },
            maxTargets = 2,
            category = "primary",
            baseDuration = 18,
        },
        {
            spellId = 413984,
            name = "Shifting Sands",
            color = { 0.60, 0.50, 0.90 },
            maxTargets = 4,
            category = "secondary",
            baseDuration = 30,
        },
        {
            spellId = 360827,
            name = "Blistering Scales",
            color = { 0.90, 0.40, 0.20 },
            maxTargets = 1,
            category = "secondary",
            baseDuration = 600,
        },
        {
            spellId = 369459,
            name = "Source of Magic",
            color = { 0.40, 0.60, 0.95 },
            maxTargets = 1,
            category = "secondary",
            baseDuration = 3600,
        },
    },

    -- Blistering Scales: only 15% of the top raid players talent it (Time
    -- Spiral: 97%), so its alert only shows when you have it.
    alerts = {
        { type = "missing_buff", spellId = 360827, name = "Blistering Scales" },
        { type = "missing_buff", spellId = 369459, name = "Source of Magic", condition = "group_has_healer" },
    },

    -- Since 12.1 the game hides your auras in combat, Ebon Might included,
    -- so OffBeat works it out from your casts. Measured on 108 Ebon Mights
    -- of top players (Oct 2026): it lasts ~13.7s after the cast, and each
    -- Eruption adds ~1.4s, Fire Breath / Upheaval ~1.5s, Breath of Eons
    -- ~7.4s (fit within ±4s, hence the 4s grace: a rough estimate can miss
    -- a mistake but not invent one). Out of combat the real aura is used.
    castAuras = {
        -- 11s, not the top players' 14: they have more haste. Checked on
        -- your LFR log (Oct 11): 11 catches 13 of your 25 Eruptions /
        -- empowers outside Ebon Might and never calls one inside it wrong.
        { aura = 395296, cast = 395152, duration = 11, max = 20, grace = 4,
          extend = {
              { spell = 395160, by = 1.4 },  -- Eruption
              { spell = 357208, by = 1.5 },  -- Fire Breath
              { spell = 396286, by = 1.5 },  -- Upheaval
              { spell = 403631, by = 7 },    -- Breath of Eons
          } },
    },

    castWarnings = {
        {
            castNames = { "Fire Breath", "Upheaval", "Eruption" },
            requireBuff = { 395296, 395152 },
            buffName = "Ebon Might",
        },
    },

    -- Every spell here is pressed by every one of the top players (Time
    -- Skip: 98%). Chrono Flames is Living Flame for Chronowarden; the log
    -- shows it under its own ID. Hover, Time Spiral and Obsidian Scales are
    -- pressed too, but they're movement and defence, not rotation.
    rotationSpells = {
        { spellId = 395160 },  -- Eruption
        { spellId = 361469 },  -- Living Flame
        { spellId = 431443 },  -- Chrono Flames (Chronowarden Living Flame)
        { spellId = 409311 },  -- Prescience
        { spellId = 395152 },  -- Ebon Might
        { spellId = 357208 },  -- Fire Breath
        { spellId = 396286 },  -- Upheaval
        { spellId = 403631 },  -- Breath of Eons
        { spellId = 370553 },  -- Tip the Scales
        { spellId = 404977 },  -- Time Skip
    },

    -- Checked against the top players' own Ebon Might (aura 395296) on
    -- Ula'tek (35 of the 40): 2.5% of their Eruptions, 0.6% of their Fire
    -- Breaths and Upheavals and 4% of their Breaths of Eons went out with
    -- it down, so each of these is a real mistake. They read your auras, so
    -- they stay quiet while the game hides them.
    mistakes = {
        {
            type = "bad_cast",
            name = "Eruption without Ebon Might",
            description = "Eruption only counts inside Ebon Might: cast Ebon Might first",
            spells = { 395160 },
            when = { aura = 395296, absent = true },
        },
        {
            type = "bad_cast",
            name = "Empower without Ebon Might",
            description = "Fire Breath and Upheaval extend Ebon Might: cast Ebon Might first",
            spells = { 357208, 396286 },
            when = { aura = 395296, absent = true },
        },
        {
            type = "bad_cast",
            name = "Breath of Eons without Ebon Might",
            description = "Breath of Eons copies damage done under Ebon Might: cast Ebon Might first",
            spells = { 403631 },
            when = { aura = 395296, absent = true },
        },
        -- 93% of the top players' Breaths had a Prescience cast in the 12s
        -- before (the rest are mostly pulls, where the log misses the
        -- pre-pull Prescience). Read from your casts, so it always works.
        {
            type = "bad_cast",
            name = "Breath of Eons without Prescience",
            description = "Put Prescience on two DPS before Breath of Eons",
            spells = { 403631 },
            when = { recent = 409311, within = 12, absent = true },
        },
    },

    trackedAuras = {
        { spellId = 395296, name = "Ebon Might",     baseDuration = 10, stacks = false, alt = { 395152 } },
        { spellId = 392268, name = "Essence Burst",  baseDuration = 15, stacks = true },
        { spellId = 370553, name = "Tip the Scales", baseDuration = 0,  stacks = false },
        { spellId = 431698, name = "Temporal Burst", baseDuration = 30, stacks = true },
    },

    keyCooldown = {
        spellId = 403631,
        name = "Breath of Eons",
        duration = 10,
    },

    -- Evoker spells reach 25 yards, shorter than most casters'. Your first
    -- LFR (Oct 11, 3 bosses): Eruption failed for lack of Essence 111 times
    -- and 62 casts failed while moving.
    failNudges = {
        { error = "range", spells = { 395160, 361469, 357208, 396286, 409311 }, name = "Out of range",
          text = "Out of range: Evoker spells reach 25 yards, Hover in closer" },
        { error = "essence", spells = { 395160 }, name = "Eruption without Essence",
          text = "No Essence: Chrono Flames builds it" },
        { error = "moving", spells = { 395160, 361469, 431443 }, name = "Cast while moving",
          text = "Moving: Hover first, then cast" },
    },

    -- Countdown to Breath of Eons. Its cooldown is 2 minutes; the top
    -- players get it every ~90s (median gap 91s), most likely from Time
    -- Skip speeding cooldowns up. The game's own cooldown is used when it's readable, the
    -- 120 only when it isn't. 93% of them had Prescience out first. Fire Breath and
    -- Upheaval go right after it: 2 of them in its first 10s is the median.
    prep = {
        spellId = 403631, name = "Breath of Eons", cooldown = 120, lead = 6,
        hint = "Prescience on two DPS, Ebon Might up, then Breath and Fire Breath + Upheaval",
        checks = {
            { name = "Fire Breath", ready = 357208, cooldown = 30 },
            { name = "Upheaval",    ready = 396286, cooldown = 40 },
        },
    },

    idleCooldowns = {
        { spellId = 357208, name = "Fire Breath" },
        { spellId = 396286, name = "Upheaval" },
        { spellId = 403631, name = "Breath of Eons" },
        { spellId = 370553, name = "Tip the Scales" },
    },

    -- Coaching: Breath of Eons opens the window. In the 10s after it the
    -- top players press Fire Breath and Upheaval twice (median 2 on every
    -- boss; 4 when Time Skip resets them), with Tip the Scales on the Fire
    -- Breath. Eruptions come later, once Essence has built up.
    windows = {
        {
            name = "Breath of Eons",
            trigger = 403631,
            duration = 10,
            note = "Prescience on two DPS and Ebon Might up before Breath. Then Tip the Scales + "
                .. "Fire Breath and Upheaval (rank 1), Time Skip, and both again. Top players: 2 per Breath.",
            setup = {
                { name = "Ebon Might up", when = { aura = 395296 } },
                { name = "Prescience out", when = { recent = 409311, within = 12 } },
            },
            goals = {
                { name = "Fire Breath / Upheaval", spells = { 357208, 396286 }, min = 2 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Fire Breath + Upheaval per Breath.
    benchmarks = {
        source = "top 40 heroic parses per boss (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",  all = true },
            { name = "Eruption",        spells = { 395160 } },
            { name = "Chrono Flames",   spells = { 361469, 431443 } },
            { name = "Prescience",      spells = { 409311 } },
            { name = "Ebon Might",      spells = { 395152 } },
            { name = "Fire Breath",     spells = { 357208 } },
            { name = "Upheaval",        spells = { 396286 } },
            { name = "Breath of Eons",  spells = { 403631 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 2, values = {
                { 34.9, 35.8, 37.6 }, { 13.9, 14.5, 15.5 }, { 5.7, 6.2, 7.6 }, { 6.2, 6.4, 6.5 }, { 1.9, 2.1, 2.2 }, { 2.2, 2.3, 2.4 }, { 2.6, 2.7, 2.8 }, { 0.6, 0.6, 0.6 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 2, values = {
                { 42.8, 44.9, 45.7 }, { 17.4, 18.1, 18.6 }, { 8.4, 9.2, 10.3 }, { 6.7, 6.8, 6.9 }, { 1.9, 2.0, 2.2 }, { 2.6, 2.7, 2.8 }, { 3.1, 3.3, 3.4 }, { 0.7, 0.8, 0.8 } } },
            [3445] = { name = "Entombed Sentinels", window = 2, values = {
                { 41.1, 42.7, 44.9 }, { 16.3, 16.9, 18.2 }, { 8.5, 9.2, 10.6 }, { 6.5, 6.6, 6.7 }, { 1.7, 2.0, 2.2 }, { 2.5, 2.6, 2.7 }, { 3.0, 3.2, 3.3 }, { 0.7, 0.7, 0.8 } } },
            [3455] = { name = "Vashnik the Malignant", window = 2, values = {
                { 44.4, 46.0, 47.0 }, { 18.1, 18.8, 19.1 }, { 8.6, 10.3, 11.0 }, { 6.7, 6.8, 6.9 }, { 1.9, 2.1, 2.2 }, { 2.6, 2.6, 2.7 }, { 3.1, 3.3, 3.4 }, { 0.7, 0.8, 0.8 } } },
            [3497] = { name = "The Lost Explorers", window = 2, values = {
                { 43.9, 45.9, 46.9 }, { 18.7, 19.8, 20.8 }, { 7.2, 8.2, 9.1 }, { 6.8, 7.0, 7.1 }, { 1.9, 2.1, 2.3 }, { 2.6, 2.7, 2.8 }, { 3.2, 3.4, 3.5 }, { 0.7, 0.7, 0.9 } } },
            [3420] = { name = "Sszorak", window = 2, values = {
                { 42.3, 44.5, 45.3 }, { 16.5, 17.6, 18.3 }, { 8.8, 9.6, 11.0 }, { 6.6, 6.7, 6.8 }, { 1.9, 2.2, 2.3 }, { 2.5, 2.7, 2.7 }, { 3.0, 3.2, 3.4 }, { 0.7, 0.7, 0.7 } } },
            [3421] = { name = "The Twin Fangs", window = 2, values = {
                { 40.6, 42.1, 43.7 }, { 17.0, 18.0, 18.8 }, { 6.6, 8.0, 9.4 }, { 6.5, 6.6, 6.7 }, { 1.7, 2.0, 2.2 }, { 2.5, 2.6, 2.7 }, { 3.0, 3.2, 3.3 }, { 0.6, 0.7, 0.7 } } },
            [3429] = { name = "The Coiled Altar", window = 2, values = {
                { 41.2, 42.9, 44.4 }, { 17.1, 17.9, 18.5 }, { 8.1, 8.9, 9.7 }, { 6.4, 6.5, 6.6 }, { 1.8, 2.1, 2.2 }, { 2.4, 2.5, 2.6 }, { 3.0, 3.1, 3.1 }, { 0.6, 0.7, 0.7 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 2, values = {
                { 43.8, 45.6, 47.0 }, { 17.4, 18.2, 18.7 }, { 8.5, 10.0, 10.6 }, { 6.7, 6.9, 7.0 }, { 2.0, 2.2, 2.3 }, { 2.6, 2.7, 2.8 }, { 3.2, 3.3, 3.4 }, { 0.8, 0.8, 0.9 } } },
        },
        overall = { name = "all heroic bosses", window = 2, values = {
            { 41.1, 43.6, 45.8 }, { 16.7, 18.0, 18.8 }, { 7.6, 8.9, 10.3 }, { 6.5, 6.7, 6.9 }, { 1.9, 2.1, 2.2 }, { 2.5, 2.6, 2.7 }, { 3.0, 3.2, 3.4 }, { 0.7, 0.7, 0.8 } } },
    },

    -- /ob bars: role for role on the warlock and DK keys (binds are
    -- account-wide): spender on 1, filler on 3, big cooldown on Q, the buff
    -- you keep up on Shift-1, short cooldown on Shift-2, big channel on
    -- Shift-3, interrupt Shift-E, movement F, defensives ` / Shift-`.
    -- Fire Breath and Upheaval are empowers: hold the key to charge, let go
    -- at rank 1 (the first tick; 95-98% of top players' casts). Chrono
    -- Flames shows up on Living Flame. E (potion), F1/F2, F5, Shift-4,
    -- Shift-5, G, R and T are left alone.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 395160, note = "Eruption: Essence spender, only inside Ebon Might (Hand of Gul'dan's spot)" },
        { slot = 2,  key = "2",       spellId = 396286, note = "Upheaval: empower, let go at rank 1" },
        { slot = 3,  key = "3",       spellId = 361469, note = "Chrono Flames: filler (Living Flame in the spellbook) (Shadow Bolt's spot)" },
        { slot = 4,  key = "4",       spellId = 357208, note = "Fire Breath: empower, let go at rank 1" },
        { slot = 5,  key = "5",       spellId = 409311, note = "Prescience: two DPS, ~6-7 a minute (2 charges)" },
        { slot = 6,  key = "Q",       macro = { name = "OB Eons", spells = { 403631 }, cursor = true },
          note = "Breath of Eons at your cursor: big cooldown, 2 min (Tyrant's spot)" },
        { slot = 61, key = "Shift-1", spellId = 395152, note = "Ebon Might: keep it up, refresh with ~4s left" },
        { slot = 62, key = "Shift-2", spellId = 370553, note = "Tip the Scales: right before Fire Breath" },
        { slot = 63, key = "Shift-3", spellId = 404977, note = "Time Skip: after Fire Breath + Upheaval, then cast both again" },
        { slot = 50, key = "Shift-E", spellId = 351338, note = "Quell: interrupt" },
        { slot = 70, key = "F",       spellId = 358267, note = "Hover: cast while moving" },
        { slot = 55, key = "`",       spellId = 363916, note = "Obsidian Scales: long defensive" },
        { slot = 56, key = "Shift-`", spellId = 374348, note = "Renewing Blaze: short defensive" },
        { slot = 12, key = "X",       spellId = 374968, note = "Time Spiral: raid movement (97% of top players talent it, 75% press it)" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1, checked against the
    -- top 40 heroic parses per boss.
    rotationSheet = {
        { title = "Before the pull", lines = {
            { spellId = 369459, text = "Source of Magic on a healer" },
            { spellId = 409311, text = "Prescience on two DPS (your best two)" },
            { spellId = 361469, text = "Pre-cast Chrono Flames" },
        } },
        { title = "Pull (top players)", lines = {
            { spellId = 395152, text = "Ebon Might, then Breath of Eons" },
            { spellId = 370553, text = "Tip the Scales, Fire Breath, Upheaval (rank 1)" },
            { spellId = 404977, text = "Time Skip, then Fire Breath and Upheaval again" },
            { text = "Prescience again on two DPS, then Eruption" },
        } },
        { title = "Priority", lines = {
            { spellId = 395152, text = "Ebon Might: refresh with ~4s left (top players: up 85% of the fight)" },
            { spellId = 409311, text = "Prescience: keep it on two DPS, don't sit on 2 charges" },
            { spellId = 403631, text = "Breath of Eons: on cooldown (2 min, sooner with Time Skip), with Prescience out and Ebon Might up" },
            { spellId = 357208, text = "Fire Breath at rank 1, inside Ebon Might" },
            { spellId = 396286, text = "Upheaval at rank 1, inside Ebon Might" },
            { spellId = 370553, text = "Tip the Scales: on Fire Breath" },
            { spellId = 404977, text = "Time Skip: after Fire Breath + Upheaval, then both again" },
            { spellId = 395160, text = "Eruption: spend Essence and Essence Burst, only inside Ebon Might" },
            { spellId = 361469, alt = { 431443 }, text = "Chrono Flames: filler" },
        } },
        { title = "AoE", lines = {
            { spellId = 396286, text = "Same priority; rank Upheaval up only if rank 1 doesn't reach the pack" },
        } },
    },

    -- Method 12.1 (both hero trees): Mastery > Haste = Crit > Vers
    statPriority = { MASTERY = 1, HASTE = 2, CRIT = 2, VERS = 3 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 395160, st = 1, aoe = 1, note = "Most pressed: ~18 a minute" },
        { spellId = 361469, st = 1, aoe = 1, alt = { 431443 }, note = "Filler; Chrono Flames for Chronowarden" },
        { spellId = 409311, st = 1, aoe = 1, note = "~6-7 a minute, two DPS" },
        { spellId = 357208, st = 1, aoe = 1, note = "Empower, rank 1" },
        { spellId = 396286, st = 1, aoe = 1, note = "Empower, rank 1" },
        { spellId = 395152, st = 2, aoe = 2, note = "Refresh with ~4s left" },
        { spellId = 370553, st = 3, aoe = 3, note = "Before Fire Breath" },
        { spellId = 404977, st = 3, aoe = 3, note = "After Fire Breath + Upheaval" },
        { spellId = 403631, st = 3, aoe = 3, note = "Main cooldown, 2 min" },
    },
})
