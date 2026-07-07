local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Retribution Paladin",
        specId = 70,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method / Icy Veins",
    },

    rotationSpells = {
        { spellId = 184575 }, -- Blade of Justice
        { spellId = 20271 },  -- Judgment
        { spellId = 53385 },  -- Divine Storm
        { spellId = 85256 },  -- Templar's Verdict
        { spellId = 383328 }, -- Final Verdict
        { spellId = 255937 }, -- Wake of Ashes
        { spellId = 24275 },  -- Hammer of Wrath
        { spellId = 375576 }, -- Divine Toll
        { spellId = 343527 }, -- Execution Sentence
        { spellId = 429826 }, -- Hammer of Light
        { spellId = 407480 }, -- Templar Strike
        { spellId = 406647 }, -- Templar Slash
    },

    trackedAuras = {
        { spellId = 31884,  name = "Avenging Wrath",  baseDuration = 20, stacks = false },
        { spellId = 231895, name = "Crusade",         baseDuration = 25, stacks = true },
        { spellId = 267344, name = "Art of War",      baseDuration = 15, stacks = false },
        { spellId = 326733, name = "Empyrean Power",  baseDuration = 15, stacks = false },
    },

    keyCooldown = {
        spellId = 31884,
        name = "Avenging Wrath",
        duration = 20,
    },

    idleCooldowns = {
        { spellId = 255937, name = "Wake of Ashes" },
        { spellId = 375576, name = "Divine Toll" },
    },

    procTracking = {
        { procAura = 267344, consumeSpell = 184575, window = 0.5, name = "Art of War" },
        { procAura = 326733, consumeSpell = 53385,  window = 0.5, name = "Empyrean Power" },
    },
})
