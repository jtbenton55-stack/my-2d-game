class_name MissionAuthoredCollectiblePersistence
extends RefCounted
## D6-06 authored collectible persistence helpers (idempotent commit boundary).

const PERSIST_FLAG_PREFIX := "d6_06_authored_committed:"
const TYPED_FLAG_PREFIX := "mission_collectible:"


static func persist_flag_key(collectible_id: String, collectible_type: String = "") -> String:
	var id_s := String(collectible_id).strip_edges()
	if id_s == "":
		id_s = String(collectible_type).strip_edges()
	return PERSIST_FLAG_PREFIX + id_s


static func is_already_persisted(collectible_id: String, collectible_type: String = "") -> bool:
	var id_s := String(collectible_id).strip_edges()
	if id_s == "":
		return false
	var flag_key := persist_flag_key(id_s, collectible_type)
	if GameState.dialogue_flags.get(flag_key, false) == true:
		return true
	var typed_flag := TYPED_FLAG_PREFIX + id_s
	if GameState.dialogue_flags.get(typed_flag, false) == true:
		return true
	if GameState.typed_collectibles.has(id_s):
		var record: Dictionary = GameState.typed_collectibles.get(id_s, {})
		if record.get("discovered", false) == true:
			return true
	var money_flag := "d6_06_money:" + id_s
	if GameState.dialogue_flags.get(money_flag, false) == true:
		return true
	return false


static func mark_persisted(collectible_id: String, collectible_type: String = "") -> void:
	var id_s := String(collectible_id).strip_edges()
	if id_s == "":
		return
	GameState.dialogue_flags[persist_flag_key(id_s, collectible_type)] = true


static func hideout_flag_key(display_key: String) -> String:
	return "hideout_display:%s" % String(display_key).strip_edges()
