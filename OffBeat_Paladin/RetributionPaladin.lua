local OffBeat = _G.OffBeat

-- Retribution Paladin, Method 12.1.5 (13 Oct 2026), checked against the
-- top 40 heroic parses on every Venomous Abyss boss and the top 40 timed
-- runs per Season 2 dungeon (+21 to +24, 320 runs; Warcraft Logs, Oct
-- 2026). Both are Herald of the Sun (351 of 360 parses, 308 of 320 runs),
-- the build Method's talent builds recommend, with Execution Sentence and
-- Divine Toll; Templar talents you don't have are ignored.
--
-- The rotation is the same in raid and M+: wings, Execution Sentence and
-- Divine Toll go out together every ~62s, Wake of Ashes every ~31s, and
-- Holy Power goes on Final Verdict (single target) or Divine Storm (2+
-- targets, most of M+). Crusading Strikes is the auto attack (40+ "casts"
-- a minute in the logs) and isn't pressed.
OffBeat:RegisterProfile({
    meta = {
        name = "Retribution Paladin",
        specId = 70,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    -- Every spell here is pressed by all of the top players, raid and M+.
    rotationSpells = {
        { spellId = 383328 }, -- Final Verdict
        { spellId = 53385 },  -- Divine Storm
        { spellId = 184575 }, -- Blade of Justice
        { spellId = 24275 },  -- Hammer of Wrath (Judgment during wings)
        { spellId = 20271 },  -- Judgment
        { spellId = 255937 }, -- Wake of Ashes
        { spellId = 31884 },  -- Avenging Wrath
        { spellId = 343527 }, -- Execution Sentence
        { spellId = 375576 }, -- Divine Toll
        { spellId = 429826 }, -- Hammer of Light (Templar)
    },

    -- Divine Toll goes with wings: 98.8% of the top players' Tolls (1,959
    -- in raid) came within 20s of Avenging Wrath. Read from your casts, so
    -- it works while the game hides auras. (Execution Sentence with wings is
    -- 94%, a little loose for a rule; the countdown checks it instead.)
    mistakes = {
        {
            type = "bad_cast",
            name = "Divine Toll without wings",
            description = "Divine Toll goes inside Avenging Wrath: hold it for the next one",
            spells = { 375576 },
            when = { recent = 31884, within = 20, absent = true },
        },
        -- Overcapping: a generator pressed at 5 Holy Power wastes all of it.
        -- Not a top-player rule (the logs only give totals: ~30% of a top
        -- player's Holy Power is wasted, mostly Crusading Strikes swings),
        -- but your first Ret kills wasted half, mostly Blade of Justice at 5
        -- inside wings. Judged when you press it, before the cast adds any.
        {
            type = "bad_cast",
            name = "Generator at 5 Holy Power",
            description = "At 5 Holy Power spend first: Final Verdict or Divine Storm",
            spells = { 184575, 20271, 24275 },
            when = { power = "HolyPower", min = 5 },
        },
    },

    -- Your own buffs (aura IDs from the top logs). 12.1 hides them in
    -- combat, so these show out of combat and whenever the game lets them
    -- through.
    trackedAuras = {
        { spellId = 31884,   name = "Avenging Wrath", baseDuration = 20, stacks = false },
        { spellId = 406086,  name = "Art of War",     baseDuration = 0,  stacks = true },
        { spellId = 408458,  name = "Divine Purpose", baseDuration = 12, stacks = false },
        { spellId = 1306161, name = "Divine Arbiter", baseDuration = 0,  stacks = true },
    },

    keyCooldown = {
        spellId = 31884,
        name = "Avenging Wrath",
        duration = 20,
    },

    failNudges = {
        { error = "range", spells = { 383328, 53385 }, name = "Melee out of range",
          text = "Out of range: Judgment and Blade of Justice reach further" },
    },

    -- Countdown to wings: Execution Sentence and Divine Toll should be ready
    -- with it (top players: all three every ~62s, 92% of Sentences within
    -- 6s of wings). Method opener: Blade of Justice, wings, Execution
    -- Sentence, Wake of Ashes, Divine Toll.
    prep = {
        spellId = 31884, name = "Avenging Wrath", cooldown = 60, lead = 5,
        hint = "Hold Execution Sentence and Divine Toll; stop spending, go in with 4-5 Holy Power",
        checks = {
            -- Your kills: 5 Holy Power going in gave 8-12 spenders per wings
            -- (Vashnik), 2-3 gave 5-12 (Explorers).
            { name = "Holy Power", power = "HolyPower", min = 4 },
            { name = "Execution Sentence", ready = 343527, cooldown = 60 },
            { name = "Divine Toll",        ready = 375576, cooldown = 60 },
        },
    },

    -- On cooldown for every top player: wings every ~62s, Wake of Ashes
    -- every ~31s. Execution Sentence and Divine Toll wait for wings, and
    -- Blade of Justice and Judgment have charges.
    idleCooldowns = {
        { spellId = 31884,  name = "Avenging Wrath" },
        { spellId = 255937, name = "Wake of Ashes" },
    },

    -- Coaching: in the 20s of wings the top players spend 13 Holy Power
    -- (Final Verdict / Divine Storm, median on every boss, middle half
    -- 12-14) and cast 4 Hammers of Wrath. Method: spend as much as possible
    -- in wings and Execution Sentence.
    windows = {
        {
            name = "Avenging Wrath",
            trigger = 31884,
            duration = 20,
            note = "Wings, Execution Sentence, Divine Toll, then spend every Holy Power: Final Verdict, "
                .. "Divine Storm at 2+ targets. Top players: 13 spenders, 4 Hammers of Wrath.",
            goals = {
                { name = "Final Verdict / Divine Storm", spells = { 383328, 53385 }, min = 13 },
                { name = "Hammer of Wrath", spells = { 24275 }, min = 4 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. window = median spenders per wings.
    -- Dungeons (by instance ID): the top 40 timed runs, per minute in combat
    -- (Warcraft Logs' pulls). Single-target bosses lean on Final Verdict,
    -- cleave bosses (The Lost Explorers, The Twin Fangs) and M+ on Divine Storm.
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",   all = true },
            { name = "Final Verdict",    spells = { 383328 } },
            { name = "Divine Storm",     spells = { 53385 } },
            { name = "Blade of Justice", spells = { 184575 } },
            { name = "Hammer of Wrath",  spells = { 24275 } },
            { name = "Judgment",         spells = { 20271 } },
            { name = "Wake of Ashes",    spells = { 255937 } },
            { name = "Wings / Sentence / Toll", spells = { 31884, 343527, 375576 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 13, values = {
                { 47.8, 49.0, 50.0 }, { 14.3, 16.2, 17.5 }, { 11.3, 12.2, 13.5 }, { 5.5, 5.9, 6.2 }, { 5.0, 5.5, 6.3 }, { 4.5, 4.8, 5.0 }, { 1.7, 1.7, 1.7 }, { 2.7, 2.7, 2.7 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 13, values = {
                { 55.8, 56.9, 57.4 }, { 23.0, 24.0, 25.2 }, { 8.3, 9.0, 10.2 }, { 6.0, 6.4, 7.3 }, { 5.8, 6.5, 6.9 }, { 4.9, 5.2, 5.8 }, { 1.9, 2.0, 2.1 }, { 3.1, 3.2, 3.3 } } },
            [3445] = { name = "Entombed Sentinels", window = 13, values = {
                { 53.2, 55.0, 56.3 }, { 20.3, 21.6, 23.1 }, { 9.0, 10.0, 11.5 }, { 5.8, 6.8, 7.4 }, { 5.6, 6.1, 6.9 }, { 4.8, 5.2, 5.9 }, { 1.9, 2.0, 2.0 }, { 3.0, 3.2, 3.3 } } },
            [3455] = { name = "Vashnik the Malignant", window = 13, values = {
                { 54.4, 55.6, 57.2 }, { 19.3, 20.4, 21.9 }, { 11.3, 11.8, 12.9 }, { 6.0, 6.6, 7.2 }, { 5.8, 6.4, 6.7 }, { 5.2, 5.7, 6.2 }, { 1.7, 1.8, 1.8 }, { 2.6, 2.8, 3.0 } } },
            [3497] = { name = "The Lost Explorers", window = 13, values = {
                { 56.1, 57.4, 58.3 }, { 9.3, 9.7, 11.2 }, { 21.9, 23.1, 24.4 }, { 6.4, 7.0, 7.7 }, { 5.8, 6.5, 7.2 }, { 4.7, 5.1, 5.7 }, { 1.9, 2.0, 2.1 }, { 3.1, 3.2, 3.3 } } },
            [3420] = { name = "Sszorak", window = 13, values = {
                { 56.7, 58.0, 58.6 }, { 25.1, 26.6, 27.3 }, { 6.8, 7.3, 7.7 }, { 6.0, 6.6, 7.2 }, { 6.7, 7.2, 7.5 }, { 4.7, 5.3, 5.7 }, { 2.0, 2.0, 2.0 }, { 3.2, 3.3, 3.4 } } },
            [3421] = { name = "The Twin Fangs", window = 13, values = {
                { 55.8, 56.9, 57.9 }, { 9.8, 10.3, 11.4 }, { 22.1, 23.3, 24.2 }, { 5.6, 6.1, 7.0 }, { 6.1, 6.5, 7.0 }, { 4.5, 5.0, 5.4 }, { 1.9, 2.0, 2.0 }, { 2.9, 3.1, 3.2 } } },
            [3429] = { name = "The Coiled Altar", window = 13, values = {
                { 54.7, 55.2, 56.2 }, { 18.1, 18.7, 19.6 }, { 12.9, 13.4, 14.2 }, { 6.1, 6.8, 7.3 }, { 5.7, 6.1, 6.6 }, { 4.6, 4.9, 5.4 }, { 1.9, 1.9, 2.0 }, { 2.9, 3.0, 3.1 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 13, values = {
                { 55.2, 57.2, 58.6 }, { 21.3, 23.5, 25.0 }, { 8.8, 9.8, 11.3 }, { 6.3, 6.7, 7.4 }, { 6.0, 6.4, 7.2 }, { 5.0, 5.5, 5.9 }, { 1.9, 2.0, 2.1 }, { 3.2, 3.3, 3.4 } } },
        },
        overall = { name = "all heroic bosses", window = 13, values = {
            { 54.4, 56.3, 57.7 }, { 14.4, 19.8, 23.7 }, { 9.1, 11.9, 14.6 }, { 5.9, 6.6, 7.3 }, { 5.8, 6.4, 7.0 }, { 4.7, 5.2, 5.7 }, { 1.8, 2.0, 2.0 }, { 2.9, 3.1, 3.3 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", values = {
                { 47.8, 49.1, 51.1 }, { 12.6, 13.5, 14.1 }, { 13.9, 14.7, 15.3 }, { 6.1, 6.6, 7.0 }, { 4.3, 4.5, 4.6 }, { 5.5, 5.7, 6.1 }, { 1.7, 1.8, 1.9 }, { 2.5, 2.6, 2.7 } } },
            [2825] = { name = "Den of Nalorakk", values = {
                { 45.8, 47.1, 48.7 }, { 12.7, 13.5, 14.2 }, { 12.5, 13.5, 14.0 }, { 5.8, 6.4, 6.6 }, { 4.4, 4.7, 4.9 }, { 5.0, 5.3, 5.8 }, { 1.7, 1.8, 1.9 }, { 2.6, 2.6, 2.7 } } },
            [1762] = { name = "Kings' Rest", values = {
                { 49.3, 50.3, 51.4 }, { 13.7, 14.7, 15.6 }, { 13.2, 14.2, 14.8 }, { 6.0, 6.7, 7.1 }, { 4.6, 4.8, 4.9 }, { 5.4, 5.8, 6.0 }, { 1.8, 1.9, 1.9 }, { 2.6, 2.7, 2.8 } } },
            [2813] = { name = "Murder Row", values = {
                { 48.2, 48.9, 51.1 }, { 13.1, 14.0, 14.6 }, { 13.2, 13.9, 14.6 }, { 6.1, 6.6, 7.0 }, { 4.3, 4.6, 5.0 }, { 5.1, 5.5, 5.9 }, { 1.7, 1.8, 2.0 }, { 2.6, 2.7, 2.8 } } },
            [2521] = { name = "Ruby Life Pools", values = {
                { 49.3, 50.3, 51.5 }, { 10.4, 11.9, 12.6 }, { 16.3, 17.1, 18.1 }, { 6.2, 6.6, 7.2 }, { 4.4, 4.7, 5.0 }, { 5.3, 5.5, 5.7 }, { 1.8, 1.8, 1.9 }, { 2.6, 2.7, 2.8 } } },
            [1877] = { name = "Temple of Sethraliss", values = {
                { 47.4, 48.4, 49.9 }, { 11.9, 12.6, 13.3 }, { 13.5, 15.2, 15.7 }, { 6.0, 6.5, 6.9 }, { 4.1, 4.5, 4.8 }, { 5.4, 5.7, 6.1 }, { 1.7, 1.7, 1.8 }, { 2.5, 2.5, 2.6 } } },
            [2859] = { name = "The Blinding Vale", values = {
                { 49.3, 50.7, 51.6 }, { 12.2, 13.1, 13.5 }, { 15.7, 16.0, 16.8 }, { 6.1, 6.6, 7.0 }, { 4.5, 4.9, 5.1 }, { 5.2, 5.6, 6.0 }, { 1.8, 1.8, 1.9 }, { 2.7, 2.7, 2.8 } } },
            [2923] = { name = "Voidscar Arena", values = {
                { 48.5, 49.5, 51.9 }, { 13.7, 14.8, 15.6 }, { 12.5, 13.3, 14.4 }, { 6.1, 6.5, 7.3 }, { 4.5, 4.8, 5.1 }, { 5.7, 5.8, 6.1 }, { 1.7, 1.9, 1.9 }, { 2.6, 2.7, 2.8 } } },
        },
        -- Dummies with /ob mode mythic: all 320 runs together.
        dungeonOverall = { name = "all M+ dungeons", values = {
            { 48.0, 49.5, 51.1 }, { 12.4, 13.4, 14.4 }, { 13.4, 14.5, 15.8 }, { 6.0, 6.6, 7.0 }, { 4.3, 4.7, 5.0 }, { 5.3, 5.7, 6.0 }, { 1.7, 1.8, 1.9 }, { 2.6, 2.7, 2.8 } } },
    },

    -- /ob bars: role for role on the keys your other specs use (binds are
    -- account-wide): spender on 1, AoE spender on 2, generators on 3-4,
    -- Wake of Ashes (every ~31s) on Q, and wings, Execution Sentence and
    -- Divine Toll (pressed back to back every ~62s) along Shift-1, 2, 3,
    -- interrupt Shift-E, stun Shift-Q, defensives on ` / Shift-`. F is
    -- Blessing of Freedom; Divine Steed stays on your Meta-Q and isn't
    -- touched. One layout for raid and M+: the top players press the same
    -- buttons in both. Hammer of Wrath has no button: it is Judgment during
    -- Avenging Wrath (top logs: no Judgment inside wings). 5, E, G, R and
    -- F5 are left alone.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 383328, note = "Final Verdict: single-target spender, ~16 a minute in raid" },
        { slot = 2,  key = "2",       spellId = 53385,  note = "Divine Storm: 2+ targets, most of M+" },
        { slot = 3,  key = "3",       spellId = 184575, note = "Blade of Justice: Art of War procs" },
        { slot = 4,  key = "4",       spellId = 20271,  note = "Judgment: turns into Hammer of Wrath during wings (4 in every wings)" },
        { slot = 6,  key = "Q",       spellId = 255937, note = "Wake of Ashes: every ~31s, one in each wings right after Execution Sentence" },
        { slot = 61, key = "Shift-1", spellId = 31884,  note = "Avenging Wrath: every ~62s, then Shift-2, Shift-3" },
        { slot = 62, key = "Shift-2", spellId = 343527, note = "Execution Sentence: right after wings" },
        { slot = 63, key = "Shift-3", spellId = 375576, note = "Divine Toll: only inside wings" },
        { slot = 50, key = "Shift-E", spellId = 96231,  note = "Rebuke: interrupt" },
        { slot = 66, key = "Shift-Q", spellId = 853,    note = "Hammer of Justice: stun" },
        { slot = 70, key = "F",       macro = { name = "OB Freedom", spells = { 1044 }, mouseover = true },
          note = "Blessing of Freedom (mouseover); Divine Steed stays on your Meta-Q" },
        { slot = 12, key = "X",       macro = { name = "OB CleanseT", spells = { 213644 }, mouseover = true },
          note = "Cleanse Toxins (mouseover): poisons and diseases" },
        { slot = 64, key = "Shift-4", macro = { name = "OB BoP", spells = { 1022 }, mouseover = true },
          note = "Blessing of Protection (mouseover): not on the tank" },
        { slot = 65, key = "Shift-5", macro = { name = "OB LoH", spells = { 633 }, mouseover = true },
          note = "Lay on Hands (mouseover)" },
        { slot = 55, key = "`",       spellId = 403876, note = "Divine Protection: defensive" },
        { slot = 56, key = "Shift-`", spellId = 642,    note = "Divine Shield" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5 (Herald of the
    -- Sun), checked against the top parses and runs.
    rotationSheet = {
        { title = "Opener", lines = {
            { spellId = 184575, text = "Blade of Justice, then wings (most top players)" },
            { spellId = 343527, text = "Execution Sentence and Wake of Ashes right after" },
            { spellId = 383328, text = "Final Verdict twice, then Divine Toll (Herald)" },
        } },
        { title = "Cooldowns", lines = {
            { spellId = 31884,  text = "Avenging Wrath on cooldown, with Execution Sentence and Divine Toll (all three every ~62s)" },
            { spellId = 375576, text = "Divine Toll only inside wings (99% of top players' Tolls)" },
            { spellId = 255937, text = "Wake of Ashes on cooldown (~31s), half of them land in wings" },
            { text = "In wings: spend everything, ~13 Final Verdict / Divine Storm in 20s" },
        } },
        { title = "Single target", lines = {
            { spellId = 383328, text = "Final Verdict at 5 Holy Power (4 before a Crusading Strikes swing)" },
            { spellId = 184575, text = "Blade of Justice on Art of War" },
            { spellId = 20271,  text = "Judgment (Hammer of Wrath in wings), then Final Verdict at 3+" },
            { text = "Keep Judgment and Expurgation on the target" },
        } },
        { title = "AoE (2+) and M+", lines = {
            { spellId = 53385,  text = "Divine Storm at 3-5 Holy Power instead of Final Verdict (M+: ~15 a minute)" },
            { spellId = 255937, text = "Wake of Ashes and Divine Toll hit the pack" },
        } },
    },

    -- Stats: the ratings the top players actually wear (Warcraft Logs, 197
    -- raid parses and 151 M+ runs): Mastery > Crit > Haste > Vers in both
    -- (median raid 1156 / 1067 / 898 / 101, M+ 1240 / 1055 / 895 / 107;
    -- Mastery first for 77% / 89%, Crit second for 61% / 75%). Method has
    -- Haste over Crit.
    statPriority = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 383328, st = 1,          note = "Single-target spender" },
        { spellId = 53385,           aoe = 1, note = "AoE spender, most of M+" },
        { spellId = 184575, st = 1, aoe = 1, note = "Art of War" },
        { spellId = 20271,  st = 1, aoe = 1, note = "Hammer of Wrath during wings" },
        { spellId = 255937, st = 2, aoe = 2, note = "Every ~31s" },
        { spellId = 31884,  st = 3, aoe = 3, note = "Every ~62s" },
        { spellId = 343527, st = 3, aoe = 3, note = "With wings" },
        { spellId = 375576, st = 3, aoe = 3, note = "Only in wings" },
        { spellId = 96231,  st = 2, aoe = 2, note = "Interrupt" },
    },
})
