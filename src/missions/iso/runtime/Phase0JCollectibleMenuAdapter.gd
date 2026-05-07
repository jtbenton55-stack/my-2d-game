@tool
class_name Phase0JCollectibleMenuAdapter
extends Node

const TypedMissionCollectibleHelper := preload("res://src/missions/iso/TypedMissionCollectible.gd")

@export var mission_id := "taco_bell_drop"


func _ready() -> void:
	set_meta("generated_by", "Phase0J-C4")
	set_meta("scene_local_only", true)


func register_collectible(item_id: String, category: String, payload: Dictionary = {}) -> Dictionary:
	match _typed_category(category, item_id):
		"polaroid":
			return register_polaroid(_polaroid_id(item_id, payload), payload)
		"evidence_clue":
			return register_clue(_clue_id(item_id, payload), payload)
		"poop_bag":
			return register_poobag_or_bag(item_id, payload)
		"glow_guy":
			return register_glow(item_id, payload)
		"tiny_icon":
			return register_tiny(item_id, payload)
		_:
			return _register_typed(item_id, _typed_category(category, item_id), payload, false, "Typed collectible state updated; no dedicated real menu found.")


func register_clue(clue_id: String, payload: Dictionary = {}) -> Dictionary:
	var data := _payload_data(clue_id, "evidence_clue", payload)
	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")
		if game_state != null and game_state.has_method("ensure_and_discover_sterling_clue"):
			game_state.call("ensure_and_discover_sterling_clue", clue_id, data)
			_record_typed(clue_id, "evidence_clue", data)
			return _status(true, true, true, "GameState", "Clue/intel recorded in GameState evidence clues; pause Clues panel reads this state.", "")
	return _register_typed(clue_id, "evidence_clue", payload, false, "GameState clue API missing; local typed state only.")


func register_polaroid(polaroid_id: String, payload: Dictionary = {}) -> Dictionary:
	var before := false
	if has_node("/root/CollectibleManager"):
		var manager := get_node("/root/CollectibleManager")
		if manager != null and manager.has_method("is_collected"):
			before = bool(manager.call("is_collected", polaroid_id))
		if manager != null and manager.has_method("collect_polaroid"):
			manager.call("collect_polaroid", polaroid_id)
			_record_typed(polaroid_id, "polaroid", _payload_data(polaroid_id, "polaroid", payload))
			return _status(true, true, true, "CollectibleManager", "Polaroid registered; PolaroidGallery reads GameState.collected_polaroids.", "Already present before collect." if before else "")
	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")
		if game_state != null and game_state.has_method("collect_polaroid"):
			game_state.call("collect_polaroid", polaroid_id)
			_record_typed(polaroid_id, "polaroid", _payload_data(polaroid_id, "polaroid", payload))
			return _status(true, true, true, "GameState", "Polaroid registered; PolaroidGallery reads GameState.collected_polaroids.", "")
	return _register_typed(polaroid_id, "polaroid", payload, false, "Polaroid manager missing; local typed state only.")


func register_poobag_or_bag(item_id: String, payload: Dictionary = {}) -> Dictionary:
	return _register_typed(item_id, "poop_bag", payload, false, "Poop bag count updated in GameState; no pause collectible tab for tools found.")


func register_glow(item_id: String, payload: Dictionary = {}) -> Dictionary:
	return _register_typed(item_id, "glow_guy", payload, false, "Glow Guy typed collectible state updated; no dedicated real menu tab found.")


func register_tiny(item_id: String, payload: Dictionary = {}) -> Dictionary:
	return _register_typed(item_id, "tiny_icon", payload, false, "Tiny icon typed collectible state updated; no dedicated real menu tab found.")


func refresh_menu_if_possible() -> Dictionary:
	return _status(true, false, false, "", "No active collectible menu refresh API found; data managers emit EventBus updates.", "")


func _register_typed(item_id: String, typed_category: String, payload: Dictionary, menu_updated: bool, warning: String) -> Dictionary:
	var display_name := String(payload.get("display_name", _pretty_id(item_id)))
	var ok := false
	if not Engine.is_editor_hint():
		ok = bool(TypedMissionCollectibleHelper.collect(item_id, typed_category, mission_id, display_name))
		if not ok:
			_record_typed(item_id, typed_category, _payload_data(item_id, typed_category, payload))
	return _status(true, menu_updated, true, "TypedMissionCollectible/GameState", "Typed collectible state updated.", warning)


func _record_typed(item_id: String, typed_category: String, data: Dictionary) -> void:
	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")
		if game_state != null and game_state.has_method("record_typed_collectible"):
			game_state.call("record_typed_collectible", item_id, typed_category, data)


func _payload_data(item_id: String, typed_category: String, payload: Dictionary) -> Dictionary:
	var data := payload.duplicate(true)
	data["mission_id"] = String(data.get("mission_id", mission_id))
	data["display_name"] = String(data.get("display_name", _pretty_id(item_id)))
	data["collectible_type"] = typed_category
	data["collection_group"] = typed_category
	data["discovered"] = true
	data["title"] = String(data.get("title", data.get("display_name", _pretty_id(item_id))))
	data["description"] = String(data.get("description", "Phase0J Taco Bell redesign pickup."))
	data["category"] = String(data.get("category", "Mission Bible"))
	data["connects_to"] = String(data.get("connects_to", "Sterling Tower"))
	return data


func _typed_category(category: String, item_id: String) -> String:
	var cat := category.to_lower()
	if item_id == "OBJ_bag_recovery":
		return "evidence_clue"
	if cat in ["polaroid", "photo"]:
		return "polaroid"
	if cat in ["evidence_clue", "clue", "intel"]:
		return "evidence_clue"
	if cat in ["poop_bag", "bag"]:
		return "poop_bag"
	if cat in ["glow_guy", "glow"]:
		return "glow_guy"
	if cat in ["tiny_icon", "tiny"]:
		return "tiny_icon"
	return cat


func _polaroid_id(item_id: String, payload: Dictionary) -> String:
	if payload.has("polaroid_id"):
		return String(payload["polaroid_id"])
	var aliases: Array = payload.get("aliases", [])
	for alias in aliases:
		var text := String(alias)
		if text == "hidden_polaroid_market_rain":
			return "taco_bell_midnight_market_rain"
		if text == "perfect_polaroid_garage_ambush":
			return "taco_bell_perfect_ambush"
	return item_id


func _clue_id(item_id: String, payload: Dictionary) -> String:
	return String(payload.get("clue_id", item_id))


func _status(success: bool, menu_updated: bool, manager_called: bool, manager_name: String, message: String, warning: String) -> Dictionary:
	return {
		"success": success,
		"menu_updated": menu_updated,
		"manager_called": manager_called,
		"manager_name": manager_name,
		"message": message,
		"warning": warning,
	}


func _pretty_id(id: String) -> String:
	return id.replace("_", " ").capitalize()
