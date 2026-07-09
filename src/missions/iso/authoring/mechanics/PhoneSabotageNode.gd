@tool
class_name PhoneSabotageNode
extends "res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd"

## Replan Packet 5: intercept counterplay. Sabotaging a phone/report point
## marks it dead -- witnesses that walk there to file a report give up.
## The act itself leaves an audit-style paper trace (severity configurable).

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")

@export_group("Sabotage")
## Node that witnesses walk to. Empty = this node doubles as the report point.
@export var sabotage_target_path: NodePath
@export var leaves_trace: bool = true
@export_range(0, 5) var trace_severity: int = 1

var sabotaged: bool = false


func _init() -> void:
	prompt_text = "Press E: Sabotage phone"
	locked_prompt_text = "Can't reach the wiring"
	preview_color = Color(0.8, 0.35, 0.5, 0.35)
	interact_duration = 1.5
	one_shot = true


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	if sabotage_target_path == NodePath():
		add_to_group("witness_report_point")


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result := super.activate(actor, reason)
	if not bool(result.get("ok", false)) or String(result.get("code", "")) != "activation_succeeded":
		return result
	_apply_sabotage(actor)
	return result


func _apply_sabotage(actor: Node) -> void:
	sabotaged = true
	var target := _resolve_target()
	if target != null:
		target.set_meta("sabotaged", true)
	if leaves_trace:
		PaperTrailAdapterScript.record_trace(
			"%s_sabotage" % String(mechanic_id),
			String(mechanic_id),
			"audit_log",
			trace_severity,
			true,
			"",
			build_context(actor)
		)
	EventBus.objective_updated.emit("Phone line dead. Reports won't go through here.")


func _resolve_target() -> Node:
	if sabotage_target_path == NodePath():
		return self
	return get_node_or_null(sabotage_target_path)
