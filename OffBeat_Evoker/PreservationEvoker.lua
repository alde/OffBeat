local OffBeat = _G.OffBeat

-- Preservation Evoker, Method 12.1 (20 Aug 2026), checked against the top 40
-- heroic parses (by healing) on every Venomous Abyss boss (Warcraft Logs,
-- Oct 2026). All 360 of them play Flameshaper, which Method also
-- recommends for raid and M+, so this is a Flameshaper raid profile.
--
-- Healing is reactive, so there are no mistake rules: nothing the top
-- players do is near-universal enough to call a mistake (even Temporal
-- Anomaly right after Dream Breath is only 68% of theirs). What's here is
-- what they all do the same way: the Dream Breath loop, empower ranks,
-- cooldowns kept rolling, and casts per minute to compare against.
OffBeat:RegisterProfile({
    meta = {
        name = "Preservation Evoker",
        specId = 1468,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method 12.1 + top 40 heroic parses per boss (Oct 2026)",
    },

    -- Pressed by 84%+ of the top players. Twin Flame (20 a minute in their
    -- logs) is left out: it fires off Echo and Emerald Blossom by itself.
    -- Spiritbloom isn't pressed at all in raid; Time Dilation only by 64%.
    rotationSpells = {
        { spellId = 364343 },  -- Echo
        { spellId = 355913 },  -- Emerald Blossom
        { spellId = 355936 },  -- Dream Breath
        { spellId = 355941 },  -- Dream Breath (instant: Tip the Scales / Stasis)
        { spellId = 373861 },  -- Temporal Anomaly
        { spellId = 1256581 }, -- Merithra's Blessing
        { spellId = 357208 },  -- Fire Breath
        { spellId = 361469 },  -- Living Flame
        { spellId = 361509 },  -- Living Flame (cast on an enemy)
        { spellId = 360995 },  -- Verdant Embrace
        { spellId = 366155 },  -- Reversion
        { spellId = 370553 },  -- Tip the Scales
        { spellId = 370537 },  -- Stasis
        { spellId = 363534 },  -- Rewind
    },

    -- Your own buffs. 12.1 hides them in combat, so these show out of
    -- combat and whenever the game lets them through.
    trackedAuras = {
        { spellId = 369299,  name = "Essence Burst",       baseDuration = 15, stacks = true },
        { spellId = 1256579, name = "Merithra's Blessing", baseDuration = 0,  stacks = false },
        { spellId = 1242759, name = "Twin Echoes",         baseDuration = 0,  stacks = true },
        { spellId = 370553,  name = "Tip the Scales",      baseDuration = 0,  stacks = false },
        { spellId = 370562,  name = "Stasis",              baseDuration = 30, stacks = true },
    },

    keyCooldown = {
        spellId = 370537,
        name = "Stasis",
        duration = 0,
    },

    -- Echo and Emerald Blossom cost Essence; Living Flame is the builder.
    failNudges = {
        { error = "essence", spells = { 364343, 355913 }, name = "Spender without Essence",
          text = "No Essence: Living Flame builds it (Essence Burst makes the next one free)" },
        { error = "moving", spells = { 361469, 355936 }, name = "Cast while moving",
          text = "Moving: Hover first, then cast" },
    },

    -- On cooldown for every top player: Temporal Anomaly every ~15s
    -- (median gap), Dream Breath ~3.8 a minute, Fire Breath ~2.5 a minute.
    -- Tip the Scales, Stasis and Rewind are held for damage, so no nag.
    idleCooldowns = {
        { spellId = 373861, name = "Temporal Anomaly" },
        { spellId = 355936, name = "Dream Breath" },
        { spellId = 357208, name = "Fire Breath" },
    },

    -- Coaching: the Dream Breath loop (Method: Dream Breath, Temporal
    -- Anomaly, Echo / Emerald Blossom, Merithra's Blessing). In the 10s
    -- after Dream Breath the top players cast Temporal Anomaly (88% of
    -- the time) and 4 Echoes / Emerald Blossoms (median, every boss), with
    -- Merithra's Blessing after about half of them.
    windows = {
        {
            name = "Dream Breath",
            trigger = 355936,
            duration = 10,
            note = "Dream Breath (rank 1), Temporal Anomaly, then spend Essence on Echo and "
                .. "Emerald Blossom, Merithra's Blessing to finish. Top players: 4 spenders.",
            goals = {
                { name = "Temporal Anomaly", spells = { 373861 }, min = 1 },
                { name = "Echo / Emerald Blossom", spells = { 364343, 355913 }, min = 4 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Echo + Emerald Blossom per Dream
    -- Breath.
    benchmarks = {
        source = "top 40 heroic parses per boss (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",      all = true },
            { name = "Echo",                spells = { 364343 } },
            { name = "Emerald Blossom",     spells = { 355913 } },
            { name = "Dream Breath",        spells = { 355936, 355941 } },
            { name = "Temporal Anomaly",    spells = { 373861 } },
            { name = "Merithra's Blessing", spells = { 1256581 } },
            { name = "Fire Breath",         spells = { 357208 } },
            { name = "Living Flame",        spells = { 361469, 361509 } },
            { name = "Verdant Embrace",     spells = { 360995 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 4, values = {
                { 42.3, 43.8, 44.4 }, { 12.1, 13.7, 14.5 }, { 10.1, 10.6, 11.3 }, { 3.6, 3.7, 3.8 }, { 3.9, 4.0, 4.1 }, { 3.6, 3.8, 3.9 }, { 2.1, 2.5, 2.6 }, { 1.9, 2.8, 3.3 }, { 0.4, 0.6, 1.0 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 4, values = {
                { 40.7, 42.0, 43.6 }, { 9.1, 10.1, 11.3 }, { 11.0, 11.5, 12.4 }, { 3.6, 3.8, 4.3 }, { 3.9, 4.1, 4.3 }, { 3.5, 3.8, 4.2 }, { 2.2, 2.6, 3.0 }, { 1.8, 2.3, 2.9 }, { 0.4, 0.8, 1.8 } } },
            [3445] = { name = "Entombed Sentinels", window = 4, values = {
                { 40.2, 41.6, 43.9 }, { 8.9, 10.3, 12.8 }, { 10.6, 11.3, 12.2 }, { 3.5, 3.6, 3.8 }, { 3.7, 4.0, 4.2 }, { 3.6, 3.9, 4.3 }, { 1.9, 2.4, 2.7 }, { 1.3, 2.0, 3.2 }, { 0.7, 1.4, 2.1 } } },
            [3455] = { name = "Vashnik the Malignant", window = 4, values = {
                { 40.3, 42.9, 44.4 }, { 9.7, 10.8, 12.1 }, { 10.7, 11.5, 12.4 }, { 3.7, 3.9, 4.0 }, { 3.9, 4.3, 4.4 }, { 3.3, 3.7, 4.0 }, { 2.2, 2.7, 3.1 }, { 1.1, 2.3, 3.5 }, { 0.7, 1.2, 1.6 } } },
            [3497] = { name = "The Lost Explorers", window = 4, values = {
                { 40.2, 42.1, 44.1 }, { 9.7, 11.0, 12.0 }, { 9.8, 11.0, 12.2 }, { 3.7, 3.9, 4.1 }, { 4.0, 4.2, 4.6 }, { 3.4, 3.8, 4.2 }, { 2.0, 2.7, 3.0 }, { 1.1, 1.8, 3.0 }, { 0.5, 0.8, 1.4 } } },
            [3420] = { name = "Sszorak", window = 4, values = {
                { 42.2, 44.0, 45.9 }, { 10.7, 11.6, 13.8 }, { 11.3, 11.9, 12.8 }, { 3.7, 3.9, 4.1 }, { 4.1, 4.3, 4.5 }, { 3.8, 4.2, 4.5 }, { 2.0, 2.5, 2.8 }, { 1.3, 2.0, 2.8 }, { 0.7, 1.0, 1.5 } } },
            [3421] = { name = "The Twin Fangs", window = 4, values = {
                { 39.9, 41.8, 43.2 }, { 10.1, 11.4, 12.5 }, { 10.5, 11.2, 12.4 }, { 3.5, 3.7, 3.9 }, { 3.8, 4.1, 4.3 }, { 3.7, 4.0, 4.4 }, { 1.9, 2.2, 2.6 }, { 1.4, 1.8, 2.5 }, { 0.7, 1.2, 1.8 } } },
            [3429] = { name = "The Coiled Altar", window = 4, values = {
                { 42.1, 43.4, 45.1 }, { 10.3, 11.8, 12.7 }, { 11.3, 12.0, 13.1 }, { 3.7, 3.8, 4.1 }, { 4.0, 4.1, 4.3 }, { 3.6, 3.8, 4.3 }, { 2.1, 2.5, 2.9 }, { 1.3, 2.0, 3.3 }, { 0.7, 1.2, 1.6 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 4, values = {
                { 40.5, 41.9, 44.6 }, { 10.0, 10.9, 12.6 }, { 10.0, 10.9, 11.7 }, { 3.6, 3.7, 4.1 }, { 3.9, 4.1, 4.4 }, { 3.2, 3.5, 4.1 }, { 2.2, 2.8, 3.1 }, { 1.4, 2.8, 3.5 }, { 0.5, 1.0, 1.5 } } },
        },
        overall = { name = "all heroic bosses", window = 4, values = {
            { 40.8, 42.7, 44.5 }, { 9.9, 11.2, 12.9 }, { 10.5, 11.3, 12.4 }, { 3.6, 3.8, 4.0 }, { 3.9, 4.1, 4.4 }, { 3.5, 3.8, 4.2 }, { 2.1, 2.5, 2.9 }, { 1.4, 2.1, 3.1 }, { 0.6, 1.1, 1.6 } } },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1 (Flameshaper raid),
    -- checked against the top 40 heroic parses per boss.
    rotationSheet = {
        { title = "Before the pull", lines = {
            { spellId = 370537, text = "Stasis: store Dream Breath, Dream Breath, Temporal Anomaly (most top players)" },
            { spellId = 369459, text = "Source of Magic on the healer who needs mana most" },
        } },
        { title = "Core loop", lines = {
            { spellId = 355936, alt = { 355941 }, text = "Dream Breath at rank 1 (98% of top casts): same total healing, starts the ramp" },
            { spellId = 373861, text = "Temporal Anomaly right after (top players: every ~15s)" },
            { spellId = 364343, text = "Echo and Emerald Blossom: spend Essence, ~4 in the 10s after Dream Breath" },
            { spellId = 355913, text = "Essence Burst on Emerald Blossom, unless Twin Echoes is at 2 charges: then Echo" },
            { spellId = 1256581, text = "Merithra's Blessing to finish the ramp" },
            { spellId = 366155, text = "No Merithra's proc: Dream Breath > Reversion > Verdant Embrace" },
        } },
        { title = "Cooldowns", lines = {
            { spellId = 370553, text = "Tip the Scales: on Fire Breath (91% of top players' Tips)" },
            { spellId = 370564, text = "Stasis release: into heavy damage, ~15s after storing" },
            { spellId = 363534, text = "Rewind: after a heavy hit, not for chip damage" },
        } },
        -- M+ from Method 12.1 and the top 20 runs per dungeon (Oct 2026,
        -- 93% Flameshaper): Disintegrate is their most pressed spell, and
        -- Dream Breath / Fire Breath come round twice as often as in raid.
        { title = "M+: always", content = "dungeon", lines = {
            { spellId = 366155, text = "Reversion on the tank (Temporal Anomaly into Reversion), pre-spread between pulls" },
            { spellId = 355936, alt = { 355941 }, text = "Dream Breath before damage; Fire Breath DoT on every pack" },
            { spellId = 373861, text = "Temporal Anomaly between Dream Breath and Fire Breath" },
            { spellId = 356995, text = "Disintegrate when no healing is needed: banks Merithra's Blessing" },
        } },
        { title = "M+: damage coming", content = "dungeon", lines = {
            { spellId = 360995, text = "Verdant Embrace (one target) or Emerald Blossom (group) consumes Dream Breath" },
            { spellId = 1256581, text = "Merithra's Blessing after a big hit (Golden Hour)" },
            { spellId = 374251, text = "Cauterizing Flame: bleeds, poisons, curses, diseases" },
        } },
        { title = "Filler / damage", lines = {
            { spellId = 357208, text = "Fire Breath on cooldown, mostly at max rank" },
            { spellId = 361469, text = "Living Flame: builds Essence Burst (20% a cast)" },
            { spellId = 357210, text = "Deep Breath when it hits 2+ targets" },
        } },
    },

    -- Method 12.1 raid: Mastery > Crit > Haste = Vers; M+ (healing):
    -- Mastery > Crit > Haste > Vers
    statPriority = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 3 },
    contentStatPriorities = {
        raid    = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 3 },
        dungeon = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
    },

    -- Bars: same keys as the other OffBeat specs (1-5, Q, G, E, R, X, the
    -- Shift row, F, `), laid out like Mistweaver: one layout for raid and
    -- one for M+ / delves, heals as mouseover macros (Living Flame heals
    -- your mouseover, else hits your target). Ordered by how often the top
    -- players press them. Raid (top 40 heroic): Echo and Emerald Blossom
    -- ~11 a minute, then Temporal Anomaly / Dream Breath / Merithra's ~4.
    -- M+ (top 20 runs per dungeon): Disintegrate is first, Echo drops to
    -- ~2 a minute (its key moves to Shift-5), Cauterizing Flame joins.
    -- Fire Breath, Tip the Scales, Hover, Quell and the defensives sit
    -- where Augmentation has them.
    barLayout = {
        -- both
        { slot = 2,  key = "2",       macro = { name = "OB Blossom", spells = { 355913 }, mouseover = true },
          note = "Emerald Blossom (mouseover): ~11 a minute in raid, Essence Burst goes here" },
        { slot = 3,  key = "3",       macro = { name = "OB LFlame", spells = { 361469 }, mouseover = true },
          note = "Living Flame: heals your mouseover, else hits your target. Builds Essence Burst" },
        { slot = 4,  key = "4",       spellId = 357208, note = "Fire Breath: on cooldown (Augmentation's spot)" },
        { slot = 5,  key = "5",       macro = { name = "OB Merithra", spells = { 1256581 }, mouseover = true },
          note = "Merithra's Blessing (mouseover): finishes the ramp" },
        { slot = 6,  key = "Q",       spellId = 355936, note = "Dream Breath: rank 1, starts the ramp" },
        { slot = 8,  key = "E",       spellId = 373861, note = "Temporal Anomaly: right after Dream Breath, every ~15s" },
        { slot = 7,  key = "G",       macro = { name = "OB Verdant", spells = { 360995 }, mouseover = true },
          note = "Verdant Embrace (mouseover): stabilize, Lifebind" },
        { slot = 67, key = "R",       macro = { name = "OB Reversion", spells = { 366155 }, mouseover = true },
          note = "Reversion (mouseover): Echo it first on the tank" },
        { slot = 12, key = "X",       macro = { name = "OB Naturalize", spells = { 360823 }, mouseover = true },
          note = "Naturalize (mouseover): dispel" },
        { slot = 61, key = "Shift-1", macro = { name = "OB TimeDil", spells = { 357170 }, mouseover = true },
          note = "Time Dilation (mouseover): tank before a big hit" },
        { slot = 62, key = "Shift-2", spellId = 370553, note = "Tip the Scales: on Fire Breath (Augmentation's spot)" },
        { slot = 63, key = "Shift-3", spellId = 370537, note = "Stasis: store Dream Breath x2 + Temporal Anomaly, press again to release" },
        { slot = 64, key = "Shift-4", spellId = 363534, note = "Rewind: after a heavy hit" },
        { slot = 50, key = "Shift-E", spellId = 351338, note = "Quell: interrupt" },
        { slot = 70, key = "F",       spellId = 358267, note = "Hover: cast while moving" },
        { slot = 55, key = "`",       spellId = 363916, note = "Obsidian Scales: defensive" },
        { slot = 56, key = "Shift-`", spellId = 374348, note = "Renewing Blaze: defensive" },

        -- raid
        { slot = 1,  key = "1",       content = "raid", macro = { name = "OB Echo", spells = { 364343 }, mouseover = true },
          note = "Echo (mouseover): most pressed with Emerald Blossom, ~11 a minute" },

        -- M+ / delves
        { slot = 1,  key = "1",       content = "dungeon", spellId = 356995,
          note = "Disintegrate: the top M+ players' most pressed spell (banks Merithra's Blessing)" },
        { slot = 65, key = "Shift-5", content = "dungeon", macro = { name = "OB Echo", spells = { 364343 }, mouseover = true },
          note = "Echo (mouseover): ~2 a minute in M+" },
        { slot = 66, key = "Shift-Q", content = "dungeon", macro = { name = "OB Cauterize", spells = { 374251 }, mouseover = true },
          note = "Cauterizing Flame (mouseover): bleeds, poisons, curses, diseases" },
    },

    keyLayoutLabels = { st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 364343,  st = 1, aoe = 1, note = "Most pressed after Emerald Blossom (~11 a minute)" },
        { spellId = 355913,           aoe = 1, note = "~11 a minute, Essence Burst goes here" },
        { spellId = 355936,           aoe = 1, alt = { 355941 }, note = "Rank 1, starts the ramp" },
        { spellId = 373861,           aoe = 1, note = "Right after Dream Breath, every ~15s" },
        { spellId = 1256581, st = 1, aoe = 1, note = "Strongest single target; finishes the ramp" },
        { spellId = 366155,  st = 1, aoe = 2, note = "Echo it on the target first (double Reversion)" },
        { spellId = 360995,  st = 1, aoe = 2, note = "Stabilize; Lifebind" },
        { spellId = 361469,  st = 2, aoe = 2, note = "Filler, Essence Burst" },
        { spellId = 357208,  st = 2, aoe = 2, note = "On cooldown, mostly max rank" },
        { spellId = 360823,  st = 2, aoe = 2, note = "Dispel" },
        { spellId = 357170,  st = 3,          note = "Tank before a big hit" },
        { spellId = 370553,  st = 3, aoe = 3, note = "On Fire Breath" },
        { spellId = 370537,           aoe = 3, note = "Store Dream Breath x2 + Temporal Anomaly" },
        { spellId = 363534,           aoe = 3, note = "Raid cooldown after a heavy hit" },
        { spellId = 363916,  st = 3, aoe = 3, note = "Defensive" },
    },
})
