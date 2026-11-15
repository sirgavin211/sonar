# Graphics to draw (Andrew)

Perspective: **top-down / bird's-eye**. Everything is a rectangle placeholder in code right now (`Placeholder.box` calls). Size listed = current placeholder size in px, so art drops in at the right scale.

## Characters
- [ ] **Player**: detailed circle, 28x28. Facing doesn't matter, the gun rotates separately.
- [ ] **Sonar gun**: 24x8, points right (angle 0). Sits on the player and rotates to the mouse.
- [ ] **Listener** (enemy): 26x26. Creepy, all ears.
- [ ] **Boss**: 80x80, big Listener.

## Sonar
- [ ] **Sonar wave**: 18x6, points right. It rotates to its travel direction.
- [ ] **Echo glow**: optional custom light texture (currently a soft white circle).

## World
- [ ] **Ground tile**: dark dirt, tileable.
- [ ] **Mountain block**: 100x100, tileable, lines the map edge.
- [ ] **Rocks**: a few variants, 40-120 px.

## Items (ground + backpack icon)
- [ ] **Food**: 20x20
- [ ] **Fuel**: 20x20 (sun debris / burning chunk)
- [ ] **Shard**: 20x20 (artificial sun fragment, should feel special)

## Camp: metal facility (Subnautica-habitat vibe)
- [ ] **Metal floor**: 480x320 interior
- [ ] **Metal walls**: 16 px thick, plus the door gap on the bottom side
- [ ] **Chest**: closed + open, 44x30
- [ ] **Sun Core** station: 60x60. States: cold/unlit, partly fueled, fully lit. It grows with shards.
- [ ] **Artificial sun** rising: for the ending, when it flies up into the sky

## UI
- [ ] Backpack/chest slot frame (64x64)
- [ ] Health bar, sun fuel bar
- [ ] Roll screen (slot-machine look) for the ability + playtime rolls
- [ ] Win screen ("The sun rises") and lose screen ("You froze")
