class_name MissionFactBridge
extends RefCounted

const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")

const FACT_ALWAYS := &"always"
const FACT_MISSION_ID := &"mission_id"
const FACT_MISSION_COMPLETED := &"mission_completed"
const FACT_SELECTED_CARD := &"selected_card"
const FACT_UNLOCKED_CARD := &"unlocked_card"
const FACT_SCHEME_EFFECT := &"scheme_effect"
const FACT_TYPED_COLLECTIBLE := &"typed_collectible"
const FACT_TYPED_COLLECTIBLE_TYPE_COUNT := &"typed_collectible_type_count"
const FACT_EVIDENCE_CLUE := &"evidence_clue"
const FACT_CREW_ASSIST := &"crew_assist"
const FACT_OBJECTIVE_ACTIVE := &"objective_active"
const FACT_OBJECTIVE_COMPLETED := &"objective_completed"
const FACT_ALERT_STATE := &"alert_state"
const FACT_DIALOGUE_FLAG := &"dialogue_flag"
const FACT_MISSION_FLAG := &"mission_flag"
const FACT_POOP_BAG_COUNT := &"poop_bag_count"
const FACT_INVENTORY_HAS_ITEM := &"inventory_has_item"
const FACT_INVENTORY_ITEM_COUNT := &"inventory_item_count"
const FACT_INVENTORY_HAS_CATEGORY := &"inventory_has_category"


static func resolve_mission_id(context: Dictionary = {}) -> String:
	var explicit := String(context.get("mission_id", "")).strip_edges()
	if explicit != "":
		return explicit
	var game_state := _autoload("GameState")
	if game_state != null:
		var current := String(game_state.get("current_mission_id")).strip_edges()
		if current != "":
			return current
		var pending := String(game_state.get("pending_mission_id")).strip_edges()
		if pending != "":
			return pending
	return ""


static func evaluate_fact(fact_type: StringName, key: String, expected: Variant = true, context: Dictionary = {}) -> Dictionary:
	if not is_known_fact_type(fact_type):
		return _result(false, "unknown_fact_type", "Unknown fact type: %s." % String(fact_type), String(key), {"fact_type": String(fact_type)})
	var actual: Variant = get_fact_value(fact_type, key, context)
	var ok := _values_equal(actual, expected)
	return _result(
		ok,
		"fact_matched" if ok else "fact_mismatch",
		"Fact %s %s expected %s, got %s." % [String(fact_type), key, str(expected), str(actual)],
		String(key),
		{"fact_type": String(fact_type), "key": key, "expected": expected, "actual": actual}
	)


static func get_fact_value(fact_type: StringName, key: String, context: Dictionary = {}) -> Variant:
	var game_state := _autoload("GameState")
	var quest_manager := _autoload("QuestManager")
	match fact_type:
		FACT_ALWAYS:
			return true
		FACT_MISSION_ID:
			return resolve_mission_id(context)
		FACT_MISSION_COMPLETED:
			return game_state != null and game_state.has_method("has_completed") and bool(game_state.call("has_completed", key))
		FACT_SELECTED_CARD:
			return game_state != null and game_state.has_method("has_selected_card") and bool(game_state.call("has_selected_card", key))
		FACT_UNLOCKED_CARD:
			return _has_unlocked_card(game_state, key)
		FACT_SCHEME_EFFECT:
			return _has_scheme_effect(key, context)
		FACT_TYPED_COLLECTIBLE:
			return _typed_collectibles(game_state).has(key)
		FACT_TYPED_COLLECTIBLE_TYPE_COUNT:
			return _typed_collectible_type_count(game_state, key)
		FACT_EVIDENCE_CLUE:
			return game_state != null and game_state.has_method("has_evidence_clue") and bool(game_state.call("has_evidence_clue", key))
		FACT_CREW_ASSIST:
			return game_state != null and game_state.has_method("has_crew_assist") and bool(game_state.call("has_crew_assist", key))
		FACT_OBJECTIVE_ACTIVE:
			return _is_objective_active(quest_manager, key, resolve_mission_id(context))
		FACT_OBJECTIVE_COMPLETED:
			return quest_manager != null and quest_manager.has_method("is_objective_completed") and bool(quest_manager.call("is_objective_completed", key, resolve_mission_id(context)))
		FACT_ALERT_STATE:
			var mid := key.strip_edges()
			if mid == "":
				mid = resolve_mission_id(context)
			return game_state.call("get_mission_alert_state", mid) if game_state != null and game_state.has_method("get_mission_alert_state") else "normal"
		FACT_DIALOGUE_FLAG:
			return _dialogue_flags(game_state).get(key, false)
		FACT_MISSION_FLAG:
			return _dialogue_flags(game_state).get(_mission_flag_key(resolve_mission_id(context), key), false)
		FACT_POOP_BAG_COUNT:
			return int(game_state.call("get_poop_bag_count")) if game_state != null and game_state.has_method("get_poop_bag_count") else 0
		FACT_INVENTORY_HAS_ITEM:
			return MissionInventoryScript.has_item(key)
		FACT_INVENTORY_ITEM_COUNT:
			return MissionInventoryScript.get_item_count(key)
		FACT_INVENTORY_HAS_CATEGORY:
			return MissionInventoryScript.has_category(key)
		_:
			return null


static func set_fact_value(fact_type: StringName, key: String, value: Variant, context: Dictionary = {}) -> Dictionary:
	var game_state := _autoload("GameState")
	if game_state == null:
		return _result(false, "game_state_missing", "GameState autoload is missing.", key)
	match fact_type:
		FACT_MISSION_FLAG:
			var mid := resolve_mission_id(context)
			if mid == "":
				return _result(false, "mission_id_missing", "Cannot set mission flag without a mission id.", key)
			var mission_flags := _dialogue_flags(game_state)
			mission_flags[_mission_flag_key(mid, key)] = value
			_emit_game_state_changed()
			return _result(true, "mission_flag_set", "Mission flag %s set to %s." % [key, str(value)], key, {"mission_id": mid, "value": value})
		FACT_DIALOGUE_FLAG:
			var dialogue_flags := _dialogue_flags(game_state)
			dialogue_flags[key] = value
			_emit_game_state_changed()
			return _result(true, "dialogue_flag_set", "Dialogue flag %s set to %s." % [key, str(value)], key, {"value": value})
		FACT_ALERT_STATE:
			var alert_mid := resolve_mission_id(context)
			if alert_mid == "":
				return _result(false, "mission_id_missing", "Cannot set alert state without a mission id.", key)
			if game_state.has_method("set_mission_alert_state"):
				game_state.call("set_mission_alert_state", alert_mid, String(value))
				_emit_game_state_changed()
				return _result(true, "alert_state_set", "Alert state set to %s." % String(value), key, {"mission_id": alert_mid})
		FACT_UNLOCKED_CARD:
			if game_state.has_method("unlock_card"):
				var changed := bool(game_state.call("unlock_card", key))
				return _result(true, "card_unlocked", "Unlocked card: %s." % key, key, {"changed": changed})
		FACT_TYPED_COLLECTIBLE:
			if game_state.has_method("record_typed_collectible"):
				var payload: Dictionary = {}
				var raw_payload: Variant = context.get("payload", null)
				if raw_payload is Dictionary:
					payload = raw_payload
				var collectible_type: String = String(payload.get("type", payload.get("collectible_type", "item")))
				game_state.call("record_typed_collectible", key, collectible_type, payload)
				_emit_game_state_changed()
				return _result(true, "typed_collectible_recorded", "Recorded typed collectible: %s." % key, key, {"type": collectible_type})
		FACT_EVIDENCE_CLUE:
			if game_state.has_method("record_evidence_clue"):
				var data: Dictionary = {}
				var raw_data: Variant = context.get("payload", null)
				if raw_data is Dictionary:
					data = raw_data
				game_state.call("record_evidence_clue", key, data)
				_emit_game_state_changed()
				return _result(true, "evidence_clue_recorded", "Recorded evidence clue: %s." % key, key)
	return _result(false, "unsupported_set_fact", "Fact type %s cannot be set by MissionFactBridge." % String(fact_type), key)


static func clear_fact_value(fact_type: StringName, key: String, context: Dictionary = {}) -> Dictionary:
	var game_state := _autoload("GameState")
	if game_state == null:
		return _result(false, "game_state_missing", "GameState autoload is missing.", key)
	match fact_type:
		FACT_MISSION_FLAG:
			var mid := resolve_mission_id(context)
			var flag_key := _mission_flag_key(mid, key)
			var mission_flags_clear := _dialogue_flags(game_state)
			mission_flags_clear.erase(flag_key)
			_emit_game_state_changed()
			return _result(true, "mission_flag_cleared", "Mission flag %s cleared." % key, key, {"mission_id": mid})
		FACT_DIALOGUE_FLAG:
			var dialogue_flags_clear := _dialogue_flags(game_state)
			dialogue_flags_clear.erase(key)
			_emit_game_state_changed()
			return _result(true, "dialogue_flag_cleared", "Dialogue flag %s cleared." % key, key)
	return _result(false, "unsupported_clear_fact", "Fact type %s cannot be cleared by MissionFactBridge." % String(fact_type), key)


static func has_autoload(name: String) -> bool:
	return _autoload(name) != null


static func is_known_fact_type(fact_type: StringName) -> bool:
	return fact_type in [
		FACT_ALWAYS,
		FACT_MISSION_ID,
		FACT_MISSION_COMPLETED,
		FACT_SELECTED_CARD,
		FACT_UNLOCKED_CARD,
		FACT_SCHEME_EFFECT,
		FACT_TYPED_COLLECTIBLE,
		FACT_TYPED_COLLECTIBLE_TYPE_COUNT,
		FACT_EVIDENCE_CLUE,
		FACT_CREW_ASSIST,
		FACT_OBJECTIVE_ACTIVE,
		FACT_OBJECTIVE_COMPLETED,
		FACT_ALERT_STATE,
		FACT_DIALOGUE_FLAG,
		FACT_MISSION_FLAG,
		FACT_POOP_BAG_COUNT,
		FACT_INVENTORY_HAS_ITEM,
		FACT_INVENTORY_ITEM_COUNT,
		FACT_INVENTORY_HAS_CATEGORY,
	]


static func _mission_flag_key(mission_id: String, flag_id: String) -> String:
	return "mission_flag:%s:%s" % [mission_id, flag_id]


static func _autoload(name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return null
	var tree := main_loop as SceneTree
	return tree.root.get_node_or_null(name)


static func _has_unlocked_card(game_state: Node, key: String) -> bool:
	if game_state == null:
		return false
	if game_state.has_method("has_scheme_card"):
		return bool(game_state.call("has_scheme_card", key))
	var unlocked: Variant = game_state.get("unlocked_cards")
	return unlocked is Array and (unlocked as Array).has(key)


static func _has_scheme_effect(effect_id: String, context: Dictionary) -> bool:
	if effect_id == "":
		return false
	return MissionSchemeBridge.has_scheme_effect(effect_id, resolve_mission_id(context))


static func _typed_collectibles(game_state: Node) -> Dictionary:
	if game_state == null:
		return {}
	var value: Variant = game_state.get("typed_collectibles")
	if value is Dictionary:
		return value as Dictionary
	return {}


static func _typed_collectible_type_count(game_state: Node, type_id: String) -> int:
	var count := 0
	for record in _typed_collectibles(game_state).values():
		if not (record is Dictionary):
			continue
		var d := record as Dictionary
		if String(d.get("type", "")) == type_id or String(d.get("collection_group", "")) == type_id:
			count += 1
	return count


static func _dialogue_flags(game_state: Node) -> Dictionary:
	if game_state == null:
		return {}
	var value: Variant = game_state.get("dialogue_flags")
	if value is Dictionary:
		return value as Dictionary
	return {}


static func _is_objective_active(quest_manager: Node, objective_id: String, mission_id: String) -> bool:
	if quest_manager == null or mission_id == "":
		return false
	var active_value: Variant = quest_manager.get("active_objectives")
	if not (active_value is Dictionary):
		return false
	var active := active_value as Dictionary
	if not active.has(mission_id):
		return false
	var mission_active: Variant = active[mission_id]
	return mission_active is Dictionary and (mission_active as Dictionary).has(objective_id)


static func _values_equal(actual: Variant, expected: Variant) -> bool:
	if typeof(actual) in [TYPE_INT, TYPE_FLOAT] or typeof(expected) in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(actual), float(expected))
	return actual == expected


static func _emit_game_state_changed() -> void:
	var event_bus := _autoload("EventBus")
	if event_bus != null:
		event_bus.game_state_changed.emit()


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
