extends "res://src/levels/LevelBase.gd"
## Reusable data-driven isometric blockout base.
## GameplayRoot owns collision/markers; ArtRoot is intentionally visual-only.

const BLOCKOUT_TILESET_PATH := "res://assets/tilesets/iso_blockout/IsoBlockoutTileset.tres"
const BLOCKOUT_ATLAS_PATH := "res://assets/tilesets/iso_blockout/iso_blockout_atlas.png"
const SOURCE_ID := 0

const TILE_FLOOR := Vector2i(0, 0)
const TILE_WALL := Vector2i(1, 0)
const TILE_COVER := Vector2i(2, 0)
const TILE_PLAYER_SPAWN := Vector2i(3, 0)
const TILE_ENEMY_SPAWN := Vector2i(4, 0)
const TILE_OBJECTIVE := Vector2i(5, 0)
const TILE_INTERACTABLE := Vector2i(0, 1)
const TILE_CLUE := Vector2i(1, 1)
const TILE_POLAROID := Vector2i(2, 1)
const TILE_GLOW_GUY := Vector2i(3, 1)
const TILE_TINY_ICON := Vector2i(4, 1)
const TILE_POOP_BAG := Vector2i(5, 1)
const TILE_HAZARD := Vector2i(0, 2)
const TILE_CAMERA_BOUND := Vector2i(1, 2)
const TILE_PATROL_POINT := Vector2i(2, 2)
const TILE_EXIT := Vector2i(3, 2)
const TILE_PUZZLE_GATE := Vector2i(4, 2)
const TILE_FRIEND_ASSIST := Vector2i(5, 2)

# Boundary colliders are invisible containment only. TileMap wall cells remain the
# readable blockout language, while these strips sit just outside the playable floor.
const BOUNDARY_THICKNESS := 28.0
const BOUNDARY_OUTSET := 0.0
const CORNER_SEAL_SIZE := 72.0
const MIN_REQUIRED_PASSAGE_WIDTH_CELLS := 3
const MIN_EXIT_APPROACH_WIDTH_CELLS := 3
const PLAYER_CLEARANCE_PADDING_PX := 4.0
const ISO_PLAYER_VISUAL_SCALE := 0.86
const ISO_PLAYER_COLLISION_SIZE := Vector2(24, 24)

@export var mission_definition: Resource
@export var auto_generate_from_definition := true
@export var default_zone_size := Vector2i(12, 8)

var _required_objective_ids: Array[String] = []
var _completed_objective_ids: Dictionary = {}
var _required_objective_text: Dictionary = {}
var _required_collectible_ids: Array[String] = []
var _completed_collectible_ids: Dictionary = {}
var _required_clue_ids: Array[String] = []
var _completed_clue_ids: Dictionary = {}
var _mission_completing := false
var _active_mutations: Dictionary = {}


func _ready() -> void:
	_ensure_iso_structure()
	_apply_blockout_tileset()
	if mission_definition != null:
		mission_id = mission_definition.mission_id
		objective_text = _initial_objective_text()
		if auto_generate_from_definition:
			_generate_from_definition()
	super._ready()


func validate_blockout() -> Dictionary:
	if mission_definition == null:
		return {"ok": false, "errors": ["MissionDefinition is null."], "warnings": [], "debug": {}}
	return MissionBlockoutValidator.validate(mission_definition, self)


func _ensure_iso_structure() -> void:
	var gameplay := _ensure_node(self, "GameplayRoot", Node2D.new()) as Node2D
	var art := _ensure_node(self, "ArtRoot", Node2D.new()) as Node2D
	var entity := _ensure_node(self, "EntityRoot", Node2D.new()) as Node2D
	entity.y_sort_enabled = true
	_ensure_node(gameplay, "GameplayFloorLayer", TileMapLayer.new())
	_ensure_node(gameplay, "GameplayCollisionLayer", TileMapLayer.new())
	_ensure_node(gameplay, "GameplayMarkersLayer", TileMapLayer.new())
	_ensure_node(gameplay, "BoundaryColliders", Node2D.new())
	_ensure_node(gameplay, "ZoneLabels", Node2D.new())
	_ensure_node(gameplay, "ObjectiveAreas", Node2D.new())
	_ensure_node(gameplay, "ExitAreas", Node2D.new())
	_ensure_node(gameplay, "SpawnPoints", Node2D.new())
	_ensure_node(gameplay, "EnemyPaths", Node2D.new())
	for layer_name in ["GroundArtLayer", "WallArtLayer", "PropArtLayer", "DecorBelowLayer", "DecorAboveLayer", "LightingLayer"]:
		var layer := _ensure_node(art, layer_name, TileMapLayer.new()) as TileMapLayer
		layer.collision_enabled = false
		layer.y_sort_enabled = true
	_ensure_node(entity, "Enemies", Node2D.new())
	_ensure_node(entity, "Interactables", Node2D.new())
	if get_node_or_null("Camera2D") == null:
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		camera.limit_left = -1200
		camera.limit_top = -900
		camera.limit_right = 1200
		camera.limit_bottom = 900
		add_child(camera)
	_ensure_node(self, "MissionController", Node.new())


func _ensure_node(parent: Node, child_name: String, node: Node) -> Node:
	var existing := parent.get_node_or_null(child_name)
	if existing != null:
		return existing
	node.name = child_name
	parent.add_child(node)
	return node


func _apply_blockout_tileset() -> void:
	var ts := _resolve_blockout_tileset()
	if ts == null:
		push_error("IsoMissionBase: missing blockout TileSet.")
		return
	for path in [
		"GameplayRoot/GameplayFloorLayer",
		"GameplayRoot/GameplayCollisionLayer",
		"GameplayRoot/GameplayMarkersLayer",
		"ArtRoot/GroundArtLayer",
		"ArtRoot/WallArtLayer",
		"ArtRoot/PropArtLayer",
		"ArtRoot/DecorBelowLayer",
		"ArtRoot/DecorAboveLayer",
		"ArtRoot/LightingLayer",
	]:
		var layer := get_node_or_null(path) as TileMapLayer
		if layer == null:
			continue
		layer.tile_set = ts
		layer.y_sort_enabled = true
		layer.collision_enabled = path.contains("GameplayCollisionLayer")


func _resolve_blockout_tileset() -> TileSet:
	if FileAccess.file_exists(BLOCKOUT_ATLAS_PATH):
		var runtime_ts := _build_runtime_blockout_tileset()
		if runtime_ts != null:
			return runtime_ts
	var ts := load(BLOCKOUT_TILESET_PATH) as TileSet
	if ts != null and ts.get_source_count() > 0:
		var src := ts.get_source(SOURCE_ID)
		if src is TileSetAtlasSource and (src as TileSetAtlasSource).texture != null:
			return ts
	return _build_runtime_blockout_tileset()


func _build_runtime_blockout_tileset() -> TileSet:
	var img := Image.new()
	if img.load(ProjectSettings.globalize_path(BLOCKOUT_ATLAS_PATH)) != OK:
		return null
	var atlas_texture := ImageTexture.create_from_image(img)
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_STACKED
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	ts.tile_size = Vector2i(64, 32)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 4)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(64, 64)
	ts.add_source(source, SOURCE_ID)
	for y in range(3):
		for x in range(6):
			source.create_tile(Vector2i(x, y))
	# Keep wall solids compact so adjacent isometric wall cells do not create player-trapping seams.
	_add_tile_collision(source, TILE_WALL, PackedVector2Array([Vector2(18, 28), Vector2(46, 28), Vector2(46, 50), Vector2(18, 50)]))
	_add_tile_collision(source, TILE_COVER, PackedVector2Array([Vector2(20, 30), Vector2(44, 30), Vector2(44, 48), Vector2(20, 48)]))
	return ts


func _add_tile_collision(source: TileSetAtlasSource, coords: Vector2i, points: PackedVector2Array) -> void:
	var td := source.get_tile_data(coords, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, points)


func _generate_from_definition() -> void:
	_required_objective_ids.clear()
	_completed_objective_ids.clear()
	_required_objective_text.clear()
	_required_collectible_ids.clear()
	_completed_collectible_ids.clear()
	_required_clue_ids.clear()
	_completed_clue_ids.clear()
	_active_mutations.clear()
	var pool: Dictionary = mission_definition.mutation_pool()
	if not pool.is_empty():
		_active_mutations = MissionMutationHelper.roll(mission_definition.mission_id, pool)
	_paint_zones()
	_create_boundary_colliders()
	_create_spawn_points()
	_create_objective_areas()
	_create_clue_pickups()
	_create_collectible_pickups()
	_create_gate_placeholders()
	_create_enemy_markers()
	_create_cutscene_triggers()
	_create_exit_areas()
	_apply_camera_bounds()
	_update_next_required_objective()


func _paint_zones() -> void:
	var floor_layer := $GameplayRoot/GameplayFloorLayer as TileMapLayer
	var collision_layer := $GameplayRoot/GameplayCollisionLayer as TileMapLayer
	var marker_layer := $GameplayRoot/GameplayMarkersLayer as TileMapLayer
	var labels := $GameplayRoot/ZoneLabels as Node2D
	floor_layer.clear()
	collision_layer.clear()
	marker_layer.clear()
	_clear_children(labels)
	var zones: Array = mission_definition.zones
	if zones.is_empty():
		_paint_floor_zone(Vector2i(-int(default_zone_size.x / 2.0), -int(default_zone_size.y / 2.0)), default_zone_size)
		_paint_boundary_walls()
		return
	for zone in zones:
		if zone == null:
			continue
		var origin: Vector2i = zone.origin
		var size := Vector2i(maxi(3, zone.size.x), maxi(3, zone.size.y))
		_paint_floor_zone(origin, size)
		_add_zone_label(labels, zone.display_name, origin, size)
	_apply_layout_profile()
	_paint_boundary_walls()


func _paint_floor_zone(origin: Vector2i, size: Vector2i) -> void:
	var floor_layer := $GameplayRoot/GameplayFloorLayer as TileMapLayer
	for x in range(origin.x, origin.x + size.x):
		for y in range(origin.y, origin.y + size.y):
			floor_layer.set_cell(Vector2i(x, y), SOURCE_ID, TILE_FLOOR)


func _apply_layout_profile() -> void:
	if mission_definition == null or mission_definition.mission_id != "taco_bell_drop":
		return
	_apply_taco_bell_layout_profile()


func _apply_taco_bell_layout_profile() -> void:
	var collision_layer := $GameplayRoot/GameplayCollisionLayer as TileMapLayer
	for cell in [
		Vector2i(-11, -1), Vector2i(-10, -1), Vector2i(-8, 2),
		Vector2i(-2, -6), Vector2i(-1, -6), Vector2i(-1, 6),
		Vector2i(10, -1), Vector2i(11, -1), Vector2i(12, 1), Vector2i(13, 1),
		Vector2i(15, -3), Vector2i(16, -3), Vector2i(15, 3), Vector2i(16, 3),
		Vector2i(20, 2), Vector2i(21, 2), Vector2i(24, 4), Vector2i(25, 4),
		Vector2i(30, 4), Vector2i(31, 4), Vector2i(7, 10), Vector2i(8, 10),
	]:
		collision_layer.set_cell(cell, SOURCE_ID, TILE_COVER)


func _add_zone_label(parent: Node2D, text: String, origin: Vector2i, size: Vector2i) -> void:
	if text == "":
		return
	var label := Label.new()
	label.name = _node_name("ZoneLabel", text)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.modulate = Color(0.85, 0.95, 1.0, 0.85)
	parent.add_child(label)
	label.global_position = _map_to_global(origin + Vector2i(int(size.x / 2.0), 0)) + Vector2(-72, -28)


func _paint_boundary_walls() -> void:
	var floor_layer := $GameplayRoot/GameplayFloorLayer as TileMapLayer
	var collision_layer := $GameplayRoot/GameplayCollisionLayer as TileMapLayer
	var floor_cells := {}
	for cell in floor_layer.get_used_cells():
		floor_cells[cell] = true
	for cell in floor_cells.keys():
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var wall_cell: Vector2i = cell + offset
			if not floor_cells.has(wall_cell):
				collision_layer.set_cell(wall_cell, SOURCE_ID, TILE_WALL)


func _create_boundary_colliders() -> void:
	var parent := $GameplayRoot/BoundaryColliders as Node2D
	_clear_children(parent)
	var floor_layer := $GameplayRoot/GameplayFloorLayer as TileMapLayer
	var collision_layer := $GameplayRoot/GameplayCollisionLayer as TileMapLayer
	if floor_layer == null or collision_layer == null:
		return
	var floor_cells := {}
	for cell in floor_layer.get_used_cells():
		floor_cells[cell] = true
	var wall_cells := []
	for cell in collision_layer.get_used_cells():
		if collision_layer.get_cell_atlas_coords(cell) != TILE_WALL:
			continue
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if floor_cells.has(cell + offset):
				wall_cells.append(cell)
				break
	var index := 0
	for cell in wall_cells:
		index += 1
		_add_boundary_rect(parent, "BoundaryWall_%03d" % index, _boundary_collider_center(cell, floor_cells), Vector2(8, 8))


func _boundary_collider_center(wall_cell: Vector2i, floor_cells: Dictionary) -> Vector2:
	var wall_pos := _map_to_global(wall_cell)
	var floor_center_sum := Vector2.ZERO
	var floor_neighbor_count := 0
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = wall_cell + offset
		if floor_cells.has(neighbor):
			floor_center_sum += _map_to_global(neighbor)
			floor_neighbor_count += 1
	if floor_neighbor_count == 0:
		return wall_pos
	var floor_center := floor_center_sum / float(floor_neighbor_count)
	var outward := wall_pos - floor_center
	if outward.length() < 0.01:
		return wall_pos
	return wall_pos + outward.normalized() * 42.0


func _add_boundary_rect(parent: Node2D, rect_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = rect_name
	body.collision_layer = 4
	body.collision_mask = 0
	body.set_meta("purpose", "Generated invisible outer boundary for iso blockout.")
	parent.add_child(body)
	body.global_position = center
	var shape := CollisionShape2D.new()
	shape.name = rect_name + "Shape"
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)


func _create_spawn_points() -> void:
	var spawns := $GameplayRoot/SpawnPoints as Node2D
	_clear_children(spawns)
	var spawn_cell := Vector2i.ZERO
	for spawn_def in mission_definition.enemies:
		if spawn_def != null and int(spawn_def.type) == 0:
			spawn_cell = spawn_def.marker_cell
			break
	var marker := Marker2D.new()
	marker.name = "default"
	spawns.add_child(marker)
	marker.global_position = _map_to_global(spawn_cell)
	$GameplayRoot/GameplayMarkersLayer.set_cell(spawn_cell, SOURCE_ID, TILE_PLAYER_SPAWN)


func _create_objective_areas() -> void:
	var parent := $GameplayRoot/ObjectiveAreas as Node2D
	_clear_children(parent)
	var objectives: Array = []
	objectives.append_array(mission_definition.primary_objectives)
	objectives.append_array(mission_definition.optional_objectives)
	for objective in objectives:
		if objective == null:
			continue
		if _is_scent_objective(objective.objective_id):
			_create_scent_objective(parent, objective)
		elif _is_code_objective(objective.objective_id):
			_create_code_objective(parent, objective)
		else:
			var node = _new_placeholder("res://src/missions/iso/placeholders/MissionObjectivePlaceholder.gd")
			node.name = _node_name("Objective", objective.objective_id)
			node.placeholder_id = objective.objective_id
			node.mission_id = mission_definition.mission_id
			node.display_name = "Objective"
			node.interaction_text = objective.display_text
			node.objective_update = objective.completion_text
			node.required = objective.required
			node.global_position = _map_to_global(objective.marker_cell)
			_add_area_shape(node, 30.0)
			_add_debug_label(node, objective.display_text)
			parent.add_child(node)
			node.placeholder_completed.connect(_on_objective_completed)
		if objective.required:
			_required_objective_ids.append(objective.objective_id)
			_required_objective_text[objective.objective_id] = objective.display_text
		$GameplayRoot/GameplayMarkersLayer.set_cell(objective.marker_cell, SOURCE_ID, TILE_OBJECTIVE)


func _is_scent_objective(objective_id: String) -> bool:
	return objective_id.contains("scent")


func _is_code_objective(objective_id: String) -> bool:
	return objective_id.contains("code") or objective_id.contains("keypad")


func _create_scent_objective(parent: Node2D, objective: Resource) -> void:
	var trails := _scent_trail_cells()
	if trails.is_empty():
		trails["parking_garage"] = objective.marker_cell
	var real_id := String(_active_mutations.get("real_scent_trail", "parking_garage"))
	if not trails.has(real_id):
		real_id = "parking_garage"
	for trail_id in trails.keys():
		var node = _new_placeholder("res://src/missions/iso/placeholders/MissionScentTrailPlaceholder.gd")
		node.name = _node_name("Objective" if trail_id == real_id else "ScentTrail", objective.objective_id if trail_id == real_id else trail_id)
		node.placeholder_id = objective.objective_id
		node.objective_id = objective.objective_id
		node.trail_id = trail_id
		node.real_trail_id = real_id
		node.mission_id = mission_definition.mission_id
		node.display_name = _scent_display_name(trail_id)
		node.real_text = "Bentley locks onto the Sterling chemical scent."
		node.fake_text = _fake_scent_text(trail_id)
		node.objective_update = objective.completion_text
		node.global_position = _map_to_global(trails[trail_id])
		_add_area_shape(node, 30.0)
		_add_debug_label(node, node.display_name)
		parent.add_child(node)
		node.placeholder_completed.connect(_on_objective_completed)
		$GameplayRoot/GameplayMarkersLayer.set_cell(trails[trail_id], SOURCE_ID, TILE_FRIEND_ASSIST if trail_id == real_id else TILE_HAZARD)


func _create_code_objective(parent: Node2D, objective: Resource) -> void:
	var node = _new_placeholder("res://src/missions/iso/placeholders/MissionCodeGatePlaceholder.gd")
	node.name = _node_name("Objective", objective.objective_id)
	node.placeholder_id = objective.objective_id
	node.objective_id = objective.objective_id
	node.gate_id = "garage_office_code"
	node.mission_id = mission_definition.mission_id
	node.display_name = "Garage Office Keypad"
	node.correct_code = String(_active_mutations.get("garage_code", "2174"))
	node.required_clue_id = "route_manifest_half"
	node.bypass_item_id = "garage_staff_keycard"
	node.wrong_code_text = "Wrong code. The keypad chirps and flashes red."
	node.solved_text = objective.completion_text
	node.global_position = _map_to_global(objective.marker_cell)
	_add_rect_shape(node, Vector2(84, 48))
	_add_debug_label(node, "Garage code " + node.correct_code)
	parent.add_child(node)
	node.placeholder_completed.connect(_on_objective_completed)


func _create_clue_pickups() -> void:
	var parent := $EntityRoot/Interactables as Node2D
	for clue in mission_definition.evidence_clues:
		if clue == null:
			continue
		var node = _new_placeholder("res://src/missions/iso/placeholders/MissionCluePickupPlaceholder.gd")
		node.name = _node_name("Clue", clue.clue_id)
		node.placeholder_id = clue.clue_id
		node.clue_id = clue.clue_id
		node.mission_id = mission_definition.mission_id
		node.display_name = clue.display_name
		node.clue_description = clue.description
		node.connects_to = clue.connects_to
		node.unlocks_or_modifies = clue.unlocks_or_modifies
		node.final_tower_relevance = clue.final_tower_relevance
		node.interaction_text = "Evidence clue logged: " + clue.display_name
		node.global_position = _map_to_global(clue.marker_cell)
		_add_area_shape(node, 24.0)
		_add_debug_label(node, clue.display_name)
		parent.add_child(node)
		node.placeholder_completed.connect(_on_clue_completed)
		if clue.required:
			_required_clue_ids.append(clue.clue_id)
		$GameplayRoot/GameplayMarkersLayer.set_cell(clue.marker_cell, SOURCE_ID, TILE_CLUE)


func _create_collectible_pickups() -> void:
	var parent := $EntityRoot/Interactables as Node2D
	for collectible in mission_definition.collectibles:
		if collectible == null:
			continue
		var script_path := "res://src/missions/iso/placeholders/MissionCollectiblePickupPlaceholder.gd"
		if int(collectible.type) == 5:
			script_path = "res://src/missions/iso/placeholders/MissionPoopBagPlaceholder.gd"
		elif String(collectible.collectible_id).contains("keycard") or String(collectible.collectible_id).contains("route_code"):
			script_path = "res://src/missions/iso/placeholders/MissionAccessItemPlaceholder.gd"
		var node = _new_placeholder(script_path)
		node.name = _node_name("Collectible", collectible.collectible_id)
		node.placeholder_id = collectible.collectible_id
		node.collectible_id = collectible.collectible_id
		if node is MissionAccessItemPlaceholder:
			node.access_item_id = collectible.collectible_id
		node.collectible_type = _collectible_type_string(collectible.type)
		node.mission_id = mission_definition.mission_id
		node.display_name = collectible.display_name
		node.required = collectible.required
		node.interaction_text = collectible.completion_text
		node.global_position = _map_to_global(collectible.marker_cell)
		_add_area_shape(node, 22.0)
		_add_debug_label(node, collectible.display_name)
		parent.add_child(node)
		node.placeholder_completed.connect(_on_collectible_completed)
		if collectible.required:
			_required_collectible_ids.append(collectible.collectible_id)
		$GameplayRoot/GameplayMarkersLayer.set_cell(collectible.marker_cell, SOURCE_ID, _tile_for_collectible(collectible.type))


func _create_gate_placeholders() -> void:
	var parent := $EntityRoot/Interactables as Node2D
	for gate in mission_definition.puzzle_gates:
		if gate == null:
			continue
		if String(gate.gate_id).contains("garage_office_code"):
			continue
		var node = _new_placeholder("res://src/missions/iso/placeholders/MissionPuzzleGatePlaceholder.gd")
		node.name = _node_name("Gate", gate.gate_id)
		node.placeholder_id = gate.gate_id
		node.gate_id = gate.gate_id
		node.mission_id = mission_definition.mission_id
		node.display_name = gate.display_name
		node.required_item_id = gate.required_item_id
		node.locked_text = gate.locked_text
		node.unlocked_text = gate.unlocked_text
		node.global_position = _map_to_global(gate.marker_cell)
		_add_rect_shape(node, Vector2(72, 42))
		_add_debug_label(node, gate.display_name)
		parent.add_child(node)
		$GameplayRoot/GameplayMarkersLayer.set_cell(gate.marker_cell, SOURCE_ID, TILE_PUZZLE_GATE)


func _create_enemy_markers() -> void:
	var parent := $GameplayRoot/EnemyPaths as Node2D
	var interactables := $EntityRoot/Interactables as Node2D
	_clear_children(parent)
	for spawn_def in mission_definition.enemies:
		if spawn_def == null:
			continue
		if int(spawn_def.type) == 2:
			var marker := Marker2D.new()
			marker.name = _node_name("EnemySpawn", spawn_def.spawn_id)
			parent.add_child(marker)
			marker.global_position = _map_to_global(spawn_def.marker_cell)
			_add_debug_label(marker, _spawn_label(spawn_def.spawn_id))
			$GameplayRoot/GameplayMarkersLayer.set_cell(spawn_def.marker_cell, SOURCE_ID, TILE_ENEMY_SPAWN)
		elif int(spawn_def.type) == 4:
			if String(spawn_def.spawn_id).begins_with("scent_"):
				continue
			var hook = _new_placeholder("res://src/missions/iso/MissionMechanicHook.gd")
			hook.name = _node_name("Placeholder", spawn_def.spawn_id)
			hook.display_name = _spawn_label(spawn_def.spawn_id)
			hook.placeholder_text = _spawn_placeholder_text(spawn_def.spawn_id)
			hook.objective_update = hook.placeholder_text
			hook.global_position = _map_to_global(spawn_def.marker_cell)
			_add_area_shape(hook, 24.0)
			_add_debug_label(hook, hook.display_name)
			interactables.add_child(hook)
			$GameplayRoot/GameplayMarkersLayer.set_cell(spawn_def.marker_cell, SOURCE_ID, _spawn_tile(spawn_def.spawn_id))


func _create_cutscene_triggers() -> void:
	var parent := $EntityRoot/Interactables as Node2D
	for cutscene in mission_definition.cutscenes:
		if cutscene == null:
			continue
		var node = _new_placeholder("res://src/missions/iso/placeholders/MissionCutsceneTriggerPlaceholder.gd")
		node.name = _node_name("Cutscene", cutscene.cutscene_id)
		node.placeholder_id = cutscene.cutscene_id
		node.mission_id = mission_definition.mission_id
		node.display_name = "Cutscene"
		node.lines = cutscene.lines
		node.objective_update = cutscene.objective_update
		node.once_only = cutscene.once_only
		var cell := _find_marker_for_trigger(cutscene.trigger_id)
		node.global_position = _map_to_global(cell)
		_add_area_shape(node, 30.0)
		parent.add_child(node)
		$GameplayRoot/GameplayMarkersLayer.set_cell(cell, SOURCE_ID, TILE_FRIEND_ASSIST)


func _create_exit_areas() -> void:
	var parent := $GameplayRoot/ExitAreas as Node2D
	_clear_children(parent)
	var exit_cell := _default_exit_cell()
	var node = _new_placeholder("res://src/missions/iso/placeholders/MissionExitTriggerPlaceholder.gd")
	node.name = "ExitZone"
	node.placeholder_id = "exit"
	node.mission_id = mission_definition.mission_id
	node.display_name = "Exit"
	node.interaction_text = "Exit reached."
	node.global_position = _map_to_global(exit_cell)
	_add_rect_shape(node, Vector2(96, 64))
	parent.add_child(node)
	node.add_to_group("iso_mission_exit")
	$GameplayRoot/GameplayMarkersLayer.set_cell(exit_cell, SOURCE_ID, TILE_EXIT)


func _apply_camera_bounds() -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var rect := _mission_rect()
	camera.limit_left = int(rect.position.x - 256)
	camera.limit_top = int(rect.position.y - 256)
	camera.limit_right = int(rect.end.x + 256)
	camera.limit_bottom = int(rect.end.y + 256)


func _new_placeholder(script_path: String) -> Area2D:
	var script := load(script_path) as Script
	var node := script.new() as Area2D
	node.collision_layer = 0
	node.collision_mask = 1
	return node


func _add_area_shape(node: Area2D, radius: float) -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	node.add_child(collision)


func _add_rect_shape(node: Area2D, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	node.add_child(collision)


func _add_debug_label(node: Node2D, text: String) -> void:
	if text == "":
		return
	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	label.position = Vector2(-64, -42)
	label.size = Vector2(128, 20)
	node.add_child(label)


func _scent_trail_cells() -> Dictionary:
	var trails := {}
	for spawn_def in mission_definition.enemies:
		if spawn_def == null or int(spawn_def.type) != 4:
			continue
		var id := String(spawn_def.spawn_id)
		if id.begins_with("scent_"):
			trails[id.substr("scent_".length())] = spawn_def.marker_cell
	return trails


func _scent_display_name(trail_id: String) -> String:
	match trail_id:
		"trash_area":
			return "Fake Scent A"
		"loading_dock":
			return "Fake Scent B"
		"parking_garage":
			return "Real Scent Trail"
		_:
			return trail_id.replace("_", " ").capitalize()


func _fake_scent_text(trail_id: String) -> String:
	match trail_id:
		"trash_area":
			return "Bentley sneezes. This smells like raccoons and regret."
		"loading_dock":
			return "Bentley sits down judgmentally. Decoy bag."
		_:
			return "Bentley refuses the trail. Wrong scent, no softlock."


func _spawn_label(spawn_id: String) -> String:
	return spawn_id.replace("_", " ").capitalize()


func _spawn_placeholder_text(spawn_id: String) -> String:
	if spawn_id.contains("cover"):
		return "Stealth placeholder: cars and cones create a low cover route."
	if spawn_id.contains("vent"):
		return "Bentley vent route placeholder: future shortcut/bypass."
	if spawn_id.contains("ambush"):
		return "Combat placeholder: garage floor 2 ambush beat."
	if spawn_id.contains("camera"):
		return "Heat placeholder: camera watches this lane on hotter restarts."
	if spawn_id.contains("alarm"):
		return "Alarm placeholder: route is noisy unless bypassed."
	if spawn_id.contains("guard"):
		return "Heat placeholder: extra guard marker."
	if spawn_id.contains("louis"):
		return "Louis phone line: safehouses are hidden inside delivery logistics."
	return "Mission placeholder: " + _spawn_label(spawn_id)


func _spawn_tile(spawn_id: String) -> Vector2i:
	if spawn_id.contains("camera"):
		return TILE_CAMERA_BOUND
	if spawn_id.contains("alarm"):
		return TILE_HAZARD
	if spawn_id.contains("ambush") or spawn_id.contains("guard"):
		return TILE_ENEMY_SPAWN
	if spawn_id.contains("vent") or spawn_id.contains("louis"):
		return TILE_FRIEND_ASSIST
	return TILE_INTERACTABLE


func _on_objective_completed(id: String) -> void:
	_completed_objective_ids[id] = true
	_update_next_required_objective()


func _on_collectible_completed(id: String) -> void:
	_completed_collectible_ids[id] = true


func _on_clue_completed(id: String) -> void:
	_completed_clue_ids[id] = true
	_update_next_required_objective()


func set_iso_access_item(id: String) -> void:
	if id == "":
		return
	GameState.dialogue_flags["mission_access_item:" + id] = true


func complete_level() -> void:
	request_exit_completion(player)


func request_exit_completion(_player: Node = null) -> bool:
	if _mission_completing or is_complete or is_failed:
		return false
	_complete_exit_return_objectives()
	if not _all_required_done():
		_show_exit_locked_feedback()
		return false
	_mission_completing = true
	super.complete_level()
	return true


func _show_exit_locked_feedback() -> void:
	var message := _exit_locked_message()
	QuestManager.set_objective(message, get_mission_id())
	DialogueManager.start_simple_dialogue([{ "speaker": "Exit", "text": message }])


func _exit_locked_message() -> String:
	for id in _required_objective_ids:
		if not _completed_objective_ids.has(id):
			return "Exit locked: " + String(_required_objective_text.get(id, "finish required objectives first."))
	for id in _required_clue_ids:
		if not _completed_clue_ids.has(id):
			return "Exit locked: recover the required clue before leaving."
	for id in _required_collectible_ids:
		if not _completed_collectible_ids.has(id):
			return "Exit locked: collect required pickups before leaving."
	return "Exit locked: finish required objectives first."


func _complete_exit_return_objectives() -> void:
	for id in _required_objective_ids:
		if String(id).contains("escape") or String(id).contains("return_to_louis"):
			_completed_objective_ids[id] = true


func _update_next_required_objective() -> void:
	for id in _required_objective_ids:
		if not _completed_objective_ids.has(id):
			QuestManager.set_objective(String(_required_objective_text.get(id, "Continue the route.")), get_mission_id())
			return
	for id in _required_clue_ids:
		if not _completed_clue_ids.has(id):
			QuestManager.set_objective("Recover required clue: " + id.replace("_", " ").capitalize(), get_mission_id())
			return
	QuestManager.set_objective("Return to Louis at the exit.", get_mission_id())


func _on_exit_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		request_exit_completion(body)


func _all_required_done() -> bool:
	for id in _required_objective_ids:
		if not _completed_objective_ids.has(id):
			return false
	for id in _required_collectible_ids:
		if not _completed_collectible_ids.has(id):
			return false
	for id in _required_clue_ids:
		if not _completed_clue_ids.has(id):
			return false
	return true


func _setup_exit_zone() -> void:
	for exit_area in get_tree().get_nodes_in_group("iso_mission_exit"):
		if exit_area is Area2D and not exit_area.body_entered.is_connected(_on_exit_zone_body_entered):
			exit_area.body_entered.connect(_on_exit_zone_body_entered)
	var exits := get_node_or_null("GameplayRoot/ExitAreas")
	if exits:
		for child in exits.get_children():
			if child is Area2D:
				var area := child as Area2D
				area.add_to_group("iso_mission_exit")
				if not area.body_entered.is_connected(_on_exit_zone_body_entered):
					area.body_entered.connect(_on_exit_zone_body_entered)


func _get_spawn_point() -> Node2D:
	var spawn_points := get_node_or_null("GameplayRoot/SpawnPoints")
	if spawn_points:
		var spawn_name: String = GameState.next_spawn
		var named := spawn_points.get_node_or_null(spawn_name) as Node2D
		if named:
			GameState.next_spawn = "default"
			return named
		var default_spawn := spawn_points.get_node_or_null("default") as Node2D
		if default_spawn:
			return default_spawn
	return super._get_spawn_point()


func _spawn_player_if_needed() -> void:
	var entity_root := get_node_or_null("EntityRoot") as Node2D
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
	_apply_iso_player_profile()


func _apply_iso_player_profile() -> void:
	if player == null:
		return
	if not bool(player.get_meta("iso_blockout_profile_applied", false)):
		var sprite := player.get_node_or_null("AnimatedSprite2D") as Node2D
		if sprite != null:
			sprite.scale *= ISO_PLAYER_VISUAL_SCALE
		player.set_meta("iso_blockout_profile_applied", true)
	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null and collision.shape is RectangleShape2D:
		var rect := RectangleShape2D.new()
		rect.size = ISO_PLAYER_COLLISION_SIZE
		collision.shape = rect


func _spawn_dog_if_needed() -> void:
	var entity_root := get_node_or_null("EntityRoot") as Node2D
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
	# In iso blockouts Bentley is a companion/sensor, not a physical wall that can pin the player.
	if dog is CollisionObject2D:
		(dog as CollisionObject2D).collision_layer = 0
		(dog as CollisionObject2D).collision_mask = 0


func _map_to_global(cell: Vector2i) -> Vector2:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer:
		return floor_layer.to_global(floor_layer.map_to_local(cell))
	return Vector2(cell.x * 64, cell.y * 32)


func _initial_objective_text() -> String:
	if mission_definition.primary_objectives.is_empty():
		return "Explore the isometric mission blockout."
	var objective = mission_definition.primary_objectives[0]
	return objective.display_text if objective != null else "Explore the isometric mission blockout."


func _default_exit_cell() -> Vector2i:
	if not mission_definition.zones.is_empty() and mission_definition.zones[-1] != null:
		var zone = mission_definition.zones[-1]
		return zone.origin + Vector2i(zone.size.x - 2, int(zone.size.y / 2))
	return Vector2i(5, 0)


func _find_marker_for_trigger(trigger_id: String) -> Vector2i:
	for objective in mission_definition.primary_objectives:
		if objective != null and objective.objective_id == trigger_id:
			return objective.marker_cell
	for objective in mission_definition.optional_objectives:
		if objective != null and objective.objective_id == trigger_id:
			return objective.marker_cell
	for clue in mission_definition.evidence_clues:
		if clue != null and clue.clue_id == trigger_id:
			return clue.marker_cell
	for collectible in mission_definition.collectibles:
		if collectible != null and collectible.collectible_id == trigger_id:
			return collectible.marker_cell
	for gate in mission_definition.puzzle_gates:
		if gate != null and gate.gate_id == trigger_id:
			return gate.marker_cell
	for spawn_def in mission_definition.enemies:
		if spawn_def != null and spawn_def.spawn_id == trigger_id:
			return spawn_def.marker_cell
	return Vector2i.ZERO


func _mission_rect() -> Rect2:
	var min_cell := Vector2i(-8, -6)
	var max_cell := Vector2i(8, 6)
	for zone in mission_definition.zones:
		if zone == null:
			continue
		min_cell.x = mini(min_cell.x, zone.origin.x)
		min_cell.y = mini(min_cell.y, zone.origin.y)
		max_cell.x = maxi(max_cell.x, zone.origin.x + zone.size.x)
		max_cell.y = maxi(max_cell.y, zone.origin.y + zone.size.y)
	var min_world := _map_to_global(min_cell)
	var max_world := _map_to_global(max_cell)
	return Rect2(min_world, max_world - min_world).abs()


func _floor_cell_bounds() -> Rect2i:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer == null:
		return Rect2i()
	var cells := floor_layer.get_used_cells()
	if cells.is_empty():
		return Rect2i()
	var min_x := cells[0].x
	var max_x := cells[0].x
	var min_y := cells[0].y
	var max_y := cells[0].y
	for cell in cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))


func _floor_world_bounds() -> Rect2:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer == null:
		return Rect2()
	var cells := floor_layer.get_used_cells()
	if cells.is_empty():
		return Rect2()
	var half_tile := Vector2(32, 16)
	var first_pos := floor_layer.to_global(floor_layer.map_to_local(cells[0]))
	var min_x := first_pos.x - half_tile.x
	var max_x := first_pos.x + half_tile.x
	var min_y := first_pos.y - half_tile.y
	var max_y := first_pos.y + half_tile.y
	for cell in cells:
		var pos := floor_layer.to_global(floor_layer.map_to_local(cell))
		min_x = minf(min_x, pos.x - half_tile.x)
		max_x = maxf(max_x, pos.x + half_tile.x)
		min_y = minf(min_y, pos.y - half_tile.y)
		max_y = maxf(max_y, pos.y + half_tile.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _node_name(prefix: String, id: String) -> String:
	var clean := id.replace(" ", "_").replace("-", "_")
	return prefix + "_" + clean


func _collectible_type_string(type: int) -> String:
	match type:
		0:
			return "polaroid"
		1:
			return "glow_guy"
		2:
			return "desk_spirit"
		3:
			return "tiny_icon"
		4:
			return "shelf_goblin"
		5:
			return "poop_bag"
		6:
			return "evidence_clue"
		_:
			return "intel"


func _tile_for_collectible(type: int) -> Vector2i:
	match type:
		0:
			return TILE_POLAROID
		1, 2:
			return TILE_GLOW_GUY
		3, 4:
			return TILE_TINY_ICON
		5:
			return TILE_POOP_BAG
		6:
			return TILE_CLUE
		_:
			return TILE_INTERACTABLE
