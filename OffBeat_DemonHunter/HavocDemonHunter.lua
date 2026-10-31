local OffBeat = _G.OffBeat

-- Havoc Demon Hunter, Method 12.1.5 (16 Oct 2026), checked against the top
-- 40 heroic parses on every Venomous Abyss boss (360) and the top 40 timed
-- runs per Season 2 dungeon (320 runs; Warcraft Logs, Oct 2026). The top
-- players are Aldrachi Reaver (Reaver's Glaive in 93% of raid parses and
-- 98% of runs); nobody plays Fel-Scarred, so the sheet is Method's
-- Aldrachi Reaver priority.
--
-- Cooldowns, on cooldown for every top player: Metamorphosis every ~2:03,
-- The Hunt ~61s, Essence Break ~31s, Eye Beam and Vengeful Retreat ~21s
-- (paired), Immolation Aura ~22s. Annihilation is the most pressed spell
-- (~19 a minute in raid): Demonic keeps you in demon form after every Eye
-- Beam. Inside Metamorphosis's 20s the top players fit 11 Annihilations
-- (10 in M+) and 4 Death Sweeps. Throw Glaive goes out by itself
-- (Screaming Brutality) and isn't counted.
OffBeat:RegisterProfile({
    meta = {
        name = "Havoc Demon Hunter",
        specId = 577,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Pressed by the top players. Metamorphosis is logged as 200166.
    rotationSpells = {
        { spellId = 162794 }, -- Chaos Strike
        { spellId = 201427 }, -- Annihilation (Chaos Strike in demon form)
        { spellId = 188499 }, -- Blade Dance
        { spellId = 210152 }, -- Death Sweep (Blade Dance in demon form)
        { spellId = 198013 }, -- Eye Beam
        { spellId = 258860 }, -- Essence Break
        { spellId = 258920 }, -- Immolation Aura
        { spellId = 370965 }, -- The Hunt
        { spellId = 442294 }, -- Reaver's Glaive (Aldrachi Reaver)
        { spellId = 232893 }, -- Felblade
        { spellId = 198793 }, -- Vengeful Retreat
        { spellId = 200166 }, -- Metamorphosis
    },

    -- Your own buffs. 12.1 hides them in combat, so these show out of
    -- combat and whenever the game lets them through.
    trackedAuras = {
        { spellId = 162264, name = "Metamorphosis", baseDuration = 20, stacks = false },
        { spellId = 391215, name = "Initiative",    baseDuration = 5,  stacks = false },
    },

    keyCooldown = {
        spellId = 200166,
        name = "Metamorphosis",
        duration = 20,
    },

    failNudges = {
        { error = "range", spells = { 162794, 201427, 188499, 210152 }, name = "Melee out of range",
          text = "Out of range: Felblade back in, Reaver's Glaive / Throw Glaive" },
    },

    -- Countdown to Metamorphosis. Method: if Eye Beam is under 10s away,
    -- wait for it and cast it first; Vengeful Retreat with it (cancel its
    -- animation with Metamorphosis to save a GCD).
    prep = {
        spellId = 200166, name = "Metamorphosis", cooldown = 120, lead = 5,
        hint = "Eye Beam first, Vengeful Retreat, then Metamorphosis",
        checks = {
            { name = "Eye Beam",         ready = 198013, cooldown = 20 },
            { name = "Vengeful Retreat", ready = 198793, cooldown = 20 },
        },
    },

    -- On cooldown for every top player.
    idleCooldowns = {
        { spellId = 198013, name = "Eye Beam" },
        { spellId = 258860, name = "Essence Break" },
        { spellId = 370965, name = "The Hunt" },
        { spellId = 200166, name = "Metamorphosis" },
        { spellId = 258920, name = "Immolation Aura" },
    },

    -- Coaching: Metamorphosis (20s). Raid: 11 Annihilations, 4 Death
    -- Sweeps. M+: 10 Annihilations.
    windows = {
        {
            name = "Metamorphosis (raid)",
            trigger = 200166,
            duration = 20,
            content = "raid",
            note = "Eye Beam and Vengeful Retreat right before it, then Death Sweep and Annihilation; "
                .. "Essence Break whenever it's up. Top players: 11 Annihilations, 4 Death Sweeps.",
            goals = {
                { name = "Annihilation", spells = { 201427 }, min = 11 },
                { name = "Death Sweep", spells = { 210152 }, min = 4 },
            },
        },
        {
            name = "Metamorphosis (M+)",
            trigger = 200166,
            duration = 20,
            content = "dungeon",
            note = "Into a pack after Eye Beam: Death Sweep on cooldown, Annihilation between. "
                .. "Top players: 10 Annihilations, 4 Death Sweeps.",
            goals = {
                { name = "Annihilation", spells = { 201427 }, min = 10 },
                { name = "Death Sweep", spells = { 210152 }, min = 4 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Annihilations per Metamorphosis
    -- (top 20 per boss). Dungeons (by instance ID): the top 40 timed runs,
    -- per minute in combat (Warcraft Logs' pulls).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts", all = true },
            { name = "Annihilation",   spells = { 201427 } },
            { name = "Chaos Strike",   spells = { 162794 } },
            { name = "Death Sweep / Blade Dance", spells = { 210152, 188499 } },
            { name = "Eye Beam",       spells = { 198013 } },
            { name = "Reaver's Glaive", spells = { 442294 } },
            { name = "Felblade",       spells = { 232893 } },
            { name = "Essence Break / The Hunt", spells = { 258860, 370965 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 10, values = {
                { 48.2, 50.2, 51.6 }, { 11.9, 13.2, 14.8 }, { 9.0, 9.8, 10.9 }, { 8.6, 9.0, 9.4 }, { 2.6, 2.8, 2.8 }, { 4.2, 4.4, 4.6 }, { 2.8, 3.4, 4.0 }, { 2.4, 2.5, 2.6 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 12, values = {
                { 57.2, 60.9, 62.5 }, { 18.3, 21.1, 22.3 }, { 7.0, 7.9, 8.7 }, { 10.6, 11.1, 11.5 }, { 3.0, 3.2, 3.3 }, { 4.8, 5.0, 5.2 }, { 3.8, 4.8, 5.3 }, { 2.9, 3.0, 3.0 } } },
            [3445] = { name = "Entombed Sentinels", window = 12, values = {
                { 55.2, 58.0, 60.1 }, { 16.8, 18.8, 19.6 }, { 7.6, 8.3, 8.9 }, { 10.1, 10.5, 11.0 }, { 2.9, 3.1, 3.1 }, { 4.6, 4.9, 5.2 }, { 3.5, 4.6, 5.5 }, { 2.9, 3.0, 3.1 } } },
            [3455] = { name = "Vashnik the Malignant", window = 12, values = {
                { 58.3, 60.5, 61.9 }, { 17.6, 19.0, 22.1 }, { 7.9, 8.7, 10.1 }, { 9.9, 10.5, 11.0 }, { 2.9, 3.0, 3.1 }, { 4.8, 5.0, 5.2 }, { 3.8, 4.8, 5.5 }, { 2.7, 2.8, 3.0 } } },
            [3497] = { name = "The Lost Explorers", window = 12, values = {
                { 58.3, 60.0, 61.1 }, { 18.6, 19.5, 19.9 }, { 6.4, 7.3, 8.1 }, { 10.4, 11.2, 11.5 }, { 3.1, 3.2, 3.3 }, { 4.8, 5.1, 5.3 }, { 4.4, 5.4, 5.9 }, { 2.9, 3.0, 3.2 } } },
            [3420] = { name = "Sszorak", window = 13, values = {
                { 60.4, 61.9, 63.2 }, { 20.5, 22.0, 23.3 }, { 6.6, 7.4, 8.6 }, { 10.5, 11.2, 11.7 }, { 3.1, 3.2, 3.3 }, { 4.9, 5.2, 5.5 }, { 3.3, 4.4, 5.3 }, { 3.0, 3.1, 3.2 } } },
            [3421] = { name = "The Twin Fangs", window = 12, values = {
                { 58.7, 59.8, 61.5 }, { 18.3, 19.2, 20.2 }, { 8.4, 8.9, 9.5 }, { 10.3, 10.8, 11.2 }, { 3.0, 3.1, 3.1 }, { 4.9, 5.1, 5.4 }, { 3.6, 4.6, 5.4 }, { 2.9, 2.9, 3.0 } } },
            [3429] = { name = "The Coiled Altar", window = 12, values = {
                { 57.0, 57.4, 59.4 }, { 17.4, 17.8, 18.9 }, { 8.6, 9.3, 10.0 }, { 10.1, 10.3, 10.6 }, { 3.0, 3.0, 3.1 }, { 4.7, 5.0, 5.1 }, { 3.6, 4.5, 5.2 }, { 2.8, 2.9, 3.0 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 11, values = {
                { 58.2, 60.1, 62.8 }, { 17.3, 19.6, 22.1 }, { 6.8, 8.2, 9.1 }, { 10.0, 10.5, 11.2 }, { 3.0, 3.1, 3.2 }, { 4.7, 5.0, 5.3 }, { 3.9, 4.9, 5.8 }, { 2.9, 3.0, 3.1 } } },
        },
        overall = { name = "all heroic bosses", window = 11, values = {
            { 56.2, 59.5, 61.4 }, { 16.7, 19.0, 21.1 }, { 7.4, 8.5, 9.5 }, { 10.0, 10.6, 11.3 }, { 2.9, 3.1, 3.2 }, { 4.6, 5.0, 5.3 }, { 3.5, 4.5, 5.4 }, { 2.8, 3.0, 3.1 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 10, values = {
                { 51.7, 53.6, 55.5 }, { 13.7, 15.1, 15.9 }, { 8.5, 9.6, 10.7 }, { 9.5, 9.9, 10.2 }, { 2.7, 2.8, 2.9 }, { 4.5, 4.6, 4.8 }, { 3.6, 4.7, 5.3 }, { 2.5, 2.6, 2.7 } } },
            [2825] = { name = "Den of Nalorakk", window = 10, values = {
                { 49.8, 51.8, 53.6 }, { 13.0, 14.1, 15.4 }, { 8.2, 9.2, 10.0 }, { 9.0, 9.4, 9.8 }, { 2.6, 2.7, 2.8 }, { 4.2, 4.5, 4.7 }, { 4.4, 4.7, 5.1 }, { 2.5, 2.6, 2.6 } } },
            [1762] = { name = "Kings' Rest", window = 10, values = {
                { 53.1, 54.4, 56.2 }, { 13.9, 15.3, 16.0 }, { 8.6, 9.2, 9.9 }, { 9.4, 9.9, 10.4 }, { 2.8, 2.9, 3.0 }, { 4.5, 4.7, 4.8 }, { 4.0, 4.6, 5.1 }, { 2.7, 2.7, 2.8 } } },
            [2813] = { name = "Murder Row", window = 10, values = {
                { 50.0, 51.8, 54.0 }, { 12.8, 13.9, 15.0 }, { 8.6, 9.0, 9.8 }, { 9.2, 9.5, 10.2 }, { 2.7, 2.8, 2.9 }, { 4.3, 4.5, 4.7 }, { 3.9, 4.5, 5.0 }, { 2.6, 2.6, 2.7 } } },
            [2521] = { name = "Ruby Life Pools", window = 10, values = {
                { 52.1, 53.3, 55.6 }, { 13.7, 14.8, 15.8 }, { 8.7, 9.3, 9.7 }, { 9.5, 9.9, 10.3 }, { 2.8, 2.9, 2.9 }, { 4.6, 4.8, 4.9 }, { 3.8, 4.4, 5.3 }, { 2.6, 2.7, 2.7 } } },
            [1877] = { name = "Temple of Sethraliss", window = 9, values = {
                { 50.2, 52.1, 54.1 }, { 12.7, 13.6, 14.7 }, { 8.9, 9.4, 10.1 }, { 9.2, 9.9, 10.2 }, { 2.7, 2.8, 2.9 }, { 4.8, 4.9, 5.1 }, { 3.6, 4.3, 5.0 }, { 2.5, 2.6, 2.7 } } },
            [2859] = { name = "The Blinding Vale", window = 10, values = {
                { 53.2, 54.3, 56.6 }, { 13.7, 14.7, 15.7 }, { 9.2, 9.8, 10.6 }, { 9.4, 9.8, 10.4 }, { 2.8, 2.9, 3.0 }, { 4.7, 4.8, 4.9 }, { 4.1, 4.5, 5.1 }, { 2.6, 2.7, 2.8 } } },
            [2923] = { name = "Voidscar Arena", window = 9, values = {
                { 51.0, 52.9, 55.0 }, { 13.4, 14.7, 15.8 }, { 8.4, 9.0, 10.0 }, { 9.3, 9.7, 10.0 }, { 2.8, 2.9, 3.0 }, { 4.5, 4.6, 4.7 }, { 3.7, 4.5, 5.3 }, { 2.6, 2.7, 2.7 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 10, values = {
            { 50.8, 53.2, 55.2 }, { 13.3, 14.6, 15.7 }, { 8.6, 9.3, 10.1 }, { 9.3, 9.8, 10.2 }, { 2.7, 2.8, 2.9 }, { 4.5, 4.7, 4.8 }, { 3.9, 4.5, 5.1 }, { 2.6, 2.6, 2.7 } } },
    },

    -- /ob bars: role for role on the keys your other melee specs use
    -- (binds are account-wide): the spender on 1 (Chaos Strike, Annihilation
    -- in demon form), the AoE spender on 2, Throw Glaive on 3 (it turns into
    -- Reaver's Glaive), Felblade on 4, Immolation Aura on 5, Eye Beam (every
    -- ~21s) on Q, Essence Break on G, Metamorphosis (every ~2 min) at the
    -- cursor on Shift-1, The Hunt on Shift-2, Vengeful Retreat on R.
    -- Interrupt Shift-E, stun Shift-Q, defensives on ` / Shift-`, Fel Rush
    -- on F. One layout for raid and M+.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 162794, note = "Chaos Strike / Annihilation: most pressed (~19 Annihilations a minute in raid)" },
        { slot = 2,  key = "2",       spellId = 188499, note = "Blade Dance / Death Sweep: on cooldown, before Annihilation" },
        { slot = 3,  key = "3",       spellId = 185123, note = "Throw Glaive: turns into Reaver's Glaive (~5 a minute)" },
        { slot = 4,  key = "4",       spellId = 232893, note = "Felblade: Fury, and back into melee" },
        { slot = 5,  key = "5",       spellId = 258920, note = "Immolation Aura: before it reaches 2 charges" },
        { slot = 6,  key = "Q",       spellId = 198013, note = "Eye Beam: every ~21s, with Vengeful Retreat" },
        { slot = 7,  key = "G",       spellId = 258860, note = "Essence Break: on cooldown (~31s)" },
        { slot = 61, key = "Shift-1", macro = { name = "OB Meta", spells = { 191427 }, cursor = true },
          note = "Metamorphosis at your cursor: every ~2 min, after Eye Beam" },
        { slot = 62, key = "Shift-2", spellId = 370965, note = "The Hunt: on cooldown (~61s), when Reaver's Glaive isn't up" },
        { slot = 67, key = "R",       spellId = 198793, note = "Vengeful Retreat: with Eye Beam (Initiative)" },
        { slot = 63, key = "Shift-3", macro = { name = "OB Misery", spells = { 207684 }, cursor = true },
          note = "Sigil of Misery at your cursor: fear a pack (M+)" },
        { slot = 64, key = "Shift-4", spellId = 217832, note = "Imprison (M+)" },
        { slot = 65, key = "Shift-5", spellId = 278326, note = "Consume Magic: an enemy buff (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 179057, note = "Chaos Nova: stun a pack" },
        { slot = 50, key = "Shift-E", spellId = 183752, note = "Disrupt: interrupt" },
        { slot = 70, key = "F",       spellId = 195072, note = "Fel Rush: movement, mind where you land" },
        { slot = 55, key = "`",       spellId = 198589, note = "Blur: defensive" },
        { slot = 56, key = "Shift-`", spellId = 196718, note = "Darkness: raid / group defensive" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Aldrachi Reaver),
    -- checked against the top parses and runs.
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 258920, text = "Immolation Aura 1s before the pull" },
            { spellId = 370965, text = "The Hunt, potion and trinket, Reaver's Glaive" },
            { spellId = 198013, text = "Eye Beam, Essence Break, Death Sweep, Annihilation" },
            { spellId = 191427, text = "Vengeful Retreat and Metamorphosis, Eye Beam again" },
        } },
        { title = "Single target (raid)", content = "raid", lines = {
            { spellId = 370965, text = "The Hunt when Reaver's Glaive isn't up" },
            { spellId = 442294, text = "Reaver's Glaive" },
            { spellId = 258860, text = "Essence Break" },
            { spellId = 198013, text = "Vengeful Retreat with Eye Beam" },
            { spellId = 210152, text = "Death Sweep, Metamorphosis (Eye Beam first if <10s away)" },
            { spellId = 201427, text = "Annihilation, Blade Dance, Chaos Strike" },
            { spellId = 258920, text = "Immolation Aura, then Felblade" },
        } },
        { title = "Mythic+", content = "dungeon", lines = {
            { spellId = 258920, text = "Immolation Aura at 2 charges" },
            { spellId = 258860, text = "Essence Break" },
            { spellId = 188499, text = "Blade Dance with Glaive Flurry (no Rending Strike)" },
            { spellId = 162794, text = "Chaos Strike with Glaive Flurry and Rending Strike" },
            { spellId = 442294, text = "Reaver's Glaive, then Vengeful Retreat with Eye Beam" },
            { spellId = 210152, text = "Death Sweep; Metamorphosis when Eye Beam is on cooldown" },
            { spellId = 201427, text = "Annihilation, Blade Dance, Chaos Strike, Felblade" },
        } },
    },

    -- Stats: Method: Crit > Mastery > Haste > Versatility (Aldrachi Reaver
    -- leans further to Crit).
    statPriority = { CRIT = 1, MASTERY = 2, HASTE = 3, VERS = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 162794, st = 1, aoe = 1, alt = { 201427 }, note = "Chaos Strike / Annihilation" },
        { spellId = 188499, st = 1, aoe = 1, alt = { 210152 }, note = "Blade Dance / Death Sweep" },
        { spellId = 185123, st = 1, aoe = 1, alt = { 442294 }, note = "Reaver's Glaive" },
        { spellId = 232893, st = 2, aoe = 2, note = "Fury, gap closer" },
        { spellId = 258920, st = 2, aoe = 1, note = "Two charges" },
        { spellId = 198013, st = 2, aoe = 1, note = "Every ~21s" },
        { spellId = 258860, st = 2, aoe = 2, note = "Every ~31s" },
        { spellId = 198793, st = 2, aoe = 2, note = "With Eye Beam" },
        { spellId = 370965, st = 3, aoe = 3, note = "Every ~61s" },
        { spellId = 191427, st = 3, aoe = 3, alt = { 200166 }, note = "Every ~2 min" },
        { spellId = 183752, st = 2, aoe = 2, note = "Interrupt" },
    },
})
