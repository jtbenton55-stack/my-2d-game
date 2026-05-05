class_name MissionPoopBagDecoyPoint
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var decoy_id: String = ""
@export var distraction_seconds: float = 5.0
@export_multiline var no_bag_text: String = "Need at least one poop bag for a decoy."
@export_multiline var used_text: String = "Poop bag decoy deployed. Nearby guard is distracted."


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
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	if mid != "":
		GameState.record_mission_performance_event(mid, "poop_bags_collected", -1)
	_show(used_text)
	super._complete(player)


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


func _show(text: String) -> void:
	QuestManager.set_objective(text, mission_id)
	DialogueManager.start_simple_dialogue([{ "speaker": "Bentley", "text": text }])
