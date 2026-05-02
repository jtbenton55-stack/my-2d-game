extends "res://src/levels/LevelBase.gd"
## Dev-only isometric vertical slice: standalone TileMapLayers under WorldRoot (no TileMap parent).
## Tiles are painted at runtime from IsoVerticalSlice.tres — see docs/ISOMETRIC_LEVEL_SPEC.md.

const TILESET_PATH := "res://assets/tilesets/iso_vertical_slice/IsoVerticalSlice.tres"
const ROOM_HALF := 7

func _ready() -> void:
	mission_id = "iso_vertical_slice"
	objective_text = "Iso prototype: reach the exit zone."
	_configure_world_layers()
	_paint_iso_room()
	_place_spawn_and_exit()
	super._ready()


func _configure_world_layers() -> void:
	var ts: TileSet = load(TILESET_PATH) as TileSet
	var world := get_node_or_null("WorldRoot") as Node2D
	if world == null or ts == null:
		push_error("IsoVerticalSlice: missing WorldRoot or TileSet.")
		return
	for child in world.get_children():
		if child is TileMapLayer:
			var layer := child as TileMapLayer
			layer.tile_set = ts
			layer.collision_enabled = true


func _paint_iso_room() -> void:
	var ground := $WorldRoot/GroundLayer as TileMapLayer
	var walls := $WorldRoot/WallLayer as TileMapLayer
	if ground == null or walls == null:
		return
	var floor_atlas := Vector2i(0, 0)
	var wall_atlas := Vector2i(1, 0)
	const SOURCE_ID := 0
	for x in range(-ROOM_HALF, ROOM_HALF + 1):
		for y in range(-ROOM_HALF, ROOM_HALF + 1):
			ground.set_cell(Vector2i(x, y), SOURCE_ID, floor_atlas)
	for x in range(-ROOM_HALF, ROOM_HALF + 1):
		walls.set_cell(Vector2i(x, -ROOM_HALF), SOURCE_ID, wall_atlas)
		walls.set_cell(Vector2i(x, ROOM_HALF), SOURCE_ID, wall_atlas)
	for y in range(-ROOM_HALF, ROOM_HALF + 1):
		walls.set_cell(Vector2i(-ROOM_HALF, y), SOURCE_ID, wall_atlas)
		walls.set_cell(Vector2i(ROOM_HALF, y), SOURCE_ID, wall_atlas)


func _place_spawn_and_exit() -> void:
	var ground := $WorldRoot/GroundLayer as TileMapLayer
	var spawn := get_node_or_null("PlayerSpawn") as Marker2D
	var exit_zone := get_node_or_null("ExitZone") as Area2D
	if ground == null:
		return
	var center_world := ground.to_global(ground.map_to_local(Vector2i(0, 0)))
	var exit_world := ground.to_global(ground.map_to_local(Vector2i(ROOM_HALF - 1, 0)))
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
