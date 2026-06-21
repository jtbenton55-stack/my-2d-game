class_name MissionPoopBagDecoyPoint
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

@export var decoy_id: String = ""
@export var distraction_seconds: float = 5.0
@export_multiline var no_bag_text: String = "Need at least one poop bag for a decoy."
@export_multiline var used_text: String = "Poop bag decoy deployed. Nearby guard is distracted."
@export_group("Noise")
@export var emit_noise_on_use: bool = true
@export var noise_id: StringName = &"poop_bag_decoy_noise"
@export_enum("generic", "bark", "decoy", "object", "alarm", "footstep", "poop_decoy") var noise_kind: String = "poop_decoy"
@export_enum("neutral", "player", "npc", "security") var noise_team: String = "player"
@export var noise_radius: float = 220.0
@export var noise_strength: float = 0.8
@export var route_to_alert_controller: bool = true

var last_noise_event: Dictionary = {}
var last_noise_result: Dictionary = {}


func _ready() -> void:
	auto_trigger_on_enter = false
	once_only = false
	interaction_priority = 70
	allow_repeat_interaction = true
	available_when_completed = true
	if interaction_text.strip_edges() == "":
		interaction_text = "Click to deploy poop bag decoy."
	super._ready()
	add_to_group("iso_poop_decoy")


func _complete(player: Node = null) -> void:
	if not GameState.try_consume_poop_bag():
		_show(no_bag_text)
		return
	_apply_distraction()
	if emit_noise_on_use:
		last_noise_result = emit_decoy_noise(player)
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	if mid != "":
		GameState.record_mission_performance_event(mid, "poop_bags_collected", -1)
	_show(used_text)
	super._complete(player)


func emit_decoy_noise(actor: Node = null) -> Dictionary:
	var source := decoy_id if decoy_id.strip_edges() != "" else placeholder_id
	if source.strip_edges() == "":
		source = name
	var event := NoiseEventHelper.make_event(
		String(noise_id),
		source,
		global_position,
		noise_radius,
		noise_strength,
		noise_kind,
		noise_team,
		{"actor_path": str(actor.get_path()) if actor != null and actor.is_inside_tree() else "", "reason": "poop_bag_decoy"}
	)
	event["mechanic_path"] = str(get_path()) if is_inside_tree() else ""
	last_noise_event = event
	if EventBus.has_signal("mission_noise_emitted"):
		EventBus.mission_noise_emitted.emit(event)
	EventBus.debug("Poop bag decoy noise emitted %s" % NoiseEventHelper.debug_summary(event))
	var alert_result := {}
	var controller := _find_alert_controller()
	if route_to_alert_controller and controller != null and controller.has_method("register_noise_event"):
		alert_result = controller.call("register_noise_event", event)
	return {"ok": true, "code": "noise_emitted", "noise_event": event, "alert_result": alert_result}


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


func _apply_distraction() -> void:
	var closest: Node2D = null
	var best := INF
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D:
			var d := global_position.distance_to(enemy.global_position)
			if d < 220.0 and d < best:
				best = d
				closest = enemy
	if closest != null:
		if closest.has_method("stun"):
			closest.stun(distraction_seconds)
		else:
			closest.set_meta("iso_distracted_until", Time.get_ticks_msec() + int(distraction_seconds * 1000.0))


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


func _show(text: String) -> void:
	QuestManager.set_objective(text, mission_id)
	DialogueManager.start_simple_dialogue([{ "speaker": "Bentley", "text": text }])
