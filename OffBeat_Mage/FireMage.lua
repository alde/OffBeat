local OffBeat = _G.OffBeat

-- Fire Mage, Method 12.1.5 (14 Oct 2026), checked against the top 40
-- heroic parses on every Venomous Abyss boss (360) and the top 40 timed
-- runs per Season 2 dungeon (320 runs; Warcraft Logs, Oct 2026). Every one
-- of them is Sunfury, as Method recommends (no Frostfire Bolt in any log).
--
-- One build everywhere: Combustion on cooldown (every ~61s), Meteor every
-- ~31s and right before Combustion (the cast just before it 36% of the
-- time, one Meteor in the 12s before it for most). Inside Combustion's
-- ~14s the top players fit 13 Pyroblasts (raid) or 12 Pyroblasts and
-- Flamestrikes (M+) and 9-10 Fire Blasts, and almost never a Fireball.
-- Flamestrike is an M+ spell (pack size), barely used on bosses.
OffBeat:RegisterProfile({
    meta = {
        name = "Fire Mage",
        specId = 63,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Pressed by the top players. Flamestrike is logged as 2120 (hardcast)
    -- and 1254851 (Hot Streak); both count.
    rotationSpells = {
        { spellId = 11366 },   -- Pyroblast
        { spellId = 108853 },  -- Fire Blast
        { spellId = 133 },     -- Fireball
        { spellId = 2948 },    -- Scorch
        { spellId = 2120 },    -- Flamestrike
        { spellId = 1254851 }, -- Flamestrike (Hot Streak)
        { spellId = 190319 },  -- Combustion
        { spellId = 153561 },  -- Meteor
    },

    -- Fireball inside Combustion: 0.2% of the top players' Fireballs land
    -- 1.5-14s into it (2-3% of their Combustions have one). A Fireball you
    -- started before pressing Combustion ("Fireball into Combustion")
    -- finishes inside the first 1.5s and isn't counted.
    mistakes = {
        { type = "bad_cast", name = "Fireball in Combustion", spells = { 133 },
          when = { recent = 190319, within = 14, after = 1.5 } },
    },

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through.
    trackedAuras = {
        { spellId = 190319,  name = "Combustion", baseDuration = 14, stacks = false },
        { spellId = 48108,   name = "Hot Streak!", baseDuration = 15, stacks = false },
        { spellId = 48107,   name = "Heating Up", baseDuration = 10, stacks = false },
        { spellId = 269651,  name = "Pyroclasm", baseDuration = 15, stacks = true },
        { spellId = 1257350, name = "Fired Up", baseDuration = 0, stacks = true },
        { spellId = 1242220, name = "Hyperthermia", baseDuration = 0, stacks = false },
    },

    keyCooldown = {
        spellId = 190319,
        name = "Combustion",
        duration = 14,
    },

    -- Fireball and hardcast Pyroblast / Flamestrike have cast times. Scorch
    -- casts while moving.
    failNudges = {
        { error = "moving", spells = { 133, 11366, 2120 }, name = "Cast while moving",
          text = "Moving: Scorch, Fire Blast into Hot Streak, then the instant Pyroblast" },
    },
    movingCasts = { { spellId = 11366, name = "Pyroblast" } },

    -- Countdown to Combustion. Method: bank Fire Blast charges from ~12s out
    -- (3 ideally, 2 is fine, never cap), hold Hot Streak when it's 3-4s
    -- away, Meteor first. Top players: one Meteor and ~2 Fire Blasts in the
    -- 12s before it.
    prep = {
        spellId = 190319, name = "Combustion", cooldown = 60, lead = 5,
        hint = "Bank Fire Blast charges, hold Hot Streak, Meteor first, then Combustion",
        checks = {
            { name = "Meteor",     ready = 153561, cooldown = 30 },
            { name = "Fire Blast", ready = 108853, cooldown = 12 },
        },
    },

    -- On cooldown for every top player: Combustion every ~61s, Meteor every
    -- ~31s.
    idleCooldowns = {
        { spellId = 190319, name = "Combustion", cooldown = 60 },
        { spellId = 153561, name = "Meteor", cooldown = 30 },
    },

    -- Coaching: Combustion (~14s). Raid: 13 Pyroblasts (12 on Nymrissa) and
    -- 10 Fire Blasts. M+: 12 Pyroblasts and Flamestrikes together (packs
    -- decide which) and 9 Fire Blasts.
    windows = {
        {
            name = "Combustion (raid)",
            trigger = 190319,
            duration = 14,
            content = "raid",
            note = "Meteor first, then Pyroblast and Fire Blast back to back to chain crits; Scorch "
                .. "when Fire Blast is out. Empty Fire Blast before it ends. Top players: 13 Pyroblasts.",
            goals = {
                { name = "Pyroblast / Flamestrike", spells = { 11366, 2120, 1254851 }, min = 13 },
                { name = "Fire Blast", spells = { 108853 }, min = 10 },
            },
        },
        {
            name = "Combustion (M+)",
            trigger = 190319,
            duration = 14,
            content = "dungeon",
            note = "Into a fresh pack: Flamestrike at the cursor on 5+ targets, Pyroblast otherwise, "
                .. "Fire Blast between them (it spreads Ignite). Top players: 12 of them, 9 Fire Blasts.",
            goals = {
                { name = "Pyroblast / Flamestrike", spells = { 11366, 2120, 1254851 }, min = 12 },
                { name = "Fire Blast", spells = { 108853 }, min = 9 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median Pyroblasts (and Flamestrikes) per
    -- Combustion. Dungeons (by instance ID): the top 40 timed runs, per
    -- minute in combat (Warcraft Logs' pulls).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts", all = true },
            { name = "Pyroblast",      spells = { 11366 } },
            { name = "Fire Blast",     spells = { 108853 } },
            { name = "Fireball",       spells = { 133 } },
            { name = "Scorch",         spells = { 2948 } },
            { name = "Flamestrike",    spells = { 2120, 1254851 } },
            { name = "Combustion / Meteor", spells = { 190319, 153561 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 13, values = {
                { 57.5, 59.7, 61.6 }, { 23.2, 24.8, 26.2 }, { 17.3, 18.1, 19.2 }, { 4.0, 4.6, 5.7 }, { 4.8, 6.0, 7.4 }, { 2.1, 2.7, 3.6 }, { 2.4, 2.6, 2.7 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 13, values = {
                { 71.8, 73.7, 75.5 }, { 32.9, 34.0, 35.3 }, { 21.3, 22.3, 23.3 }, { 7.2, 8.4, 9.4 }, { 4.1, 4.7, 6.4 }, { 0.0, 0.5, 1.5 }, { 2.9, 3.0, 3.1 } } },
            [3445] = { name = "Entombed Sentinels", window = 13, values = {
                { 70.1, 72.1, 76.8 }, { 32.8, 34.2, 35.2 }, { 20.8, 21.9, 23.5 }, { 7.6, 8.3, 9.6 }, { 4.4, 5.2, 6.2 }, nil, { 2.6, 2.8, 3.0 } } },
            [3455] = { name = "Vashnik the Malignant", window = 13, values = {
                { 72.1, 73.6, 75.7 }, { 26.6, 29.2, 31.0 }, { 20.6, 21.7, 22.9 }, { 8.9, 10.6, 12.0 }, { 3.7, 5.5, 6.5 }, { 3.1, 5.3, 6.2 }, { 2.4, 2.6, 2.8 } } },
            [3497] = { name = "The Lost Explorers", window = 13, values = {
                { 70.7, 73.2, 75.5 }, { 33.3, 34.3, 36.0 }, { 21.3, 22.6, 24.0 }, { 5.3, 6.7, 7.8 }, { 4.0, 5.1, 6.3 }, nil, { 2.8, 3.0, 3.1 } } },
            [3420] = { name = "Sszorak", window = 13, values = {
                { 68.6, 72.1, 73.9 }, { 32.5, 34.0, 35.2 }, { 20.4, 21.5, 22.8 }, { 6.1, 7.4, 8.8 }, { 4.5, 6.4, 7.2 }, nil, { 2.8, 2.9, 3.0 } } },
            [3421] = { name = "The Twin Fangs", window = 13, values = {
                { 67.9, 70.1, 71.7 }, { 29.7, 31.3, 32.2 }, { 19.8, 21.1, 22.3 }, { 6.2, 7.7, 8.6 }, { 5.0, 6.4, 7.2 }, { 0.0, 1.2, 2.7 }, { 2.8, 2.9, 3.0 } } },
            [3429] = { name = "The Coiled Altar", window = 13, values = {
                { 68.5, 70.2, 71.8 }, { 32.4, 33.2, 34.2 }, { 19.8, 20.6, 22.0 }, { 4.4, 4.9, 7.3 }, { 5.6, 7.9, 9.4 }, nil, { 2.7, 2.8, 2.9 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 12, values = {
                { 66.0, 69.1, 71.5 }, { 21.1, 23.4, 26.7 }, { 19.5, 21.0, 22.0 }, { 6.4, 8.1, 9.0 }, { 4.1, 5.3, 6.5 }, { 5.7, 8.8, 10.5 }, { 2.8, 2.9, 3.0 } } },
        },
        overall = { name = "all heroic bosses", window = 13, values = {
            { 67.5, 71.1, 74.1 }, { 27.6, 32.3, 34.4 }, { 19.9, 21.3, 22.7 }, { 5.7, 7.6, 9.2 }, { 4.3, 5.6, 7.1 }, { 0.0, 0.3, 3.1 }, { 2.6, 2.8, 3.0 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", window = 12, values = {
                { 57.5, 60.1, 62.2 }, { 11.7, 13.0, 14.2 }, { 16.7, 17.4, 18.2 }, { 4.6, 6.1, 8.6 }, { 3.4, 5.8, 7.9 }, { 14.5, 15.3, 16.4 }, { 2.5, 2.5, 2.6 } } },
            [2825] = { name = "Den of Nalorakk", window = 12, values = {
                { 58.2, 60.0, 62.2 }, { 15.3, 16.7, 17.5 }, { 16.9, 17.4, 18.3 }, { 4.3, 5.1, 6.4 }, { 5.6, 7.0, 7.8 }, { 11.0, 11.8, 12.9 }, { 2.4, 2.5, 2.6 } } },
            [1762] = { name = "Kings' Rest", window = 12, values = {
                { 57.6, 61.3, 64.5 }, { 19.1, 20.7, 22.2 }, { 16.9, 17.8, 19.2 }, { 4.7, 5.6, 6.9 }, { 5.3, 6.3, 7.7 }, { 6.6, 7.6, 8.8 }, { 2.4, 2.5, 2.6 } } },
            [2813] = { name = "Murder Row", window = 11, values = {
                { 58.6, 60.9, 62.7 }, { 14.1, 15.5, 17.8 }, { 16.7, 17.5, 18.3 }, { 5.0, 6.0, 7.7 }, { 4.9, 6.4, 7.6 }, { 10.9, 12.3, 13.4 }, { 2.4, 2.5, 2.6 } } },
            [2521] = { name = "Ruby Life Pools", window = 12, values = {
                { 59.9, 62.3, 63.8 }, { 13.4, 16.3, 17.9 }, { 17.2, 17.6, 18.5 }, { 4.3, 5.2, 6.7 }, { 5.8, 7.5, 8.6 }, { 10.2, 12.2, 14.4 }, { 2.5, 2.5, 2.6 } } },
            [1877] = { name = "Temple of Sethraliss", window = 12, values = {
                { 54.7, 58.3, 61.0 }, { 11.3, 13.9, 15.7 }, { 16.1, 16.9, 17.9 }, { 4.0, 4.8, 6.1 }, { 5.5, 6.7, 8.5 }, { 11.6, 12.8, 14.1 }, { 2.3, 2.5, 2.5 } } },
            [2859] = { name = "The Blinding Vale", window = 12, values = {
                { 59.3, 61.8, 63.9 }, { 10.9, 12.8, 14.4 }, { 16.6, 17.8, 18.4 }, { 4.9, 5.8, 7.6 }, { 5.4, 6.8, 8.6 }, { 14.3, 15.9, 17.1 }, { 2.4, 2.5, 2.6 } } },
            [2923] = { name = "Voidscar Arena", window = 12, values = {
                { 58.8, 60.3, 63.4 }, { 14.2, 15.9, 18.8 }, { 17.0, 18.0, 18.6 }, { 4.1, 4.9, 6.3 }, { 6.5, 7.4, 8.5 }, { 10.5, 11.5, 12.6 }, { 2.4, 2.5, 2.6 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", window = 12, values = {
            { 57.8, 60.8, 63.4 }, { 13.1, 15.3, 17.7 }, { 16.7, 17.6, 18.4 }, { 4.4, 5.3, 7.0 }, { 5.2, 6.9, 8.2 }, { 10.6, 12.6, 14.6 }, { 2.4, 2.5, 2.6 } } },
    },

    -- /ob bars: role for role on the keys your other specs use (binds are
    -- account-wide): the spender on 1, Fire Blast on 2, filler on 3, Scorch
    -- on 4, Combustion (every ~61s) on Q, Meteor (every ~31s) on G, the
    -- ground AoE at the cursor on E. Interrupt Shift-E, knockback Shift-Q,
    -- defensives on ` / Shift-`, Shimmer on F. Time Warp sits on F5, out of
    -- the way so you don't press it by accident. One layout for raid and
    -- M+. Polymorph, Arcane Intellect and anything not listed are left
    -- alone.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 11366,  note = "Pyroblast: on Hot Streak, your most pressed spell (~32 a minute in raid)" },
        { slot = 2,  key = "2",       spellId = 108853, note = "Fire Blast: off the GCD, turns Heating Up into Hot Streak; bank charges for Combustion" },
        { slot = 3,  key = "3",       spellId = 133,    note = "Fireball: filler, never inside Combustion" },
        { slot = 4,  key = "4",       spellId = 2948,   note = "Scorch: on the move, and in Combustion when Fire Blast is out" },
        { slot = 6,  key = "Q",       spellId = 190319, note = "Combustion: on cooldown (~61s), after Meteor" },
        { slot = 7,  key = "G",       macro = { name = "OB Meteor", spells = { 153561 }, cursor = true },
          note = "Meteor at your cursor: on cooldown (~31s), right before Combustion" },
        { slot = 8,  key = "E",       macro = { name = "OB Flamestrike", spells = { 2120 }, cursor = true },
          note = "Flamestrike at your cursor: Hot Streak on 5+ targets (~13 a minute in M+)" },
        { slot = 67, key = "R",       spellId = 55342,  note = "Mirror Image: on cooldown in M+ (87% of top runs)" },
        { slot = 71, key = "Shift-F", spellId = 110959, note = "Greater Invisibility: drops threat, less damage taken (87% of top M+ runs)" },
        { slot = 62, key = "Shift-2", spellId = 342245, note = "Alter Time: press again to go back (87% of top M+ runs)" },
        { slot = 63, key = "Shift-3", spellId = 31661,  note = "Dragon's Breath: disorient a pack (M+)" },
        { slot = 64, key = "Shift-4", spellId = 122,    note = "Frost Nova: root a pack (M+)" },
        { slot = 65, key = "Shift-5", spellId = 30449,  note = "Spellsteal: an enemy buff (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 157980, note = "Supernova: knock a pack up (65% of top M+ runs)" },
        { slot = 50, key = "Shift-E", spellId = 2139,   note = "Counterspell: interrupt" },
        { slot = 12, key = "X",       macro = { name = "OB RemoveCurse", spells = { 475 }, mouseover = true },
          note = "Remove Curse (mouseover): curses" },
        { slot = 70, key = "F",       spellId = 212653, alt = { 1953 }, note = "Shimmer / Blink: movement, you keep casting" },
        { slot = 25, key = "F5",      spellId = 80353,  note = "Time Warp: out of the way on purpose" },
        { slot = 55, key = "`",       spellId = 414658, alt = { 45438 }, note = "Ice Cold (Ice Block): long defensive, you keep casting" },
        { slot = 56, key = "Shift-`", spellId = 235313, note = "Blazing Barrier: on cooldown in M+ (~1.5 a minute)" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Sunfury), checked
    -- against the top parses and runs.
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 11366,  text = "Precast Pyroblast; Fire Blast procs into Hot Streak (Firestarter, Fired Up)" },
            { spellId = 133,    text = "Potion, trinket, Time Warp, then Fireball into Combustion" },
            { spellId = 153561, text = "Meteor, then Pyroblast / Fire Blast back to back" },
        } },
        { title = "Combustion (~14s, every minute)", lines = {
            { spellId = 108853, text = "From ~12s out: bank Fire Blast (2-3 charges), never cap" },
            { spellId = 153561, text = "Meteor first, then Combustion; hold Hot Streak if it's 3-4s away" },
            { spellId = 11366,  text = "Pyroblast, Fire Blast, Pyroblast... (top players: 13 and 10)" },
            { spellId = 2948,   text = "Scorch when Fire Blast is out; no Fireball inside" },
            { text = "Empty Fire Blast before it ends (spreads Ignite); Pyroclasm with ~4s left" },
        } },
        { title = "Between Combustions", lines = {
            { spellId = 133,    text = "Fireball to build Heating Up" },
            { spellId = 108853, text = "Fire Blast on Heating Up (off the GCD, mid-Fireball is fine)" },
            { spellId = 11366,  text = "Pyroblast on Hot Streak, right after a Fireball" },
            { spellId = 153561, text = "Meteor on cooldown (~31s)" },
        } },
        { title = "AoE (5+) and M+", lines = {
            { spellId = 2120,   text = "Flamestrike at the cursor on Hot Streak instead of Pyroblast" },
            { spellId = 190319, text = "Combustion into a fresh pack unless you plan a big pull" },
            { spellId = 55342,  text = "Mirror Image on cooldown" },
        } },
    },

    -- Stats: Method (Sunfury): Haste > Versatility > Mastery > Crit.
    statPriority = { HASTE = 1, VERS = 2, MASTERY = 3, CRIT = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 11366,  st = 1, aoe = 1, note = "Hot Streak spender" },
        { spellId = 108853, st = 1, aoe = 1, note = "Off the GCD, ~20 a minute" },
        { spellId = 133,    st = 1, aoe = 2, note = "Filler" },
        { spellId = 2948,   st = 2, aoe = 2, note = "Moving, Combustion" },
        { spellId = 2120,            aoe = 1, note = "5+ targets" },
        { spellId = 153561, st = 2, aoe = 2, note = "Every ~31s" },
        { spellId = 190319, st = 3, aoe = 3, note = "Every ~61s" },
        { spellId = 212653, st = 3, aoe = 3, alt = { 1953 }, note = "Movement" },
        { spellId = 2139,   st = 2, aoe = 2, note = "Interrupt" },
    },
})
