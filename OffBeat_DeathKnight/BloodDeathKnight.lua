local OffBeat = _G.OffBeat

-- Blood Death Knight, Method 12.1.5 (13 Oct 2026), checked against the top
-- 40 heroic parses on every Venomous Abyss boss (360) and the top 40 timed
-- runs per Season 2 dungeon (314 runs; Warcraft Logs, Oct 2026). Method
-- recommends San'layn everywhere; the top players agree in M+ (every run)
-- and on most raid bosses (75% of parses), with Deathbringer (Reaper's
-- Mark, Exterminate) for the rest. The sheet covers both.
--
-- Dancing Rune Weapon every ~91s, Reaper's Mark every ~46s (Deathbringer),
-- Death and Decay every ~13s, Vampiric Blood more often in M+ (~1.9 a
-- minute) than raid. Death Strike and Heart Strike / Vampiric Strike are
-- the busiest buttons. Consumption isn't pressed by anyone. Vampiric
-- Strike is cast as 433895 and Exterminate as 441424 in the logs.
OffBeat:RegisterProfile({
    meta = {
        name = "Blood Death Knight",
        specId = 250,
        version = 3,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    rotationSpells = {
        { spellId = 195182 }, -- Marrowrend
        { spellId = 206930 }, -- Heart Strike
        { spellId = 433895 }, -- Vampiric Strike (San'layn)
        { spellId = 49998 },  -- Death Strike
        { spellId = 50842 },  -- Blood Boil
        { spellId = 43265 },  -- Death and Decay
        { spellId = 49028 },  -- Dancing Rune Weapon
        { spellId = 439843 }, -- Reaper's Mark (Deathbringer)
        { spellId = 441424 }, -- Exterminate (Deathbringer)
        { spellId = 55233 },  -- Vampiric Blood
        { spellId = 195292 }, -- Death's Caress
    },

    -- Your own buffs. 12.1 hides them in combat, so these show out of
    -- combat and whenever the game lets them through.
    trackedAuras = {
        { spellId = 195181,  name = "Bone Shield",                baseDuration = 30, stacks = true },
        { spellId = 81256,   name = "Dancing Rune Weapon",        baseDuration = 8,  stacks = false },
        { spellId = 55233,   name = "Vampiric Blood",             baseDuration = 10, stacks = false },
        { spellId = 81141,   name = "Crimson Scourge",            baseDuration = 15, stacks = false },
        { spellId = 1265790, name = "Boiling Point",              baseDuration = 0,  stacks = false },
        { spellId = 444040,  name = "Essence of the Blood Queen", baseDuration = 20, stacks = true },
        { spellId = 439843,  name = "Reaper's Mark",              baseDuration = 12, stacks = true },
    },

    keyCooldown = {
        spellId = 49028,
        name = "Dancing Rune Weapon",
        duration = 8,
    },

    failNudges = {
        { error = "range", spells = { 206930, 49998, 195182 }, name = "Melee out of range",
          text = "Out of range: Death's Caress for Bone Shield, Blood Boil when you're back" },
    },

    idleCooldowns = {
        { spellId = 49028,  name = "Dancing Rune Weapon" },
        { spellId = 439843, name = "Reaper's Mark" }, -- Deathbringer: on cooldown
    },

    -- Method: "Death Strike ... above 75 RP" comes first and "keep 5+ Bone
    -- Shield", so a filler Heart Strike in either state is a missed priority.
    mistakes = {
        {
            type = "bad_cast",
            name = "Runic Power Pooling",
            description = "Heart Strike at 75+ Runic Power, Death Strike first",
            spells = { 206930 },
            when = { power = "RunicPower", min = 75 },
        },
        {
            type = "bad_cast",
            name = "Low Bone Shield",
            description = "Heart Strike with under 5 Bone Shield, Marrowrend first",
            spells = { 206930 },
            when = { aura = 195181, maxStacks = 4 },
        },
    },

    procTracking = {
        { procAura = 81141,   consumeSpells = { 43265 }, window = 0.5, name = "Crimson Scourge" },
        { procAura = 1265790, consumeSpells = { 50842 }, window = 0.5, name = "Boiling Point" },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. Vampiric Strike spreads wide on bosses where a
    -- quarter of the top players are Deathbringer. Dungeons (by instance
    -- ID): the top 40 timed runs, per minute in combat (Warcraft Logs'
    -- pulls).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",  all = true },
            { name = "Death Strike",    spells = { 49998 } },
            { name = "Heart Strike",    spells = { 206930 } },
            { name = "Vampiric Strike", spells = { 433895 } },
            { name = "Blood Boil",      spells = { 50842 } },
            { name = "Death and Decay", spells = { 43265 } },
            { name = "Marrowrend / Exterminate", spells = { 195182, 441424 } },
            { name = "Vampiric Blood",  spells = { 55233 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", values = {
                { 50.5, 52.1, 54.3 }, { 14.2, 15.7, 16.1 }, { 11.9, 13.0, 14.0 }, { 4.6, 7.7, 8.3 }, { 7.2, 8.4, 9.2 }, { 3.0, 3.4, 4.0 }, { 1.5, 1.7, 3.9 }, { 0.5, 0.6, 0.9 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", values = {
                { 56.9, 59.3, 61.6 }, { 14.2, 16.3, 17.5 }, { 14.9, 16.0, 16.8 }, { 0.0, 9.8, 10.7 }, { 8.5, 9.6, 10.5 }, { 3.3, 3.7, 3.9 }, { 1.6, 1.8, 7.9 }, { 0.3, 0.5, 0.6 } } },
            [3445] = { name = "Entombed Sentinels", values = {
                { 58.0, 59.6, 61.0 }, { 16.8, 17.7, 18.2 }, { 14.9, 16.2, 17.5 }, { 9.5, 10.6, 11.5 }, { 6.0, 7.0, 8.7 }, { 3.1, 3.4, 3.7 }, { 1.6, 1.8, 2.5 }, { 0.3, 0.6, 1.2 } } },
            [3455] = { name = "Vashnik the Malignant", values = {
                { 59.0, 60.5, 62.1 }, { 16.3, 17.3, 18.0 }, { 14.6, 16.1, 17.4 }, { 9.1, 10.1, 10.8 }, { 8.5, 9.4, 10.9 }, { 3.4, 3.7, 4.0 }, { 1.4, 1.6, 2.0 }, { 0.0, 0.3, 0.8 } } },
            [3497] = { name = "The Lost Explorers", values = {
                { 59.4, 60.7, 62.9 }, { 17.2, 18.0, 18.4 }, { 13.7, 16.0, 16.7 }, { 9.9, 10.8, 11.8 }, { 6.8, 9.3, 10.2 }, { 3.3, 3.8, 4.0 }, { 1.6, 2.1, 2.7 }, { 0.3, 0.4, 0.9 } } },
            [3420] = { name = "Sszorak", values = {
                { 58.3, 60.1, 62.8 }, { 14.6, 15.8, 16.9 }, { 16.9, 17.8, 19.5 }, nil, { 9.3, 10.7, 11.4 }, { 3.4, 3.7, 4.1 }, { 2.7, 7.2, 7.8 }, { 0.3, 0.6, 1.1 } } },
            [3421] = { name = "The Twin Fangs", values = {
                { 62.2, 63.3, 64.9 }, { 18.5, 19.2, 19.8 }, { 15.3, 16.4, 17.2 }, { 10.0, 10.6, 11.2 }, { 7.7, 8.7, 10.8 }, { 3.3, 3.6, 4.1 }, { 1.6, 1.9, 2.1 }, { 0.2, 0.5, 0.9 } } },
            [3429] = { name = "The Coiled Altar", values = {
                { 56.2, 57.8, 59.8 }, { 14.9, 16.7, 17.1 }, { 13.9, 14.9, 15.7 }, { 8.2, 9.0, 10.2 }, { 8.6, 10.2, 10.9 }, { 3.4, 3.6, 4.0 }, { 1.5, 2.0, 3.1 }, { 0.2, 0.4, 0.7 } } },
            [3379] = { name = "Nymrissa Wavecaller", values = {
                { 56.5, 59.3, 61.9 }, { 14.6, 15.9, 17.4 }, { 15.0, 15.9, 17.1 }, { 0.0, 7.9, 10.9 }, { 8.9, 10.4, 11.2 }, { 3.3, 3.9, 4.1 }, { 1.6, 2.2, 7.9 }, { 0.0, 0.4, 1.0 } } },
        },
        overall = { name = "all heroic bosses", values = {
            { 56.7, 59.8, 62.2 }, { 15.3, 16.9, 18.1 }, { 14.4, 15.8, 17.1 }, { 0.0, 9.7, 10.9 }, { 7.9, 9.3, 10.7 }, { 3.3, 3.6, 4.0 }, { 1.5, 1.9, 5.8 }, { 0.3, 0.5, 0.9 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", values = {
                { 60.5, 61.4, 62.3 }, { 18.5, 19.0, 19.3 }, { 14.7, 15.3, 16.1 }, { 10.0, 10.3, 10.6 }, { 6.5, 7.0, 7.5 }, { 3.8, 4.0, 4.1 }, { 1.6, 1.9, 2.1 }, { 1.9, 1.9, 2.1 } } },
            [2825] = { name = "Den of Nalorakk", values = {
                { 58.7, 60.1, 61.6 }, { 17.4, 18.3, 19.0 }, { 14.0, 14.7, 15.5 }, { 9.7, 10.1, 10.4 }, { 6.7, 7.1, 7.9 }, { 3.6, 3.8, 4.0 }, { 1.6, 1.9, 2.2 }, { 1.6, 1.8, 1.9 } } },
            [1762] = { name = "Kings' Rest", values = {
                { 60.3, 61.7, 62.6 }, { 17.9, 18.2, 18.8 }, { 15.4, 16.1, 17.0 }, { 9.7, 10.2, 10.6 }, { 6.7, 7.3, 7.9 }, { 3.6, 3.8, 3.9 }, { 1.6, 1.9, 2.3 }, { 1.5, 1.8, 1.9 } } },
            [2813] = { name = "Murder Row", values = {
                { 59.7, 61.0, 62.2 }, { 18.4, 18.9, 19.8 }, { 14.6, 15.0, 16.0 }, { 9.7, 10.3, 11.1 }, { 5.8, 6.3, 7.2 }, { 3.8, 3.9, 4.1 }, { 1.8, 2.0, 2.3 }, { 1.8, 1.9, 2.0 } } },
            [2521] = { name = "Ruby Life Pools", values = {
                { 60.9, 62.0, 63.3 }, { 19.4, 20.0, 20.7 }, { 14.0, 15.0, 15.9 }, { 10.1, 10.6, 11.0 }, { 5.9, 6.7, 7.4 }, { 3.9, 4.1, 4.3 }, { 1.9, 2.2, 2.6 }, { 1.8, 2.0, 2.1 } } },
            [1877] = { name = "Temple of Sethraliss", values = {
                { 59.6, 60.7, 62.4 }, { 18.5, 18.9, 19.3 }, { 14.1, 15.5, 16.6 }, { 9.6, 9.9, 10.4 }, { 6.1, 7.2, 8.3 }, { 3.8, 4.0, 4.1 }, { 1.6, 2.0, 2.2 }, { 1.6, 1.8, 1.9 } } },
            [2859] = { name = "The Blinding Vale", values = {
                { 61.5, 62.6, 64.0 }, { 18.7, 19.2, 19.8 }, { 14.9, 15.6, 16.8 }, { 10.0, 10.4, 10.9 }, { 6.7, 7.2, 8.3 }, { 3.8, 4.0, 4.2 }, { 1.8, 2.1, 2.4 }, { 1.8, 1.9, 2.1 } } },
            [2923] = { name = "Voidscar Arena", values = {
                { 60.4, 61.6, 62.9 }, { 18.5, 19.0, 19.6 }, { 14.6, 15.4, 16.1 }, { 9.8, 10.3, 10.7 }, { 6.6, 7.2, 7.7 }, { 3.8, 3.9, 4.1 }, { 1.7, 2.1, 2.4 }, { 1.7, 1.8, 2.0 } } },
        },
        -- Dummies with /ob mode mythic: all 314 runs together.
        dungeonOverall = { name = "all M+ dungeons", values = {
            { 60.2, 61.4, 62.6 }, { 18.3, 18.9, 19.6 }, { 14.4, 15.4, 16.2 }, { 9.8, 10.2, 10.8 }, { 6.3, 7.0, 7.7 }, { 3.7, 3.9, 4.1 }, { 1.7, 2.0, 2.4 }, { 1.7, 1.9, 2.0 } } },
    },

    -- /ob bars: role for role on the keys your other tank and melee specs
    -- use (binds are account-wide): Death Strike on 1, Blood Boil on 2,
    -- Heart Strike on 3 (it becomes Vampiric Strike), Marrowrend on 4,
    -- Death's Caress on 5, Dancing Rune Weapon on Q, Reaper's Mark on G,
    -- Death and Decay on E, Vampiric Blood on Shift-1, Dark Command on X.
    -- Interrupt Shift-E, Gorefiend's Grasp Shift-Q, defensives on ` /
    -- Shift-`, Death's Advance on F, Raise Ally on F5. One layout for raid
    -- and M+.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 49998,  note = "Death Strike: above 75 Runic Power, or to live (~17-19 a minute)" },
        { slot = 2,  key = "2",       spellId = 50842,  note = "Blood Boil: don't cap charges, spend Boiling Point" },
        { slot = 3,  key = "3",       spellId = 206930, note = "Heart Strike / Vampiric Strike: filler" },
        { slot = 4,  key = "4",       spellId = 195182, note = "Marrowrend: keep 5+ Bone Shield, spend Blood Debt" },
        { slot = 5,  key = "5",       spellId = 195292, note = "Death's Caress: Bone Shield from range, the pull" },
        { slot = 6,  key = "Q",       spellId = 49028,  note = "Dancing Rune Weapon: on cooldown (~91s)" },
        { slot = 7,  key = "G",       spellId = 439843, note = "Reaper's Mark (Deathbringer): on cooldown, before DRW" },
        { slot = 8,  key = "E",       spellId = 43265,  note = "Death and Decay: keep it down (~every 13s)" },
        { slot = 61, key = "Shift-1", spellId = 55233,  note = "Vampiric Blood: your planned defensive" },
        { slot = 67, key = "R",       spellId = 46585,  note = "Raise Dead: with DRW" },
        { slot = 12, key = "X",       spellId = 56222,  note = "Dark Command: taunt" },
        { slot = 62, key = "Shift-2", spellId = 51052,  note = "Anti-Magic Zone: group magic damage" },
        { slot = 63, key = "Shift-3", spellId = 49576,  note = "Death Grip: careful, it taunts" },
        { slot = 64, key = "Shift-4", spellId = 207167, note = "Blinding Sleet (M+)" },
        { slot = 65, key = "Shift-5", spellId = 49039,  note = "Lichborne: more healing in a bad moment" },
        { slot = 66, key = "Shift-Q", spellId = 108199, note = "Gorefiend's Grasp: pull a pack together" },
        { slot = 50, key = "Shift-E", spellId = 47528,  note = "Mind Freeze: interrupt" },
        { slot = 70, key = "F",       spellId = 48265,  note = "Death's Advance: movement" },
        { slot = 25, key = "F5",      spellId = 61999,  note = "Raise Ally: combat rez" },
        { slot = 55, key = "`",       spellId = 48792,  note = "Icebound Fortitude: long defensive, don't overlap" },
        { slot = 56, key = "Shift-`", spellId = 48707,  note = "Anti-Magic Shell: before magic damage" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5.
    rotationSheet = {
        { title = "San'layn", unknown = { 439843 }, lines = {
            { spellId = 49998,  text = "Death Strike to live, or above 75 Runic Power" },
            { spellId = 195182, text = "Marrowrend under 5 Bone Shield, and to spend Blood Debt" },
            { spellId = 43265,  text = "Death and Decay: keep it down" },
            { spellId = 50842,  text = "Blood Boil on Boiling Point" },
            { spellId = 433895, text = "Vampiric Strike, then Blood Boil before it caps" },
            { spellId = 206930, text = "Heart Strike as filler" },
        } },
        { title = "San'layn: Dancing Rune Weapon", unknown = { 439843 }, lines = {
            { spellId = 49028, text = "Raise Dead with it; Blood Boil once" },
            { spellId = 43265, text = "Death and Decay on Crimson Scourge" },
            { spellId = 433895, text = "Vampiric Strike, Blood Boil as filler" },
        } },
        { title = "Deathbringer", known = { 439843 }, lines = {
            { spellId = 49998,  text = "Death Strike to live, or above 75 Runic Power" },
            { spellId = 441424, text = "5+ Bone Shield via Exterminate or Marrowrend" },
            { spellId = 43265,  text = "Death and Decay: keep it down" },
            { spellId = 439843, text = "Reaper's Mark on cooldown, then Dancing Rune Weapon" },
            { spellId = 50842,  text = "Blood Boil before it caps or on Boiling Point" },
            { spellId = 206930, text = "Heart Strike when Blood Boil is out" },
        } },
        { title = "Defensives", lines = {
            { spellId = 55233, text = "Vampiric Blood: the one to plan around" },
            { spellId = 48707, text = "Anti-Magic Shell before magic damage (and Runic Power)" },
            { spellId = 48792, text = "Icebound Fortitude: don't overlap it with the others" },
        } },
    },

    -- Method 12.1.5: Deathbringer Crit = Vers = Mastery > Haste; San'layn
    -- Haste > Crit = Vers = Mastery.
    statPriority = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 2 },
    heroStatPriorities = {
        ["Deathbringer"] = { CRIT = 1, MASTERY = 1, VERS = 1, HASTE = 2 },
        ["San'layn"] = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 2 },
    },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Rows you don't have talented are hidden.
    keyLayout = {
        { spellId = 206930, st = 1, aoe = 1, alt = { 433895 }, note = "Filler / Vampiric Strike" },
        { spellId = 49998,  st = 1, aoe = 1, note = "Above 75 RP or when you need the heal" },
        { spellId = 195182, st = 1, aoe = 1, note = "Keep 5+ Bone Shield" },
        { spellId = 50842,  st = 1, aoe = 1, note = "Never cap charges, spend Boiling Point" },
        { spellId = 43265,  st = 2, aoe = 1, note = "Keep it down, spend Crimson Scourge" },
        { spellId = 441424, st = 2, aoe = 2, note = "Deathbringer: Bone Shield instead of Marrowrend" },
        { spellId = 195292, st = 2, aoe = 2, note = "Bone Shield from range" },
        { spellId = 49028,  st = 3, aoe = 3, note = "Every ~91s" },
        { spellId = 439843, st = 3, aoe = 3, note = "Deathbringer: every ~46s" },
        { spellId = 55233,  st = 3, aoe = 3, note = "Defensive" },
        { spellId = 48707,  st = 3, aoe = 3, note = "Defensive, magic" },
        { spellId = 48792,  st = 3, aoe = 3, note = "Defensive" },
        { spellId = 47528,  st = 2, aoe = 2, note = "Interrupt" },
    },
})
