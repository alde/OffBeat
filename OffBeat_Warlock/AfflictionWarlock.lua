local OffBeat = _G.OffBeat

-- Method 12.1 (12 Aug 2026) and Kalamazi 12.1, checked against the top 25
-- heroic parses per boss and 18 top M+ runs (Warcraft Logs, Oct 2026).
--
-- One build for raid and M+: Soul Harvester. Kalamazi calls it the best hero
-- tree in both; all 18 top M+ runs play it; in raid top players pick it on
-- the multi-target bosses (Ula'tek 24 of 25, Nymrissa 23, Twin Fangs 15,
-- Vashnik 16) and Hellcaller on single target, where Soul Harvester players
-- press the same buttons at nearly the same rate. Nobody casts Vile Taint,
-- Soul Rot or Phantom Singularity: no ground-targeted spells. Talents you
-- don't have are ignored.
OffBeat:RegisterProfile({
    meta = {
        name = "Affliction Warlock",
        specId = 265,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1 + Kalamazi 12.1 + top parses (Oct 2026)",
    },

    -- Pet died / missing / low warnings, and pet deaths in training.
    -- Fel Domination makes the next summon instant.
    pet = { quickSummon = 333889, sacrifice = 108503 }, -- Grimoire of Sacrifice: no pet

    rotationSpells = {
        { spellId = 686 },     -- Shadow Bolt
        { spellId = 198590 },  -- Drain Soul (talent, replaces Shadow Bolt)
        { spellId = 980 },     -- Agony
        { spellId = 172 },     -- Corruption
        { spellId = 445465 },  -- Wither (Hellcaller, replaces Corruption)
        { spellId = 445468 },  -- Wither (cast variant)
        { spellId = 1259790 }, -- Unstable Affliction (the ID top players' logs show)
        { spellId = 316099 },  -- Unstable Affliction (older ID)
        { spellId = 27243 },   -- Seed of Corruption
        { spellId = 48181 },   -- Haunt
        { spellId = 1261149 }, -- Malefic Grasp (talent; shows on the Shadow Bolt button)
        { spellId = 1261153 }, -- Malefic Grasp (cast)
        { spellId = 205180 },  -- Summon Darkglare
        { spellId = 442726 },  -- Malevolence (Hellcaller)
        { spellId = 1257052 }, -- Dark Harvest (Soul Harvester)
    },

    -- Shards past 5 are lost, and Agony keeps generating them: at 5, spend
    -- (Unstable Affliction, or Seed of Corruption on 3+) before a filler.
    mistakes = {
        {
            type = "bad_cast",
            name = "Soul Shard Overcap",
            description = "Filler at 5 shards: cast Unstable Affliction (Seed on 3+) first",
            spells = { 686, 198590, 1261153 },
            when = { power = "SoulShards", min = 5 },
        },
    },

    -- Coaching: shards go out during Darkglare. Top players' median per
    -- 20s Darkglare: 7-10 Unstable Affliction + Seed of Corruption (Seed on
    -- the multi-target bosses, Unstable Affliction on single target).
    windows = {
        {
            name = "Darkglare",
            trigger = 205180,
            duration = 20,
            note = "Pool shards before it, then spend them all: Unstable Affliction on 1-2 "
                .. "targets, Seed of Corruption on 3+. Dark Harvest with it. Top players' median: 8.",
            goals = {
                { name = "Unstable Affliction + Seed", spells = { 1259790, 316099, 27243 }, min = 8 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { 25th, median, 75th
    -- percentile } across the top 25 heroic parses per boss (both hero trees:
    -- shard spending looks the same, the spender depends on target count).
    -- window = median Unstable Affliction + Seed per Darkglare.
    benchmarks = {
        source = "top 25 heroic parses per boss (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",          all = true },
            { name = "Unstable Affliction + Seed", spells = { 1259790, 316099, 27243 } },
            { name = "Shadow Bolt / Malefic Grasp", spells = { 686, 198590, 1261153 } },
            { name = "Agony",                   spells = { 980 } },
            { name = "Haunt",                   spells = { 48181 } },
            { name = "Dark Harvest",            spells = { 1257052 } },
            { name = "Summon Darkglare",        spells = { 205180 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 7, values = {
                { 38, 39.7, 41.2 }, { 14.9, 15.8, 16.6 }, { 8.3, 9.2, 9.9 }, { 7.6, 8.5, 9.2 }, { 2.8, 3, 3.2 }, { 1.1, 1.1, 1.3 }, { 0.5, 0.5, 0.5 } } }, -- 24 of 25 Soul Harvester
            [3470] = { name = "Nek'zali the Soulcoiler", window = 9, values = {
                { 50.6, 51.9, 52.2 }, { 16.6, 17.4, 18.6 }, { 16.7, 17.3, 19.6 }, { 6.5, 7.1, 8.4 }, { 3.5, 3.7, 3.8 }, { 1, 1, 1.1 }, { 0.5, 0.6, 0.6 } } }, -- 2 of 25 Soul Harvester
            [3445] = { name = "Entombed Sentinels", window = 9, values = {
                { 49, 50.3, 51.3 }, { 18.1, 18.5, 19.1 }, { 14.1, 16.3, 17.7 }, { 7.2, 7.8, 9.1 }, { 3.1, 3.2, 3.5 }, { 1, 1, 1.1 }, { 0.5, 0.6, 0.6 } } }, -- 1 of 25 Soul Harvester
            [3455] = { name = "Vashnik the Malignant", window = 8, values = {
                { 47.3, 49.9, 51.4 }, { 18.5, 19.6, 20.3 }, { 15.7, 17.9, 19.8 }, { 5.1, 5.6, 6.4 }, { 3.4, 3.4, 3.6 }, { 1.1, 1.2, 1.4 }, { 0.6, 0.6, 0.7 } } }, -- 16 of 25 Soul Harvester
            [3497] = { name = "The Lost Explorers", window = 10, values = {
                { 50.4, 51.8, 54.3 }, { 19.5, 20, 21.3 }, { 13.8, 15.4, 16.7 }, { 7.5, 8.3, 9.8 }, { 3.3, 3.5, 3.6 }, { 1, 1.1, 1.1 }, { 0.6, 0.7, 0.7 } } }, -- 0 of 25 Soul Harvester
            [3420] = { name = "Sszorak", window = 8, values = {
                { 46.1, 47.9, 50.2 }, { 16.2, 16.8, 17.6 }, { 18.1, 20, 21.1 }, { 3.8, 4.6, 5.2 }, { 3.3, 3.5, 3.6 }, { 1, 1.1, 1.2 }, { 0.6, 0.6, 0.7 } } }, -- 5 of 25 Soul Harvester
            [3421] = { name = "The Twin Fangs", window = 9, values = {
                { 43.8, 47.1, 49.8 }, { 19.1, 19.7, 20.8 }, { 12.2, 13.2, 17.4 }, { 5.2, 6.3, 7.3 }, { 3.3, 3.4, 3.5 }, { 1.1, 1.4, 1.5 }, { 0.5, 0.6, 0.6 } } }, -- 15 of 25 Soul Harvester
            [3429] = { name = "The Coiled Altar", window = 10, values = {
                { 47.6, 49.8, 50.9 }, { 16.6, 17.3, 18.4 }, { 18.7, 19.7, 20.1 }, { 4.7, 5.8, 6.5 }, { 3.3, 3.5, 3.6 }, { 0.9, 1, 1 }, { 0.4, 0.5, 0.6 } } }, -- 1 of 25 Soul Harvester
            [3379] = { name = "Nymrissa Wavecaller", window = 7, values = {
                { 41.7, 43.9, 45.3 }, { 17.7, 19, 20.3 }, { 9.2, 10.5, 13.2 }, { 6.9, 7.5, 9.3 }, { 3.1, 3.4, 3.6 }, { 1.1, 1.3, 1.4 }, { 0.5, 0.6, 0.6 } } }, -- 23 of 25 Soul Harvester
        },
        overall = { name = "all heroic bosses", window = 8, values = {
            { 44.9, 48.9, 51.1 }, { 17, 18.4, 19.7 }, { 12.5, 16.5, 19.1 }, { 5.7, 6.9, 8.3 }, { 3.2, 3.4, 3.6 }, { 1, 1.1, 1.3 }, { 0.5, 0.6, 0.6 } } },
    },

    -- /ob bars: role for role on your warlock keys. Spender on 1, short
    -- cooldown on 2, filler on 3, AoE spender on 4, DoT on 5, big cooldown on
    -- Q, second cooldown on Shift-3, the other DoT on G, interrupt Shift-E,
    -- movement F, soulstone F5, long / short defensive on ` / Shift-`. Your
    -- curses (Shift-1, Shift-2), Shadowfury (Shift-4), Drain Life (Shift-5),
    -- potion (E), F1/F2, R and Shift-Q are left alone. Drain Soul (Kalamazi's
    -- builds take it) replaces Shadow Bolt, so key 3 gets whichever you
    -- have; Malefic Grasp takes over that button, Wither the Corruption one.
    -- None of the 36 top parses we read cast Drain Soul: all Shadow Bolt.
    -- Every Affliction AoE here is cast on a target: no cursor macros.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 1259790, alt = { 316099 }, note = "Unstable Affliction: main shard spender (Hand of Gul'dan's spot)" },
        { slot = 2,  key = "2",       spellId = 48181,   note = "Haunt: on cooldown (Dreadstalkers' spot)" },
        { slot = 3,  key = "3",       spellId = 198590,  alt = { 686 }, note = "Drain Soul (or Shadow Bolt): filler, Malefic Grasp shows up here (Shadow Bolt's spot)" },
        { slot = 4,  key = "4",       spellId = 27243,   note = "Seed of Corruption: shard spender on 3+ (Implosion's spot)" },
        { slot = 5,  key = "5",       spellId = 980,     note = "Agony: never let it drop, your only shard source (Demonbolt's spot)" },
        { slot = 6,  key = "Q",       spellId = 205180,  note = "Summon Darkglare: big cooldown (Tyrant's spot)" },
        { slot = 63, key = "Shift-3", spellId = 1257052, note = "Dark Harvest: with Darkglare (Imp Lord's spot)" },
        { slot = 7,  key = "G",       spellId = 172,     note = "Corruption: keep it up (Seed spreads it on packs)" },
        { slot = 50, key = "Shift-E", spellId = 119898,  note = "Command Demon: Spell Lock (interrupt)" },
        { slot = 70, key = "F",       spellId = 111400,  note = "Burning Rush: movement" },
        { slot = 25, key = "F5",      spellId = 20707,   note = "Soulstone: combat rez" },
        { slot = 55, key = "`",       spellId = 104773,  note = "Unending Resolve: long defensive" },
        { slot = 56, key = "Shift-`", spellId = 108416,  note = "Dark Pact: short defensive" },
    },

    -- The movable cheat sheet (/ob sheet): Kalamazi 12.1 Soul Harvester.
    rotationSheet = {
        { title = "Before the pull", lines = {
            { spellId = 108503, text = "Summon Felhunter, then Grimoire of Sacrifice (no pet to keep alive)" },
            { spellId = 48181,  text = "Precast Haunt" },
            { spellId = 980,    text = "M+: Agony on a few mobs while the pack is gathered" },
        } },
        { title = "Single target", lines = {
            { spellId = 980,     text = "Agony: never let it drop, it's your only shard source (refresh in the last ~5s)" },
            { spellId = 172,     text = "Corruption: keep it up" },
            { spellId = 48181,   text = "Haunt: on cooldown" },
            { spellId = 205180,  text = "Summon Darkglare: pool shards, then spend them all in it (top players: 8)" },
            { spellId = 1257052, text = "Dark Harvest: with Darkglare" },
            { spellId = 442726,  text = "Malevolence: on cooldown" },
            { spellId = 1259790, alt = { 316099 }, text = "Unstable Affliction: spend shards, never sit at 5; free on Shard Instability" },
            { spellId = 198590,  alt = { 686 }, text = "Drain Soul / Shadow Bolt: filler, becomes Malefic Grasp (cast that whenever it shows). Drain Soul is a channel: on the move, cast the instants" },
        } },
        { title = "Packs and adds (3+)", lines = {
            { spellId = 27243,   text = "Seed of Corruption: spend shards on it, it spreads Corruption" },
            { spellId = 980,     text = "Agony on as many as you can (tab through): more Agony, more shards" },
            { spellId = 48181,   text = "Haunt: keep it up on one target" },
            { spellId = 205180,  text = "Darkglare + Dark Harvest on big packs, then Seed spam" },
        } },
    },

    keyCooldown = {
        spellId = 205180,
        name = "Summon Darkglare",
        duration = 20,
    },

    idleCooldowns = {
        { spellId = 205180,  name = "Summon Darkglare" },
        { spellId = 442726,  name = "Malevolence" },
        { spellId = 1257052, name = "Dark Harvest" },
    },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Rows you don't have talented are hidden.
    keyLayout = {
        { spellId = 1259790, alt = { 316099 }, st = 1, aoe = 2, note = "Main shard spender (Seed on 3+)" },
        { spellId = 27243,            aoe = 1, note = "AoE shard spender, spam when stacked" },
        { spellId = 686,     st = 1, aoe = 2, note = "Filler" },
        { spellId = 198590,  st = 1, aoe = 2, note = "Channeled filler with execute" },
        { spellId = 980,     st = 2, aoe = 1, note = "AoE: keep it on 4-6 targets for shards" },
        { spellId = 445465, alt = { 445468 }, st = 2, aoe = 2, note = "Hellcaller: replaces Corruption" },
        { spellId = 172,     st = 2, aoe = 2, note = "Keep it up" },
        { spellId = 48181,   st = 2, aoe = 2, note = "Precast, keep it on the main target" },
        { spellId = 1261149, st = 2,          note = "Inside Darkglare, if specced" },
        { spellId = 205180,  st = 3, aoe = 3, note = "Main cooldown, dump shards during it" },
        { spellId = 442726,  st = 3, aoe = 3, note = "Hellcaller" },
        { spellId = 1257052, st = 3, aoe = 3, note = "Soul Harvester: cast at 0-1 shards" },
    },
})
