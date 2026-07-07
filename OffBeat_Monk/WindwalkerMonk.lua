local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Windwalker Monk",
        specId = 269,
        version = 1,
        author = "OffBeat Defaults",
        source = "Icy Veins / Method",
    },

    rotationSpells = {
        { spellId = 100780 },  -- Tiger Palm
        { spellId = 100784 },  -- Blackout Kick
        { spellId = 107428 },  -- Rising Sun Kick
        { spellId = 113656 },  -- Fists of Fury
        { spellId = 101546 },  -- Spinning Crane Kick
        { spellId = 152175 },  -- Whirling Dragon Punch
        { spellId = 392983 },  -- Strike of the Windlord
        { spellId = 117952 },  -- Crackling Jade Lightning
        { spellId = 322109 },  -- Touch of Death
        { spellId = 468179 },  -- Rushing Wind Kick
        { spellId = 1217413 }, -- Slicing Winds
        { spellId = 443028 },  -- Celestial Conduit
        { spellId = 1272696 }, -- Zenith Stomp
    },

    mistakes = {
        {
            type = "repeat_cast",
            name = "Mastery Break",
            description = "Same ability cast twice breaks Combo Strikes mastery",
        },
    },

    trackedAuras = {
        { spellId = 1249625, name = "Zenith",           baseDuration = 15, stacks = false },
        { spellId = 116768,  name = "Blackout Kick!",   baseDuration = 15, stacks = true },
        { spellId = 220358,  name = "Dance of Chi-Ji",  baseDuration = 15, stacks = true },
        { spellId = 248646,  name = "Tigereye Brew",    baseDuration = 0,  stacks = true },
    },

    keyCooldown = {
        spellId = 1249625,
        name = "Zenith",
        duration = 15,
        wasteSpell = { spellId = 100780, name = "Tiger Palm" },
    },

    idleCooldowns = {
        { spellId = 322109, name = "Touch of Death" },
        { spellId = 392983, name = "Strike of the Windlord" },
        { spellId = 152175, name = "Whirling Dragon Punch" },
    },
})
