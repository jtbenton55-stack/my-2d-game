@tool
class_name ItemData
extends Resource

const CATEGORY_KEY_ITEM := "key_item"
const CATEGORY_TOOL := "tool"
const CATEGORY_EVIDENCE := "evidence"
const CATEGORY_CONSUMABLE := "consumable"
const CATEGORY_CREDENTIAL := "credential"
const CATEGORY_CONTRABAND := "contraband"
const CATEGORY_FLAVOR := "flavor"
const CATEGORIES: Array[String] = [
	CATEGORY_KEY_ITEM,
	CATEGORY_TOOL,
	CATEGORY_EVIDENCE,
	CATEGORY_CONSUMABLE,
	CATEGORY_CREDENTIAL,
	CATEGORY_CONTRABAND,
	CATEGORY_FLAVOR,
]

@export var item_id: StringName = &"item"
@export var display_name: String = ""
@export_enum("key_item", "tool", "evidence", "consumable", "credential", "contraband", "flavor") var category: String = CATEGORY_KEY_ITEM
@export var stackable: bool = false
@export var max_stack: int = 1
@export var mission_only: bool = true
@export var suspicious: bool = false
@export var heat_value: int = 0
## Replan Packet 2: how bad this looks in a frisk/inspection (0 = innocent).
@export_range(0, 5) var incriminating: int = 0
## Replan Packet 2: bulky items slow the player and raise footstep noise.
@export var bulky: bool = false
@export var icon: Texture2D
@export_multiline var description: String = ""


static func is_known_category(value: String) -> bool:
	return CATEGORIES.has(value.strip_edges())


func get_item_id() -> String:
	return String(item_id).strip_edges()


func get_display_name() -> String:
	var text := display_name.strip_edges()
	return text if text != "" else _pretty_id(get_item_id())


func get_category() -> String:
	var text := category.strip_edges()
	return text if is_known_category(text) else CATEGORY_KEY_ITEM


func get_stack_limit() -> int:
	return maxi(1, max_stack) if stackable else 1


func is_valid_item() -> bool:
	return get_item_id() != "" and is_known_category(get_category())


func get_designer_summary() -> String:
	return "%s [%s] stack %d mission_only=%s" % [get_display_name(), get_category(), get_stack_limit(), str(mission_only)]


func _pretty_id(id: String) -> String:
	var parts := id.split("_")
	for i in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)
