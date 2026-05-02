extends "res://src/levels/LevelBase.gd"
## Dev-only isometric vertical slice: standalone TileMapLayers under WorldRoot (no TileMap parent).
## Tiles are painted at runtime from IsoCyberpunkVerticalSlice.tres — see docs/ISOMETRIC_LEVEL_SPEC.md.

const TILESET_PATH := "res://assets/tilesets/iso_vertical_slice/IsoCyberpunkVerticalSlice.tres"
const CYBER_ATLAS_PNG := "res://assets/tilesets/iso_vertical_slice/processed/cyberpunk_iso_atlas.png"

## Atlas coords — grid 6×2 @ 64×64 in cyberpunk_iso_atlas.png (see processed/cyberpunk_iso_atlas_source_map.md).
const SOURCE_ID := 0
const ATLAS_FLOOR_A := Vector2i(0, 0)
const ATLAS_FLOOR_B := Vector2i(1, 0)
const ATLAS_FLOOR_C := Vector2i(2, 0)
const ATLAS_WALL_A := Vector2i(3, 0)
const ATLAS_WALL_B := Vector2i(4, 0)
const ATLAS_DOOR := Vector2i(5, 0)
const ATLAS_PROP_VENT := Vector2i(0, 1)
const ATLAS_PROP_BOX := Vector2i(1, 1)
const ATLAS_PROP_METAL := Vector2i(2, 1)
const ATLAS_PROP_PILLS := Vector2i(3, 1)
const ATLAS_PROP_CABLE := Vector2i(4, 1)

const ROOM_HALF := 7


func _ready() -> void:
	mission_id = "iso_vertical_slice"
	objective_text = "Iso prototype: reach the exit zone."
	var exit_zone := get_node_or_null("ExitZone") as Area2D
	if exit_zone:
		# Avoid spurious body_entered during TileMapLayer boot / deferred paints.
		exit_zone.monitoring = false
	_configure_world_layers()
	_place_spawn_and_exit()
	super._ready()
	await get_tree().process_frame
	_paint_iso_room()
	if exit_zone:
		await get_tree().create_timer(0.35).timeout
		exit_zone.monitoring = true


func _configure_world_layers() -> void:
	var ts := _resolve_cyberpunk_tileset()
	var world := get_node_or_null("WorldRoot") as Node2D
	if world == null or ts == null:
		push_error("IsoVerticalSlice: missing WorldRoot or TileSet.")
		return
	for child in world.get_children():
		if child is TileMapLayer:
			var layer := child as TileMapLayer
			layer.tile_set = ts
			layer.collision_enabled = true


func _resolve_cyberpunk_tileset() -> TileSet:
	var ts := load(TILESET_PATH) as TileSet
	if ts != null and ts.get_source_count() > 0:
		var src_any := ts.get_source(SOURCE_ID)
		if src_any is TileSetAtlasSource:
			var src := src_any as TileSetAtlasSource
			if src.texture != null:
				return ts
	push_warning(
		"IsoVerticalSlice: IsoCyberpunkVerticalSlice texture missing (import cache). Building TileSet from PNG at runtime."
	)
	return _build_runtime_cyberpunk_tileset()


func _build_runtime_cyberpunk_tileset() -> TileSet:
	var img := Image.new()
	var abs_path := ProjectSettings.globalize_path(CYBER_ATLAS_PNG)
	if img.load(abs_path) != OK:
		push_error("IsoVerticalSlice: failed to load cyberpunk atlas image: " + abs_path)
		return null
	var tex := ImageTexture.create_from_image(img)
	var out := TileSet.new()
	out.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	# Match IsoCyberpunkVerticalSlice.tres (stored as 0 / 0)
	out.tile_layout = TileSet.TILE_LAYOUT_STACKED
	out.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	out.tile_size = Vector2i(64, 32)
	out.add_physics_layer()
	out.set_physics_layer_collision_layer(0, 4)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(64, 64)
	atlas.margins = Vector2i(0, 0)
	atlas.separation = Vector2i(0, 0)
	out.add_source(atlas, SOURCE_ID)
	for cx in range(6):
		atlas.create_tile(Vector2i(cx, 0))
	for cx in range(5):
		atlas.create_tile(Vector2i(cx, 1))
	_tile_collision_footprint(
		atlas,
		Vector2i(3, 0),
		PackedVector2Array([Vector2(12, 40), Vector2(52, 40), Vector2(52, 58), Vector2(12, 58)])
	)
	_tile_collision_footprint(
		atlas,
		Vector2i(4, 0),
		PackedVector2Array([Vector2(12, 40), Vector2(52, 40), Vector2(52, 58), Vector2(12, 58)])
	)
	_tile_collision_footprint(
		atlas,
		Vector2i(0, 1),
		PackedVector2Array([Vector2(22, 46), Vector2(42, 46), Vector2(42, 58), Vector2(22, 58)])
	)
	_tile_collision_footprint(
		atlas,
		Vector2i(1, 1),
		PackedVector2Array([Vector2(18, 44), Vector2(46, 44), Vector2(46, 58), Vector2(18, 58)])
	)
	_tile_collision_footprint(
		atlas,
		Vector2i(2, 1),
		PackedVector2Array([Vector2(20, 46), Vector2(44, 46), Vector2(44, 58), Vector2(20, 58)])
	)
	return out


func _tile_collision_footprint(atlas: TileSetAtlasSource, coords: Vector2i, pts: PackedVector2Array) -> void:
	var td := atlas.get_tile_data(coords, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, pts)


func _floor_atlas_for_cell(map_coords: Vector2i) -> Vector2i:
	var floors: Array[Vector2i] = [ATLAS_FLOOR_A, ATLAS_FLOOR_B, ATLAS_FLOOR_C]
	var i: int = abs(map_coords.x + map_coords.y * 3) % floors.size()
	return floors[i]


func _wall_atlas_for_cell(map_coords: Vector2i) -> Vector2i:
	return ATLAS_WALL_A if ((map_coords.x + map_coords.y) & 1) == 0 else ATLAS_WALL_B


func _paint_iso_room() -> void:
	var ground := $WorldRoot/GroundLayer as TileMapLayer
	var detail_layer := $WorldRoot/DetailLayer as TileMapLayer
	var walls := $WorldRoot/WallLayer as TileMapLayer
	var prop_layer := $WorldRoot/PropLayer as TileMapLayer
	if ground == null or detail_layer == null or walls == null or prop_layer == null:
		return
	for x in range(-ROOM_HALF, ROOM_HALF + 1):
		for y in range(-ROOM_HALF, ROOM_HALF + 1):
			ground.set_cell(Vector2i(x, y), SOURCE_ID, _floor_atlas_for_cell(Vector2i(x, y)))
	for x in range(-ROOM_HALF, ROOM_HALF + 1):
		var north := Vector2i(x, -ROOM_HALF)
		var south := Vector2i(x, ROOM_HALF)
		walls.set_cell(north, SOURCE_ID, _wall_atlas_for_cell(north))
		walls.set_cell(south, SOURCE_ID, _wall_atlas_for_cell(south))
	for y in range(-ROOM_HALF, ROOM_HALF + 1):
		var west := Vector2i(-ROOM_HALF, y)
		var east := Vector2i(ROOM_HALF, y)
		walls.set_cell(west, SOURCE_ID, _wall_atlas_for_cell(west))
		walls.set_cell(east, SOURCE_ID, _wall_atlas_for_cell(east))
	# Door + props on later frames: same-frame bulk paint + extra layers can skip cells on some Godot builds.
	call_deferred("_paint_iso_room_details")


func _paint_iso_room_details() -> void:
	var detail_layer := $WorldRoot/DetailLayer as TileMapLayer
	var prop_layer := $WorldRoot/PropLayer as TileMapLayer
	if detail_layer == null or prop_layer == null:
		return
	detail_layer.set_cell(Vector2i(ROOM_HALF - 2, 0), SOURCE_ID, ATLAS_DOOR)
	# PropLayer drops multi-cell same-frame updates on some builds; space paints across frames.
	var prop_cells: Array[Vector2i] = [
		Vector2i(-4, -4),
		Vector2i(3, -3),
		Vector2i(-3, 4),
		Vector2i(2, 3),
		Vector2i(-2, -2),
	]
	var prop_atlas: Array[Vector2i] = [
		ATLAS_PROP_VENT,
		ATLAS_PROP_BOX,
		ATLAS_PROP_METAL,
		ATLAS_PROP_PILLS,
		ATLAS_PROP_CABLE,
	]
	for i in prop_cells.size():
		prop_layer.set_cell(prop_cells[i], SOURCE_ID, prop_atlas[i])
		await get_tree().process_frame


func _place_spawn_and_exit() -> void:
	var ground := $WorldRoot/GroundLayer as TileMapLayer
	var spawn := get_node_or_null("PlayerSpawn") as Marker2D
	var exit_zone := get_node_or_null("ExitZone") as Area2D
	if ground == null:
		return
	# Spawn west, exit east — avoids accidental ExitZone overlap with player on boot (iso spacing is tight).
	var spawn_cell := Vector2i(-ROOM_HALF + 2, 0)
	var exit_cell := Vector2i(ROOM_HALF - 1, 0)
	var center_world := ground.to_global(ground.map_to_local(spawn_cell))
	var exit_world := ground.to_global(ground.map_to_local(exit_cell))
	if spawn:
		spawn.global_position = center_world
	if exit_zone:
		exit_zone.global_position = exit_world


func _spawn_player_if_needed() -> void:
	var entity_root := get_node_or_null("WorldRoot/EntityRoot") as Node2D
	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		var scene := preload("res://scenes/characters/player.tscn")
		player = scene.instantiate()
		if entity_root:
			entity_root.add_child(player)
		else:
			add_child(player)
	elif entity_root != null and player.get_parent() != entity_root:
		player.reparent(entity_root)
	var spawn := _get_spawn_point()
	if spawn and player:
		player.global_position = spawn.global_position


func _spawn_dog_if_needed() -> void:
	var entity_root := get_node_or_null("WorldRoot/EntityRoot") as Node2D
	dog = get_tree().get_first_node_in_group("bentley") as Node2D
	if dog == null:
		var scene := preload("res://scenes/characters/dog.tscn")
		dog = scene.instantiate()
		if entity_root:
			entity_root.add_child(dog)
		else:
			add_child(dog)
	elif entity_root != null and dog.get_parent() != entity_root:
		dog.reparent(entity_root)
	if player:
		dog.global_position = player.global_position + Vector2(42, 18)
