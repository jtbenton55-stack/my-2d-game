@tool
class_name InventoryEntry
extends Resource

const ItemDataScript := preload("res://src/inventory/items/ItemData.gd")

@export var item_data: Resource
@export var item_id: StringName = &""
@export var count: int = 0
@export_enum("key_item", "tool", "evidence", "consumable", "credential", "contraband", "flavor") var category: String = "key_item"
@export var stackable: bool = true
@export var max_stack: int = 99
@export var mission_only: bool = true
@export_range(0, 5) var incriminating: int = 0
@export var bulky: bool = false


func configure_from_item(item: Resource, fallback_data: Dictionary = {}) -> void:
	item_data = item
	if item_data != null:
		item_id = StringName(item_data.call("get_item_id"))
		category = String(item_data.call("get_category"))
		stackable = bool(item_data.get("stackable"))
		max_stack = int(item_data.call("get_stack_limit"))
		mission_only = bool(item_data.get("mission_only"))
		if item_data.get("incriminating") != null:
			incriminating = int(item_data.get("incriminating"))
		if item_data.get("bulky") != null:
			bulky = bool(item_data.get("bulky"))
	for key in fallback_data.keys():
		match String(key):
			"category":
				category = String(fallback_data[key])
			"stackable":
				stackable = bool(fallback_data[key])
			"max_stack":
				max_stack = maxi(1, int(fallback_data[key]))
			"mission_only":
				mission_only = bool(fallback_data[key])
			"incriminating":
				incriminating = clampi(int(fallback_data[key]), 0, 5)
			"bulky":
				bulky = bool(fallback_data[key])


func get_item_id() -> String:
	if item_data != null and String(item_data.call("get_item_id")) != "":
		return String(item_data.call("get_item_id"))
	return String(item_id).strip_edges()


func get_category() -> String:
	if item_data != null:
		return String(item_data.call("get_category"))
	var text := category.strip_edges()
	return text if ItemDataScript.is_known_category(text) else "key_item"


func get_stack_limit() -> int:
	if item_data != null:
		return int(item_data.call("get_stack_limit"))
	return maxi(1, max_stack) if stackable else 1


func add_count(amount: int) -> int:
	var before := count
	var limit := get_stack_limit()
	count = clampi(count + maxi(0, amount), 0, limit)
	return count - before


func remove_count(amount: int) -> int:
	var before := count
	count = maxi(0, count - maxi(0, amount))
	return before - count


func is_empty() -> bool:
	return count <= 0


func to_summary() -> Dictionary:
	return {
		"item_id": get_item_id(),
		"count": count,
		"category": get_category(),
		"mission_only": mission_only,
		"stackable": stackable,
		"max_stack": get_stack_limit(),
		"incriminating": incriminating,
		"bulky": bulky,
	}
