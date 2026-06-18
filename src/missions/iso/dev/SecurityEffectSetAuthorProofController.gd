extends Node2D

const MissionAuthoringRuntimeBuilderScript := preload("res://src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd")

const DEV_MISSION_ID := "phase4b_security_effect_set_proof"
const TEST_EVENT_ID := &"phase4b_area_alarm"
const TEST_FLAG_ID := "phase4b_area_alarm_effect_seen"

@export var status_label_path: NodePath = NodePath("UI/StatusLabel")

var _router: Node = null
var _snapshot: Dictionary = {}
var _last_effect_type: String = ""
var _last_effect_result: Dictionary = {}
var _effect_author_count := 0
var _effect_set_author_count := 0

@onready var _status_label: Label = get_node_or_null(status_label_path) as Label


func _ready() -> void:
	_snapshot_game_state()
	GameState.current_mission_id = DEV_MISSION_ID
	GameState.pending_mission_id = ""
	GameState.dialogue_flags.clear()
	var authoring_root := get_node_or_null("GameplayRoot/SecurityAuthoringRoot") as Node2D
	_router = MissionAuthoringRuntimeBuilderScript.setup(self, authoring_root)
	_refresh_status()


func _exit_tree() -> void:
	_restore_game_state()


func get_security_event_router() -> Node:
	return _router


func set_security_event_router(router: Node) -> void:
	_router = router


func emit_phase4b_test_event() -> Dictionary:
	if _router == null or not is_instance_valid(_router):
		return {"handled": false, "reason": "router_missing"}
	var result: Dictionary = _router.call("emit_event", TEST_EVENT_ID, {
		"source_type": "phase4b_dev_scene",
		"source_id": "Phase4B_AreaAlarm_Author",
		"reason": "scene_proof_manual_emit",
	})
	_refresh_status()
	return result


func is_phase4b_flag_set() -> bool:
	return bool(GameState.dialogue_flags.get(_flag_key(), false))


func get_phase4b_debug_summary() -> Dictionary:
	return {
		"mission_id": DEV_MISSION_ID,
		"event_id": String(TEST_EVENT_ID),
		"flag_id": TEST_FLAG_ID,
		"flag_set": is_phase4b_flag_set(),
		"router_active": _router != null and is_instance_valid(_router),
		"registered_event_count": int(_router.call("get_registered_event_count")) if _router != null else 0,
		"effect_author_count": _effect_author_count,
		"effect_set_count": _effect_set_author_count,
		"last_effect_type": _last_effect_type,
		"last_effect_result": _last_effect_result.duplicate(true),
	}


func _store_d6_05_effect_author_counts(door_n: int, lockdown_n: int, objective_n: int, toggle_n: int) -> void:
	_effect_author_count = door_n + lockdown_n + objective_n + toggle_n


func _store_d6_05_effect_set_author_count(effect_set_n: int) -> void:
	_effect_set_author_count = effect_set_n
	_effect_author_count += effect_set_n


func _record_authoring_effect_result(effect_type: String, _author: Node, result: Dictionary) -> void:
	_last_effect_type = effect_type
	_last_effect_result = result.duplicate(true)
	_refresh_status()


func _snapshot_game_state() -> void:
	_snapshot = {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
	}


func _restore_game_state() -> void:
	if _snapshot.is_empty():
		return
	GameState.current_mission_id = String(_snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(_snapshot.get("pending_mission_id", ""))
	GameState.dialogue_flags = (_snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)


func _flag_key() -> String:
	return "mission_flag:%s:%s" % [DEV_MISSION_ID, TEST_FLAG_ID]


func _refresh_status() -> void:
	if _status_label == null:
		return
	_status_label.text = "Phase 4B security EffectSet proof\nEvent: %s\nFlag set: %s\nLast: %s/%s" % [
		String(TEST_EVENT_ID),
		str(is_phase4b_flag_set()),
		String(_last_effect_result.get("result", "none")),
		String(_last_effect_result.get("reason", "")),
	]
