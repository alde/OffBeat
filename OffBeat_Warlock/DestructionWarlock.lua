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

    -- Pet died / missing / low warnings, and pet deaths in training.
    -- Fel Domination makes the next summon instant. All of the top 82
    -- heroic Ula'tek parses we could read (Oct 2026) kept a pet out, mostly
    -- the Imp or the Sayaad; none played without one.
    pet = { quickSummon = 333889, sacrifice = 108503 }, -- Grimoire of Sacrifice: no pet

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
        { procAura = 1245633, consumeSpells = { 17877 },  window = 0.5, name = "Fiendish Cruelty" },
        { procAura = 428524,  consumeSpells = { 116858 }, window = 0.5, name = "Demonic Art: Overlord" },
        { procAura = 432794,  consumeSpells = { 116858 }, window = 0.5, name = "Demonic Art: Mother of Chaos" },
        { procAura = 432795,  consumeSpells = { 116858 }, window = 0.5, name = "Demonic Art: Pit Lord" },
    },

    -- Soul Shards past 5 are lost. Incinerate and Conflagrate build them;
    -- at 5, spend one first (Chaos Bolt, or Shadowburn on the move).
    mistakes = {
        {
            type = "bad_cast",
            name = "Soul Shard Overcap",
            description = "Incinerate at 5 shards, cast Chaos Bolt first",
            spells = { 29722 },
            when = { power = "SoulShards", min = 5 },
        },
        {
            type = "bad_cast",
            name = "Soul Shard Overcap",
            description = "Conflagrate at 5 shards, spend a shard first",
            spells = { 17962 },
            when = { power = "SoulShards", min = 5 },
        },
    },

    -- Coaching: Summon Infernal's 30 seconds are where Chaos Bolts count most.
    -- Across the top 40 heroic parses per boss (Oct 2026) the median Infernal
    -- window holds 7 Chaos Bolts (12.6 a minute vs 8.8 outside it). They don't
    -- pool shards for it: median 1.6 shards when they press Infernal, since
    -- the Infernal itself generates them. Method: Malevolence goes on
    -- cooldown and "does not line up" with Infernal.
    windows = {
        {
            name = "Infernal",
            trigger = 1122,
            duration = 30,
            note = "Spend everything on Chaos Bolt while the Infernal is out (it feeds you "
                .. "shards). Top players' median: 7 per window. No need to pool before it.",
            goals = {
                { name = "Chaos Bolt", spells = { 116858 }, min = 7 },
            },
        },
    },

    -- Per-boss top-parse cast rates (casts per minute), { low, median, high }
    -- across the top 40 heroic parses; values follow the order of rates.
    -- window = top players' median Chaos Bolt count per Infernal window.
    -- 357 of those 360 parses play Hellcaller (Wither).
    benchmarks = {
        source = "top 40 heroic parses per boss (Warcraft Logs, Oct 2026)",
        rates = {
            { name = "Rotation casts",    all = true },
            { name = "Chaos Bolt",        spells = { 116858 } },
            { name = "Incinerate",        spells = { 29722 } },
            { name = "Conflagrate",       spells = { 17962 } },
            { name = "Shadowburn",        spells = { 17877 } },
            { name = "Soul Fire",         spells = { 6353, 265321 } },
            { name = "Wither / Immolate", spells = { 445468, 445465, 348 } },
        },
        encounters = {
            [3492] = { name = "Ula'tek", window = 7, values = {
                { 43.0, 44.6, 45.7 }, { 7.6, 8.5, 9.4 }, { 8.3, 9.2, 10.0 }, { 7.6, 7.9, 8.1 }, { 8.0, 9.6, 11.3 }, { 1.0, 1.0, 1.2 }, { 3.3, 3.8, 4.2 } } },
            [3470] = { name = "Nek'zali the Soulcoiler", window = 6, values = {
                { 51.6, 54.3, 55.8 }, { 9.6, 10.0, 10.9 }, { 15.6, 17.5, 19.6 }, { 8.7, 9.0, 9.1 }, { 8.3, 9.1, 9.8 }, { 1.2, 1.3, 1.4 }, { 3.5, 4.2, 4.8 } } },
            [3445] = { name = "Entombed Sentinels", window = 8, values = {
                { 51.2, 52.4, 54.1 }, { 10.9, 11.8, 12.2 }, { 11.8, 12.6, 14.1 }, { 8.3, 8.6, 8.9 }, { 10.3, 11.0, 11.7 }, { 1.2, 1.2, 1.3 }, { 3.2, 3.9, 4.5 } } },
            [3455] = { name = "Vashnik the Malignant", window = 7, values = {
                { 52.1, 54.2, 56.2 }, { 9.6, 10.7, 11.3 }, { 17.7, 19.0, 20.5 }, { 8.6, 8.9, 9.2 }, { 7.6, 8.6, 9.5 }, { 1.2, 1.3, 1.4 }, { 2.1, 2.8, 3.3 } } },
            [3497] = { name = "The Lost Explorers", window = 9, values = {
                { 54.1, 55.0, 55.9 }, { 12.0, 13.2, 14.0 }, { 10.4, 10.8, 11.9 }, { 9.0, 9.2, 9.5 }, { 11.2, 13.1, 15.1 }, { 1.2, 1.3, 1.4 }, { 4.3, 4.6, 5.0 } } },
            [3420] = { name = "Sszorak", window = 6, values = {
                { 50.0, 51.8, 53.2 }, { 9.1, 9.5, 9.9 }, { 19.2, 20.4, 21.3 }, { 8.8, 9.0, 9.2 }, { 6.8, 7.3, 8.0 }, { 1.2, 1.3, 1.4 }, { 2.1, 2.4, 2.5 } } },
            [3421] = { name = "The Twin Fangs", window = 8, values = {
                { 50.2, 51.9, 53.2 }, { 11.9, 12.4, 13.1 }, { 11.5, 12.2, 13.6 }, { 8.7, 8.9, 9.1 }, { 11.1, 11.8, 12.6 }, { 1.1, 1.2, 1.3 }, { 2.5, 2.9, 3.5 } } },
            [3429] = { name = "The Coiled Altar", window = 6, values = {
                { 51.3, 52.4, 54.4 }, { 7.1, 7.8, 8.6 }, { 15.2, 15.8, 16.7 }, { 8.4, 8.7, 9.0 }, { 13.1, 14.2, 15.4 }, { 1.2, 1.3, 1.3 }, { 2.4, 2.7, 2.9 } } },
            [3379] = { name = "Nymrissa Wavecaller", window = 6, values = {
                { 49.0, 51.7, 53.3 }, { 9.1, 9.9, 10.9 }, { 11.9, 13.4, 15.3 }, { 8.6, 9.0, 9.2 }, { 8.7, 9.9, 11.4 }, { 1.2, 1.3, 1.3 }, { 2.9, 3.4, 4.3 } } },
        },
        overall = { name = "all heroic bosses", window = 7, values = {
            { 50.0, 52.4, 54.7 }, { 9.1, 10.4, 11.8 }, { 11.5, 14.3, 17.7 }, { 8.4, 8.9, 9.1 }, { 8.6, 10.3, 12.1 }, { 1.2, 1.3, 1.3 }, { 2.5, 3.3, 4.3 } } },
    },

    -- /ob bars: role for role on your Demonology keys. Spender on 1, short
    -- cooldown on 2, filler on 3, second spender on 4, DoT on 5, big
    -- cooldown on Q, second cooldown on Shift-3, interrupt Shift-E, movement
    -- F, soulstone F5, long / short defensive on ` / Shift-`. G, R and
    -- Shift-Q get Soul Fire, Havoc / Cataclysm and Rain of Fire. Your curses
    -- (Shift-1, Shift-2), Shadowfury (Shift-4), Drain Life (Shift-5), potion
    -- (E) and F1/F2 are left alone.
    --
    -- One build for raid and M+, so practice carries over: Hellcaller in
    -- both (Kalamazi 12.1 lists a Hellcaller M+ build). Raid takes Havoc;
    -- M+ takes Mayhem (passive Havoc) and Cataclysm, and spends on Rain of
    -- Fire at 3+. R is a macro that casts whichever of Havoc and Cataclysm
    -- the loadout has. Top raid parses (31 heroic, Oct 2026): all Hellcaller,
    -- Shadowburn ~9 a minute, no Cataclysm or Rain of Fire. Top M+ runs (48,
    -- Season 2): all Diabolist, every one casts Cataclysm (~1.2 a minute)
    -- and Rain of Fire (~5). Immolate is placed as the base spell; with
    -- Hellcaller the button shows Wither.
    -- Command Demon is Spell Lock with a Felhunter out, or sacrificed with
    -- Grimoire of Sacrifice.
    barLayout = {
        { slot = 1,  key = "1",       spellId = 116858, note = "Chaos Bolt: main shard spender (Hand of Gul'dan's spot)" },
        { slot = 2,  key = "2",       spellId = 17962,  note = "Conflagrate: 2 charges, gives Backdraft (Dreadstalkers' spot)" },
        { slot = 3,  key = "3",       spellId = 29722,  note = "Incinerate: filler, most pressed (Shadow Bolt's spot)" },
        { slot = 4,  key = "4",       spellId = 17877,  note = "Shadowburn: ~9 a minute for top players, free on Fiendish Cruelty (Implosion's spot)" },
        { slot = 5,  key = "5",       spellId = 348,    alt = { 445468 }, note = "Immolate / Wither: keep it up (Demonbolt's spot)" },
        { slot = 6,  key = "Q",       spellId = 1122,   note = "Summon Infernal: big cooldown (Tyrant's spot)" },
        { slot = 63, key = "Shift-3", spellId = 442726, note = "Malevolence: on cooldown (Imp Lord's spot)" },
        { slot = 7,  key = "G",       spellId = 6353,   alt = { 265321 }, note = "Soul Fire: on cooldown, with Backdraft" },
        { slot = 67, key = "R",       macro = { name = "OB Havoc/Cata", spells = { 80240, 152108 } },
          note = "Havoc in raid (second target), Cataclysm in M+ (every pack)" },
        { slot = 66, key = "Shift-Q", spellId = 5740,   note = "Rain of Fire: M+ spender at 3+ targets" },
        { slot = 50, key = "Shift-E", spellId = 119898, note = "Command Demon: Spell Lock (interrupt)" },
        { slot = 70, key = "F",       spellId = 111400, note = "Burning Rush: movement" },
        { slot = 25, key = "F5",      spellId = 20707,  note = "Soulstone: combat rez" },
        { slot = 55, key = "`",       spellId = 104773, note = "Unending Resolve: long defensive" },
        { slot = 56, key = "Shift-`", spellId = 108416, note = "Dark Pact: short defensive" },
    },

    -- The movable cheat sheet (/ob sheet). Method 12.1 / Kalamazi 12.1
    -- priority, checked against the top parses above. Hellcaller sections
    -- show while you know Wither, the Diabolist one otherwise; raid / M+
    -- sections follow the instance you're in (all of them outside).
    rotationSheet = {
        { title = "Before the pull", lines = {
            { spellId = 108503, text = "Summon Felhunter, then Grimoire of Sacrifice (no pet to keep alive)" },
        } },
        { title = "Single target", known = { 445465, 445468 }, lines = {
            { spellId = 445468, alt = { 445465 }, text = "Wither: keep it up, refresh in the last few seconds" },
            { spellId = 442726, text = "Malevolence: on cooldown, don't hold it for Infernal" },
            { spellId = 1122,   text = "Summon Infernal: on cooldown, then Chaos Bolt everything (top players: 7 per Infernal)" },
            { spellId = 116858, text = "Chaos Bolt: spend shards, never sit at 5" },
            { spellId = 17877,  text = "Shadowburn: when Fiendish Cruelty makes it free, and while moving" },
            { spellId = 17962,  text = "Conflagrate: don't sit at 2 charges (gives Backdraft)" },
            { spellId = 6353,   alt = { 265321 }, text = "Soul Fire: on cooldown, with Backdraft" },
            { spellId = 29722,  text = "Incinerate: filler" },
        } },
        { title = "Raid cleave (2 targets)", content = "raid", lines = {
            { spellId = 80240,  text = "Havoc the second target with 2.5-3.5 shards, Wither on both" },
        } },
        -- Kalamazi 12.1 AoE / M+ priority.
        { title = "M+ packs (3+)", content = "dungeon", known = { 445465, 445468 }, lines = {
            { spellId = 152108, text = "Cataclysm: first on every pack, then on cooldown" },
            { spellId = 1122,   text = "Summon Infernal and Malevolence on big packs" },
            { spellId = 5740,   text = "Rain of Fire: spend every shard on it at 3+ (unless one mob must die first)" },
            { spellId = 17962,  text = "Conflagrate, Incinerate, Soul Fire: build shards for it" },
            { text = "2 targets: Mayhem cleaves by itself, Wither both if they live 6+ seconds" },
        } },
        { title = "Diabolist", unknown = { 445465, 445468 }, lines = {
            { spellId = 348,    text = "Immolate: keep it up on what lives" },
            { spellId = 152108, text = "Cataclysm: first on every pack, then on cooldown" },
            { spellId = 1122,   text = "Summon Infernal on big packs and bosses" },
            { spellId = 116858, text = "Chaos Bolt: spender, also at 3+ until lots of targets (then Rain of Fire). Becomes Ruination" },
            { spellId = 17877,  text = "Shadowburn: on Fiendish Cruelty and while moving" },
            { spellId = 17962,  text = "Conflagrate: don't sit at 2 charges" },
            { spellId = 29722,  text = "Incinerate: filler, becomes Infernal Bolt" },
        } },
    },

    -- Method 12.1 (same for both hero trees): Haste > Crit = Mastery >> Vers
    statPriority = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 3 },

    -- Key Layout page. st / aoe tier: 1 = core (best keys), 2 = regular,
    -- 3 = cooldown, nil = unused. Rows you don't have talented are hidden.
    keyLayout = {
        { spellId = 29722,  st = 1, aoe = 1, note = "Filler" },
        { spellId = 116858, st = 1, aoe = 1, note = "Main shard spender, spends Demonic Art" },
        { spellId = 17962,  st = 1, aoe = 1, note = "Don't sit at 2 charges, grants Backdraft" },
        { spellId = 445465, alt = { 445468 }, st = 2, aoe = 2, note = "Hellcaller: never let it drop" },
        { spellId = 348,    st = 2, aoe = 2, note = "Diabolist: keep it up" },
        { spellId = 265321, alt = { 6353 }, st = 2, aoe = 2, note = "Cast with Backdraft" },
        { spellId = 17877,  st = 2, aoe = 2, note = "Fiendish Cruelty, movement, shard cap" },
        { spellId = 5740,   aoe = 2, note = "Hellcaller AoE spender. Diabolist: 8+ targets" },
        { spellId = 152108, aoe = 2, note = "M+: first on every pack, then on cooldown" },
        { spellId = 1122,   st = 3, aoe = 3, note = "Main cooldown" },
        { spellId = 442726, st = 3, aoe = 3, note = "Hellcaller: on cooldown, don't hold it" },
    },
})
