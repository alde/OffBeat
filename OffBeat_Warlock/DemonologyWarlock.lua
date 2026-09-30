local OffBeat = _G.OffBeat

-- Method 12.1 (updated 27 Sep 2026). Diabolist is Method's pick for both raid
-- and M+; Soul Harvester is covered by the same spell list. 12.1 dropped
-- Grimoire: Felguard, Summon Vilefiend and Demonic Strength from the builds in
-- favour of Summon Doomguard and the Grimoire: Imp Lord / Fel Ravager choice
-- node. Talents you don't have are ignored.
OffBeat:RegisterProfile({
    meta = {
        name = "Demonology Warlock",
        specId = 266,
        version = 2,
        author = "OffBeat Defaults",
        source = "Method 12.1 (27 Sep 2026)",
    },

    rotationSpells = {
        { spellId = 686 },     -- Shadow Bolt
        { spellId = 264178 },  -- Demonbolt
        { spellId = 105174 },  -- Hand of Gul'dan
        { spellId = 104316 },  -- Call Dreadstalkers
        { spellId = 265187 },  -- Summon Demonic Tyrant
        { spellId = 18540 },   -- Summon Doomguard
        { spellId = 1288945 }, -- Grimoire: Imp Lord (choice node)
        { spellId = 1276467 }, -- Grimoire: Fel Ravager (choice node)
        { spellId = 196277 },  -- Implosion
        { spellId = 264130 },  -- Power Siphon (talent)
        { spellId = 460551 },  -- Doom (talent, applied via Demonbolt)
    },

    trackedAuras = {
        -- Instant Demonbolt. Method: don't overcap (cap 4), spend at 2+ outside Tyrant
        { spellId = 264173, name = "Demonic Core",  baseDuration = 20, stacks = true },
        -- Tyrant empowerment on your demons (extended by Reign of Tyranny)
        { spellId = 265273, name = "Demonic Power", baseDuration = 15, stacks = false },
    },

    keyCooldown = {
        spellId = 265187,
        name = "Summon Demonic Tyrant",
        duration = 15,
    },

    -- Method: Dreadstalkers go on cooldown unless you're lining them up for
    -- Tyrant (Reign of Tyranny); disable its idle nag under Spec if that's noisy.
    idleCooldowns = {
        { spellId = 104316,  name = "Call Dreadstalkers" },
        { spellId = 264130,  name = "Power Siphon" },
        { spellId = 18540,   name = "Summon Doomguard" },
        { spellId = 1288945, name = "Grimoire: Imp Lord" },
        { spellId = 1276467, name = "Grimoire: Fel Ravager" },
    },

    -- Demonic Core dropping without a Demonbolt is a wasted instant cast.
    procTracking = {
        {
            procAura = 264173,
            consumeSpell = 264178,
            window = 0.5,
            name = "Demonic Core",
        },
    },

    -- Method 12.1 (same for both hero trees): Crit > Haste = Mastery > Vers
    statPriority = { CRIT = 1, HASTE = 2, MASTERY = 2, VERS = 3 },

    -- Key Layout page (Method 12.1, updated 27 Sep 2026).
    -- st / aoe tier: 1 = core (best keys), 2 = regular, 3 = cooldown, nil = unused.
    keyLayout = {
        { spellId = 686,     st = 1, aoe = 1, note = "Filler, builds Soul Shards" },
        { spellId = 105174,  st = 1, aoe = 1, note = "Spend at 3+ Soul Shards" },
        { spellId = 264178,  st = 1, aoe = 1, note = "Demonic Core procs. AoE: spread Doom" },
        { spellId = 196277,  st = 2, aoe = 1, note = "At 6+ Imps" },
        { spellId = 104316,  st = 2, aoe = 2, note = "On cooldown unless lining up Tyrant" },
        { spellId = 264130,  st = 2, aoe = 2, note = "Precast ~5s before the pull" },
        { spellId = 265187,  st = 3, aoe = 3, note = "Main cooldown, go in at 5 shards" },
        { spellId = 18540,   st = 3, aoe = 3, note = "Opener, before Grimoire" },
        { spellId = 1288945, st = 3, aoe = 3, note = "Grimoire choice node" },
        { spellId = 1276467, st = 3, aoe = 3, note = "Grimoire choice node" },
    },
})
