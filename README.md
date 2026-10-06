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

**Key Layout**: a settings page that shows which spells deserve your best keys, for single target and AoE, next to your current keybinds.

**Training** (e.g. Demonology Warlock): coaching for your big cooldown windows, scored against goals and casts-per-minute benchmarks taken from top Warcraft Logs parses, with a report panel at the end of each session.

A profile can use any combination.

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
| OffBeat_Warlock | Affliction, Demonology, Destruction | Rotation, Pet Spenders & Demonic Art / Fiendish Cruelty procs, Key Layout; Training (Demonology) |
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
| `/ob training` | Toggle cooldown window coaching for this session |
| `/ob report` | Show the last training report |


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

    -- Training (see below)
    windows = { { name = "Big CD", trigger = 99999, duration = 20,
                  goals = { { name = "Spender", spells = { 22222 }, min = 6 } } } },
    benchmarks = { source = "top parses", rates = {
        { name = "Spender", spells = { 22222 }, low = 10, median = 11, high = 12 } } },
})
```

Profiles can be exported as `!OB1!` strings from the settings panel and shared in chat or on the web.

## Key Layout

Profiles with a `keyLayout` section get a **Key Layout** page in settings (`/ob`). It lists the guide's rotation spells grouped by how often you press them (core, regular, cooldown), marks whether each is used in single target, AoE or both, and shows your current keybind so you can see what's on a bad key: red means a core or regular spell is unbound, amber means a core spell sits behind a modifier. Spells you haven't talented are hidden by default, and hero-tree replacements (Immolate -> Wither) collapse into one row. `alt` lists fallback IDs for spells that have changed ID.

`keyLayoutLabels` renames the two contexts, e.g. `{ st = "Single", aoe = "Group", stLong = "Single Target", aoeLong = "Group Healing" }` for a healer; without it they're ST / AoE.

Currently filled in for all Warlock and Death Knight specs, and Discipline and Holy Priest.

## Training

Training coaches your big cooldown windows and compares your casting with top players. It's off by default and never saved: `/ob training` (or the toggle on the **Training** settings page) turns it on until you turn it off, reload or relog, so it can't follow you into a raid by accident.

How to use it:

1. Turn it on and fight a target dummy (or a boss).
2. When you press the window's cooldown, OffBeat checks your setup (for Demonology: 5 Soul Shards pooled) and a counter shows the casts that matter inside the window against a goal.
3. Each window ends with a scorecard in chat; each fight ends with a summary and your casts per minute against the profile's benchmarks.
4. Turn training off and a **report panel** sums up the session: one bar per window against its goal, and one bar per benchmark spell over the top players' middle half. `/ob report` reopens the last report.

Goals can be adjusted per spec on the Training page, so you can start with one you can reach and raise it as you improve.

Training also turns on combat logging for the session (setting on the Training page), so it can be uploaded to Warcraft Logs and compared afterwards. It only turns off a log it started itself, and warns if Advanced Combat Logging is off, which Warcraft Logs needs.

### Windows

Casting `trigger` opens a window for `duration` seconds. `setup` checks are judged when you press the trigger (same conditions as mistake rules); `goals` count casts inside the window. `note` is shown on the Training page.

```lua
windows = { {
    name = "Tyrant", trigger = 265187, duration = 25,
    note = "Pool shards and cores, then spend everything on Hand of Gul'dan.",
    setup = { { name = "5 Soul Shards", when = { power = "SoulShards", min = 5 } } },
    goals = { { name = "Hand of Gul'dan", spells = { 105174 }, min = 8 } },
} }
```

### Benchmarks

Casts per minute taken from top parses: `median` plus `low` / `high` for the middle half. `all = true` counts every `rotationSpells` cast. A fight reaches a benchmark when your rate is at least `low`.

```lua
benchmarks = {
    source = "top 100 heroic Ula'tek",
    rates = {
        { name = "Rotation casts",  all = true,           low = 40.5, median = 41.5, high = 42.7 },
        { name = "Hand of Gul'dan", spells = { 105174 },  low = 12.7, median = 13.1, high = 13.6 },
    },
}
```

Demonology's goals and benchmarks come from the top 93 heroic Ula'tek Demonology parses on Warcraft Logs (October 2026). They are boss-specific: on other fights treat the casts-per-minute comparison as a rough guide.

## Mistake types

| Type | Rule | Example |
|------|------|---------|
| `repeat_cast` | Same spell cast twice in a row | Windwalker mastery break |
| `bad_cast` | One of `spells` cast while every condition in `when` holds | Frost Strike at 2 Killing Machine, Heart Strike at 75+ Runic Power |

`when` is one condition or a list of them (all must hold). Four kinds:

```lua
{ aura = 264173, minStacks = 4 }              -- aura up, optional stack range; absent = true for "not up"
{ power = "RunicPower", min = 75 }            -- Enum.PowerType name or number, min and/or max
{ combat = true }                             -- in or out of combat
{ hardcast = true }                           -- the cast had a cast bar (not instant)
```

Conditions are judged when the cast is sent, so costs and consumed procs don't skew the result, and only casts that succeed are counted. A value the game won't reveal (secret) never matches, so it can hide a mistake but never invent one; that includes "aura not up" while the game hides auras. Prefer `hardcast` over "proc aura absent" for instant-on-proc spells: it doesn't depend on reading auras.

## License

MIT
