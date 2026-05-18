@tool
extends "res://src/missions/iso/authoring/SecurityEffectAuthorBase.gd"

@export_group("Lockdown")
@export var lockdown_level: int = 1
@export var set_alert_state: StringName = &"alerted"
@export var emit_debug_message := true


func get_effect_type() -> String:
	return "lockdown"


func _apply_effect(event_id: String, _payload: Dictionary) -> Dictionary:
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller == null:
		return _reject("rejected_missing_alert_controller")
	var state := String(set_alert_state).strip_edges().to_lower()
	if state != "" and controller.has_method("set_alert_state"):
		controller.call("set_alert_state", state)
	elif lockdown_level > 0 and controller.has_method("register_detection_event"):
		controller.call("register_detection_event", String(effect_id), float(lockdown_level), "authoring_lockdown")
	else:
		return _reject("rejected_missing_lockdown_api")
	if _mission != null:
		_mission.set_meta("d6_05_lockdown_active", true)
		_mission.set_meta("d6_05_lockdown_level", lockdown_level)
		_mission.set_meta("d6_05_lockdown_event", event_id)
	if emit_debug_message:
		EventBus.debug("Security lockdown effect %s -> %s (level %d)" % [String(effect_id), state, lockdown_level])
	return _success(
		"lockdown_applied",
		state,
		{
			"lockdown_level": lockdown_level,
			"alert_state": state,
			"event_id": event_id,
		},
	)
