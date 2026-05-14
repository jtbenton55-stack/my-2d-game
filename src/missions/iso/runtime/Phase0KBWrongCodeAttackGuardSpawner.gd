@tool
class_name Phase0KBWrongCodeAttackGuardSpawner
extends Node

@export var wrong_code_threshold := 2
@export var safe_code_marker_path: NodePath = NodePath("../../MarkerRoot/EditorOnlyPlaceholders/SAFE_CODE_INPUT_ZONE")
@export var debug_hud_path: NodePath = NodePath("../Phase0JDebugHUD")

var wrong_code_attempts := 0
var dispatched_guard_count := 0
var max_dispatched_guards := 1
var _last_effective_wrong_threshold := 2


func _ready() -> void:
	set_meta("generated_by", "Phase0K-B")
	set_meta("scene_local_only", true)


func register_wrong_code_attempt() -> Dictionary:
	var eff_threshold := wrong_code_threshold
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("get_wrong_code_alarm_threshold"):
		eff_threshold = maxi(1, int(mission.call("get_wrong_code_alarm_threshold")))
	_last_effective_wrong_threshold = eff_threshold
	wrong_code_attempts += 1
	_report_wrong_code_security_event()
	if wrong_code_attempts < eff_threshold:
		_show("Wrong code. Security heard the keypad.")
		return _result(false, "warning_only")
	if wrong_code_attempts == eff_threshold:
		_report_wrong_code_alarm_event()
	if dispatched_guard_count >= max_dispatched_guards:
		_show("Wrong code again - guard already dispatched!")
		return _result(false, "guard_already_dispatched")
	var guard := spawn_attack_guard()
	var spawned := guard != null
	if spawned:
		_report_reinforcement_security_event(String(guard.name))
	_show("Wrong code again - guard incoming!" if spawned else "Wrong code again - guard dispatch failed.")
	return _result(spawned, "guard_dispatched" if spawned else "spawn_failed")


func spawn_attack_guard() -> Node:
	## Use canonical `guard.tscn` via mission (same as MissionCodeGatePlaceholder / alarm spawns).
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("spawn_attack_guard_near_player"):
		mission.call("spawn_attack_guard_near_player", "wrong_code_phase0kb")
		call_deferred("_finalize_wrong_code_spawn_result")
		return mission
	push_warning("[Phase0KB] spawn_attack_guard: mission missing spawn_attack_guard_near_player; no guard spawned.")
	return null


func _finalize_wrong_code_spawn_result() -> void:
	var mission := get_tree().current_scene
	if mission == null or not mission.has_method("get_runtime_debug_summary"):
		return
	var rsum: Dictionary = mission.call("get_runtime_debug_summary")
	var probe: Dictionary = rsum.get("d6_fix5_spawn_probe", {}) as Dictionary
	if String(probe.get("source_id", "")) == "wrong_code_phase0kb" and String(probe.get("result", "")) == "success":
		dispatched_guard_count = maxi(dispatched_guard_count, int(rsum.get("security_response_spawn_count", dispatched_guard_count)))


func _result(spawned: bool, status: String) -> Dictionary:
	return {
		"wrong_code_attempts": wrong_code_attempts,
		"threshold": _last_effective_wrong_threshold,
		"guard_spawned": spawned,
		"status": status,
		"dispatched_guard_count": dispatched_guard_count,
	}


func _show(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 4.0)
	if has_node("/root/EventBus"):
		EventBus.objective_updated.emit(text)


func _report_wrong_code_security_event() -> void:
	var ctrl := get_tree().get_first_node_in_group("iso_alert_controller")
	if ctrl == null or not ctrl.has_method("get_security_event_adapter"):
		return
	var adapter: Variant = ctrl.call("get_security_event_adapter")
	if adapter != null and adapter.has_method("report_security_event"):
		adapter.call("report_security_event", "wrong_code", "phase0kb_wrong_code_spawner", 1, {"attempts": wrong_code_attempts})


func _report_wrong_code_alarm_event() -> void:
	var ctrl := get_tree().get_first_node_in_group("iso_alert_controller")
	if ctrl == null or not ctrl.has_method("get_security_event_adapter"):
		return
	var adapter: Variant = ctrl.call("get_security_event_adapter")
	if adapter != null and adapter.has_method("report_security_event"):
		adapter.call("report_security_event", "wrong_code_alarm", "phase0kb_wrong_code_spawner", 2, {"attempts": wrong_code_attempts})


func _report_reinforcement_security_event(guard_name: String) -> void:
	var ctrl := get_tree().get_first_node_in_group("iso_alert_controller")
	if ctrl == null or not ctrl.has_method("get_security_event_adapter"):
		return
	var adapter: Variant = ctrl.call("get_security_event_adapter")
	if adapter != null and adapter.has_method("report_security_event"):
		adapter.call("report_security_event", "reinforcement_spawned", guard_name, 2, {"reason": "wrong_code"})
