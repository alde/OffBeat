local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Demonology Warlock",
        specId = 266,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method / Icy Veins / Wowhead",
    },

    rotationSpells = {
        { spellId = 686 },    -- Shadow Bolt
        { spellId = 264178 }, -- Demonbolt
        { spellId = 105174 }, -- Hand of Gul'dan
        { spellId = 104316 }, -- Call Dreadstalkers
        { spellId = 265187 }, -- Summon Demonic Tyrant
        { spellId = 196277 }, -- Implosion
        { spellId = 264130 }, -- Power Siphon
        { spellId = 111898 }, -- Grimoire: Felguard
        { spellId = 264119 }, -- Summon Vilefiend (talent)
        { spellId = 267171 }, -- Demonic Strength
        { spellId = 460551 }, -- Doom (talent, applied via Demonbolt)
    },

    trackedAuras = {
        { spellId = 264173, name = "Demonic Core",  baseDuration = 20, stacks = true },
        { spellId = 265273, name = "Demonic Power",  baseDuration = 15, stacks = false },
    },

    keyCooldown = {
        spellId = 265187,
        name = "Summon Demonic Tyrant",
        duration = 15,
    },

    idleCooldowns = {
        { spellId = 104316, name = "Call Dreadstalkers" },
        { spellId = 264130, name = "Power Siphon" },
        { spellId = 111898, name = "Grimoire: Felguard" },
        { spellId = 264119, name = "Summon Vilefiend" },
    },

    procTracking = {
        {
            procAura = 264173,
            consumeSpell = 264178,
            window = 0.5,
            name = "Demonic Core",
        },
    },
})
