local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Arcane Mage",
        specId = 62,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method / Icy Veins",
    },

    rotationSpells = {
        { spellId = 30451 },   -- Arcane Blast
        { spellId = 44425 },   -- Arcane Barrage
        { spellId = 5143 },    -- Arcane Missiles
        { spellId = 153626 },  -- Arcane Orb
        { spellId = 1241462 }, -- Arcane Pulse
        { spellId = 365350 },  -- Arcane Surge
        { spellId = 321507 },  -- Touch of the Magi
        { spellId = 12051 },   -- Evocation
        { spellId = 205025 },  -- Presence of Mind
    },

    trackedAuras = {
        { spellId = 79684,  name = "Clearcasting",  baseDuration = 15, stacks = true },
        { spellId = 365350, name = "Arcane Surge",   baseDuration = 12, stacks = false },
        { spellId = 384452, name = "Arcane Salvo",   baseDuration = 0,  stacks = true },
        { spellId = 451038, name = "Arcane Soul",    baseDuration = 0,  stacks = false },
    },

    keyCooldown = {
        spellId = 365350,
        name = "Arcane Surge",
        duration = 12,
    },

    idleCooldowns = {
        { spellId = 365350, name = "Arcane Surge" },
        { spellId = 321507, name = "Touch of the Magi" },
        { spellId = 12051,  name = "Evocation" },
    },

    procTracking = {
        {
            procAura = 79684,
            consumeSpell = 5143,
            window = 0.5,
            name = "Clearcasting",
        },
    },
})
