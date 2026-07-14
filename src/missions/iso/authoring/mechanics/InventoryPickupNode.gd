@tool
class_name InventoryPickupNode
extends RewardNode

const ItemDataScript := preload("res://src/inventory/items/ItemData.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const MissionEffectApplierScript := preload("res://src/missions/iso/authoring/core/MissionEffectApplier.gd")

@export_group("Inventory Pickup")
@export var item_data: Resource
@export var item_id: StringName = &""
@export var item_count: int = 1
@export_enum("key_item", "tool", "evidence", "consumable", "credential", "contraband", "flavor") var item_category: String = "key_item"
@export var item_stackable: bool = true
@export var item_max_stack: int = 99
@export var item_mission_only: bool = true
@export var grant_item_on_collect: bool = true

var last_item_grant_result: Dictionary = {}


func _ready() -> void:
	reward_kind = "item"
	if reward_id == &"" and get_item_id() != "":
		reward_id = StringName(get_item_id())
	super._ready()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["item_id"] = get_item_id()
	context["item_count"] = get_item_count()
	context["item_category"] = get_item_category()
	return context


func collect(actor: Node = null, reason: String = "interact") -> Dictionary:
	last_item_grant_result = {}
	if grant_item_on_collect and get_item_id() == "":
		last_collect_result = _collect_result(false, "item_id_missing", "Inventory pickup is missing item_id.", {"reason": reason})
		return last_collect_result
	var result: Dictionary = super.collect(actor, reason)
	if grant_item_on_collect and bool(result.get("ok", false)) and String(result.get("code", "")) == "reward_collected":
		last_item_grant_result = _apply_item_grant(actor)
		result = _merge_collect_details(result, {"item_grant_result": last_item_grant_result})
		if not bool(last_item_grant_result.get("ok", false)):
			result["ok"] = false
			result["code"] = "item_grant_failed"
			result["message"] = String(last_item_grant_result.get("message", "Item grant failed."))
		last_collect_result = result
		refresh_debug_label()
	return result


func get_item_id() -> String:
	if _is_item_data(item_data) and String(item_data.call("get_item_id")) != "":
		return String(item_data.call("get_item_id"))
	return String(item_id).strip_edges()


func get_item_count() -> int:
	return maxi(1, item_count)


func get_item_category() -> String:
	if _is_item_data(item_data):
		return String(item_data.call("get_category"))
	return item_category.strip_edges() if item_category.strip_edges() != "" else "key_item"


func get_inventory_summary() -> Dictionary:
	return {
		"item_id": get_item_id(),
		"item_count": get_item_count(),
		"item_category": get_item_category(),
		"mission_only": _mission_only_value(),
		"grant_item_on_collect": grant_item_on_collect,
		"last_item_grant_result": last_item_grant_result,
	}


func _apply_item_grant(actor: Node) -> Dictionary:
	var effect := MissionEffectScript.new()
	effect.effect_id = StringName("grant_item_%s" % get_item_id())
	effect.effect_type = MissionEffectScript.EffectType.GRANT_ITEM
	effect.key = get_item_id()
	effect.value_type = "int"
	effect.value_int = get_item_count()
	effect.payload = _item_payload()
	return MissionEffectApplierScript.apply_effect(effect, build_context(actor))


func _item_payload() -> Dictionary:
	if _is_item_data(item_data):
		return {
			"item_id": get_item_id(),
			"display_name": String(item_data.call("get_display_name")),
			"category": String(item_data.call("get_category")),
			"stackable": bool(item_data.get("stackable")),
			"max_stack": int(item_data.call("get_stack_limit")),
			"mission_only": bool(item_data.get("mission_only")),
		}
	return {
		"item_id": get_item_id(),
		"display_name": display_name if display_name.strip_edges() != "" else get_item_id().capitalize(),
		"category": get_item_category(),
		"stackable": item_stackable,
		"max_stack": maxi(1, item_max_stack),
		"mission_only": item_mission_only,
	}


func _mission_only_value() -> bool:
	return bool(item_data.get("mission_only")) if _is_item_data(item_data) else item_mission_only


func _is_item_data(value: Variant) -> bool:
	return value is Resource and (value as Resource).get_script() == ItemDataScript
