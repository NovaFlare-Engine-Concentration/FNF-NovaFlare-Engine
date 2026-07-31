# Origin Funkin 0.8.4 compatibility source

This source root is intentionally separate from NovaFlare's `source/` tree.

- `funkin/` is the Friday Night Funkin' 0.8.4 source snapshot.
- `animate/` is the 0.8.4 flixel-animate snapshot adapted to NF's Flixel API.
- `originfunkin/` is the small NovaFlare bootstrap and read-only asset bridge.
- Runtime assets are never committed. Players provide them in an
  `originFunkin` directory next to the executable.

Expected runtime layout:

```text
assets/
crash/
logs/
mods/
mods-vslice/
originFunkin/
  fonts/
  preload/
  shared/
  songs/
  tutorial/
  week1/
  ...
replays/
(Wait, would it look a bit messy if I arrange it like this)
```

When the directory is absent, NovaFlare follows its normal startup path.

[Friday Night Funkin](https://github.com/FunkinCrew/Funkin)
[Friday Night Funkin Assets](https://github.com/FunkinCrew/Funkin.assets/tree/d1d027d4747aaba151c6df121ea736c31d6aed38)
