local OffBeat = _G.OffBeat

-- Frost Death Knight, checked against the top 40 heroic parses on every
-- Venomous Abyss boss (Warcraft Logs, Oct 2026): all of them play
-- Deathbringer (Reaper's Mark) with Breath of Sindragosa. Method 12.1
-- (27 Sep 2026) for the rest. Talents you don't have are ignored.
OffBeat:RegisterProfile({
    meta = {
        name = "Frost Death Knight",
        specId = 251,
        version = 3,
        author = "OffBeat Defaults",
        source = "Method 12.1 + top 40 heroic parses per boss (Oct 2026)",
    },

    -- Every spell here is pressed by at least 80% of those top players.
    -- Remorseless Winter is left out: none of them cast it.
    rotationSpells = {
        { spellId = 49020 },   -- Obliterate
        { spellId = 441424 },  -- Exterminate (Deathbringer; takes over Obliterate)
        { spellId = 49143 },   -- Frost Strike
        { spellId = 49184 },   -- Howling Blast
        { spellId = 207230 },  -- Frostscythe
        { spellId = 194913 },  -- Glacial Advance
        { spellId = 47568 },   -- Empower Rune Weapon
        { spellId = 51271 },   -- Pillar of Frost
        { spellId = 279302 },  -- Frostwyrm's Fury
        { spellId = 1249658 }, -- Breath of Sindragosa
        { spellId = 439843 },  -- Reaper's Mark (Deathbringer)
        { spellId = 46585 },   -- Raise Dead
    },

    -- Howling Blast is a Rime spender: 95% of the top players' Howling
    -- Blasts (1,071 of 1,125, 12 top Ula'tek kills) had Rime up. Method's
    -- "Frost Strike at 2 Killing Machine is a waste" isn't checked: the same
    -- players do it on 13% of their Frost Strikes, so it would flag good play.
    mistakes = {
        {
            type = "bad_cast",
            name = "Howling Blast without Rime",
            description = "Howling Blast is only worth casting on a Rime proc",
            spells = { 49184 },
            when = { aura = 59052, absent = true },
        },
        -- Breath goes with Pillar, every other one (all top players). The
        -- cooldown macro skips Pillar when it's on cooldown and fires Breath
        -- alone: 10 of 15 Breaths in your +10 Ruby Life Pools. Checked
        -- from your casts (Pillar in the last 12s), so it works while the
        -- game hides auras.
        {
            type = "bad_cast",
            name = "Breath without Pillar",
            description = "Breath of Sindragosa outside Pillar of Frost: press the macro only when Pillar is ready",
            spells = { 1249658 },
            when = { recent = 51271, within = 12, absent = true },
        },
        -- Method 12.1: Empower Rune Weapon "when Breath is off cooldown and
        -- you don't have 60 Runic Power". Breath is pressed by the cooldown
        -- macro, so this is judged at the press, with what you had then.
        {
            type = "bad_cast",
            name = "Breath under 60 Runic Power",
            description = "Breath of Sindragosa with under 60 Runic Power: Empower Rune Weapon (or Frost Strike less) before the macro",
            spells = { 1249658 },
            when = { power = "RunicPower", max = 59 },
        },
    },

    trackedAuras = {
        { spellId = 51124,  name = "Killing Machine",       baseDuration = 10, stacks = true },
        { spellId = 59052,  name = "Rime",                  baseDuration = 15, stacks = false },
        { spellId = 51271,  name = "Pillar of Frost",       baseDuration = 12, stacks = false },
        { spellId = 1249658, name = "Breath of Sindragosa", baseDuration = 0,  stacks = false },
        { spellId = 194879,  name = "Icy Talons",           baseDuration = 6,  stacks = true },
        { spellId = 377098,  name = "Bonegrinder",          baseDuration = 10, stacks = true },
        -- AoE: Frost Strike while Frostbane is up
        { spellId = 455993,  name = "Frostbane",            baseDuration = 0,  stacks = false },
    },

    keyCooldown = {
        spellId = 51271,
        name = "Pillar of Frost",
        duration = 12,
    },

    idleCooldowns = {
        { spellId = 51271,  name = "Pillar of Frost" },
        { spellId = 47568,  name = "Empower Rune Weapon" },
        { spellId = 279302, name = "Frostwyrm's Fury" },
    },

    procTracking = {
        {
            procAura = 59052,
            consumeSpells = { 49184 },
            window = 0.5,
            name = "Rime",
        },
    },

    -- Coaching: inside Pillar of Frost the top players' Obliterates jump from
    -- 20 a minute to 30, and Exterminate from 4 to 15. The median 12s Pillar
    -- holds 9 Obliterate + Exterminate (8 on Ula'tek and Vashnik). Around
    -- each Pillar they also press Reaper's Mark (just before or just after),
    -- Empower Rune Weapon twice, and every other Pillar Breath of Sindragosa
    -- and Frostwyrm's Fury.
    windows = {
        {
            name = "Pillar of Frost",
            trigger = 51271,
            duration = 12,
            note = "Pool 3-4 runes first. Reaper's Mark with Pillar, then Obliterate (Frostscythe "
                .. "at 3+ targets) on every Killing Machine and rune. Top players' median: 9 per Pillar.",
            -- Method 12.1: "pool 3-4 Runes before Pillar of Frost, so you
            -- are not rune starved". Judged when the macro is pressed.
            setup = {
                { name = "3+ runes ready", when = { power = "Runes", min = 3 } },
            },
            -- Frostscythe is Obliterate's AoE version (Exterminate empowers
            -- both), so it counts the same; before, AoE Pillars read 0.
            goals = {
                { name = "Obliterate / Frostscythe", spells = { 49020, 441424, 207230 }, min = 9 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses; values follow the order of rates.
    -- window = top players' median Obliterate + Exterminate per Pillar.
    benchmarks = {
        source = "top 40 heroic parses per boss (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",      all = true },
            { name = "Obliterate",          spells = { 49020 } },
            { name = "Exterminate",         spells = { 441424 } },
            { name = "Frost Strike",        spells = { 49143 } },
            { name = "Howling Blast",       spells = { 49184 } },
            { name = "Empower Rune Weapon", spells = { 47568 } },
            { name = "Pillar of Frost",     spells = { 51271 } },
            { name = "Reaper's Mark",       spells = { 439843 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 8, values = {
                { 52.8, 54.4, 56.7 }, { 14.1, 15.0, 15.9 }, { 3.7, 3.8, 4.0 }, { 10.5, 11.4, 12.2 }, { 8.8, 9.5, 10.4 }, { 4.1, 4.3, 4.5 }, { 1.2, 1.3, 1.3 }, { 1.2, 1.3, 1.3 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 9, values = {
                { 61.9, 64.1, 66.1 }, { 20.7, 21.7, 23.2 }, { 4.0, 4.1, 4.2 }, { 15.1, 16.0, 16.8 }, { 9.9, 10.6, 11.2 }, { 4.9, 5.0, 5.2 }, { 1.4, 1.4, 1.5 }, { 1.4, 1.4, 1.4 } } },
            [3445] = { name = "Entombed Sentinels", window = 9, values = {
                { 59.1, 61.5, 63.2 }, { 20.3, 21.6, 23.0 }, { 3.8, 3.9, 4.0 }, { 15.3, 15.7, 16.8 }, { 9.6, 10.3, 11.0 }, { 4.5, 4.7, 4.9 }, { 1.3, 1.3, 1.3 }, { 1.3, 1.3, 1.3 } } },
            [3455] = { name = "Vashnik the Malignant", window = 8, values = {
                { 61.1, 63.2, 65.5 }, { 16.8, 18.4, 19.7 }, { 4.0, 4.1, 4.3 }, { 13.5, 14.7, 15.3 }, { 10.3, 10.9, 11.6 }, { 4.8, 5.0, 5.2 }, { 1.3, 1.4, 1.4 }, { 1.3, 1.4, 1.4 } } },
            [3497] = { name = "The Lost Explorers", window = 9, values = {
                { 63.5, 65.6, 67.5 }, { 21.6, 22.8, 24.3 }, { 4.1, 4.3, 4.4 }, { 15.9, 16.6, 18.0 }, { 10.2, 11.0, 11.5 }, { 4.9, 5.0, 5.3 }, { 1.4, 1.4, 1.5 }, { 1.4, 1.4, 1.5 } } },
            [3420] = { name = "Sszorak", window = 9, values = {
                { 64.5, 66.4, 67.7 }, { 22.8, 23.7, 24.4 }, { 3.9, 4.0, 4.2 }, { 17.0, 17.7, 18.3 }, { 10.1, 11.0, 11.7 }, { 4.8, 5.0, 5.2 }, { 1.3, 1.4, 1.4 }, { 1.3, 1.4, 1.4 } } },
            [3421] = { name = "The Twin Fangs", window = 9, values = {
                { 63.4, 64.8, 66.4 }, { 21.8, 22.6, 23.3 }, { 4.1, 4.1, 4.2 }, { 16.6, 16.9, 17.9 }, { 10.5, 11.2, 11.8 }, { 4.8, 5.0, 5.1 }, { 1.4, 1.4, 1.4 }, { 1.4, 1.4, 1.4 } } },
            [3429] = { name = "The Coiled Altar", window = 9, values = {
                { 61.3, 62.4, 64.3 }, { 20.7, 21.5, 22.7 }, { 3.8, 3.9, 4.1 }, { 15.4, 16.5, 17.0 }, { 10.0, 10.6, 11.2 }, { 4.6, 4.8, 5.1 }, { 1.3, 1.3, 1.4 }, { 1.3, 1.3, 1.4 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 9, values = {
                { 63.2, 65.9, 67.2 }, { 19.9, 21.6, 22.9 }, { 4.0, 4.1, 4.3 }, { 14.7, 16.3, 17.7 }, { 10.4, 10.9, 11.8 }, { 4.9, 5.1, 5.4 }, { 1.4, 1.4, 1.5 }, { 1.4, 1.4, 1.5 } } },
        },
        overall = { name = "all heroic bosses", window = 9, values = {
            { 61.1, 63.7, 66.3 }, { 19.6, 21.7, 23.2 }, { 3.9, 4.1, 4.2 }, { 14.7, 16.2, 17.2 }, { 10.0, 10.8, 11.5 }, { 4.6, 4.9, 5.1 }, { 1.3, 1.4, 1.4 }, { 1.3, 1.4, 1.4 } } },
    },

    -- /ob bars: role for role on the warlock's keys (binds are account-wide):
    -- spender on 1, AoE spender on 2, filler on 3, big cooldown on Q,
    -- debuff on Shift-1, short cooldown on Shift-2, big summon/channel on
    -- Shift-3, interrupt Shift-E, movement F, combat rez F5, long / short
    -- defensive on ` / Shift-`, Anti-Magic Zone on X. E (potion), F1/F2,
    -- Shift-4, Shift-5, G and R are left alone, as are T (your Death Grip) and
    -- F11 (your Death and Decay macro, on a mouse button). Exterminate takes over the
    -- Obliterate button, so it gets no slot. Shift-1 holds your cooldown
    -- macro and is never touched: Pillar of Frost + Reaper's Mark + Raise
    -- Dead + Berserking + Breath of Sindragosa (shown as Pillar, so Breath
    -- only goes out with a Pillar). Shift-3 is Reaper's Mark on its own, for
    -- when the macro's Reaper's Mark hits the global cooldown.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 49143,   note = "Frost Strike: Runic Power spender (Hand of Gul'dan's spot)" },
        { slot = 2,  key = "2",       spellId = 194913,  note = "Glacial Advance: AoE Runic Power spender (single target: 1 3 5, AoE: 2 4 5)" },
        { slot = 3,  key = "3",       spellId = 49020,   note = "Obliterate: most pressed, Exterminate shows up here (Shadow Bolt's spot)" },
        { slot = 4,  key = "4",       spellId = 207230,  note = "Frostscythe: Obliterate's 3+ target version, next to it" },
        { slot = 5,  key = "5",       spellId = 49184,   note = "Howling Blast: only on Rime" },
        { slot = 6,  key = "Q",       spellId = 279302,  note = "Frostwyrm's Fury: right after Pillar starts, when it's off cooldown" },
        { slot = 63, key = "Shift-3", spellId = 439843,  note = "Reaper's Mark: again if the macro's one didn't land" },
        { slot = 62, key = "Shift-2", spellId = 47568,   note = "Empower Rune Weapon: ~5 a minute, twice per Pillar" },
        { slot = 50, key = "Shift-E", spellId = 47528,   note = "Mind Freeze: interrupt" },
        { slot = 70, key = "F",       spellId = 48265,   note = "Death's Advance: movement (every top player uses it)" },
        { slot = 25, key = "F5",      spellId = 61999,   note = "Raise Ally: combat rez (soulstone's spot)" },
        { slot = 55, key = "`",       spellId = 48792,   note = "Icebound Fortitude: long defensive" },
        { slot = 56, key = "Shift-`", spellId = 48707,   note = "Anti-Magic Shell: short defensive (every top player uses it)" },
        { slot = 12, key = "X",       spellId = 51052,   note = "Anti-Magic Zone (swap in your macro)" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1, checked against the
    -- top 40 heroic parses per boss.
    rotationSheet = {
        { title = "Cooldowns", lines = {
            { spellId = 51271,  text = "Cooldown macro when Pillar is ready, with 3-4 runes pooled" },
            { spellId = 1249658, text = "Breath turn: 60+ Runic Power first (Empower Rune Weapon if short)" },
            { spellId = 439843, text = "Reaper's Mark: press again if no mark landed with Pillar" },
            { spellId = 279302, text = "Frostwyrm's Fury: right after Pillar starts" },
            { spellId = 47568,  text = "Empower Rune Weapon: twice per Pillar (~5 a minute)" },
            { text = "In Pillar: Obliterate (Frostscythe at 3+) on every Killing Machine and rune (top: 9 per Pillar)" },
        } },
        { title = "Single target", lines = {
            { spellId = 49020,  text = "Obliterate: on Killing Machine, and to spend runes" },
            { spellId = 49184,  text = "Howling Blast: only on Rime (it has range, save it for running)" },
            { spellId = 49143,  text = "Frost Strike at 75+ Runic Power, at 0-1 runes, and in Pillar when nothing else is up" },
        } },
        { title = "AoE (3+)", lines = {
            { spellId = 207230, text = "Frostscythe instead of Obliterate" },
            { spellId = 194913, text = "Glacial Advance at 75+ Runic Power or in Pillar" },
            { spellId = 49143,  text = "Frost Strike while Frostbane is up" },
        } },
    },

    -- Method 12.1 (same for both hero trees): Crit > Mastery >= Haste > Vers
    statPriority = { CRIT = 1, MASTERY = 2, HASTE = 2.5, VERS = 3.5 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Rows you don't have talented are hidden.
    keyLayout = {
        { spellId = 49020,   st = 1,          note = "Killing Machine spender, rune dump; Exterminate shows up here" },
        { spellId = 207230,           aoe = 1, note = "Replaces Obliterate at 3+ targets" },
        { spellId = 49143,   st = 1, aoe = 1, note = "RP spender. AoE: on Frostbane" },
        { spellId = 49184,   st = 1, aoe = 1, note = "Only on Rime" },
        { spellId = 194913,           aoe = 1, note = "At 75+ RP or in Pillar, 3+ targets" },
        { spellId = 47568,   st = 2, aoe = 2, note = "~5 a minute, twice per Pillar" },
        { spellId = 51271,   st = 3, aoe = 3, note = "Main cooldown" },
        { spellId = 439843,  st = 3, aoe = 3, note = "Deathbringer: with every Pillar" },
        { spellId = 1249658, st = 3, aoe = 3, note = "Every other Pillar" },
        { spellId = 279302,  st = 3, aoe = 3, note = "With Breath, every other Pillar" },
        { spellId = 46585,   st = 3, aoe = 3, note = "With Pillar" },
    },
})
