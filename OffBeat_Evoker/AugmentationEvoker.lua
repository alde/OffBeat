local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "Augmentation Evoker",
        specId = 1473,
        version = 1,
        author = "OffBeat Defaults",
        source = "Icy Veins / Method",
    },

    trackedBuffs = {
        {
            spellId = 395152,
            name = "Ebon Might",
            color = { 0.20, 0.80, 0.35 },
            maxTargets = 1,
            category = "primary",
            baseDuration = 10,
            selfBuff = true,
        },
        {
            spellId = 409311,
            name = "Prescience",
            color = { 0.90, 0.80, 0.20 },
            maxTargets = 2,
            category = "primary",
            baseDuration = 18,
        },
        {
            spellId = 413984,
            name = "Shifting Sands",
            color = { 0.60, 0.50, 0.90 },
            maxTargets = 4,
            category = "secondary",
            baseDuration = 30,
        },
        {
            spellId = 360827,
            name = "Blistering Scales",
            color = { 0.90, 0.40, 0.20 },
            maxTargets = 1,
            category = "secondary",
            baseDuration = 600,
        },
        {
            spellId = 369459,
            name = "Source of Magic",
            color = { 0.40, 0.60, 0.95 },
            maxTargets = 1,
            category = "secondary",
            baseDuration = 3600,
        },
    },

    alerts = {
        { type = "missing_buff", spellId = 360827, name = "Blistering Scales" },
        { type = "missing_buff", spellId = 369459, name = "Source of Magic", condition = "group_has_healer" },
    },

    castWarnings = {
        {
            castNames = { "Fire Breath", "Upheaval", "Eruption" },
            requireBuff = 395152,
            buffName = "Ebon Might",
        },
    },
})
