local OffBeat = _G.OffBeat

-- Method 12.1 (updated 27 Sep 2026). Covers both hero trees: Riders of the
-- Apocalypse and Deathbringer (Reaper's Mark), with or without Breath.
OffBeat:RegisterProfile({
    meta = {
        name = "Frost Death Knight",
        specId = 251,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1 (27 Sep 2026)",
    },

    rotationSpells = {
        { spellId = 49020 },  -- Obliterate
        { spellId = 49143 },  -- Frost Strike
        { spellId = 49184 },  -- Howling Blast
        { spellId = 207230 }, -- Frostscythe
        { spellId = 194913 }, -- Glacial Advance
        { spellId = 196770 }, -- Remorseless Winter
        { spellId = 279302 }, -- Frostwyrm's Fury
        { spellId = 47568 },  -- Empower Rune Weapon
        { spellId = 1249658 }, -- Breath of Sindragosa
        { spellId = 439843 }, -- Reaper's Mark (Deathbringer)
        { spellId = 46585 },  -- Raise Dead
        { spellId = 49998 },  -- Death Strike
    },

    -- Method 12.1: Obliterate at 2 Killing Machine outranks everything but
    -- cooldowns; Frost Strike on 1 KM can be right (<=1 rune, Razorice at 5).
    -- Howling Blast is only ever cast on Rime, and Remorseless Winter inside
    -- Pillar wastes Killing Machine generation.
    mistakes = {
        {
            type = "bad_cast",
            name = "KM Waste",
            description = "Frost Strike or Glacial Advance at 2 Killing Machine, Obliterate first",
            spells = { 49143, 194913 },
            when = { aura = 51124, minStacks = 2 },
        },
        {
            type = "bad_cast",
            name = "Howling Blast without Rime",
            description = "Howling Blast is only in the priority on a Rime proc",
            spells = { 49184 },
            when = { aura = 59052, absent = true },
        },
        {
            type = "bad_cast",
            name = "Winter in Pillar",
            description = "Remorseless Winter during Pillar of Frost doesn't generate Killing Machine",
            spells = { 196770 },
            when = { aura = 51271 },
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

    -- Method 12.1 (same for both hero trees): Crit > Mastery >= Haste > Vers
    statPriority = { CRIT = 1, MASTERY = 2, HASTE = 2.5, VERS = 3.5 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Rows you don't have talented are hidden.
    keyLayout = {
        { spellId = 49020,   st = 1,          note = "Killing Machine spender, rune dump" },
        { spellId = 207230,           aoe = 1, note = "Replaces Obliterate at 3+ targets" },
        { spellId = 49143,   st = 1, aoe = 1, note = "RP spender. AoE: on Frostbane" },
        { spellId = 49184,   st = 1, aoe = 1, note = "Only on Rime" },
        { spellId = 194913,           aoe = 2, note = "At 75+ RP or in Pillar, 3+ targets" },
        { spellId = 47568,   st = 2, aoe = 2, note = "At 2 charges or under 35 RP" },
        { spellId = 51271,   st = 3, aoe = 3, note = "Main cooldown" },
        { spellId = 279302,  st = 3, aoe = 3, note = "Right after Pillar" },
        { spellId = 1249658, st = 3, aoe = 3, note = "If talented, with Pillar" },
        { spellId = 439843,  st = 3, aoe = 3, note = "Deathbringer, not inside Pillar" },
        { spellId = 46585,   st = 3, aoe = 3, note = "Lowest priority, with the opener" },
    },
})
