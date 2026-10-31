local OffBeat = _G.OffBeat

-- Arcane Mage, Method 12.1.5 (16 Oct 2026), checked against the top 40
-- heroic parses on every Venomous Abyss boss (360) and the top 40 timed
-- runs per Season 2 dungeon (317 runs; Warcraft Logs, Oct 2026). Every
-- one of them is Sunfury (Method also has Spellslinger builds; no top
-- player uses one), so the sheet follows Method's Sunfury priority.
--
-- Arcane Surge every ~92s and Touch of the Magi every ~46s, both on
-- cooldown: Touch lands within 8s of every Surge (big burn) and once
-- between them (miniburn), after an Arcane Barrage 82% of the time.
-- Inside Surge's ~17s the top players fit 6 Arcane Missiles, 4 Arcane
-- Barrages and 2 Prismatic Bolts, raid and M+ alike. Evocation, Presence
-- of Mind and Arcane Pulse aren't pressed by anyone.
OffBeat:RegisterProfile({
    meta = {
        name = "Arcane Mage",
        specId = 62,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Pressed by the top players. Prismatic Bolt (1295924) replaces Arcane
    -- Blast on its proc (the proc aura is 1295942).
    rotationSpells = {
        { spellId = 5143 },    -- Arcane Missiles
        { spellId = 44425 },   -- Arcane Barrage
        { spellId = 1295924 }, -- Prismatic Bolt
        { spellId = 30451 },   -- Arcane Blast
        { spellId = 153626 },  -- Arcane Orb
        { spellId = 1449 },    -- Arcane Explosion
        { spellId = 365350 },  -- Arcane Surge
        { spellId = 321507 },  -- Touch of the Magi
    },

    -- No mistake rules: the priority is about Arcane Salvo and Cumulative
    -- Power stacks, which the game hides in combat, and the logs don't
    -- support a cast-order rule strong enough to flag.

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through. The Arcane Surge buff is 365362, not the spell's ID; Arcane
    -- Salvo's stacks are 1242974.
    trackedAuras = {
        { spellId = 263725,  name = "Clearcasting",     baseDuration = 15, stacks = true },
        { spellId = 365362,  name = "Arcane Surge",     baseDuration = 17, stacks = false },
        { spellId = 1242974, name = "Arcane Salvo",     baseDuration = 0,  stacks = true },
        { spellId = 451038,  name = "Arcane Soul",      baseDuration = 4,  stacks = false },
        { spellId = 1296930, name = "Cumulative Power", baseDuration = 0,  stacks = true },
        { spellId = 1295942, name = "Prismatic Bolt!",  baseDuration = 0,  stacks = false },
    },

    keyCooldown = {
        spellId = 365350,
        name = "Arcane Surge",
        duration = 17,
    },

    failNudges = {
        { error = "moving", spells = { 30451, 1295924, 5143 }, name = "Cast while moving",
          text = "Moving: Arcane Barrage, Arcane Orb, Shimmer" },
    },

    -- Countdown to Arcane Surge: Touch of the Magi should come up with it
    -- (Method: always together when they line up, never delay a Touch).
    prep = {
        spellId = 365350, name = "Arcane Surge", cooldown = 90, lead = 5,
        hint = "Arcane Surge, Arcane Missiles, Arcane Barrage, then Touch of the Magi",
        checks = {
            { name = "Touch of the Magi", ready = 321507, cooldown = 45 },
        },
    },

    -- On cooldown for every top player: Arcane Surge every ~92s, Touch of
    -- the Magi every ~46s. The cooldowns are given because combat hides
    -- them and the game's base cooldown for Touch of the Magi reads 15s.
    idleCooldowns = {
        { spellId = 365350, name = "Arcane Surge", cooldown = 90 },
        { spellId = 321507, name = "Touch of the Magi", cooldown = 45 },
    },

    -- Coaching: Arcane Surge (~17s), the big burn. The same in raid and
    -- M+: 6 Missiles, 4 Barrages, 2 Prismatic Bolts.
    windows = {
        {
            name = "Arcane Surge",
            trigger = 365350,
            duration = 17,
            note = "Arcane Missiles, Arcane Barrage, Touch of the Magi, then Missiles below 12 Arcane Salvo "
                .. "and Barrage at 25 (spam it in Arcane Soul). Top players: 6 Missiles, 4 Barrages, 2 Prismatic Bolts.",
            goals = {
                { name = "Arcane Barrage", spells = { 44425 }, min = 4 },
                { name = "Arcane Missiles", spells = { 5143 }, min = 6 },
                { name = "Prismatic Bolt", spells = { 1295924 }, min = 2 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Arcane Barrages per Arcane Surge.
    -- Dungeons (by instance ID): the top 40 timed runs, per minute in combat
    -- (Warcraft Logs' pulls). Arcane Explosion only counts in M+ and on
    -- Ula'tek.
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",   all = true },
            { name = "Arcane Missiles",  spells = { 5143 } },
            { name = "Arcane Barrage",   spells = { 44425 } },
            { name = "Prismatic Bolt",   spells = { 1295924 } },
            { name = "Arcane Blast",     spells = { 30451 } },
            { name = "Arcane Orb",       spells = { 153626 } },
            { name = "Arcane Explosion", spells = { 1449 } },
            { name = "Arcane Surge / Touch of the Magi", spells = { 365350, 321507 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 4, values = {
                { 38.4, 39.4, 40.2 }, { 13.8, 14.2, 14.6 }, { 12.0, 12.4, 12.9 }, { 4.7, 5.2, 5.4 }, { 3.2, 3.9, 5.2 }, { 0.5, 0.8, 1.1 }, { 0.4, 0.7, 1.2 }, { 1.7, 1.8, 1.9 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 4, values = {
                { 43.0, 43.9, 44.8 }, { 15.9, 16.6, 17.1 }, { 14.1, 14.5, 14.9 }, { 5.7, 6.2, 6.8 }, { 2.3, 4.1, 5.1 }, { 0.2, 0.5, 0.9 }, nil, { 2.0, 2.1, 2.2 } } },
            [3445] = { name = "Entombed Sentinels", window = 4, values = {
                { 42.3, 43.3, 43.9 }, { 15.4, 15.9, 16.6 }, { 13.5, 14.2, 14.7 }, { 5.7, 6.0, 6.5 }, { 2.1, 3.8, 5.3 }, { 0.3, 0.5, 0.7 }, nil, { 1.9, 2.1, 2.2 } } },
            [3455] = { name = "Vashnik the Malignant", window = 4, values = {
                { 43.9, 45.3, 46.3 }, { 16.0, 16.9, 17.6 }, { 14.4, 15.2, 16.0 }, { 5.8, 6.3, 6.7 }, { 2.6, 4.3, 5.5 }, { 0.3, 0.5, 0.9 }, nil, { 2.1, 2.2, 2.2 } } },
            [3497] = { name = "The Lost Explorers", window = 4, values = {
                { 44.4, 45.3, 46.6 }, { 16.7, 17.3, 17.8 }, { 14.8, 15.5, 16.6 }, { 6.0, 6.8, 7.2 }, { 1.5, 2.3, 3.6 }, { 0.4, 0.4, 0.8 }, nil, { 2.1, 2.2, 2.4 } } },
            [3420] = { name = "Sszorak", window = 4, values = {
                { 43.7, 44.9, 46.3 }, { 16.7, 17.5, 18.3 }, { 14.7, 15.1, 15.7 }, { 6.4, 6.7, 7.2 }, { 1.6, 3.0, 4.0 }, { 0.2, 0.5, 0.8 }, nil, { 2.0, 2.2, 2.2 } } },
            [3421] = { name = "The Twin Fangs", window = 4, values = {
                { 43.4, 44.1, 45.4 }, { 16.3, 17.1, 17.8 }, { 14.4, 15.0, 15.6 }, { 5.8, 6.4, 6.8 }, { 2.2, 3.6, 4.6 }, { 0.2, 0.5, 0.8 }, nil, { 2.0, 2.1, 2.2 } } },
            [3429] = { name = "The Coiled Altar", window = 4, values = {
                { 42.3, 43.4, 44.3 }, { 15.4, 16.1, 17.0 }, { 13.1, 13.8, 14.6 }, { 5.5, 5.8, 6.3 }, { 2.5, 3.8, 5.3 }, { 0.2, 0.4, 0.7 }, nil, { 1.8, 1.9, 2.0 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 4, values = {
                { 41.4, 43.0, 44.4 }, { 14.9, 16.1, 16.6 }, { 13.7, 14.6, 15.0 }, { 5.3, 5.8, 6.4 }, { 2.2, 4.4, 5.2 }, { 0.3, 0.5, 0.9 }, nil, { 1.9, 2.1, 2.2 } } },
        },
        overall = { name = "all heroic bosses", window = 4, values = {
            { 42.3, 43.8, 45.3 }, { 15.5, 16.5, 17.4 }, { 13.7, 14.5, 15.3 }, { 5.5, 6.1, 6.7 }, { 2.2, 3.6, 5.0 }, { 0.3, 0.5, 0.8 }, nil, { 1.9, 2.1, 2.2 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 4, values = {
                { 38.0, 39.0, 39.7 }, { 13.8, 14.1, 14.6 }, { 12.3, 12.6, 13.2 }, { 4.5, 4.7, 4.9 }, { 3.6, 4.1, 4.9 }, { 0.5, 0.7, 0.9 }, { 0.2, 0.4, 0.7 }, { 1.7, 1.8, 1.9 } } },
            [2825] = { name = "Den of Nalorakk", window = 4, values = {
                { 37.7, 38.4, 39.2 }, { 13.5, 13.8, 14.4 }, { 12.1, 12.6, 13.0 }, { 4.4, 4.6, 4.7 }, { 3.3, 4.0, 4.6 }, { 0.5, 0.8, 1.0 }, { 0.4, 0.7, 1.1 }, { 1.8, 1.8, 1.9 } } },
            [1762] = { name = "Kings' Rest", window = 4, values = {
                { 39.4, 40.1, 41.0 }, { 14.1, 14.5, 14.8 }, { 12.6, 12.9, 13.4 }, { 4.5, 4.8, 5.0 }, { 3.7, 4.5, 5.1 }, { 0.6, 0.9, 1.1 }, { 0.3, 0.5, 0.9 }, { 1.8, 1.9, 1.9 } } },
            [2813] = { name = "Murder Row", window = 3, values = {
                { 38.4, 39.7, 41.1 }, { 13.7, 14.2, 14.7 }, { 12.3, 12.5, 13.2 }, { 4.3, 4.7, 5.0 }, { 3.9, 4.7, 5.7 }, { 0.5, 0.6, 0.9 }, { 0.2, 0.7, 1.1 }, { 1.8, 1.8, 1.9 } } },
            [2521] = { name = "Ruby Life Pools", window = 4, values = {
                { 38.5, 39.7, 40.6 }, { 14.1, 14.4, 14.9 }, { 12.3, 12.8, 13.4 }, { 4.5, 4.6, 4.9 }, { 3.7, 4.2, 4.7 }, { 0.4, 0.7, 0.9 }, { 0.3, 0.5, 0.9 }, { 1.8, 1.8, 1.9 } } },
            [1877] = { name = "Temple of Sethraliss", window = 4, values = {
                { 38.4, 39.3, 40.3 }, { 14.2, 14.4, 14.6 }, { 12.0, 12.6, 13.3 }, { 4.6, 4.8, 5.0 }, { 3.5, 4.1, 4.6 }, { 0.6, 0.8, 1.0 }, { 0.4, 0.7, 1.0 }, { 1.7, 1.8, 1.8 } } },
            [2859] = { name = "The Blinding Vale", window = 3, values = {
                { 39.8, 40.7, 41.3 }, { 14.5, 15.0, 15.5 }, { 12.9, 13.2, 13.7 }, { 4.7, 4.9, 5.3 }, { 3.4, 4.3, 4.9 }, { 0.4, 0.7, 0.9 }, { 0.2, 0.5, 0.8 }, { 1.8, 1.8, 1.9 } } },
            [2923] = { name = "Voidscar Arena", window = 4, values = {
                { 39.4, 40.3, 40.8 }, { 14.0, 14.5, 14.8 }, { 12.4, 13.0, 13.6 }, { 4.3, 4.8, 5.0 }, { 3.8, 4.4, 5.0 }, { 0.7, 0.8, 1.1 }, { 0.4, 0.8, 1.0 }, { 1.8, 1.9, 1.9 } } },
        },
        -- Dummies with /ob mode mythic: all 317 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 4, values = {
            { 38.5, 39.6, 40.7 }, { 13.9, 14.4, 14.8 }, { 12.3, 12.8, 13.4 }, { 4.5, 4.7, 5.0 }, { 3.6, 4.2, 4.9 }, { 0.5, 0.7, 1.0 }, { 0.3, 0.5, 1.0 }, { 1.8, 1.8, 1.9 } } },
    },

    -- /ob bars: role for role on the keys your other specs use (binds are
    -- account-wide): Missiles (most pressed) on 1, Barrage on 2, Arcane
    -- Blast on 3 (it turns into Prismatic Bolt on the proc), Arcane Orb on
    -- 4, Arcane Surge (every ~92s) on Q, Touch of the Magi (every ~46s) on
    -- G, Arcane Explosion on E. Interrupt Shift-E, knockback Shift-Q,
    -- defensives on ` / Shift-`, Shimmer on F. Time Warp sits on F5, out of
    -- the way so you don't press it by accident. One layout for raid and
    -- M+. Polymorph, Arcane Intellect and anything not listed are left
    -- alone.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 5143,   note = "Arcane Missiles: your most pressed spell (~16 a minute), below 12 Arcane Salvo" },
        { slot = 2,  key = "2",       spellId = 44425,  note = "Arcane Barrage: at 25 Arcane Salvo, spam it in Arcane Soul" },
        { slot = 3,  key = "3",       spellId = 30451,  note = "Arcane Blast: filler, becomes Prismatic Bolt on the proc (~6 a minute)" },
        { slot = 4,  key = "4",       spellId = 153626, note = "Arcane Orb: Arcane Charges when you need them" },
        { slot = 6,  key = "Q",       spellId = 365350, note = "Arcane Surge: on cooldown (~92s), with Touch of the Magi" },
        { slot = 7,  key = "G",       spellId = 321507, note = "Touch of the Magi: on cooldown (~46s), right after an Arcane Barrage" },
        { slot = 8,  key = "E",       spellId = 1449,   note = "Arcane Explosion: packs in M+ (92% of top runs)" },
        { slot = 67, key = "R",       spellId = 55342,  note = "Mirror Image: on cooldown in M+ (all top runs)" },
        { slot = 71, key = "Shift-F", spellId = 110959, note = "Greater Invisibility: drops threat, less damage taken (91% of top M+ runs)" },
        { slot = 62, key = "Shift-2", spellId = 342245, note = "Alter Time: press again to go back (96% of top M+ runs)" },
        { slot = 63, key = "Shift-3", spellId = 31661,  note = "Dragon's Breath: disorient a pack (M+)" },
        { slot = 64, key = "Shift-4", spellId = 122,    note = "Frost Nova: root a pack (M+)" },
        { slot = 65, key = "Shift-5", spellId = 30449,  note = "Spellsteal: an enemy buff (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 157980, note = "Supernova: knock a pack up (79% of top M+ runs)" },
        { slot = 50, key = "Shift-E", spellId = 2139,   note = "Counterspell: interrupt" },
        { slot = 12, key = "X",       macro = { name = "OB RemoveCurse", spells = { 475 }, mouseover = true },
          note = "Remove Curse (mouseover): curses" },
        { slot = 70, key = "F",       spellId = 212653, alt = { 1953 }, note = "Shimmer / Blink: movement, you keep casting" },
        { slot = 25, key = "F5",      spellId = 80353,  note = "Time Warp: out of the way on purpose" },
        { slot = 55, key = "`",       spellId = 414658, alt = { 45438 }, note = "Ice Cold (Ice Block): long defensive, you keep casting" },
        { slot = 56, key = "Shift-`", spellId = 235450, note = "Prismatic Barrier: on cooldown in M+ (~1.7 a minute)" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Sunfury), checked
    -- against the top parses and runs.
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 365350, text = "Potion, precast Arcane Surge, trinket" },
            { spellId = 5143,   text = "Arcane Missiles, Arcane Barrage" },
            { spellId = 321507, text = "Touch of the Magi, then the priority" },
        } },
        { title = "Cooldowns", lines = {
            { spellId = 365350, text = "Arcane Surge on cooldown (~92s), Touch of the Magi with it" },
            { spellId = 321507, text = "Touch of the Magi on cooldown (~46s): never delay it, after a Barrage" },
        } },
        { title = "Priority (single target and AoE)", lines = {
            { spellId = 5143,    text = "Arcane Missiles below 12 Arcane Salvo" },
            { spellId = 44425,   text = "Arcane Barrage while Arcane Soul is up" },
            { spellId = 1295924, text = "Prismatic Bolt at 8 Cumulative Power, Arcane Soul down" },
            { spellId = 44425,   text = "Arcane Barrage at 25 Salvo, or 12+ with Clearcasting (AoE: or Orb)" },
            { spellId = 1295924, text = "Prismatic Bolt" },
            { spellId = 153626,  text = "Arcane Orb" },
            { spellId = 30451,   text = "Arcane Blast" },
        } },
        { title = "Mythic+", content = "dungeon", lines = {
            { spellId = 1449,  text = "Arcane Explosion on stacked packs (~0.6 a minute for top players)" },
            { spellId = 55342, text = "Mirror Image and Prismatic Barrier on cooldown" },
        } },
    },

    -- Stats: Method: Haste > Versatility > Crit > Mastery.
    statPriority = { HASTE = 1, VERS = 2, CRIT = 3, MASTERY = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 5143,   st = 1, aoe = 1, note = "Most pressed, builds Arcane Salvo" },
        { spellId = 44425,  st = 1, aoe = 1, note = "Salvo spender" },
        { spellId = 30451,  st = 1, aoe = 1, alt = { 1295924 }, note = "Filler / Prismatic Bolt" },
        { spellId = 153626, st = 2, aoe = 2, note = "Arcane Charges" },
        { spellId = 1449,            aoe = 2, note = "M+ packs" },
        { spellId = 321507, st = 2, aoe = 2, note = "Every ~46s" },
        { spellId = 365350, st = 3, aoe = 3, note = "Every ~92s" },
        { spellId = 212653, st = 3, aoe = 3, alt = { 1953 }, note = "Movement" },
        { spellId = 2139,   st = 2, aoe = 2, note = "Interrupt" },
    },
})
