@tool
class_name ObjectSwapNode
extends MechanicAreaBase

signal object_swapped(swap_id: String, result: Dictionary)

const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")

@export_group("Object Swap")
@export var swap_id: StringName = &"object_swap"
@export var required_item_id: StringName = &""
@export var replacement_item_id: StringName = &""
@export var item_count: int = 1
@export var swapped_flag: StringName = &""

var swapped: bool = false
var last_swap_result: Dictionary = {}


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["swap_id"] = String(swap_id)
	context["required_item_id"] = String(required_item_id)
	context["replacement_item_id"] = String(replacement_item_id)
	context["item_count"] = maxi(1, item_count)
	context["swapped_flag"] = String(swapped_flag)
	context["swapped"] = swapped
	return context


func swap_object(actor: Node = null, reason: String = "interact") -> Dictionary:
	if not enabled:
		last_swap_result = _result(false, "mechanic_disabled", "Mechanic is disabled.", String(mechanic_id), {"reason": reason})
		return last_swap_result
	if one_shot and swapped:
		last_swap_result = _result(true, "already_swapped", "Object already swapped.", String(mechanic_id), {"reason": reason})
		return last_swap_result
	if actor != null and not can_actor_use(actor):
		last_swap_result = _result(false, "actor_not_allowed", "Actor cannot use this object swap.", String(mechanic_id), {"reason": reason, "actor": actor})
		return last_swap_result
	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_swap_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_swap_result)
		refresh_debug_label()
		return last_swap_result
	var remove_result := _remove_required_item()
	if not bool(remove_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_swap_result = _result(false, "swap_item_missing", String(remove_result.get("message", "Required swap item missing.")), String(mechanic_id), {"reason": reason, "remove_result": remove_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_swap_result)
		refresh_debug_label()
		return last_swap_result
	var grant_result := _grant_replacement_item()
	swapped = true
	var flag_result := _set_swapped_flag(context)
	last_effect_result = apply_success_effects(context)
	if one_shot:
		mark_used()
	last_swap_result = _result(true, "object_swapped", "Object swapped.", String(mechanic_id), {"reason": reason, "remove_result": remove_result, "grant_result": grant_result, "swapped_flag_result": flag_result, "effect_result": last_effect_result})
	activation_succeeded.emit(String(mechanic_id), last_swap_result)
	object_swapped.emit(String(swap_id), last_swap_result)
	refresh_debug_label()
	_notify_availability()
	return last_swap_result


func interact(actor: Node = null) -> bool:
	return bool(swap_object(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(swap_object(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(swap_object(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(swap_object(actor, "interact").get("ok", false))


func get_swap_summary() -> Dictionary:
	return {
		"swap_id": String(swap_id),
		"required_item_id": String(required_item_id),
		"replacement_item_id": String(replacement_item_id),
		"item_count": maxi(1, item_count),
		"swapped_flag": String(swapped_flag),
		"swapped": swapped,
		"last_swap_result": last_swap_result.duplicate(true),
	}


func _remove_required_item() -> Dictionary:
	var id := String(required_item_id).strip_edges()
	if id == "":
		return _result(false, "required_item_id_missing", "ObjectSwapNode requires required_item_id.", String(mechanic_id))
	return MissionInventoryScript.remove_item(id, maxi(1, item_count))


func _grant_replacement_item() -> Dictionary:
	var id := String(replacement_item_id).strip_edges()
	if id == "":
		return _result(true, "no_replacement_item", "No replacement_item_id configured.")
	return MissionInventoryScript.add_item(id, maxi(1, item_count), {"item_id": id, "source": String(swap_id)})


func _set_swapped_flag(context: Dictionary) -> Dictionary:
	if swapped_flag == &"":
		return _result(true, "no_swapped_flag", "No swapped_flag configured.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(swapped_flag), true, context)


func _debug_label_text() -> String:
	return "SWAPPED" if swapped else "SWAP"
