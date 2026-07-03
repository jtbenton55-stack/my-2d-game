@tool
class_name Phase15ReactiveNpcProofHarness
extends Node

const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")

@export var status_label_path: NodePath = NodePath("StatusLabel")

@onready var _status_label: Label = get_node_or_null(status_label_path) as Label


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_connect_button("Run Ignored Signal", _run_ignored_signal)
	_connect_button("Run Investigation Reaction", _run_investigation_reaction)
	_connect_button("Run Authority Report", _run_authority_report)
	_connect_button("Run Routine Override", _run_routine_override)
	_set_status("Phase 15 reactive NPC proof ready. Reactions are bounded, fallback-driven, and LimboAI-absent safe.")


func _run_ignored_signal() -> void:
	_prepare()
	var node := get_node_or_null("../../MissionMechanics/InvestigationPointNode_phase15_ignore")
	var result: Dictionary = node.call("investigate", null, "proof") if node != null else {"ok": false, "code": "node_missing"}
	_set_status(_summary_line("ignored", result))


func _run_investigation_reaction() -> void:
	_prepare()
	var node := get_node_or_null("../../MissionMechanics/InvestigationPointNode_phase15_inspect")
	var result: Dictionary = node.call("investigate", null, "proof") if node != null else {"ok": false, "code": "node_missing"}
	_set_status(_summary_line("inspect", result))


func _run_authority_report() -> void:
	_prepare()
	var node := get_node_or_null("../../MissionMechanics/InvestigationPointNode_phase15_report")
	var result: Dictionary = node.call("investigate", null, "proof") if node != null else {"ok": false, "code": "node_missing"}
	_set_status(_summary_line("report", result))


func _run_routine_override() -> void:
	_prepare()
	var node := get_node_or_null("../../MissionMechanics/RoutineOverrideNode_phase15_route")
	var result: Dictionary = node.call("apply_override", null, "proof") if node != null else {"ok": false, "code": "node_missing"}
	_set_status(_summary_line("routine", result))


func _prepare() -> void:
	GameState.current_mission_id = "test_mission"
	GameState.is_in_mission = true
	ReactiveNpcBrainAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.reset_mission("test_mission")


func _summary_line(route_tag: String, result: Dictionary) -> String:
	var summary := ReactiveNpcBrainAdapterScript.get_summary("test_mission")
	return "Phase15 %s -> ok=%s code=%s state=%s signals=%d reactions=%d reports=%d limbo_used=%s" % [route_tag, str(result.get("ok", false)), String(result.get("code", "")), ReactiveNpcBrainAdapterScript.annotate_mission_result({"mission_id": "test_mission"}).get("reactive_npc_state", "quiet"), int(summary.get("signal_count", 0)), int(summary.get("reaction_count", 0)), int(summary.get("authority_reports", 0)), str(summary.get("limbo_adapter_used", false))]


func _connect_button(button_name: String, target: Callable) -> void:
	var button := find_child(button_name, true, false) as Button
	if button != null and not button.pressed.is_connected(target):
		button.pressed.connect(target)


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
