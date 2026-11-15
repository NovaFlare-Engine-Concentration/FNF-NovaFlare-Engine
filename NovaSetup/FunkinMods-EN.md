# Funkin Directory and Engine Entry Explanation

This document explains where the `Funkin` runtime directory for NovaFlare Engine should be placed, how to organize resources and mods for OriginFunkin and CodeName Engine, and how to switch to the corresponding engine from NovaFlare Engine.

## Where to Put the Funkin Directory

On Windows, place `Funkin` next to `NovaFlare Engine.exe`. For this project's normal Windows build, the runtime directory is `export/release/windows/bin/`:

```text
NovaFlare Engine.exe
assets/
manifest/
mods/
replays/
Funkin/ <---here
```

Do **not** place the `Funkin` directory inside NovaFlare's own `assets`, `mods`, or any other subdirectory.

Both Origin and CNE require users to download and place their full resource packs externally. These packs are not bundled with the engine, and this guide does not download them automatically.

## Full Directory Structure

```text
Funkin/
├─ chain.json
│
├─ OriginFunkin/
│  ├─ assets/
│  │  ├─ gameplay/           # Songs, characters, stages and gameplay assets
│  │  ├─ ui/                 # Menus, fonts and interface assets
│  │  ├─ exclude/            # Editor layouts, styles and supporting assets
│  │  └─ LICENSE.md
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

- Place the official resources for this project's imported Origin runtime baseline into `Funkin/OriginFunkin/assets/`. This pinned baseline is not necessarily the latest upstream public preview.
- Place V-Slice mods into `Funkin/OriginFunkin/mods-vslice/`.
- `assets` and `mods-vslice` must be at the same directory level.
- Do **not** place `mods-vslice` inside `assets`.
- The matching asset revision is `0b28106619ecf017af57c54dfde8653350b66128`.
- [Funkin Assets resource page](https://github.com/FunkinCrew/funkin.assets/tree/0b28106619ecf017af57c54dfde8653350b66128)
- [Direct resource ZIP download](https://github.com/FunkinCrew/funkin.assets/archive/0b28106619ecf017af57c54dfde8653350b66128.zip)

The current source includes compatibility work for historical Origin mods and selected 0.9 preview APIs. Support varies by mod and feature; the latest changes have not received a complete native build or game-wide validation. See the [compatibility evidence and outstanding checks](../docs/origin-mod-compatibility.md).

Extraction steps:

1. Extract the ZIP and open its outer `funkin.assets-0b28106619ecf017af57c54dfde8653350b66128` folder.
2. Place the `gameplay`, `ui` and `exclude` directories, along with `LICENSE.md` and the other documentation files, directly inside `Funkin/OriginFunkin/assets/`. Do not keep the ZIP's outer directory or add another `assets` level.
3. When upgrading, move the old `fonts`, `preload`, `shared`, `songs`, `week*` and other legacy directories out of `assets` and back them up first. Keep the new pack separate from the old layout. The sibling `mods-vslice` directory does not need to be replaced.
4. Keep `exclude`: it contains editor layouts and styles. Installing the resource pack does not enable the editors by itself.

The directory currently selected for this checkout is:

```text
D:\game\FNF-NovaFlare-Engine\export\release\windows\bin\Funkin\OriginFunkin\assets\
```

These paths should be directly accessible after extraction:

```text
assets/gameplay/songs/tutorial/tutorial-metadata.json
assets/gameplay/songs/tutorial/Inst.ogg
assets/ui/fonts/
assets/ui/title/logo-bumpin.png
assets/exclude/ui/editors/
```

The Origin source archive, `Funkin-miniaudio-public-playtest.zip`, does not replace the resource ZIP. Extract V-Slice mods separately into `mods-vslice/<mod-name>/`, preserving each mod's structure. Do not overwrite the base `assets` directory with mod files.

#### Additional Resources for Old Character Skins

Some old mods replace only a PNG, while current stock characters use Animate atlases. These mods also need the original XML and animation definitions. Run this from the project root:

```powershell
./tools/setup-origin-legacy-assets.ps1 -AssetsRoot 'D:/game/FNF-NovaFlare-Engine/export/release/windows/bin/Funkin/OriginFunkin/assets'
```

The script downloads resources from pinned official assets commits into the external `assets/compatibility/origin-v0.3.2/` folder and records their sources and SHA256 hashes. It covers 12 character profiles: BF, Dad, GF, Pico, Tankman and their car/Christmas variants, plus the five `win0`–`win4` light images for each of the old Philly normal and Erect stages and the Sparrow atlas used by historical Nene scripts/data. The Nene atlas preserves the modern stock character profile. This does not establish compatibility with every historical mod. Users can install this `compatibility` folder separately; it remains outside the engine package. Keep the current base resource pack described above and install mods in the sibling `mods-vslice` directory.

At runtime, a mod's images select the historical profile. Authored character JSON/scripts take precedence, and a later modern atlas can restore current character data. Re-running the installer preserves locally modified profile files by stopping before overwriting them. Run it again after updating the base pack to refresh the adapted stock character scripts.
  
### CodeName Engine

- Place official CodeName Engine resources into `Funkin/CodeName/assets/`.
- Place CodeName mods into `Funkin/CodeName/mods-codename/`.
- `assets` and `mods-codename` must be at the same directory level.
- [Matching CodeName Engine upstream snapshot](https://github.com/CodenameCrew/CodenameEngine/tree/2289c833aa4d9a6a7f9f98a49fe994101ab75c16)
- [Direct ZIP download](https://github.com/CodenameCrew/CodenameEngine/archive/2289c833aa4d9a6a7f9f98a49fe994101ab75c16.zip). Place only the contents of its `assets` directory inside `Funkin/CodeName/assets/`. Do not copy the entire source archive or create `assets/assets/`.

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

**CodeName Engine is available on both PC and mobile. Mobile builds use NovaFlare's touch controls.**

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
| `codename` | CodeName Engine |
| `auto` | Attempts OriginFunkin first; falls back to NovaFlare Engine if resources are unavailable |

It is recommended to change this via the in-game engine selection interface. Do **not** manually edit `chain.json` while the program is running.

## Origin Editors and Testing

Windows desktop builds enable the chart, stage, camera and animation editors, plus results testing. Press the grave accent key (usually shared with `~`) in the Origin main menu to open the test menu. Press `F2` for the Flixel debugger. Runtime logs are written to `logs/` beside the executable.

Build with `lime test windows`. Editor layouts default to `export/release/windows/bin/Funkin/OriginFunkin/assets`, with both upstream `ui/editors/` and `exclude/ui/editors/` directories preserved. If your compile-time assets are elsewhere, use `lime test windows -DORIGIN_ASSETS_PATH=C:/path/to/assets`. Runtime assets still need to be installed in the external folder described above.

Before building from source, run `./tools/setup-hxcpp-callback-handoff.ps1` from the repository root to install the verified hxcpp native callback-thread handoff fix, then repeat with `-VerifyOnly`. The script backs up the original and rejects unknown runtime sources. Check again after reinstalling hxcpp. Players running a release package do not need this development step.

For a separate Tracy profiling build, also run `./tools/setup-hxcpp-tracy-on-demand.ps1`, verify it with `-VerifyOnly`, and rebuild. Switching between regular and Tracy builds requires a full native object rebuild; see `docs/upstream-migration.md`. Keep the output directory and its external assets intact.

To compile before installing the full resource pack, run `./tools/setup-origin-editor-layouts.ps1`, then `lime build windows -DORIGIN_ASSETS_PATH=D:/path/to/repository/_build/origin-editor-build-assets`. This development script downloads and verifies only 95 editor XML/CSS files from the pinned commit for the build macros. Running the game still requires the complete external resource pack described above.

After compiling and closing that game instance, launch a test from the runtime folder:

```powershell
Set-Location export/release/windows/bin
& '.\NovaFlare Engine.exe' '--origin-test=chart'
```

Replace `chart` with `menu` (debug menu), `main`, `mods` (Mod Menu), `camera`, `stage`, `animation`, `results` (results settings), `result-screen` (default results screen), `play` (Bopeebo with practice and bot play), or `input` (main menu with keyboard diagnostics). The `play` target does not record scores. With debug functions enabled, an explicit test argument selects Origin for this process without changing the startup preference in `chain.json`. Use `attract` for the real title video, or `native-video` for the longer video/audio/disposal regression; require its final `CHECKS PASSED` log. Close the game before rebuilding so Windows can replace its DLLs.

## Common Mistakes

- Incorrect: `Funkin/OriginFunkin/gameplay/`

  Correct: `Funkin/OriginFunkin/assets/gameplay/`

- Incorrect: `Funkin/OriginFunkin/assets/funkin.assets-0b28106619ecf017af57c54dfde8653350b66128/gameplay/` or `assets/assets/gameplay/`.

  Correct: `Funkin/OriginFunkin/assets/gameplay/`, with `ui` and `exclude` alongside `gameplay`.

- Incorrect: `Funkin/OriginFunkin/assets/mods-vslice/`

  Correct: `Funkin/OriginFunkin/mods-vslice/`

- Incorrect: `Funkin/CodeName/assets/mods-codename/`

  Correct: `Funkin/CodeName/mods-codename/`

- Incorrect: Mixing OriginFunkin and CodeName resources in the same `assets` folder.

  Correct: Each engine uses its own separate `assets` folder.

> Compiled-mod support is experimental: ordinary Windows builds do not enable CPPIA automatically. The separate `Project-OriginCPPIA.xml` build requires adapted hxcpp and Polymod dependencies. Only limited mod loading and startup have been checked; compatibility with all 0.9 mods or modcharts is not guaranteed.

Before an experimental CPPIA build, developers can run `tools/check-origin-cppia-dependencies.ps1 -PolymodRoot <Polymod directory> -HxcppRoot <hxcpp directory>`. This read-only check compares the locally validated patch-stack fingerprints; it does not install or overwrite dependencies. Other versions or additional changes will be reported, which does not by itself mean they are damaged. Installers expect exact preceding layers, and an earlier layer's standalone Verify may not apply after later patches. Roll back in reverse order and retain each backup. A complete clean reinstall of the stack has not yet been verified end to end.

For an experimental Windows CPPIA build, run `./tools/build-origin-cppia-windows.ps1`; add `-CheckOnly` to check the selected dependency stack without building. The script uses `Project-OriginCPPIA.xml`, the normal Windows output directory, one compilation thread, and stops its build process tree below 200 MiB of available physical memory. `-CheckOnly` and the full build have been checked on the current Windows environment; the low-memory stop path has not been separately verified.
