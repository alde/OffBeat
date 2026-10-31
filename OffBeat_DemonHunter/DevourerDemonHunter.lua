local OffBeat = _G.OffBeat

-- Devourer Demon Hunter, Method 12.1.5 (18 Oct 2026), checked against the
-- top 40 heroic parses on every Venomous Abyss boss (360) and the top 40
-- timed runs per Season 2 dungeon (317 runs; Warcraft Logs, Oct 2026).
--
-- Both hero trees are played: Void-Scarred (Voidblade, The Hunt, Reaper's
-- Toll) in 79% of raid parses and 47% of runs, Annihilator (Devour-heavy,
-- ~18 a minute) for the rest; Annihilator owns The Twin Fangs and most of
-- M+. The sheet switches on Voidblade. Void Ray every ~7s and Collapsing
-- Star every ~9-12s are the core casts; The Hunt and Voidblade every
-- ~65s set up Void Metamorphosis (Void-Scarred). Void Metamorphosis
-- itself doesn't show up as a cast in the logs, so it isn't counted.
OffBeat:RegisterProfile({
    meta = {
        name = "Devourer Demon Hunter",
        specId = 1480,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1.5 + top 40 heroic parses per boss / timed runs per dungeon (Oct 2026)",
    },

    rotationSpells = {
        { spellId = 473662 },  -- Consume
        { spellId = 1217610 }, -- Devour (Consume during Void Metamorphosis)
        { spellId = 473728 },  -- Void Ray
        { spellId = 1226019 }, -- Reap
        { spellId = 1245453 }, -- Cull (Reap during Void Metamorphosis)
        { spellId = 1221150 }, -- Collapsing Star
        { spellId = 1241937 }, -- Soul Immolation
        { spellId = 1245412 }, -- Voidblade (Void-Scarred)
        { spellId = 1239123 }, -- Hungering Slash (Void-Scarred)
        { spellId = 1246167 }, -- The Hunt
        { spellId = 1245470 }, -- Reaper's Toll (Void-Scarred)
        { spellId = 1245483 }, -- Pierce the Veil (Void-Scarred)
        { spellId = 1259431 }, -- Predator's Wake (Void-Scarred)
    },

    -- Your own buffs. 12.1 hides them in combat, so these show out of
    -- combat and whenever the game lets them through.
    trackedAuras = {
        { spellId = 1217605, name = "Void Metamorphosis", baseDuration = 30, stacks = false },
        { spellId = 1253304, name = "Voidfall",           baseDuration = 30, stacks = true },
        { spellId = 1238488, name = "Moment of Craving",  baseDuration = 8,  stacks = false },
    },

    keyCooldown = {
        spellId = 1221150,
        name = "Collapsing Star",
        duration = 0,
    },

    -- Void Ray and Collapsing Star are long casts; Consume casts on the move.
    failNudges = {
        { error = "moving", spells = { 473728, 1221150 }, name = "Cast while moving",
          text = "Moving: Consume / Devour, Shift ahead of the next Void Ray" },
    },

    -- On cooldown for the top players (Voidblade and The Hunt only for
    -- Void-Scarred; idle alerts skip spells you haven't talented).
    idleCooldowns = {
        { spellId = 473728,  name = "Void Ray" },
        { spellId = 1245412, name = "Voidblade" },
        { spellId = 1246167, name = "The Hunt" },
    },

    -- Method: Eradicate on Moment of Craving.
    procTracking = {
        {
            procAura = 1238488,
            consumeSpells = { 1226019, 1245453 },
            window = 0.5,
            name = "Moment of Craving",
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses (low/high = middle half); values follow
    -- the order of rates. Both hero trees together, so Devour and Reap /
    -- Cull spread wide (Annihilator presses more Devour, Void-Scarred more
    -- Cull). Dungeons (by instance ID): the top 40 timed runs, per minute
    -- in combat (Warcraft Logs' pulls).
    benchmarks = {
        source = "top 40 heroic parses per boss, top 40 timed runs per dungeon (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",  all = true },
            { name = "Devour",          spells = { 1217610 } },
            { name = "Consume",         spells = { 473662 } },
            { name = "Void Ray",        spells = { 473728 } },
            { name = "Collapsing Star", spells = { 1221150 } },
            { name = "Reap / Cull",     spells = { 1226019, 1245453 } },
            { name = "Reaper's Toll",   spells = { 1245470 } },
            { name = "Soul Immolation", spells = { 1241937 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", values = {
                { 36.0, 37.4, 40.0 }, { 4.6, 5.4, 6.9 }, { 6.9, 7.7, 8.2 }, { 5.2, 5.5, 6.0 }, { 1.8, 2.1, 2.4 }, { 1.8, 3.9, 5.3 }, { 3.5, 3.9, 4.3 }, { 1.9, 2.3, 3.0 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", values = {
                { 45.8, 48.8, 52.9 }, { 7.5, 8.3, 9.0 }, { 5.8, 7.0, 7.9 }, { 5.7, 6.1, 6.5 }, { 2.5, 2.6, 2.8 }, { 5.5, 9.2, 12.3 }, { 4.9, 5.3, 5.6 }, { 1.5, 1.6, 1.9 } } },
            [3445] = { name = "Entombed Sentinels", values = {
                { 48.2, 50.5, 52.6 }, { 7.7, 9.0, 10.1 }, { 6.9, 7.8, 8.8 }, { 5.4, 5.7, 6.0 }, { 2.4, 2.6, 2.8 }, { 6.8, 10.6, 12.2 }, { 4.7, 5.1, 5.4 }, { 1.5, 1.6, 1.8 } } },
            [3455] = { name = "Vashnik the Malignant", values = {
                { 44.7, 46.5, 48.3 }, { 7.9, 9.5, 15.0 }, { 6.4, 7.4, 8.4 }, { 5.9, 6.3, 6.8 }, { 2.7, 3.1, 3.5 }, { 1.6, 3.2, 5.5 }, { 3.7, 5.1, 5.5 }, { 1.6, 2.0, 2.8 } } },
            [3497] = { name = "The Lost Explorers", values = {
                { 42.6, 44.5, 47.1 }, { 7.8, 10.1, 13.1 }, { 6.4, 7.1, 8.2 }, { 6.2, 6.9, 7.4 }, { 2.4, 2.8, 3.1 }, { 2.2, 4.1, 5.2 }, { 4.4, 5.0, 5.5 }, { 1.6, 1.7, 1.9 } } },
            [3420] = { name = "Sszorak", values = {
                { 50.2, 52.2, 54.1 }, { 7.9, 8.4, 9.6 }, { 6.9, 7.7, 8.7 }, { 5.6, 5.9, 6.3 }, { 2.4, 2.6, 2.8 }, { 10.1, 11.5, 12.9 }, { 4.8, 5.2, 5.4 }, { 1.5, 1.8, 2.0 } } },
            [3421] = { name = "The Twin Fangs", values = {
                { 40.4, 41.9, 43.4 }, { 16.3, 17.8, 19.2 }, { 7.1, 7.6, 8.6 }, { 6.9, 7.3, 7.5 }, { 3.2, 3.6, 3.7 }, { 1.5, 2.3, 3.0 }, nil, { 1.5, 1.7, 1.8 } } },
            [3429] = { name = "The Coiled Altar", values = {
                { 43.0, 44.9, 47.0 }, { 7.4, 8.2, 8.7 }, { 5.9, 6.6, 7.5 }, { 5.5, 6.1, 6.6 }, { 2.4, 2.5, 2.7 }, { 4.5, 5.9, 8.5 }, { 4.5, 4.9, 5.4 }, { 1.6, 1.7, 2.0 } } },
            [3379] = { name = "Nymrissa Wavecaller", values = {
                { 38.9, 41.3, 45.9 }, { 8.4, 11.9, 16.3 }, { 6.5, 7.0, 7.6 }, { 6.2, 6.6, 6.9 }, { 2.7, 3.0, 3.3 }, { 2.2, 4.0, 6.4 }, { 0.0, 2.2, 5.0 }, { 1.4, 1.7, 1.9 } } },
        },
        overall = { name = "all heroic bosses", values = {
            { 42.1, 45.7, 50.1 }, { 7.4, 8.8, 11.6 }, { 6.4, 7.4, 8.3 }, { 5.7, 6.2, 6.8 }, { 2.4, 2.7, 3.1 }, { 2.6, 5.1, 10.3 }, { 3.8, 4.8, 5.4 }, { 1.5, 1.7, 2.1 } } },
        dungeons = {
            [2993] = { name = "Altar of Fangs", values = {
                { 37.8, 40.3, 42.3 }, { 9.5, 14.7, 17.0 }, { 6.9, 7.8, 8.5 }, { 5.7, 6.4, 7.0 }, { 3.0, 3.3, 3.6 }, { 0.6, 1.3, 1.9 }, nil, { 1.7, 1.9, 2.3 } } },
            [2825] = { name = "Den of Nalorakk", values = {
                { 36.2, 38.0, 40.8 }, { 10.7, 15.7, 16.3 }, { 7.7, 8.3, 8.8 }, { 5.8, 6.4, 6.7 }, { 2.9, 3.3, 3.4 }, { 0.7, 1.1, 1.9 }, nil, { 1.5, 1.7, 1.9 } } },
            [1762] = { name = "Kings' Rest", values = {
                { 38.3, 40.2, 42.6 }, { 9.5, 14.1, 16.8 }, { 7.6, 8.3, 8.9 }, { 5.8, 6.4, 7.0 }, { 2.7, 3.0, 3.3 }, { 0.9, 1.4, 2.5 }, nil, { 1.7, 1.9, 2.3 } } },
            [2813] = { name = "Murder Row", values = {
                { 38.1, 41.0, 43.0 }, { 8.8, 10.3, 16.1 }, { 7.3, 7.9, 8.4 }, { 5.6, 6.2, 6.9 }, { 2.8, 3.1, 3.5 }, { 1.0, 1.6, 2.7 }, { 0.0, 3.9, 4.4 }, { 1.8, 2.0, 2.5 } } },
            [2521] = { name = "Ruby Life Pools", values = {
                { 38.6, 41.6, 43.9 }, { 9.7, 11.7, 16.9 }, { 6.9, 7.6, 8.3 }, { 5.7, 6.2, 6.9 }, { 2.9, 3.2, 3.6 }, { 0.7, 1.3, 2.1 }, { 0.0, 3.7, 4.5 }, { 1.7, 1.9, 2.6 } } },
            [1877] = { name = "Temple of Sethraliss", values = {
                { 37.7, 39.1, 41.7 }, { 9.8, 14.7, 16.5 }, { 7.3, 8.1, 8.9 }, { 5.6, 6.4, 6.9 }, { 2.8, 3.2, 3.5 }, { 0.8, 1.3, 1.8 }, nil, { 1.6, 1.8, 2.0 } } },
            [2859] = { name = "The Blinding Vale", values = {
                { 39.0, 41.5, 44.3 }, { 11.0, 15.3, 17.4 }, { 7.1, 7.8, 8.6 }, { 5.9, 6.8, 7.4 }, { 3.0, 3.5, 3.6 }, { 1.0, 1.3, 1.9 }, nil, { 1.7, 1.9, 2.4 } } },
            [2923] = { name = "Voidscar Arena", values = {
                { 39.1, 40.9, 43.1 }, { 9.5, 13.4, 17.5 }, { 8.0, 8.4, 9.2 }, { 5.7, 6.1, 6.9 }, { 2.6, 3.2, 3.6 }, { 0.8, 1.3, 2.1 }, { 0.0, 1.8, 4.3 }, { 1.6, 1.9, 2.1 } } },
        },
        -- Dummies with /ob mode mythic: all 317 runs together.
        dungeonOverall = { name = "all M+ dungeons", values = {
            { 38.1, 40.2, 42.8 }, { 9.7, 14.5, 16.7 }, { 7.3, 8.1, 8.8 }, { 5.7, 6.4, 6.9 }, { 2.8, 3.2, 3.5 }, { 0.8, 1.3, 2.0 }, nil, { 1.6, 1.9, 2.2 } } },
    },

    -- /ob bars: role for role on the keys your other ranged specs use
    -- (binds are account-wide): Consume on 1 (it becomes Devour), Void Ray
    -- on 2, Reap on 3 (Cull in Void Metamorphosis), Collapsing Star on 4,
    -- Soul Immolation on 5, The Hunt on Q, Voidblade on G, Hungering Slash
    -- on Shift-2, Vengeful Retreat on R. Interrupt Shift-E, stun Shift-Q,
    -- defensives on ` / Shift-`, Shift on F. One layout for both hero
    -- trees, raid and M+.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 473662,  note = "Consume / Devour: most pressed, casts on the move" },
        { slot = 2,  key = "2",       spellId = 473728,  note = "Void Ray: every ~7s, channel it fully (resets Reap)" },
        { slot = 3,  key = "3",       spellId = 1226019, note = "Reap / Cull: at 4+ souls, Eradicate on Moment of Craving" },
        { slot = 4,  key = "4",       spellId = 1221150, note = "Collapsing Star: in Void Metamorphosis (~3 a minute)" },
        { slot = 5,  key = "5",       spellId = 1241937, note = "Soul Immolation: as Void Metamorphosis ends, and a heal" },
        { slot = 6,  key = "Q",       spellId = 1246167, note = "The Hunt (Void-Scarred): right before Void Metamorphosis (~65s)" },
        { slot = 7,  key = "G",       spellId = 1245412, note = "Voidblade (Void-Scarred): before Void Metamorphosis" },
        { slot = 62, key = "Shift-2", spellId = 1239123, note = "Hungering Slash (Void-Scarred): turns into Reaper's Toll" },
        { slot = 67, key = "R",       spellId = 198793,  note = "Vengeful Retreat: with Voidstep (Void-Scarred)" },
        { slot = 63, key = "Shift-3", macro = { name = "OB Misery", spells = { 207684 }, cursor = true },
          note = "Sigil of Misery at your cursor: fear a pack (M+)" },
        { slot = 64, key = "Shift-4", spellId = 217832, note = "Imprison (M+)" },
        { slot = 65, key = "Shift-5", spellId = 278326, note = "Consume Magic: an enemy buff (M+)" },
        { slot = 66, key = "Shift-Q", spellId = 1234195, note = "Void Nova: stun a pack (93% of top M+ runs)" },
        { slot = 50, key = "Shift-E", spellId = 183752, note = "Disrupt: interrupt" },
        { slot = 70, key = "F",       spellId = 1234796, note = "Shift: reposition before a Void Ray or Collapsing Star" },
        { slot = 55, key = "`",       spellId = 198589, note = "Blur: defensive" },
        { slot = 56, key = "Shift-`", spellId = 196718, note = "Darkness: group defensive" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1.5, one priority per
    -- hero tree (Void-Scarred when you know Voidblade).
    rotationSheet = {
        { title = "Annihilator", unknown = { 1245412 }, lines = {
            { spellId = 473662,  text = "Consume with Soulburst; Void Metamorphosis when available" },
            { spellId = 1226019, text = "Reap / Eradicate at 4+ souls or 3 Voidfall" },
            { spellId = 473728,  text = "Void Ray, Consume" },
            { text = "In Void Metamorphosis:" },
            { spellId = 1217610, text = "Devour with Soulburst; Cull / Eradicate at 4+ souls or 3 Voidfall" },
            { spellId = 1221150, text = "Collapsing Star at 35+ souls stored, else Void Ray" },
            { spellId = 1241937, text = "Soul Immolation as you leave it" },
        } },
        { title = "Void-Scarred", known = { 1245412 }, lines = {
            { spellId = 473662,  text = "Consume when it triggers Soulburst, Reap at 4+ souls" },
            { spellId = 1241937, text = "Soul Immolation if none is rolling" },
            { spellId = 1245412, text = "Voidblade, Vengeful Retreat, The Hunt, then Void Metamorphosis" },
            { spellId = 1239123, text = "Hungering Slash, Void Ray, Consume" },
            { text = "In Void Metamorphosis:" },
            { spellId = 1245453, text = "Cull at 4+ souls and max charges, Reaper's Toll" },
            { spellId = 1245483, text = "Pierce the Veil, Predator's Wake, Void Ray, Collapsing Star" },
            { spellId = 1217610, text = "Cull at 4+ souls, Devour; Soul Immolation as you leave" },
        } },
        { title = "Moving", lines = {
            { spellId = 1234796, text = "Void Ray and Collapsing Star need you still: Shift first" },
            { spellId = 473662,  text = "Consume casts on the move" },
        } },
    },

    -- Stats: Method: Mastery > Haste >= Crit >> Versatility.
    statPriority = { MASTERY = 1, HASTE = 2, CRIT = 2, VERS = 4 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 473662,  st = 1, aoe = 1, alt = { 1217610 }, note = "Consume / Devour" },
        { spellId = 473728,  st = 1, aoe = 1, note = "Every ~7s" },
        { spellId = 1226019, st = 1, aoe = 1, alt = { 1245453 }, note = "Reap / Cull" },
        { spellId = 1221150, st = 1, aoe = 1, note = "Void Metamorphosis" },
        { spellId = 1241937, st = 2, aoe = 2, note = "Heal, end of Void Metamorphosis" },
        { spellId = 1245412, st = 2, aoe = 2, note = "Void-Scarred" },
        { spellId = 1239123, st = 2, aoe = 2, note = "Void-Scarred" },
        { spellId = 1246167, st = 3, aoe = 3, note = "Every ~65s" },
        { spellId = 1234796, st = 3, aoe = 3, note = "Movement" },
        { spellId = 183752,  st = 2, aoe = 2, note = "Interrupt" },
    },
})
