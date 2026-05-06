extends "res://src/levels/LevelBase.gd"
## Reusable data-driven isometric blockout base.
## GameplayRoot owns collision/markers; ArtRoot is intentionally visual-only.

const BLOCKOUT_TILESET_PATH := "res://assets/tilesets/iso_blockout_clean/IsoBlockoutTileset_Clean.tres"
const BLOCKOUT_ATLAS_PATH := "res://assets/tilesets/iso_blockout_clean/iso_blockout_atlas_clean.png"
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
const ISO_ENEMY_VISUAL_SCALE := 0.86
const ISO_ENEMY_COLLISION_SIZE := Vector2(24, 24)
const LIGHT_ZONE_SHADOW := "shadow"
const LIGHT_ZONE_BRIGHT := "bright"
const LIGHT_ZONE_FLICKER := "flicker"
const ALARM_STATE_NORMAL := "normal"
const ALARM_STATE_SUSPICIOUS := "suspicious"
const ALARM_STATE_ALERTED := "alerted"
const ALARM_STATE_RESOLVED := "resolved"
const ISO_MARKER_SCRIPT := preload("res://src/missions/iso/authoring/IsoMissionMarker.gd")
const TacoBellDialogue := preload("res://src/missions/iso/runtime/TacoBellDialogue.gd")
const MARKER_CATEGORIES: Array[String] = [
	"Spawns",
	"Objectives",
	"Patrols",
	"Enemies",
	"Cameras",
	"LightZones",
	"AlarmZones",
	"EncounterZones",
	"Clues",
	"Collectibles",
	"ScentTrails",
	"Gates",
	"Routes",
	"Transitions",
	"Exit",
]

@export var mission_definition: Resource
@export var auto_generate_from_definition := true
@export var default_zone_size := Vector2i(12, 8)
@export var dev_harness_enabled := true

var _required_objective_ids: Array[String] = []
var _completed_objective_ids: Dictionary = {}
var _required_objective_text: Dictionary = {}
var _required_collectible_ids: Array[String] = []
var _completed_collectible_ids: Dictionary = {}
var _required_clue_ids: Array[String] = []
var _completed_clue_ids: Dictionary = {}
var _mission_completing := false
var _active_mutations: Dictionary = {}
var _runtime_spawned_ids: Dictionary = {}
var _runtime_counts: Dictionary = {}
var _runtime_marker_source := "definition"
var _scene_marker_count := 0
var _generated_marker_count := 0
var _spawn_points_by_id: Dictionary = {}
var _runtime_position_resolutions: Array = []
var _marker_index_ready := false
var _markers_by_id: Dictionary = {}
var _markers_by_type: Dictionary = {}
var _markers_by_link: Dictionary = {}
var _bake_marker_ids: Dictionary = {}
var _heat_profile: Dictionary = {}
var _code_gate_blockers: Dictionary = {}
var _attempt_runtime_state: Dictionary = {}


func _ready() -> void:
	_ensure_iso_structure()
	_apply_blockout_tileset()
	if mission_definition != null:
		mission_id = mission_definition.mission_id
		GameState.start_mission(mission_id)
		objective_text = _initial_objective_text()
		if auto_generate_from_definition:
			_generate_from_definition()
	_ensure_dev_harness()
	super._ready()


func get_authoring_mode() -> String:
	if mission_definition != null and mission_definition.has_method("get"):
		return String(mission_definition.get("authoring_mode"))
	return "generated"


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
	_ensure_node(gameplay, "AuthoringMarkers", Node2D.new())
	_ensure_node(gameplay, "Subareas", Node2D.new())
	var layout_root := _ensure_node(gameplay, "LayoutRoot", Node2D.new())
	_ensure_node(layout_root, "FloorLayer", TileMapLayer.new())
	_ensure_node(layout_root, "WallLayer", TileMapLayer.new())
	_ensure_node(layout_root, "CoverLayer", TileMapLayer.new())
	_ensure_node(layout_root, "CollisionBarrierLayer", TileMapLayer.new())
	_ensure_node(layout_root, "MarkerTileLayer", TileMapLayer.new())
	var debug_layer := _ensure_node(layout_root, "DebugLabelLayer", TileMapLayer.new()) as CanvasItem
	if debug_layer != null:
		debug_layer.visible = OS.is_debug_build()
	var marker_root := _ensure_node(gameplay, "MarkerRoot", Node2D.new())
	for category in MARKER_CATEGORIES:
		_ensure_node(marker_root, category, Node2D.new())
	var runtime := _ensure_node(gameplay, "RuntimeSystems", Node2D.new())
	_ensure_node(runtime, "SpawnedGuards", Node2D.new())
	_ensure_node(runtime, "SpawnedCameras", Node2D.new())
	_ensure_node(runtime, "LightZones", Node2D.new())
	_ensure_node(runtime, "DetectionZones", Node2D.new())
	_ensure_node(runtime, "AlarmZones", Node2D.new())
	_ensure_node(runtime, "EncounterZones", Node2D.new())
	_ensure_node(runtime, "RouteAccessPoints", Node2D.new())
	_ensure_node(runtime, "TransitionTriggers", Node2D.new())
	var debug_labels := _ensure_node(runtime, "DebugLabels", Node2D.new()) as CanvasItem
	if debug_labels != null:
		debug_labels.visible = OS.is_debug_build()
	_ensure_node(runtime, "DebugUI", Node2D.new())
	for layer_name in ["GroundArtLayer", "WallArtLayer", "PropArtLayer", "DecorBelowLayer", "DecorAboveLayer", "LightingLayer", "LightingArtLayer"]:
		var layer := _ensure_node(art, layer_name, TileMapLayer.new()) as TileMapLayer
		layer.collision_enabled = false
		layer.y_sort_enabled = true
	_ensure_node(entity, "Enemies", Node2D.new())
	_ensure_node(entity, "Cameras", Node2D.new())
	_ensure_node(entity, "Interactables", Node2D.new())
	_ensure_node(entity, "DynamicProps", Node2D.new())
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
		"GameplayRoot/LayoutRoot/FloorLayer",
		"GameplayRoot/LayoutRoot/WallLayer",
		"GameplayRoot/LayoutRoot/CoverLayer",
		"GameplayRoot/LayoutRoot/CollisionBarrierLayer",
		"GameplayRoot/LayoutRoot/MarkerTileLayer",
		"GameplayRoot/LayoutRoot/DebugLabelLayer",
		"ArtRoot/GroundArtLayer",
		"ArtRoot/WallArtLayer",
		"ArtRoot/PropArtLayer",
		"ArtRoot/DecorBelowLayer",
		"ArtRoot/DecorAboveLayer",
		"ArtRoot/LightingLayer",
		"ArtRoot/LightingArtLayer",
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
	_apply_heat_profile()
	var mode := get_authoring_mode()
	_runtime_marker_source = "scene_markers" if mode == "scene_authored" or mode == "hybrid" else "definition"
	_reset_marker_index()
	_scene_marker_count = _collect_authoring_markers().size()
	_generated_marker_count = 0
	EventBus.debug("Iso authoring_mode=%s layout_source=%s marker_source=%s scene_markers=%d" % [
		mode,
		_resolved_layout_source(),
		_runtime_marker_source,
		_scene_marker_count
	])
	_sync_layout_root_to_gameplay_layers()
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
	_create_route_test_subareas()
	_setup_runtime_systems()
	_apply_camera_bounds()
	_update_next_required_objective()
	_sync_gameplay_layers_to_layout_root()


func _paint_zones() -> void:
	var floor_layer := $GameplayRoot/GameplayFloorLayer as TileMapLayer
	var collision_layer := $GameplayRoot/GameplayCollisionLayer as TileMapLayer
	var marker_layer := $GameplayRoot/GameplayMarkersLayer as TileMapLayer
	var labels := $GameplayRoot/ZoneLabels as Node2D
	labels.visible = OS.is_debug_build()
	var mode := get_authoring_mode()
	var preserve_scene_layout := mode == "scene_authored" or mode == "hybrid"
	if preserve_scene_layout and floor_layer.get_used_cells().size() > 0:
		EventBus.debug("Iso layout preserved from scene-authored TileMapLayer.")
	else:
		floor_layer.clear()
		collision_layer.clear()
		marker_layer.clear()
		_generated_marker_count += 1
	_clear_children(labels)
	var zones: Array = mission_definition.zones
	if preserve_scene_layout and floor_layer.get_used_cells().size() > 0:
		_apply_layout_profile()
		return
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
	_spawn_points_by_id.clear()
	var spawn_cell := Vector2i.ZERO
	var player_marker := _find_authoring_marker("PLAYER_SPAWN", "start_main")
	if player_marker == null:
		player_marker = _find_authoring_marker("PLAYER_SPAWN", "")
	if player_marker != null:
		var start := Marker2D.new()
		start.name = "start_main"
		start.global_position = player_marker.global_position
		spawns.add_child(start)
		_spawn_points_by_id["start_main"] = start.global_position
		for sub in _collect_authoring_markers("SUBAREA_SPAWN"):
			var sub_id := String(sub.marker_id if sub.has_method("get") else "")
			if sub_id == "":
				continue
			var sub_marker := Marker2D.new()
			sub_marker.name = sub_id
			sub_marker.global_position = sub.global_position
			spawns.add_child(sub_marker)
			_spawn_points_by_id[sub_id] = sub_marker.global_position
		return
	for spawn_def in mission_definition.enemies:
		if spawn_def != null and int(spawn_def.type) == 0:
			spawn_cell = spawn_def.marker_cell
			break
	var marker := Marker2D.new()
	marker.name = "default"
	spawns.add_child(marker)
	marker.global_position = _map_to_global(spawn_cell)
	_spawn_points_by_id["default"] = marker.global_position
	_spawn_points_by_id["start_main"] = marker.global_position
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
			node.global_position = _resolve_point_position(objective.marker_cell, "OBJECTIVE", String(objective.objective_id))
			node.interaction_priority = 95 if objective.required else 60
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
		var marker_type := "SCENT_TRAIL_REAL" if trail_id == real_id else "SCENT_TRAIL_FAKE"
		node.global_position = _resolve_point_position(trails[trail_id], marker_type, String(trail_id))
		node.interaction_priority = 85 if trail_id == real_id else 65
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
	node.wrong_code_text = "Wrong code. Keypad flashes red and security starts to react."
	node.solved_text = objective.completion_text
	node.global_position = _resolve_point_position(objective.marker_cell, "CODE_GATE", String(objective.objective_id))
	node.interaction_priority = 90
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
		node.interaction_text = "Click to inspect clue: " + clue.display_name
		node.global_position = _resolve_point_position(clue.marker_cell, "CLUE", String(clue.clue_id), {
			"linked_clue_id": String(clue.clue_id),
			"canonical_marker_id": "clue_" + String(clue.clue_id),
		})
		node.interaction_priority = 80 if clue.required else 55
		_add_area_shape(node, 24.0)
		_add_debug_label(node, clue.display_name)
		parent.add_child(node)
		node.placeholder_completed.connect(_on_clue_completed)
		if clue.required:
			_required_clue_ids.append(clue.clue_id)
		$GameplayRoot/GameplayMarkersLayer.set_cell(clue.marker_cell, SOURCE_ID, TILE_CLUE)


func _create_collectible_pickups() -> void:
	var parent := $EntityRoot/Interactables as Node2D
	var hidden_slot := String(_active_mutations.get("hidden_collectible_slot", "market_rain"))
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
		node.interaction_text = "Click to pick up " + collectible.display_name + "."
		var marker_cell: Vector2i = collectible.marker_cell
		if String(collectible.collectible_id) == "taco_bell_midnight_market_rain":
			marker_cell = _mutated_hidden_collectible_cell(hidden_slot, marker_cell)
		var marker_type := "POLAROID_HIDDEN"
		if node.collectible_type == "tiny_icon":
			marker_type = "TINY_ICON"
		elif node.collectible_type == "glow_guy":
			marker_type = "GLOW_GUY"
		elif node.collectible_type == "poop_bag":
			marker_type = "POOP_BAG"
		node.global_position = _resolve_point_position(marker_cell, marker_type, String(collectible.collectible_id), {
			"linked_collectible_id": String(collectible.collectible_id),
			"canonical_marker_id": _canonical_collectible_marker_id(String(collectible.collectible_id)),
		})
		node.interaction_priority = 75 if collectible.required else 50
		_add_area_shape(node, 22.0)
		_add_debug_label(node, collectible.display_name)
		parent.add_child(node)
		node.placeholder_completed.connect(_on_collectible_completed)
		if collectible.required:
			_required_collectible_ids.append(collectible.collectible_id)
		$GameplayRoot/GameplayMarkersLayer.set_cell(marker_cell, SOURCE_ID, _tile_for_collectible(collectible.type))


func _create_gate_placeholders() -> void:
	var parent := $EntityRoot/Interactables as Node2D
	for gate in mission_definition.puzzle_gates:
		if gate == null:
			continue
		if String(gate.gate_id).contains("garage_office_code"):
			continue
		if String(gate.gate_id).contains("vent_route") or String(gate.gate_id).contains("future_shortcut"):
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
	node.global_position = _resolve_point_position(exit_cell, "EXIT", "exit", {
		"canonical_marker_id": "exit_return_to_louis",
	})
	_add_rect_shape(node, Vector2(96, 64))
	parent.add_child(node)
	node.add_to_group("iso_mission_exit")
	$GameplayRoot/GameplayMarkersLayer.set_cell(exit_cell, SOURCE_ID, TILE_EXIT)


func _create_route_test_subareas() -> void:
	var floor_layer := $GameplayRoot/GameplayFloorLayer as TileMapLayer
	var collision_layer := $GameplayRoot/GameplayCollisionLayer as TileMapLayer
	if floor_layer == null or collision_layer == null:
		return
	var mode := get_authoring_mode()
	if mode == "scene_authored":
		return
	var authored := _collect_authoring_markers("SUBAREA_SPAWN")
	if authored.size() >= 4:
		return
	var louis_origin := Vector2i(58, -2)
	var vent_origin := Vector2i(58, 10)
	for x in range(louis_origin.x, louis_origin.x + 7):
		for y in range(louis_origin.y, louis_origin.y + 4):
			floor_layer.set_cell(Vector2i(x, y), SOURCE_ID, TILE_FLOOR)
	for x in range(vent_origin.x, vent_origin.x + 6):
		for y in range(vent_origin.y, vent_origin.y + 4):
			floor_layer.set_cell(Vector2i(x, y), SOURCE_ID, TILE_FLOOR)
	for x in range(louis_origin.x - 1, louis_origin.x + 8):
		collision_layer.set_cell(Vector2i(x, louis_origin.y - 1), SOURCE_ID, TILE_WALL)
		collision_layer.set_cell(Vector2i(x, louis_origin.y + 4), SOURCE_ID, TILE_WALL)
	for y in range(louis_origin.y - 1, louis_origin.y + 5):
		collision_layer.set_cell(Vector2i(louis_origin.x - 1, y), SOURCE_ID, TILE_WALL)
		collision_layer.set_cell(Vector2i(louis_origin.x + 7, y), SOURCE_ID, TILE_WALL)
	for x in range(vent_origin.x - 1, vent_origin.x + 7):
		collision_layer.set_cell(Vector2i(x, vent_origin.y - 1), SOURCE_ID, TILE_WALL)
		collision_layer.set_cell(Vector2i(x, vent_origin.y + 4), SOURCE_ID, TILE_WALL)
	for y in range(vent_origin.y - 1, vent_origin.y + 5):
		collision_layer.set_cell(Vector2i(vent_origin.x - 1, y), SOURCE_ID, TILE_WALL)
		collision_layer.set_cell(Vector2i(vent_origin.x + 6, y), SOURCE_ID, TILE_WALL)
	_ensure_subarea_spawn_marker("route_louis_entry", _map_to_global(louis_origin + Vector2i(1, 1)))
	_ensure_subarea_spawn_marker("route_louis_return", _map_to_global(Vector2i(20, -4)))
	_ensure_subarea_spawn_marker("route_vent_entry", _map_to_global(vent_origin + Vector2i(1, 1)))
	_ensure_subarea_spawn_marker("route_vent_return", _map_to_global(Vector2i(26, -6)))


func _ensure_subarea_spawn_marker(spawn_id: String, spawn_position: Vector2) -> void:
	var spawns := $GameplayRoot/SpawnPoints as Node2D
	if spawns == null:
		return
	var marker := spawns.get_node_or_null(spawn_id) as Marker2D
	if marker == null:
		marker = Marker2D.new()
		marker.name = spawn_id
		spawns.add_child(marker)
	marker.global_position = spawn_position
	_spawn_points_by_id[spawn_id] = spawn_position


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
	label.visible = OS.is_debug_build()
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
			return "Oily paw prints"
		"loading_dock":
			return "Sweet sauce smell"
		"parking_garage":
			return "Cold service alley"
		_:
			return "Bentley notices something"


func _fake_scent_text(trail_id: String) -> String:
	match trail_id:
		"trash_area":
			return "Bentley sniffs the air, then glances back at you."
		"loading_dock":
			return "Bentley paces in a small circle. He seems unsure."
		_:
			return "Bentley gives a low huff. Not a clear signal."


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


func _mutated_hidden_collectible_cell(slot: String, fallback: Vector2i) -> Vector2i:
	match slot:
		"market_rain":
			return Vector2i(-10, 1)
		"garage_stairs":
			return Vector2i(19, -4)
		"exit_lobby":
			return Vector2i(-18, 10)
		_:
			return fallback


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


func get_wrong_code_alarm_threshold() -> int:
	return int(_heat_profile.get("wrong_code_threshold", 2))


func get_fake_scent_penalty() -> int:
	return int(_heat_profile.get("fake_scent_penalty", 1))


func spawn_attack_guard_near_player(source_id: String = "wrong_code") -> void:
	if not can_spawn_alarm_guard_for_source(source_id):
		return
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null:
		return
	var spawn_def := MissionSpawnDefinition.new()
	spawn_def.spawn_id = "attack_guard_" + source_id + "_" + str(Time.get_ticks_msec())
	spawn_def.marker_cell = Vector2i.ZERO
	spawn_def.scene_path = "res://scenes/characters/guard.tscn"
	_spawn_guard_for_spawn(spawn_def)
	var enemies := get_node_or_null("EntityRoot/Enemies") as Node2D
	if enemies == null or enemies.get_child_count() <= 0:
		return
	var guard := enemies.get_child(enemies.get_child_count() - 1) as Node2D
	if guard == null:
		return
	guard.global_position = player_node.global_position + Vector2(72, 0)
	GameState.record_mission_performance_event(mission_definition.mission_id, "guards_alerted", 1)
	_attempt_runtime_state["guards_alerted"] = int(_attempt_runtime_state.get("guards_alerted", 0)) + 1
	_attempt_runtime_state["attack_guard_spawned"] = int(_attempt_runtime_state.get("attack_guard_spawned", 0)) + 1
	if source_id.begins_with("alarm_"):
		_attempt_runtime_state["alarm_guard_spawned:" + source_id] = true
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null:
		controller.call("register_detection_event", source_id, 1.0, "guard_detected")


func set_code_gate_open(gate_id: String, open: bool) -> void:
	var blocker := _code_gate_blockers.get(gate_id, null) as StaticBody2D
	if blocker == null:
		return
	blocker.set_deferred("collision_layer", 0 if open else 4)
	blocker.set_deferred("visible", not open)


func deploy_poop_bag_decoy_at(world_pos: Vector2, radius: float = 120.0) -> bool:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer == null:
		return false
	var cell := floor_layer.local_to_map(floor_layer.to_local(world_pos))
	if floor_layer.get_cell_source_id(cell) < 0:
		return false
	var clamped_pos := floor_layer.to_global(floor_layer.map_to_local(cell))
	var props := get_node_or_null("EntityRoot/DynamicProps") as Node2D
	if props == null:
		props = self
	var marker := Node2D.new()
	marker.name = "PoopBagThrown_%d" % Time.get_ticks_msec()
	marker.global_position = clamped_pos
	var ring := Polygon2D.new()
	ring.color = Color(0.58, 0.35, 0.12, 0.42)
	var pts := PackedVector2Array()
	var steps := 14
	for i in range(steps):
		var t := TAU * float(i) / float(steps)
		pts.append(Vector2(cos(t), sin(t)) * 10.0)
	ring.polygon = pts
	marker.add_child(ring)
	props.add_child(marker)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D):
			continue
		if (enemy as Node2D).global_position.distance_to(clamped_pos) > radius:
			continue
		if enemy.has_method("stun"):
			enemy.call("stun", 1.8)
		if enemy.has_method("set"):
			enemy.set("target", null)
	_attempt_runtime_state["poop_bags_used"] = int(_attempt_runtime_state.get("poop_bags_used", 0)) + 1
	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(func():
		if is_instance_valid(marker):
			marker.queue_free()
	)
	return true


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
	_record_runtime_completion_metadata()
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


func _record_runtime_completion_metadata() -> void:
	for reward in mission_definition.scheme_card_rewards:
		if reward == null:
			continue
		var reward_id := String(reward.reward_id)
		if reward_id == "":
			continue
		GameState.unlock_scheme_card(reward_id, {
			"card_id": reward_id,
			"display_name": String(reward.display_name),
			"description": String(reward.description),
			"unlocked_by_mission": mission_definition.mission_id,
			"effect_type": String(reward.effect_type),
			"effect_data": reward.effect_data if reward.effect_data is Dictionary else {},
			"is_equipped": false,
		})
		DialogueManager.start_simple_dialogue([{
			"speaker": "Mission",
			"text": String(TacoBellDialogue.line("mission_complete_001", "Scheme Card unlocked: " + String(reward.display_name), "Mission").get("text"))
		}])
		if reward_id == "louis_delivery_route":
			GameState.unlock_crew_assist("louis_delivery_route_assist", {
				"friend_name": "louis",
				"unlocked_by_mission": mission_definition.mission_id,
				"effect_type": "delivery_route_access",
				"usable_in_missions": ["jazz_club", "rewrite_room", "sterling_tower_heist"],
			})


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
	if player.get_meta("iso_blockout_profile_applied", false) != true:
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


func _setup_runtime_systems() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems") as Node2D
	if runtime == null:
		return
	_reset_attempt_runtime_state()
	for child_name in ["SpawnedGuards", "SpawnedCameras", "LightZones", "DetectionZones", "AlarmZones", "EncounterZones", "RouteAccessPoints", "TransitionTriggers", "DebugLabels"]:
		var bucket := runtime.get_node_or_null(child_name)
		if bucket != null:
			_clear_children(bucket)
	for blocker_id in _code_gate_blockers.keys():
		var blocker := _code_gate_blockers[blocker_id] as Node
		if blocker != null and is_instance_valid(blocker):
			blocker.queue_free()
	_code_gate_blockers.clear()
	_runtime_spawned_ids.clear()
	_runtime_counts.clear()
	_reset_marker_index()
	_attach_camera_shake()
	var alert := _create_alert_controller()
	_spawn_runtime_from_markers(alert)
	_spawn_light_zones()
	_spawn_route_access_points()
	_spawn_transition_placeholder()
	_spawn_poop_bag_decoy()
	_spawn_scent_tutorial_prompt()
	_spawn_camera_terminal()
	_spawn_code_gate_blockers()
	_spawn_route_flavor_interactables()
	if int(_runtime_counts.get("cameras", 0)) <= 0:
		_spawn_fallback_camera(alert)
	var min_cameras := 2
	if _heat_profile.get("extra_camera", false) == true:
		min_cameras = 3
	while int(_runtime_counts.get("cameras", 0)) < min_cameras:
		_spawn_fallback_camera(alert)
	_apply_iso_profile_to_all_runtime_guards()
	if int(_runtime_counts.get("guards", 0)) <= 0:
		_spawn_fallback_guard()
	var debug := _runtime_debug_summary()
	set_meta("iso_runtime_debug", debug)


func _attach_camera_shake() -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	if camera.get_node_or_null("MissionCameraShake") != null:
		return
	var shake_script := load("res://src/missions/iso/runtime/MissionCameraShake.gd") as Script
	if shake_script == null:
		return
	var shake := shake_script.new() as Node
	shake.name = "MissionCameraShake"
	camera.add_child(shake)


func _create_alert_controller() -> Node:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems") as Node2D
	if runtime == null:
		return null
	var script := load("res://src/missions/iso/runtime/MissionAlertController.gd") as Script
	if script == null:
		return null
	var controller := script.new() as Node
	controller.name = "MissionAlertController"
	controller.add_to_group("iso_alert_controller")
	controller.set("mission_id", mission_definition.mission_id)
	runtime.add_child(controller)
	_register_runtime("alert_controllers", "mission_alert_controller")
	return controller


func _spawn_runtime_from_markers(_alert_controller: Node) -> void:
	var heat := GameState.get_mission_heat(mission_definition.mission_id)
	for spawn_def in mission_definition.enemies:
		if spawn_def == null:
			continue
		if spawn_def.heat_min > heat:
			continue
		var spawn_id := String(spawn_def.spawn_id)
		if spawn_id.contains("guard"):
			_spawn_guard_for_spawn(spawn_def)
		elif spawn_id.contains("camera"):
			if spawn_def.heat_min <= heat:
				_spawn_security_camera(spawn_def.marker_cell, spawn_id)
		elif spawn_id.contains("alarm"):
			_spawn_alarm_zone(spawn_def.marker_cell, spawn_id)
		elif spawn_id.contains("ambush"):
			_spawn_encounter_trigger(spawn_def.marker_cell, spawn_id)


func _spawn_guard_for_spawn(spawn_def: Resource) -> void:
	var spawn_id := String(spawn_def.spawn_id)
	if _runtime_spawned_ids.has("guard:" + spawn_id):
		return
	var packed := load(spawn_def.scene_path if String(spawn_def.scene_path) != "" else "res://scenes/characters/guard.tscn") as PackedScene
	if packed == null:
		return
	var guard := packed.instantiate() as Node2D
	if guard == null:
		return
	var enemies := get_node_or_null("EntityRoot/Enemies") as Node2D
	if enemies == null:
		return
	enemies.add_child(guard)
	guard.global_position = _resolve_point_position(spawn_def.marker_cell, "GUARD_SPAWN", spawn_id, {
		"linked_guard_id": spawn_id,
		"canonical_marker_id": "guard_" + spawn_id,
	})
	_apply_iso_enemy_profile(guard)
	if guard.has_signal("spotted_player"):
		guard.connect("spotted_player", Callable(self, "_on_runtime_guard_spotted").bind(spawn_id))
	_spawn_guard_patrol_path(guard, spawn_def.marker_cell, spawn_id)
	_runtime_spawned_ids["guard:" + spawn_id] = true
	_register_runtime("guards", spawn_id)


func _spawn_guard_patrol_path(guard: Node2D, marker_cell: Vector2i, spawn_id: String) -> void:
	if not guard.has_method("assign_patrol_path"):
		return
	var paths := get_node_or_null("GameplayRoot/EnemyPaths") as Node2D
	if paths == null:
		return
	var path := Path2D.new()
	path.name = _node_name("Patrol", spawn_id)
	var c := Curve2D.new()
	var patrol_markers: Array = []
	for marker in _collect_authoring_markers("patrol_point"):
		var linked_guard := _value_string(marker.get("linked_guard_id"))
		var group_id := _value_string(marker.get("group_id"))
		if linked_guard == spawn_id or group_id == spawn_id:
			patrol_markers.append(marker)
	patrol_markers.sort_custom(func(a, b): return int(a.get("order")) < int(b.get("order")))
	if patrol_markers.size() >= 2:
		for marker in patrol_markers:
			c.add_point((marker as Node2D).global_position)
	else:
		var base := _map_to_global(marker_cell)
		c.add_point(base + Vector2(-90, -20))
		c.add_point(base + Vector2(0, 30))
		c.add_point(base + Vector2(90, -20))
	path.curve = c
	paths.add_child(path)
	guard.assign_patrol_path(path)
	_register_runtime("patrol_paths", spawn_id)


func _apply_iso_enemy_profile(guard: Node2D) -> void:
	var sprite := guard.get_node_or_null("AnimatedSprite2D") as Node2D
	if sprite != null:
		sprite.scale = Vector2.ONE * ISO_ENEMY_VISUAL_SCALE
	var collider := guard.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider != null and collider.shape is RectangleShape2D:
		(collider.shape as RectangleShape2D).size = ISO_ENEMY_COLLISION_SIZE
	var hurtbox := guard.get_node_or_null("Hurtbox/CollisionShape2D") as CollisionShape2D
	if hurtbox != null and hurtbox.shape is RectangleShape2D:
		(hurtbox.shape as RectangleShape2D).size = ISO_ENEMY_COLLISION_SIZE
	var vision_cone := guard.get_node_or_null("VisionArea/VisionCone") as CanvasItem
	if vision_cone != null:
		vision_cone.visible = OS.is_debug_build()


func _apply_iso_profile_to_all_runtime_guards() -> void:
	var enemies := get_node_or_null("EntityRoot/Enemies")
	if enemies == null:
		return
	for guard in enemies.get_children():
		if guard is Node2D:
			_apply_iso_enemy_profile(guard as Node2D)


func _spawn_security_camera(cell: Vector2i, camera_id: String) -> void:
	if _runtime_spawned_ids.has("camera:" + camera_id):
		return
	var script := load("res://src/missions/iso/runtime/MissionSecurityCamera.gd") as Script
	if script == null:
		return
	var camera := script.new() as Area2D
	camera.name = _node_name("SecurityCamera", camera_id)
	camera.global_position = _resolve_point_position(cell, "SECURITY_CAMERA", camera_id)
	camera.set("camera_id", camera_id)
	var rate_mult := float(_heat_profile.get("camera_rate_mult", 1.0))
	var sweep_mult := float(_heat_profile.get("camera_sweep_mult", 1.0))
	camera.set("detection_rate", float(camera.get("detection_rate")) * rate_mult)
	camera.set("sweep_speed", float(camera.get("sweep_speed")) * sweep_mult)
	var parent := get_node_or_null("EntityRoot/Cameras") as Node2D
	if parent == null:
		parent = get_node_or_null("EntityRoot/Interactables") as Node2D
	if parent == null:
		return
	parent.add_child(camera)
	_register_runtime("cameras", camera_id)
	var detection_parent := get_node_or_null("GameplayRoot/RuntimeSystems/DetectionZones") as Node2D
	if detection_parent != null:
		var proxy := Area2D.new()
		proxy.name = _node_name("DetectionZone", camera_id)
		proxy.collision_layer = 0
		proxy.collision_mask = 1
		proxy.global_position = camera.global_position
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 64.0
		shape.shape = circle
		proxy.add_child(shape)
		detection_parent.add_child(proxy)
		_register_runtime("detection_zones", camera_id)
	_runtime_spawned_ids["camera:" + camera_id] = true


func _spawn_alarm_zone(cell: Vector2i, alarm_id: String) -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/AlarmZones") as Node2D
	if runtime == null:
		return
	var resolved_alarm_id := alarm_id
	var target_cell := cell
	if alarm_id.contains("alarm_zone_placeholder"):
		resolved_alarm_id = "garage_entry_beam"
		target_cell = Vector2i(8, 2)
	var area := Area2D.new()
	area.name = _node_name("AlarmZone", resolved_alarm_id)
	area.collision_layer = 0
	area.collision_mask = 1
	area.global_position = _resolve_point_position(target_cell, "ALARM_ZONE", resolved_alarm_id)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(96, 52) if _is_alarm_zone_one_shot(resolved_alarm_id) else Vector2(100, 72)
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(_on_runtime_alarm_zone_entered.bind(resolved_alarm_id, area))
	runtime.add_child(area)
	_register_runtime("alarm_zones", resolved_alarm_id)


func _spawn_encounter_trigger(cell: Vector2i, encounter_id: String) -> void:
	if _runtime_spawned_ids.has("encounter:" + encounter_id):
		return
	var script := load("res://src/missions/iso/runtime/MissionEncounterTrigger.gd") as Script
	if script == null:
		return
	var trigger := script.new() as Area2D
	trigger.name = _node_name("Encounter", encounter_id)
	trigger.global_position = _resolve_point_position(cell, "AMBUSH_TRIGGER", encounter_id)
	trigger.set("encounter_id", encounter_id)
	trigger.set("spawn_guard", true)
	trigger.set("dialogue_line", "Garage ambush! Keep moving and recover the bag.")
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/EncounterZones") as Node2D
	if runtime == null:
		return
	runtime.add_child(trigger)
	_register_runtime("encounters", encounter_id)
	_runtime_spawned_ids["encounter:" + encounter_id] = true


func _spawn_light_zones() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/LightZones") as Node2D
	if runtime == null:
		return
	_spawn_light_zone_for("fake_scent_trail_a_trash_area", LIGHT_ZONE_SHADOW, 68.0)
	_spawn_light_zone_for("fake_scent_trail_b_loading_dock", LIGHT_ZONE_FLICKER, 78.0)
	_spawn_light_zone_for("parking_garage_floor_1", LIGHT_ZONE_BRIGHT, 92.0)


func _spawn_light_zone_for(zone_id: String, zone_type: String, radius: float) -> void:
	var zone: Resource = _zone_by_id(zone_id)
	if zone == null:
		return
	var script := load("res://src/missions/iso/runtime/MissionLightZone.gd") as Script
	if script == null:
		return
	var node := script.new() as Area2D
	node.name = _node_name("LightZone", zone_id)
	var center: Vector2i = zone.origin + Vector2i(int(zone.size.x / 2), int(zone.size.y / 2))
	node.global_position = _map_to_global(center)
	node.set("zone_type", zone_type)
	node.set("radius", radius)
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/LightZones") as Node2D
	runtime.add_child(node)
	_register_runtime("light_zones", zone_id + ":" + zone_type)


func _spawn_route_access_points() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/RouteAccessPoints") as Node2D
	if runtime == null:
		return
	var script := load("res://src/missions/iso/runtime/MissionRouteAccessPoint.gd") as Script
	if script == null:
		return
	for gate in mission_definition.puzzle_gates:
		if gate == null:
			continue
		var gate_id := String(gate.gate_id)
		if not gate_id.contains("vent_route") and not gate_id.contains("future_shortcut"):
			continue
		var route := script.new() as Area2D
		route.name = _node_name("RouteAccess", gate_id)
		route.set("mission_id", mission_definition.mission_id)
		route.set("display_name", gate.display_name)
		route.set("route_id", gate_id)
		route.set("is_future_placeholder", gate_id.contains("future_shortcut"))
		route.set("required_card", "louis_delivery_route" if gate_id.contains("future_shortcut") else "")
		if gate_id.contains("future_shortcut"):
			route.set("locked_message", "Locked: requires Louis Delivery Route.")
			route.set("unlocked_message", "Louis Delivery Route available. Route recognized. Functional test route available.")
		elif gate_id.contains("vent_route"):
			route.set("locked_message", "Send Bentley through the vent? Route is currently blocked.")
			route.set("unlocked_message", "Send Bentley through the vent? Bentley opens the shortcut.")
		else:
			route.set("locked_message", gate.locked_text)
			route.set("unlocked_message", gate.unlocked_text)
		route.set("target_spawn_id", "route_louis_entry" if gate_id.contains("future_shortcut") else "route_vent_entry")
		route.set("return_spawn_id", "route_louis_return" if gate_id.contains("future_shortcut") else "route_vent_return")
		route.global_position = _resolve_point_position(gate.marker_cell, "ROUTE_ACCESS", gate_id)
		route.set("interaction_priority", 88)
		_add_rect_shape(route, Vector2(68, 40))
		_add_debug_label(route, gate.display_name)
		runtime.add_child(route)
		_register_runtime("route_access_points", gate_id)
	var keycard_route := script.new() as Area2D
	keycard_route.name = "RouteAccess_garage_staff_keycard_route"
	keycard_route.set("mission_id", mission_definition.mission_id)
	keycard_route.set("display_name", "Garage Staff Keycard Route")
	keycard_route.set("route_id", "garage_staff_keycard_route")
	keycard_route.set("required_item", "garage_staff_keycard")
	keycard_route.set("locked_message", "Need staff keycard (or alternate bypass) for this route.")
	keycard_route.set("unlocked_message", "Keycard route unlocked.")
	keycard_route.set("target_spawn_id", "route_louis_entry")
	keycard_route.set("return_spawn_id", "route_louis_return")
	var security_zone: Resource = _zone_by_id("security_booth_keycard_room")
	if security_zone != null:
		var center: Vector2i = security_zone.origin + Vector2i(int(security_zone.size.x / 2), int(security_zone.size.y / 2))
		keycard_route.global_position = _resolve_point_position(center, "ROUTE_ACCESS", "garage_staff_keycard_route")
	keycard_route.set("interaction_priority", 70)
	_add_rect_shape(keycard_route, Vector2(66, 40))
	_add_debug_label(keycard_route, "Staff Keycard Route")
	runtime.add_child(keycard_route)
	_register_runtime("route_access_points", "garage_staff_keycard_route")


func _spawn_transition_placeholder() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/TransitionTriggers") as Node2D
	if runtime == null:
		return
	var script := load("res://src/missions/iso/runtime/MissionTransitionPlaceholder.gd") as Script
	if script == null:
		return
	var node := script.new() as Area2D
	node.name = "Transition_garage_floor2_service_stairs"
	node.set("mission_id", mission_definition.mission_id)
	node.set("display_name", "Garage Floor 2 Service Transition")
	node.set("transition_id", "garage_floor2_service_stairs")
	node.set("target_subarea", "garage_floor_2")
	node.set("target_spawn_id", "route_louis_entry")
	node.set("return_spawn_id", "route_louis_return")
	node.set("is_placeholder", false)
	node.set("locked_message", "Future transition: Garage Floor 2 route.")
	var office: Resource = _zone_by_id("garage_office")
	if office != null:
		var center: Vector2i = office.origin + Vector2i(maxi(1, office.size.x - 2), int(office.size.y / 2))
		node.global_position = _resolve_point_position(center, "TRANSITION", "garage_floor2_service_stairs")
	node.set("interaction_priority", 84)
	_add_rect_shape(node, Vector2(64, 42))
	runtime.add_child(node)
	_register_runtime("transition_triggers", "garage_floor2_service_stairs")
	var route_return := script.new() as Area2D
	route_return.name = "Transition_route_louis_return"
	route_return.set("mission_id", mission_definition.mission_id)
	route_return.set("display_name", "Return From Louis Route")
	route_return.set("transition_id", "route_louis_return")
	route_return.set("target_spawn_id", "route_louis_return")
	route_return.set("is_placeholder", false)
	route_return.set("interaction_priority", 90)
	route_return.global_position = _spawn_points_by_id.get("route_louis_entry", _map_to_global(Vector2i(58, -2)))
	_add_rect_shape(route_return, Vector2(62, 36))
	runtime.add_child(route_return)
	_register_runtime("transition_triggers", "route_louis_return")
	var vent_return := script.new() as Area2D
	vent_return.name = "Transition_route_vent_return"
	vent_return.set("mission_id", mission_definition.mission_id)
	vent_return.set("display_name", "Return From Vent Route")
	vent_return.set("transition_id", "route_vent_return")
	vent_return.set("target_spawn_id", "route_vent_return")
	vent_return.set("is_placeholder", false)
	vent_return.set("interaction_priority", 90)
	vent_return.global_position = _spawn_points_by_id.get("route_vent_entry", _map_to_global(Vector2i(58, 10)))
	_add_rect_shape(vent_return, Vector2(62, 36))
	runtime.add_child(vent_return)
	_register_runtime("transition_triggers", "route_vent_return")


func _spawn_poop_bag_decoy() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/RouteAccessPoints") as Node2D
	if runtime == null:
		return
	var script := load("res://src/missions/iso/runtime/MissionPoopBagDecoyPoint.gd") as Script
	if script == null:
		return
	var node := script.new() as Area2D
	node.name = "PoopBagDecoy_loading_dock"
	node.set("mission_id", mission_definition.mission_id)
	node.set("display_name", "Poop Bag Decoy Point")
	node.set("interaction_text", "Deploy a poop bag decoy to distract nearby guards.")
	var zone: Resource = _zone_by_id("fake_scent_trail_b_loading_dock")
	if zone != null:
		var center: Vector2i = zone.origin + Vector2i(maxi(1, zone.size.x - 2), int(zone.size.y / 2))
		node.global_position = _resolve_point_position(center, "POOP_BAG", "loading_dock_decoy")
	node.set("interaction_priority", 72)
	_add_area_shape(node, 24.0)
	runtime.add_child(node)
	_register_runtime("poop_bag_utility_points", "loading_dock_decoy")


func _spawn_camera_terminal() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/RouteAccessPoints") as Node2D
	if runtime == null:
		return
	var script := load("res://src/missions/iso/runtime/MissionCameraTerminal.gd") as Script
	if script == null:
		return
	var node := script.new() as Area2D
	node.name = "CameraTerminal_security_booth"
	node.set("mission_id", mission_definition.mission_id)
	node.set("display_name", "Security Camera Terminal")
	var zone: Resource = _zone_by_id("security_booth_keycard_room")
	if zone != null:
		var center: Vector2i = zone.origin + Vector2i(int(zone.size.x / 2), int(zone.size.y / 2))
		node.global_position = _resolve_point_position(center, "CAMERA_TERMINAL", "security_booth_terminal")
	node.set("interaction_priority", 82)
	_add_rect_shape(node, Vector2(60, 36))
	runtime.add_child(node)
	_register_runtime("camera_terminals", "security_booth_terminal")


func _spawn_scent_tutorial_prompt() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/RouteAccessPoints") as Node2D
	if runtime == null:
		return
	var script := load("res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd") as Script
	if script == null:
		return
	var node := script.new() as Area2D
	node.name = "ScentTutorial_delivery_alley"
	node.set("mission_id", mission_definition.mission_id)
	node.set("display_name", "Bentley")
	node.set("placeholder_id", "scent_tutorial_delivery_alley")
	node.set("interaction_text", "Click to ask Bentley to sniff this trail.")
	node.set("objective_update", "Click scent trails and let Bentley confirm the freshest route.")
	node.set("auto_trigger_on_enter", true)
	node.set("once_only", true)
	node.global_position = _map_to_global(Vector2i(-2, -4))
	_add_area_shape(node, 24.0)
	runtime.add_child(node)
	_register_runtime("route_access_points", "scent_tutorial_delivery_alley")


func _spawn_code_gate_blockers() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/TransitionTriggers") as Node2D
	if runtime == null:
		return
	var blocker := StaticBody2D.new()
	blocker.name = "CodeGateBarrier_garage_office_code"
	blocker.collision_layer = 4
	blocker.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(84, 28)
	shape.shape = rect
	blocker.add_child(shape)
	blocker.global_position = _resolve_point_position(Vector2i(21, -3), "CODE_GATE", "code_gate_garage_office")
	runtime.add_child(blocker)
	_code_gate_blockers["garage_office_code"] = blocker


func _spawn_route_flavor_interactables() -> void:
	var parent := get_node_or_null("EntityRoot/Interactables") as Node2D
	if parent == null:
		return
	var placeholder_script := load("res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd") as Script
	if placeholder_script == null:
		return
	var louis := placeholder_script.new() as Area2D
	louis.name = "Flavor_route_louis_corridor"
	louis.set("placeholder_id", "flavor_route_louis_corridor")
	louis.set("mission_id", mission_definition.mission_id)
	louis.set("display_name", "Delivery Crates")
	louis.set("interaction_text", "Click to inspect the delivery crates.")
	louis.set("objective_update", "Delivery corridor inspected.")
	louis.global_position = _spawn_points_by_id.get("route_louis_entry", _map_to_global(Vector2i(59, -1))) + Vector2(64, 0)
	_add_area_shape(louis, 18.0)
	parent.add_child(louis)
	var vent := placeholder_script.new() as Area2D
	vent.name = "Flavor_route_vent_passage"
	vent.set("placeholder_id", "flavor_route_vent_passage")
	vent.set("mission_id", mission_definition.mission_id)
	vent.set("display_name", "Vent Service Hatch")
	vent.set("interaction_text", "Click to inspect the vent service hatch.")
	vent.set("objective_update", "Vent passage inspected.")
	vent.global_position = _spawn_points_by_id.get("route_vent_entry", _map_to_global(Vector2i(59, 11))) + Vector2(52, 0)
	_add_area_shape(vent, 18.0)
	parent.add_child(vent)
	var reward_script := load("res://src/missions/iso/placeholders/MissionCollectiblePickupPlaceholder.gd") as Script
	if reward_script != null:
		var reward := reward_script.new() as Area2D
		reward.name = "Collectible_route_louis_reward"
		reward.set("placeholder_id", "collectible_route_louis_reward")
		reward.set("collectible_id", "route_louis_tip_coin")
		reward.set("collectible_type", "tiny_icon")
		reward.set("mission_id", mission_definition.mission_id)
		reward.set("display_name", "Delivery Tip Token")
		reward.set("interaction_text", "Click to pocket the delivery tip token.")
		reward.global_position = _spawn_points_by_id.get("route_louis_entry", _map_to_global(Vector2i(59, -1))) + Vector2(96, -18)
		_add_area_shape(reward, 16.0)
		parent.add_child(reward)


func _spawn_fallback_camera(_alert_controller: Node) -> void:
	var index := int(_runtime_counts.get("cameras", 0))
	var slots := [
		Vector2i(8, 0),   # garage entry lane
		Vector2i(21, -5), # office/code approach
		Vector2i(-5, 8),  # bypass/return corridor
	]
	var center: Vector2i = slots[mini(index, slots.size() - 1)]
	_spawn_security_camera(center, "garage_fallback_camera_%d" % index)


func _spawn_fallback_guard() -> void:
	var zone: Resource = _zone_by_id("parking_garage_floor_1")
	if zone == null:
		return
	var spawn_def := MissionSpawnDefinition.new()
	spawn_def.spawn_id = "garage_fallback_guard"
	spawn_def.scene_path = "res://scenes/characters/guard.tscn"
	spawn_def.marker_cell = zone.origin + Vector2i(2, int(zone.size.y / 2))
	_spawn_guard_for_spawn(spawn_def)


func _on_runtime_guard_spotted(spawn_id: String) -> void:
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null:
		controller.call("register_detection_event", spawn_id, 1.0, "guard_detected")
	EventBus.screen_shake.emit(0.9, 0.08)


func _on_runtime_alarm_zone_entered(body: Node, alarm_id: String, area: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	if _is_alarm_zone_one_shot(alarm_id):
		if _is_runtime_flag_true("alarm_triggered:" + alarm_id):
			return
		_attempt_runtime_state["alarm_triggered:" + alarm_id] = true
		_attempt_runtime_state["ambush_triggered"] = int(_attempt_runtime_state.get("ambush_triggered", 0)) + 1
		if area != null:
			area.set_deferred("monitoring", false)
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null:
		controller.call("register_detection_event", "alarm_" + alarm_id, 1.0, "alarm_zone")


func _zone_by_id(id: String) -> Resource:
	for zone in mission_definition.zones:
		if zone != null and String(zone.zone_id) == id:
			return zone
	return null


func _register_runtime(bucket: String, id: String) -> void:
	_runtime_counts[bucket] = int(_runtime_counts.get(bucket, 0)) + 1
	_runtime_spawned_ids[bucket + ":" + id] = true


func _runtime_debug_summary() -> Dictionary:
	var enemies := get_node_or_null("EntityRoot/Enemies")
	var cameras := get_node_or_null("EntityRoot/Cameras")
	var runtime_guard_count := enemies.get_child_count() if enemies != null else 0
	var camera_count := cameras.get_child_count() if cameras != null else 0
	return {
		"marker_to_runtime_counts": _runtime_counts.duplicate(true),
		"spawned_runtime_ids": _runtime_spawned_ids.keys(),
		"authoring_mode": get_authoring_mode(),
		"layout_source": _resolved_layout_source(),
		"marker_source": _runtime_marker_source,
		"heat_profile": _heat_profile.duplicate(true),
		"scene_markers_found": _scene_marker_count,
		"generated_markers_found": _generated_marker_count,
		"using_scene_authored_layout": get_authoring_mode() == "hybrid" or get_authoring_mode() == "scene_authored",
		"using_scene_authored_markers": _runtime_marker_source == "scene_markers",
		"position_resolutions": _runtime_position_resolutions.duplicate(true),
		"extra_guard_active": runtime_guard_count > 1,
		"extra_camera_active": camera_count > 1,
		"attempt_runtime_state": _attempt_runtime_state.duplicate(true),
		"garage_beam_armed": not _is_runtime_flag_true("alarm_triggered:garage_entry_beam"),
		"garage_beam_triggered": _is_runtime_flag_true("alarm_triggered:garage_entry_beam"),
	}


func _reset_attempt_runtime_state() -> void:
	_attempt_runtime_state = {
		"alarms": 0,
		"wrong_code": 0,
		"guards_alerted": 0,
		"cameras_triggered": 0,
		"wrong_scent": 0,
		"attack_guard_spawned": 0,
		"ambush_triggered": 0,
		"poop_bags_collected": 0,
		"poop_bags_used": 0,
	}
	GameState.begin_mission_performance(mission_definition.mission_id)
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null and controller.has_method("reset_attempt_state"):
		controller.call("reset_attempt_state")


func _is_runtime_flag_true(key: String) -> bool:
	return _attempt_runtime_state.get(key, false) == true


func _is_alarm_zone_one_shot(alarm_id: String) -> bool:
	return alarm_id == "garage_entry_beam"


func mark_runtime_encounter_triggered(encounter_id: String) -> void:
	if encounter_id == "":
		return
	_attempt_runtime_state["encounter_triggered:" + encounter_id] = true
	_attempt_runtime_state["ambush_triggered"] = int(_attempt_runtime_state.get("ambush_triggered", 0)) + 1


func is_runtime_encounter_triggered(encounter_id: String) -> bool:
	if encounter_id == "":
		return false
	return _is_runtime_flag_true("encounter_triggered:" + encounter_id)


func can_spawn_alarm_guard_for_source(source_id: String) -> bool:
	if source_id.begins_with("alarm_garage_entry_beam"):
		return _is_runtime_flag_true("alarm_guard_spawned:alarm_garage_entry_beam") != true
	return true


func increment_attempt_counter(counter_id: String, amount: int = 1) -> void:
	if counter_id == "" or amount == 0:
		return
	_attempt_runtime_state[counter_id] = int(_attempt_runtime_state.get(counter_id, 0)) + amount


func get_attempt_counter(counter_id: String) -> int:
	if counter_id == "":
		return 0
	return int(_attempt_runtime_state.get(counter_id, 0))


func get_runtime_debug_summary() -> Dictionary:
	return _runtime_debug_summary()


func _resolved_layout_source() -> String:
	if mission_definition == null:
		return "definition"
	if mission_definition.has_method("get"):
		var value = mission_definition.get("layout_source_id")
		if value != null and String(value).strip_edges() != "":
			return String(value)
	return "definition"


func _collect_authoring_markers(type_filter: String = "") -> Array:
	_ensure_marker_index()
	var normalized_filter := _normalized_marker_type(type_filter)
	if normalized_filter == "":
		return _markers_by_type.get("*", [])
	return _markers_by_type.get(normalized_filter, [])


func _ensure_marker_index() -> void:
	if _marker_index_ready:
		return
	_rebuild_marker_index()


func _rebuild_marker_index() -> void:
	_markers_by_id.clear()
	_markers_by_type.clear()
	_markers_by_link.clear()
	_markers_by_type["*"] = []
	var roots := _marker_collection_roots()
	for root in roots:
		_collect_marker_nodes_recursive(root, _markers_by_type["*"], "")
	for marker in _markers_by_type["*"]:
		_index_marker(marker)
	_marker_index_ready = true


func _marker_collection_roots() -> Array:
	var roots: Array = []
	var marker_root := get_node_or_null("GameplayRoot/MarkerRoot")
	if marker_root != null and marker_root.get_child_count() > 0:
		roots.append(marker_root)
	if roots.is_empty():
		var legacy_root := get_node_or_null("GameplayRoot/AuthoringMarkers")
		if legacy_root != null:
			roots.append(legacy_root)
	return roots


func _index_marker(marker: Node) -> void:
	if marker == null:
		return
	var marker_type := _normalized_marker_type(_value_string(marker.get("marker_type")))
	if not _markers_by_type.has(marker_type):
		_markers_by_type[marker_type] = []
	(_markers_by_type[marker_type] as Array).append(marker)
	var marker_id := _value_string(marker.get("marker_id"))
	if marker_id != "" and not _markers_by_id.has(marker_id):
		_markers_by_id[marker_id] = marker
	var link_fields := [
		"linked_objective_id",
		"linked_clue_id",
		"linked_collectible_id",
		"linked_route_id",
		"linked_guard_id",
		"linked_camera_id",
		"group_id",
	]
	for field in link_fields:
		var value := _value_string(marker.get(field))
		if value == "":
			continue
		var key: String = field + ":" + value
		if not _markers_by_link.has(key):
			_markers_by_link[key] = []
		(_markers_by_link[key] as Array).append(marker)


func _reset_marker_index() -> void:
	_marker_index_ready = false
	_markers_by_id.clear()
	_markers_by_type.clear()
	_markers_by_link.clear()


func _collect_authoring_markers_legacy(type_filter: String = "") -> Array:
	var out: Array = []
	var roots := _marker_collection_roots()
	for root in roots:
		_collect_marker_nodes_recursive(root, out, type_filter)
	out.sort_custom(func(a, b): return int(a.get("order")) < int(b.get("order")))
	return out


func _collect_marker_nodes_recursive(node: Node, out: Array, type_filter: String) -> void:
	var normalized_filter := _normalized_marker_type(type_filter)
	for child in node.get_children():
		if child == null:
			continue
		if child.has_method("get") and child.get("marker_type") != null:
			var marker_type := _normalized_marker_type(str(child.get("marker_type")))
			if normalized_filter == "" or marker_type == normalized_filter:
				out.append(child)
		_collect_marker_nodes_recursive(child, out, type_filter)


func _find_authoring_marker(type_filter: String, marker_id: String) -> Node:
	_ensure_marker_index()
	if marker_id != "" and _markers_by_id.has(marker_id):
		var direct := _markers_by_id[marker_id] as Node
		if type_filter == "" or _normalized_marker_type(_value_string(direct.get("marker_type"))) == _normalized_marker_type(type_filter):
			return direct
	for marker in _collect_authoring_markers(type_filter):
		if marker_id == "" or _value_string(marker.get("marker_id")) == marker_id:
			return marker
	return null


func _resolve_point_position(default_cell: Vector2i, type_filter: String, marker_id: String, query: Dictionary = {}) -> Vector2:
	var normalized_type := _normalized_marker_type(type_filter)
	_ensure_marker_index()
	var marker := _resolve_marker_from_query(normalized_type, marker_id, query)
	var default_position := _map_to_global(default_cell)
	if marker == null and normalized_type == "guard_spawn":
		marker = _resolve_marker_from_query("ambush_guard_spawn", marker_id, query)
	if marker == null and normalized_type == "route_access":
		if marker_id.contains("vent"):
			marker = _resolve_marker_from_query("bentley_vent_route", marker_id, query)
		elif marker_id.contains("louis"):
			marker = _resolve_marker_from_query("louis_delivery_route", marker_id, query)
	if marker == null and normalized_type == "transition":
		marker = _resolve_marker_from_query("transition_entry", marker_id, query)
	if marker == null and normalized_type == "poop_bag":
		marker = _resolve_marker_from_query("poop_bag", marker_id, query)
	if marker == null and marker_id != "":
		marker = _resolve_marker_from_query("", marker_id, query)
	if marker != null:
		var marker_position := (marker as Node2D).global_position
		_record_position_resolution(marker_id, normalized_type, "scene_marker", _value_string(marker.get("marker_id")), marker_position, marker_position)
		return marker_position
	_record_position_resolution(marker_id, normalized_type, "definition_fallback", marker_id, default_position, default_position)
	return default_position


func _resolve_marker_from_query(type_filter: String, marker_id: String, query: Dictionary) -> Node:
	var normalized_type := _normalized_marker_type(type_filter)
	var id_value := marker_id.strip_edges()
	if id_value != "" and _markers_by_id.has(id_value):
		var by_id := _markers_by_id[id_value] as Node
		if normalized_type == "" or _normalized_marker_type(_value_string(by_id.get("marker_type"))) == normalized_type:
			return by_id
	var linked_order := [
		"linked_clue_id",
		"linked_collectible_id",
		"linked_objective_id",
		"linked_route_id",
		"linked_guard_id",
		"linked_camera_id",
	]
	for field in linked_order:
		var value := _value_string(query.get(field, ""))
		if value == "":
			continue
		var key: String = field + ":" + value
		if _markers_by_link.has(key):
			for marker in _markers_by_link[key]:
				if normalized_type == "" or _normalized_marker_type(_value_string(marker.get("marker_type"))) == normalized_type:
					return marker
	var canonical := _value_string(query.get("canonical_marker_id", ""))
	if canonical != "" and _markers_by_id.has(canonical):
		return _markers_by_id[canonical]
	if normalized_type != "":
		var typed: Array = _markers_by_type.get(normalized_type, [])
		for marker in typed:
			if id_value == "" or _value_string(marker.get("marker_id")) == id_value:
				return marker
	return null


func _record_position_resolution(object_id: String, object_type: String, source: String, marker_id: String, marker_position: Vector2, runtime_position: Vector2) -> void:
	_runtime_position_resolutions.append({
		"object_id": object_id,
		"object_type": object_type,
		"resolved_from": source,
		"marker_id": marker_id,
		"scene_marker_position": marker_position,
		"runtime_spawn_position": runtime_position,
		"position_delta": runtime_position - marker_position,
	})


func _normalized_marker_type(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	if normalized == "":
		return ""
	return normalized.replace(" ", "_")


func _ensure_dev_harness() -> void:
	if not OS.is_debug_build() or not dev_harness_enabled:
		for node in get_tree().get_nodes_in_group("iso_debug_hud"):
			if is_instance_valid(node):
				node.queue_free()
		return
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems/DebugUI") as Node2D
	if runtime == null:
		return
	for node in get_tree().get_nodes_in_group("iso_debug_hud"):
		if node.get_parent() != self and is_instance_valid(node):
			node.queue_free()
	var existing := get_node_or_null("IsoMissionDebugPanel")
	if existing != null:
		for dup in get_tree().get_nodes_in_group("iso_debug_hud"):
			if dup != existing and is_instance_valid(dup):
				dup.queue_free()
		return
	var script := load("res://src/missions/iso/runtime/IsoMissionDebugPanel.gd") as Script
	if script == null:
		return
	var panel := script.new() as CanvasLayer
	panel.name = "IsoMissionDebugPanel"
	panel.set("mission_id", mission_definition.mission_id)
	add_child(panel)
	var token := Node2D.new()
	token.name = "IsoDebugHarnessToken"
	runtime.add_child(token)


func trigger_alarm_test() -> void:
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null:
		controller.call("register_detection_event", "debug_alarm", 1.0, "debug_alarm")
	spawn_extra_guard_test()


func spawn_extra_guard_test() -> void:
	var spawn_def := MissionSpawnDefinition.new()
	spawn_def.spawn_id = "debug_extra_guard"
	spawn_def.marker_cell = Vector2i(14, -3)
	spawn_def.scene_path = "res://scenes/characters/guard.tscn"
	_spawn_guard_for_spawn(spawn_def)


func teleport_player_to_spawn_id(spawn_id: String) -> void:
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null:
		return
	if _spawn_points_by_id.has(spawn_id):
		player_node.global_position = _spawn_points_by_id[spawn_id]
		return
	var fallback := {
		"delivery_hub": Vector2i(-2, -5),
		"garage_1": Vector2i(14, -6),
		"code_gate": Vector2i(19, -2),
		"ambush": Vector2i(24, 1),
		"bag_recovery": Vector2i(29, 2),
		"exit": _default_exit_cell()
	}
	if fallback.has(spawn_id):
		var value = fallback[spawn_id]
		if value is Vector2i:
			player_node.global_position = _map_to_global(value)


func handle_route_access(route_id: String, target_spawn_id: String, return_spawn_id: String) -> bool:
	if target_spawn_id == "":
		return false
	teleport_player_to_spawn_id(target_spawn_id)
	if return_spawn_id != "":
		GameState.dialogue_flags["iso_return_spawn:" + route_id] = return_spawn_id
	return true


func handle_transition_trigger(_transition_id: String, target_spawn_id: String, return_spawn_id: String) -> bool:
	if target_spawn_id == "":
		return false
	teleport_player_to_spawn_id(target_spawn_id)
	if return_spawn_id != "":
		GameState.dialogue_flags["iso_return_spawn:last"] = return_spawn_id
	return true


func bake_to_editable_scene(output_scene_path: String = "res://scenes/missions_iso/TacoBellIso_Editable.tscn", overwrite_existing := false) -> Dictionary:
	if FileAccess.file_exists(output_scene_path) and not overwrite_existing:
		return {"ok": false, "error": "Output scene already exists. Pass overwrite_existing=true or move it first.", "path": output_scene_path}
	_prepare_editable_bake_state()
	_strip_runtime_state_for_bake()
	_ensure_owner_tree_for_bake()
	name = "TacoBellIso_Editable"
	var packed := PackedScene.new()
	var pack_err := packed.pack(self)
	if pack_err != OK:
		return {"ok": false, "error": "PackedScene.pack failed: " + str(pack_err), "path": output_scene_path}
	var save_err := ResourceSaver.save(packed, output_scene_path)
	return {"ok": save_err == OK, "path": output_scene_path, "error": "" if save_err == OK else "ResourceSaver.save failed: " + str(save_err)}


func bake_hand_edit_test_scene(source_scene_path: String = "res://scenes/missions_iso/TacoBellIso_Editable.tscn", test_scene_path: String = "res://scenes/missions_iso/TacoBellIso_Editable_Test.tscn", overwrite_existing := true) -> Dictionary:
	if not FileAccess.file_exists(source_scene_path):
		return {"ok": false, "error": "Source editable scene not found: " + source_scene_path}
	if FileAccess.file_exists(test_scene_path) and not overwrite_existing:
		return {"ok": false, "error": "Test scene already exists and overwrite_existing=false."}
	var packed := load(source_scene_path) as PackedScene
	if packed == null:
		return {"ok": false, "error": "Failed loading source scene."}
	var inst := packed.instantiate() as Node2D
	if inst == null:
		return {"ok": false, "error": "Failed instantiating source scene."}
	var level := inst as Node
	if level == null:
		return {"ok": false, "error": "Source scene root is not a Node2D."}
	level.call("_apply_hand_edit_test_mutations")
	inst.name = "TacoBellIso_Editable_Test"
	var out := PackedScene.new()
	var pack_err := out.pack(inst)
	if pack_err != OK:
		inst.queue_free()
		return {"ok": false, "error": "PackedScene.pack failed: " + str(pack_err)}
	var save_err := ResourceSaver.save(out, test_scene_path)
	inst.queue_free()
	return {"ok": save_err == OK, "path": test_scene_path, "error": "" if save_err == OK else "ResourceSaver.save failed: " + str(save_err)}


func _prepare_editable_bake_state() -> void:
	_bake_marker_ids.clear()
	_ensure_iso_structure()
	_sync_gameplay_layers_to_layout_root()
	_rebuild_marker_root_from_scene_nodes()
	_normalize_marker_positions_for_bake()
	_deduplicate_scene_markers()
	_reset_marker_index()
	set("auto_generate_from_definition", true)
	if mission_definition != null and mission_definition.has_method("set"):
		mission_definition.set("authoring_mode", "hybrid")
		mission_definition.set("layout_source_id", "scene_authored_tile_layers")
		mission_definition.set("marker_source_id", "scene_authored_marker_nodes")


func _deduplicate_scene_markers() -> void:
	var seen := {}
	for marker in _collect_authoring_markers_legacy(""):
		var marker_id := _value_string(marker.get("marker_id"))
		if marker_id == "":
			var replacement := _unique_bake_marker_id(_normalized_marker_type(_value_string(marker.get("marker_type"))), "marker", {})
			marker.set("marker_id", replacement)
			marker.name = replacement
			seen[replacement] = true
			continue
		if not seen.has(marker_id):
			seen[marker_id] = true
			continue
		var replacement_id := _unique_bake_marker_id(_normalized_marker_type(_value_string(marker.get("marker_type"))), marker_id, {})
		marker.set("marker_id", replacement_id)
		marker.name = replacement_id
		seen[replacement_id] = true


func _normalize_marker_positions_for_bake() -> void:
	for marker in _collect_authoring_markers_legacy(""):
		if not marker is Node2D:
			continue
		(marker as Node2D).global_position = _snap_marker_position((marker as Node2D).global_position)


func _strip_runtime_state_for_bake() -> void:
	var gameplay_roots := [
		"GameplayRoot/ObjectiveAreas",
		"GameplayRoot/ExitAreas",
		"GameplayRoot/SpawnPoints",
		"GameplayRoot/EnemyPaths",
		"GameplayRoot/RuntimeSystems/SpawnedGuards",
		"GameplayRoot/RuntimeSystems/SpawnedCameras",
		"GameplayRoot/RuntimeSystems/LightZones",
		"GameplayRoot/RuntimeSystems/DetectionZones",
		"GameplayRoot/RuntimeSystems/AlarmZones",
		"GameplayRoot/RuntimeSystems/EncounterZones",
		"GameplayRoot/RuntimeSystems/RouteAccessPoints",
		"GameplayRoot/RuntimeSystems/TransitionTriggers",
		"GameplayRoot/RuntimeSystems/DebugLabels",
		"GameplayRoot/RuntimeSystems/DebugUI",
	]
	for path in gameplay_roots:
		var node := get_node_or_null(path)
		if node != null:
			_clear_children_immediate(node)
	var entity := get_node_or_null("EntityRoot")
	if entity != null:
		for child in entity.get_children():
			if String(child.name) in ["Enemies", "Cameras", "Interactables", "DynamicProps"]:
				_clear_children_immediate(child)
			elif String(child.name) == "Player" or String(child.name).contains("Dog"):
				child.queue_free()
	var legacy := get_node_or_null("GameplayRoot/AuthoringMarkers")
	if legacy != null:
		_clear_children_immediate(legacy)
	var debug_panel := get_node_or_null("IsoMissionDebugPanel")
	if debug_panel != null:
		debug_panel.queue_free()


func _rebuild_marker_root_from_scene_nodes() -> void:
	_bake_marker_ids.clear()
	var marker_root := get_node_or_null("GameplayRoot/MarkerRoot") as Node2D
	if marker_root == null:
		return
	for category in MARKER_CATEGORIES:
		var bucket := marker_root.get_node_or_null(category)
		if bucket != null:
			_clear_children_immediate(bucket)
	var legacy := get_node_or_null("GameplayRoot/AuthoringMarkers")
	if legacy != null:
		_clear_children_immediate(legacy)
	_add_spawn_markers()
	_add_patrol_markers()
	_add_objective_markers()
	_add_clue_markers()
	_add_collectible_markers()
	_add_runtime_security_markers()
	_add_route_transition_markers()
	_add_exit_marker()


func _marker_bucket(category: String) -> Node2D:
	return get_node_or_null("GameplayRoot/MarkerRoot/" + category) as Node2D


func _add_editable_marker(category: String, type: String, marker_id: String, label: String, marker_position: Vector2, extra: Dictionary = {}) -> Node2D:
	var bucket := _marker_bucket(category)
	if bucket == null:
		return null
	var final_id := _unique_bake_marker_id(type, marker_id, extra)
	var marker := ISO_MARKER_SCRIPT.new() as Node2D
	marker.name = final_id
	marker.position = bucket.to_local(_snap_marker_position(marker_position))
	marker.set("marker_type", type)
	marker.set("marker_id", final_id)
	marker.set("display_name", label)
	for key in extra.keys():
		marker.set(key, extra[key])
	bucket.add_child(marker)
	marker.owner = self
	return marker


func _add_spawn_markers() -> void:
	var spawns := get_node_or_null("GameplayRoot/SpawnPoints") as Node2D
	if spawns != null:
		for child in spawns.get_children():
			var id := String(child.name)
			var marker_type := "player_spawn" if id.contains("start") or id == "default" else "transition_entry"
			var marker_id := id if marker_type == "player_spawn" else "spawn_" + id
			_add_editable_marker("Spawns", marker_type, marker_id, id.replace("_", " ").capitalize(), (child as Node2D).global_position, {
				"group_id": id
			})
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null:
		_add_editable_marker("Spawns", "player_spawn", "player_spawn_main", "PLAYER", player_node.global_position, {
			"group_id": "spawns"
		})
	var dog_node := get_tree().get_first_node_in_group("dog") as Node2D
	if dog_node != null:
		_add_editable_marker("Spawns", "bentley_spawn", "bentley_spawn_main", "BENTLEY", dog_node.global_position, {
			"group_id": "spawns"
		})
	elif player_node != null:
		_add_editable_marker("Spawns", "bentley_spawn", "bentley_spawn_main", "BENTLEY", player_node.global_position + Vector2(32, 16), {
			"group_id": "spawns"
		})
	for spawn_def in mission_definition.enemies:
		if spawn_def == null:
			continue
		if int(spawn_def.type) != 2:
			continue
		var sid := String(spawn_def.spawn_id)
		if not sid.contains("guard"):
			continue
		_add_editable_marker("Enemies", "guard_spawn", sid, "GUARD", _map_to_global(spawn_def.marker_cell), {
			"linked_guard_id": sid
		})


func _add_patrol_markers() -> void:
	var paths := get_node_or_null("GameplayRoot/EnemyPaths") as Node2D
	if paths == null:
		return
	for path_node in paths.get_children():
		if not path_node is Path2D:
			continue
		var path := path_node as Path2D
		var route_id := String(path.name)
		var linked_guard := route_id.replace("Patrol_", "")
		if path.curve == null:
			continue
		for i in range(path.curve.point_count):
			var world_pos := path.to_global(path.curve.get_point_position(i))
			_add_editable_marker("Patrols", "patrol_point", "patrol_%s_%02d" % [linked_guard.to_lower(), i + 1], "PATROL %d" % [i + 1], world_pos, {
				"linked_guard_id": linked_guard,
				"group_id": linked_guard,
				"order": i + 1
			})


func _add_objective_markers() -> void:
	var objectives := get_node_or_null("GameplayRoot/ObjectiveAreas") as Node2D
	if objectives == null:
		return
	for node in objectives.get_children():
		if not node is Node2D:
			continue
		var id := String(node.name).to_lower()
		var objective_id := _value_string(node.get("objective_id")) if node.has_method("get") else ""
		if objective_id == "":
			objective_id = _value_string(node.get("placeholder_id")) if node.has_method("get") else ""
		if objective_id == "":
			objective_id = String(node.name)
		var mtype := "objective"
		if id.contains("scenttrail"):
			mtype = "scent_trail_fake"
			if String(node.name).contains("Objective_follow_correct"):
				mtype = "scent_trail_real"
		elif id.contains("code"):
			mtype = "code_gate"
		var canonical := _canonical_objective_marker_id(objective_id, mtype)
		_add_editable_marker("Gates" if mtype == "code_gate" else "ScentTrails" if mtype.contains("scent") else "Objectives", mtype, canonical, String(node.name), (node as Node2D).global_position, {
			"linked_objective_id": objective_id,
		})


func _add_clue_markers() -> void:
	var interactables := get_node_or_null("EntityRoot/Interactables") as Node2D
	if interactables == null:
		return
	for node in interactables.get_children():
		if not node is Node2D:
			continue
		var clue_id := _value_string(node.get("clue_id")) if node.has_method("get") else ""
		if clue_id == "":
			continue
		_add_editable_marker("Clues", "clue", "clue_" + clue_id, "CLUE", (node as Node2D).global_position, {
			"linked_clue_id": clue_id
		})


func _add_collectible_markers() -> void:
	var interactables := get_node_or_null("EntityRoot/Interactables") as Node2D
	if interactables == null:
		return
	for node in interactables.get_children():
		if not node is Node2D:
			continue
		var node_name := String(node.name)
		if not node_name.begins_with("Collectible_"):
			continue
		var type := "polaroid_hidden"
		var display := "POLAROID"
		var collectible_id := _value_string(node.get("collectible_id")) if node.has_method("get") else ""
		if collectible_id == "":
			continue
		var low := collectible_id.to_lower()
		if low.contains("glow"):
			type = "glow_guy"
			display = "GLOW"
		elif low.contains("tiny_icon"):
			type = "tiny_icon"
			display = "TINY"
		elif low.contains("poop_bag"):
			type = "poop_bag"
			display = "POOP"
		elif low.contains("perfect"):
			type = "polaroid_perfect"
		_add_editable_marker("Collectibles", type, _canonical_collectible_marker_id(collectible_id), display, (node as Node2D).global_position, {
			"linked_collectible_id": collectible_id
		})


func _add_runtime_security_markers() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems") as Node2D
	if runtime == null:
		return
	var cameras := runtime.get_node_or_null("SpawnedCameras")
	if cameras != null:
		for node in cameras.get_children():
			if node is Node2D:
				_add_editable_marker("Cameras", "security_camera", String(node.name).to_lower(), "CAMERA", (node as Node2D).global_position, {
					"linked_camera_id": String(node.name).to_lower()
				})
	var alarm_zones := runtime.get_node_or_null("AlarmZones")
	if alarm_zones != null:
		for node in alarm_zones.get_children():
			if node is Node2D:
				_add_editable_marker("AlarmZones", "alarm_zone", String(node.name).to_lower(), "ALARM", (node as Node2D).global_position)
	var encounters := runtime.get_node_or_null("EncounterZones")
	if encounters != null:
		for node in encounters.get_children():
			if node is Node2D:
				_add_editable_marker("EncounterZones", "ambush_trigger", String(node.name).to_lower(), "AMBUSH", (node as Node2D).global_position)
	var light_zones := runtime.get_node_or_null("LightZones")
	if light_zones != null:
		for node in light_zones.get_children():
			if node is Node2D:
				var lower := String(node.name).to_lower()
				var kind := "shadow_zone"
				if lower.contains("bright"):
					kind = "bright_zone"
				elif lower.contains("flicker"):
					kind = "flicker_zone"
				_add_editable_marker("LightZones", kind, lower, "LIGHT", (node as Node2D).global_position)


func _add_route_transition_markers() -> void:
	var runtime := get_node_or_null("GameplayRoot/RuntimeSystems") as Node2D
	if runtime == null:
		return
	var routes := runtime.get_node_or_null("RouteAccessPoints")
	if routes != null:
		for node in routes.get_children():
			if node is Node2D:
				var route_id := _value_string(node.get("route_id")) if node.has_method("get") else ""
				if route_id == "":
					route_id = String(node.name).to_lower()
				var canonical_route := _canonical_route_marker_id(route_id)
				_add_editable_marker("Routes", "route_access", canonical_route, "ROUTE", (node as Node2D).global_position, {
					"linked_route_id": route_id
				})
	var transitions := runtime.get_node_or_null("TransitionTriggers")
	if transitions != null:
		for node in transitions.get_children():
			if node is Node2D:
				var transition_id := _value_string(node.get("transition_id")) if node.has_method("get") else ""
				if transition_id == "":
					transition_id = String(node.name).to_lower()
				_add_editable_marker("Transitions", "transition", "transition_" + transition_id, "TRANSITION", (node as Node2D).global_position, {
					"group_id": transition_id
				})


func _add_exit_marker() -> void:
	var exits := get_node_or_null("GameplayRoot/ExitAreas") as Node2D
	if exits == null:
		return
	for node in exits.get_children():
		if node is Node2D:
			_add_editable_marker("Exit", "exit", "exit_return_to_louis", "EXIT", (node as Node2D).global_position, {
				"group_id": "exit"
			})
			return


func _find_editable_marker_by_id(marker_id: String) -> Node2D:
	for marker in _collect_authoring_markers(""):
		if str(marker.get("marker_id")) == marker_id:
			return marker as Node2D
	return null


func _apply_hand_edit_test_mutations() -> void:
	var moved := {
		"poop_bag_dog_station": Vector2(120, 64),
		"garage_floor_1_guard_placeholder": Vector2(64, 48),
		"patrol_garage_floor_1_guard_placeholder_01": Vector2(32, -24),
		"patrol_garage_floor_1_guard_placeholder_02": Vector2(84, -36),
		"clue_velvet_paw_stamp": Vector2(-64, 52),
		"exit_return_to_louis": Vector2(56, -12),
	}
	for id in moved.keys():
		var marker := _find_editable_marker_by_id(id)
		if marker != null:
			var target: Vector2 = marker.global_position + moved[id]
			marker.global_position = _snap_marker_position(target)
	var cover := get_node_or_null("GameplayRoot/LayoutRoot/CoverLayer") as TileMapLayer
	if cover != null:
		cover.set_cell(Vector2i(8, 1), SOURCE_ID, TILE_COVER)
	var wall := get_node_or_null("GameplayRoot/LayoutRoot/WallLayer") as TileMapLayer
	if wall != null:
		var cells := wall.get_used_cells()
		if not cells.is_empty():
			wall.erase_cell(cells[0])
	_sync_layout_root_to_gameplay_layers()


func _ensure_owner_tree_for_bake() -> void:
	_assign_owner_recursive(self)


func _assign_owner_recursive(node: Node) -> void:
	for child in node.get_children():
		if child.owner == null:
			child.owner = self
		_assign_owner_recursive(child)


func _clear_children_immediate(node: Node) -> void:
	var children := node.get_children()
	for child in children:
		node.remove_child(child)
		child.free()


func _snap_marker_position(world_pos: Vector2) -> Vector2:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer == null:
		return world_pos
	var floor_cells := _cell_set(floor_layer.get_used_cells())
	if floor_cells.is_empty():
		return world_pos
	var collision_layer := get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	var blocked := _cell_set(collision_layer.get_used_cells()) if collision_layer != null else {}
	var origin := floor_layer.local_to_map(floor_layer.to_local(world_pos))
	if floor_cells.has(origin) and not blocked.has(origin):
		return world_pos
	var best_cell := origin
	var best_distance := INF
	for radius in range(1, 10):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var cell := Vector2i(x, y)
				if not floor_cells.has(cell) or blocked.has(cell):
					continue
				var dist := (Vector2(cell - origin)).length_squared()
				if dist < best_distance:
					best_distance = dist
					best_cell = cell
		if best_distance < INF:
			break
	return floor_layer.to_global(floor_layer.map_to_local(best_cell))


func _cell_set(cells: Array) -> Dictionary:
	var out := {}
	for cell in cells:
		out[cell] = true
	return out


func _value_string(value: Variant) -> String:
	if value == null:
		return ""
	var text := str(value).strip_edges()
	return "" if text == "<null>" else text


func _canonical_collectible_marker_id(collectible_id: String) -> String:
	var map := {
		"taco_bell_poop_bag_1": "poop_bag_dog_station",
		"taco_bell_poop_bag_2": "poop_bag_garage_pet_bin",
		"taco_bell_poop_bag_3": "poop_bag_lobby_trash",
		"taco_bell_glow_guys": "glow_guy_garage_stairs",
		"louis_tiny_icon_delivery_bag": "tiny_icon_louis_delivery",
		"taco_bell_midnight_market_rain": "hidden_polaroid_market_rain",
		"taco_bell_perfect_ambush": "perfect_polaroid_garage_ambush",
		"garage_staff_keycard": "keycard_garage_staff",
	}
	return map.get(collectible_id, collectible_id)


func _canonical_objective_marker_id(objective_id: String, marker_type: String) -> String:
	var map := {
		"follow_correct_bentley_scent_trail": "scent_real_parking_garage",
		"recover_decoy_bag_extra_intel": "scent_fake_loading_dock",
		"complete_without_wrong_scent_trail": "scent_fake_trash_area",
		"solve_garage_office_code": "code_gate_garage_office",
	}
	if map.has(objective_id):
		return map[objective_id]
	return marker_type + "_" + objective_id


func _canonical_route_marker_id(route_id: String) -> String:
	if route_id.contains("vent"):
		return "route_bentley_vent"
	if route_id.contains("louis"):
		return "route_louis_delivery_future"
	return "route_" + route_id


func _unique_bake_marker_id(marker_type: String, base_id: String, extra: Dictionary) -> String:
	var candidate := base_id.strip_edges()
	if candidate == "":
		candidate = marker_type + "_" + _value_string(extra.get("linked_objective_id", extra.get("linked_collectible_id", extra.get("linked_clue_id", "marker"))))
	var key := candidate
	if not _bake_marker_ids.has(key):
		_bake_marker_ids[key] = 1
		return key
	var idx := int(_bake_marker_ids[key]) + 1
	_bake_marker_ids[key] = idx
	return "%s_%02d" % [candidate, idx]


func _map_to_global(cell: Vector2i) -> Vector2:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer:
		return floor_layer.to_global(floor_layer.map_to_local(cell))
	return Vector2(cell.x * 64, cell.y * 32)


func _initial_objective_text() -> String:
	if mission_definition.primary_objectives.is_empty():
		return "Explore the isometric mission blockout."
	var objective = mission_definition.primary_objectives[0]
	if objective == null:
		return "Explore the isometric mission blockout."
	var base_text := String(objective.display_text)
	var fails := int(GameState.failed_attempts.get(mission_definition.mission_id, 0))
	var heat := GameState.get_mission_heat(mission_definition.mission_id)
	if heat >= 3 or fails >= 3:
		return base_text + " Louis hint (tier 3): real scent leads garage-ward, code clue sits in office paperwork."
	if heat >= 2 or fails >= 2:
		return base_text + " Louis hint (tier 2): ignore sneeze trails; use the Sterling-smelling path."
	if fails >= 1:
		return base_text + " Louis hint (tier 1): check trail reactions and route manifest logic."
	return base_text


func _apply_heat_profile() -> void:
	var heat := GameState.get_mission_heat(mission_definition.mission_id)
	var profile := {
		"wrong_code_threshold": 2,
		"camera_rate_mult": 1.0,
		"camera_sweep_mult": 1.0,
		"extra_camera": false,
		"extra_guard_pressure": false,
		"fake_scent_penalty": 1,
	}
	if heat == 1:
		profile["camera_rate_mult"] = 1.08
		profile["camera_sweep_mult"] = 1.12
	elif heat == 2:
		profile["wrong_code_threshold"] = 2
		profile["camera_rate_mult"] = 1.22
		profile["camera_sweep_mult"] = 1.3
		profile["extra_camera"] = true
		profile["extra_guard_pressure"] = true
		profile["fake_scent_penalty"] = 2
	elif heat >= 3:
		profile["wrong_code_threshold"] = 1
		profile["camera_rate_mult"] = 1.38
		profile["camera_sweep_mult"] = 1.55
		profile["extra_camera"] = true
		profile["extra_guard_pressure"] = true
		profile["fake_scent_penalty"] = 2
	_heat_profile = profile
	_active_mutations["wrong_code_threshold"] = int(profile.get("wrong_code_threshold", 2))
	_active_mutations["camera_rate_mult"] = float(profile.get("camera_rate_mult", 1.0))
	_active_mutations["camera_sweep_mult"] = float(profile.get("camera_sweep_mult", 1.0))
	_active_mutations["extra_camera_active"] = profile.get("extra_camera", false) == true
	_active_mutations["extra_guard_pressure"] = profile.get("extra_guard_pressure", false) == true
	_active_mutations["fake_scent_penalty"] = int(profile.get("fake_scent_penalty", 1))


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


func _sync_layout_root_to_gameplay_layers() -> void:
	var mode := get_authoring_mode()
	if mode != "hybrid" and mode != "scene_authored":
		return
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var collision_layer := get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	var marker_layer := get_node_or_null("GameplayRoot/GameplayMarkersLayer") as TileMapLayer
	var layout_floor := get_node_or_null("GameplayRoot/LayoutRoot/FloorLayer") as TileMapLayer
	var layout_wall := get_node_or_null("GameplayRoot/LayoutRoot/WallLayer") as TileMapLayer
	var layout_cover := get_node_or_null("GameplayRoot/LayoutRoot/CoverLayer") as TileMapLayer
	var layout_barrier := get_node_or_null("GameplayRoot/LayoutRoot/CollisionBarrierLayer") as TileMapLayer
	var layout_markers := get_node_or_null("GameplayRoot/LayoutRoot/MarkerTileLayer") as TileMapLayer
	if floor_layer == null or collision_layer == null or layout_floor == null:
		return
	if layout_floor.get_used_cells().is_empty() and layout_wall != null and layout_wall.get_used_cells().is_empty():
		return
	floor_layer.clear()
	collision_layer.clear()
	if marker_layer != null:
		marker_layer.clear()
	for cell in layout_floor.get_used_cells():
		floor_layer.set_cell(cell, SOURCE_ID, TILE_FLOOR)
	if layout_wall != null:
		for cell in layout_wall.get_used_cells():
			collision_layer.set_cell(cell, SOURCE_ID, TILE_WALL)
	if layout_cover != null:
		for cell in layout_cover.get_used_cells():
			collision_layer.set_cell(cell, SOURCE_ID, TILE_COVER)
	if layout_barrier != null:
		for cell in layout_barrier.get_used_cells():
			collision_layer.set_cell(cell, SOURCE_ID, TILE_WALL)
	if marker_layer != null and layout_markers != null:
		for cell in layout_markers.get_used_cells():
			var atlas := layout_markers.get_cell_atlas_coords(cell)
			if atlas != Vector2i(-1, -1):
				marker_layer.set_cell(cell, SOURCE_ID, atlas)


func _sync_gameplay_layers_to_layout_root() -> void:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var collision_layer := get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	var marker_layer := get_node_or_null("GameplayRoot/GameplayMarkersLayer") as TileMapLayer
	var layout_floor := get_node_or_null("GameplayRoot/LayoutRoot/FloorLayer") as TileMapLayer
	var layout_wall := get_node_or_null("GameplayRoot/LayoutRoot/WallLayer") as TileMapLayer
	var layout_cover := get_node_or_null("GameplayRoot/LayoutRoot/CoverLayer") as TileMapLayer
	var layout_barrier := get_node_or_null("GameplayRoot/LayoutRoot/CollisionBarrierLayer") as TileMapLayer
	var layout_markers := get_node_or_null("GameplayRoot/LayoutRoot/MarkerTileLayer") as TileMapLayer
	if floor_layer == null or collision_layer == null or layout_floor == null:
		return
	layout_floor.clear()
	if layout_wall != null:
		layout_wall.clear()
	if layout_cover != null:
		layout_cover.clear()
	if layout_barrier != null:
		layout_barrier.clear()
	if layout_markers != null:
		layout_markers.clear()
	for cell in floor_layer.get_used_cells():
		layout_floor.set_cell(cell, SOURCE_ID, TILE_FLOOR)
	for cell in collision_layer.get_used_cells():
		var atlas := collision_layer.get_cell_atlas_coords(cell)
		if atlas == TILE_WALL and layout_wall != null:
			layout_wall.set_cell(cell, SOURCE_ID, TILE_WALL)
		elif atlas == TILE_COVER and layout_cover != null:
			layout_cover.set_cell(cell, SOURCE_ID, TILE_COVER)
	if marker_layer != null and layout_markers != null:
		for cell in marker_layer.get_used_cells():
			var atlas := marker_layer.get_cell_atlas_coords(cell)
			if atlas != Vector2i(-1, -1):
				layout_markers.set_cell(cell, SOURCE_ID, atlas)


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
