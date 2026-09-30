local OffBeat = _G.OffBeat

-- Method 12.1 (updated 15 Aug 2026). Covers both hero trees: Hellcaller
-- (Wither + Malevolence, preferred in raid ST) and Diabolist (Immolate +
-- Diabolic Ritual / Demonic Art). Talents you don't have are ignored.
OffBeat:RegisterProfile({
    meta = {
        name = "Destruction Warlock",
        specId = 267,
        version = 1,
        author = "OffBeat Defaults",
        source = "Method",
    },

    rotationSpells = {
        { spellId = 29722 },  -- Incinerate
        { spellId = 116858 }, -- Chaos Bolt
        { spellId = 17962 },  -- Conflagrate
        { spellId = 6353 },   -- Soul Fire
        { spellId = 265321 }, -- Soulfire (Method links this ID; both listed, only one will fire)
        { spellId = 17877 },  -- Shadowburn
        { spellId = 348 },    -- Immolate (Diabolist)
        { spellId = 445465 }, -- Wither (Hellcaller, replaces Immolate)
        { spellId = 445468 }, -- Wither (cast variant)
        { spellId = 1122 },   -- Summon Infernal
        { spellId = 442726 }, -- Malevolence (Hellcaller)
        { spellId = 428522 }, -- Ruination (Diabolist)
        { spellId = 434635 }, -- Ruination (cast variant)
        { spellId = 5740 },   -- Rain of Fire
        { spellId = 80240 },  -- Havoc
        { spellId = 152108 }, -- Cataclysm
        { spellId = 196447 }, -- Channel Demonfire
    },

    trackedAuras = {
        -- Conflagrate charge -> faster Soul Fire / Incinerate / Chaos Bolt
        { spellId = 117828,  name = "Backdraft",        baseDuration = 10, stacks = true },
        -- Free / instant Shadowburn; Method: spend it for movement or to avoid overcapping
        { spellId = 1245633, name = "Fiendish Cruelty", baseDuration = 0,  stacks = false },
        -- Hellcaller cooldown window: spend Soul Shards inside it
        { spellId = 442726,  name = "Malevolence",      baseDuration = 0,  stacks = false },
        -- Diabolist: Diabolic Ritual finishes -> next Chaos Bolt summons the demon
        { spellId = 428524,  name = "Demonic Art: Overlord",        baseDuration = 0, stacks = false },
        { spellId = 432794,  name = "Demonic Art: Mother of Chaos", baseDuration = 0, stacks = false },
        { spellId = 432795,  name = "Demonic Art: Pit Lord",        baseDuration = 0, stacks = false },
    },

    keyCooldown = {
        spellId = 1122,
        name = "Summon Infernal",
        duration = 30,
    },

    idleCooldowns = {
        { spellId = 1122,   name = "Summon Infernal" },
        { spellId = 442726, name = "Malevolence" }, -- Method: cast on cooldown, don't hold it
    },

    -- Each proc is flagged as wasted if it drops without its consumer being cast.
    -- Backdraft is left out: Soul Fire, Incinerate and Chaos Bolt all consume it.
    procTracking = {
        { procAura = 1245633, consumeSpell = 17877,  window = 0.5, name = "Fiendish Cruelty" },
        { procAura = 428524,  consumeSpell = 116858, window = 0.5, name = "Demonic Art: Overlord" },
        { procAura = 432794,  consumeSpell = 116858, window = 0.5, name = "Demonic Art: Mother of Chaos" },
        { procAura = 432795,  consumeSpell = 116858, window = 0.5, name = "Demonic Art: Pit Lord" },
    },

    -- Method 12.1 (same for both hero trees): Haste > Crit = Mastery >> Vers
    statPriority = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 3 },
})
