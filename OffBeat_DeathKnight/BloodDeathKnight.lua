local OffBeat = _G.OffBeat

-- Method 12.1 (updated 4 Sep 2026). Covers both hero trees: San'layn
-- (Vampiric Strike) and Deathbringer (Reaper's Mark, Exterminate).
OffBeat:RegisterProfile({
    meta = {
        name = "Blood Death Knight",
        specId = 250,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1 (4 Sep 2026)",
    },

    rotationSpells = {
        { spellId = 195182 }, -- Marrowrend
        { spellId = 206930 }, -- Heart Strike
        { spellId = 433901 }, -- Vampiric Strike (San'layn)
        { spellId = 49998 },  -- Death Strike
        { spellId = 50842 },  -- Blood Boil
        { spellId = 43265 },  -- Death and Decay
        { spellId = 49028 },  -- Dancing Rune Weapon
        { spellId = 1263824 }, -- Consumption (talent)
        { spellId = 439843 }, -- Reaper's Mark (Deathbringer)
        { spellId = 441378 }, -- Exterminate (Deathbringer)
        { spellId = 55233 },  -- Vampiric Blood
        { spellId = 48707 },  -- Anti-Magic Shell
        { spellId = 48792 },  -- Icebound Fortitude
        { spellId = 46585 },  -- Raise Dead
    },


    trackedAuras = {
        { spellId = 195181, name = "Bone Shield",               baseDuration = 30, stacks = true },
        { spellId = 81256,  name = "Dancing Rune Weapon",       baseDuration = 8,  stacks = false },
        { spellId = 55233,  name = "Vampiric Blood",            baseDuration = 10, stacks = false },
        { spellId = 81141,  name = "Crimson Scourge",           baseDuration = 15, stacks = false },
        -- Method: Blood Boil on Boiling Point
        { spellId = 1265790, name = "Boiling Point",            baseDuration = 0,  stacks = false },
        { spellId = 273947, name = "Hemostasis",                baseDuration = 15, stacks = true },
        { spellId = 390268, name = "Coagulopathy",              baseDuration = 10, stacks = true },
        { spellId = 444040, name = "Essence of the Blood Queen", baseDuration = 20, stacks = true },
        { spellId = 439843, name = "Reaper's Mark",             baseDuration = 12, stacks = true },
    },

    keyCooldown = {
        spellId = 49028,
        name = "Dancing Rune Weapon",
        duration = 8,
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
        {
            procAura = 81141,
            consumeSpells = { 43265 },
            window = 0.5,
            name = "Crimson Scourge",
        },
        {
            procAura = 1265790,
            consumeSpells = { 50842 },
            window = 0.5,
            name = "Boiling Point",
        },
    },

    -- Method 12.1: Deathbringer Crit = Vers = Mastery > Haste; San'layn Haste > Crit = Vers = Mastery
    statPriority = { CRIT = 1, MASTERY = 1, VERS = 1, HASTE = 2 },
    heroStatPriorities = {
        ["Deathbringer"] = { CRIT = 1, MASTERY = 1, VERS = 1, HASTE = 2 },
        ["San'layn"] = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 2 },
    },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Rows you don't have talented are hidden.
    keyLayout = {
        { spellId = 206930, st = 1, aoe = 1, note = "Filler" },
        { spellId = 433901, st = 1, aoe = 1, note = "San'layn: replaces Heart Strike on proc" },
        { spellId = 49998,  st = 1, aoe = 1, note = "Above 75 RP or when you need the heal" },
        { spellId = 195182, st = 1, aoe = 1, note = "Keep 5+ Bone Shield" },
        { spellId = 50842,  st = 1, aoe = 1, note = "Never cap charges, spend Boiling Point" },
        { spellId = 43265,  st = 2, aoe = 1, note = "Keep the buff up, spend Crimson Scourge" },
        { spellId = 441378, st = 2, aoe = 2, note = "Deathbringer: Bone Shield instead of Marrowrend" },
        { spellId = 1263824, alt = { 274156 }, st = 2, aoe = 2, note = "Rank I outside DRW, Rank III after" },
        { spellId = 49028,  st = 3, aoe = 3, note = "Main cooldown" },
        { spellId = 439843, st = 3, aoe = 3, note = "Deathbringer: on cooldown" },
        { spellId = 55233,  st = 3, aoe = 3, note = "Defensive" },
        { spellId = 48707,  st = 3, aoe = 3, note = "Defensive, magic" },
        { spellId = 48792,  st = 3, aoe = 3, note = "Defensive" },
    },
})
