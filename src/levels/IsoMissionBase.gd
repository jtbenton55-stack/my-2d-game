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
## D6-01-FIX7D: collision-derived vertical beam (rays at choke X; wall overlap). No numeric choke guessing on success path.
const D6_FIX7D_AMBUSH_BEAM_VISUAL_WIDTH := 32.0
const D6_FIX7D_AMBUSH_BEAM_TRIGGER_WIDTH := 72.0
## Slight penetration into TileMap/static collision so the line reads wall-to-wall.
const D6_FIX7D_AMBUSH_BEAM_WALL_OVERLAP_PX := 36.0
const D6_FIX7D_RAY_PROBE_LENGTH := 4200.0
## Match player CharacterBody2D obstacle mask (see player.tscn collision_mask = 7).
const D6_FIX7D_COLLISION_MASK := 7
const D6_FIX7D_MIN_CORRIDOR_HEIGHT := 64.0
## Emergency only — explicit fallback if vertical ray probes fail (F10 reports mode=fallback).
const D6_FIX7D_FALLBACK_ANCHOR_OFFSET := Vector2(-380.0, -48.0)
const D6_FIX7D_FALLBACK_HEIGHT := 840.0
## D6-01-FIX7E: inner walkable A–B vertical span at choke X (single probe; no largest-gap sweep).
## Visual uses inner collision hits; trigger extends slightly beyond visual for reliable beam_trip.
const D6_FIX7E_AMBUSH_BEAM_VISUAL_WIDTH := 32.0
const D6_FIX7E_AMBUSH_BEAM_TRIGGER_WIDTH := 72.0
const D6_FIX7E_VISUAL_WALL_OVERLAP_PX := 0.0
const D6_FIX7E_TRIGGER_WALL_OVERLAP_PX := 8.0
const D6_FIX7E_RAY_PROBE_LENGTH := 2200.0
const D6_FIX7E_COLLISION_MASK := 7
const D6_FIX7E_MIN_VISUAL_HEIGHT := 96.0
const D6_FIX7E_MAX_VISUAL_HEIGHT := 520.0
const D6_FIX7E_FALLBACK_VISUAL_HEIGHT := 360.0
const D6_FIX7E_FALLBACK_TRIGGER_HEIGHT := 400.0
const D6_FIX7E_INNER_GAP_MIN_EPS := 4.0
## D6-01-FIX7F: search doorway rectangle (candidate X/Y grid + shape overlap rejection).
const D6_FIX7F_AMBUSH_BEAM_VISUAL_WIDTH := 32.0
const D6_FIX7F_AMBUSH_BEAM_TRIGGER_WIDTH := 72.0
const D6_FIX7F_VISUAL_WALL_OVERLAP_PX := 0.0
const D6_FIX7F_TRIGGER_WALL_OVERLAP_PX := 8.0
const D6_FIX7F_RAY_PROBE_LENGTH := 180.0
const D6_FIX7F_COLLISION_MASK := 7
const D6_FIX7F_MIN_VISUAL_HEIGHT := 48.0
const D6_FIX7F_MAX_VISUAL_HEIGHT := 520.0
const D6_FIX7F_FALLBACK_VISUAL_HEIGHT := 280.0
const D6_FIX7F_FALLBACK_TRIGGER_HEIGHT := 296.0
const D6_FIX7F_SEARCH_X_MIN_OFFSET := -192.0
const D6_FIX7F_SEARCH_X_MAX_OFFSET := 128.0
const D6_FIX7F_SEARCH_X_STEP := 16.0
const D6_FIX7F_SEARCH_Y_RANGE := 160.0
const D6_FIX7F_SEARCH_Y_STEP := 24.0
const D6_FIX7F_IDEAL_VISUAL_HEIGHT := 220.0
## D6-01-D6-02: hand-placed security authoring (editor source of truth when present).
const D6_02_SECURITY_AUTHORING_ROOT_PATH := "GameplayRoot/SecurityAuthoringRoot"
const D6_03_MISSION_AUTHORING_BUILDER := preload("res://src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd")
const D6_06_COLLECTIBLE_BUILDER := preload("res://src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd")
const D6_06_HIDEOUT_SYNC := preload("res://src/missions/iso/runtime/MissionCollectibleHideoutSync.gd")
const D6_06_PERSIST := preload("res://src/missions/iso/runtime/MissionAuthoredCollectiblePersistence.gd")
const TYPED_MISSION_COLLECTIBLE := preload("res://src/missions/iso/TypedMissionCollectible.gd")
## Missions that may use Phase0K Louis exit when formal IsoMission objectives are incomplete.
## Do not add new missions here without an explicit design review.
const PHASE0K_LOUIS_EXIT_FALLBACK_MISSION_IDS: Array[String] = ["taco_bell_drop"]
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
var _dialogue_provider: MissionDialogueProvider = null
## D6-01-FIX3: queue security spawns so `add_child`/guard setup never runs during Area2D query flush.
var _pending_security_guard_source_ids: Array[String] = []
var _security_guard_spawn_flush_scheduled: bool = false
var _security_spawn_probe: Dictionary = {}
## D6-01-FIX6A: reinforcement cooldown tracking to prevent low-heat chain spawning.
var _last_security_reinforcement_request_msec: int = -60000
var _last_security_reinforcement_source: String = ""
var _last_security_reinforcement_result: String = ""
## D6-03: mission-local security event router for authoring triggers/responses.
var _security_event_router: Node = null
## D6-06B: authored collectibles collected this attempt (committed on mission success only).
var _d6_06_pending_collectibles: Array[Dictionary] = []
## D6-06D: prevents double-commit if multiple success paths fire in one attempt.
var _d6_06_authored_commit_applied := false


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
	call_deferred("_ensure_d6_fix5_runtime_helpers")


## D6-01-FIX6B: override _process to update guard lifecycle management.
func _process(delta: float) -> void:
	super._process(delta)
	_update_security_guard_lifecycle(delta)


func get_authoring_mode() -> String:
	if mission_definition != null and mission_definition.has_method("get"):
		return String(mission_definition.get("authoring_mode"))
	return "generated"


func validate_blockout() -> Dictionary:
	if mission_definition == null:
		return {"ok": false, "errors": ["MissionDefinition is null."], "warnings": [], "debug": {}}
	return MissionBlockoutValidator.validate(mission_definition, self)


func _resolve_dialogue_provider() -> MissionDialogueProvider:
	if _dialogue_provider != null:
		return _dialogue_provider
	var mid := String(get_mission_id()).to_lower()
	if mid.contains("taco"):
		var script: Script = load("res://src/missions/taco_bell/TacoBellDialogueProvider.gd") as Script
		if script != null:
			_dialogue_provider = script.new() as MissionDialogueProvider
	if _dialogue_provider == null:
		_dialogue_provider = MissionDialogueProvider.new()
	return _dialogue_provider


func get_mission_dialogue_provider() -> MissionDialogueProvider:
	return _resolve_dialogue_provider()


func _mission_dialogue_line(dialogue_id: String, fallback_text: String, fallback_speaker: String = "Mission") -> Dictionary:
	var provider := _resolve_dialogue_provider()
	if provider == null:
		return {"ok": true, "speaker": fallback_speaker, "text": fallback_text, "sequence": [], "reason": "no_provider"}
	return provider.get_dialogue_line(dialogue_id, {"fallback_text": fallback_text, "fallback_speaker": fallback_speaker})


func supports_tool(tool_id: String) -> bool:
	return tool_id == MissionToolSurfaceHelper.TOOL_POOP_BAG


func handle_tool_use(tool_id: String, payload: Dictionary = {}) -> Dictionary:
	if tool_id == MissionToolSurfaceHelper.TOOL_POOP_BAG:
		var wp: Vector2 = payload.get("world_pos", Vector2.ZERO) as Vector2
		var ok := deploy_poop_bag_decoy_at(wp)
		return {
			"ok": ok,
			"handled": true,
			"reason": "" if ok else "deploy_rejected",
			"tool_id": tool_id,
			"effect": "poop_decoy",
			"payload": payload,
		}
	return {
		"ok": false,
		"handled": false,
		"reason": "unknown_tool",
		"tool_id": tool_id,
		"effect": "",
		"payload": payload,
	}


func get_tool_surface_id() -> String:
	return "iso_mission_base"


func reset_tool_surface_runtime_state() -> void:
	pass


## Documented entry point for attempt-local runtime (see phase0md1b_attempt_reset_contract). Normal completion/failure uses SceneManager scene reload.
func reset_mission_runtime_for_new_attempt() -> void:
	var live_security_clear := _clear_d5_attempt_live_security_runtime()
	_setup_runtime_systems()
	var mid := get_mission_id()
	var objective_reset := MissionObjectiveBridge.reset_runtime_objectives_for_mission(mid)
	var security_beam_runtime := _ensure_d5_attempt_security_beam_runtime()
	var security_reset := _reset_d5_attempt_security_runtime()
	var interactable_reset := _reset_d5_attempt_interactables()
	var phase0k_reset := _reset_phase0k_attempt_state()
	set_meta("d5_01_attempt_reset", {
		"mission_id": mid,
		"live_security_clear": live_security_clear,
		"objective_reset": objective_reset,
		"security_beam_runtime": security_beam_runtime,
		"security_reset": security_reset,
		"interactable_reset": interactable_reset,
		"phase0k_reset": phase0k_reset,
	})


func _clear_d5_attempt_live_security_runtime() -> Dictionary:
	var removed_cameras: Array[String] = []
	var removed_guards: Array[String] = []
	_pending_security_guard_source_ids.clear()
	_security_guard_spawn_flush_scheduled = false
	var cameras := get_node_or_null("EntityRoot/Cameras") as Node
	if cameras != null:
		for child in cameras.get_children():
			if not (child is Node):
				continue
			var node := child as Node
			removed_cameras.append(str(node.get_path()))
			cameras.remove_child(node)
			node.queue_free()
	var enemies := get_node_or_null("EntityRoot/Enemies") as Node
	if enemies != null:
		for child in enemies.get_children():
			if not (child is Node):
				continue
			var node := child as Node
			if not _is_d5_attempt_security_guard_node(node):
				continue
			removed_guards.append(str(node.get_path()))
			enemies.remove_child(node)
			node.queue_free()
	return {
		"ok": true,
		"code": "d5_attempt_live_security_runtime_cleared",
		"removed_cameras": removed_cameras,
		"removed_guards": removed_guards,
	}


func _is_d5_attempt_security_guard_node(node: Node) -> bool:
	if node == null:
		return false
	if node.get_meta("d5_attempt_runtime_guard", false) == true:
		return true
	if node.get_meta("security_response_spawn", false) == true:
		return true
	if node.get_meta("security_response_guard", false) == true:
		return true
	return node.has_meta("author_spawn_id")


func _ensure_d5_attempt_security_beam_runtime() -> Dictionary:
	if mission_definition != null and String(mission_definition.mission_id) == "taco_bell_drop":
		var tree := get_tree()
		if tree != null and tree.physics_frame.is_connected(_setup_fix7_ambush_beam_runtime):
			tree.physics_frame.disconnect(_setup_fix7_ambush_beam_runtime)
		_remove_fix7_stale_temp_beam_nodes()
		_setup_fix7_ambush_beam_runtime()
	var armed_nodes: Array[String] = []
	var alarm_zones := get_node_or_null("GameplayRoot/RuntimeSystems/AlarmZones") as Node
	if alarm_zones != null:
		var beam_alarm_ids: Array[String] = ["AMBUSH_security_beam", "garage_entry_beam"]
		for alarm_id in beam_alarm_ids:
			var area := alarm_zones.get_node_or_null("AlarmZone_%s" % alarm_id) as Area2D
			if area == null or area.is_queued_for_deletion():
				continue
			_arm_d5_attempt_alarm_area(area, alarm_id)
			armed_nodes.append(str(area.get_path()))
	return {
		"ok": true,
		"code": "d5_attempt_security_beam_runtime_ready",
		"armed_beam_nodes": armed_nodes,
	}


func _reset_d5_attempt_security_runtime() -> Dictionary:
	var reset_nodes: Array[String] = []
	var removed_guards: Array[String] = []
	var alarm_zones := get_node_or_null("GameplayRoot/RuntimeSystems/AlarmZones") as Node
	if alarm_zones != null:
		for child in alarm_zones.get_children():
			var area := child as Area2D
			if area == null:
				continue
			var alarm_id := String(area.name).replace("AlarmZone_", "")
			if not _is_alarm_zone_one_shot(alarm_id):
				continue
			_arm_d5_attempt_alarm_area(area, alarm_id)
			reset_nodes.append(str(area.get_path()))
	var enemies := get_node_or_null("EntityRoot/Enemies") as Node
	if enemies != null:
		for child in enemies.get_children():
			if not (child is Node):
				continue
			var node := child as Node
			if node.get_meta("security_response_spawn", false) != true and node.get_meta("security_response_guard", false) != true:
				continue
			removed_guards.append(str(node.get_path()))
			enemies.remove_child(node)
			node.queue_free()
	return {
		"ok": true,
		"code": "d5_attempt_security_runtime_reset",
		"rearmed_alarm_zones": reset_nodes,
		"removed_response_guards": removed_guards,
	}


func _arm_d5_attempt_alarm_area(area: Area2D, alarm_id: String) -> void:
	if area == null:
		return
	var entered_callable := Callable(self, "_on_runtime_alarm_zone_entered").bind(alarm_id, area)
	if not area.body_entered.is_connected(entered_callable):
		area.body_entered.connect(entered_callable)
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 1
	for child in area.get_children():
		var shape := child as CollisionShape2D
		if shape != null:
			shape.disabled = false
	area.monitoring = true


func _reset_d5_attempt_interactables() -> Dictionary:
	var reset_nodes: Array[String] = []
	var state_adapter := get_node_or_null("GameplayRoot/RuntimeHelpers/Phase0JMissionStateAdapter")
	if state_adapter != null and state_adapter.has_method("reset_attempt_state"):
		state_adapter.call("reset_attempt_state")
		reset_nodes.append(str(state_adapter.get_path()))
	for node in get_tree().get_nodes_in_group("phase0k_delivery_bag"):
		if node != null and node.has_method("reset_attempt_state"):
			node.call("reset_attempt_state")
			reset_nodes.append(str(node.get_path()))
	for node in get_tree().get_nodes_in_group("phase0j_interactable"):
		if node == null or not node.has_method("reset_attempt_state"):
			continue
		if _node_string_property(node, "candidate_id") != "OBJ_bag_recovery":
			continue
		node.call("reset_attempt_state")
		reset_nodes.append(str(node.get_path()))
	return {"ok": true, "code": "d5_attempt_interactables_reset", "nodes": reset_nodes}


func _node_string_property(node: Node, property_name: String) -> String:
	for property in node.get_property_list():
		if str(property.get("name", "")) != property_name:
			continue
		var value: Variant = node.get(property_name)
		if value == null:
			return ""
		return str(value)
	return ""


func _reset_phase0k_attempt_state() -> Dictionary:
	var controller := get_node_or_null("GameplayRoot/RuntimeHelpers/Phase0KMissionCompletionController")
	if controller == null:
		return {"ok": true, "code": "phase0k_controller_not_present"}
	if not controller.has_method("reset_attempt_state"):
		return {"ok": false, "code": "phase0k_reset_missing"}
	var result: Variant = controller.call("reset_attempt_state")
	if result is Dictionary:
		return result as Dictionary
	return {"ok": true, "code": "phase0k_reset_called"}


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
	## Pre-validate synchronously; defer `add_child`/guard mutations to avoid
	## "Can't change this state while flushing queries" when called from Area2D/camera paths.
	## D6-01-FIX6A: enforce heat-scaled reinforcement cooldown to prevent chain spawning at low heat.
	if not can_spawn_alarm_guard_for_source(source_id):
		_record_security_reinforcement_request(source_id, false, "source_blocked_by_policy")
		return
	if not _can_request_security_reinforcement(source_id, "spawn_request"):
		var cooldown_sec := _get_security_reinforcement_cooldown_sec()
		EventBus.debug("spawn_attack_guard_near_player: cooldown active (%.1fs) for %s" % [cooldown_sec, source_id])
		_record_security_reinforcement_request(source_id, false, "cooldown_active")
		return
	var cap := _get_security_spawn_cap()
	var live := _count_live_security_response_guards()
	var reserved := _get_reserved_security_guard_count()
	if (live + reserved) >= cap:
		EventBus.debug("spawn_attack_guard_near_player: cap reached (live=%d reserved=%d cap=%d)" % [live, reserved, cap])
		_record_security_reinforcement_request(source_id, false, "cap_full")
		return
	if get_tree().get_first_node_in_group("player") == null:
		_record_security_reinforcement_request(source_id, false, "no_player")
		return
	_record_security_reinforcement_request(source_id, true, "")
	_pending_security_guard_source_ids.append(source_id)
	if not _security_guard_spawn_flush_scheduled:
		_security_guard_spawn_flush_scheduled = true
		call_deferred("_flush_deferred_security_guard_spawns")


func _flush_deferred_security_guard_spawns() -> void:
	_security_guard_spawn_flush_scheduled = false
	var cap := _get_security_spawn_cap()
	while _pending_security_guard_source_ids.size() > 0:
		var source_id: String = _pending_security_guard_source_ids.pop_front()
		if not can_spawn_alarm_guard_for_source(source_id):
			_record_security_spawn_probe({
				"source_id": source_id,
				"result": "rejected",
				"reject_reason": "source_blocked_by_policy",
				"cap": cap,
				"queued_count": _pending_security_guard_source_ids.size(),
			})
			continue
		var live_now := _count_functional_security_response_guards()
		if live_now >= cap:
			EventBus.debug("_flush_deferred_security_guard_spawns: cap reached (live=%d cap=%d)" % [live_now, cap])
			_record_security_spawn_probe({
				"source_id": source_id,
				"result": "rejected",
				"reject_reason": "functional_cap_reached",
				"functional_live_count": live_now,
				"raw_live_count": _count_raw_security_response_guards(),
				"invalid_offmap_security_guard_count": _count_invalid_security_response_guards(),
				"cap": cap,
				"queued_count": _pending_security_guard_source_ids.size(),
			})
			break
		var player_node := get_tree().get_first_node_in_group("player") as Node2D
		if player_node == null:
			_record_security_spawn_probe({
				"source_id": source_id,
				"result": "rejected",
				"reject_reason": "player_not_found",
				"cap": cap,
				"queued_count": _pending_security_guard_source_ids.size(),
			})
			break
		var spawn_choice := _choose_security_response_spawn_position(source_id, player_node.global_position)
		var requested: Vector2 = spawn_choice.get("requested_position", player_node.global_position)
		var chosen: Vector2 = spawn_choice.get("chosen_position", player_node.global_position)
		var spawn_mode := String(spawn_choice.get("mode", "rejected"))
		var spawn_reason := String(spawn_choice.get("reason", ""))
		if not bool(spawn_choice.get("valid", false)):
			_record_security_spawn_probe({
				"source_id": source_id,
				"requested_position": requested,
				"chosen_position": chosen,
				"actual_position": chosen,
				"spawn_mode": spawn_mode,
				"result": "rejected",
				"reject_reason": spawn_reason,
				"last_spawn_distance_to_player": chosen.distance_to(player_node.global_position),
				"cap": cap,
				"queued_count": _pending_security_guard_source_ids.size(),
			})
			continue
		var spawn_def := MissionSpawnDefinition.new()
		spawn_def.spawn_id = "attack_guard_" + source_id + "_" + str(Time.get_ticks_msec())
		spawn_def.marker_cell = _global_to_map_cell(chosen)
		spawn_def.scene_path = MissionSecurityGuardResolver.good_guard_scene_path()
		var guard := _spawn_guard_for_spawn(spawn_def)
		if guard == null:
			EventBus.debug("_flush_deferred_security_guard_spawns: spawn failed for " + source_id)
			_record_security_spawn_probe({
				"source_id": source_id,
				"requested_position": requested,
				"chosen_position": chosen,
				"actual_position": chosen,
				"spawn_mode": spawn_mode,
				"guard_scene_path": spawn_def.scene_path,
				"result": "failed",
				"reject_reason": "spawn_guard_for_spawn_returned_null",
				"cap": cap,
				"queued_count": _pending_security_guard_source_ids.size(),
			})
			continue
		_finalize_security_guard_position(guard, chosen)
		guard.set_meta("security_response_spawn", true)
		guard.set_meta("security_spawn_source", source_id)
		guard.set_meta("security_chase_soft", true)
		guard.set_meta("security_spawn_mode", spawn_mode)
		guard.set_meta("security_spawn_reason", spawn_reason)
		if guard.has_method("set"):
			guard.set("target", player_node)
			guard.set("aggro_range", maxf(float(guard.get("aggro_range")), 440.0))
		_assign_fallback_patrol_for_security_guard(guard, chosen)
		var final_ok := _finalize_security_guard_position(guard, chosen)
		var functional := final_ok and _is_guard_functional_for_cap(guard as Node2D)
		if not functional:
			var actual_bad := guard.global_position if guard != null else chosen
			guard.set_meta("security_invalid_reason", "actual_position_diverged_or_not_functional")
			guard.set_meta("security_response_spawn", false)
			if is_instance_valid(guard):
				guard.queue_free()
			_record_security_spawn_probe({
				"source_id": source_id,
				"requested_position": requested,
				"chosen_position": chosen,
				"actual_position": actual_bad,
				"spawn_mode": spawn_mode,
				"parent_path": "EntityRoot/Enemies",
				"guard_scene_path": spawn_def.scene_path,
				"result": "rejected",
				"reject_reason": "actual_position_diverged_or_not_functional",
				"invalid_offmap_security_guard_count": _count_invalid_security_response_guards(),
				"cap": cap,
				"queued_count": _pending_security_guard_source_ids.size(),
			})
			continue
		GameState.record_mission_performance_event(mission_definition.mission_id, "guards_alerted", 1)
		_attempt_runtime_state["guards_alerted"] = int(_attempt_runtime_state.get("guards_alerted", 0)) + 1
		_attempt_runtime_state["attack_guard_spawned"] = _count_functional_security_response_guards()
		if source_id.begins_with("alarm_"):
			_attempt_runtime_state["alarm_guard_spawned:" + source_id] = true
		## D6-01-FIX6B: capture search net role and heat for F10 debug.
		var heat_at_spawn := GameState.get_mission_heat(mission_definition.mission_id)
		var ordinal_at_spawn := _count_functional_security_response_guards()
		var role_at_spawn := _get_security_search_role(heat_at_spawn, ordinal_at_spawn)
		_record_security_spawn_probe({
			"source_id": source_id,
			"requested_position": requested,
			"chosen_position": chosen,
			"actual_position": guard.global_position,
			"spawn_mode": spawn_mode,
			"parent_path": "EntityRoot/Enemies",
			"guard_scene_path": spawn_def.scene_path,
			"result": "success",
			"reject_reason": spawn_reason,
			"last_spawn_distance_to_player": guard.global_position.distance_to(player_node.global_position),
			"functional_live_count": _count_functional_security_response_guards(),
			"raw_live_count": _count_raw_security_response_guards(),
			"invalid_offmap_security_guard_count": _count_invalid_security_response_guards(),
			"cap": cap,
			"queued_count": _pending_security_guard_source_ids.size(),
			## D6-01-FIX6B search net debug.
			"last_heat": heat_at_spawn,
			"last_ordinal": ordinal_at_spawn,
			"last_role": role_at_spawn,
		})


func _get_security_spawn_cap() -> int:
	var heat := GameState.get_mission_heat(_debug_mission_id())
	return mini(6, 4 + heat)


## D6-01-FIX6A: heat-scaled reinforcement cooldown to prevent low-heat chain spawning.
## Heat 0–1: 6.0 sec, Heat 2–3: 4.5 sec, Heat 4: 3.0 sec, Heat 5: 2.0 sec
func _get_security_reinforcement_cooldown_sec() -> float:
	var heat := GameState.get_mission_heat(_debug_mission_id())
	if heat <= 1:
		return 6.0
	elif heat <= 3:
		return 4.5
	elif heat == 4:
		return 3.0
	else:
		return 2.0


func _debug_mission_id() -> String:
	return String(mission_definition.mission_id) if mission_definition != null else get_mission_id()


## D6-01-FIX6A: check whether a reinforcement request is allowed given cooldown/cap/queue.
func _can_request_security_reinforcement(_source_id: String, _reason: String = "") -> bool:
	var cooldown_ms := int(_get_security_reinforcement_cooldown_sec() * 1000.0)
	var now := Time.get_ticks_msec()
	var elapsed := now - _last_security_reinforcement_request_msec
	if elapsed < cooldown_ms:
		return false
	var cap := _get_security_spawn_cap()
	var functional := _count_functional_security_response_guards()
	var reserved := _get_reserved_security_guard_count()
	if (functional + reserved) >= cap:
		return false
	return true


## D6-01-FIX6A: count pending queued spawns toward cap to prevent over-commitment.
func _get_reserved_security_guard_count() -> int:
	return _pending_security_guard_source_ids.size()


## D6-01-FIX6A: record reinforcement request for F10/debug visibility.
func _record_security_reinforcement_request(source_id: String, accepted: bool, reason: String = "") -> void:
	_last_security_reinforcement_request_msec = Time.get_ticks_msec()
	_last_security_reinforcement_source = source_id
	_last_security_reinforcement_result = "accepted" if accepted else ("rejected: " + reason)


func _count_live_security_response_guards() -> int:
	return _count_functional_security_response_guards()


func _count_raw_security_response_guards() -> int:
	var enemies := get_node_or_null("EntityRoot/Enemies")
	if enemies == null:
		return 0
	var n := 0
	for ch in enemies.get_children():
		if not (ch is Node2D):
			continue
		if not is_instance_valid(ch):
			continue
		if not ch.is_inside_tree():
			continue
		if ch.get_meta("security_response_spawn", false) != true:
			continue
		n += 1
	return n


func _count_functional_security_response_guards() -> int:
	var enemies := get_node_or_null("EntityRoot/Enemies")
	if enemies == null:
		return 0
	var n := 0
	for ch in enemies.get_children():
		if not (ch is Node2D):
			continue
		var guard := ch as Node2D
		if _is_guard_functional_for_cap(guard):
			n += 1
	return n


func _count_invalid_security_response_guards() -> int:
	var enemies := get_node_or_null("EntityRoot/Enemies")
	if enemies == null:
		return 0
	var n := 0
	for ch in enemies.get_children():
		if not (ch is Node2D):
			continue
		var guard := ch as Node2D
		if guard.get_meta("security_response_spawn", false) != true:
			continue
		if not _is_guard_functional_for_cap(guard):
			n += 1
	return n


func _is_guard_functional_for_cap(guard: Node2D) -> bool:
	if guard == null:
		return false
	if not is_instance_valid(guard):
		return false
	if not guard.is_inside_tree():
		return false
	if guard.get_meta("security_response_spawn", false) != true:
		return false
	if not _is_guard_visibility_chain_visible(guard):
		return false
	var p := guard.global_position
	if not _is_spawn_position_sane(p):
		return false
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null and p.distance_to(player_node.global_position) > 760.0:
		return false
	return true


## D6-01-FIX6B: performance-safe lifecycle management for security-response guards.
## Tracks and optionally removes distant inactive guards to prevent performance degradation.
var _d6_fix6b_lifecycle_last_check_msec: int = 0
var _d6_fix6b_lifecycle_check_interval_ms: int = 2000  ## Check every 2 seconds.
var _d6_fix6b_lifecycle_removed_count: int = 0
var _d6_fix6b_lifecycle_active_near_radius: float = 1000.0
var _d6_fix6b_lifecycle_distant_cleanup_radius: float = 1600.0
var _d6_fix6b_lifecycle_min_age_sec: int = 12
var _d6_fix6b_lifecycle_min_distant_time_sec: int = 8


## D6-01-FIX6B: call this periodically (from _process or mission update) to cleanup distant guards.
func _update_security_guard_lifecycle(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if (now - _d6_fix6b_lifecycle_last_check_msec) < _d6_fix6b_lifecycle_check_interval_ms:
		return
	_d6_fix6b_lifecycle_last_check_msec = now
	
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null:
		return
	
	var enemies := get_node_or_null("EntityRoot/Enemies")
	if enemies == null:
		return
	
	for ch in enemies.get_children():
		if not (ch is Node2D):
			continue
		var guard := ch as Node2D
		if not _is_security_guard_cleanup_candidate(guard, player_node.global_position):
			continue
		## Mark as inactive and queue free.
		var guard_id := str(guard.get_instance_id())
		EventBus.debug("_update_security_guard_lifecycle: removing distant inactive guard id=" + guard_id)
		guard.set_meta("security_lifecycle_removed", true)
		guard.set_meta("security_response_spawn", false)  ## Remove from functional count.
		_d6_fix6b_lifecycle_removed_count += 1
		guard.queue_free()


## D6-01-FIX6B: check if a guard is eligible for cleanup (far, inactive, not chasing, not recently spawned).
func _is_security_guard_cleanup_candidate(guard: Node2D, player_pos: Vector2) -> bool:
	## Must be a security response spawn.
	if guard.get_meta("security_response_spawn", false) != true:
		return false
	
	## Must not be chasing (check if has target and is chasing).
	if guard.has_method("is_chasing"):
		if guard.call("is_chasing"):
			return false
	## Alternative: check common chase state properties.
	var is_chasing := false
	if guard.get("chasing") != null:
		is_chasing = bool(guard.get("chasing"))
	if guard.get("target") != null:
		is_chasing = true
	if is_chasing:
		return false
	
	## Must not be attacking.
	if guard.get("attacking") != null:
		if bool(guard.get("attacking")):
			return false
	
	## Check distance - must be far away.
	var dist := guard.global_position.distance_to(player_pos)
	if dist < _d6_fix6b_lifecycle_distant_cleanup_radius:
		return false
	
	## Must have been spawned long enough ago.
	var spawn_time := int(guard.get_meta("security_spawn_time_sec", 0))
	var current_time: int = int(Time.get_time_dict_from_system()["second"])
	## Handle wrap-around at 60 seconds (simple diff, may have small edge cases).
	var age_sec := int(current_time - spawn_time)
	if age_sec < 0:
		age_sec += 60
	if age_sec < _d6_fix6b_lifecycle_min_age_sec:
		return false
	if age_sec < _d6_fix6b_lifecycle_min_distant_time_sec:
		return false
	
	## Must not be visible on screen (simple distance check, could add viewport check).
	if dist < _d6_fix6b_lifecycle_active_near_radius:
		return false
	
	## Check if heat is 5 - be more conservative at max heat.
	var heat := GameState.get_mission_heat(mission_definition.mission_id)
	if heat >= 5:
		## At heat 5, only cleanup if very far (beyond 2000) and inactive longer.
		if dist < 2000.0:
			return false
		if age_sec < 20:
			return false
	
	return true


## D6-01-FIX6B: get lifecycle stats for F10 debug.
func _get_security_guard_lifecycle_stats() -> Dictionary:
	var enemies := get_node_or_null("EntityRoot/Enemies")
	var active := 0
	var searching := 0
	var dormant := 0
	if enemies != null:
		for ch in enemies.get_children():
			if not (ch is Node2D):
				continue
			var guard := ch as Node2D
			if guard.get_meta("security_response_spawn", false) != true:
				continue
			## Classify by state.
			if guard.get("target") != null:
				active += 1
			elif guard.get_meta("security_search_role", "") != "":
				searching += 1
			else:
				dormant += 1
	return {
		"active": active,
		"searching": searching,
		"dormant": dormant,
		"removed_total": _d6_fix6b_lifecycle_removed_count,
		"near_radius": _d6_fix6b_lifecycle_active_near_radius,
		"cleanup_radius": _d6_fix6b_lifecycle_distant_cleanup_radius,
	}


func _is_guard_visibility_chain_visible(guard: Node2D) -> bool:
	var node := guard as CanvasItem
	while node != null:
		if not node.visible:
			return false
		if node.modulate.a <= 0.02:
			return false
		var parent := node.get_parent()
		if parent is CanvasItem:
			node = parent as CanvasItem
		else:
			break
	return true


func _get_playable_world_bounds() -> Rect2:
	var floor_bounds := _floor_world_bounds()
	if floor_bounds.size.x > 16.0 and floor_bounds.size.y > 16.0:
		return floor_bounds.grow(90.0)
	return _mission_rect().grow(140.0)


func _is_spawn_position_sane(pos: Vector2) -> bool:
	var bounds := _get_playable_world_bounds()
	return bounds.has_point(pos)


func _choose_security_response_spawn_position(source_id: String, player_pos: Vector2) -> Dictionary:
	var requested := _preferred_security_spawn_from_source(source_id, player_pos)
	var candidates := _get_player_near_security_spawn_candidates(player_pos, source_id)
	for candidate in candidates:
		if _is_security_spawn_position_sane(candidate, player_pos):
			return {
				"valid": true,
				"requested_position": requested,
				"chosen_position": candidate,
				"mode": "player_near",
				"reason": "first player-near sane candidate",
			}
	if _is_security_spawn_position_sane(requested, player_pos):
		return {
			"valid": true,
			"requested_position": requested,
			"chosen_position": requested,
			"mode": "source_near",
			"reason": "source position sane and player-near candidates rejected",
		}
	var fallback := player_pos + Vector2(220, 0)
	return {
		"valid": _is_spawn_position_sane(fallback),
		"requested_position": requested,
		"chosen_position": fallback,
		"mode": "fallback",
		"reason": "fallback player-near candidate; collision validation unavailable or all candidates rejected",
	}


func _get_player_near_security_spawn_candidates(player_pos: Vector2, _source_id: String = "") -> Array[Vector2]:
	var offsets: Array[Vector2] = [
		Vector2(220, 0),
		Vector2(-220, 0),
		Vector2(0, 220),
		Vector2(0, -220),
		Vector2(180, 180),
		Vector2(-180, 180),
		Vector2(180, -180),
		Vector2(-180, -180),
		Vector2(300, 0),
		Vector2(-300, 0),
	]
	var out: Array[Vector2] = []
	for offset in offsets:
		out.append(player_pos + offset)
	return out


func _is_security_spawn_position_sane(pos: Vector2, player_pos: Vector2) -> bool:
	if not _is_spawn_position_sane(pos):
		return false
	var dist := pos.distance_to(player_pos)
	if dist < 150.0 or dist > 430.0:
		return false
	return _is_security_spawn_cell_open(pos)


func _is_security_spawn_cell_open(pos: Vector2) -> bool:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer == null or floor_layer.get_used_cells().is_empty():
		return true
	var cell := floor_layer.local_to_map(floor_layer.to_local(pos))
	var floor_cells := _cell_set(floor_layer.get_used_cells())
	if not floor_cells.has(cell):
		return false
	var collision_layer := get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	if collision_layer == null:
		return true
	var blocked := _cell_set(collision_layer.get_used_cells())
	return not blocked.has(cell)


func _finalize_security_guard_position(guard: Node2D, chosen_pos: Vector2) -> bool:
	if guard == null or not is_instance_valid(guard):
		return false
	if not guard.is_inside_tree():
		return false
	guard.global_position = chosen_pos
	var actual := guard.global_position
	return actual.distance_to(chosen_pos) <= 6.0


func _global_to_map_cell(world_pos: Vector2) -> Vector2i:
	var floor_layer := get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer != null:
		return floor_layer.local_to_map(floor_layer.to_local(world_pos))
	return Vector2i(roundi(world_pos.x / 64.0), roundi(world_pos.y / 32.0))


func _preferred_security_spawn_from_source(source_id: String, player_pos: Vector2) -> Vector2:
	if source_id == "":
		return player_pos
	var normalized := source_id
	if source_id.begins_with("attack_guard_"):
		var parts := source_id.split("_")
		if parts.size() >= 4:
			normalized = "_".join(parts.slice(2, parts.size() - 1))
	if normalized.begins_with("alarm_"):
		normalized = normalized.substr("alarm_".length())
	var cams := get_node_or_null("EntityRoot/Cameras")
	if cams != null:
		var cam := cams.get_node_or_null(_node_name("SecurityCamera", normalized)) as Node2D
		if cam != null:
			return cam.global_position
		for ch in cams.get_children():
			if ch is Node2D and String((ch as Node).name).find(normalized) != -1:
				return (ch as Node2D).global_position
	var marker := _find_authoring_marker("SECURITY_CAMERA", normalized)
	if marker is Node2D:
		return (marker as Node2D).global_position
	return player_pos


func _get_safe_security_spawn_position(source_id: String, preferred_pos: Vector2 = Vector2.ZERO, player_pos: Vector2 = Vector2.ZERO) -> Vector2:
	var player_position := player_pos
	if player_position == Vector2.ZERO:
		var player_node := get_tree().get_first_node_in_group("player") as Node2D
		if player_node != null:
			player_position = player_node.global_position
	var base := preferred_pos
	if base == Vector2.ZERO:
		base = _preferred_security_spawn_from_source(source_id, player_position)
	var away := (player_position - base).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	var dists := [190.0, 230.0, 260.0, 150.0]
	for d in dists:
		var candidate: Vector2 = player_position + away * d
		if _is_spawn_position_sane(candidate):
			return candidate
	var ring := [
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 0.7).normalized(), Vector2(-1, 0.7).normalized(),
		Vector2(1, -0.7).normalized(), Vector2(-1, -0.7).normalized(),
	]
	for dir in ring:
		var candidate: Vector2 = player_position + dir * 210.0
		if _is_spawn_position_sane(candidate):
			return candidate
	return base


func _record_security_spawn_probe(data: Dictionary) -> void:
	_security_spawn_probe = data.duplicate(true)
	_security_spawn_probe["timestamp_msec"] = Time.get_ticks_msec()


func _security_guard_positions_preview(max_lines: int = 4) -> Array[String]:
	var out: Array[String] = []
	var enemies := get_node_or_null("EntityRoot/Enemies")
	if enemies == null:
		out.append("(none)")
		return out
	var shown := 0
	for ch in enemies.get_children():
		if not (ch is Node2D):
			continue
		if not is_instance_valid(ch) or not ch.is_inside_tree():
			continue
		if ch.get_meta("security_response_spawn", false) != true:
			continue
		if not _is_guard_functional_for_cap(ch as Node2D):
			continue
		var src := String(ch.get_meta("security_spawn_source", ""))
		var tag := src if src != "" else "security"
		var mode := String(ch.get_meta("security_spawn_mode", "?"))
		out.append("%s/%s @ (%d,%d)" % [tag, mode, int((ch as Node2D).global_position.x), int((ch as Node2D).global_position.y)])
		shown += 1
		if shown >= max_lines:
			break
	if out.is_empty():
		out.append("(none)")
	return out


func _security_guard_raw_positions_preview(max_lines: int = 4) -> Array[String]:
	var out: Array[String] = []
	var enemies := get_node_or_null("EntityRoot/Enemies")
	if enemies == null:
		out.append("(none)")
		return out
	var shown := 0
	for ch in enemies.get_children():
		if not (ch is Node2D):
			continue
		if not is_instance_valid(ch) or not ch.is_inside_tree():
			continue
		if ch.get_meta("security_response_spawn", false) != true:
			continue
		var src := String(ch.get_meta("security_spawn_source", ""))
		var tag := src if src != "" else "security"
		out.append("%s @ (%d,%d)" % [tag, int((ch as Node2D).global_position.x), int((ch as Node2D).global_position.y)])
		shown += 1
		if shown >= max_lines:
			break
	if out.is_empty():
		out.append("(none)")
	return out


func _count_security_cameras_sweeping() -> Dictionary:
	var parent := get_node_or_null("EntityRoot/Cameras")
	var moving := 0
	var total := 0
	if parent == null:
		return {"total": 0, "moving": 0, "static": 0}
	for ch in parent.get_children():
		if not (ch is Area2D):
			continue
		if not (ch as Node).is_in_group("iso_security_camera"):
			continue
		if not ch.has_method("set_camera_enabled"):
			continue
		total += 1
		var enabled := true
		var en_v: Variant = ch.get("enabled")
		if en_v != null:
			enabled = bool(en_v)
		var ss := float(ch.get("sweep_speed")) if ch.get("sweep_speed") != null else 0.0
		var smin := float(ch.get("sweep_min_degrees")) if ch.get("sweep_min_degrees") != null else 0.0
		var smax := float(ch.get("sweep_max_degrees")) if ch.get("sweep_max_degrees") != null else 0.0
		if enabled and absf(ss) > 0.0001 and absf(smax - smin) > 0.5:
			moving += 1
	return {"total": total, "moving": moving, "static": total - moving}


func _pick_security_spawn_near_player(player_pos: Vector2, _min_dist: float, _max_dist: float) -> Vector2:
	return _get_safe_security_spawn_position("", player_pos, player_pos)


## D6-01-FIX6B: heat-scaled search net with triangle patrol fallback.
## Assigns search/patrol points that vary by heat level and guard ordinal to prevent stacking.
func _assign_fallback_patrol_for_security_guard(guard: Node2D, anchor: Vector2) -> void:
	var paths_root := get_node_or_null("GameplayRoot/EnemyPaths") as Node2D
	if paths_root == null:
		return
	
	## Get heat and compute search role and triangle pattern.
	var heat := GameState.get_mission_heat(mission_definition.mission_id)
	var ordinal := _count_raw_security_response_guards()
	var role := _get_security_search_role(heat, ordinal)
	var direction := 1 if (ordinal % 2 == 0) else -1
	
	## Build search points based on role and heat.
	var search_points := _build_search_net_points(anchor, heat, ordinal, role)
	var validated_points := _validate_security_search_route_points(search_points, anchor)
	
	## Always create a concrete Path2D to preserve backward compatibility with guard patrol API.
	var path := Path2D.new()
	path.name = _node_name("Patrol", "security_search_" + str(Time.get_ticks_msec()))
	path.global_position = Vector2.ZERO  ## Points are in world space.
	var c := Curve2D.new()
	for pt in validated_points:
		c.add_point(pt)
	path.curve = c
	paths_root.add_child(path)
	if guard.has_method("assign_patrol_path"):
		guard.assign_patrol_path(path)
	## D6-01-FIX7: explicit security handoff so local search net is real behavior, not only metadata.
	var search_net_payload := {
		"center": anchor,
		"radius": _get_security_search_radius_for_heat(heat),
		"role": role,
		"ordinal": ordinal,
		"direction": direction,
		"route_points": validated_points,
	}
	if guard.has_method("apply_security_search_net"):
		guard.call("apply_security_search_net", search_net_payload)
	
	## Store metadata for debug and lifecycle management.
	guard.set_meta("security_spawn_position", anchor)
	guard.set_meta("security_local_patrol_enabled", true)
	guard.set_meta("security_search_net_enabled", true)
	guard.set_meta("security_spawn_origin", anchor)
	guard.set_meta("security_search_center", anchor)
	guard.set_meta("security_search_radius", _get_security_search_radius_for_heat(heat))
	guard.set_meta("security_search_direction", direction)
	guard.set_meta("security_search_route_points_count", validated_points.size())
	guard.set_meta("security_search_role", role)
	guard.set_meta("security_search_ordinal", ordinal)
	guard.set_meta("security_heat_at_spawn", heat)
	guard.set_meta("security_spawn_time_sec", Time.get_time_dict_from_system()["second"])
	EventBus.debug("_assign_fallback_patrol_for_security_guard: heat=%d ordinal=%d role=%s direction=%d points=%d" % [heat, ordinal, role, direction, validated_points.size()])


## D6-01-FIX6B: determine search role based on heat and guard ordinal.
func _get_security_search_role(heat: int, ordinal: int) -> String:
	if heat <= 1:
		return "territorial"
	elif heat <= 3:
		## At heat 2-3, first guard is pursuer, others are flankers.
		if ordinal == 0:
			return "pursuer_search"
		else:
			return "flanker" if (ordinal % 2 == 1) else "pursuer_search"
	elif heat == 4:
		## At heat 4, distribute roles across types.
		var roles := ["pursuer_search", "flanker", "chokepoint_holder", "objective_sentry"]
		return roles[ordinal % roles.size()]
	else:
		## Heat 5: coordinated lockdown with objective sentry emphasis.
		var roles := ["pursuer_search", "flanker", "chokepoint_holder", "objective_sentry", "objective_sentry"]
		return roles[ordinal % roles.size()]


## D6-01-FIX6B: build search net patrol points based on role, heat, and guard ordinal.
func _build_search_net_points(center: Vector2, heat: int, ordinal: int, role: String) -> Array[Vector2]:
	## Heat-scaled radius for search area.
	var radius: float = _get_security_search_radius_for_heat(heat)
	
	## Ordinal-based rotation offset to prevent guards from stacking.
	var rotation_offset := (ordinal * 60.0) * (PI / 180.0)
	if ordinal % 2 == 1:
		rotation_offset += PI  ## Alternate direction for odd ordinals.
	
	## Role-based position adjustments.
	var points: Array[Vector2] = []
	match role:
		"territorial":
			## Simple triangle around center.
			points = _build_triangle_points(center, radius, rotation_offset)
		"pursuer_search":
			## Search near last known position with wider triangle.
			points = _build_triangle_points(center, radius * 0.9, rotation_offset)
		"flanker":
			## Flank offset left or right of center.
			var flank_dir := 1.0 if (ordinal % 2 == 1) else -1.0
			var flank_center := center + Vector2(flank_dir * radius * 0.6, 0)
			points = _build_triangle_points(flank_center, radius * 0.7, rotation_offset)
		"chokepoint_holder":
			## Hold position at offset + small patrol.
			var choke_offset := Vector2(radius * 0.4, 0).rotated(rotation_offset)
			var choke_center := center + choke_offset
			## Small tight triangle at chokepoint.
			points = _build_triangle_points(choke_center, radius * 0.4, rotation_offset)
		"objective_sentry":
			## Position toward bag room if known, otherwise offset from center.
			var bag_marker := _find_authoring_marker("OBJECTIVE", "retrieve_delivery_bag")
			if bag_marker is Node2D:
				var bag_pos := (bag_marker as Node2D).global_position
				var to_bag := (bag_pos - center).normalized()
				var sentry_center := center + to_bag * (radius * 0.5)
				points = _build_triangle_points(sentry_center, radius * 0.5, rotation_offset)
			else:
				points = _build_triangle_points(center + Vector2(radius * 0.5, 0), radius * 0.5, rotation_offset)
		_:
			points = _build_triangle_points(center, radius, rotation_offset)
	
	return points


func _get_security_search_radius_for_heat(heat: int) -> float:
	match heat:
		0, 1:
			return 140.0
		2, 3:
			return 200.0
		4:
			return 260.0
		_:
			return 320.0


## D6-01-FIX7: keep security-search routes in sane playable bounds near encounter area.
func _validate_security_search_route_points(points: Array[Vector2], center: Vector2) -> Array[Vector2]:
	var validated: Array[Vector2] = []
	var max_distance_from_center := 520.0
	for p in points:
		var point := p
		if point.distance_to(center) > max_distance_from_center:
			point = center + (point - center).normalized() * max_distance_from_center
		if not _is_spawn_position_sane(point):
			var fallback := _get_safe_security_spawn_position("search_route_adjust", center, center)
			point = fallback
		validated.append(point)
	if validated.size() < 2:
		validated = [center + Vector2(64, 0), center + Vector2(-64, 0)]
	return validated


## D6-01-FIX6B: build a triangle of 3 points around center with given radius and rotation.
func _build_triangle_points(center: Vector2, radius: float, rotation_offset: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var angles: Array[float] = [0.0, 2.094, 4.189]  ## 0, 120, 240 degrees in radians.
	for a in angles:
		var angle: float = a + rotation_offset
		var pt := center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.6)  ## Flatten Y for iso.
		points.append(pt)
	return points


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


func fail_level(reason = "Not the cleanest getaway.") -> void:
	_clear_pending_authored_collectibles("mission_failed")
	super.fail_level(reason)


func complete_level() -> void:
	request_exit_completion(player)


func allows_phase0k_louis_exit_fallback() -> bool:
	return String(get_mission_id()) in PHASE0K_LOUIS_EXIT_FALLBACK_MISSION_IDS


func request_exit_completion(_player: Node = null) -> bool:
	if _mission_completing or is_complete or is_failed:
		return false
	_complete_exit_return_objectives()
	if not _all_required_done():
		_show_exit_locked_feedback()
		return false
	_mission_completing = true
	commit_authored_collectibles_for_success("request_exit_completion")
	_record_runtime_completion_metadata()
	super.complete_level()
	return true


## Taco/Phase0K-only: Louis exit when bag+gate are met but formal definition objectives are not all flagged.
func apply_phase0k_louis_exit_completion() -> Dictionary:
	if not allows_phase0k_louis_exit_fallback():
		push_warning(
			"[D6-06D] Phase0K Louis exit fallback denied for mission '%s'. Add to PHASE0K_LOUIS_EXIT_FALLBACK_MISSION_IDS only after review."
			% String(get_mission_id())
		)
		return {"success": false, "via": "fallback_denied", "mission_id": get_mission_id()}
	if _mission_completing or is_complete or is_failed:
		return {"success": false, "via": "mission_already_resolved", "mission_id": get_mission_id()}
	_complete_exit_return_objectives()
	_mission_completing = true
	var commit_result := commit_authored_collectibles_for_success("phase0k_louis_exit")
	_record_runtime_completion_metadata()
	super.complete_level()
	return {
		"success": true,
		"via": "phase0k_louis_exit",
		"mission_id": get_mission_id(),
		"commit": commit_result,
	}


func commit_authored_collectibles_for_success(reason: String = "") -> Dictionary:
	if _d6_06_authored_commit_applied:
		_attempt_runtime_state["d6_06_commit_reason"] = String(_attempt_runtime_state.get("d6_06_commit_reason", reason))
		_attempt_runtime_state["d6_06_commit_duplicate_blocked"] = true
		return {
			"committed": 0,
			"skipped": _d6_06_pending_collectibles.size(),
			"already_applied": true,
		}
	_d6_06_authored_commit_applied = true
	_attempt_runtime_state["d6_06_commit_reason"] = reason
	_attempt_runtime_state["d6_06_commit_duplicate_blocked"] = false
	return _commit_pending_authored_collectibles()


func _show_exit_locked_feedback() -> void:
	var message := _exit_locked_message()
	MissionObjectiveBridge.publish_primary_objective(get_mission_id(), message)
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
			MissionObjectiveBridge.publish_primary_objective(get_mission_id(), String(_required_objective_text.get(id, "Continue the route.")))
			return
	for id in _required_clue_ids:
		if not _completed_clue_ids.has(id):
			MissionObjectiveBridge.publish_primary_objective(get_mission_id(), "Recover required clue: " + id.replace("_", " ").capitalize())
			return
	MissionObjectiveBridge.publish_primary_objective(get_mission_id(), "Return to Louis at the exit.")


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
		var dline := _mission_dialogue_line("mission_complete_001", "Scheme Card unlocked: " + String(reward.display_name), "Mission")
		DialogueManager.start_simple_dialogue([{
			"speaker": String(dline.get("speaker", "Mission")),
			"text": String(dline.get("text", "Scheme Card unlocked: " + String(reward.display_name)))
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
	_security_event_router = null
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


func _spawn_guard_for_spawn(spawn_def: Resource) -> Node2D:
	var spawn_id := String(spawn_def.spawn_id)
	if _runtime_spawned_ids.has("guard:" + spawn_id):
		return null
	var packed := load(spawn_def.scene_path if String(spawn_def.scene_path) != "" else "res://scenes/characters/guard.tscn") as PackedScene
	if packed == null:
		return null
	var guard := packed.instantiate() as Node2D
	if guard == null:
		return null
	guard.set_meta("d5_attempt_runtime_guard", true)
	guard.set_meta("security_spawn_source", "runtime_definition:" + spawn_id)
	var enemies := get_node_or_null("EntityRoot/Enemies") as Node2D
	if enemies == null:
		return null
	enemies.add_child(guard)
	guard.global_position = _resolve_point_position(spawn_def.marker_cell, "GUARD_SPAWN", spawn_id, {
		"linked_guard_id": spawn_id,
		"canonical_marker_id": "guard_" + spawn_id,
	})
	_apply_iso_enemy_profile(guard)
	if guard.has_signal("spotted_player"):
		guard.connect("spotted_player", Callable(self, "_on_runtime_guard_spotted").bind(spawn_id))
	if not spawn_id.begins_with("attack_guard_"):
		_spawn_guard_patrol_path(guard, spawn_def.marker_cell, spawn_id)
	_runtime_spawned_ids["guard:" + spawn_id] = true
	_register_runtime("guards", spawn_id)
	return guard


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
	camera.set_meta("d5_attempt_runtime_camera", true)
	camera.set_meta("security_camera_source", "runtime_definition:" + camera_id)
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
	if camera.has_method("refresh_sweep_basis_from_world"):
		camera.call_deferred("refresh_sweep_basis_from_world")
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
	## FIX7A/FIX7F: AMBUSH_security_beam geometry is applied in `_setup_fix7_ambush_beam_runtime` (deferred)
	## so anchor + collision-derived choke span stay the single source of truth. Avoid attaching here (spawn order vs deferred setup).


## D6-01-FIX6B: temporary visible red beam across far-right hallway before bag room.
## Tagged for removal/finalization in later level design pass.
func _add_d6_fix5_temp_beam_visual(pos_a: Vector2, pos_b: Vector2) -> void:
	var root := get_node_or_null("GameplayRoot/RuntimeSystems") as Node2D
	if root == null:
		root = get_node_or_null("GameplayRoot") as Node2D
	if root == null:
		return
	## Remove old beam versions from previous passes.
	var old_fix4 := root.get_node_or_null("D6_FIX4_TEMP_BEAM_WORLD_VISUAL_REMOVE_IN_FINAL_LEVEL_PASS")
	if old_fix4 != null:
		old_fix4.queue_free()
	var old_fix5 := root.get_node_or_null("D6_FIX5_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS")
	if old_fix5 != null:
		old_fix5.queue_free()
	var old_fix6 := root.get_node_or_null("D6_FIX6_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS")
	if old_fix6 != null:
		old_fix6.queue_free()
	var old_fix6a := root.get_node_or_null("D6_FIX6A_TEMP_SECURITY_BEAM_LOCATOR_REMOVE_OR_FINALIZE_IN_LEVEL_PASS")
	if old_fix6a != null:
		old_fix6a.queue_free()
	## Skip if FIX6B beam already exists.
	if root.get_node_or_null("D6_FIX6B_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS") != null:
		return
	var host := Node2D.new()
	host.name = "D6_FIX6B_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS"
	host.set_meta("D6_FIX6B_TEMP_SECURITY_BEAM_LOCATOR_REMOVE_OR_FINALIZE_IN_LEVEL_PASS", true)
	host.z_index = 2400
	root.add_child(host)
	## Thick red beam line.
	var line := Line2D.new()
	line.name = "FarRightHallwayBeamSpan"
	line.width = 32.0
	line.default_color = Color(1.0, 0.08, 0.08, 1.0)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.z_index = 2400
	line.add_point(host.to_local(pos_a))
	line.add_point(host.to_local(pos_b))
	host.add_child(line)
	## Floating label near beam center.
	var beam_center := (pos_a + pos_b) * 0.5
	var label := Label.new()
	label.name = "BeamLocatorLabel"
	## D6-01-FIX6B: updated label text for far-right hallway location.
	label.text = "FAR-RIGHT SECURITY BEAM — walk through red line"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.position = host.to_local(beam_center) + Vector2(-150, -55)
	label.z_index = 2401
	host.add_child(label)
	## Red beacon circle at beam center for visibility.
	var beacon := Node2D.new()
	beacon.name = "BeamLocatorBeacon"
	beacon.position = host.to_local(beam_center)
	beacon.z_index = 2399
	host.add_child(beacon)
	EventBus.debug("_add_d6_fix5_temp_beam_visual: FIX6B beam placed at " + str(beam_center) + " (far-right hallway before bag room)")


func _ensure_d6_fix5_runtime_helpers() -> void:
	## D6_FIX5: keep beam visual for right hallway test, remove/disable test warp runtime.
	if mission_definition == null or String(mission_definition.mission_id) != "taco_bell_drop":
		return
	_remove_d6_fix_test_warp_nodes()
	_remove_fix7_stale_temp_beam_nodes()
	_schedule_fix7_ambush_beam_physics_setup()


func get_security_event_router() -> Node:
	if _security_event_router == null:
		return null
	if not is_instance_valid(_security_event_router):
		_security_event_router = null
		return null
	if _security_event_router.is_queued_for_deletion() or not _security_event_router.is_inside_tree():
		_security_event_router = null
		return null
	return _security_event_router


func set_security_event_router(router: Node) -> void:
	_security_event_router = router


func _author_prop(author: Node, key: String, fallback: Variant = null) -> Variant:
	if author == null:
		return fallback
	var v: Variant = author.get(key)
	if v == null:
		return fallback
	return v


func _is_beam_alarm_id(alarm_id: String) -> bool:
	return alarm_id == "garage_entry_beam" or alarm_id == "AMBUSH_security_beam"


func _is_louis_delivery_route_active() -> bool:
	return GameState.has_selected_card("louis_delivery_route") or GameState.has_scheme_card("louis_delivery_route")


func _try_bypass_louis_route_beam(alarm_id: String, area: Area2D, body: Node) -> bool:
	if not _is_beam_alarm_id(alarm_id):
		return false
	if not _is_louis_delivery_route_active():
		return false
	if _is_runtime_flag_true("alarm_bypassed:" + alarm_id):
		return true
	_attempt_runtime_state["alarm_bypassed:" + alarm_id] = true
	_attempt_runtime_state["louis_route_beam_bypass_used"] = true
	_attempt_runtime_state["louis_route_beam_bypass_count"] = int(_attempt_runtime_state.get("louis_route_beam_bypass_count", 0)) + 1
	_attempt_runtime_state["louis_route_beam_bypass_alarm_id"] = alarm_id
	_attempt_runtime_state["louis_route_beam_bypass_player_position"] = (body as Node2D).global_position if body is Node2D else Vector2.ZERO
	_attempt_runtime_state["d5_03_louis_route_beam_bypass"] = "used"
	if area != null:
		area.set_deferred("monitoring", false)
	return true


func _setup_d6_03_authoring_security_runtime() -> void:
	if mission_definition == null or String(mission_definition.mission_id) != "taco_bell_drop":
		return
	var sec_root := _find_security_authoring_root()
	if sec_root == null or not bool(sec_root.get("runtime_enabled")):
		_attempt_runtime_state["d6_03_security_router_active"] = false
		return
	_attempt_runtime_state["d6_04_runtime_authored_camera_count"] = 0
	_security_event_router = D6_03_MISSION_AUTHORING_BUILDER.setup(self, sec_root)
	_attempt_runtime_state["d6_03_security_router_active"] = _security_event_router != null
	if _security_event_router == null:
		return
	var dbg: Dictionary = _security_event_router.call("get_debug_summary") as Dictionary
	_attempt_runtime_state["d6_03_registered_event_count"] = int(dbg.get("registered_event_count", 0))
	_attempt_runtime_state["d6_03_authored_area_trigger_count"] = sec_root.call("get_enabled_area_trigger_authors").size() if sec_root.has_method("get_enabled_area_trigger_authors") else 0
	for author in sec_root.call("collect_guard_spawn_authors"):
		if author is Node and author.has_method("bind_mission"):
			author.call("bind_mission", self)
	for author in sec_root.call("collect_effect_authors") if sec_root.has_method("collect_effect_authors") else []:
		if author is Node and author.has_method("bind_mission"):
			author.call("bind_mission", self)
	_setup_d6_06_collectible_authoring_runtime()


func _setup_d6_06_collectible_authoring_runtime() -> void:
	if mission_definition == null or String(mission_definition.mission_id) != "taco_bell_drop":
		_attempt_runtime_state["d6_06_authoring_root_found"] = false
		return
	var sec_root := _find_security_authoring_root()
	_attempt_runtime_state["d6_06_authoring_root_found"] = sec_root != null
	if sec_root == null or not bool(sec_root.get("runtime_enabled")):
		_attempt_runtime_state["d6_06_runtime_pickup_count"] = 0
		return
	var spawned: int = D6_06_COLLECTIBLE_BUILDER.setup(self, sec_root)
	_attempt_runtime_state["d6_06_runtime_pickup_count"] = spawned


func store_d6_06_collectible_author_counts(
	author_count: int,
	spawned: int,
	poop_n: int,
	money_n: int,
	polaroid_n: int,
	tiny_n: int,
	root_found: bool,
	glow_n: int = 0,
	clue_n: int = 0,
	case_cash_n: int = 0,
	duplicate_ids: Array[String] = []
) -> void:
	_attempt_runtime_state["d6_06_collectible_author_count"] = author_count
	_attempt_runtime_state["d6_06_runtime_pickup_count"] = spawned
	_attempt_runtime_state["d6_06_poop_author_count"] = poop_n
	_attempt_runtime_state["d6_06_money_author_count"] = money_n
	_attempt_runtime_state["d6_06_polaroid_author_count"] = polaroid_n
	_attempt_runtime_state["d6_06_tiny_icon_author_count"] = tiny_n
	_attempt_runtime_state["d6_06_glow_guy_author_count"] = glow_n
	_attempt_runtime_state["d6_06_clue_author_count"] = clue_n
	_attempt_runtime_state["d6_06_case_cash_author_count"] = case_cash_n
	_attempt_runtime_state["d6_06_duplicate_author_ids"] = duplicate_ids
	_attempt_runtime_state["d6_06_duplicate_author_id_count"] = duplicate_ids.size()
	_attempt_runtime_state["d6_06_authoring_root_found"] = root_found


func record_authored_collectible_pickup(
	pickup_type: String,
	collectible_id: String,
	result: Dictionary,
	objective_id: String = "",
	pickup_meta: Dictionary = {}
) -> void:
	_attempt_runtime_state["d6_06_last_authored_pickup_type"] = pickup_type
	_attempt_runtime_state["d6_06_last_authored_pickup_id"] = collectible_id
	_attempt_runtime_state["d6_06_last_authored_pickup_result"] = String(result.get("result", ""))
	var source := String(pickup_meta.get("source", result.get("source", ""))).strip_edges()
	_attempt_runtime_state["d6_06_last_pickup_source"] = source
	_attempt_runtime_state["d6_06_last_pickup_body"] = String(pickup_meta.get("body_name", ""))
	_attempt_runtime_state["d6_06_last_pickup_body_path"] = String(pickup_meta.get("body_path", ""))
	_attempt_runtime_state["d6_06_last_pickup_has_shape"] = pickup_meta.get("has_collision_shape", false)
	_attempt_runtime_state["d6_06_last_pickup_radius"] = float(pickup_meta.get("pickup_radius", 0.0))
	_attempt_runtime_state["d6_06_last_pickup_monitoring"] = pickup_meta.get("monitoring", false)
	if source == "body_entered" or source == "overlap_scan":
		_attempt_runtime_state["d6_06_physical_overlap_verified"] = true
	if objective_id.strip_edges() != "":
		_attempt_runtime_state["d6_06_last_objective_id"] = objective_id
	var flag_key := "d6_06_proof_collected:%s" % collectible_id
	GameState.dialogue_flags[flag_key] = true
	_attempt_runtime_state["d6_06_proof_flags"] = _count_d6_06_proof_flags()


func store_d6_06b_runtime_pickup_physics_summary(summaries: Array) -> void:
	_attempt_runtime_state["d6_06b_runtime_pickup_physics"] = summaries
	var all_shapes := summaries.size() > 0
	var all_monitoring := summaries.size() > 0
	for entry_v in summaries:
		if not (entry_v is Dictionary):
			all_shapes = false
			all_monitoring = false
			continue
		var entry: Dictionary = entry_v as Dictionary
		if not bool(entry.get("has_collision_shape", false)):
			all_shapes = false
		if not bool(entry.get("monitoring", false)):
			all_monitoring = false
	_attempt_runtime_state["d6_06b_all_pickups_have_shape"] = all_shapes
	_attempt_runtime_state["d6_06b_all_pickups_monitoring"] = all_monitoring


func _count_d6_06_proof_flags() -> int:
	var n := 0
	for key in GameState.dialogue_flags.keys():
		if String(key).begins_with("d6_06_proof_collected:"):
			n += 1
	return n


func store_d6_06_runtime_path(path_kind: String, parent_path: String) -> void:
	_attempt_runtime_state["d6_06_runtime_path_kind"] = path_kind
	_attempt_runtime_state["d6_06_runtime_parent_path"] = parent_path


func record_authored_collectible_attempt(
	collectible_id: String,
	category: String,
	payload: Dictionary,
	source_node: Node = null
) -> Dictionary:
	var id_s := String(collectible_id).strip_edges()
	var cat_s := String(category).strip_edges()
	if id_s == "" or cat_s == "":
		return {"success": false, "already_done": false, "message": "Missing collectible id/type", "result": "rejected"}
	for entry in _d6_06_pending_collectibles:
		if String(entry.get("collectible_id", "")) == id_s:
			record_authored_collectible_pickup(
				cat_s,
				id_s,
				{"success": false, "result": "already_collected", "source": "interact"},
				String(payload.get("objective_id", "")),
				{"source": "interact", "duplicate": true}
			)
			return {
				"success": true,
				"already_done": true,
				"message": "Already collected this attempt: %s" % id_s,
				"real_system_updated": false,
				"menu_updated": false,
			}
	var hideout_key := D6_06_HIDEOUT_SYNC.resolve_hideout_key(
		cat_s,
		id_s,
		String(payload.get("hideout_collection_key", ""))
	)
	var entry := {
		"collectible_id": id_s,
		"category": cat_s,
		"collectible_type": _authored_type_from_category(cat_s, payload),
		"display_name": String(payload.get("display_name", id_s.capitalize())),
		"objective_id": String(payload.get("objective_id", "")),
		"hideout_collection_key": hideout_key,
		"payload": payload.duplicate(true),
		"committed": false,
		"node_path": str(source_node.get_path()) if source_node != null else "",
		"one_shot": bool(payload.get("one_shot", true)),
	}
	if cat_s in ["money", "case_cash"] or entry["collectible_type"] in ["money", "case_cash"]:
		entry["amount"] = maxi(int(payload.get("amount", 1)), 1)
		entry["currency_type"] = String(payload.get("currency_type", "cash"))
		entry["commits_as_case_cash"] = bool(payload.get("commits_as_case_cash", entry["collectible_type"] == "case_cash"))
	if entry["collectible_type"] in ["evidence_clue", "clue"]:
		entry["clue_id"] = String(payload.get("clue_id", id_s))
		entry["clue_title"] = String(payload.get("clue_title", entry["display_name"]))
		entry["clue_text"] = String(payload.get("clue_text", ""))
		entry["case_id"] = String(payload.get("case_id", ""))
	if entry["collectible_type"] == "glow_guy":
		entry["glow_guy_id"] = String(payload.get("glow_guy_id", id_s))
	if entry["collectible_type"] == "poop_bag":
		entry["poop_count"] = maxi(int(payload.get("poop_count", 1)), 1)
	_d6_06_pending_collectibles.append(entry)
	_attempt_runtime_state["d6_06_pending_collectible_count"] = _d6_06_pending_collectibles.size()
	_update_d6_06_pending_type_counts()
	record_authored_collectible_pickup(
		cat_s,
		id_s,
		{"success": true, "result": "pending_attempt", "source": "interact"},
		entry["objective_id"],
		{"source": "interact", "body_path": entry["node_path"]}
	)
	if source_node != null and source_node.has_method("get_interaction_text"):
		EventBus.objective_updated.emit("Collected (mission attempt): " + String(source_node.get("prompt_text")))
	return {
		"success": true,
		"already_done": false,
		"message": "Recorded for mission attempt: %s" % id_s,
		"real_system_updated": false,
		"menu_updated": false,
	}


func _authored_type_from_category(category: String, payload: Dictionary) -> String:
	var from_payload := String(payload.get("collectible_type", "")).strip_edges()
	if from_payload != "":
		return from_payload
	return category.strip_edges().to_lower()


func _update_d6_06_pending_type_counts() -> void:
	var poop := 0
	var money := 0
	var polaroid := 0
	var tiny := 0
	var glow := 0
	var clue := 0
	var case_cash_amount := 0
	var case_cash_instances := 0
	for entry in _d6_06_pending_collectibles:
		if bool(entry.get("committed", false)):
			continue
		match String(entry.get("collectible_type", "")):
			"poop_bag":
				poop += 1
			"money":
				money += 1
				if bool(entry.get("commits_as_case_cash", true)):
					case_cash_instances += 1
					case_cash_amount += maxi(int(entry.get("amount", 1)), 1)
			"case_cash":
				case_cash_instances += 1
				case_cash_amount += maxi(int(entry.get("amount", 1)), 1)
			"polaroid":
				polaroid += 1
			"tiny_icon":
				tiny += 1
			"glow_guy":
				glow += 1
			"evidence_clue", "clue":
				clue += 1
	_attempt_runtime_state["d6_06_pending_poop"] = poop
	_attempt_runtime_state["d6_06_pending_money"] = money
	_attempt_runtime_state["d6_06_pending_polaroid"] = polaroid
	_attempt_runtime_state["d6_06_pending_tiny_icon"] = tiny
	_attempt_runtime_state["d6_06_pending_glow_guy"] = glow
	_attempt_runtime_state["d6_06_pending_clue"] = clue
	_attempt_runtime_state["d6_06_pending_case_cash_amount"] = case_cash_amount
	_attempt_runtime_state["d6_06_pending_case_cash_instances"] = case_cash_instances


func _on_authored_collectible_collected_signal(collectible_id: String, category: String) -> void:
	record_authored_collectible_pickup(
		category,
		collectible_id,
		{"success": true, "result": "collected_signal", "source": "interact"},
		"",
		{"source": "interact"}
	)


func _commit_pending_authored_collectibles() -> Dictionary:
	var committed := 0
	var skipped := 0
	var already_persisted := 0
	var adapter := _find_phase0j_mission_state_adapter()
	for entry in _d6_06_pending_collectibles:
		if bool(entry.get("committed", false)):
			skipped += 1
			continue
		var id_s := String(entry.get("collectible_id", ""))
		var cat_s := String(entry.get("category", ""))
		var payload: Dictionary = entry.get("payload", {}) as Dictionary
		var ctype := String(entry.get("collectible_type", cat_s))
		if D6_06_PERSIST.is_already_persisted(id_s, ctype):
			entry["committed"] = true
			entry["skipped_reason"] = "already_persisted"
			already_persisted += 1
			skipped += 1
			continue
		if ctype in ["money", "case_cash"]:
			_commit_authored_money(entry)
			D6_06_PERSIST.mark_persisted(id_s, ctype)
			entry["committed"] = true
			committed += 1
			continue
		if adapter != null and adapter.has_method("sync_to_real_systems"):
			var sync_result: Dictionary = adapter.call("sync_to_real_systems", id_s, cat_s, payload)
			entry["sync_result"] = sync_result
			if ctype == "poop_bag":
				var extra: int = maxi(int(entry.get("poop_count", 1)), 1) - 1
				for _i in range(extra):
					GameState.add_poop_bag()
		else:
			TYPED_MISSION_COLLECTIBLE.collect(
				id_s,
				ctype,
				get_mission_id(),
				String(entry.get("display_name", id_s))
			)
		var hideout_key := String(entry.get("hideout_collection_key", ""))
		D6_06_HIDEOUT_SYNC.mark_hideout_display_found(hideout_key)
		D6_06_PERSIST.mark_persisted(id_s, ctype)
		entry["committed"] = true
		committed += 1
	_attempt_runtime_state["d6_06_committed_collectible_count"] = committed
	_attempt_runtime_state["d6_06_commit_skipped_count"] = skipped
	_attempt_runtime_state["d6_06_commit_already_persisted_count"] = already_persisted
	_attempt_runtime_state["d6_06_hideout_sync_status"] = "committed_%d" % committed
	_attempt_runtime_state["d6_06_clue_corkboard_sync"] = _d6_06_clue_commit_summary()
	_attempt_runtime_state["d6_06_glow_guy_shelf_sync"] = _d6_06_glow_commit_summary()
	_update_d6_06_pending_type_counts()
	return {"committed": committed, "skipped": skipped, "already_persisted": already_persisted}


func _commit_authored_money(entry: Dictionary) -> void:
	var id_s := String(entry.get("collectible_id", ""))
	var flag_key := "d6_06_money:" + id_s
	if GameState.dialogue_flags.get(flag_key, false) == true:
		return
	GameState.dialogue_flags[flag_key] = true
	var amount := maxi(int(entry.get("amount", 1)), 1)
	var added := D6_06_HIDEOUT_SYNC.commit_case_cash(amount, entry)
	increment_attempt_counter("d6_06_authored_money_cash", added)
	increment_attempt_counter("d6_06_authored_money_%s" % String(entry.get("currency_type", "cash")), amount)


func _d6_06_clue_commit_summary() -> String:
	var n := 0
	for entry in _d6_06_pending_collectibles:
		if not bool(entry.get("committed", false)):
			continue
		if String(entry.get("collectible_type", "")) in ["evidence_clue", "clue"]:
			n += 1
	return "clues_committed_%d" % n


func _d6_06_glow_commit_summary() -> String:
	var n := 0
	for entry in _d6_06_pending_collectibles:
		if not bool(entry.get("committed", false)):
			continue
		if String(entry.get("collectible_type", "")) == "glow_guy":
			n += 1
	return "glow_guys_committed_%d" % n


func _clear_pending_authored_collectibles(reason: String = "") -> void:
	_d6_06_pending_collectibles.clear()
	_d6_06_authored_commit_applied = false
	_attempt_runtime_state["d6_06_pending_collectible_count"] = 0
	_attempt_runtime_state["d6_06_pending_cleared_reason"] = reason
	_attempt_runtime_state["d6_06_commit_duplicate_blocked"] = false
	_update_d6_06_pending_type_counts()


func _find_phase0j_mission_state_adapter() -> Node:
	return find_child("Phase0JMissionStateAdapter", true, false)


func _store_d6_05_effect_author_counts(door_n: int, lockdown_n: int, objective_n: int, toggle_n: int) -> void:
	_attempt_runtime_state["d6_05_door_effect_count"] = door_n
	_attempt_runtime_state["d6_05_lockdown_effect_count"] = lockdown_n
	_attempt_runtime_state["d6_05_objective_effect_count"] = objective_n
	_attempt_runtime_state["d6_05_node_toggle_effect_count"] = toggle_n
	_recompute_d6_05_effect_author_count()


func _store_d6_05_effect_set_author_count(effect_set_n: int) -> void:
	_attempt_runtime_state["d6_05_effect_set_count"] = effect_set_n
	_recompute_d6_05_effect_author_count()


func _recompute_d6_05_effect_author_count() -> void:
	_attempt_runtime_state["d6_05_effect_author_count"] = (
		int(_attempt_runtime_state.get("d6_05_door_effect_count", 0))
		+ int(_attempt_runtime_state.get("d6_05_lockdown_effect_count", 0))
		+ int(_attempt_runtime_state.get("d6_05_objective_effect_count", 0))
		+ int(_attempt_runtime_state.get("d6_05_node_toggle_effect_count", 0))
		+ int(_attempt_runtime_state.get("d6_05_effect_set_count", 0))
	)


func _record_authoring_effect_result(effect_type: String, author: Node, result: Dictionary) -> void:
	_attempt_runtime_state["d6_05_last_effect_type"] = effect_type
	_attempt_runtime_state["d6_05_last_effect_id"] = String(result.get("effect_id", ""))
	if author != null and is_instance_valid(author):
		_attempt_runtime_state["d6_05_last_effect_author_path"] = str(author.get_path())
	_attempt_runtime_state["d6_05_last_effect_event"] = String(last_trigger_event_from_author(author))
	_attempt_runtime_state["d6_05_last_effect_result"] = String(result.get("result", ""))
	_attempt_runtime_state["d6_05_last_effect_reason"] = String(result.get("reason", ""))
	_attempt_runtime_state["d6_05_last_effect_target"] = String(
		result.get("target_path", result.get("target_gate_id", result.get("objective_id", "")))
	)
	if effect_type == "effect_set":
		_attempt_runtime_state["d6_05_last_effect_set_id"] = String(result.get("effect_set_id", ""))
		_attempt_runtime_state["d6_05_last_effect_set_message"] = String(result.get("effect_set_message", ""))
		_attempt_runtime_state["d6_05_last_effect_set_summary"] = String(result.get("effect_set_summary", ""))
		_attempt_runtime_state["d6_05_last_effect_set_applied_count"] = int(result.get("effect_set_applied_count", 0))
		_attempt_runtime_state["d6_05_last_effect_set_failed_count"] = int(result.get("effect_set_failed_count", 0))
		_attempt_runtime_state["d6_05_last_effect_chain"] = result.get("debug_chain", [])
	if effect_type == "lockdown":
		_attempt_runtime_state["d6_05_lockdown_active"] = true
		_attempt_runtime_state["d6_05_lockdown_level"] = int(result.get("lockdown_level", 0))
		var ctrl := get_tree().get_first_node_in_group("iso_alert_controller")
		if ctrl != null:
			_attempt_runtime_state["d6_05_lockdown_alert_state"] = String(ctrl.get("alert_state"))
	if effect_type == "door_lock":
		_attempt_runtime_state["d6_05_last_door_effect_id"] = String(result.get("effect_id", ""))
		var door_action := String(result.get("lock_action", ""))
		if door_action == "" and author != null:
			door_action = String(author.get("lock_action"))
		_attempt_runtime_state["d6_05_last_door_action"] = door_action
		_attempt_runtime_state["d6_05_last_door_lock_state"] = String(result.get("lock_state", ""))
		_attempt_runtime_state["d6_05_last_door_target"] = String(
			result.get("target_path", result.get("target_gate_id", ""))
		)
		if result.has("collision_enabled"):
			_attempt_runtime_state["d6_05a_test_door_collision_enabled"] = bool(
				result.get("collision_enabled", false)
			)
		if result.has("collision_layer"):
			_attempt_runtime_state["d6_05a_test_door_collision_layer"] = int(
				result.get("collision_layer", 0)
			)
		_attempt_runtime_state["d6_05_last_door_event"] = String(
			last_trigger_event_from_author(author)
		)
		_refresh_d6_05a_test_door_state()


func record_d6_05c_zone_trigger(zone_id: String, event_id: String, _payload: Dictionary = {}) -> void:
	_attempt_runtime_state["d6_05c_last_zone_id"] = zone_id
	_attempt_runtime_state["d6_05c_last_zone_event"] = event_id


func _refresh_d6_05a_test_door_state() -> void:
	for node in get_tree().get_nodes_in_group("d6_05a_test_door_lock"):
		if node != null and node.has_method("get_runtime_debug_state"):
			var st: Dictionary = node.call("get_runtime_debug_state") as Dictionary
			_attempt_runtime_state["d6_05a_test_door_path"] = String(st.get("path", ""))
			_attempt_runtime_state["d6_05a_test_door_locked"] = String(st.get("lock_state", "unknown")) == "locked"
			_attempt_runtime_state["d6_05a_test_door_lock_state"] = String(st.get("lock_state", "unknown"))
			_attempt_runtime_state["d6_05a_test_door_collision_layer"] = int(st.get("collision_layer", 0))
			_attempt_runtime_state["d6_05a_test_door_collision_enabled"] = bool(
				st.get("collision_enabled", false)
			)
			_attempt_runtime_state["d6_05a_test_door_orientation_degrees"] = float(
				st.get("orientation_degrees", 0.0)
			)
			return


func last_trigger_event_from_author(author: Node) -> String:
	if author == null:
		return ""
	if author.get("last_trigger_event") != null:
		return String(author.get("last_trigger_event"))
	return ""


func _emit_security_authoring_event(event_id: StringName, payload: Dictionary) -> Dictionary:
	_mark_authoring_beam_trip_if_needed(event_id, payload)
	if _security_event_router == null:
		return {}
	var full := payload.duplicate(true)
	if not full.has("heat"):
		full["heat"] = GameState.get_mission_heat(mission_definition.mission_id) if mission_definition != null else 0
	if not full.has("player_position"):
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			full["player_position"] = player.global_position
	var dispatch: Dictionary = _security_event_router.call("emit_event", event_id, full)
	_record_security_event_dispatch(dispatch)
	return dispatch


func _mark_authoring_beam_trip_if_needed(event_id: StringName, payload: Dictionary) -> void:
	if not _is_authoring_beam_trip_event(event_id, payload):
		return
	var alarm_id := String(payload.get("source_id", "")).strip_edges()
	if not _is_beam_alarm_id(alarm_id):
		alarm_id = "AMBUSH_security_beam"
	var key := "alarm_triggered:" + alarm_id
	if _is_runtime_flag_true(key):
		return
	_attempt_runtime_state[key] = true
	_attempt_runtime_state["beam_trip"] = int(_attempt_runtime_state.get("beam_trip", 0)) + 1
	_attempt_runtime_state["ambush_triggered"] = int(_attempt_runtime_state.get("ambush_triggered", 0)) + 1
	_attempt_runtime_state["d5_01_authoring_beam_trip_marked"] = true


func _is_authoring_beam_trip_event(event_id: StringName, payload: Dictionary) -> bool:
	if String(payload.get("source_type", "")).strip_edges() == "security_beam_author":
		return true
	return String(event_id).strip_edges() == "ambush_beam_tripped"


func _record_security_event_dispatch(dispatch: Dictionary) -> void:
	var dbg: Dictionary = _security_event_router.call("get_debug_summary") as Dictionary if _security_event_router != null else {}
	_attempt_runtime_state["d6_03_last_dispatched_event"] = String(dbg.get("last_dispatched_event", ""))
	_attempt_runtime_state["d6_03_registered_event_count"] = int(dbg.get("registered_event_count", 0))
	_attempt_runtime_state["d6_04_last_event_listeners_registered"] = int(dispatch.get("listeners_registered", 0))
	_attempt_runtime_state["d6_04_last_event_listeners_called"] = int(dispatch.get("listeners_called", 0))
	_attempt_runtime_state["d6_04_last_event_listeners_handled"] = int(dispatch.get("listeners_handled", 0))
	_attempt_runtime_state["d6_04_last_event_listeners_rejected"] = int(dispatch.get("listeners_rejected", 0))
	_attempt_runtime_state["d6_04_last_event_handled"] = bool(dispatch.get("handled", false))
	_attempt_runtime_state["d6_04_last_event_rejection_reasons"] = dispatch.get("reasons", [])
	_attempt_runtime_state["d6_04_last_successful_listener_paths"] = dispatch.get("successful_listener_paths", [])


func _get_authoring_beam_trip_event_id(alarm_id: String) -> StringName:
	var sec_root := _find_security_authoring_root()
	if sec_root == null:
		return &"ambush_beam_tripped"
	var beam_author: Node = null
	if sec_root.has_method("find_enabled_beam_author"):
		beam_author = sec_root.call("find_enabled_beam_author", &"AMBUSH_security_beam") as Node
	if beam_author == null and alarm_id != "":
		for author in sec_root.call("collect_beam_authors"):
			if String(_author_prop(author, "alarm_id", "")).strip_edges() == alarm_id.strip_edges():
				beam_author = author
				break
	if beam_author != null and bool(_author_prop(beam_author, "emit_event_on_trip", true)):
		var ev := String(_author_prop(beam_author, "on_trip_event", "ambush_beam_tripped")).strip_edges()
		if ev != "":
			return StringName(ev)
	return &"ambush_beam_tripped"


func _should_suppress_direct_spawn_for_event(event_id: StringName) -> bool:
	if _security_event_router == null:
		return false
	if not bool(_security_event_router.call("has_listeners", event_id)):
		return false
	var result: Dictionary = _security_event_router.call("get_last_dispatch_result")
	if String(result.get("event_id", "")).strip_edges() != String(event_id).strip_edges():
		return true
	if int(result.get("listeners_called", 0)) <= 0:
		return false
	return true


func _should_suppress_direct_beam_guard_spawn(alarm_id: String) -> bool:
	var trip_event := _get_authoring_beam_trip_event_id(alarm_id)
	var suppressed := _should_suppress_direct_spawn_for_event(trip_event)
	_attempt_runtime_state["d6_03_beam_event_route_used"] = suppressed
	_attempt_runtime_state["d6_03_beam_direct_fallback_suppressed"] = suppressed
	_attempt_runtime_state["d6_03_duplicate_spawn_avoided"] = suppressed
	return suppressed


func _get_authored_camera_alarm_event_id(camera_source_id: String) -> StringName:
	var sec_root := _find_security_authoring_root()
	if sec_root == null:
		return &""
	var want := camera_source_id.strip_edges()
	for author in sec_root.call("collect_camera_authors"):
		if String(_author_prop(author, "camera_id", "")).strip_edges() == want:
			var ev := String(_author_prop(author, "on_alarm_event", "")).strip_edges()
			if ev != "":
				return StringName(ev)
	return &""


func _bind_authored_security_camera(camera: Node, author: Node, _router: Node, cfg: Dictionary) -> void:
	if camera == null or author == null:
		return
	var cam_id := String(cfg.get("camera_id", ""))
	if camera.has_signal("player_detected") and not camera.has_meta("authored_alarm_bound"):
		camera.set_meta("authored_alarm_bound", true)
		camera.player_detected.connect(_on_authored_security_camera_alarm.bind(author, cfg))
	_attempt_runtime_state["d6_04_runtime_authored_camera_count"] = int(_attempt_runtime_state.get("d6_04_runtime_authored_camera_count", 0)) + 1
	_attempt_runtime_state["d6_04_authored_camera_runtime_path"] = String(camera.get_path())
	_attempt_runtime_state["d6_04_authored_camera_runtime_class"] = String(camera.get_class())
	_attempt_runtime_state["d6_04_authored_camera_parity_target"] = String(cfg.get("parity_target", "CAM_market_01"))
	_attempt_runtime_state["d6_04_authored_camera_parent_path"] = String(camera.get_parent().get_path()) if camera.get_parent() != null else ""
	if camera.has_method("get_runtime_debug_state"):
		var cst: Dictionary = camera.call("get_runtime_debug_state") as Dictionary
		_attempt_runtime_state["d6_04_authored_camera_enabled"] = bool(cst.get("enabled", false))
		_attempt_runtime_state["d6_04_authored_camera_monitoring"] = bool(cst.get("monitoring", false))
		_attempt_runtime_state["d6_04_authored_camera_has_shape"] = bool(cst.get("has_shape", false))
		_attempt_runtime_state["d6_04_authored_camera_player_in_cone"] = bool(cst.get("player_in_cone", false))
		_attempt_runtime_state["d6_04_authored_camera_detection_value"] = float(cst.get("detection_value", 0.0))


func _on_authored_security_camera_alarm(cam_id: String, author: Node, cfg: Dictionary) -> void:
	_attempt_runtime_state["d6_04_last_camera_id"] = cam_id
	_attempt_runtime_state["d6_04_last_camera_source_path"] = String(cfg.get("author_path", ""))
	if bool(cfg.get("emit_detect_event", false)):
		var detect_ev := String(cfg.get("on_detect_event", "")).strip_edges()
		if detect_ev != "":
			_emit_security_authoring_event(StringName(detect_ev), {
				"source_type": "security_camera_author",
				"source_id": cam_id,
				"source_path": String(cfg.get("author_path", "")),
				"reason": "camera_detect",
				"timestamp": Time.get_ticks_msec(),
			})
			_attempt_runtime_state["d6_04_last_camera_detect_event"] = detect_ev
	if bool(cfg.get("emit_alarm_event", true)):
		var alarm_ev := String(cfg.get("on_alarm_event", "camera_alarm")).strip_edges()
		if alarm_ev != "":
			var dispatch := _emit_security_authoring_event(StringName(alarm_ev), {
				"source_type": "security_camera_author",
				"source_id": cam_id,
				"source_path": String(cfg.get("author_path", "")),
				"reason": "camera_alarm",
				"timestamp": Time.get_ticks_msec(),
			})
			_attempt_runtime_state["d6_04_last_camera_alarm_event"] = alarm_ev
			_attempt_runtime_state["d6_04_last_camera_alarm_handled"] = bool(dispatch.get("handled", false))


func _spawn_guard_from_authoring_spawn(author: Node2D, event_id: StringName, payload: Dictionary) -> Dictionary:
	var spawn_id := String(_author_prop(author, "spawn_id", "guard_spawn"))
	_attempt_runtime_state["d6_03_last_guard_spawn_author_id"] = spawn_id
	if author == null or not is_instance_valid(author):
		return {"result": "failed", "reason": "invalid_author", "spawned_count": 0, "spawned_guards": []}
	var attempt_key := _authoring_guard_spawn_attempt_key(author, event_id)
	if _should_authoring_guard_spawn_be_once_per_attempt(event_id, payload) and _is_runtime_flag_true(attempt_key):
		_attempt_runtime_state["d6_03_last_guard_spawn_result"] = "rejected"
		_attempt_runtime_state["d6_03_last_guard_spawn_reason"] = "one_shot_already_used"
		_attempt_runtime_state["d5_01_authoring_guard_spawn_repeat_blocked"] = true
		return {"handled": false, "result": "rejected", "reason": "one_shot_already_used", "spawned_count": 0, "spawned_guards": []}
	if author.has_method("can_accept_event") and not author.call("can_accept_event", String(event_id), payload):
		var reason := "rejected_cooldown_or_cap_or_heat"
		if author is Node and author.get("last_spawn_reason"):
			reason = String(author.get("last_spawn_reason"))
		_attempt_runtime_state["d6_03_last_guard_spawn_result"] = "rejected"
		_attempt_runtime_state["d6_03_last_guard_spawn_reason"] = reason
		_attempt_runtime_state["d6_04_last_guard_initial_behavior"] = String(_author_prop(author, "initial_behavior", ""))
		_attempt_runtime_state["d6_04_last_guard_fallback_behavior"] = String(_author_prop(author, "fallback_behavior", ""))
		return {"handled": false, "result": "rejected", "reason": reason, "spawned_count": 0, "spawned_guards": []}
	var count_want := maxi(1, int(_author_prop(author, "spawn_count", 1)))
	var spawned: Array = []
	var enemies_root := get_node_or_null("EntityRoot/Enemies") as Node2D
	if enemies_root == null:
		_attempt_runtime_state["d6_03_last_guard_spawn_result"] = "failed"
		_attempt_runtime_state["d6_03_last_guard_spawn_reason"] = "no_enemies_root"
		return {"result": "failed", "reason": "no_enemies_root", "spawned_count": 0, "spawned_guards": []}
	var scene_path := MissionSecurityGuardResolver.good_guard_scene_path()
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_attempt_runtime_state["d6_03_last_guard_spawn_result"] = "failed"
		_attempt_runtime_state["d6_03_last_guard_spawn_reason"] = "missing_guard_scene"
		return {"result": "failed", "reason": "missing_guard_scene", "spawned_count": 0, "spawned_guards": []}
	var cap := _get_security_spawn_cap()
	for i in range(count_want):
		if _count_functional_security_response_guards() + spawned.size() >= cap:
			break
		var guard := packed.instantiate() as Node2D
		if guard == null:
			continue
		enemies_root.add_child(guard)
		var spawn_pos: Vector2 = author.global_position
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			spawn_pos = author.global_position.lerp(player.global_position, 0.35)
		guard.global_position = spawn_pos
		guard.set_meta("author_spawn_id", spawn_id)
		guard.set_meta("author_trigger_event", String(event_id))
		guard.set_meta("guard_archetype", String(_author_prop(author, "guard_archetype", "grunt")))
		guard.set_meta("security_response_guard", true)
		guard.set_meta("security_response_spawn", true)
		guard.set_meta("security_spawn_source", "author:" + spawn_id)
		guard.set_meta("security_spawn_time_sec", int(Time.get_ticks_msec() / 1000))
		if guard.has_method("apply_archetype_metadata"):
			guard.call("apply_archetype_metadata", _author_prop(author, "guard_archetype", &"grunt"))
		var behavior_payload := _build_authoring_behavior_payload(author, payload)
		if guard.has_method("apply_authoring_spawn_behavior"):
			guard.call("apply_authoring_spawn_behavior", _author_prop(author, "initial_behavior", &"attack_player"), behavior_payload)
		var route_id := String(_author_prop(author, "patrol_route_id", "")).strip_edges()
		_attempt_runtime_state["d6_04_last_guard_patrol_route_assigned"] = route_id != "" and behavior_payload.has("patrol_points")
		spawned.append(guard)
	var result := "spawned" if spawned.size() > 0 else "failed"
	var reason := "" if spawned.size() > 0 else "no_guards_created"
	_attempt_runtime_state["d6_03_last_guard_spawn_result"] = result
	_attempt_runtime_state["d6_03_last_guard_spawn_reason"] = reason
	_attempt_runtime_state["d6_03_last_spawned_guard_count"] = spawned.size()
	_attempt_runtime_state["d6_04_last_guard_initial_behavior"] = String(_author_prop(author, "initial_behavior", ""))
	_attempt_runtime_state["d6_04_last_guard_fallback_behavior"] = String(_author_prop(author, "fallback_behavior", ""))
	_attempt_runtime_state["attack_guard_spawned"] = _count_functional_security_response_guards()
	if spawned.size() > 0 and _should_authoring_guard_spawn_be_once_per_attempt(event_id, payload):
		_attempt_runtime_state[attempt_key] = true
	return {
		"handled": spawned.size() > 0,
		"result": result,
		"reason": reason,
		"spawned_count": spawned.size(),
		"spawned_guards": spawned,
	}


func _authoring_guard_spawn_attempt_key(author: Node, event_id: StringName) -> String:
	var spawn_id := String(_author_prop(author, "spawn_id", "guard_spawn"))
	return "author_guard_spawned:%s:%s" % [String(event_id).strip_edges(), spawn_id.strip_edges()]


func _should_authoring_guard_spawn_be_once_per_attempt(event_id: StringName, payload: Dictionary) -> bool:
	var source_type := String(payload.get("source_type", "")).strip_edges()
	if source_type == "security_beam_author":
		return true
	return String(event_id).strip_edges() == "ambush_beam_tripped"


func _build_authoring_behavior_payload(author: Node2D, payload: Dictionary) -> Dictionary:
	var out := payload.duplicate(true)
	out["fallback_behavior"] = String(_author_prop(author, "fallback_behavior", "security_net"))
	var route_id := String(_author_prop(author, "patrol_route_id", "")).strip_edges()
	if route_id != "":
		var sec_root := _find_security_authoring_root()
		if sec_root != null and sec_root.has_method("find_patrol_route"):
			var route := sec_root.call("find_patrol_route", StringName(route_id)) as Node2D
			if route != null and route.has_method("get_patrol_points_global"):
				out["patrol_points"] = route.call("get_patrol_points_global")
				out["loop_route"] = bool(_author_prop(route, "loop_route", true))
				out["patrol_direction"] = _author_prop(route, "direction", &"clockwise")
	var init_key := String(_author_prop(author, "initial_behavior", "")).strip_edges().to_lower()
	var fb_key := String(out.get("fallback_behavior", "")).strip_edges().to_lower()
	if init_key == "join_security_net" or fb_key in ["security_net", "join_security_net"]:
		var heat := GameState.get_mission_heat(mission_definition.mission_id) if mission_definition != null else 0
		var ordinal := _count_functional_security_response_guards()
		var role := _get_security_search_role(heat, ordinal)
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var base_pos := author.global_position
		if player != null and init_key == "join_security_net":
			base_pos = player.global_position
		var direction := 1 if (ordinal % 2 == 0) else -1
		var route_pts := _validate_security_search_route_points(_build_search_net_points(base_pos, heat, ordinal, role), base_pos)
		out["search_net"] = {
			"center": base_pos,
			"radius": _get_security_search_radius_for_heat(heat),
			"role": role,
			"ordinal": ordinal,
			"direction": direction,
			"route_points": route_pts,
		}
	if out.has("player_position"):
		out["investigate_position"] = out.get("player_position", author.global_position)
	return out


func _schedule_fix7_ambush_beam_physics_setup() -> void:
	## TileMap / static bodies may not be queryable on the same deferred frame as mission boot.
	var tree := get_tree()
	if tree == null:
		_setup_fix7_ambush_beam_runtime()
		return
	if tree.physics_frame.is_connected(_setup_fix7_ambush_beam_runtime):
		return
	tree.physics_frame.connect(_setup_fix7_ambush_beam_runtime, CONNECT_ONE_SHOT)


func _remove_d6_fix_test_warp_nodes() -> void:
	var props := get_node_or_null("EntityRoot/DynamicProps") as Node2D
	if props == null:
		return
	for n in ["D6_FIX4_GarageCodeTestWarp", "D6_FIX3_GarageCodeTestWarp"]:
		var node := props.get_node_or_null(n)
		if node != null:
			node.queue_free()


func _setup_d6_fix5_beam_visual_fallback() -> void:
	## FIX7A: legacy fallback intentionally disabled to avoid misleading old beam placement.
	## Keep method for compatibility with older debug reports, but no runtime action.
	return


## FIX7A: remove stale temporary beam runtime visuals from prior passes.
func _remove_fix7_stale_temp_beam_nodes() -> void:
	var root := get_node_or_null("GameplayRoot/RuntimeSystems") as Node2D
	if root == null:
		root = get_node_or_null("GameplayRoot") as Node2D
	if root == null:
		return
	for stale_name in [
		"D6_FIX3_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS",
		"D6_FIX4_TEMP_BEAM_WORLD_VISUAL_REMOVE_IN_FINAL_LEVEL_PASS",
		"D6_FIX5_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS",
		"D6_FIX6_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS",
		"D6_FIX6A_TEMP_SECURITY_BEAM_LOCATOR_REMOVE_OR_FINALIZE_IN_LEVEL_PASS",
		"D6_FIX6B_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS",
		"SecurityBeam_Ambush_RightHallway",
	]:
		var node := root.get_node_or_null(stale_name)
		if node != null:
			node.queue_free()
	## Also remove old FIX6B visual attached to root aliases if present.
	var old_alias := root.get_node_or_null("RightHallwayBeamSpan")
	if old_alias != null:
		old_alias.queue_free()


func _clear_fix7b_ambush_beam_runtime_state() -> void:
	for k in [
		"fix7b_ambush_beam_orientation",
		"fix7b_ambush_beam_anchor_position",
		"fix7b_ambush_beam_center",
		"fix7b_ambush_beam_center_offset",
		"fix7b_ambush_beam_visual_width",
		"fix7b_ambush_beam_trigger_width",
		"fix7b_ambush_beam_height",
		"fix7b_ambush_beam_trigger_size",
		"fix7b_ambush_beam_status",
		"fix7b_ambush_beam_visual_path",
		"fix7b_ambush_beam_trigger_path",
		"fix7b_ambush_beam_visual_trigger_mismatch_px",
		"fix7d_ambush_beam_mode",
		"fix7d_collision_boundary_success",
		"fix7d_choke_x",
		"fix7d_choke_source",
		"fix7d_probe_y",
		"fix7d_top_boundary_y",
		"fix7d_bottom_boundary_y",
		"fix7d_failure_reason",
		"fix7d_fallback_used",
		"fix7e_mode",
		"fix7e_collision_ok",
		"fix7e_fallback_used",
		"fix7e_choke_x",
		"fix7e_probe_y",
		"fix7e_top_hit_y",
		"fix7e_bottom_hit_y",
		"fix7e_visual_top_y",
		"fix7e_visual_bottom_y",
		"fix7e_visual_height",
		"fix7e_trigger_top_y",
		"fix7e_trigger_bottom_y",
		"fix7e_trigger_height",
		"fix7e_reason",
		"fix7e_visual_trigger_mismatch_px",
		"fix7f_mode",
		"fix7f_success",
		"fix7f_fallback_used",
		"fix7f_seed_x",
		"fix7f_chosen_x",
		"fix7f_x_shift_from_seed",
		"fix7f_probe_y",
		"fix7f_chosen_probe_y",
		"fix7f_candidate_count",
		"fix7f_rejected_inside_wall",
		"fix7f_rejected_missing_hits",
		"fix7f_rejected_height",
		"fix7f_rejected_visual_overlap",
		"fix7f_rejected_trigger_overlap",
		"fix7f_top_hit_y",
		"fix7f_bottom_hit_y",
		"fix7f_visual_top_y",
		"fix7f_visual_bottom_y",
		"fix7f_visual_height",
		"fix7f_trigger_top_y",
		"fix7f_trigger_bottom_y",
		"fix7f_trigger_height",
		"fix7f_visual_overlap_ok",
		"fix7f_trigger_overlap_ok",
		"fix7f_reason",
		"d6_02_security_authoring_root_found",
		"d6_02_security_authoring_beam_count",
		"d6_02_ambush_beam_source",
		"d6_02_ambush_beam_author_path",
		"d6_02_ambush_beam_author_enabled",
		"d6_02_ambush_beam_center",
		"d6_02_ambush_beam_visual_height",
		"d6_02_ambush_beam_visual_width",
		"d6_02_ambush_beam_trigger_width",
		"d6_02_ambush_beam_trigger_height",
		"d6_02_ambush_beam_trigger_extra_height",
		"d6_02_ambush_beam_trigger_size",
		"d6_02_ambush_beam_trip_count",
		"d6_02_ambush_beam_runtime_status",
		"d6_02_ambush_beam_validation_status",
		"d6_02_authored_camera_count",
		"d6_02_authored_guard_spawn_count",
		"d6_02_authored_patrol_route_count",
		"d6_03_security_router_active",
		"d6_03_registered_event_count",
		"d6_03_last_dispatched_event",
		"d6_03_last_guard_spawn_author_id",
		"d6_03_last_guard_spawn_result",
		"d6_03_last_guard_spawn_reason",
		"d6_03_last_spawned_guard_count",
		"d6_03_beam_event_route_used",
		"d6_03_beam_direct_fallback_suppressed",
		"d6_03_duplicate_spawn_avoided",
		"d6_03_authored_area_trigger_count",
		"d6_04_last_event_listeners_registered",
		"d6_04_last_event_listeners_called",
		"d6_04_last_event_listeners_handled",
		"d6_04_last_event_listeners_rejected",
		"d6_04_last_event_handled",
		"d6_04_last_event_rejection_reasons",
		"d6_04_last_successful_listener_paths",
		"d6_04_runtime_authored_camera_count",
		"d6_04_last_camera_id",
		"d6_04_last_camera_detect_event",
		"d6_04_last_camera_alarm_event",
		"d6_04_last_camera_alarm_handled",
		"d6_04_last_camera_source_path",
		"d6_04_last_beam_event_handled",
		"d6_04_last_guard_initial_behavior",
		"d6_04_last_guard_fallback_behavior",
		"d6_04_last_guard_patrol_route_assigned",
	]:
		_attempt_runtime_state.erase(k)


func _find_fix7d_spawn_route_louis_return_marker() -> Node2D:
	var m := _find_authoring_marker("", "spawn_route_louis_return")
	if m is Node2D:
		return m as Node2D
	m = _find_runtime_debug_marker("spawn_route_louis_return")
	return m as Node2D


func _raycast_fix7e_boundary(space: PhysicsDirectSpaceState2D, origin: Vector2, direction: Vector2, length: float) -> Dictionary:
	var to := origin + direction.normalized() * length
	var q := PhysicsRayQueryParameters2D.create(origin, to)
	q.collision_mask = D6_FIX7E_COLLISION_MASK
	q.collide_with_areas = false
	q.collide_with_bodies = true
	return space.intersect_ray(q)


func _fix7e_finalize_fallback(out: Dictionary, choke_x: float, probe_y: float, mode: String, reason: String, rays_ok: bool) -> void:
	out["mode"] = mode
	out["fallback_used"] = true
	out["success"] = false
	out["collision_ok"] = rays_ok
	out["reason"] = reason
	var vh := D6_FIX7E_FALLBACK_VISUAL_HEIGHT
	var th := D6_FIX7E_FALLBACK_TRIGGER_HEIGHT
	out["visual_top_y"] = probe_y - vh * 0.5
	out["visual_bottom_y"] = probe_y + vh * 0.5
	out["visual_height"] = vh
	out["trigger_top_y"] = probe_y - th * 0.5
	out["trigger_bottom_y"] = probe_y + th * 0.5
	out["trigger_height"] = th
	out["center"] = Vector2(choke_x, probe_y)


func _compute_fix7e_ambush_beam_inner_gap(anchor_pos: Vector2) -> Dictionary:
	var out := {
		"mode": "fallback_missing_collision",
		"collision_ok": false,
		"fallback_used": true,
		"success": false,
		"choke_x": anchor_pos.x,
		"choke_source": "",
		"probe_y": anchor_pos.y,
		"top_hit_y": -1.0,
		"bottom_hit_y": -1.0,
		"visual_top_y": 0.0,
		"visual_bottom_y": 0.0,
		"visual_height": D6_FIX7E_FALLBACK_VISUAL_HEIGHT,
		"trigger_top_y": 0.0,
		"trigger_bottom_y": 0.0,
		"trigger_height": D6_FIX7E_FALLBACK_TRIGGER_HEIGHT,
		"center": Vector2(anchor_pos.x, anchor_pos.y),
		"reason": "",
	}
	var choke_x := anchor_pos.x
	var choke_src := "anchor_x_only_spawn_marker_missing"
	var spawn_m := _find_fix7d_spawn_route_louis_return_marker()
	if spawn_m is Node2D:
		choke_x = (spawn_m as Node2D).global_position.x
		choke_src = "spawn_route_louis_return"
	var probe_y := anchor_pos.y
	if spawn_m is Node2D:
		var sy := (spawn_m as Node2D).global_position.y
		probe_y = (anchor_pos.y + sy) * 0.5
	out["choke_x"] = choke_x
	out["choke_source"] = choke_src
	out["probe_y"] = probe_y
	var w2d := get_world_2d()
	if w2d == null:
		_fix7e_finalize_fallback(out, choke_x, probe_y, "fallback_missing_collision", "world_2d_null", false)
		return out
	var space := w2d.direct_space_state
	if space == null:
		_fix7e_finalize_fallback(out, choke_x, probe_y, "fallback_missing_collision", "direct_space_state_null", false)
		return out
	var from := Vector2(choke_x, probe_y)
	var up := _raycast_fix7e_boundary(space, from, Vector2.UP, D6_FIX7E_RAY_PROBE_LENGTH)
	var dn := _raycast_fix7e_boundary(space, from, Vector2.DOWN, D6_FIX7E_RAY_PROBE_LENGTH)
	if up.is_empty() or dn.is_empty():
		_fix7e_finalize_fallback(out, choke_x, probe_y, "fallback_missing_collision", "vertical_ray_miss_one_or_both_directions", false)
		return out
	var top_hit: float = up.position.y
	var bottom_hit: float = dn.position.y
	out["top_hit_y"] = top_hit
	out["bottom_hit_y"] = bottom_hit
	if bottom_hit <= top_hit + D6_FIX7E_INNER_GAP_MIN_EPS:
		_fix7e_finalize_fallback(out, choke_x, probe_y, "fallback_clamped", "corridor_hit_order_inverted_or_degenerate", false)
		return out
	var v_top := top_hit + D6_FIX7E_VISUAL_WALL_OVERLAP_PX
	var v_bottom := bottom_hit - D6_FIX7E_VISUAL_WALL_OVERLAP_PX
	var v_h: float = v_bottom - v_top
	if v_h < D6_FIX7E_MIN_VISUAL_HEIGHT:
		_fix7e_finalize_fallback(out, choke_x, probe_y, "fallback_clamped", "collision_inner_gap_too_small", true)
		return out
	if v_h > D6_FIX7E_MAX_VISUAL_HEIGHT:
		_fix7e_finalize_fallback(out, choke_x, probe_y, "fallback_clamped", "collision_inner_gap_exceeds_max_clamped", true)
		return out
	out["mode"] = "collision_inner_gap"
	out["collision_ok"] = true
	out["fallback_used"] = false
	out["success"] = true
	out["reason"] = ""
	out["visual_top_y"] = v_top
	out["visual_bottom_y"] = v_bottom
	out["visual_height"] = v_h
	out["trigger_top_y"] = v_top - D6_FIX7E_TRIGGER_WALL_OVERLAP_PX
	out["trigger_bottom_y"] = v_bottom + D6_FIX7E_TRIGGER_WALL_OVERLAP_PX
	var tr_top: float = float(out["trigger_top_y"])
	var tr_bot: float = float(out["trigger_bottom_y"])
	out["trigger_height"] = tr_bot - tr_top
	out["center"] = Vector2(choke_x, (v_top + v_bottom) * 0.5)
	return out


func _apply_fix7e_ambush_beam_geometry(beam_area: Area2D, _beam_visual_host: Node2D, geom: Dictionary) -> void:
	if beam_area == null:
		return
	var th := float(geom.get("trigger_height", D6_FIX7E_FALLBACK_TRIGGER_HEIGHT))
	_apply_fix7d_ambush_beam_rectangle_shape(beam_area, Vector2(D6_FIX7E_AMBUSH_BEAM_TRIGGER_WIDTH, th))


func _raycast_fix7f_vertical(space: PhysicsDirectSpaceState2D, origin: Vector2, upward: bool) -> Dictionary:
	var dir := Vector2.UP if upward else Vector2.DOWN
	var to := origin + dir * D6_FIX7F_RAY_PROBE_LENGTH
	var q := PhysicsRayQueryParameters2D.create(origin, to)
	q.collision_mask = D6_FIX7F_COLLISION_MASK
	q.collide_with_areas = false
	q.collide_with_bodies = true
	return space.intersect_ray(q)


func _fix7f_point_blocked(space: PhysicsDirectSpaceState2D, p: Vector2) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = p
	params.collision_mask = D6_FIX7F_COLLISION_MASK
	params.collide_with_areas = false
	params.collide_with_bodies = true
	return space.intersect_point(params, 1).size() > 0


func _fix7f_passage_walkable(
	space: PhysicsDirectSpaceState2D,
	center: Vector2,
	half_width: float,
	top_y: float,
	bottom_y: float,
) -> bool:
	if _fix7f_point_blocked(space, center):
		return false
	var mid_y: float = (top_y + bottom_y) * 0.5
	var span: float = bottom_y - top_y
	if span <= 1.0:
		return false
	var offsets: Array[Vector2] = [
		Vector2(-half_width, 0.0),
		Vector2(half_width, 0.0),
	]
	for frac in [0.2, 0.5, 0.8]:
		var y: float = top_y + span * frac
		offsets.append(Vector2(0.0, y - mid_y))
	for off in offsets:
		if _fix7f_point_blocked(space, center + off):
			return false
	return true


func _probe_fix7f_candidate_doorway_x(
	space: PhysicsDirectSpaceState2D,
	candidate_x: float,
	probe_y: float,
	stats: Dictionary,
) -> Dictionary:
	stats["candidate_count"] = int(stats.get("candidate_count", 0)) + 1
	var origin := Vector2(candidate_x, probe_y)
	if _fix7f_point_blocked(space, origin):
		stats["rejected_inside_wall"] = int(stats.get("rejected_inside_wall", 0)) + 1
		return {}
	var up := _raycast_fix7f_vertical(space, origin, true)
	var dn := _raycast_fix7f_vertical(space, origin, false)
	if up.is_empty() or dn.is_empty():
		stats["rejected_missing_hits"] = int(stats.get("rejected_missing_hits", 0)) + 1
		return {}
	var top_hit: float = up.position.y
	var bottom_hit: float = dn.position.y
	if bottom_hit <= top_hit + D6_FIX7E_INNER_GAP_MIN_EPS:
		stats["rejected_missing_hits"] = int(stats.get("rejected_missing_hits", 0)) + 1
		return {}
	var v_top := top_hit + D6_FIX7F_VISUAL_WALL_OVERLAP_PX
	var v_bottom := bottom_hit - D6_FIX7F_VISUAL_WALL_OVERLAP_PX
	var v_h: float = v_bottom - v_top
	if v_h < D6_FIX7F_MIN_VISUAL_HEIGHT or v_h > D6_FIX7F_MAX_VISUAL_HEIGHT:
		stats["rejected_height"] = int(stats.get("rejected_height", 0)) + 1
		return {}
	var center := Vector2(candidate_x, (v_top + v_bottom) * 0.5)
	if not _fix7f_passage_walkable(
		space,
		center,
		D6_FIX7F_AMBUSH_BEAM_VISUAL_WIDTH * 0.5,
		v_top,
		v_bottom,
	):
		stats["rejected_visual_overlap"] = int(stats.get("rejected_visual_overlap", 0)) + 1
		return {}
	var tr_top := v_top - D6_FIX7F_TRIGGER_WALL_OVERLAP_PX
	var tr_bot := v_bottom + D6_FIX7F_TRIGGER_WALL_OVERLAP_PX
	var tr_h: float = tr_bot - tr_top
	var trigger_size := Vector2(D6_FIX7F_AMBUSH_BEAM_TRIGGER_WIDTH, tr_h)
	if not _fix7f_passage_walkable(
		space,
		center,
		D6_FIX7F_AMBUSH_BEAM_TRIGGER_WIDTH * 0.5,
		tr_top,
		tr_bot,
	):
		stats["rejected_trigger_overlap"] = int(stats.get("rejected_trigger_overlap", 0)) + 1
		return {}
	var seed_x: float = float(stats.get("seed_x", candidate_x))
	var seed_probe_y: float = float(stats.get("seed_probe_y", probe_y))
	var dist_seed: float = absf(candidate_x - seed_x) + absf(probe_y - seed_probe_y) * 0.35
	var height_penalty: float = absf(v_h - D6_FIX7F_IDEAL_VISUAL_HEIGHT) * 0.15
	var score: float = dist_seed + height_penalty
	return {
		"candidate_x": candidate_x,
		"probe_y": probe_y,
		"top_hit_y": top_hit,
		"bottom_hit_y": bottom_hit,
		"visual_top_y": v_top,
		"visual_bottom_y": v_bottom,
		"visual_height": v_h,
		"trigger_top_y": tr_top,
		"trigger_bottom_y": tr_bot,
		"trigger_height": tr_h,
		"center": center,
		"trigger_size": trigger_size,
		"score": score,
		"visual_overlap_ok": true,
		"trigger_overlap_ok": true,
	}


func _fix7f_build_geom_from_candidate(cand: Dictionary, mode: String, success: bool, fallback_used: bool, reason: String) -> Dictionary:
	return {
		"mode": mode,
		"success": success,
		"fallback_used": fallback_used,
		"collision_ok": success,
		"reason": reason,
		"choke_x": float(cand.get("candidate_x", 0.0)),
		"probe_y": float(cand.get("probe_y", 0.0)),
		"top_hit_y": float(cand.get("top_hit_y", -1.0)),
		"bottom_hit_y": float(cand.get("bottom_hit_y", -1.0)),
		"visual_top_y": float(cand.get("visual_top_y", 0.0)),
		"visual_bottom_y": float(cand.get("visual_bottom_y", 0.0)),
		"visual_height": float(cand.get("visual_height", D6_FIX7F_FALLBACK_VISUAL_HEIGHT)),
		"trigger_top_y": float(cand.get("trigger_top_y", 0.0)),
		"trigger_bottom_y": float(cand.get("trigger_bottom_y", 0.0)),
		"trigger_height": float(cand.get("trigger_height", D6_FIX7F_FALLBACK_TRIGGER_HEIGHT)),
		"center": cand.get("center", Vector2.ZERO),
		"trigger_size": cand.get("trigger_size", Vector2(D6_FIX7F_AMBUSH_BEAM_TRIGGER_WIDTH, D6_FIX7F_FALLBACK_TRIGGER_HEIGHT)),
		"visual_overlap_ok": cand.get("visual_overlap_ok", false),
		"trigger_overlap_ok": cand.get("trigger_overlap_ok", false),
		"stats": cand.get("stats", {}),
	}


func _fix7f_finalize_safe_fallback(
	out: Dictionary,
	seed_x: float,
	seed_probe_y: float,
	stats: Dictionary,
	reason: String,
) -> Dictionary:
	var vh := D6_FIX7F_FALLBACK_VISUAL_HEIGHT
	var th := D6_FIX7F_FALLBACK_TRIGGER_HEIGHT
	var cand := {
		"candidate_x": seed_x,
		"probe_y": seed_probe_y,
		"top_hit_y": -1.0,
		"bottom_hit_y": -1.0,
		"visual_top_y": seed_probe_y - vh * 0.5,
		"visual_bottom_y": seed_probe_y + vh * 0.5,
		"visual_height": vh,
		"trigger_top_y": seed_probe_y - th * 0.5,
		"trigger_bottom_y": seed_probe_y + th * 0.5,
		"trigger_height": th,
		"center": Vector2(seed_x, seed_probe_y),
		"trigger_size": Vector2(D6_FIX7F_AMBUSH_BEAM_TRIGGER_WIDTH, th),
		"visual_overlap_ok": false,
		"trigger_overlap_ok": false,
		"stats": stats,
	}
	var built := _fix7f_build_geom_from_candidate(cand, "fallback_safe", false, true, reason)
	for k in built.keys():
		out[k] = built[k]
	out["seed_x"] = seed_x
	out["chosen_x"] = seed_x
	out["x_shift_from_seed"] = 0.0
	out["chosen_probe_y"] = seed_probe_y
	out["stats"] = stats
	out["candidate_count"] = int(stats.get("candidate_count", 0))
	out["rejected_inside_wall"] = int(stats.get("rejected_inside_wall", 0))
	out["rejected_missing_hits"] = int(stats.get("rejected_missing_hits", 0))
	out["rejected_height"] = int(stats.get("rejected_height", 0))
	out["rejected_visual_overlap"] = int(stats.get("rejected_visual_overlap", 0))
	out["rejected_trigger_overlap"] = int(stats.get("rejected_trigger_overlap", 0))
	return out


func _compute_fix7f_ambush_beam_doorway_rect(anchor_pos: Vector2) -> Dictionary:
	var out := {
		"mode": "fallback_safe",
		"success": false,
		"fallback_used": true,
		"collision_ok": false,
		"reason": "",
		"seed_x": anchor_pos.x,
		"chosen_x": anchor_pos.x,
		"x_shift_from_seed": 0.0,
		"probe_y": anchor_pos.y,
		"chosen_probe_y": anchor_pos.y,
		"stats": {},
	}
	var seed_x := anchor_pos.x
	var spawn_m := _find_fix7d_spawn_route_louis_return_marker()
	if spawn_m is Node2D:
		seed_x = (spawn_m as Node2D).global_position.x
	var seed_probe_y := anchor_pos.y
	if spawn_m is Node2D:
		var sy := (spawn_m as Node2D).global_position.y
		seed_probe_y = (anchor_pos.y + sy) * 0.5
		## Prefer spawn-route Y when midpoint lands in a narrow collision pocket.
		if absf(anchor_pos.y - sy) > 80.0:
			seed_probe_y = sy
	out["seed_x"] = seed_x
	out["probe_y"] = seed_probe_y
	var w2d := get_world_2d()
	if w2d == null:
		return _fix7f_finalize_safe_fallback(out, seed_x, seed_probe_y, {}, "world_2d_null")
	var space := w2d.direct_space_state
	if space == null:
		return _fix7f_finalize_safe_fallback(out, seed_x, seed_probe_y, {}, "direct_space_state_null")
	var stats := {
		"seed_x": seed_x,
		"seed_probe_y": seed_probe_y,
		"candidate_count": 0,
		"rejected_inside_wall": 0,
		"rejected_missing_hits": 0,
		"rejected_height": 0,
		"rejected_visual_overlap": 0,
		"rejected_trigger_overlap": 0,
	}
	var best: Dictionary = {}
	var best_score := INF
	var x := seed_x + D6_FIX7F_SEARCH_X_MIN_OFFSET
	while x <= seed_x + D6_FIX7F_SEARCH_X_MAX_OFFSET + 0.001:
		var py := seed_probe_y - D6_FIX7F_SEARCH_Y_RANGE
		while py <= seed_probe_y + D6_FIX7F_SEARCH_Y_RANGE + 0.001:
			var cand := _probe_fix7f_candidate_doorway_x(space, x, py, stats)
			if not cand.is_empty():
				var sc: float = float(cand.get("score", INF))
				if sc < best_score:
					best_score = sc
					best = cand
			py += D6_FIX7F_SEARCH_Y_STEP
		x += D6_FIX7F_SEARCH_X_STEP
	out["stats"] = stats
	out["candidate_count"] = int(stats.get("candidate_count", 0))
	out["rejected_inside_wall"] = int(stats.get("rejected_inside_wall", 0))
	out["rejected_missing_hits"] = int(stats.get("rejected_missing_hits", 0))
	out["rejected_height"] = int(stats.get("rejected_height", 0))
	out["rejected_visual_overlap"] = int(stats.get("rejected_visual_overlap", 0))
	out["rejected_trigger_overlap"] = int(stats.get("rejected_trigger_overlap", 0))
	if best.is_empty():
		return _fix7f_finalize_safe_fallback(
			out,
			seed_x,
			seed_probe_y,
			stats,
			"no_valid_doorway_candidate_in_search_grid",
		)
	best["stats"] = stats
	var built := _fix7f_build_geom_from_candidate(best, "doorway_rect", true, false, "")
	out.merge(built, true)
	out["seed_x"] = seed_x
	out["chosen_x"] = float(best.get("candidate_x", seed_x))
	out["x_shift_from_seed"] = out["chosen_x"] - seed_x
	out["chosen_probe_y"] = float(best.get("probe_y", seed_probe_y))
	out["stats"] = stats
	return out


func _apply_fix7f_ambush_beam_geometry(beam_area: Area2D, geom: Dictionary) -> void:
	if beam_area == null:
		return
	var trig_sz: Vector2 = geom.get("trigger_size", Vector2(D6_FIX7F_AMBUSH_BEAM_TRIGGER_WIDTH, D6_FIX7F_FALLBACK_TRIGGER_HEIGHT))
	_apply_fix7d_ambush_beam_rectangle_shape(beam_area, trig_sz)


func _attach_fix7f_debug_markers(host: Node2D, geom: Dictionary, seed_pos: Vector2) -> void:
	var old := host.get_node_or_null("Fix7fDebugMarkers")
	if old != null:
		old.queue_free()
	var dbg := Node2D.new()
	dbg.name = "Fix7fDebugMarkers"
	dbg.set_meta("D6_FIX7F_TEMP_DEBUG_MARKERS_REMOVE_IN_LEVEL_PASS", true)
	dbg.z_index = 2599
	host.add_child(dbg)
	var chosen: Vector2 = geom.get("center", Vector2.ZERO)
	_add_fix7f_debug_dot(dbg, "Seed", seed_pos, Color(1.0, 1.0, 0.2, 0.9))
	_add_fix7f_debug_dot(dbg, "Center", chosen, Color(0.2, 1.0, 0.4, 0.9))
	var v_top: float = float(geom.get("visual_top_y", 0.0))
	var v_bot: float = float(geom.get("visual_bottom_y", 0.0))
	var cx: float = chosen.x
	_add_fix7f_debug_dot(dbg, "TopHit", Vector2(cx, float(geom.get("top_hit_y", v_top))), Color(1.0, 0.5, 0.2, 0.85))
	_add_fix7f_debug_dot(dbg, "BottomHit", Vector2(cx, float(geom.get("bottom_hit_y", v_bot))), Color(1.0, 0.5, 0.2, 0.85))
	_add_fix7f_debug_dot(dbg, "VisualTop", Vector2(cx, v_top), Color(1.0, 0.2, 0.2, 0.95))
	_add_fix7f_debug_dot(dbg, "VisualBottom", Vector2(cx, v_bot), Color(1.0, 0.2, 0.2, 0.95))
	var tr_top: float = float(geom.get("trigger_top_y", v_top))
	var tr_bot: float = float(geom.get("trigger_bottom_y", v_bot))
	_add_fix7f_debug_dot(dbg, "TriggerTop", Vector2(cx, tr_top), Color(0.6, 0.2, 1.0, 0.75))
	_add_fix7f_debug_dot(dbg, "TriggerBottom", Vector2(cx, tr_bot), Color(0.6, 0.2, 1.0, 0.75))


func _add_fix7f_debug_dot(parent: Node2D, label_name: String, global_pos: Vector2, color: Color) -> void:
	var n := Node2D.new()
	n.name = "Fix7f_" + label_name
	parent.add_child(n)
	n.global_position = global_pos
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4),
	])
	n.add_child(poly)


func _store_fix7f_runtime_state(geom: Dictionary) -> void:
	var stats: Dictionary = geom.get("stats", {})
	_attempt_runtime_state["fix7f_mode"] = String(geom.get("mode", "unknown"))
	_attempt_runtime_state["fix7f_success"] = bool(geom.get("success", false))
	_attempt_runtime_state["fix7f_fallback_used"] = bool(geom.get("fallback_used", true))
	_attempt_runtime_state["fix7f_seed_x"] = float(geom.get("seed_x", 0.0))
	_attempt_runtime_state["fix7f_chosen_x"] = float(geom.get("chosen_x", geom.get("choke_x", 0.0)))
	_attempt_runtime_state["fix7f_x_shift_from_seed"] = float(geom.get("x_shift_from_seed", 0.0))
	_attempt_runtime_state["fix7f_probe_y"] = float(geom.get("probe_y", 0.0))
	_attempt_runtime_state["fix7f_chosen_probe_y"] = float(geom.get("chosen_probe_y", geom.get("probe_y", 0.0)))
	_attempt_runtime_state["fix7f_candidate_count"] = int(geom.get("candidate_count", stats.get("candidate_count", 0)))
	_attempt_runtime_state["fix7f_rejected_inside_wall"] = int(geom.get("rejected_inside_wall", stats.get("rejected_inside_wall", 0)))
	_attempt_runtime_state["fix7f_rejected_missing_hits"] = int(geom.get("rejected_missing_hits", stats.get("rejected_missing_hits", 0)))
	_attempt_runtime_state["fix7f_rejected_height"] = int(geom.get("rejected_height", stats.get("rejected_height", 0)))
	_attempt_runtime_state["fix7f_rejected_visual_overlap"] = int(geom.get("rejected_visual_overlap", stats.get("rejected_visual_overlap", 0)))
	_attempt_runtime_state["fix7f_rejected_trigger_overlap"] = int(geom.get("rejected_trigger_overlap", stats.get("rejected_trigger_overlap", 0)))
	_attempt_runtime_state["fix7f_top_hit_y"] = float(geom.get("top_hit_y", -1.0))
	_attempt_runtime_state["fix7f_bottom_hit_y"] = float(geom.get("bottom_hit_y", -1.0))
	_attempt_runtime_state["fix7f_visual_top_y"] = float(geom.get("visual_top_y", 0.0))
	_attempt_runtime_state["fix7f_visual_bottom_y"] = float(geom.get("visual_bottom_y", 0.0))
	_attempt_runtime_state["fix7f_visual_height"] = float(geom.get("visual_height", 0.0))
	_attempt_runtime_state["fix7f_trigger_top_y"] = float(geom.get("trigger_top_y", 0.0))
	_attempt_runtime_state["fix7f_trigger_bottom_y"] = float(geom.get("trigger_bottom_y", 0.0))
	_attempt_runtime_state["fix7f_trigger_height"] = float(geom.get("trigger_height", 0.0))
	_attempt_runtime_state["fix7f_visual_overlap_ok"] = bool(geom.get("visual_overlap_ok", false))
	_attempt_runtime_state["fix7f_trigger_overlap_ok"] = bool(geom.get("trigger_overlap_ok", false))
	_attempt_runtime_state["fix7f_reason"] = String(geom.get("reason", ""))


func _fix7d_intersect_vertical_ray(space: PhysicsDirectSpaceState2D, from: Vector2, upward: bool) -> Dictionary:
	var to := from + Vector2(0.0, -D6_FIX7D_RAY_PROBE_LENGTH if upward else D6_FIX7D_RAY_PROBE_LENGTH)
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = D6_FIX7D_COLLISION_MASK
	q.collide_with_areas = false
	q.collide_with_bodies = true
	return space.intersect_ray(q)


func _probe_fix7d_vertical_wall_boundaries(space: PhysicsDirectSpaceState2D, choke_x: float, probe_ys: Array) -> Dictionary:
	var best_gap := -1.0
	var best: Dictionary = {}
	for probe_y in probe_ys:
		var from := Vector2(choke_x, float(probe_y))
		var up := _fix7d_intersect_vertical_ray(space, from, true)
		var dn := _fix7d_intersect_vertical_ray(space, from, false)
		if up.is_empty() or dn.is_empty():
			continue
		var uy: float = up.position.y
		var dy: float = dn.position.y
		if dy <= uy + D6_FIX7D_MIN_CORRIDOR_HEIGHT:
			continue
		var gap: float = dy - uy
		if gap > best_gap:
			best_gap = gap
			best = {"probe_y": float(probe_y), "uy": uy, "dy": dy, "from": from}
	if best.is_empty():
		return {}
	var top_y: float = float(best["uy"]) - D6_FIX7D_AMBUSH_BEAM_WALL_OVERLAP_PX
	var bottom_y: float = float(best["dy"]) + D6_FIX7D_AMBUSH_BEAM_WALL_OVERLAP_PX
	best["top_y"] = top_y
	best["bottom_y"] = bottom_y
	return best


func _compute_fix7d_ambush_beam_from_collision(anchor_pos: Vector2) -> Dictionary:
	var out := {
		"success": false,
		"mode": "fallback",
		"reason": "",
		"anchor_pos": anchor_pos,
		"choke_x": anchor_pos.x,
		"choke_source": "",
		"probe_y": anchor_pos.y,
		"top_y": 0.0,
		"bottom_y": 0.0,
		"center": Vector2.ZERO,
		"height": D6_FIX7D_FALLBACK_HEIGHT,
		"trigger_size": Vector2(D6_FIX7D_AMBUSH_BEAM_TRIGGER_WIDTH, D6_FIX7D_FALLBACK_HEIGHT),
	}
	var w2d := get_world_2d()
	if w2d == null:
		out["reason"] = "world_2d_null"
		return out
	var space := w2d.direct_space_state
	if space == null:
		out["reason"] = "direct_space_state_null"
		return out
	var choke_src := ""
	var choke_x := anchor_pos.x
	var spawn_m := _find_fix7d_spawn_route_louis_return_marker()
	if spawn_m is Node2D:
		choke_x = (spawn_m as Node2D).global_position.x
		choke_src = "spawn_route_louis_return"
	else:
		choke_src = "anchor_x_only_spawn_marker_missing"
	var probe_ys: Array = [anchor_pos.y]
	if spawn_m is Node2D:
		var sy := (spawn_m as Node2D).global_position.y
		probe_ys.append(sy)
		probe_ys.append((sy + anchor_pos.y) * 0.5)
	var probe_result := _probe_fix7d_vertical_wall_boundaries(space, choke_x, probe_ys)
	if probe_result.is_empty():
		out["reason"] = "vertical_rays_did_not_hit_both_walls_or_corridor_too_narrow"
		out["choke_x"] = choke_x
		out["choke_source"] = choke_src
		out["top_y"] = -1.0
		out["bottom_y"] = -1.0
		out["center"] = anchor_pos + D6_FIX7D_FALLBACK_ANCHOR_OFFSET
		out["height"] = D6_FIX7D_FALLBACK_HEIGHT
		out["trigger_size"] = Vector2(D6_FIX7D_AMBUSH_BEAM_TRIGGER_WIDTH, D6_FIX7D_FALLBACK_HEIGHT)
		out["mode"] = "fallback"
		return out
	var top_y: float = float(probe_result["top_y"])
	var bottom_y: float = float(probe_result["bottom_y"])
	var height: float = bottom_y - top_y
	if height < D6_FIX7D_MIN_CORRIDOR_HEIGHT:
		out["reason"] = "computed_height_below_minimum"
		out["choke_x"] = choke_x
		out["choke_source"] = choke_src
		out["top_y"] = top_y
		out["bottom_y"] = bottom_y
		out["center"] = anchor_pos + D6_FIX7D_FALLBACK_ANCHOR_OFFSET
		out["height"] = D6_FIX7D_FALLBACK_HEIGHT
		out["trigger_size"] = Vector2(D6_FIX7D_AMBUSH_BEAM_TRIGGER_WIDTH, D6_FIX7D_FALLBACK_HEIGHT)
		out["mode"] = "fallback"
		return out
	var center := Vector2(choke_x, (top_y + bottom_y) * 0.5)
	out["success"] = true
	out["mode"] = "collision_boundary"
	out["reason"] = ""
	out["choke_x"] = choke_x
	out["choke_source"] = choke_src
	out["probe_y"] = float(probe_result["probe_y"])
	out["top_y"] = top_y
	out["bottom_y"] = bottom_y
	out["center"] = center
	out["height"] = height
	out["trigger_size"] = Vector2(D6_FIX7D_AMBUSH_BEAM_TRIGGER_WIDTH, height)
	return out


func _apply_fix7d_ambush_beam_rectangle_shape(area: Area2D, sz: Vector2) -> void:
	if area == null:
		return
	for child in area.get_children():
		if child is CollisionShape2D:
			var cs := child as CollisionShape2D
			if cs.shape is RectangleShape2D:
				(cs.shape as RectangleShape2D).size = sz
				return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sz
	shape.shape = rect
	area.add_child(shape)


func _find_security_authoring_root() -> Node2D:
	var node := get_node_or_null(D6_02_SECURITY_AUTHORING_ROOT_PATH)
	if node is Node2D and node.has_method("find_enabled_beam_author"):
		return node as Node2D
	return null


func _collect_security_authoring_counts(root: Node2D) -> Dictionary:
	if root == null:
		return {"beams": 0, "cameras": 0, "guards": 0, "patrols": 0}
	return {
		"beams": root.call("collect_beam_authors").size(),
		"cameras": root.call("collect_camera_authors").size(),
		"guards": root.call("collect_guard_spawn_authors").size(),
		"patrols": root.call("collect_patrol_route_authors").size(),
	}


func _store_d6_02_authoring_summary(
	root: Node2D,
	beam_source: String,
	author_path: String,
	author_enabled: bool,
	beam_center: Vector2,
	visual_h: float,
	visual_w: float,
	trig_sz: Vector2,
	trig_extra_h: float,
	runtime_status: String,
	validation_status: String = "ok",
) -> void:
	var counts := _collect_security_authoring_counts(root)
	_attempt_runtime_state["d6_02_security_authoring_root_found"] = root != null
	_attempt_runtime_state["d6_02_security_authoring_beam_count"] = int(counts.get("beams", 0))
	_attempt_runtime_state["d6_02_ambush_beam_source"] = beam_source
	_attempt_runtime_state["d6_02_ambush_beam_author_path"] = author_path
	_attempt_runtime_state["d6_02_ambush_beam_author_enabled"] = author_enabled
	_attempt_runtime_state["d6_02_ambush_beam_center"] = beam_center
	_attempt_runtime_state["d6_02_ambush_beam_visual_height"] = visual_h
	_attempt_runtime_state["d6_02_ambush_beam_visual_width"] = visual_w
	_attempt_runtime_state["d6_02_ambush_beam_trigger_width"] = trig_sz.x
	_attempt_runtime_state["d6_02_ambush_beam_trigger_height"] = trig_sz.y
	_attempt_runtime_state["d6_02_ambush_beam_trigger_extra_height"] = trig_extra_h
	_attempt_runtime_state["d6_02_ambush_beam_trigger_size"] = trig_sz
	_attempt_runtime_state["d6_02_ambush_beam_trip_count"] = _get_beam_trip_count()
	_attempt_runtime_state["d6_02_ambush_beam_runtime_status"] = runtime_status
	_attempt_runtime_state["d6_02_ambush_beam_validation_status"] = validation_status
	_attempt_runtime_state["d6_02_authored_camera_count"] = int(counts.get("cameras", 0))
	_attempt_runtime_state["d6_02_authored_guard_spawn_count"] = int(counts.get("guards", 0))
	_attempt_runtime_state["d6_02_authored_patrol_route_count"] = int(counts.get("patrols", 0))


func _get_beam_trip_count() -> int:
	var adapter := get_node_or_null("GameplayRoot/RuntimeSystems/MissionAlertController")
	if adapter == null:
		adapter = get_tree().get_first_node_in_group("iso_alert_controller")
	if adapter != null and adapter.has_method("get_event_kind_counts"):
		var kinds: Dictionary = adapter.call("get_event_kind_counts")
		return int(kinds.get("beam_trip", 0))
	return int(_attempt_runtime_state.get("beam_trip", 0))


func _setup_ambush_beam_from_security_beam_author(author: Node2D, root: Node2D) -> void:
	var cfg: Dictionary = author.call("build_runtime_config")
	var beam_center: Vector2 = cfg.get("center", author.global_position)
	var visual_h: float = float(cfg.get("visual_height", 170.0))
	var visual_w: float = float(cfg.get("visual_width", 32.0))
	var trig_sz: Vector2 = cfg.get("trigger_size", Vector2(72.0, visual_h))
	var trig_extra_h: float = float(cfg.get("trigger_extra_height", 0.0))
	var validation_status: String = String(cfg.get("validation_status", "ok"))
	var alarm_id: String = String(cfg.get("alarm_id", "AMBUSH_security_beam"))
	_attempt_runtime_state["fix7_ambush_beam_anchor_found"] = true
	_attempt_runtime_state["fix7_ambush_beam_anchor_path"] = String(author.get_path())
	_attempt_runtime_state["fix7_ambush_beam_anchor_resolve_source"] = "security_beam_author"
	_attempt_runtime_state["fix7_ambush_beam_anchor_position"] = author.global_position
	_attempt_runtime_state["fix7b_ambush_beam_orientation"] = "vertical"
	_attempt_runtime_state["fix7b_ambush_beam_anchor_position"] = author.global_position
	_attempt_runtime_state["fix7b_ambush_beam_center"] = beam_center
	_attempt_runtime_state["fix7b_ambush_beam_center_offset"] = beam_center - author.global_position
	_attempt_runtime_state["fix7b_ambush_beam_visual_width"] = visual_w
	_attempt_runtime_state["fix7b_ambush_beam_trigger_width"] = trig_sz.x
	_attempt_runtime_state["fix7b_ambush_beam_height"] = visual_h
	_attempt_runtime_state["fix7b_ambush_beam_trigger_size"] = trig_sz
	_attempt_runtime_state["fix7d_ambush_beam_mode"] = "authoring_node"
	_attempt_runtime_state["fix7d_collision_boundary_success"] = true
	_attempt_runtime_state["fix7d_choke_x"] = beam_center.x
	_attempt_runtime_state["fix7d_choke_source"] = "SecurityBeamAuthor"
	_attempt_runtime_state["fix7d_probe_y"] = beam_center.y
	_attempt_runtime_state["fix7d_top_boundary_y"] = beam_center.y - visual_h * 0.5
	_attempt_runtime_state["fix7d_bottom_boundary_y"] = beam_center.y + visual_h * 0.5
	_attempt_runtime_state["fix7d_failure_reason"] = ""
	_attempt_runtime_state["fix7d_fallback_used"] = false
	var alarm_zones := get_node_or_null("GameplayRoot/RuntimeSystems/AlarmZones") as Node2D
	var runtime_status := "armed"
	if alarm_zones == null:
		runtime_status = "visual_only_no_alarm_zone_parent"
		_store_d6_02_authoring_summary(
			root, "authoring_node", str(author.get_path()), bool(author.get("enabled")),
			beam_center, visual_h, visual_w, trig_sz, trig_extra_h, runtime_status, validation_status,
		)
		_attach_fix7_ambush_beam_visual(beam_center, null, visual_h * 0.5, {}, author.global_position, visual_w)
		return
	var beam_area := alarm_zones.get_node_or_null("AlarmZone_%s" % alarm_id) as Area2D
	if beam_area != null and beam_area.is_queued_for_deletion():
		beam_area = null
	if beam_area == null:
		beam_area = Area2D.new()
		beam_area.name = "AlarmZone_%s" % alarm_id
		alarm_zones.add_child(beam_area)
	_arm_d5_attempt_alarm_area(beam_area, alarm_id)
	_apply_fix7d_ambush_beam_rectangle_shape(beam_area, trig_sz)
	beam_area.global_position = beam_center
	_attach_fix7_ambush_beam_visual(beam_center, beam_area, visual_h * 0.5, {}, author.global_position, visual_w)
	_attempt_runtime_state["fix7e_visual_trigger_mismatch_px"] = float(_attempt_runtime_state.get("fix7_ambush_beam_visual_trigger_mismatch_px", -1.0))
	_store_d6_02_authoring_summary(
		root, "authoring_node", str(author.get_path()), bool(author.get("enabled")),
		beam_center, visual_h, visual_w, trig_sz, trig_extra_h, runtime_status, validation_status,
	)
	_setup_d6_03_authoring_security_runtime()


## D6-01-FIX7: canonical AMBUSH beam rebuild. D6-02: prefers hand-placed SecurityBeamAuthor when enabled.
func _setup_fix7_ambush_beam_runtime() -> void:
	if mission_definition == null or String(mission_definition.mission_id) != "taco_bell_drop":
		return
	var sec_root := _find_security_authoring_root()
	var beam_author: Node2D = null
	if sec_root != null and bool(sec_root.get("runtime_enabled")):
		beam_author = sec_root.call("find_enabled_beam_author", &"AMBUSH_security_beam") as Node2D
	if beam_author != null:
		_setup_ambush_beam_from_security_beam_author(beam_author, sec_root)
		return
	_store_d6_02_authoring_summary(
		sec_root, "fix7f_fallback", "", false, Vector2.ZERO, 0.0, 0.0, Vector2.ZERO, 0.0, "fix7f_fallback", "fix7f_fallback",
	)
	_setup_d6_03_authoring_security_runtime()
	var anchor_resolution_source := "authoring_marker_root"
	var ambush_anchor := _find_authoring_marker("", "AMBUSH_security_beam")
	if not (ambush_anchor is Node2D):
		ambush_anchor = _find_runtime_debug_marker("AMBUSH_security_beam")
		anchor_resolution_source = "runtime_debug_interactable_or_label"
	if not (ambush_anchor is Node2D):
		_clear_fix7b_ambush_beam_runtime_state()
		_attempt_runtime_state["fix7_ambush_beam_anchor_found"] = false
		_attempt_runtime_state["fix7_ambush_beam_anchor_path"] = "missing"
		_attempt_runtime_state["fix7_ambush_beam_anchor_resolve_source"] = "missing"
		_attempt_runtime_state["fix7_ambush_beam_anchor_position"] = Vector2.ZERO
		_attempt_runtime_state["fix7_ambush_beam_visual_center"] = Vector2.ZERO
		_attempt_runtime_state["fix7_ambush_beam_trigger_center"] = Vector2.ZERO
		_attempt_runtime_state["fix7_ambush_beam_visual_trigger_mismatch_px"] = -1.0
		_attempt_runtime_state["fix7_ambush_beam_status"] = "missing_anchor"
		_store_d6_02_authoring_summary(
			sec_root, "missing", "", false, Vector2.ZERO, 0.0, 0.0, Vector2.ZERO, 0.0, "missing_anchor", "missing_anchor",
		)
		_setup_d6_03_authoring_security_runtime()
		return
	var anchor_pos := (ambush_anchor as Node2D).global_position
	var geom := _compute_fix7f_ambush_beam_doorway_rect(anchor_pos)
	var beam_center: Vector2 = geom.get("center", Vector2.ZERO)
	var visual_h: float = float(geom.get("visual_height", 0.0))
	var trig_sz: Vector2 = geom.get("trigger_size", Vector2(D6_FIX7F_AMBUSH_BEAM_TRIGGER_WIDTH, D6_FIX7F_FALLBACK_TRIGGER_HEIGHT))
	var trig_h: float = trig_sz.y
	var computed_offset: Vector2 = beam_center - anchor_pos
	_attempt_runtime_state["fix7_ambush_beam_anchor_found"] = true
	_attempt_runtime_state["fix7_ambush_beam_anchor_path"] = String((ambush_anchor as Node2D).get_path())
	_attempt_runtime_state["fix7_ambush_beam_anchor_resolve_source"] = anchor_resolution_source
	_attempt_runtime_state["fix7_ambush_beam_anchor_position"] = anchor_pos
	_attempt_runtime_state["fix7b_ambush_beam_orientation"] = "vertical"
	_attempt_runtime_state["fix7b_ambush_beam_anchor_position"] = anchor_pos
	_attempt_runtime_state["fix7b_ambush_beam_center"] = beam_center
	_attempt_runtime_state["fix7b_ambush_beam_center_offset"] = computed_offset
	_attempt_runtime_state["fix7b_ambush_beam_visual_width"] = D6_FIX7F_AMBUSH_BEAM_VISUAL_WIDTH
	_attempt_runtime_state["fix7b_ambush_beam_trigger_width"] = trig_sz.x
	_attempt_runtime_state["fix7b_ambush_beam_height"] = visual_h
	_attempt_runtime_state["fix7b_ambush_beam_trigger_size"] = trig_sz
	_attempt_runtime_state["fix7d_ambush_beam_mode"] = String(geom.get("mode", "unknown"))
	_attempt_runtime_state["fix7d_collision_boundary_success"] = bool(geom.get("success", false))
	_attempt_runtime_state["fix7d_choke_x"] = float(geom.get("chosen_x", geom.get("choke_x", 0.0)))
	_attempt_runtime_state["fix7d_choke_source"] = "fix7f_doorway_rect"
	_attempt_runtime_state["fix7d_probe_y"] = float(geom.get("chosen_probe_y", geom.get("probe_y", 0.0)))
	_attempt_runtime_state["fix7d_top_boundary_y"] = float(geom.get("visual_top_y", -1.0))
	_attempt_runtime_state["fix7d_bottom_boundary_y"] = float(geom.get("visual_bottom_y", -1.0))
	_attempt_runtime_state["fix7d_failure_reason"] = String(geom.get("reason", ""))
	_attempt_runtime_state["fix7d_fallback_used"] = bool(geom.get("fallback_used", true))
	_store_fix7f_runtime_state(geom)
	_attempt_runtime_state["fix7e_mode"] = String(geom.get("mode", "unknown"))
	_attempt_runtime_state["fix7e_collision_ok"] = bool(geom.get("success", false))
	_attempt_runtime_state["fix7e_fallback_used"] = bool(geom.get("fallback_used", true))
	_attempt_runtime_state["fix7e_choke_x"] = float(geom.get("chosen_x", 0.0))
	_attempt_runtime_state["fix7e_probe_y"] = float(geom.get("chosen_probe_y", 0.0))
	_attempt_runtime_state["fix7e_top_hit_y"] = float(geom.get("top_hit_y", -1.0))
	_attempt_runtime_state["fix7e_bottom_hit_y"] = float(geom.get("bottom_hit_y", -1.0))
	_attempt_runtime_state["fix7e_visual_top_y"] = float(geom.get("visual_top_y", 0.0))
	_attempt_runtime_state["fix7e_visual_bottom_y"] = float(geom.get("visual_bottom_y", 0.0))
	_attempt_runtime_state["fix7e_visual_height"] = visual_h
	_attempt_runtime_state["fix7e_trigger_top_y"] = float(geom.get("trigger_top_y", 0.0))
	_attempt_runtime_state["fix7e_trigger_bottom_y"] = float(geom.get("trigger_bottom_y", 0.0))
	_attempt_runtime_state["fix7e_trigger_height"] = trig_h
	_attempt_runtime_state["fix7e_reason"] = String(geom.get("reason", ""))
	_attempt_runtime_state["fix7e_visual_trigger_mismatch_px"] = -1.0
	var alarm_zones := get_node_or_null("GameplayRoot/RuntimeSystems/AlarmZones") as Node2D
	if alarm_zones == null:
		_attempt_runtime_state["fix7_ambush_beam_status"] = "visual_only_no_alarm_zone_parent"
		_attempt_runtime_state["fix7b_ambush_beam_status"] = "visual_only_no_alarm_zone_parent"
		_attach_fix7_ambush_beam_visual(beam_center, null, visual_h * 0.5, geom, anchor_pos)
		return
	var beam_area := alarm_zones.get_node_or_null("AlarmZone_AMBUSH_security_beam") as Area2D
	if beam_area != null and beam_area.is_queued_for_deletion():
		beam_area = null
	if beam_area == null:
		beam_area = Area2D.new()
		beam_area.name = "AlarmZone_AMBUSH_security_beam"
		alarm_zones.add_child(beam_area)
	_arm_d5_attempt_alarm_area(beam_area, "AMBUSH_security_beam")
	_apply_fix7f_ambush_beam_geometry(beam_area, geom)
	beam_area.global_position = beam_center
	_attach_fix7_ambush_beam_visual(beam_center, beam_area, visual_h * 0.5, geom, anchor_pos)
	_attempt_runtime_state["fix7e_visual_trigger_mismatch_px"] = float(_attempt_runtime_state.get("fix7_ambush_beam_visual_trigger_mismatch_px", -1.0))
	_store_d6_02_authoring_summary(
		sec_root,
		"fix7f_fallback",
		"",
		false,
		beam_center,
		visual_h,
		D6_FIX7F_AMBUSH_BEAM_VISUAL_WIDTH,
		trig_sz,
		0.0,
		String(_attempt_runtime_state.get("fix7_ambush_beam_status", "unknown")),
		"fix7f_fallback",
	)
	_setup_d6_03_authoring_security_runtime()


## D6-01-FIX7A: locate generated runtime marker nodes not included in authoring index.
## Search order:
## 1) GeneratedRuntimeMarkerDebugInteractables (prefer)
## 2) GeneratedRuntimeMarkerLabels
func _find_runtime_debug_marker(marker_id: String) -> Node2D:
	var marker_id_trimmed := marker_id.strip_edges()
	if marker_id_trimmed == "":
		return null
	var roots: Array[String] = [
		"GameplayRoot/GeneratedRuntimeMarkerDebugInteractables",
		"GameplayRoot/GeneratedRuntimeMarkerLabels",
	]
	var prefixes: Array[String] = ["Debug_", "Label_"]
	for i in range(roots.size()):
		var parent := get_node_or_null(roots[i]) as Node
		if parent == null:
			continue
		var by_name := parent.get_node_or_null(prefixes[i] + marker_id_trimmed) as Node2D
		if by_name != null:
			return by_name
		for child in parent.get_children():
			if not (child is Node2D):
				continue
			var prop_id := _value_string((child as Node).get("marker_id"))
			if prop_id == marker_id_trimmed:
				return child as Node2D
			if (child as Node).has_meta("marker_id"):
				var meta_id := String((child as Node).get_meta("marker_id"))
				if meta_id == marker_id_trimmed:
					return child as Node2D
	return null


## Shared beam center for Line2D host + AlarmZone; half_height = FIX7F visual span / 2.
func _attach_fix7_ambush_beam_visual(
	beam_center: Vector2,
	beam_area: Area2D,
	beam_half_height: float,
	geom: Dictionary = {},
	seed_pos: Vector2 = Vector2.ZERO,
	visual_line_width: float = D6_FIX7F_AMBUSH_BEAM_VISUAL_WIDTH,
) -> void:
	var root := get_node_or_null("GameplayRoot/RuntimeSystems") as Node2D
	if root == null:
		return
	var old_host := root.get_node_or_null("SecurityBeam_Ambush_RightHallway")
	if old_host != null:
		old_host.queue_free()
	var host := Node2D.new()
	host.name = "SecurityBeam_Ambush_RightHallway"
	host.set_meta("D6_FIX7_TEMP_AMBUSH_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS", true)
	host.z_index = 2600
	root.add_child(host)
	host.global_position = beam_center
	var half_h := beam_half_height
	var line := Line2D.new()
	line.name = "AmbushBeamLine"
	line.width = visual_line_width
	line.default_color = Color(1.0, 0.0, 0.0, 1.0)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.z_index = 2601
	line.add_point(Vector2(0.0, -half_h))
	line.add_point(Vector2(0.0, half_h))
	host.add_child(line)
	var label := Label.new()
	label.name = "AmbushBeamLabel"
	label.text = "SECURITY BEAM"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(-80.0, -half_h - 58.0)
	label.z_index = 2602
	host.add_child(label)
	var beacon_t := Node2D.new()
	beacon_t.name = "AmbushBeamEndTop"
	beacon_t.position = Vector2(0.0, -half_h)
	host.add_child(beacon_t)
	var beacon_b := Node2D.new()
	beacon_b.name = "AmbushBeamEndBottom"
	beacon_b.position = Vector2(0.0, half_h)
	host.add_child(beacon_b)
	var visual_center := beam_center
	var trigger_center := beam_center if beam_area == null else beam_area.global_position
	var mismatch: float = visual_center.distance_to(trigger_center)
	_attempt_runtime_state["fix7_ambush_beam_visual_center"] = visual_center
	_attempt_runtime_state["fix7_ambush_beam_trigger_center"] = trigger_center
	_attempt_runtime_state["fix7_ambush_beam_visual_trigger_mismatch_px"] = mismatch
	var fix7b_stat := "armed" if beam_area != null else "visual_only"
	if beam_area == null and get_node_or_null("GameplayRoot/RuntimeSystems/AlarmZones") == null:
		fix7b_stat = "visual_only_no_alarm_zone_parent"
	_attempt_runtime_state["fix7_ambush_beam_status"] = fix7b_stat
	_attempt_runtime_state["fix7b_ambush_beam_status"] = fix7b_stat
	_attempt_runtime_state["fix7b_ambush_beam_visual_trigger_mismatch_px"] = mismatch
	_attempt_runtime_state["fix7b_ambush_beam_visual_path"] = str(host.get_path()) + "/" + line.name
	_attempt_runtime_state["fix7b_ambush_beam_trigger_path"] = str(beam_area.get_path()) if beam_area != null else "none"
	if not geom.is_empty():
		var seed_pt := seed_pos if seed_pos != Vector2.ZERO else beam_center
		_attach_fix7f_debug_markers(host, geom, seed_pt)


## D6-01-FIX6B: place beam immediately before the bag room (far-right hallway).
## Bag is at ~15392,336; beam should be the final obstacle before reaching it.
func _d6_fix6_right_hallway_beam_center() -> Vector2:
	var bag_marker := _find_authoring_marker("OBJECTIVE", "retrieve_delivery_bag")
	if bag_marker is Node2D:
		var bag_pos := (bag_marker as Node2D).global_position
		## Place beam only 80px before the bag (immediately before the room entrance).
		## This is the far-right hallway approach - the final challenge before the objective.
		return bag_pos + Vector2(-80, 0)
	return _map_to_global(Vector2i(28, 2))


func _d6_fix4_first_rect_size_from_area(area: Area2D) -> Vector2:
	for child in area.get_children():
		if child is CollisionShape2D:
			var sh := (child as CollisionShape2D).shape
			if sh is RectangleShape2D:
				return (sh as RectangleShape2D).size
	return Vector2.ZERO


## D6-01-FIX6A: compute beam distance and direction from player for F10 locator.
func _compute_beam_player_relationship() -> Dictionary:
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null:
		return {"distance": -1.0, "direction": "no_player", "center": Vector2.ZERO}
	if _attempt_runtime_state.get("fix7_ambush_beam_anchor_found", false) != true:
		return {"distance": -1.0, "direction": "missing_anchor", "center": Vector2.ZERO}
	var beam_center: Vector2
	if _attempt_runtime_state.has("fix7b_ambush_beam_center"):
		beam_center = _attempt_runtime_state["fix7b_ambush_beam_center"]
	else:
		beam_center = _attempt_runtime_state.get("fix7_ambush_beam_anchor_position", Vector2.ZERO)
	var to_beam := beam_center - player_node.global_position
	var distance: float = to_beam.length()
	var angle: float = to_beam.angle()
	var direction := "unknown"
	var abs_angle := absf(angle)
	if abs_angle < PI * 0.25:
		direction = "right"
	elif abs_angle > PI * 0.75:
		direction = "left"
	elif angle > 0:
		direction = "down"
	else:
		direction = "up"
	return {"distance": distance, "direction": direction, "center": beam_center}


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
	if _try_bypass_louis_route_beam(alarm_id, area, body):
		return
	if _is_alarm_zone_one_shot(alarm_id):
		if _is_runtime_flag_true("alarm_triggered:" + alarm_id):
			return
		_attempt_runtime_state["alarm_triggered:" + alarm_id] = true
		_attempt_runtime_state["ambush_triggered"] = int(_attempt_runtime_state.get("ambush_triggered", 0)) + 1
		if area != null:
			area.set_deferred("monitoring", false)
	if _is_beam_alarm_id(alarm_id):
		var trip_event := _get_authoring_beam_trip_event_id(alarm_id)
		var beam_dispatch := _emit_security_authoring_event(trip_event, {
			"source_type": "security_beam_author",
			"source_id": alarm_id,
			"source_path": str(area.get_path()) if area != null else "",
			"player_position": (body as Node2D).global_position if body is Node2D else Vector2.ZERO,
			"timestamp": Time.get_ticks_msec(),
			"reason": "beam_crossed",
		})
		_attempt_runtime_state["d6_04_last_beam_event_handled"] = bool(beam_dispatch.get("handled", false))
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


func _refresh_d6_04_live_debug_state() -> void:
	_refresh_d6_05a_test_door_state()
	var cameras_parent := get_node_or_null("EntityRoot/Cameras")
	if cameras_parent == null:
		return
	for child in cameras_parent.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if not String(child.name).begins_with("AuthoredCamera_"):
			continue
		if child.has_method("get_runtime_debug_state"):
			var cst: Dictionary = child.call("get_runtime_debug_state") as Dictionary
			_attempt_runtime_state["d6_04_authored_camera_runtime_path"] = String(child.get_path())
			_attempt_runtime_state["d6_04_authored_camera_runtime_class"] = String(cst.get("class_name", child.get_class()))
			_attempt_runtime_state["d6_04_authored_camera_enabled"] = bool(cst.get("enabled", false))
			_attempt_runtime_state["d6_04_authored_camera_monitoring"] = bool(cst.get("monitoring", false))
			_attempt_runtime_state["d6_04_authored_camera_has_shape"] = bool(cst.get("has_shape", false))
			_attempt_runtime_state["d6_04_authored_camera_player_in_cone"] = bool(cst.get("player_in_cone", false))
			_attempt_runtime_state["d6_04_authored_camera_detection_value"] = float(cst.get("detection_value", 0.0))
			_attempt_runtime_state["d6_04_last_camera_id"] = String(cst.get("camera_id", ""))
	var enemies := get_node_or_null("EntityRoot/Enemies")
	if enemies == null:
		return
	for guard in enemies.get_children():
		if guard == null or not guard.has_method("get_authoring_debug_state"):
			continue
		if not guard.has_meta("author_spawn_id"):
			continue
		var gst: Dictionary = guard.call("get_authoring_debug_state") as Dictionary
		_attempt_runtime_state["d6_04_authored_guard_force_chase"] = bool(gst.get("force_chase", false))
		_attempt_runtime_state["d6_04_authored_guard_fallback_entered"] = bool(gst.get("fallback_entered", false))
		_attempt_runtime_state["d6_04_authored_guard_debug_cone_range"] = float(gst.get("debug_cone_range", 0.0))
		_attempt_runtime_state["d6_04_authored_guard_aggro_range"] = float(gst.get("aggro_range", 0.0))


func _runtime_debug_summary() -> Dictionary:
	_refresh_d6_04_live_debug_state()
	var enemies := get_node_or_null("EntityRoot/Enemies")
	var cameras := get_node_or_null("EntityRoot/Cameras")
	var runtime_guard_count := enemies.get_child_count() if enemies != null else 0
	var camera_count := cameras.get_child_count() if cameras != null else 0
	var sec_spawned := _count_functional_security_response_guards()
	var sec_raw := _count_raw_security_response_guards()
	var sec_invalid := _count_invalid_security_response_guards()
	var cam_sweep := _count_security_cameras_sweeping()
	## D6-01-FIX6A: compute beam distance/direction from player for F10 locator.
	var beam_info := _compute_beam_player_relationship()
	## D6-01-FIX6B: get lifecycle stats for F10.
	var lifecycle_stats := _get_security_guard_lifecycle_stats()
	## D6-01-FIX6B: get heat and last spawn role for search net debug.
	var heat := GameState.get_mission_heat(_debug_mission_id())
	var garage_beam_triggered := _is_runtime_flag_true("alarm_triggered:garage_entry_beam") or _is_runtime_flag_true("alarm_triggered:AMBUSH_security_beam")
	var garage_beam_bypassed := _is_runtime_flag_true("alarm_bypassed:garage_entry_beam") or _is_runtime_flag_true("alarm_bypassed:AMBUSH_security_beam")
	var last_role := ""
	var last_ordinal := -1
	var last_heat_at_spawn := -1
	if not _security_spawn_probe.is_empty():
		last_role = str(_security_spawn_probe.get("last_role", ""))
		last_ordinal = int(_security_spawn_probe.get("last_ordinal", -1))
		last_heat_at_spawn = int(_security_spawn_probe.get("last_heat", -1))
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
		"garage_beam_armed": not garage_beam_triggered and not garage_beam_bypassed,
		"garage_beam_triggered": garage_beam_triggered,
		"garage_beam_bypassed": garage_beam_bypassed,
		"louis_route_beam_bypass_active": _is_louis_delivery_route_active(),
		"beam_alarm_id": "garage_entry_beam",
		"beam_runtime_node_path": "GameplayRoot/RuntimeSystems/AlarmZones/AlarmZone_garage_entry_beam",
		"beam_f10_plain": "Beam: FIX7F doorway rectangle (grid search + overlap rejection, mask=7). Mid-run alarm only.",
		"beam_f10_fix7d_note": "FIX7F: searches candidate X/Y near seed; picks centered walkable doorway span.",
		"beam_f10_fix7d_fallback_warning": "FIX7F fallback — check FIX7F reason on F10." if bool(_attempt_runtime_state.get("fix7f_fallback_used", false)) else "",
		"beam_f10_how_to_test": "Test: walk through vertical red beam at AMBUSH_security_beam choke. beam_trip +1 once.",
		"beam_distance_from_player": beam_info.get("distance", -1.0),
		"beam_direction_from_player": beam_info.get("direction", "unknown"),
		"beam_center_position": beam_info.get("center", Vector2.ZERO),
		"security_spawn_cap": _get_security_spawn_cap(),
		"security_response_spawn_count": sec_spawned,
		"security_response_spawn_count_raw": sec_raw,
		"invalid_offmap_security_guard_count": sec_invalid,
		"security_spawn_pending_count": _pending_security_guard_source_ids.size(),
		"security_reserved_count": _get_reserved_security_guard_count(),
		"security_attack_spawn_counter": int(_attempt_runtime_state.get("attack_guard_spawned", 0)),
		"security_active_guards_preview": _security_guard_positions_preview(3),
		"security_active_guards_raw_preview": _security_guard_raw_positions_preview(5),
		"security_cameras_total": int(cam_sweep.get("total", 0)),
		"security_cameras_moving": int(cam_sweep.get("moving", 0)),
		"security_cameras_static": int(cam_sweep.get("static", 0)),
		"reinforcement_cooldown_sec": _get_security_reinforcement_cooldown_sec(),
		"last_reinforcement_source": _last_security_reinforcement_source,
		"last_reinforcement_result": _last_security_reinforcement_result,
		"d6_fix5_spawn_probe": _security_spawn_probe.duplicate(true),
		"d6_fix6_spawn_probe": _security_spawn_probe.duplicate(true),
		"heat_restart_audit_note": "Heat +1 only when fail_mission runs (e.g. fail_level / player death). Mid-run alarms do not add persistent heat.",
		"good_guard_scene": MissionSecurityGuardResolver.good_guard_scene_path(),
		"bad_guard_script_note": MissionSecurityGuardResolver.bad_guard_script_path(),
		"garage_beam_f10_hint": "FIX7 uses AMBUSH_security_beam only (no bag-offset placement).",
		"beam_status": String(_attempt_runtime_state.get("fix7_ambush_beam_status", "unknown")),
		"ambush_beam_anchor_found": _attempt_runtime_state.get("fix7_ambush_beam_anchor_found", false),
		"ambush_beam_anchor_resolve_source": String(_attempt_runtime_state.get("fix7_ambush_beam_anchor_resolve_source", "missing")),
		"ambush_beam_anchor_path": String(_attempt_runtime_state.get("fix7_ambush_beam_anchor_path", "missing")),
		"ambush_beam_anchor_position": _attempt_runtime_state.get("fix7_ambush_beam_anchor_position", Vector2.ZERO),
		"ambush_beam_visual_center": _attempt_runtime_state.get("fix7_ambush_beam_visual_center", Vector2.ZERO),
		"ambush_beam_trigger_center": _attempt_runtime_state.get("fix7_ambush_beam_trigger_center", Vector2.ZERO),
		"ambush_beam_visual_trigger_mismatch_px": float(_attempt_runtime_state.get("fix7_ambush_beam_visual_trigger_mismatch_px", -1.0)),
		"fix7b_ambush_beam_orientation": String(_attempt_runtime_state.get("fix7b_ambush_beam_orientation", "unknown")),
		"fix7b_ambush_beam_center": _attempt_runtime_state.get("fix7b_ambush_beam_center", Vector2.ZERO),
		"fix7b_ambush_beam_center_offset": _attempt_runtime_state.get("fix7b_ambush_beam_center_offset", Vector2.ZERO),
		"fix7b_ambush_beam_height": float(_attempt_runtime_state.get("fix7b_ambush_beam_height", 0.0)),
		"fix7b_ambush_beam_visual_width": float(_attempt_runtime_state.get("fix7b_ambush_beam_visual_width", 0.0)),
		"fix7b_ambush_beam_trigger_size": _attempt_runtime_state.get("fix7b_ambush_beam_trigger_size", Vector2.ZERO),
		"fix7b_ambush_beam_visual_trigger_mismatch_px": float(_attempt_runtime_state.get("fix7b_ambush_beam_visual_trigger_mismatch_px", -1.0)),
		"fix7b_ambush_beam_status": String(_attempt_runtime_state.get("fix7b_ambush_beam_status", "unknown")),
		"fix7d_ambush_beam_mode": String(_attempt_runtime_state.get("fix7d_ambush_beam_mode", "unknown")),
		"fix7d_collision_boundary_success": _attempt_runtime_state.get("fix7d_collision_boundary_success", false),
		"fix7d_choke_x": float(_attempt_runtime_state.get("fix7d_choke_x", 0.0)),
		"fix7d_choke_source": String(_attempt_runtime_state.get("fix7d_choke_source", "")),
		"fix7d_probe_y": float(_attempt_runtime_state.get("fix7d_probe_y", 0.0)),
		"fix7d_top_boundary_y": float(_attempt_runtime_state.get("fix7d_top_boundary_y", -1.0)),
		"fix7d_bottom_boundary_y": float(_attempt_runtime_state.get("fix7d_bottom_boundary_y", -1.0)),
		"fix7d_failure_reason": String(_attempt_runtime_state.get("fix7d_failure_reason", "")),
		"fix7d_fallback_used": _attempt_runtime_state.get("fix7d_fallback_used", false),
		"fix7e_mode": String(_attempt_runtime_state.get("fix7e_mode", "")),
		"fix7e_collision_ok": _attempt_runtime_state.get("fix7e_collision_ok", false),
		"fix7e_fallback_used": _attempt_runtime_state.get("fix7e_fallback_used", false),
		"fix7e_choke_x": float(_attempt_runtime_state.get("fix7e_choke_x", 0.0)),
		"fix7e_probe_y": float(_attempt_runtime_state.get("fix7e_probe_y", 0.0)),
		"fix7e_top_hit_y": float(_attempt_runtime_state.get("fix7e_top_hit_y", -1.0)),
		"fix7e_bottom_hit_y": float(_attempt_runtime_state.get("fix7e_bottom_hit_y", -1.0)),
		"fix7e_visual_top_y": float(_attempt_runtime_state.get("fix7e_visual_top_y", 0.0)),
		"fix7e_visual_bottom_y": float(_attempt_runtime_state.get("fix7e_visual_bottom_y", 0.0)),
		"fix7e_visual_height": float(_attempt_runtime_state.get("fix7e_visual_height", 0.0)),
		"fix7e_trigger_top_y": float(_attempt_runtime_state.get("fix7e_trigger_top_y", 0.0)),
		"fix7e_trigger_bottom_y": float(_attempt_runtime_state.get("fix7e_trigger_bottom_y", 0.0)),
		"fix7e_trigger_height": float(_attempt_runtime_state.get("fix7e_trigger_height", 0.0)),
		"fix7e_reason": String(_attempt_runtime_state.get("fix7e_reason", "")),
		"fix7e_visual_trigger_mismatch_px": float(_attempt_runtime_state.get("fix7e_visual_trigger_mismatch_px", -1.0)),
		"beam_f10_fix7e_instruction": "Beam should span only A-B inner hallway gap, not through walls.",
		"fix7f_mode": String(_attempt_runtime_state.get("fix7f_mode", "")),
		"fix7f_success": _attempt_runtime_state.get("fix7f_success", false),
		"fix7f_fallback_used": _attempt_runtime_state.get("fix7f_fallback_used", false),
		"fix7f_seed_x": float(_attempt_runtime_state.get("fix7f_seed_x", 0.0)),
		"fix7f_chosen_x": float(_attempt_runtime_state.get("fix7f_chosen_x", 0.0)),
		"fix7f_x_shift_from_seed": float(_attempt_runtime_state.get("fix7f_x_shift_from_seed", 0.0)),
		"fix7f_probe_y": float(_attempt_runtime_state.get("fix7f_probe_y", 0.0)),
		"fix7f_chosen_probe_y": float(_attempt_runtime_state.get("fix7f_chosen_probe_y", 0.0)),
		"fix7f_candidate_count": int(_attempt_runtime_state.get("fix7f_candidate_count", 0)),
		"fix7f_rejected_inside_wall": int(_attempt_runtime_state.get("fix7f_rejected_inside_wall", 0)),
		"fix7f_rejected_missing_hits": int(_attempt_runtime_state.get("fix7f_rejected_missing_hits", 0)),
		"fix7f_rejected_height": int(_attempt_runtime_state.get("fix7f_rejected_height", 0)),
		"fix7f_rejected_visual_overlap": int(_attempt_runtime_state.get("fix7f_rejected_visual_overlap", 0)),
		"fix7f_rejected_trigger_overlap": int(_attempt_runtime_state.get("fix7f_rejected_trigger_overlap", 0)),
		"fix7f_top_hit_y": float(_attempt_runtime_state.get("fix7f_top_hit_y", -1.0)),
		"fix7f_bottom_hit_y": float(_attempt_runtime_state.get("fix7f_bottom_hit_y", -1.0)),
		"fix7f_visual_top_y": float(_attempt_runtime_state.get("fix7f_visual_top_y", 0.0)),
		"fix7f_visual_bottom_y": float(_attempt_runtime_state.get("fix7f_visual_bottom_y", 0.0)),
		"fix7f_visual_height": float(_attempt_runtime_state.get("fix7f_visual_height", 0.0)),
		"fix7f_trigger_top_y": float(_attempt_runtime_state.get("fix7f_trigger_top_y", 0.0)),
		"fix7f_trigger_bottom_y": float(_attempt_runtime_state.get("fix7f_trigger_bottom_y", 0.0)),
		"fix7f_trigger_height": float(_attempt_runtime_state.get("fix7f_trigger_height", 0.0)),
		"fix7f_visual_overlap_ok": _attempt_runtime_state.get("fix7f_visual_overlap_ok", false),
		"fix7f_trigger_overlap_ok": _attempt_runtime_state.get("fix7f_trigger_overlap_ok", false),
		"fix7f_reason": String(_attempt_runtime_state.get("fix7f_reason", "")),
		"beam_f10_fix7f_instruction": "Beam centered in doorway; visual = inner walls; trigger slightly larger.",
		"d6_02_security_authoring_root_found": _attempt_runtime_state.get("d6_02_security_authoring_root_found", false),
		"d6_02_security_authoring_beam_count": int(_attempt_runtime_state.get("d6_02_security_authoring_beam_count", 0)),
		"d6_02_ambush_beam_source": String(_attempt_runtime_state.get("d6_02_ambush_beam_source", "unknown")),
		"d6_02_ambush_beam_author_path": String(_attempt_runtime_state.get("d6_02_ambush_beam_author_path", "")),
		"d6_02_ambush_beam_author_enabled": _attempt_runtime_state.get("d6_02_ambush_beam_author_enabled", false),
		"d6_02_ambush_beam_center": _attempt_runtime_state.get("d6_02_ambush_beam_center", Vector2.ZERO),
		"d6_02_ambush_beam_visual_height": float(_attempt_runtime_state.get("d6_02_ambush_beam_visual_height", 0.0)),
		"d6_02_ambush_beam_visual_width": float(_attempt_runtime_state.get("d6_02_ambush_beam_visual_width", 0.0)),
		"d6_02_ambush_beam_trigger_width": float(_attempt_runtime_state.get("d6_02_ambush_beam_trigger_width", 0.0)),
		"d6_02_ambush_beam_trigger_height": float(_attempt_runtime_state.get("d6_02_ambush_beam_trigger_height", 0.0)),
		"d6_02_ambush_beam_trigger_extra_height": float(_attempt_runtime_state.get("d6_02_ambush_beam_trigger_extra_height", 0.0)),
		"d6_02_ambush_beam_trigger_size": _attempt_runtime_state.get("d6_02_ambush_beam_trigger_size", Vector2.ZERO),
		"d6_02_ambush_beam_trip_count": int(_attempt_runtime_state.get("d6_02_ambush_beam_trip_count", 0)),
		"d6_02_ambush_beam_runtime_status": String(_attempt_runtime_state.get("d6_02_ambush_beam_runtime_status", "")),
		"d6_02_ambush_beam_validation_status": String(_attempt_runtime_state.get("d6_02_ambush_beam_validation_status", "")),
		"d6_02_authored_camera_count": int(_attempt_runtime_state.get("d6_02_authored_camera_count", 0)),
		"d6_02_authored_guard_spawn_count": int(_attempt_runtime_state.get("d6_02_authored_guard_spawn_count", 0)),
		"d6_02_authored_patrol_route_count": int(_attempt_runtime_state.get("d6_02_authored_patrol_route_count", 0)),
		"d6_03_security_router_active": _attempt_runtime_state.get("d6_03_security_router_active", false),
		"d6_03_registered_event_count": int(_attempt_runtime_state.get("d6_03_registered_event_count", 0)),
		"d6_03_last_dispatched_event": String(_attempt_runtime_state.get("d6_03_last_dispatched_event", "")),
		"d6_03_last_guard_spawn_author_id": String(_attempt_runtime_state.get("d6_03_last_guard_spawn_author_id", "")),
		"d6_03_last_guard_spawn_result": String(_attempt_runtime_state.get("d6_03_last_guard_spawn_result", "")),
		"d6_03_last_guard_spawn_reason": String(_attempt_runtime_state.get("d6_03_last_guard_spawn_reason", "")),
		"d6_03_last_spawned_guard_count": int(_attempt_runtime_state.get("d6_03_last_spawned_guard_count", 0)),
		"d6_03_beam_event_route_used": _attempt_runtime_state.get("d6_03_beam_event_route_used", false),
		"d6_03_beam_direct_fallback_suppressed": _attempt_runtime_state.get("d6_03_beam_direct_fallback_suppressed", false),
		"d6_03_duplicate_spawn_avoided": _attempt_runtime_state.get("d6_03_duplicate_spawn_avoided", false),
		"d6_03_authored_area_trigger_count": int(_attempt_runtime_state.get("d6_03_authored_area_trigger_count", 0)),
		"d6_03_router_listener_counts": (_security_event_router.call("get_debug_summary") as Dictionary).get("listener_counts", {}) if _security_event_router != null else {},
		"d6_03_router_recent_events": (_security_event_router.call("get_debug_summary") as Dictionary).get("recent_events", []) if _security_event_router != null else [],
		"d6_04_last_event_listeners_registered": int(_attempt_runtime_state.get("d6_04_last_event_listeners_registered", 0)),
		"d6_04_last_event_listeners_called": int(_attempt_runtime_state.get("d6_04_last_event_listeners_called", 0)),
		"d6_04_last_event_listeners_handled": int(_attempt_runtime_state.get("d6_04_last_event_listeners_handled", 0)),
		"d6_04_last_event_listeners_rejected": int(_attempt_runtime_state.get("d6_04_last_event_listeners_rejected", 0)),
		"d6_04_last_event_handled": _attempt_runtime_state.get("d6_04_last_event_handled", false),
		"d6_04_last_event_rejection_reasons": _attempt_runtime_state.get("d6_04_last_event_rejection_reasons", []),
		"d6_04_last_successful_listener_paths": _attempt_runtime_state.get("d6_04_last_successful_listener_paths", []),
		"d6_04_runtime_authored_camera_count": int(_attempt_runtime_state.get("d6_04_runtime_authored_camera_count", 0)),
		"d6_04_last_camera_id": String(_attempt_runtime_state.get("d6_04_last_camera_id", "")),
		"d6_04_last_camera_detect_event": String(_attempt_runtime_state.get("d6_04_last_camera_detect_event", "")),
		"d6_04_last_camera_alarm_event": String(_attempt_runtime_state.get("d6_04_last_camera_alarm_event", "")),
		"d6_04_last_camera_alarm_handled": _attempt_runtime_state.get("d6_04_last_camera_alarm_handled", false),
		"d6_04_last_camera_source_path": String(_attempt_runtime_state.get("d6_04_last_camera_source_path", "")),
		"d6_04_last_beam_event_handled": _attempt_runtime_state.get("d6_04_last_beam_event_handled", false),
		"d6_04_last_guard_initial_behavior": String(_attempt_runtime_state.get("d6_04_last_guard_initial_behavior", "")),
		"d6_04_last_guard_fallback_behavior": String(_attempt_runtime_state.get("d6_04_last_guard_fallback_behavior", "")),
		"d6_04_last_guard_patrol_route_assigned": _attempt_runtime_state.get("d6_04_last_guard_patrol_route_assigned", false),
		"d6_04_authored_camera_runtime_path": String(_attempt_runtime_state.get("d6_04_authored_camera_runtime_path", "")),
		"d6_04_authored_camera_runtime_class": String(_attempt_runtime_state.get("d6_04_authored_camera_runtime_class", "")),
		"d6_04_authored_camera_parity_target": String(_attempt_runtime_state.get("d6_04_authored_camera_parity_target", "CAM_market_01")),
		"d6_04_authored_camera_parent_path": String(_attempt_runtime_state.get("d6_04_authored_camera_parent_path", "")),
		"d6_04_authored_camera_enabled": _attempt_runtime_state.get("d6_04_authored_camera_enabled", false),
		"d6_04_authored_camera_monitoring": _attempt_runtime_state.get("d6_04_authored_camera_monitoring", false),
		"d6_04_authored_camera_has_shape": _attempt_runtime_state.get("d6_04_authored_camera_has_shape", false),
		"d6_04_authored_camera_player_in_cone": _attempt_runtime_state.get("d6_04_authored_camera_player_in_cone", false),
		"d6_04_authored_camera_detection_value": float(_attempt_runtime_state.get("d6_04_authored_camera_detection_value", 0.0)),
		"d6_04_authored_guard_force_chase": _attempt_runtime_state.get("d6_04_authored_guard_force_chase", false),
		"d6_04_authored_guard_fallback_entered": _attempt_runtime_state.get("d6_04_authored_guard_fallback_entered", false),
		"d6_04_authored_guard_debug_cone_range": float(_attempt_runtime_state.get("d6_04_authored_guard_debug_cone_range", 0.0)),
		"d6_04_authored_guard_aggro_range": float(_attempt_runtime_state.get("d6_04_authored_guard_aggro_range", 0.0)),
		"d6_05_effect_author_count": int(_attempt_runtime_state.get("d6_05_effect_author_count", 0)),
		"d6_05_door_effect_count": int(_attempt_runtime_state.get("d6_05_door_effect_count", 0)),
		"d6_05_lockdown_effect_count": int(_attempt_runtime_state.get("d6_05_lockdown_effect_count", 0)),
		"d6_05_objective_effect_count": int(_attempt_runtime_state.get("d6_05_objective_effect_count", 0)),
		"d6_05_node_toggle_effect_count": int(_attempt_runtime_state.get("d6_05_node_toggle_effect_count", 0)),
		"d6_05_effect_set_count": int(_attempt_runtime_state.get("d6_05_effect_set_count", 0)),
		"d6_05_last_effect_id": String(_attempt_runtime_state.get("d6_05_last_effect_id", "")),
		"d6_05_last_effect_type": String(_attempt_runtime_state.get("d6_05_last_effect_type", "")),
		"d6_05_last_effect_event": String(_attempt_runtime_state.get("d6_05_last_effect_event", "")),
		"d6_05_last_effect_target": String(_attempt_runtime_state.get("d6_05_last_effect_target", "")),
		"d6_05_last_effect_result": String(_attempt_runtime_state.get("d6_05_last_effect_result", "")),
		"d6_05_last_effect_reason": String(_attempt_runtime_state.get("d6_05_last_effect_reason", "")),
		"d6_05_last_effect_set_id": String(_attempt_runtime_state.get("d6_05_last_effect_set_id", "")),
		"d6_05_last_effect_set_message": String(_attempt_runtime_state.get("d6_05_last_effect_set_message", "")),
		"d6_05_last_effect_set_summary": String(_attempt_runtime_state.get("d6_05_last_effect_set_summary", "")),
		"d6_05_last_effect_set_applied_count": int(_attempt_runtime_state.get("d6_05_last_effect_set_applied_count", 0)),
		"d6_05_last_effect_set_failed_count": int(_attempt_runtime_state.get("d6_05_last_effect_set_failed_count", 0)),
		"d6_05_last_effect_chain": _attempt_runtime_state.get("d6_05_last_effect_chain", []),
		"d6_05_lockdown_active": _attempt_runtime_state.get("d6_05_lockdown_active", false),
		"d6_05_lockdown_alert_state": String(_attempt_runtime_state.get("d6_05_lockdown_alert_state", "")),
		"d6_05_last_door_effect_id": String(_attempt_runtime_state.get("d6_05_last_door_effect_id", "")),
		"d6_05_last_door_action": String(_attempt_runtime_state.get("d6_05_last_door_action", "")),
		"d6_05_last_door_lock_state": String(_attempt_runtime_state.get("d6_05_last_door_lock_state", "")),
		"d6_05_last_door_target": String(_attempt_runtime_state.get("d6_05_last_door_target", "")),
		"d6_05_last_door_event": String(_attempt_runtime_state.get("d6_05_last_door_event", "")),
		"d6_05a_test_door_path": String(_attempt_runtime_state.get("d6_05a_test_door_path", "")),
		"d6_05a_test_door_lock_state": String(_attempt_runtime_state.get("d6_05a_test_door_lock_state", "unknown")),
		"d6_05a_test_door_locked": _attempt_runtime_state.get("d6_05a_test_door_locked", false),
		"d6_05a_test_door_collision_layer": int(
			_attempt_runtime_state.get("d6_05a_test_door_collision_layer", 0)
		),
		"d6_05a_test_door_collision_enabled": _attempt_runtime_state.get(
			"d6_05a_test_door_collision_enabled", false
		),
		"d6_05a_test_door_orientation_degrees": float(
			_attempt_runtime_state.get("d6_05a_test_door_orientation_degrees", 0.0)
		),
		"d6_05c_last_zone_event": String(_attempt_runtime_state.get("d6_05c_last_zone_event", "")),
		"d6_05c_last_zone_id": String(_attempt_runtime_state.get("d6_05c_last_zone_id", "")),
		"d6_06_authoring_root_found": _attempt_runtime_state.get("d6_06_authoring_root_found", false),
		"d6_06_collectible_author_count": int(_attempt_runtime_state.get("d6_06_collectible_author_count", 0)),
		"d6_06_runtime_pickup_count": int(_attempt_runtime_state.get("d6_06_runtime_pickup_count", 0)),
		"d6_06_poop_author_count": int(_attempt_runtime_state.get("d6_06_poop_author_count", 0)),
		"d6_06_money_author_count": int(_attempt_runtime_state.get("d6_06_money_author_count", 0)),
		"d6_06_polaroid_author_count": int(_attempt_runtime_state.get("d6_06_polaroid_author_count", 0)),
		"d6_06_tiny_icon_author_count": int(_attempt_runtime_state.get("d6_06_tiny_icon_author_count", 0)),
		"d6_06_glow_guy_author_count": int(_attempt_runtime_state.get("d6_06_glow_guy_author_count", 0)),
		"d6_06_clue_author_count": int(_attempt_runtime_state.get("d6_06_clue_author_count", 0)),
		"d6_06_case_cash_author_count": int(_attempt_runtime_state.get("d6_06_case_cash_author_count", 0)),
		"d6_06_last_authored_pickup_id": String(_attempt_runtime_state.get("d6_06_last_authored_pickup_id", "")),
		"d6_06_last_authored_pickup_type": String(_attempt_runtime_state.get("d6_06_last_authored_pickup_type", "")),
		"d6_06_last_authored_pickup_result": String(_attempt_runtime_state.get("d6_06_last_authored_pickup_result", "")),
		"d6_06_last_pickup_source": String(_attempt_runtime_state.get("d6_06_last_pickup_source", "")),
		"d6_06_last_pickup_body": String(_attempt_runtime_state.get("d6_06_last_pickup_body", "")),
		"d6_06_last_pickup_body_path": String(_attempt_runtime_state.get("d6_06_last_pickup_body_path", "")),
		"d6_06_last_pickup_has_shape": _attempt_runtime_state.get("d6_06_last_pickup_has_shape", false),
		"d6_06_last_pickup_radius": float(_attempt_runtime_state.get("d6_06_last_pickup_radius", 0.0)),
		"d6_06_last_pickup_monitoring": _attempt_runtime_state.get("d6_06_last_pickup_monitoring", false),
		"d6_06_physical_overlap_verified": _attempt_runtime_state.get("d6_06_physical_overlap_verified", false),
		"d6_06b_all_pickups_have_shape": _attempt_runtime_state.get("d6_06b_all_pickups_have_shape", false),
		"d6_06b_all_pickups_monitoring": _attempt_runtime_state.get("d6_06b_all_pickups_monitoring", false),
		"d6_06_proof_flags": int(_attempt_runtime_state.get("d6_06_proof_flags", 0)),
		"d6_06_poop_count": int(GameState.poop_bag_inventory.get("count", 0)),
		"d6_06_money_proof_cash": int(_attempt_runtime_state.get("d6_06_authored_money_cash", 0)),
		"d6_06_runtime_path_kind": String(_attempt_runtime_state.get("d6_06_runtime_path_kind", "")),
		"d6_06_runtime_parent_path": String(_attempt_runtime_state.get("d6_06_runtime_parent_path", "")),
		"d6_06_pending_collectible_count": int(_attempt_runtime_state.get("d6_06_pending_collectible_count", 0)),
		"d6_06_committed_collectible_count": int(_attempt_runtime_state.get("d6_06_committed_collectible_count", 0)),
		"d6_06_hideout_sync_status": String(_attempt_runtime_state.get("d6_06_hideout_sync_status", "")),
		"d6_06_pending_poop": int(_attempt_runtime_state.get("d6_06_pending_poop", 0)),
		"d6_06_pending_money": int(_attempt_runtime_state.get("d6_06_pending_money", 0)),
		"d6_06_pending_polaroid": int(_attempt_runtime_state.get("d6_06_pending_polaroid", 0)),
		"d6_06_pending_tiny_icon": int(_attempt_runtime_state.get("d6_06_pending_tiny_icon", 0)),
		"d6_06_pending_glow_guy": int(_attempt_runtime_state.get("d6_06_pending_glow_guy", 0)),
		"d6_06_pending_clue": int(_attempt_runtime_state.get("d6_06_pending_clue", 0)),
		"d6_06_pending_case_cash_amount": int(_attempt_runtime_state.get("d6_06_pending_case_cash_amount", 0)),
		"d6_06_pending_case_cash_instances": int(_attempt_runtime_state.get("d6_06_pending_case_cash_instances", 0)),
		"d6_06_clue_corkboard_sync": String(_attempt_runtime_state.get("d6_06_clue_corkboard_sync", "")),
		"d6_06_glow_guy_shelf_sync": String(_attempt_runtime_state.get("d6_06_glow_guy_shelf_sync", "")),
		"d6_06_case_cash_bank": int(GameState.dialogue_flags.get("d6_06_case_cash_bank", 0)),
		"d6_06_duplicate_author_id_count": int(_attempt_runtime_state.get("d6_06_duplicate_author_id_count", 0)),
		"d6_06_duplicate_author_ids": _attempt_runtime_state.get("d6_06_duplicate_author_ids", []),
		"d6_06_pending_cleared_reason": String(_attempt_runtime_state.get("d6_06_pending_cleared_reason", "")),
		"search_net_last_role": last_role,
		"search_net_last_ordinal": last_ordinal,
		"search_net_last_heat_at_spawn": last_heat_at_spawn,
		"search_net_triangle_radius_by_heat": {0: 140, 1: 140, 2: 200, 3: 200, 4: 260, 5: 320}.get(heat, 140),
		"search_net_roles_by_heat": "H0-1: territorial | H2-3: pursuer/flanker | H4: pursuer/flanker/choke/sentry | H5: +double sentry",
		"search_net_local_route_real_handoff": true,
		"lifecycle_active": lifecycle_stats.get("active", 0),
		"lifecycle_searching": lifecycle_stats.get("searching", 0),
		"lifecycle_dormant": lifecycle_stats.get("dormant", 0),
		"lifecycle_removed_total": lifecycle_stats.get("removed_total", 0),
		"lifecycle_near_radius": lifecycle_stats.get("near_radius", 1000),
		"lifecycle_cleanup_radius": lifecycle_stats.get("cleanup_radius", 1600),
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
	_pending_security_guard_source_ids.clear()
	_security_guard_spawn_flush_scheduled = false
	_security_spawn_probe.clear()
	_clear_pending_authored_collectibles("attempt_reset")
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller != null and controller.has_method("reset_attempt_state"):
		controller.call("reset_attempt_state")


func _is_runtime_flag_true(key: String) -> bool:
	return _attempt_runtime_state.get(key, false) == true


func _is_alarm_zone_one_shot(alarm_id: String) -> bool:
	return alarm_id == "garage_entry_beam" or alarm_id == "AMBUSH_security_beam"


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
	if source_id.begins_with("alarm_AMBUSH_security_beam"):
		if _should_suppress_direct_beam_guard_spawn("AMBUSH_security_beam"):
			return false
		return _is_runtime_flag_true("alarm_guard_spawned:alarm_AMBUSH_security_beam") != true
	var cam_alarm_ev := _get_authored_camera_alarm_event_id(source_id)
	if cam_alarm_ev != &"" and _should_suppress_direct_spawn_for_event(cam_alarm_ev):
		_attempt_runtime_state["d6_03_duplicate_spawn_avoided"] = true
		return false
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
	call_deferred("_spawn_extra_guard_test_deferred")


func _spawn_extra_guard_test_deferred() -> void:
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
		profile["camera_rate_mult"] = 1.15
		profile["camera_sweep_mult"] = 1.18
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
		parent.remove_child(child)
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
