# Haven

Open `project.godot` in Godot. The entry scene is `scenes/main.tscn`.

## Where things live

- `scenes/`: game scenes, grouped into characters, world, effects, and UI.
- `scripts/`: matching gameplay scripts; inventory is under `systems/`.
- `assets/textures/`: characters, items, terrain, and nature props (by pixel size).
- `assets/audio/`: sound effects in `sfx/`, environment loops in `ambience/`.
- `assets/fonts/`: Pixelify Sans and its license.
- `assets/ui/`: project icon.
- `resources/`: shared themes and generated light textures.
- `docs/`: graphics and sound task lists.
- `tests/`: inventory checks and the gameplay smoke test.
- `assets/source/`: original audio/art retained for editing, excluded from Godot import.
- `docs/archive/`: old metadata and an empty legacy placeholder, excluded from Godot import.

Keep `.gd.uid` and `.import` companion files beside their script or asset. Godot manages them.
Use the Godot FileSystem dock for future moves so resource references stay synchronized.

## Checks

From this folder, substitute your Godot executable for `godot`:

```sh
godot --headless --editor --import
godot --headless --path . --script tests/test_inventory.gd
godot --headless --path . --script tests/smoke_game.gd
```

After the folder reorganization, open the project in the editor once to refresh resource imports before running it.
