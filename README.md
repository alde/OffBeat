<p align="center">
  <img src="media/icon.svg" width="96" alt="OffBeat"/>
</p>

<h1 align="center">OffBeat</h1>

<p align="center">Buff and rotation tracker for World of Warcraft with shareable, data-driven profiles.</p>

---

## What it does

OffBeat is a single addon framework that tracks buffs on party members **or** your own rotation accuracy - depending on the profile loaded for your spec. Profiles are pure data: no code, just spell IDs and rules. Import and export them like WeakAura strings. It's meant to codify the guide from [method.gg](https://method.gg).

**Buff tracking** (e.g. Augmentation Evoker): countdown bars for party buffs, uptime percentages, Gantt-chart timeline, cast warnings.

**Rotation tracking** (e.g. Windwalker Monk, Frost DK, Ret Paladin): ability history strip, mistake detection, key cooldown alerts, proc tracking, cast log with export.

A profile can use both at once.

## Included profiles

| Addon | Spec | Type |
|-------|------|------|
| OffBeat_Evoker | Augmentation Evoker | Buff tracking |
| OffBeat_Monk | Windwalker Monk | Rotation (Combo Strikes) |
| OffBeat_DeathKnight | Blood Death Knight | Rotation (Bone Shield, DRW, Crimson Scourge, Boiling Point), Key Layout |
| OffBeat_DeathKnight | Frost Death Knight | Rotation (KM waste, Rime), Key Layout |
| OffBeat_DeathKnight | Unholy Death Knight | Rotation (Dark Transformation, Sudden Doom), Key Layout |
| OffBeat_Paladin | Retribution Paladin | Rotation (Art of War, Empyrean Power) |
| OffBeat_DemonHunter | Havoc, Vengeance, Devourer | Rotation & Tank Cooldowns |
| OffBeat_Shaman | Elemental, Enhancement | Rotation & Maelstrom Spenders |
| OffBeat_Warlock | Affliction, Demonology, Destruction | Rotation, Pet Spenders & Demonic Art / Fiendish Cruelty procs, Key Layout |
| OffBeat_Mage | Arcane | Rotation & Burn Phases |
| OffBeat_Priest | Discipline, Holy | Key Layout, Surge of Light, healer cooldowns |

## Stat priority

The stat priority panel has moved to its own addon, **[Statisfaction](https://github.com/alde/statisfaction)**. OffBeat profiles can still set `statPriority` / `heroStatPriorities`; when Statisfaction is installed it uses them over its built-in table.

## Installation

Install **OffBeat** (the core) plus whichever `OffBeat_<Class>` addons you need. Each class addon must be its own folder in `Interface/AddOns/` - the CurseForge packager handles this automatically via `move-folders`.

**From source** (development): clone the repo into your AddOns directory, then symlink the satellites so WoW can find them:

```bash
cd Interface/AddOns/OffBeat
./dev_install.sh        # macOS/Linux
.\dev_install.ps1       # Windows (creates junctions)
```

## Commands

| Command | Action |
|---------|--------|
| `/ob` | Open settings |
| `/ob show` | Toggle display panel |
| `/ob timeline` | Toggle timeline |
| `/ob lock` | Lock/unlock frames |
| `/ob profile <name>` | Switch profile |
| `/ob test` | Inject test data |


## Creating a profile

A profile is a Lua table registered with `OffBeat:RegisterProfile({...})`. Create a new `OffBeat_<Class>` addon with a `.toc` that depends on OffBeat, and a single `.lua` file:

```lua
local OffBeat = _G.OffBeat

OffBeat:RegisterProfile({
    meta = {
        name = "My Spec",
        specId = 123,       -- WoW specialization ID
        version = 1,
        author = "You",
    },

    -- Pick the sections you need:

    -- Buff tracking (party buffs)
    trackedBuffs = { { spellId = 12345, name = "Buff", color = {1,1,1}, category = "primary", baseDuration = 10 } },
    alerts = { { type = "missing_buff", spellId = 12345, name = "Buff" } },
    castWarnings = { { castNames = {"Spell"}, requireBuff = 12345, buffName = "Buff" } },

    -- Rotation tracking (personal casts)
    rotationSpells = { { spellId = 11111 }, { spellId = 22222 } },
    mistakes = { { type = "repeat_cast", name = "Mastery Break" } },
    trackedAuras = { { spellId = 99999, name = "Proc", baseDuration = 15 } },
    keyCooldown = { spellId = 99999, name = "Big CD", duration = 20 },
    idleCooldowns = { { spellId = 55555, name = "Cooldown" } },
    procTracking = { { procAura = 99999, consumeSpells = { 11111 }, window = 0.5, name = "Proc" } },

    -- Key Layout page: tier per context, 1 = core, 2 = regular, 3 = cooldown, nil = unused
    keyLayout = { { spellId = 11111, st = 1, aoe = 2, note = "Filler", alt = { 11112 } } },
    keyLayoutLabels = { st = "ST", aoe = "AoE", stLong = "Single Target", aoeLong = "AoE" }, -- optional
})
```

Profiles can be exported as `!OB1!` strings from the settings panel and shared in chat or on the web.

## Key Layout

Profiles with a `keyLayout` section get a **Key Layout** page in settings (`/ob`). It lists the guide's rotation spells grouped by how often you press them (core, regular, cooldown), marks whether each is used in single target, AoE or both, and shows your current keybind so you can see what's on a bad key: red means a core or regular spell is unbound, amber means a core spell sits behind a modifier. Spells you haven't talented are hidden by default, and hero-tree replacements (Immolate -> Wither) collapse into one row. `alt` lists fallback IDs for spells that have changed ID.

`keyLayoutLabels` renames the two contexts, e.g. `{ st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" }` for a healer; without it they're ST / AoE.

Currently filled in for all Warlock and Death Knight specs, and Discipline and Holy Priest.

## Mistake types

| Type | Rule | Example |
|------|------|---------|
| `repeat_cast` | Same spell cast twice in a row | Windwalker mastery break |
| `bad_cast` | One of `spells` cast while every condition in `when` holds | Frost Strike at 2 Killing Machine, Heart Strike at 75+ Runic Power |

`when` is one condition or a list of them (all must hold). Three kinds:

```lua
{ aura = 264173, minStacks = 4 }              -- aura up, optional stack range; absent = true for "not up"
{ power = "RunicPower", min = 75 }            -- Enum.PowerType name or number, min and/or max
{ combat = true }                             -- in or out of combat
```

Conditions are judged when the cast is sent, so costs and consumed procs don't skew the result, and only casts that succeed are counted. A value the game won't reveal (secret) never matches, so it can hide a mistake but never invent one.

## License

MIT
