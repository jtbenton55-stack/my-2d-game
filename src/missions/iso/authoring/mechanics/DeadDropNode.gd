@tool
class_name DeadDropNode
extends InteractiveContainer

signal dead_drop_completed(drop_id: String, result: Dictionary)

const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")

@export_group("Dead Drop")
@export var drop_id: StringName = &"dead_drop"
@export_enum("deposit", "retrieve") var drop_mode: String = "deposit"
@export var item_id: StringName = &""
@export var item_count: int = 1
@export var completed_flag: StringName = &""

var completed: bool = false
var last_dead_drop_result: Dictionary = {}


func _ready() -> void:
	container_kind = "stash"
	if prompt_text.strip_edges() == "" or prompt_text == "Press E: Open":
		prompt_text = "Press E: Use dead drop"
	super._ready()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["drop_id"] = String(drop_id)
	context["drop_mode"] = drop_mode
	context["item_id"] = String(item_id)
	context["item_count"] = maxi(1, item_count)
	context["completed_flag"] = String(completed_flag)
	context["completed"] = completed
	return context


func use_dead_drop(actor: Node = null, reason: String = "interact") -> Dictionary:
	if not enabled:
		last_dead_drop_result = _result(false, "mechanic_disabled", "Mechanic is disabled.", String(mechanic_id), {"reason": reason})
		return last_dead_drop_result
	if one_shot and completed:
		last_dead_drop_result = _result(true, "already_completed", "Dead drop already completed.", String(mechanic_id), {"reason": reason})
		return last_dead_drop_result
	if actor != null and not can_actor_use(actor):
		last_dead_drop_result = _result(false, "actor_not_allowed", "Actor cannot use this dead drop.", String(mechanic_id), {"reason": reason, "actor": actor})
		return last_dead_drop_result
	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_dead_drop_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_dead_drop_result)
		refresh_debug_label()
		return last_dead_drop_result
	var inventory_result := _apply_inventory_step()
	if not bool(inventory_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_dead_drop_result = _result(false, "dead_drop_inventory_failed", String(inventory_result.get("message", "Dead drop inventory step failed.")), String(mechanic_id), {"reason": reason, "inventory_result": inventory_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_dead_drop_result)
		refresh_debug_label()
		return last_dead_drop_result
	completed = true
	searched = true
	opened = true
	var flag_result := _set_completed_flag(context)
	var target_result := apply_container_open_targets()
	last_effect_result = apply_success_effects(context)
	if one_shot:
		mark_used()
	last_dead_drop_result = _result(true, "dead_drop_completed", "Dead drop completed.", String(mechanic_id), {"reason": reason, "inventory_result": inventory_result, "completed_flag_result": flag_result, "target_result": target_result, "effect_result": last_effect_result})
	activation_succeeded.emit(String(mechanic_id), last_dead_drop_result)
	dead_drop_completed.emit(String(drop_id), last_dead_drop_result)
	refresh_debug_label()
	_notify_availability()
	return last_dead_drop_result


func open_container(actor: Node = null, reason: String = "interact") -> Dictionary:
	return use_dead_drop(actor, reason)


func interact(actor: Node = null) -> bool:
	return bool(use_dead_drop(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(use_dead_drop(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(use_dead_drop(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(use_dead_drop(actor, "interact").get("ok", false))


func get_dead_drop_summary() -> Dictionary:
	return {
		"drop_id": String(drop_id),
		"drop_mode": drop_mode,
		"item_id": String(item_id),
		"item_count": maxi(1, item_count),
		"completed_flag": String(completed_flag),
		"completed": completed,
		"last_dead_drop_result": last_dead_drop_result.duplicate(true),
	}


func _apply_inventory_step() -> Dictionary:
	var id := String(item_id).strip_edges()
	if id == "":
		return _result(false, "item_id_missing", "DeadDropNode requires item_id.", String(mechanic_id))
	if drop_mode == "retrieve":
		return MissionInventoryScript.add_item(id, maxi(1, item_count), {"item_id": id, "source": String(drop_id)})
	return MissionInventoryScript.remove_item(id, maxi(1, item_count))


func _set_completed_flag(context: Dictionary) -> Dictionary:
	if completed_flag == &"":
		return _result(true, "no_completed_flag", "No completed_flag configured.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(completed_flag), true, context)


func _debug_label_text() -> String:
	return "DROP DONE" if completed else "DEAD DROP"
