# Graphics to draw (Andrew)

Perspective: **top-down / bird's-eye**. Everything is a rectangle placeholder right now: a `ColorRect` named `Body` (or `Core`/`Barrel`) inside each object's `.tscn` scene. Swap it for a `Sprite2D` in the editor. Size listed = current placeholder size in px, so art drops in at the right scale.

## Characters
- [x] **Player**: detailed circle, 28x28. Facing doesn't matter, the gun rotates separately.
- [ ] **Sonar gun**: 24x8, points right (angle 0). Sits on the player and rotates to the mouse.
- [ ] **Listener** (enemy): 26x26. Creepy, all ears.
- [ ] **Boss**: 80x80, big Listener.

## Sonar
- [ ] **Sonar wave**: expanding arc (45° cone) with trailing ripples, drawn in code now. Optional: a ripple texture or a shader to replace it.
- [ ] **Echo return**: the smaller arc bouncing back to the player, tinted by the object (drawn in code now).
- [ ] **Echo glow**: optional custom light texture (currently a soft white circle).

## World
- [x] **Ground tile**: 4 tiles, bare rock to dense moss (`01`–`04`), 16x16 drawn 3x. Noise picks them so moss grows in patches.
- [ ] **Mountain block**: 100x100, tileable, lines the map edge.
- [x] **Nature props** (`nature/`): trees + stones are solid obstacles (replaced the grey rocks), bushes + small rocks are walk-over clutter. Drawn 3x.

## Items (ground + backpack icon)
- [ ] **Food**: 20x20
- [x] **Fuel**: `Fuel.png`, 20x19.
- [x] **Shard**: `shard.png`, 14x19 (cut out of `Pixie_Shard.webp`: grey background removed, shrunk 8x to its real pixel size). A transparent PNG at real size next time saves that step.

## Camp: metal facility (Subnautica-habitat vibe)
- [ ] **Metal floor**: 480x320 interior
- [ ] **Metal walls**: 16 px thick, plus the door gap on the bottom side
- [ ] **Sun Core** station: 60x60. States: cold/unlit, partly fueled, fully lit. It grows with shards.
- [ ] **Artificial sun** rising: for the ending, when it flies up into the sky

## UI
- [ ] Backpack slot frame (58x58)
- [ ] Health bar, stamina bar, sun fuel bar
- [ ] Roll screen (slot-machine look) for the ability + playtime rolls
- [ ] Win screen ("The sun rises") and lose screen ("You froze")
