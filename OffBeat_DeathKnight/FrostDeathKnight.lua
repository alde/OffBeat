local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Frost Death Knight",
        specId = 251,
        version = 1,
        author = "OffBeat Defaults",
        source = "Icy Veins / Method",
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
        { spellId = 152279 }, -- Breath of Sindragosa
        { spellId = 439843 }, -- Reaper's Mark
        { spellId = 343294 }, -- Soul Reaper
        { spellId = 46585 },  -- Raise Dead
        { spellId = 49998 },  -- Death Strike
    },

    mistakes = {
        {
            type = "proc_waste",
            name = "KM Waste",
            description = "Frost Strike or Glacial Advance while Killing Machine is active",
            procAura = 51124,
            wasteSpells = { 49143, 194913 },
        },
    },

    trackedAuras = {
        { spellId = 51124,  name = "Killing Machine",       baseDuration = 10, stacks = true },
        { spellId = 59052,  name = "Rime",                  baseDuration = 15, stacks = false },
        { spellId = 51271,  name = "Pillar of Frost",       baseDuration = 12, stacks = false },
        { spellId = 152279, name = "Breath of Sindragosa",  baseDuration = 0,  stacks = false },
        { spellId = 194879, name = "Icy Talons",            baseDuration = 6,  stacks = true },
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
            consumeSpell = 49184,
            window = 0.5,
            name = "Rime",
        },
    },
})
