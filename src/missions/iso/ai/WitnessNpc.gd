class_name WitnessNpc
extends Node2D

## Replan Packet 5: every NPC is a camera with legs -- but slower and
## distractible. A witness that spots mess telegraphs a "?" (your window to
## act), then physically walks to a report point (phone/manager) before
## anything escalates. Counterplay: clean the mess before they arrive,
## distract them with player noise (decoy/bark), or sabotage the phone.

signal witness_state_changed(state: String)
signal report_filed(report: Dictionary)

const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")
const SocialSignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")

const REPORT_POINT_GROUP := "witness_report_point"

@export var witness_id: StringName = &"witness"
@export var sight_radius: float = 140.0
## Seconds between spotting something and starting the report walk.
@export var notice_delay: float = 1.5
@export var move_speed: float = 90.0
@export var report_arrive_distance: float = 24.0
## Alert exposure added when a report is successfully filed.
@export var report_exposure: float = 0.45
## Player noise (decoy/bark/poop) inside its radius interrupts this witness.
@export var distraction_seconds: float = 4.0
@export var gossip_enabled: bool = true
@export var gossip_radius: float = 220.0
@export var scan_interval: float = 0.4
@export var report_target_path: NodePath

var state: String = "idle"
var reports_filed: int = 0
var gossip_received: bool = false
var last_report: Dictionary = {}

var _scan_timer := 0.0
var _notice_timer := 0.0
var _distract_timer := 0.0
var _witnessed_ref: WeakRef = null
var _report_target: Node2D = null
var _home_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("mission_witness")
	_home_position = global_position
	if not Engine.is_editor_hint() and EventBus.has_signal("mission_noise_emitted"):
		if not EventBus.mission_noise_emitted.is_connected(_on_noise_emitted):
			EventBus.mission_noise_emitted.connect(_on_noise_emitted)


func _exit_tree() -> void:
	if EventBus.has_signal("mission_noise_emitted") and EventBus.mission_noise_emitted.is_connected(_on_noise_emitted):
		EventBus.mission_noise_emitted.disconnect(_on_noise_emitted)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match state:
		"idle":
			_scan_timer -= delta
			if _scan_timer <= 0.0:
				_scan_timer = scan_interval
				_scan_for_mess()
		"noticing":
			if not _witnessed_still_there():
				_stand_down("nothing_there")
				return
			_notice_timer -= delta
			if _notice_timer <= 0.0:
				_begin_report()
		"reporting":
			if not _witnessed_still_there():
				_stand_down("evidence_gone")
				return
			_walk_to_report_target(delta)
		"distracted":
			_distract_timer -= delta
			if _distract_timer <= 0.0:
				_set_state("idle")
		"returning":
			global_position = global_position.move_toward(_home_position, move_speed * delta)
			if global_position.distance_to(_home_position) <= 4.0:
				_set_state("idle")
	queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		return
	var bubble := ""
	var color := Color.WHITE
	match state:
		"noticing":
			bubble = "?"
			color = Color(1.0, 0.85, 0.3)
		"reporting":
			bubble = "!"
			color = Color(1.0, 0.35, 0.3)
		"distracted":
			bubble = "..."
			color = Color(0.6, 0.8, 1.0)
	if bubble == "":
		return
	var pos := Vector2(0.0, -46.0)
	draw_circle(pos, 11.0, Color(0.08, 0.08, 0.1, 0.85))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-6.0, 6.0), bubble, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, color)


func receive_gossip() -> void:
	gossip_received = true


func force_notice(target: Node2D) -> void:
	_witnessed_ref = weakref(target)
	_notice_timer = notice_delay * (0.5 if gossip_received else 1.0)
	_set_state("noticing")


func get_witness_summary() -> Dictionary:
	return {
		"witness_id": String(witness_id),
		"state": state,
		"reports_filed": reports_filed,
		"gossip_received": gossip_received,
	}


func _scan_for_mess() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var nearest: Node2D = null
	var nearest_dist := sight_radius * (1.2 if gossip_received else 1.0)
	for node in tree.get_nodes_in_group("mission_mess"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var node2d := node as Node2D
		if not node2d.visible:
			continue
		var dist := global_position.distance_to(node2d.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node2d
	if nearest != null:
		force_notice(nearest)


func _witnessed_still_there() -> bool:
	if _witnessed_ref == null:
		return false
	var node: Variant = _witnessed_ref.get_ref()
	if node == null or not is_instance_valid(node):
		return false
	if node is CanvasItem and not (node as CanvasItem).visible:
		return false
	if node is Node and not (node as Node).is_in_group("mission_mess"):
		return false
	return true


func _begin_report() -> void:
	_report_target = _resolve_report_target()
	_set_state("reporting")
	EventBus.debug("Witness %s heading to report." % String(witness_id))


func _walk_to_report_target(delta: float) -> void:
	if _report_target == null or not is_instance_valid(_report_target):
		_file_report()
		return
	global_position = global_position.move_toward(_report_target.global_position, move_speed * delta)
	if global_position.distance_to(_report_target.global_position) <= report_arrive_distance:
		_file_report()


func _file_report() -> void:
	if _report_target != null and is_instance_valid(_report_target) and bool(_report_target.get_meta("sabotaged", false)):
		EventBus.objective_updated.emit("The phone is dead. The witness gives up, confused.")
		_stand_down("phone_sabotaged")
		return
	reports_filed += 1
	var mission_id := _current_mission_id()
	var event: Resource = SocialSignalEventScript.new()
	event.signal_id = StringName("%s_report_%d" % [String(witness_id), reports_filed])
	event.signal_type = SocialSignalEventScript.SIGNAL_EVIDENCE_SPOTTED
	event.source_id = witness_id
	event.mission_id = mission_id
	event.position = global_position
	ReactiveNpcBrainAdapterScript.record_signal(event, {"mission_id": mission_id})
	PaperTrailAdapterScript.record_trace(
		"%s_witness_trace_%d" % [String(witness_id), reports_filed],
		String(witness_id),
		"witness",
		2,
		false,
		"",
		{"mission_id": mission_id, "position": global_position}
	)
	var controller := _alert_controller()
	if controller != null and controller.has_method("accumulate_exposure") and report_exposure > 0.0:
		controller.call("accumulate_exposure", String(witness_id), report_exposure, "witness_report")
	last_report = {
		"witness_id": String(witness_id),
		"mission_id": mission_id,
		"signal_id": String(event.signal_id),
		"position": global_position,
	}
	report_filed.emit(last_report)
	EventBus.objective_updated.emit("A witness reported what they saw.")
	if gossip_enabled:
		_spread_gossip()
	_set_state("returning")


func _spread_gossip() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("mission_witness"):
		if node == self or not (node is Node2D) or not is_instance_valid(node):
			continue
		if bool(node.get("gossip_received")):
			continue
		if global_position.distance_to((node as Node2D).global_position) > gossip_radius:
			continue
		if node.has_method("receive_gossip"):
			node.call("receive_gossip")
			EventBus.debug("Witness %s gossiped to %s." % [String(witness_id), String(node.get("witness_id"))])
		break


func _stand_down(reason: String) -> void:
	_witnessed_ref = null
	EventBus.debug("Witness %s stood down (%s)." % [String(witness_id), reason])
	_set_state("returning")


func _on_noise_emitted(noise_event: Dictionary) -> void:
	if state != "noticing" and state != "reporting":
		return
	if String(noise_event.get("team", "")) != "player":
		return
	var kind := String(noise_event.get("kind", ""))
	if not kind in ["decoy", "bark", "poop_decoy"]:
		return
	if not NoiseEventHelper.is_point_in_range(noise_event, global_position):
		return
	_witnessed_ref = null
	_distract_timer = distraction_seconds
	_set_state("distracted")
	EventBus.debug("Witness %s distracted by %s." % [String(witness_id), kind])


func _resolve_report_target() -> Node2D:
	if report_target_path != NodePath():
		var explicit := get_node_or_null(report_target_path)
		if explicit is Node2D:
			return explicit as Node2D
	var tree := get_tree()
	if tree == null:
		return null
	var nearest: Node2D = null
	var nearest_dist := INF
	for node in tree.get_nodes_in_group(REPORT_POINT_GROUP):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var dist := global_position.distance_to((node as Node2D).global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node as Node2D
	return nearest


func _set_state(next_state: String) -> void:
	if state == next_state:
		return
	state = next_state
	witness_state_changed.emit(state)
	queue_redraw()


func _current_mission_id() -> String:
	return MissionFactBridge.resolve_mission_id({})


func _alert_controller() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("iso_alert_controller")
