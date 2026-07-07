<p align="center">
  <img src="media/icon.svg" width="96" alt="OffBeat"/>
</p>

<h1 align="center">OffBeat</h1>

<p align="center">Buff and rotation tracker for World of Warcraft with shareable, data-driven profiles.</p>

---

## What it does

OffBeat is a single addon framework that tracks buffs on party members **or** your own rotation accuracy — depending on the profile loaded for your spec. Profiles are pure data: no code, just spell IDs and rules. Import and export them like WeakAura strings.

**Buff tracking** (e.g. Augmentation Evoker): countdown bars for party buffs, uptime percentages, Gantt-chart timeline, cast warnings.

**Rotation tracking** (e.g. Windwalker Monk, Frost DK, Ret Paladin): ability history strip, mistake detection, key cooldown alerts, proc tracking, cast log with export.

A profile can use both at once.

## Included profiles

| Addon | Spec | Type |
|-------|------|------|
| OffBeat_Evoker | Augmentation Evoker | Buff tracking |
| OffBeat_Monk | Windwalker Monk | Rotation (Combo Strikes) |
| OffBeat_DeathKnight | Frost Death Knight | Rotation (KM waste, Rime) |
| OffBeat_Paladin | Retribution Paladin | Rotation (Art of War, Empyrean Power) |

## Installation

Install **OffBeat** (the core) plus whichever `OffBeat_<Class>` addons you need. Each class addon must be its own folder in `Interface/AddOns/` — the CurseForge packager handles this automatically via `move-folders`.

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
    procTracking = { { procAura = 99999, consumeSpell = 11111, window = 0.5, name = "Proc" } },
})
```

Profiles can be exported as `!OB1!` strings from the settings panel and shared in chat or on the web.

## Mistake types

| Type | Rule | Example |
|------|------|---------|
| `repeat_cast` | Same spell cast twice in a row | Windwalker mastery break |
| `proc_waste` | Wrong spell while a proc is active | Frost Strike during Killing Machine |

## License

MIT
