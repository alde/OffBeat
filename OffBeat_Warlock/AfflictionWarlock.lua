local OffBeat = _G.OffBeat

-- Method 12.1 (updated 12 Aug 2026). Covers both hero trees: Hellcaller
-- (Wither + Malevolence) and Soul Harvester (Dark Harvest). Talents you don't
-- have are ignored. The guide gives an opener plus "maintain DoTs, dump shards
-- into Unstable Affliction / Seed during Darkglare" rather than a strict list.
OffBeat:RegisterProfile({
    meta = {
        name = "Affliction Warlock",
        specId = 265,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method 12.1 (12 Aug 2026)",
    },

    rotationSpells = {
        { spellId = 686 },     -- Shadow Bolt
        { spellId = 198590 },  -- Drain Soul (talent, replaces Shadow Bolt)
        { spellId = 980 },     -- Agony
        { spellId = 172 },     -- Corruption
        { spellId = 445465 },  -- Wither (Hellcaller, replaces Corruption)
        { spellId = 445468 },  -- Wither (cast variant)
        { spellId = 316099 },  -- Unstable Affliction
        { spellId = 27243 },   -- Seed of Corruption
        { spellId = 48181 },   -- Haunt
        { spellId = 1261149 }, -- Malefic Grasp (talent)
        { spellId = 205180 },  -- Summon Darkglare
        { spellId = 442726 },  -- Malevolence (Hellcaller)
        { spellId = 1257052 }, -- Dark Harvest (Soul Harvester)
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
        { spellId = 316099,  st = 1,          note = "Main shard spender" },
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
