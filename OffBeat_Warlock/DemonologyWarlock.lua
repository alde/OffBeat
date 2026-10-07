local OffBeat = _G.OffBeat

-- Method 12.1 (updated 27 Sep 2026). Diabolist is Method's pick for both raid
-- and M+; Soul Harvester is covered by the same spell list. 12.1 dropped
-- Grimoire: Felguard, Summon Vilefiend and Demonic Strength from the builds in
-- favour of Summon Doomguard and the Grimoire: Imp Lord / Fel Ravager choice
-- node. Talents you don't have are ignored.
OffBeat:RegisterProfile({
    meta = {
        name = "Demonology Warlock",
        specId = 266,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1 (27 Sep 2026)",
    },

    rotationSpells = {
        { spellId = 686 },     -- Shadow Bolt
        { spellId = 264178 },  -- Demonbolt
        { spellId = 105174 },  -- Hand of Gul'dan
        { spellId = 104316 },  -- Call Dreadstalkers
        { spellId = 265187 },  -- Summon Demonic Tyrant
        { spellId = 18540 },   -- Summon Doomguard
        { spellId = 1276452 }, -- Grimoire: Imp Lord (choice node)
        { spellId = 1276467 }, -- Grimoire: Fel Ravager (choice node)
        { spellId = 196277 },  -- Implosion
        { spellId = 264130 },  -- Power Siphon (talent)
        { spellId = 460551 },  -- Doom (talent, applied via Demonbolt)
        { spellId = 434635 },  -- Ruination (Diabolist)
        { spellId = 434506 },  -- Infernal Bolt (Diabolist)
    },

    trackedAuras = {
        -- Instant Demonbolt. Method: don't overcap (cap 4), spend at 2+ outside Tyrant
        { spellId = 264173, name = "Demonic Core",  baseDuration = 20, stacks = true },
        -- Tyrant empowerment on your demons (extended by Reign of Tyranny)
        { spellId = 265273, name = "Demonic Power", baseDuration = 15, stacks = false },
    },

    keyCooldown = {
        spellId = 265187,
        name = "Summon Demonic Tyrant",
        duration = 15,
    },

    -- Method: Dreadstalkers go on cooldown unless you're lining them up for
    -- Tyrant (Reign of Tyranny); disable its idle nag under Spec if that's noisy.
    -- Summon Doomguard and Power Siphon are left out: none of the top 93
    -- heroic Ula'tek parses (5 Oct 2026) cast either.
    idleCooldowns = {
        { spellId = 104316,  name = "Call Dreadstalkers" },
        { spellId = 1276452, name = "Grimoire: Imp Lord" },
        { spellId = 1276467, name = "Grimoire: Fel Ravager" },
    },

    -- Method: "don't overcap Demonic Core procs" (cap 4), and Demonbolt is
    -- only ever used instant off a Demonic Core (a hardcast precast before
    -- the pull is fine). Hardcasts are told apart by the cast bar, not the
    -- Demonic Core buff, which the game can hide from addons in combat.
    mistakes = {
        {
            type = "bad_cast",
            name = "Hardcast Demonbolt",
            description = "Demonbolt with a cast time in combat (no Demonic Core)",
            spells = { 264178 },
            when = { { hardcast = true }, { combat = true } },
        },
        {
            type = "bad_cast",
            name = "Demonic Core Overcap",
            description = "Shadow Bolt at 4 Demonic Core, spend one on Demonbolt first",
            spells = { 686 },
            when = { aura = 264173, minStacks = 4 },
        },
        -- Shards gained past 5 are lost (Twin Fangs, 6 Oct: ~3 shards a
        -- minute lost this way vs ~0 for top parses). Shadow Bolt gives 1,
        -- Demonbolt 2, Infernal Bolt 3. Instant Demonbolt while moving is
        -- fine: nothing that spends shards can be cast on the move.
        {
            type = "bad_cast",
            name = "Soul Shard Overcap",
            description = "Shadow Bolt at 5 shards, cast Hand of Gul'dan (or Tyrant) first",
            spells = { 686 },
            when = { power = "SoulShards", min = 5 },
        },
        {
            type = "bad_cast",
            name = "Soul Shard Overcap",
            description = "Demonbolt at 4+ shards while standing still, cast Hand of Gul'dan first",
            spells = { 264178 },
            when = { { power = "SoulShards", min = 4 }, { moving = false }, { combat = true } },
        },
        {
            type = "bad_cast",
            name = "Soul Shard Overcap",
            description = "Infernal Bolt at 3+ shards, cast Hand of Gul'dan first",
            spells = { 434506 },
            when = { power = "SoulShards", min = 3 },
        },
    },

    -- Coaching: Tyrant opens Dominion of Argus' window, and the guides say to
    -- pool shards for it and fit as many Hand of Gul'dans in as you can
    -- (Kalamazi: "maximize Hand of Gul'dan casts within the 25-second window").
    -- Across the top 93 heroic Ula'tek parses the median window holds 8
    -- Hand of Gul'dans and 90% hold 6 or more.
    windows = {
        {
            name = "Tyrant",
            trigger = 265187,
            duration = 25,
            note = "Pool shards and Demonic Cores before Tyrant, then spend everything on "
                .. "Hand of Gul'dan inside the 25s Dominion of Argus window. Top 100 median: "
                .. "8 per window, 90% get 6+.",
            setup = {
                { name = "5 Soul Shards", when = { power = "SoulShards", min = 5 } },
            },
            goals = {
                { name = "Hand of Gul'dan", spells = { 105174 }, min = 8 },
            },
        },
    },

    -- Per-minute rates of the top 93 heroic Ula'tek parses (Warcraft Logs,
    -- 5 Oct 2026): low/high are the middle half, scored at combat end in
    -- training mode.
    -- Per-boss top-parse cast rates (casts per minute), {low, median, high}
    -- across the top 40 heroic parses; values follow the order of rates.
    -- window = top players' median Hand of Gul'dan count per Tyrant window.
    benchmarks = {
        source = "top 40 heroic parses per boss (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",       all = true },
            { name = "Hand of Gul'dan",      spells = { 105174 } },
            { name = "Demonbolt",            spells = { 264178 } },
            { name = "Shadow/Infernal Bolt", spells = { 686, 434506 } },
            { name = "Call Dreadstalkers",   spells = { 104316 } },
            { name = "Implosion",            spells = { 196277 } },
            { name = "Ruination",            spells = { 434635 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 8, values = {
                { 41.2, 42.5, 43.5 }, { 12.9, 13.4, 14.0 }, { 9.5, 9.9, 10.2 }, { 9.8, 10.2, 10.6 }, { 2.7, 2.8, 2.8 }, { 3.0, 3.2, 3.3 }, { 1.4, 1.5, 1.5 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 9, values = {
                { 47.6, 48.8, 50.5 }, { 15.0, 15.6, 16.3 }, { 10.2, 10.8, 11.1 }, { 11.8, 12.8, 13.4 }, { 2.9, 2.9, 3.0 }, { 3.3, 3.5, 3.7 }, { 1.5, 1.6, 1.6 } } },
            [3445] = { name = "Entombed Sentinels", window = 8, values = {
                { 46.0, 47.1, 48.7 }, { 14.6, 15.0, 15.7 }, { 10.1, 10.7, 11.3 }, { 11.6, 12.5, 13.3 }, { 2.9, 2.9, 3.0 }, { 3.1, 3.3, 3.5 }, { 1.5, 1.6, 1.6 } } },
            [3455] = { name = "Vashnik the Malignant", window = 9, values = {
                { 47.0, 49.3, 50.8 }, { 14.9, 15.5, 16.2 }, { 10.2, 10.7, 11.2 }, { 12.3, 14.0, 14.4 }, { 2.8, 2.9, 3.0 }, { 3.1, 3.4, 3.5 }, { 1.5, 1.6, 1.6 } } },
            [3497] = { name = "The Lost Explorers", window = 9, values = {
                { 49.5, 50.4, 51.6 }, { 15.7, 16.1, 16.6 }, { 10.1, 10.8, 11.4 }, { 12.3, 13.3, 14.6 }, { 2.9, 3.0, 3.1 }, { 3.4, 3.6, 3.8 }, { 1.4, 1.5, 1.6 } } },
            [3420] = { name = "Sszorak", window = 9, values = {
                { 46.4, 47.5, 48.6 }, { 14.8, 15.2, 15.7 }, { 10.0, 10.6, 11.2 }, { 11.3, 12.1, 12.8 }, { 2.9, 3.0, 3.0 }, { 3.2, 3.4, 3.6 }, { 1.5, 1.5, 1.6 } } },
            [3421] = { name = "The Twin Fangs", window = 9, values = {
                { 46.9, 47.6, 49.0 }, { 14.9, 15.3, 15.8 }, { 10.3, 10.9, 11.4 }, { 11.3, 11.8, 12.6 }, { 2.9, 3.0, 3.0 }, { 3.5, 3.6, 3.6 }, { 1.5, 1.6, 1.6 } } },
            [3429] = { name = "The Coiled Altar", window = 9, values = {
                { 46.6, 47.6, 48.2 }, { 15.2, 15.4, 15.8 }, { 10.7, 11.0, 11.3 }, { 11.0, 12.0, 12.6 }, { 2.8, 2.9, 3.0 }, { 3.3, 3.4, 3.6 }, { 1.5, 1.6, 1.7 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 8, values = {
                { 44.9, 46.7, 48.1 }, { 14.0, 14.8, 15.4 }, { 9.7, 10.3, 11.0 }, { 10.6, 11.6, 13.0 }, { 2.8, 2.9, 3.0 }, { 3.2, 3.4, 3.5 }, { 1.4, 1.5, 1.6 } } },
        },
        overall = { name = "all heroic bosses", window = 9, values = {
            { 46.0, 47.6, 49.6 }, { 14.6, 15.3, 15.9 }, { 10.1, 10.7, 11.2 }, { 10.9, 12.3, 13.2 }, { 2.8, 2.9, 3.0 }, { 3.2, 3.4, 3.6 }, { 1.5, 1.5, 1.6 } } },
    },

    -- Demonic Core dropping without a Demonbolt is a wasted instant cast.
    procTracking = {
        {
            procAura = 264173,
            consumeSpells = { 264178 },
            window = 0.5,
            name = "Demonic Core",
        },
    },

    -- Method 12.1 (same for both hero trees): Crit > Haste = Mastery > Vers
    statPriority = { CRIT = 1, HASTE = 2, MASTERY = 2, VERS = 3 },

    -- Key Layout page (Method 12.1, updated 27 Sep 2026).
    -- st / aoe tier: 1 = core (best keys), 2 = regular, 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 686,     st = 1, aoe = 1, note = "Filler, builds Soul Shards" },
        { spellId = 105174,  st = 1, aoe = 1, note = "Costs 3 Soul Shards, summons 3 Wild Imps" },
        { spellId = 264178,  st = 1, aoe = 1, note = "Demonic Core procs. AoE: spread Doom" },
        { spellId = 196277,  st = 2, aoe = 1, note = "At 6+ Imps" },
        { spellId = 104316,  st = 2, aoe = 2, note = "On cooldown unless lining up Tyrant" },
        { spellId = 264130,  st = 2, aoe = 2, note = "Top parses don't take it" },
        { spellId = 265187,  st = 3, aoe = 3, note = "Main cooldown, go in at 5 shards" },
        { spellId = 18540,   st = 3, aoe = 3, note = "Top parses don't take it" },
        { spellId = 1276452, st = 3, aoe = 3, note = "Grimoire choice node" },
        { spellId = 1276467, st = 3, aoe = 3, note = "Grimoire choice node" },
    },
})
