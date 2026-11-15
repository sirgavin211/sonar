# SONAR

Open `project.godot` in Godot. The game starts at the title screen, `scenes/ui/main_menu.tscn`;
Play loads the game itself, `scenes/main.tscn`.

## Where things live

- `scenes/`: game scenes, grouped into characters, world, effects, and UI.
- `scripts/`: matching gameplay scripts; inventory is under `systems/`.
- `assets/textures/`: characters, items, terrain, and nature props (by pixel size).
- `assets/audio/`: sound effects in `sfx/`, environment loops in `ambience/`.
- `assets/fonts/`: Pixelify Sans and its license.
- `assets/ui/`: project icon.
- `resources/`: shared themes and generated light textures.
- `docs/`: graphics and sound task lists.
- `tests/`: inventory checks, the menu test, and the gameplay smoke test.
- `assets/source/`: original audio/art retained for editing, excluded from Godot import.
- `docs/archive/`: old metadata and an empty legacy placeholder, excluded from Godot import.

Keep `.gd.uid` and `.import` companion files beside their script or asset. Godot manages them.
Use the Godot FileSystem dock for future moves so resource references stay synchronized.

## Checks

From this folder, substitute your Godot executable for `godot`:

```sh
godot --headless --editor --import
godot --headless --path . --script tests/test_inventory.gd
godot --headless --path . --script tests/test_menu.gd
godot --headless --path . --script tests/smoke_game.gd
```

After the folder reorganization, open the project in the editor once to refresh resource imports before running it.

# Sonar

## What is Sonar?
- OHH NOO! The SUN has EXPLODED!!! Darkness has filled the world. FIND the 3 Scattered Shards across the map and rebuild The SUN. COLLECT food to survive and COLLECT FUEL to light up your base before the light is GONE FOREVER!!! Send sonar blasts to see in this world of DARKNESS
## Game Guide + Controls
- WASD: controls direction
- E: places shards / fuels 
- Left click: shoots sonar / eats food
- 1-5: Choose position of tool bar
- Tab: Small inventory
- Shift: Sprint
- R: Reset
- GAME GUIDE: Travel across the map shooting sonar rays to light up the path ahead of you. Keep in mind, to collect fuel and shard artifacts as you go. Sonar rays will be able to bounce off walls and light up surrounding areas even further! Remember to place fuel artifacts inside the hopper at your base so that your light wont vanish forever. If your ever low on health, make sure to eat some of the food you collected. However, BEWARE of the listeners that lurk the shadows of this new world. 3 shards is all it takes to bring back THE SUN.
## [Game Link]("insert here")
## Team and Cgit redits
- Gavin - Lead Programmer
- Andrew - Graphics Engineer, Sound Engineer
- Stanley - Graphics Engineer, Sound Engineer
