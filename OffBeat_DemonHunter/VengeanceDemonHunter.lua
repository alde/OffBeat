local OffBeat = _G.OffBeat

-- Vengeance Demon Hunter, Method 12.1.5 (14 Oct 2026), checked against the
-- top 40 heroic parses on every Venomous Abyss boss (354) and the top 40
-- timed runs per Season 2 dungeon (320 runs; Warcraft Logs, Oct 2026).
-- Every one of them is Annihilator (no Reaver's Glaive in any log), so the
-- sheet is Method's Annihilator priority.
--
-- Metamorphosis is a rotational button for Annihilator (every ~12s,
-- Untethered Rage / Voidfall reset it): ~2.4 a minute in raid. On
-- cooldown for every top player: Immolation Aura ~11s, Fiery Brand and
-- Sigil of Flame ~31s, Fel Devastation ~43s, Sigil of Spite ~62s, Demon
-- Spikes ~6s (Feed the Demon). Fracture and Soul Cleave are the busiest
-- buttons (~19 and ~18 a minute). Soul Carver is barely taken (18%).
OffBeat:RegisterProfile({
    meta = {
        name = "Vengeance Demon Hunter",
        specId = 581,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    rotationSpells = {
        { spellId = 263642 }, -- Fracture
        { spellId = 228477 }, -- Soul Cleave
        { spellId = 247454 }, -- Spirit Bomb
        { spellId = 204596 }, -- Sigil of Flame
        { spellId = 258920 }, -- Immolation Aura
        { spellId = 212084 }, -- Fel Devastation
        { spellId = 204021 }, -- Fiery Brand
        { spellId = 390163 }, -- Sigil of Spite
        { spellId = 207407 }, -- Soul Carver
        { spellId = 232893 }, -- Felblade
        { spellId = 187827 }, -- Metamorphosis
        { spellId = 203720 }, -- Demon Spikes
    },

    -- Your own buffs. 12.1 hides them in combat, so these show out of
    -- combat and whenever the game lets them through.
    trackedAuras = {
        { spellId = 203819,  name = "Demon Spikes",    baseDuration = 6,  stacks = false },
        { spellId = 187827,  name = "Metamorphosis",   baseDuration = 15, stacks = false },
        { spellId = 1270444, name = "Untethered Rage", baseDuration = 12, stacks = false },
        { spellId = 1253304, name = "Voidfall",        baseDuration = 30, stacks = true },
    },

    keyCooldown = {
        spellId = 204021,
        name = "Fiery Brand",
        duration = 10,
    },

    failNudges = {
        { error = "range", spells = { 263642, 228477, 247454 }, name = "Melee out of range",
          text = "Out of range: Felblade back in, Throw Glaive, Sigil of Flame at the cursor" },
    },

    -- On cooldown for every top player.
    idleCooldowns = {
        { spellId = 258920, name = "Immolation Aura" },
        { spellId = 204021, name = "Fiery Brand" },
        { spellId = 204596, name = "Sigil of Flame" },
        { spellId = 212084, name = "Fel Devastation" },
        { spellId = 390163, name = "Sigil of Spite" },
    },

    -- Method: Metamorphosis when Untethered Rage is about to expire.
    procTracking = {
        {
            procAura = 1270444,
            consumeSpells = { 187827 },
            window = 0.5,
            name = "Untethered Rage",
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. Dungeons (by instance ID): the top 40 timed runs,
    -- per minute in combat (Warcraft Logs' pulls).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",  all = true },
            { name = "Fracture",        spells = { 263642 } },
            { name = "Soul Cleave",     spells = { 228477 } },
            { name = "Spirit Bomb",     spells = { 247454 } },
            { name = "Immolation Aura", spells = { 258920 } },
            { name = "Metamorphosis",   spells = { 187827 } },
            { name = "Demon Spikes",    spells = { 203720 } },
            { name = "Fiery Brand / Fel Devastation", spells = { 204021, 212084 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", values = {
                { 50.4, 53.1, 55.8 }, { 15.8, 16.7, 17.0 }, { 14.4, 15.0, 16.2 }, { 3.1, 3.5, 3.6 }, { 4.5, 4.7, 5.0 }, { 1.9, 2.0, 2.2 }, { 4.3, 4.8, 7.1 }, { 1.6, 1.9, 2.2 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", values = {
                { 59.3, 62.6, 66.2 }, { 18.2, 19.2, 20.0 }, { 16.9, 18.5, 20.0 }, { 3.5, 4.0, 4.3 }, { 4.8, 5.1, 5.4 }, { 2.3, 2.6, 2.8 }, { 4.7, 6.5, 7.6 }, { 1.7, 2.1, 2.6 } } },
            [3445] = { name = "Entombed Sentinels", values = {
                { 57.4, 60.5, 63.4 }, { 17.3, 18.2, 19.2 }, { 16.2, 17.8, 18.9 }, { 3.4, 3.8, 4.1 }, { 4.6, 5.0, 5.3 }, { 2.3, 2.4, 2.5 }, { 4.8, 6.0, 7.8 }, { 1.7, 2.2, 2.6 } } },
            [3455] = { name = "Vashnik the Malignant", values = {
                { 59.0, 63.0, 65.1 }, { 18.3, 18.9, 20.1 }, { 17.6, 19.1, 20.1 }, { 3.3, 3.8, 4.2 }, { 4.7, 5.2, 5.5 }, { 2.3, 2.5, 2.7 }, { 4.4, 6.2, 7.8 }, { 1.5, 2.1, 2.5 } } },
            [3497] = { name = "The Lost Explorers", values = {
                { 58.3, 61.1, 63.6 }, { 17.5, 18.8, 19.6 }, { 16.4, 17.9, 19.5 }, { 3.4, 3.8, 4.3 }, { 4.5, 5.0, 5.4 }, { 2.1, 2.4, 2.6 }, { 4.8, 6.2, 7.9 }, { 1.8, 2.3, 2.8 } } },
            [3420] = { name = "Sszorak", values = {
                { 61.6, 63.8, 66.6 }, { 18.8, 19.6, 20.2 }, { 18.2, 19.6, 20.9 }, { 3.6, 4.0, 4.5 }, { 4.7, 5.0, 5.6 }, { 2.4, 2.6, 2.8 }, { 5.0, 7.0, 8.0 }, { 1.5, 1.8, 2.5 } } },
            [3421] = { name = "The Twin Fangs", values = {
                { 60.7, 64.2, 66.7 }, { 18.8, 19.3, 20.2 }, { 18.2, 19.6, 21.4 }, { 3.7, 4.0, 4.4 }, { 5.0, 5.2, 5.5 }, { 2.4, 2.5, 2.7 }, { 4.5, 6.4, 8.2 }, { 1.7, 2.1, 2.5 } } },
            [3429] = { name = "The Coiled Altar", values = {
                { 56.3, 60.7, 64.3 }, { 17.6, 18.5, 18.9 }, { 16.1, 17.8, 18.6 }, { 3.5, 3.8, 4.2 }, { 4.8, 5.1, 5.2 }, { 2.1, 2.4, 2.5 }, { 4.6, 7.1, 7.8 }, { 1.6, 2.1, 2.6 } } },
            [3379] = { name = "Nymrissa Wavecaller", values = {
                { 54.2, 60.5, 63.9 }, { 16.7, 18.0, 19.1 }, { 15.0, 17.5, 19.5 }, { 3.4, 3.8, 4.3 }, { 4.4, 5.0, 5.3 }, { 2.1, 2.4, 2.6 }, { 4.5, 5.8, 7.5 }, { 1.7, 2.3, 2.8 } } },
        },
        overall = { name = "all heroic bosses", values = {
            { 57.1, 60.9, 64.5 }, { 17.3, 18.7, 19.6 }, { 16.3, 18.1, 19.8 }, { 3.4, 3.8, 4.3 }, { 4.7, 5.0, 5.4 }, { 2.2, 2.4, 2.6 }, { 4.6, 6.2, 7.7 }, { 1.6, 2.1, 2.6 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", values = {
                { 57.1, 58.7, 60.7 }, { 17.7, 18.3, 18.8 }, { 15.7, 17.0, 18.3 }, { 3.5, 3.6, 3.9 }, { 5.0, 5.3, 5.5 }, { 2.1, 2.2, 2.3 }, { 4.7, 4.9, 7.4 }, { 1.8, 2.1, 2.4 } } },
            [2825] = { name = "Den of Nalorakk", values = {
                { 56.8, 58.6, 59.9 }, { 17.6, 18.3, 18.7 }, { 15.4, 16.7, 18.1 }, { 3.4, 3.7, 3.9 }, { 5.0, 5.3, 5.5 }, { 2.0, 2.2, 2.3 }, { 4.9, 5.8, 7.4 }, { 1.8, 2.0, 2.5 } } },
            [1762] = { name = "Kings' Rest", values = {
                { 58.5, 59.6, 61.4 }, { 18.1, 18.6, 19.0 }, { 16.7, 17.8, 19.0 }, { 3.3, 3.7, 3.9 }, { 5.1, 5.3, 5.5 }, { 2.1, 2.2, 2.3 }, { 4.7, 5.1, 7.7 }, { 1.7, 2.0, 2.4 } } },
            [2813] = { name = "Murder Row", values = {
                { 57.7, 59.1, 60.7 }, { 17.8, 18.2, 18.7 }, { 15.9, 17.3, 18.5 }, { 3.4, 3.7, 3.9 }, { 5.1, 5.3, 5.6 }, { 2.1, 2.2, 2.3 }, { 4.8, 5.7, 7.6 }, { 2.0, 2.3, 2.5 } } },
            [2521] = { name = "Ruby Life Pools", values = {
                { 58.1, 60.1, 62.0 }, { 18.2, 18.6, 19.2 }, { 16.1, 17.7, 18.8 }, { 3.5, 3.8, 4.0 }, { 5.1, 5.3, 5.5 }, { 2.2, 2.3, 2.4 }, { 4.8, 5.7, 7.7 }, { 1.8, 2.2, 2.5 } } },
            [1877] = { name = "Temple of Sethraliss", values = {
                { 55.7, 57.4, 59.7 }, { 17.7, 18.4, 18.8 }, { 15.1, 16.8, 18.1 }, { 3.3, 3.7, 4.0 }, { 4.9, 5.1, 5.4 }, { 2.0, 2.2, 2.3 }, { 4.6, 5.5, 7.3 }, { 1.8, 2.1, 2.4 } } },
            [2859] = { name = "The Blinding Vale", values = {
                { 58.7, 60.7, 62.3 }, { 18.4, 18.9, 19.3 }, { 16.5, 18.0, 18.7 }, { 3.6, 3.8, 4.1 }, { 5.0, 5.3, 5.5 }, { 2.2, 2.3, 2.3 }, { 4.8, 7.0, 7.7 }, { 1.9, 2.1, 2.4 } } },
            [2923] = { name = "Voidscar Arena", values = {
                { 57.0, 58.6, 60.3 }, { 17.6, 18.2, 18.5 }, { 16.2, 17.1, 17.9 }, { 3.3, 3.7, 4.0 }, { 4.8, 5.1, 5.3 }, { 2.1, 2.2, 2.3 }, { 4.6, 6.3, 7.6 }, { 1.8, 2.2, 2.4 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", values = {
            { 57.3, 59.1, 61.2 }, { 17.8, 18.4, 18.9 }, { 16.0, 17.2, 18.6 }, { 3.4, 3.7, 4.0 }, { 5.0, 5.2, 5.5 }, { 2.1, 2.2, 2.3 }, { 4.7, 6.0, 7.6 }, { 1.8, 2.1, 2.5 } } },
    },

    -- /ob bars: role for role on the keys your other melee specs use
    -- (binds are account-wide): Soul Cleave on 1, Spirit Bomb on 2, Fracture
    -- (most pressed) on 3, Felblade on 4, Immolation Aura on 5, Fiery Brand
    -- on Q, Fel Devastation on G, Sigil of Flame at the cursor on E,
    -- Metamorphosis (~2.4 a minute) on R, Sigil of Spite on Shift-1, Demon
    -- Spikes on ` (your active mitigation), Torment on X. Interrupt
    -- Shift-E, stun Shift-Q, Vengeful Retreat on F. One layout for raid and
    -- M+.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 228477, note = "Soul Cleave: ~18 a minute, at 3 Soul Fragments" },
        { slot = 2,  key = "2",       spellId = 247454, note = "Spirit Bomb: at 6 Soul Fragments" },
        { slot = 3,  key = "3",       spellId = 263642, note = "Fracture: most pressed, before 2 charges" },
        { slot = 4,  key = "4",       spellId = 232893, note = "Felblade: filler, back into melee" },
        { slot = 5,  key = "5",       spellId = 258920, note = "Immolation Aura: on cooldown (~11s)" },
        { slot = 6,  key = "Q",       spellId = 204021, note = "Fiery Brand: before it reaches 2 charges (~31s)" },
        { slot = 7,  key = "G",       spellId = 212084, note = "Fel Devastation: on cooldown (~43s)" },
        { slot = 8,  key = "E",       macro = { name = "OB SigilFlame", spells = { 204596 }, cursor = true },
          note = "Sigil of Flame at your cursor: on cooldown (~31s)" },
        { slot = 67, key = "R",       spellId = 187827, note = "Metamorphosis: at 0-1 Voidfall or as Untethered Rage ends (~every 12s)" },
        { slot = 61, key = "Shift-1", macro = { name = "OB Spite", spells = { 390163 }, cursor = true },
          note = "Sigil of Spite at your cursor: on cooldown (~62s)" },
        { slot = 12, key = "X",       spellId = 185245, note = "Torment: taunt" },
        { slot = 63, key = "Shift-3", macro = { name = "OB Misery", spells = { 207684 }, cursor = true },
          note = "Sigil of Misery at your cursor: fear a pack (M+)" },
        { slot = 64, key = "Shift-4", macro = { name = "OB Chains", spells = { 202138 }, cursor = true },
          note = "Sigil of Chains at your cursor: pull a pack together (all top M+ runs)" },
        { slot = 65, key = "Shift-5", spellId = 278326, note = "Consume Magic: an enemy buff (M+)" },
        { slot = 62, key = "Shift-2", spellId = 217832, note = "Imprison (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 179057, note = "Chaos Nova: stun a pack" },
        { slot = 50, key = "Shift-E", spellId = 183752, note = "Disrupt: interrupt" },
        { slot = 70, key = "F",       spellId = 198793, note = "Vengeful Retreat: movement" },
        { slot = 55, key = "`",       spellId = 203720, note = "Demon Spikes: active mitigation (~6 a minute)" },
        { slot = 56, key = "Shift-`", spellId = 196718, note = "Darkness: group defensive" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Annihilator); the
    -- priority is the same for any number of targets.
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 258920, text = "Immolation Aura before the pull (in AoE: on the pull)" },
            { spellId = 390163, text = "Sigil of Spite, Fiery Brand" },
            { spellId = 263642, text = "Fracture under 4 Soul Fragments, Spirit Bomb, Metamorphosis" },
        } },
        { title = "Priority", lines = {
            { spellId = 204021, text = "Fiery Brand at 3 Voidfall with Metamorphosis up, or before 2 charges" },
            { spellId = 187827, text = "Metamorphosis at 0-1 Voidfall, or as Untethered Rage ends" },
            { spellId = 247454, text = "At 3 Voidfall: Spirit Bomb at 6 souls, else Soul Cleave at 3" },
            { spellId = 263642, text = "Fracture before 2 charges" },
            { spellId = 258920, text = "Immolation Aura, Sigil of Spite" },
            { spellId = 228477, text = "Soul Cleave at 3 Soul Fragments" },
            { spellId = 212084, text = "Fel Devastation (Method: with 2s+ of Fiery Brand left)" },
            { spellId = 204596, text = "Sigil of Flame, Fracture, Felblade, Soul Cleave" },
        } },
        { title = "Defensives", lines = {
            { spellId = 203720, text = "Demon Spikes on the gaps Fiery Brand and Metamorphosis leave" },
            { text = "Keep Immolation Aura and Sigil of Flame rolling: delays add up" },
        } },
    },

    -- Stats: Method (defensive): Haste > Crit = Versatility = Mastery.
    statPriority = { HASTE = 1, CRIT = 2, VERS = 2, MASTERY = 2 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 263642, st = 1, aoe = 1, note = "Most pressed" },
        { spellId = 228477, st = 1, aoe = 1, note = "Spender" },
        { spellId = 247454, st = 1, aoe = 1, note = "6 souls" },
        { spellId = 258920, st = 1, aoe = 1, note = "Every ~11s" },
        { spellId = 187827, st = 2, aoe = 2, note = "Voidfall / Untethered Rage" },
        { spellId = 203720, st = 2, aoe = 2, note = "Active mitigation" },
        { spellId = 204021, st = 2, aoe = 2, note = "Every ~31s" },
        { spellId = 204596, st = 2, aoe = 2, note = "Every ~31s" },
        { spellId = 212084, st = 2, aoe = 2, note = "Every ~43s" },
        { spellId = 232893, st = 2, aoe = 2, note = "Filler" },
        { spellId = 390163, st = 3, aoe = 3, note = "Every ~62s" },
        { spellId = 183752, st = 2, aoe = 2, note = "Interrupt" },
    },
})
