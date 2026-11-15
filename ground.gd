@tool
class_name Ground
extends Node2D
# Floor drawn from (0, 0) to size.
# With tiles: Perlin-noise terrain (low = bare stone, middle = sparse/patchy moss,
# high = dense moss), baked once into a single texture so it's one draw call, not
# thousands. A stone pad is pushed into the noise around stone_center (the camp).
# Without tiles: flat color plus grid (camp's metal plates).

@export var size := Vector2(4000, 4000):
	set(value):
		size = value
		rebake()
@export var color := Color(0.33, 0.4, 0.28):
	set(value):
		color = value
		queue_redraw()
@export var line_color := Color(0.29, 0.35, 0.24):
	set(value):
		line_color = value
		queue_redraw()
@export var cell := 48.0:
	set(value):
		cell = maxf(value, 4.0)
		rebake()

@export_group("Terrain")
@export var tiles: Array[Texture2D] = []:  # ordered bare stone -> dense moss
	set(value):
		tiles = value
		rebake()
@export var levels: Array[float] = [-0.12, 0.0, 0.12]:  # noise cutoffs between the tiles
	set(value):
		levels = value
		rebake()
@export var patch_size := 10.0:  # cells across one moss patch; bigger = broader patches
	set(value):
		patch_size = maxf(value, 1.0)
		rebake()
@export var noise_seed := 0:
	set(value):
		noise_seed = value
		rebake()
@export var stone_center := Vector2(2000, 2000):  # forced low (stone) around here
	set(value):
		stone_center = value
		rebake()
@export var stone_radius := 450.0:
	set(value):
		stone_radius = value
		rebake()

var baked: ImageTexture


func rebake() -> void:
	baked = null
	queue_redraw()


func _draw() -> void:
	if tiles.is_empty():
		draw_grid()
		return
	if baked == null:
		baked = bake()
	var cells := Vector2(ceili(size.x / cell), ceili(size.y / cell))
	draw_texture_rect(baked, Rect2(Vector2.ZERO, cells * cell), false)


# One image, 1 tile pixel per art pixel; drawn scaled up to cell size.
func bake() -> ImageTexture:
	var variants := tile_variants()
	var tile_px := tiles[0].get_width()
	var cols := ceili(size.x / cell)
	var rows := ceili(size.y / cell)
	var image := Image.create(cols * tile_px, rows * tile_px, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = noise_seed
	noise.frequency = 1.0 / patch_size
	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed
	var tile_rect := Rect2i(0, 0, tile_px, tile_px)
	for gx in cols:
		for gy in rows:
			var height := noise.get_noise_2d(gx, gy) - stone_push(Vector2(gx + 0.5, gy + 0.5) * cell)
			var options: Array = variants[tile_for(height)]
			image.blit_rect(options[rng.randi() % options.size()], tile_rect, Vector2i(gx, gy) * tile_px)
	return ImageTexture.create_from_image(image)


# How far below the stone cutoff to push this spot: full strength inside the
# radius, fading out to nothing at 1.5x the radius.
func stone_push(at: Vector2) -> float:
	return 2.0 * smoothstep(stone_radius * 1.5, stone_radius, at.distance_to(stone_center))


func tile_for(height: float) -> int:
	var index := 0
	for level in levels:
		if height > level:
			index += 1
	return mini(index, tiles.size() - 1)


# Each tile in 4 rotations x mirrored, so the same 16px tile doesn't visibly repeat.
func tile_variants() -> Array:
	var all := []
	for texture in tiles:
		var options := []
		var image := texture.get_image()
		image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		for turn in 4:
			options.append(image.duplicate())
			var mirrored := image.duplicate()
			mirrored.flip_x()
			options.append(mirrored)
			image.rotate_90(CLOCKWISE)
		all.append(options)
	return all


func draw_grid() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, 2.0)
		x += cell
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 2.0)
		y += cell
