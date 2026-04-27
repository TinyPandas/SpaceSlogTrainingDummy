# SpaceSlog Training Dummy

A mod for [SpaceSlog](https://store.steampowered.com/app/2133570/SpaceSlog/) that adds a buildable training dummy. Crew members will use it during their entertainment time to practice combat skills.

## Requirements

This mod uses GDScript for custom AI behaviors. It requires the **SpaceSlogModLoader** to be installed first.

- [SpaceSlogModLoader](https://github.com/TinyPandas/SpaceSlogModLoader) — follow its installation instructions before installing this mod.

## Features

- **Buildable training dummy** — appears in the Entertainment build menu, costs 16 Titanium
- **Melee training** — unarmed or melee-weapon pawns lunge at the dummy, gaining Melee XP
- **Ranged training** — pawns with a ranged weapon equipped will fire at the dummy, gaining Ranged XP
- **Mood boost** — pawns gain the "Had Fun" thought after each training session
- **AI-driven** — pawns autonomously choose to train during their Entertainment schedule, no micromanagement needed

## Balance

- ~0.6 XP per training session (roughly 1 in-game hour)
- At 2 sessions per day, expect ~40 days to gain a skill level
- Training competes with other entertainment options for schedule time
- Safe skill progression that supplements but doesn't replace real combat experience

## Installation

### Prerequisites

Install the [SpaceSlogModLoader](https://github.com/TinyPandas/SpaceSlogModLoader) first.

### Install the mod

Copy the `Modules/TrainingDummy/` folder into your SpaceSlog `Modules/` directory:

```
<SpaceSlog Install>/Modules/TrainingDummy/
```

Then launch the game, go to the Mods menu, and enable **Training Dummy**.

### Finding your install directory

- **Steam**: Right-click SpaceSlog → Manage → Browse Local Files
- Typically: `C:\Program Files (x86)\Steam\steamapps\common\SpaceSlog\`

## How it works

The mod has two layers:

```
Modules/TrainingDummy/
├── Mod_Info.json                         ← mod metadata + script declarations
├── training_dummy_mod.gd                 ← entry script (extends SpaceslogMod)
├── Buildables/Entertainment.json         ← building definition (data layer)
├── Scripts/
│   ├── TaskTrainAtDummy.gd               ← training task (melee + ranged)
│   └── HasTrainingDummy.gd               ← AI consideration
└── Textures/
    ├── ModImage.png
    └── TrainingDummy/                    ← directional sprites
```

**Data layer** — loaded by the game's built-in mod system:
- `Buildables/Entertainment.json` — defines the training dummy building
- `Textures/` — sprite assets

**Script layer** — loaded by the ModLoader:
- `training_dummy_mod.gd` — entry script that registers tasks, task drivers, considerations, pawn options, and patches the Human reasoner via the ModdingAPI
- `Scripts/TaskTrainAtDummy.gd` — the training task. Extends `TaskCombat` for lunge animations. Detects equipped weapon type to branch between melee and ranged training.
- `Scripts/HasTrainingDummy.gd` — AI consideration that finds available training dummies on the facility.

The `Mod_Info.json` declares the `entry_script` and `scripts` array, which tells the ModLoader what to compile and register at `res://` paths automatically. No manual `override.cfg` editing required.

## Compatibility

- Built for SpaceSlog **v0.12.0.5**
- Requires [SpaceSlogModLoader](https://github.com/TinyPandas/SpaceSlogModLoader) v1.0+

## License

MIT — see [LICENSE](LICENSE).
