@tool
class_name TerminalHackNode
extends "res://src/missions/iso/authoring/mechanics/LockedInteractionNode.gd"

signal hack_completed(terminal_id: String, result: Dictionary)

@export_group("Terminal Hack")
@export var terminal_id: StringName = &"terminal_hack"
@export var hack_completed_flag: StringName = &""
@export var hack_prompt_text: String = "Press E: Hack terminal"
@export var hacked_prompt_text: String = "Terminal hacked"

var last_hack_result: Dictionary = {}


func _ready() -> void:
	lock_kind = "terminal"
	if prompt_text.strip_edges() == "" or prompt_text == "Press E: Unlock":
		prompt_text = hack_prompt_text
	if unlocked_prompt_text.strip_edges() == "" or unlocked_prompt_text == "Unlocked":
		unlocked_prompt_text = hacked_prompt_text
	if unlocked_flag == &"" and hack_completed_flag != &"":
		unlocked_flag = hack_completed_flag
	elif hack_completed_flag == &"" and unlocked_flag != &"":
		hack_completed_flag = unlocked_flag
	super._ready()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["terminal_id"] = String(terminal_id)
	context["hack_completed_flag"] = String(_resolved_hack_completed_flag())
	context["hack_completed"] = unlocked
	return context


func hack(actor: Node = null, reason: String = "hack") -> Dictionary:
	var result := unlock(actor, reason)
	last_hack_result = result
	if bool(result.get("ok", false)):
		hack_completed.emit(String(terminal_id), result)
	return result


func interact(actor: Node = null) -> bool:
	return bool(hack(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(hack(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(hack(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(hack(actor, "interact").get("ok", false))


func set_unlocked_flag(context: Dictionary) -> Dictionary:
	var flag := _resolved_hack_completed_flag()
	if flag == &"":
		return _result(true, "no_hack_completed_flag", "No hack_completed_flag configured.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Hack completed flag skipped in editor.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(flag), true, context)


func get_hack_summary() -> Dictionary:
	return {
		"terminal_id": String(terminal_id),
		"hack_completed_flag": String(_resolved_hack_completed_flag()),
		"hacked": unlocked,
		"last_hack_result": last_hack_result.duplicate(true),
	}


func _resolved_hack_completed_flag() -> StringName:
	if hack_completed_flag != &"":
		return hack_completed_flag
	return unlocked_flag
