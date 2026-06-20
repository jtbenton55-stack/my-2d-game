@tool
class_name NoiseEmitterNode
extends "res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd"

const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

@export_group("Noise")
@export var noise_id: StringName = &"noise_event"
@export_enum("generic", "bark", "decoy", "object", "alarm", "footstep") var noise_kind: String = "generic"
@export_enum("neutral", "player", "npc", "security") var noise_team: String = "neutral"
@export var noise_radius: float = 192.0
@export var noise_strength: float = 1.0
@export var emit_on_success: bool = true
@export var route_to_alert_controller: bool = true

var last_noise_event: Dictionary = {}
var last_noise_result: Dictionary = {}


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["noise_event"] = last_noise_event
	context["noise_result"] = last_noise_result
	return context


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result := super.activate(actor, reason)
	if emit_on_success and bool(result.get("ok", false)) and String(result.get("code", "")) == "activation_succeeded":
		last_noise_result = emit_noise(actor, reason)
		var details: Dictionary = result.get("details", {})
		details["noise_result"] = last_noise_result
		result["details"] = details
		last_activation_result = result
	return result


func emit_noise(actor: Node = null, reason: String = "script") -> Dictionary:
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Noise skipped in editor preview.", String(mechanic_id), {"reason": reason})
	var event := NoiseEventHelper.make_event(
		String(noise_id),
		String(mechanic_id),
		global_position,
		noise_radius,
		noise_strength,
		noise_kind,
		noise_team,
		{"actor_path": str(actor.get_path()) if actor != null and actor.is_inside_tree() else "", "reason": reason}
	)
	event["mechanic_path"] = str(get_path())
	last_noise_event = event
	var alert_result := {}
	if EventBus.has_signal("mission_noise_emitted"):
		EventBus.mission_noise_emitted.emit(event)
	EventBus.debug("Noise emitted %s" % NoiseEventHelper.debug_summary(event))
	var controller := _find_alert_controller()
	if route_to_alert_controller and controller != null and controller.has_method("register_noise_event"):
		alert_result = controller.call("register_noise_event", event)
	return _result(true, "noise_emitted", "Noise event emitted.", String(mechanic_id), {"noise_event": event, "alert_result": alert_result})


func get_noise_summary() -> Dictionary:
	return {
		"noise_id": String(noise_id),
		"kind": noise_kind,
		"team": noise_team,
		"radius": noise_radius,
		"strength": noise_strength,
		"last_noise_event": last_noise_event.duplicate(true),
		"last_noise_result": last_noise_result.duplicate(true),
	}


func _find_alert_controller() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var grouped := tree.get_first_node_in_group("iso_alert_controller")
	if grouped != null:
		return grouped
	if tree.current_scene != null:
		return tree.current_scene.find_child("MissionAlertController", true, false)
	return null
