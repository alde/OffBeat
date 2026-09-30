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
})
