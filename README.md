# SpaceSlog Training Dummy

A mod for [SpaceSlog](https://store.steampowered.com/app/2133570/SpaceSlog/) that adds a buildable training dummy. Crew members will use it during their entertainment time to practice combat skills.

## Features

- **Buildable training dummy** — appears in the Entertainment build menu, costs 16 Titanium
- **Melee training** — unarmed or melee-weapon pawns lunge at the dummy, gaining Melee XP
- **Ranged training** — pawns with a ranged weapon equipped will fire at the dummy, gaining Ranged XP
- **Mood boost** — pawns gain the "Had Fun" thought after each training session
- **AI-driven** — pawns autonomously choose to train during their Entertainment schedule, no micromanagement needed

## Balance

- ~0.6 XP per training session (roughly 1 in-game hour)
- At 2 sessions per day, expect ~40 days to gain a skill level
- Training competes with other entertainment options (arcade machines, etc.) for schedule time
- Safe skill progression that supplements but doesn't replace real combat experience

## Installation

### Step 1: Install the mod data

Copy the `Modules/TrainingDummy/` folder into your SpaceSlog `Modules/` directory:

```
<SpaceSlog Install>/Modules/TrainingDummy/
```

Then enable the mod in the game's mod menu.

### Step 2: Enable the script loader

This mod requires custom GDScript to add AI behaviors that the base game's data-only mod system doesn't support. You need to add one line to `override.cfg` in your SpaceSlog install directory.

If `override.cfg` doesn't exist, create it. Add or append:

```ini
[autoload]

TrainingDummyMod="*res://Modules/TrainingDummy/training_dummy_mod.gd"
```

If you already have an `[autoload]` section from another mod, just add the `TrainingDummyMod=...` line under it.

### Finding your install directory

- **Steam**: Right-click SpaceSlog → Manage → Browse Local Files
- Typically: `C:\Program Files (x86)\Steam\steamapps\common\SpaceSlog\`

## How it works

The mod has two layers:

```
SpaceSlogTrainingDummy/
├── override.cfg                          ← players add to game root
├── README.md
├── LICENSE                               ← MIT
└── Modules/TrainingDummy/                ← players copy to Modules/
    ├── Mod_Info.json
    ├── training_dummy_mod.gd             ← autoload (script loader + data patcher)
    ├── Buildables/Entertainment.json     ← building definition
    ├── Scripts/
    │   ├── TaskTrainAtDummy.gd           ← training task (melee + ranged)
    │   └── HasTrainingDummy.gd           ← AI consideration
    └── Textures/
        ├── ModImage.png
        └── TrainingDummy/                ← directional sprites
```

**Data layer** — loaded by the game's built-in mod system:
- `Buildables/Entertainment.json` — defines the training dummy building
- `Textures/` — sprite assets
- `Mod_Info.json` — mod metadata

**Script layer** — loaded via `override.cfg`, extends the game's AI:
- `training_dummy_mod.gd` — autoload that patches the game's Data dictionaries at startup, registering a custom Task, TaskDriver, Consideration, and PawnOption. Uses `GDScript.source_code` + `take_over_path()` to make scripts available to the engine's Maker system.
- `Scripts/TaskTrainAtDummy.gd` — the training task. Extends `TaskCombat` for lunge animations. Detects equipped weapon type to branch between melee and ranged training.
- `Scripts/HasTrainingDummy.gd` — AI consideration that finds available training dummies on the facility.

## Compatibility

- Built for SpaceSlog **v0.12.0.5**
- The `override.cfg` approach works alongside other mods that use the same mechanism — just ensure each mod has a unique autoload name

## License

MIT — see [LICENSE](LICENSE).
