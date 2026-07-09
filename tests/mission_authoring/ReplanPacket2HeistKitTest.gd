# GdUnit4 tests for Replan Packet 2: heist kit fields (incriminating/bulky),
# frisk pocket checks, footstep noise tiers, and the decoy throw verb.
extends GdUnitTestSuite

const ItemDataScript := preload("res://src/inventory/items/ItemData.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")
const InspectionRuleSetScript := preload("res://src/missions/iso/social/InspectionRuleSet.gd")
const PlayerFootstepNoiseEmitterScript := preload("res://src/missions/iso/runtime/kit/PlayerFootstepNoiseEmitter.gd")
const KitDecoyThrowerScript := preload("res://src/missions/iso/runtime/kit/KitDecoyThrower.gd")
const HeistKitHudScript := preload("res://src/missions/iso/runtime/kit/HeistKitHud.gd")
const MissionPlayerKitLayerScript := preload("res://src/missions/iso/runtime/kit/MissionPlayerKitLayer.gd")


func before_test() -> void:
	MissionInventoryScript.clear_all()


func after_test() -> void:
	MissionInventoryScript.clear_all()


func test_item_data_incriminating_and_bulky_flow_into_inventory() -> void:
	var crowbar: Resource = ItemDataScript.new()
	crowbar.item_id = &"test_crowbar"
	crowbar.category = "tool"
	crowbar.incriminating = 3
	crowbar.bulky = true
	MissionInventoryScript.add_item(crowbar)

	assert_int(MissionInventoryScript.get_incriminating_total()).is_equal(3)
	assert_bool(MissionInventoryScript.has_bulky_item()).is_true()
	var snapshot := MissionInventoryScript.get_snapshot()
	var summary: Dictionary = (snapshot.get("items", {}) as Dictionary).get("test_crowbar", {})
	assert_int(int(summary.get("incriminating", 0))).is_equal(3)
	assert_bool(bool(summary.get("bulky", false))).is_true()


func test_incriminating_total_scales_with_count() -> void:
	MissionInventoryScript.add_item("test_lockpick", 2, {"incriminating": 1, "stackable": true, "max_stack": 5})
	assert_int(MissionInventoryScript.get_incriminating_total()).is_equal(2)
	assert_bool(MissionInventoryScript.has_bulky_item()).is_false()


func test_inspection_frisk_fails_on_incriminating_gear() -> void:
	MissionInventoryScript.add_item("test_crowbar_frisk", 1, {"incriminating": 3})
	var rules: Resource = InspectionRuleSetScript.new()
	rules.max_incriminating = 1
	var result: Dictionary = rules.evaluate({"mission_id": "test_mission"})
	assert_bool(result.get("ok", true)).is_false()
	var details: Dictionary = result.get("details", {})
	assert_int(int(details.get("carried_incriminating", 0))).is_equal(3)

	MissionInventoryScript.remove_item("test_crowbar_frisk", 1)
	var clean_result: Dictionary = rules.evaluate({"mission_id": "test_mission"})
	assert_bool(clean_result.get("ok", false)).is_true()


func test_inspection_frisk_disabled_by_default() -> void:
	MissionInventoryScript.add_item("test_crowbar_ignored", 1, {"incriminating": 5})
	var rules: Resource = InspectionRuleSetScript.new()
	var result: Dictionary = rules.evaluate({"mission_id": "test_mission"})
	assert_bool(result.get("ok", false)).is_true()


func test_footstep_emitter_tiers_and_bulky_radius() -> void:
	var emitter: Node = PlayerFootstepNoiseEmitterScript.new()
	add_child(emitter)
	var player := CharacterBody2D.new()
	player.name = "Packet2FootstepPlayer"
	player.add_to_group("player")
	player.set("velocity", Vector2(400.0, 0.0))
	add_child(player)

	var captured: Array = []
	var handler := func(noise_event: Dictionary) -> void:
		captured.append(noise_event)
	EventBus.mission_noise_emitted.connect(handler)

	emitter._emit_footstep(player, "run")
	assert_int(captured.size()).is_equal(1)
	var event: Dictionary = captured[0]
	assert_str(String(event.get("kind", ""))).is_equal("footstep")
	assert_str(String(event.get("team", ""))).is_equal("player")
	var base_radius := float(event.get("radius", 0.0))
	assert_float(base_radius).is_equal(190.0)

	MissionInventoryScript.add_item("test_cash_bag", 1, {"bulky": true})
	emitter._emit_footstep(player, "run")
	var bulky_event: Dictionary = captured[1]
	assert_float(float(bulky_event.get("radius", 0.0))).is_greater(base_radius)

	EventBus.mission_noise_emitted.disconnect(handler)
	_free_node(player)
	_free_node(emitter)


func test_decoy_throw_consumes_item_and_emits_decoy_noise() -> void:
	var thrower: Node = KitDecoyThrowerScript.new()
	add_child(thrower)
	var player := Node2D.new()
	player.name = "Packet2ThrowPlayer"
	player.add_to_group("player")
	add_child(player)
	player.global_position = Vector2.ZERO

	var missing: Dictionary = thrower.try_throw_decoy(Vector2(100, 0))
	assert_bool(missing.get("ok", true)).is_false()
	assert_str(String(missing.get("code", ""))).is_equal("no_decoy_item")

	MissionInventoryScript.add_item("decoy_coin", 1)
	var captured: Array = []
	var handler := func(noise_event: Dictionary) -> void:
		captured.append(noise_event)
	EventBus.mission_noise_emitted.connect(handler)

	var thrown: Dictionary = thrower.try_throw_decoy(Vector2(100, 0))
	assert_bool(thrown.get("ok", false)).is_true()
	assert_bool(MissionInventoryScript.has_item("decoy_coin")).is_false()
	assert_int(captured.size()).is_equal(1)
	assert_str(String(captured[0].get("kind", ""))).is_equal("decoy")

	var far: Dictionary = thrower.try_throw_decoy(Vector2(9999, 0))
	assert_str(String(far.get("code", ""))).is_equal("no_decoy_item")

	EventBus.mission_noise_emitted.disconnect(handler)
	_free_node(player)
	_free_node(thrower)


func test_decoy_throw_clamps_to_range() -> void:
	var thrower: Node = KitDecoyThrowerScript.new()
	thrower.throw_range = 100.0
	add_child(thrower)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	player.global_position = Vector2.ZERO
	MissionInventoryScript.add_item("decoy_coin", 1)

	var thrown: Dictionary = thrower.try_throw_decoy(Vector2(500, 0))
	assert_bool(thrown.get("ok", false)).is_true()
	var event: Dictionary = (thrown.get("details", {}) as Dictionary).get("noise_event", {})
	var landing: Vector2 = event.get("position", Vector2.ZERO)
	assert_float(landing.distance_to(Vector2.ZERO)).is_less_equal(100.5)
	_free_node(player)
	_free_node(thrower)


func test_heist_kit_hud_splits_loadout_and_mission_slots() -> void:
	MissionInventoryScript.add_item("loadout_wipes", 1, {"mission_only": false})
	MissionInventoryScript.add_item("mission_badge", 1, {"mission_only": true})
	var hud: CanvasLayer = HeistKitHudScript.new()
	add_child(hud)
	var kit: Dictionary = hud.get_kit_summary()
	var loadout: Array = kit.get("loadout", [])
	var mission: Array = kit.get("mission", [])
	assert_int(loadout.size()).is_equal(1)
	assert_int(mission.size()).is_equal(1)
	assert_str(String((loadout[0] as Dictionary).get("item_id", ""))).is_equal("loadout_wipes")
	assert_str(String((mission[0] as Dictionary).get("item_id", ""))).is_equal("mission_badge")
	_free_node(hud)


func test_kit_layer_composes_all_pieces() -> void:
	var layer: Node = MissionPlayerKitLayerScript.new()
	add_child(layer)
	var summary: Dictionary = layer.get_kit_layer_summary()
	assert_bool(bool(summary.get("kit_hud", false))).is_true()
	assert_bool(bool(summary.get("footstep_emitter", false))).is_true()
	assert_bool(bool(summary.get("decoy_thrower", false))).is_true()
	assert_bool(layer.is_in_group("mission_player_kit_layer")).is_true()
	_free_node(layer)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
