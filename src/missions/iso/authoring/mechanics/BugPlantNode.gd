@tool
class_name BugPlantNode
extends MechanicAreaBase

signal bug_planted(bug_id: String, result: Dictionary)

const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")

@export_group("Bug Plant")
@export var bug_id: StringName = &"bug_plant"
@export var bug_item_id: StringName = &"listening_bug"
@export var consume_bug_item: bool = true
@export var planted_flag: StringName = &""

var planted: bool = false
var last_bug_result: Dictionary = {}


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["bug_id"] = String(bug_id)
	context["bug_item_id"] = String(bug_item_id)
	context["consume_bug_item"] = consume_bug_item
	context["planted_flag"] = String(planted_flag)
	context["planted"] = planted
	return context


func plant_bug(actor: Node = null, reason: String = "interact") -> Dictionary:
	if not enabled:
		last_bug_result = _result(false, "mechanic_disabled", "Mechanic is disabled.", String(mechanic_id), {"reason": reason})
		return last_bug_result
	if one_shot and planted:
		last_bug_result = _result(true, "already_planted", "Bug already planted.", String(mechanic_id), {"reason": reason})
		return last_bug_result
	if actor != null and not can_actor_use(actor):
		last_bug_result = _result(false, "actor_not_allowed", "Actor cannot plant this bug.", String(mechanic_id), {"reason": reason, "actor": actor})
		return last_bug_result
	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_bug_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_bug_result)
		refresh_debug_label()
		return last_bug_result
	var item_result := _consume_bug_if_needed()
	if not bool(item_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_bug_result = _result(false, "bug_item_missing", String(item_result.get("message", "Bug item missing.")), String(mechanic_id), {"reason": reason, "item_result": item_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_bug_result)
		refresh_debug_label()
		return last_bug_result
	planted = true
	var flag_result := _set_planted_flag(context)
	last_effect_result = apply_success_effects(context)
	if one_shot:
		mark_used()
	last_bug_result = _result(true, "bug_planted", "Bug planted.", String(mechanic_id), {"reason": reason, "item_result": item_result, "planted_flag_result": flag_result, "effect_result": last_effect_result})
	activation_succeeded.emit(String(mechanic_id), last_bug_result)
	bug_planted.emit(String(bug_id), last_bug_result)
	refresh_debug_label()
	_notify_availability()
	return last_bug_result


func interact(actor: Node = null) -> bool:
	return bool(plant_bug(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(plant_bug(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(plant_bug(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(plant_bug(actor, "interact").get("ok", false))


func get_bug_summary() -> Dictionary:
	return {
		"bug_id": String(bug_id),
		"bug_item_id": String(bug_item_id),
		"consume_bug_item": consume_bug_item,
		"planted_flag": String(planted_flag),
		"planted": planted,
		"last_bug_result": last_bug_result.duplicate(true),
	}


func _consume_bug_if_needed() -> Dictionary:
	if not consume_bug_item:
		return _result(true, "bug_item_not_consumed", "Bug item consumption disabled.")
	var id := String(bug_item_id).strip_edges()
	if id == "":
		return _result(false, "bug_item_id_missing", "BugPlantNode requires bug_item_id when consume_bug_item is enabled.", String(mechanic_id))
	return MissionInventoryScript.remove_item(id, 1)


func _set_planted_flag(context: Dictionary) -> Dictionary:
	if planted_flag == &"":
		return _result(true, "no_planted_flag", "No planted_flag configured.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(planted_flag), true, context)


func _debug_label_text() -> String:
	return "BUGGED" if planted else "BUG PLANT"
