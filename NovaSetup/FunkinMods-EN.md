# Funkin Directory and Engine Entry Explanation

This document explains where the `Funkin` runtime directory for NovaFlare Engine should be placed, how to organize resources and mods for OriginFunkin and CodeName Engine, and how to switch to the corresponding engine from NovaFlare Engine.

## Where to Put the Funkin Directory
```text
assets/
manifest/
mods/
replays/
Funkin/ <---here
```

Do **not** place the `Funkin` directory inside NovaFlare's own `assets`, `mods`, or any other subdirectory.

## Full Directory Structure

```text
Funkin/
├─ chain.json
│
├─ OriginFunkin/
│  ├─ assets/
│  │  ├─ fonts/
│  │  ├─ preload/
│  │  ├─ shared/
│  │  ├─ songs/
│  │  ├─ sserafim/
│  │  ├─ tutorial/
│  │  ├─ videos/
│  │  ├─ week1/
│  │  ├─ week2/
│  │  ├─ week3/
│  │  ├─ week4/
│  │  ├─ week5/
│  │  ├─ week6/
│  │  ├─ week7/
│  │  └─ weekend1/
│  │
│  └─ mods-vslice/
│
└─ CodeName/
   ├─ assets/
   │  ├─ data/
   │  ├─ fonts/
   │  ├─ images/
   │  ├─ languages/
   │  ├─ music/
   │  ├─ shaders/
   │  ├─ songs/
   │  ├─ sounds/
   │  └─ videos/
   │
   ├─ addons/
   └─ mods-codename/
```

CodeName Engine may automatically create a `.temp` directory at runtime; this is a normal temporary directory and does not need to be prepared manually.

## Resources and Mod Locations

### OriginFunkin

- Place official FNF 0.8.4 resources into `Funkin/OriginFunkin/assets/`.
- Place V-Slice mods into `Funkin/OriginFunkin/mods-vslice/`.
- `assets` and `mods-vslice` must be at the same directory level.
- Do **not** place `mods-vslice` inside `assets`.

### CodeName Engine

- Place official CodeName Engine resources into `Funkin/CodeName/assets/`.
- Place CodeName mods into `Funkin/CodeName/mods-codename/`.
- `assets` and `mods-codename` must be at the same directory level.

### NovaFlare Engine's Own Content

`Funkin` is only for storing external engine content. NovaFlare Engine's own resources and mods continue to use the directories next to the executable:

```text
assets/
mods/
```

Do **not** move NovaFlare's `assets` or `mods` into `Funkin`.

## In-Game Entry

From within NovaFlare Engine, navigate in order:

```text
Settings
└─ User Interface
   └─ SelectGameSubState (Engine Selection)
```

When the engine selection screen opens:

1. Select `Origin Funkin` or `CodeName Engine`.
2. On PC, press the confirm key to enter; on mobile, tap the currently displayed engine introduction image.
3. NovaFlare Engine will save your selection and exit.
4. Launch `NovaFlare Engine` again, and the program will boot into the selected engine.

**CodeName Engine is available only in the PC version; the mobile version can only enter OriginFunkin or continue using NovaFlare Engine.**

## Launch Configuration Entry

The current launch target is recorded in:

```text
Funkin/chain.json
```

The `preferredMode` field supports the following values:

| Value | Launch Target |
| --- | --- |
| `novaflare` | NovaFlare Engine |
| `origin` | OriginFunkin |
| `codename` | CodeName Engine (PC only) |
| `auto` | Attempts OriginFunkin first; falls back to NovaFlare Engine if resources are unavailable |

It is recommended to change this via the in-game engine selection interface. Do **not** manually edit `chain.json` while the program is running.

## Common Mistakes

- Incorrect: `Funkin/OriginFunkin/preload/`

  Correct: `Funkin/OriginFunkin/assets/preload/`

- Incorrect: `Funkin/OriginFunkin/assets/mods-vslice/`

  Correct: `Funkin/OriginFunkin/mods-vslice/`

- Incorrect: `Funkin/CodeName/assets/mods-codename/`

  Correct: `Funkin/CodeName/mods-codename/`

- Incorrect: Mixing OriginFunkin and CodeName resources in the same `assets` folder.

  Correct: Each engine uses its own separate `assets` folder.
