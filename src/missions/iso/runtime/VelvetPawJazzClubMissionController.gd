class_name VelvetPawJazzClubMissionController
extends Node

const CollisionDebugOverlayScript := preload("res://src/missions/iso/runtime/VelvetPawCollisionDebugOverlay.gd")

const MISSION_ID := "velvet_paw_jazz_club"
const FLOOR_MUSIC_KEY := "velvet_paw_floor"
const ALERT_CONTROLLER_PATH := NodePath("../MissionAlertController")
const RETURN_TELEPORT_PATH := NodePath("../../MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_02")
const PLAYER_PATH := NodePath("../../EntityRoot/Player")
const VIP_POLAROID_PATH := NodePath("../../MissionMechanics/VipChampagnePolaroid")
const VIP_VOICEMAIL_PATH := NodePath("../../MissionMechanics/SearchZone_velvet_paw_jazz_club_search_zone_01")
const VIP_GATE_SHAPE_PATH := NodePath("../../RouteBlockers/VipProtocolGateBlocker/GateShape")
const STAGE_SERVICE_DOOR_SHAPE_PATH := NodePath("../../RouteBlockers/StageServiceDoorBlocker/DoorShape")
const VIP_PROTOCOL_PATH := NodePath("../../MissionMechanics/ProtocolZone_velvet_paw_jazz_club_protocol_zone_01")
const CLUB_ENTRY_PATHS: Array[NodePath] = [
	NodePath("../../MissionMechanics/TriggerZone_velvet_paw_jazz_club_trigger_zone_01"),
	NodePath("../../MissionMechanics/TriggerZone_velvet_paw_front_entry"),
]
const VIP_WAIT_MARKER_ID := "velvet_paw_jazz_club.bentley_wait_marker.01"
const VIP_WAIT_MAX_DISTANCE := 72.0
const VIP_REINFORCEMENT_PATH := NodePath("../../SecurityAuthoringRoot/GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_08")
const VIP_CAMERA_ID := "velvet_paw_jazz_club.security_camera_author.01"
const VIP_TRESPASS_ACTION_ID := "velvet_paw_vip_bentley_trespass"
const TABLE_CLEAR_FLAGS: Array[String] = ["vpj_table_01_cleared", "vpj_table_02_cleared", "vpj_table_03_cleared"]
const TABLES_CLEARED_FLAG := "vpj_three_tables_cleared"
const VIP_ENTRY_RECT := Rect2(2632.0, 1584.0, 440.0, 928.0)
const VIP_THRESHOLD_RECT := Rect2(2368.0, 1472.0, 312.0, 448.0)
const ROOM_VISIBILITY_TELEPORT_PATHS: Array[NodePath] = [
	NodePath("../../MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_01"),
	RETURN_TELEPORT_PATH,
	NodePath("../../MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_03"),
]
const ROOM_VISIBILITY_ORDER: Array[StringName] = [
	&"owner_suite",
	&"basement",
	&"street",
	&"bathroom",
	&"stage",
	&"backstage",
	&"club_main",
]
const ROOM_VISIBILITY_RECTS := {
	&"street": Rect2(64.0, 2560.0, 3328.0, 576.0),
	&"club_main": Rect2(64.0, 1088.0, 3008.0, 1408.0),
	&"stage": Rect2(640.0, 448.0, 1408.0, 576.0),
	&"backstage": Rect2(2112.0, 448.0, 1088.0, 576.0),
	&"bathroom": Rect2(64.0, 448.0, 512.0, 576.0),
	&"owner_suite": Rect2(3520.0, 192.0, 896.0, 1216.0),
	&"basement": Rect2(3520.0, 1728.0, 896.0, 1408.0),
}
const ROOM_CURTAIN_COLOR := Color(0.3, 0.3, 0.3, 1.0)
const ROOM_CURTAIN_Z_INDEX := 3000
const BLOCKOUT_TILE_LAYER_PATHS: Array[NodePath] = [
	NodePath("../../GameplayFloorLayer"),
	NodePath("../../GameplayCollisionLayer"),
	NodePath("../../LayoutRoot/FloorLayer"),
	NodePath("../../LayoutRoot/WallLayer"),
	NodePath("../../LayoutRoot/CoverLayer"),
	NodePath("../../LayoutRoot/CollisionBarrierLayer"),
]

@export var mission_id: String = MISSION_ID
@export var return_teleport_path: NodePath = RETURN_TELEPORT_PATH

var eavesdrop_done: bool = false
var alley_intro_done: bool = false
var entered_club: bool = false
var bar_task_done: bool = false
var three_tables_cleared: bool = false
var vip_voicemail_found: bool = false
var staff_badge_collected: bool = false
var staff_gate_open: bool = false
var clue_setlist_read: bool = false
var clue_manager_read: bool = false
var soundcheck_done: bool = false
var decoy_ledger_found: bool = false
var setlist_solved: bool = false
var backstage_hatch_open: bool = false
var yordano_briefed: bool = false
var vault_power_rerouted: bool = false
var server_vault_open: bool = false
var shard_collected: bool = false
var basement_keycard_collected: bool = false
var returned_upstairs_with_shard: bool = false
var owner_stairs_open: bool = false
var owner_defeated: bool = false
var briefcase_collected: bool = false
var escape_hatch_open: bool = false
var secret_collectible_found: bool = false
var completed_objectives: Dictionary = {}

var _last_primary_objective: String = ""
var _room_visibility_curtains: Node2D = null
var _active_room_visibility_id: StringName = &"street"
var _previous_entered_club := false
var _vip_denial_armed := true
var _vip_warning_stage := 0
var _vip_trespass_registered := false
var _vip_alarm_committed := false


func _ready() -> void:
	set_meta("scene_local_only", true)
	_reset_stale_hostile_state()
	_hide_blockout_tile_layers()
	_ensure_room_visibility_curtains()
	_ensure_collision_debug_overlay()
	_apply_room_visibility()
	_seed_objectives()
	_connect_return_teleport()
	_connect_room_visibility_teleports()
	_connect_alert_music()
	_connect_club_entries()
	_connect_vip_protocol()
	call_deferred("_spawn_ambient_guards_after_startup")
	call_deferred("_ensure_authored_cameras_after_startup")
	if not Engine.is_editor_hint():
		set_process(true)


func _hide_blockout_tile_layers() -> void:
	for path: NodePath in BLOCKOUT_TILE_LAYER_PATHS:
		var layer := get_node_or_null(path) as CanvasItem
		if layer != null:
			layer.visible = false


func _process(_delta: float) -> void:
	_sync_club_entry_from_player_position()
	sync_from_mission_facts()
	_update_room_visibility()
	_sync_floor_music()
	_sync_vip_access()
	_sync_table_progression()
	_sync_vip_voicemail()
	_sync_vip_polaroid()


func _sync_vip_polaroid() -> void:
	var pickup := get_node_or_null(VIP_POLAROID_PATH) as Area2D
	if pickup == null:
		return
	var context := {"mission_id": mission_id}
	var protocol_complete := _mission_flag_set("vpj_vip_protocol_complete", context)
	var available := protocol_complete and not CollectibleManager.is_collected("velvet_vip_champagne_polaroid")
	pickup.visible = available
	pickup.collision_layer = 8 if available else 0
	pickup.monitoring = available


func _sync_vip_voicemail() -> void:
	var voicemail := get_node_or_null(VIP_VOICEMAIL_PATH) as Area2D
	if voicemail == null:
		return
	var context := {"mission_id": mission_id}
	var available := _mission_flag_set("vpj_vip_protocol_complete", context) and not _mission_flag_set("vpj_vip_voicemail_found", context)
	voicemail.visible = available
	voicemail.collision_layer = 8 if available else 0
	voicemail.monitoring = available


func _sync_table_progression() -> void:
	var all_cleared := _all_table_flags_set()
	if all_cleared and not _mission_flag_set(TABLES_CLEARED_FLAG, {"mission_id": mission_id}):
		_set_mission_flag(TABLES_CLEARED_FLAG)
	three_tables_cleared = all_cleared
	var service_shape := get_node_or_null(STAGE_SERVICE_DOOR_SHAPE_PATH) as CollisionShape2D
	if service_shape != null:
		service_shape.set_deferred("disabled", all_cleared)


func _all_table_flags_set() -> bool:
	var context := {"mission_id": mission_id}
	for flag_id: String in TABLE_CLEAR_FLAGS:
		if not _mission_flag_set(flag_id, context):
			return false
	return true


func _connect_vip_protocol() -> void:
	var protocol := get_node_or_null(VIP_PROTOCOL_PATH)
	if protocol != null and protocol.has_signal("activation_succeeded"):
		if not protocol.activation_succeeded.is_connected(_on_vip_protocol_succeeded):
			protocol.activation_succeeded.connect(_on_vip_protocol_succeeded)


func _on_vip_protocol_succeeded(_mechanic_id: String, _result: Dictionary) -> void:
	_sync_vip_gate()
	_sync_vip_voicemail()
	_sync_vip_polaroid()
	EventBus.case_hint_requested.emit("VIP access established. Enter from the left and check the phone.", "Mere")


func _sync_floor_music() -> void:
	if _floor_music_should_play() and (not _previous_entered_club or not AudioManager.is_music_playing(FLOOR_MUSIC_KEY)):
		AudioManager.play_music(FLOOR_MUSIC_KEY, 0.25)
	_previous_entered_club = entered_club


func _sync_club_entry_from_player_position() -> void:
	if _mission_flag_set("vpj_entered_club", {"mission_id": mission_id}):
		return
	var player := _find_room_visibility_player()
	if player != null and (ROOM_VISIBILITY_RECTS[&"club_main"] as Rect2).has_point(player.global_position):
		_set_mission_flag("vpj_entered_club")


func _reset_stale_hostile_state() -> void:
	if not GameState.velvet_paw_club_hostile:
		return
	if _mission_flag_set("vpj_shard_collected", {"mission_id": mission_id}):
		return
	GameState.velvet_paw_club_hostile = false
	EventBus.game_state_changed.emit()


func _floor_music_should_play() -> bool:
	if not entered_club or GameState.velvet_paw_club_hostile:
		return false
	var alert := get_node_or_null(ALERT_CONTROLLER_PATH)
	return alert == null or _is_floor_music_alert_state(String(alert.get("alert_state")))


func _is_floor_music_alert_state(state: String) -> bool:
	return state.strip_edges().to_lower() in ["normal", "resolved"]


func _sync_vip_access() -> void:
	_sync_vip_gate()
	var player := _find_room_visibility_player()
	if player == null:
		return
	var protocol_complete := _mission_flag_set("vpj_vip_protocol_complete", {"mission_id": mission_id})
	if protocol_complete and VIP_ENTRY_RECT.has_point(player.global_position):
		_set_mission_flag("vpj_vip_area_entered")
	var bentley_parked := _is_bentley_parked_for_vip()
	var trespassing := not protocol_complete and not bentley_parked and VIP_THRESHOLD_RECT.has_point(player.global_position)
	if trespassing and _vip_denial_armed:
		_vip_denial_armed = false
		_vip_warning_stage = 1
		EventBus.case_hint_requested.emit("VIP warning: back away from the rope and park Bentley at the dance-floor marker.", "VIP Bouncer")
	if not VIP_THRESHOLD_RECT.grow(64.0).has_point(player.global_position):
		_vip_denial_armed = true
		_vip_warning_stage = 0
	var alert := get_node_or_null(ALERT_CONTROLLER_PATH)
	if alert == null:
		return
	if trespassing and not _vip_trespass_registered:
		alert.call("register_suspicious_action", VIP_TRESPASS_ACTION_ID, "trespass")
		_vip_trespass_registered = true
	elif not trespassing and _vip_trespass_registered:
		alert.call("end_suspicious_action", VIP_TRESPASS_ACTION_ID)
		_vip_trespass_registered = false
	if trespassing and _vip_warning_stage == 1 and (String(alert.get("alert_state")) == "suspicious" or _vip_camera_exposure_progress() >= 0.5):
		_vip_warning_stage = 2
		EventBus.case_hint_requested.emit("Final warning: leave the VIP camera now and park Bentley, or security will respond.", "VIP Bouncer")
	if trespassing and String(alert.get("alert_state")) == "alerted" and String(alert.get("last_detection_source")) == VIP_CAMERA_ID:
		_commit_vip_trespass_alarm()


func _sync_vip_gate() -> void:
	var unlocked := _vip_gate_prerequisites_met()
	var shape := get_node_or_null(VIP_GATE_SHAPE_PATH) as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", unlocked)
	var protocol := get_node_or_null(VIP_PROTOCOL_PATH) as Area2D
	if protocol != null:
		protocol.set("enabled", unlocked)
		protocol.collision_layer = 8 if unlocked else 0
		protocol.set_deferred("monitoring", unlocked)


func _vip_gate_prerequisites_met() -> bool:
	var context := {"mission_id": mission_id}
	var has_cover := bool(SocialStealthAdapter.get_fact_value(SocialStealthAdapter.FACT_COVER_STORY_ACTIVE, "velvet_paw_new_staff", context))
	return has_cover and _all_table_flags_set() and _is_bentley_parked_for_vip()


func _is_bentley_parked_for_vip() -> bool:
	var bentley := get_tree().get_first_node_in_group("bentley")
	if bentley == null or not bentley.has_method("get_command_state"):
		return false
	var state: Dictionary = bentley.call("get_command_state")
	if String(state.get("wait_marker_id", "")) != VIP_WAIT_MARKER_ID:
		return false
	var wait_position: Variant = state.get("wait_marker_position", Vector2.INF)
	return wait_position is Vector2 and bentley is Node2D and (bentley as Node2D).global_position.distance_to(wait_position) <= VIP_WAIT_MAX_DISTANCE


func _commit_vip_trespass_alarm() -> void:
	if _vip_alarm_committed or not _vip_camera_exposure_complete():
		return
	_vip_alarm_committed = true
	_set_mission_flag("vpj_vip_trespass_alarm")
	var mission := get_node_or_null("../../..")
	var dispatch_result: Dictionary = {}
	if mission != null and mission.has_method("get_security_event_router"):
		var router: Variant = mission.call("get_security_event_router")
		if router is Node and (router as Node).has_method("emit_event"):
			dispatch_result = (router as Node).call("emit_event", &"vip_trespass_alarm", {"source_id": VIP_CAMERA_ID, "reason": "bentley_at_vip_gate"})
	if not bool(dispatch_result.get("handled", false)):
		var reinforcement := get_node_or_null(VIP_REINFORCEMENT_PATH)
		if reinforcement != null and reinforcement.has_method("on_security_event"):
			reinforcement.call("bind_mission", mission)
			reinforcement.call("on_security_event", &"vip_trespass_alarm", {"source_id": VIP_CAMERA_ID, "reason": "bentley_at_vip_gate"})
	for guard: Node in get_tree().get_nodes_in_group("enemy"):
		if guard.has_method("set_hostile"):
			guard.call("set_hostile", true, false)
	AudioManager.stop_music(0.15)


func _vip_camera_exposure_complete() -> bool:
	var mission := get_node_or_null("../../..")
	for camera: Node in get_tree().get_nodes_in_group("iso_security_camera"):
		if mission != null and not mission.is_ancestor_of(camera):
			continue
		if String(camera.get("camera_id")) != VIP_CAMERA_ID:
			continue
		return camera.has_method("is_minimum_exposure_complete") and bool(camera.call("is_minimum_exposure_complete"))
	return false


func _vip_camera_exposure_progress() -> float:
	var mission := get_node_or_null("../../..")
	for camera: Node in get_tree().get_nodes_in_group("iso_security_camera"):
		if mission != null and not mission.is_ancestor_of(camera):
			continue
		if String(camera.get("camera_id")) == VIP_CAMERA_ID and camera.has_method("get_minimum_exposure_progress"):
			return float(camera.call("get_minimum_exposure_progress"))
	return 0.0


func trigger_hostile_state(_source_id: String = "f12_qa") -> Dictionary:
	var changed := not GameState.velvet_paw_club_hostile
	GameState.velvet_paw_club_hostile = true
	for guard: Node in get_tree().get_nodes_in_group("enemy"):
		if guard.has_method("set_hostile"):
			guard.call("set_hostile", true, false)
	AudioManager.stop_music(0.25)
	if changed:
		EventBus.game_state_changed.emit()
	_sync_objective_chain()
	return {"ok": true, "changed": changed, "hostile": true}


func _ensure_room_visibility_curtains() -> void:
	if _room_visibility_curtains != null and is_instance_valid(_room_visibility_curtains):
		return
	_room_visibility_curtains = Node2D.new()
	_room_visibility_curtains.name = "RoomVisibilityCurtains"
	_room_visibility_curtains.z_as_relative = false
	_room_visibility_curtains.z_index = ROOM_CURTAIN_Z_INDEX
	add_child(_room_visibility_curtains)
	for area_id: StringName in ROOM_VISIBILITY_ORDER:
		var rect: Rect2 = ROOM_VISIBILITY_RECTS[area_id]
		var curtain := Polygon2D.new()
		curtain.name = "%sCurtain" % String(area_id).to_pascal_case()
		curtain.color = ROOM_CURTAIN_COLOR
		curtain.polygon = PackedVector2Array([
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		])
		curtain.set_meta("room_visibility_id", area_id)
		_room_visibility_curtains.add_child(curtain)


func _ensure_collision_debug_overlay() -> void:
	if get_node_or_null("CollisionDebugOverlay") != null:
		return
	var overlay := CollisionDebugOverlayScript.new()
	add_child(overlay)


func _update_room_visibility() -> void:
	var player := _find_room_visibility_player()
	if player == null:
		return
	var area_id := _room_visibility_id_at(player.global_position)
	if area_id == &"" or area_id == _active_room_visibility_id:
		return
	_active_room_visibility_id = area_id
	_apply_room_visibility()


func _find_room_visibility_player() -> Node2D:
	var player := get_node_or_null(PLAYER_PATH) as Node2D
	if player != null:
		return player
	var runtime_helpers := get_parent()
	if runtime_helpers == null or runtime_helpers.get_parent() == null:
		return null
	var mission := runtime_helpers.get_parent().get_parent()
	if mission == null:
		return null
	for candidate: Node in get_tree().get_nodes_in_group("player"):
		if candidate is Node2D and mission.is_ancestor_of(candidate):
			return candidate as Node2D
	var mission_player: Variant = mission.get("player")
	return mission_player as Node2D


func _room_visibility_id_at(world_position: Vector2) -> StringName:
	for area_id: StringName in ROOM_VISIBILITY_ORDER:
		var rect: Rect2 = ROOM_VISIBILITY_RECTS[area_id]
		if rect.has_point(world_position):
			return area_id
	return &""


func _apply_room_visibility() -> void:
	if _room_visibility_curtains == null:
		return
	for child: Node in _room_visibility_curtains.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = StringName(child.get_meta("room_visibility_id", &"")) != _active_room_visibility_id


func get_room_visibility_summary() -> Dictionary:
	var curtain_visibility: Dictionary = {}
	if _room_visibility_curtains != null:
		for child: Node in _room_visibility_curtains.get_children():
			curtain_visibility[String(child.get_meta("room_visibility_id", &""))] = (child as CanvasItem).visible
	return {
		"active_area_id": String(_active_room_visibility_id),
		"curtain_visibility": curtain_visibility,
	}


func reset_attempt_state() -> Dictionary:
	_active_room_visibility_id = &"street"
	_apply_room_visibility()
	eavesdrop_done = false
	alley_intro_done = false
	entered_club = false
	bar_task_done = false
	three_tables_cleared = false
	vip_voicemail_found = false
	staff_badge_collected = false
	staff_gate_open = false
	clue_setlist_read = false
	clue_manager_read = false
	soundcheck_done = false
	decoy_ledger_found = false
	setlist_solved = false
	backstage_hatch_open = false
	yordano_briefed = false
	vault_power_rerouted = false
	server_vault_open = false
	shard_collected = false
	basement_keycard_collected = false
	returned_upstairs_with_shard = false
	owner_stairs_open = false
	owner_defeated = false
	briefcase_collected = false
	escape_hatch_open = false
	secret_collectible_found = false
	_previous_entered_club = false
	_vip_denial_armed = true
	_vip_trespass_registered = false
	_vip_alarm_committed = false
	completed_objectives.clear()
	_last_primary_objective = ""
	return _seed_objectives()


func sync_from_mission_facts() -> void:
	_sync_authored_clue_flags()
	var context := {"mission_id": mission_id}
	eavesdrop_done = _mission_flag_set("vpj_eavesdrop_done", context)
	alley_intro_done = _mission_flag_set("vpj_alley_intro_done", context)
	entered_club = _mission_flag_set("vpj_entered_club", context)
	bar_task_done = _mission_flag_set("vpj_bar_task_done", context)
	three_tables_cleared = _mission_flag_set(TABLES_CLEARED_FLAG, context) or _all_table_flags_set()
	vip_voicemail_found = _mission_flag_set("vpj_vip_voicemail_found", context)
	staff_badge_collected = _mission_flag_set("vpj_staff_badge_collected", context)
	staff_gate_open = _mission_flag_set("vpj_staff_gate_open", context)
	clue_setlist_read = _mission_flag_set("vpj_clue_setlist_read", context)
	clue_manager_read = _mission_flag_set("vpj_clue_manager_read", context)
	soundcheck_done = _mission_flag_set("vpj_soundcheck_done", context)
	decoy_ledger_found = _mission_flag_set("vpj_decoy_ledger_found", context)
	setlist_solved = _mission_flag_set("vpj_setlist_solved", context)
	backstage_hatch_open = _mission_flag_set("vpj_backstage_hatch_open", context)
	yordano_briefed = _mission_flag_set("vpj_yordano_briefed", context)
	vault_power_rerouted = _mission_flag_set("vpj_vault_power_rerouted", context)
	server_vault_open = _mission_flag_set("vpj_server_vault_open", context)
	shard_collected = _mission_flag_set("vpj_shard_collected", context)
	basement_keycard_collected = bool(MissionFactBridge.get_fact_value(&"inventory_has_item", "velvet_paw_basement_keycard", context))
	owner_stairs_open = _mission_flag_set("vpj_owner_stairs_open", context)
	owner_defeated = _mission_flag_set("vpj_owner_defeated", context)
	briefcase_collected = _mission_flag_set("vpj_briefcase_collected", context)
	escape_hatch_open = _mission_flag_set("vpj_escape_hatch_open", context)
	secret_collectible_found = _mission_flag_set("secret_velvet_collectible", context)
	_apply_game_state_side_effects()
	_sync_objective_chain()


func mark_returned_upstairs() -> void:
	if not shard_collected:
		return
	returned_upstairs_with_shard = true
	_apply_game_state_side_effects()
	_sync_objective_chain()


func trigger_wrong_note_alarm(payload: Dictionary, _context: Dictionary = {}) -> void:
	var mission := get_tree().current_scene
	if mission == null or not mission.has_method("get_security_event_router"):
		return
	var router: Variant = mission.call("get_security_event_router")
	if router is Node and (router as Node).has_method("emit_event"):
		var event_id := StringName(String(payload.get("event_id", "wrong_note_alarm")))
		(router as Node).call("emit_event", event_id, payload)


func _mission_flag_set(flag_id: String, context: Dictionary) -> bool:
	return bool(MissionFactBridge.get_fact_value(&"mission_flag", flag_id, context))


func _apply_game_state_side_effects() -> void:
	var changed := false
	if shard_collected and not GameState.velvet_paw_basement_shard_collected:
		GameState.velvet_paw_basement_shard_collected = true
		changed = true
	if basement_keycard_collected and not GameState.velvet_paw_basement_keycard_collected:
		GameState.velvet_paw_basement_keycard_collected = true
		changed = true
	if shard_collected and returned_upstairs_with_shard and not GameState.velvet_paw_club_hostile:
		GameState.velvet_paw_club_hostile = true
		AudioManager.stop_music(0.25)
		changed = true
	if changed:
		EventBus.game_state_changed.emit()


func _sync_authored_clue_flags() -> void:
	var mission := get_tree().current_scene
	if mission == null or not mission.has_method("get_authored_collectible_attempt_snapshot"):
		return
	var snapshot: Dictionary = mission.call("get_authored_collectible_attempt_snapshot")
	for clue_value: Variant in snapshot.get("clues", []):
		if not (clue_value is Dictionary):
			continue
		var clue_id := String((clue_value as Dictionary).get("id", ""))
		if clue_id == "velvet_paw_jazz_club.clue_author.01":
			_set_mission_flag("vpj_clue_setlist_read")
		elif clue_id == "velvet_paw_jazz_club.clue_author.02":
			_set_mission_flag("vpj_clue_manager_read")


func _set_mission_flag(flag_id: String) -> void:
	MissionFactBridge.set_fact_value(&"mission_flag", flag_id, true, {"mission_id": mission_id})


func _connect_return_teleport() -> void:
	var return_zone := get_node_or_null(return_teleport_path)
	if return_zone == null or not return_zone.has_signal("activation_succeeded"):
		return
	if not return_zone.activation_succeeded.is_connected(_on_return_teleport_succeeded):
		return_zone.activation_succeeded.connect(_on_return_teleport_succeeded)


func _connect_room_visibility_teleports() -> void:
	for path: NodePath in ROOM_VISIBILITY_TELEPORT_PATHS:
		var teleport := get_node_or_null(path)
		if teleport == null or not teleport.has_signal("activation_succeeded"):
			continue
		if not teleport.activation_succeeded.is_connected(_on_room_visibility_teleport_succeeded):
			teleport.activation_succeeded.connect(_on_room_visibility_teleport_succeeded)


func _connect_alert_music() -> void:
	var alert_controller := get_node_or_null(ALERT_CONTROLLER_PATH)
	if alert_controller == null or not alert_controller.has_signal("alert_state_changed"):
		return
	if not alert_controller.alert_state_changed.is_connected(_on_alert_state_changed):
		alert_controller.alert_state_changed.connect(_on_alert_state_changed)


func _connect_club_entries() -> void:
	for path: NodePath in CLUB_ENTRY_PATHS:
		var entry := get_node_or_null(path)
		if entry != null and entry.has_signal("activation_succeeded"):
			if not entry.activation_succeeded.is_connected(_on_club_entry_succeeded):
				entry.activation_succeeded.connect(_on_club_entry_succeeded)


func _on_club_entry_succeeded(_mechanic_id: String, _result: Dictionary) -> void:
	sync_from_mission_facts()
	_sync_floor_music()


func _spawn_ambient_guards_after_startup() -> void:
	var mission := get_node_or_null("../../..")
	var security_root := get_node_or_null("../../SecurityAuthoringRoot")
	if mission == null or security_root == null or not security_root.has_method("collect_guard_spawn_authors"):
		return
	for author in security_root.call("collect_guard_spawn_authors"):
		if author is Node and bool(author.get("spawn_on_ready")) and author.has_method("spawn_initial"):
			if author.has_method("get_alive_count") and int(author.call("get_alive_count")) > 0:
				continue
			if author.has_method("reset_runtime"):
				author.call("reset_runtime")
			author.call("bind_mission", mission)
			author.call("spawn_initial")


func _ensure_authored_cameras_after_startup() -> void:
	var mission := get_node_or_null("../../..")
	var security_root := get_node_or_null("../../SecurityAuthoringRoot")
	if mission == null or security_root == null or not security_root.has_method("collect_camera_authors"):
		return
	var router: Node = mission.call("get_security_event_router") if mission.has_method("get_security_event_router") else null
	var camera_parent := mission.get_node_or_null("EntityRoot/Cameras")
	for author: Node in security_root.call("collect_camera_authors"):
		var already_spawned := false
		if camera_parent != null:
			for runtime_camera: Node in camera_parent.get_children():
				if String(runtime_camera.get_meta("author_path", "")) == String(author.get_path()):
					already_spawned = true
					break
		if already_spawned:
			continue
		if author.has_method("setup_runtime_camera"):
			author.call("setup_runtime_camera", mission, router)


func _on_alert_state_changed(state: String) -> void:
	if _is_floor_music_alert_state(state) and entered_club and not GameState.velvet_paw_club_hostile:
		AudioManager.play_music(FLOOR_MUSIC_KEY, 0.25)
	else:
		AudioManager.stop_music(0.25)


func _on_room_visibility_teleport_succeeded(_mechanic_id: String, _result: Dictionary) -> void:
	_update_room_visibility()


func _on_return_teleport_succeeded(_mechanic_id: String, _result: Dictionary) -> void:
	sync_from_mission_facts()
	mark_returned_upstairs()


func _sync_objective_chain() -> void:
	if entered_club and _complete_once("enter_club"):
		ObjectiveStepController.activate_objective("collect_staff_badge", "Grab the staff badge from the dressing area.", mission_id)
	if staff_badge_collected and _complete_once("collect_staff_badge"):
		ObjectiveStepController.activate_objective("open_staff_gate", "Swipe into the stage wing.", mission_id)
	if staff_gate_open and _complete_once("open_staff_gate"):
		ObjectiveStepController.activate_objective("read_setlist_clues", "Read both setlist clues backstage.", mission_id)
	if clue_setlist_read and clue_manager_read and _complete_once("read_setlist_clues"):
		ObjectiveStepController.activate_objective("solve_setlist", "Solve the five-song stage setlist.", mission_id)
	if setlist_solved and _complete_once("solve_setlist"):
		ObjectiveStepController.activate_objective("recover_shard", "Reach the basement server vault and recover Sterling's shard.", mission_id)
	if shard_collected and _complete_once("recover_shard"):
		ObjectiveStepController.activate_objective("return_upstairs", "Get back upstairs with the ledger shard.", mission_id)
	if GameState.velvet_paw_club_hostile and _complete_once("return_upstairs"):
		ObjectiveStepController.activate_objective("defeat_owner", "Reach the rig stairs and clear the owner suite.", mission_id)
	if owner_defeated and _complete_once("defeat_owner"):
		ObjectiveStepController.activate_objective("recover_briefcase", "Grab the blackmail briefcase on the balcony.", mission_id)
	if briefcase_collected and _complete_once("recover_briefcase"):
		ObjectiveStepController.activate_objective("open_escape", "Release the basement escape hatch.", mission_id)
	if escape_hatch_open and _complete_once("open_escape"):
		ObjectiveStepController.activate_objective("extract_basement", "Escape on Yordano's bass drop.", mission_id)
	_set_primary_objective(_current_primary_objective())


func _complete_once(objective_id: String) -> bool:
	if completed_objectives.has(objective_id):
		return false
	completed_objectives[objective_id] = true
	ObjectiveStepController.complete_objective(objective_id, "", mission_id)
	return true


func _current_primary_objective() -> String:
	if not entered_club:
		return "The Velvet Paw is hopping tonight. Find the propped staff entrance."
	if not staff_gate_open:
		return "Avoid the bouncers, find the green-room staff badge, and reach the stage wing."
	if not setlist_solved:
		return "Read both backstage clues, then solve the five-song setlist on stage."
	if not shard_collected:
		return "Open the service hatch and recover Sterling's shard from the basement server vault."
	if not GameState.velvet_paw_club_hostile:
		return "Get back upstairs with the ledger shard."
	if not owner_defeated:
		return "The club has gone hostile. Use the rig stairs and clear the owner suite."
	if not briefcase_collected:
		return "Briefcase on the balcony. Grab it and don't admire the view."
	if not escape_hatch_open:
		return "Release the basement escape hatch."
	return "Bass drop time. Escape through the basement exit before the bouncers regroup."


func _set_primary_objective(text: String) -> void:
	if text == _last_primary_objective:
		return
	_last_primary_objective = text
	QuestManager.set_objective(text, mission_id)


func _seed_objectives() -> Dictionary:
	return MissionObjectiveBridge.seed_runtime_objectives_for_mission(mission_id, [
		{"id": "enter_club", "text": "Find the propped staff entrance.", "status": "active"},
		{"id": "collect_staff_badge", "text": "Grab the staff badge from the dressing area.", "status": "locked"},
		{"id": "open_staff_gate", "text": "Swipe into the stage wing.", "status": "locked"},
		{"id": "read_setlist_clues", "text": "Read both setlist clues backstage.", "status": "locked"},
		{"id": "solve_setlist", "text": "Solve the five-song stage setlist.", "status": "locked"},
		{"id": "recover_shard", "text": "Recover Sterling's shard from the basement server vault.", "status": "locked"},
		{"id": "return_upstairs", "text": "Get back upstairs with the ledger shard.", "status": "locked"},
		{"id": "defeat_owner", "text": "Clear the owner suite.", "status": "locked"},
		{"id": "recover_briefcase", "text": "Grab the blackmail briefcase.", "status": "locked"},
		{"id": "open_escape", "text": "Release the basement escape hatch.", "status": "locked"},
		{"id": "extract_basement", "text": "Escape on Yordano's bass drop.", "status": "locked"},
	])
