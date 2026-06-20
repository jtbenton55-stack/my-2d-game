# GdUnit4 smoke tests for Phase 5A-5C-lite mission inventory.
extends GdUnitTestSuite

const ItemDataScript := preload("res://src/inventory/items/ItemData.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")


func test_item_data_exposes_item_vocabulary() -> void:
	var item := ItemDataScript.new()
	item.item_id = &"delivery_badge"
	item.category = "credential"
	item.stackable = true
	item.max_stack = 3
	item.mission_only = true

	assert_str(item.get_item_id()).is_equal("delivery_badge")
	assert_str(item.get_category()).is_equal("credential")
	assert_int(item.get_stack_limit()).is_equal(3)
	assert_bool(item.is_valid_item()).is_true()


func test_mission_inventory_add_remove_count_category_and_clear() -> void:
	MissionInventoryScript.clear_all()
	var item := ItemDataScript.new()
	item.item_id = &"glass_cutter"
	item.category = "tool"
	item.stackable = true
	item.max_stack = 2

	var added: Dictionary = MissionInventoryScript.add_item(item, 3)
	assert_bool(added.get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("glass_cutter")).is_equal(2)
	assert_bool(MissionInventoryScript.has_item("glass_cutter", 2)).is_true()
	assert_bool(MissionInventoryScript.has_category("tool")).is_true()

	var removed: Dictionary = MissionInventoryScript.remove_item("glass_cutter", 1)
	assert_bool(removed.get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("glass_cutter")).is_equal(1)

	var cleared: Dictionary = MissionInventoryScript.clear_mission_items()
	assert_bool(cleared.get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("glass_cutter")).is_equal(0)


func test_inventory_requirements_read_mission_inventory() -> void:
	MissionInventoryScript.clear_all()
	MissionInventoryScript.add_item("delivery_badge", 2, {"category": "credential", "stackable": true, "max_stack": 4})

	var has_item := MissionRequirementScript.new()
	has_item.fact_type = &"inventory_has_item"
	has_item.key = "delivery_badge"
	has_item.operator = MissionRequirementScript.Operator.EXISTS
	has_item.expected_value_type = "exists"

	var item_count := MissionRequirementScript.new()
	item_count.fact_type = &"inventory_item_count"
	item_count.key = "delivery_badge"
	item_count.operator = MissionRequirementScript.Operator.GREATER_OR_EQUAL
	item_count.expected_value_type = "int"
	item_count.expected_int = 2

	var has_category := MissionRequirementScript.new()
	has_category.fact_type = &"inventory_has_category"
	has_category.key = "credential"
	has_category.operator = MissionRequirementScript.Operator.EQUALS
	has_category.expected_value_type = "bool"
	has_category.expected_bool = true

	var set := RequirementSetScript.new()
	set.requirements = [has_item, item_count, has_category]

	var result: Dictionary = set.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()

	MissionInventoryScript.clear_all()


func test_inventory_effects_grant_remove_and_clear_items() -> void:
	MissionInventoryScript.clear_all()

	var grant := MissionEffectScript.new()
	grant.effect_type = MissionEffectScript.EffectType.GRANT_ITEM
	grant.key = "vault_key"
	grant.value_type = "int"
	grant.value_int = 2
	grant.payload = {"category": "key_item", "stackable": true, "max_stack": 5}

	var remove := MissionEffectScript.new()
	remove.effect_type = MissionEffectScript.EffectType.REMOVE_ITEM
	remove.key = "vault_key"
	remove.value_type = "int"
	remove.value_int = 1

	var grant_set := EffectSetScript.new()
	grant_set.effects = [grant]
	assert_bool(grant_set.apply_all({"mission_id": "taco_bell_drop"}).get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("vault_key")).is_equal(2)

	var remove_set := EffectSetScript.new()
	remove_set.effects = [remove]
	assert_bool(remove_set.apply_all({"mission_id": "taco_bell_drop"}).get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("vault_key")).is_equal(1)

	var clear := MissionEffectScript.new()
	clear.effect_type = MissionEffectScript.EffectType.CLEAR_MISSION_ITEMS

	var clear_set := EffectSetScript.new()
	clear_set.effects = [clear]
	assert_bool(clear_set.apply_all({"mission_id": "taco_bell_drop"}).get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("vault_key")).is_equal(0)


func test_mission_inventory_does_not_persist_and_clears_on_mission_lifecycle() -> void:
	var previous_save := GameState.to_dict().duplicate(true)
	var previous_current := GameState.current_mission_id
	var previous_in_mission := GameState.is_in_mission
	MissionInventoryScript.clear_all()
	MissionInventoryScript.add_item("route_manifest", 1)

	var save_data := GameState.to_dict()
	assert_bool(save_data.has("mission_inventory")).is_false()
	assert_bool(save_data.has("mission_items")).is_false()

	GameState.start_mission("taco_bell_drop")
	assert_int(MissionInventoryScript.get_item_count("route_manifest")).is_equal(0)

	MissionInventoryScript.add_item("route_manifest", 1)
	GameState.complete_mission("taco_bell_drop")
	assert_int(MissionInventoryScript.get_item_count("route_manifest")).is_equal(0)

	GameState.from_dict(previous_save)
	GameState.current_mission_id = previous_current
	GameState.is_in_mission = previous_in_mission
	MissionInventoryScript.clear_all()
