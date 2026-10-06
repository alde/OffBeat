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
    benchmarks = {
        source = "top 100 heroic Ula'tek",
        rates = {
            { name = "Rotation casts",       all = true,                  low = 40.5, median = 41.5, high = 42.7 },
            { name = "Hand of Gul'dan",      spells = { 105174 },         low = 12.7, median = 13.1, high = 13.6 },
            { name = "Demonbolt",            spells = { 264178 },         low = 9.2,  median = 9.7,  high = 10.0 },
            { name = "Shadow/Infernal Bolt", spells = { 686, 434506 },    low = 9.3,  median = 10.0, high = 10.6 },
            { name = "Call Dreadstalkers",   spells = { 104316 },         low = 2.7,  median = 2.8,  high = 2.8 },
            { name = "Implosion",            spells = { 196277 },         low = 2.9,  median = 3.2,  high = 3.3 },
            { name = "Ruination",            spells = { 434635 },         low = 1.4,  median = 1.5,  high = 1.5 },
        },
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
