@tool
class_name Phase0JMissionStateAdapter
extends Node

@export var mission_id := "taco_bell_drop"
@export var debug_hud_path: NodePath = NodePath("../Phase0JDebugHUD")
@export var collectible_menu_adapter_path: NodePath = NodePath("../Phase0JCollectibleMenuAdapter")
@export var objective_adapter_path: NodePath = NodePath("../Phase0JObjectiveAdapter")

var collected_ids: Dictionary = {}
var inspected_ids: Dictionary = {}
var collected_by_category: Dictionary = {
	"poop_bag": {},
	"bag": {},
	"evidence_clue": {},
	"polaroid": {},
	"glow_guy": {},
	"tiny_icon": {},
	"objective_bag": {},
}
var clues_collected: Dictionary = {}
var polaroids_collected: Dictionary = {}
var poop_bags_collected: Dictionary = {}
var bags_collected: Dictionary = {}
var tiny_collected: Dictionary = {}
var glow_collected: Dictionary = {}
var bag_items_collected: Dictionary = {}
var objective_flags: Dictionary = {}
var objective_records: Dictionary = {}
var gate_unlocked := false


func _ready() -> void:
	set_meta("generated_by", "Phase0J-C4")
	set_meta("scene_local_only", true)
	_update_hud_counts()


func collect_item(item_id: String, category: String, payload: Dictionary = {}) -> Dictionary:
	if item_id == "":
		return _result(false, false, "Missing item id", false, "", false, "Missing item id")
	var normalized_category := normalize_category(category, item_id, payload)
	_ensure_category(normalized_category)
	if has_collected(item_id) or collected_by_category[normalized_category].has(item_id):
		return _result(true, true, "Already collected: %s" % item_id, false, "", false, "")
	var previous_counts := get_all_counts()
	collected_ids[item_id] = true
	collected_by_category[normalized_category][item_id] = true
	_track_category(item_id, normalized_category)
	var menu_result := _sync_to_real_systems(item_id, normalized_category, payload)
	if item_id == "OBJ_bag_recovery":
		mark_objective("delivery_bag_recovered", "collected")
	var message := _message_for(item_id, normalized_category, menu_result)
	var new_counts := get_all_counts()
	if not assert_monotonic_counts(previous_counts, new_counts):
		return _result(false, false, "Count monotonicity failed for %s" % item_id, false, "", false, "A category count decreased unexpectedly.")
	_update_hud_counts()
	return _result(true, false, message, bool(menu_result.get("manager_called", false)), String(menu_result.get("manager_name", "")), bool(menu_result.get("menu_updated", false)), String(menu_result.get("warning", "")))


func inspect_marker(marker_id: String, _category: String, payload: Dictionary = {}) -> Dictionary:
	if not inspected_ids.has(marker_id):
		inspected_ids[marker_id] = true
	var text := "%s inspected - %s" % [marker_id, String(payload.get("deferred_mechanic", "mechanic deferred"))]
	_update_hud_counts()
	return _result(true, inspected_ids.has(marker_id), text, false, "", false, String(payload.get("warning", "INSPECT_ONLY_DEFERRED")))


func has_collected(item_id: String) -> bool:
	return collected_ids.has(item_id)


func reset_attempt_state() -> Dictionary:
	collected_ids.clear()
	inspected_ids.clear()
	for category in _canonical_categories():
		_ensure_category(category)
		collected_by_category[category].clear()
	clues_collected.clear()
	polaroids_collected.clear()
	poop_bags_collected.clear()
	bags_collected.clear()
	tiny_collected.clear()
	glow_collected.clear()
	bag_items_collected.clear()
	objective_flags.clear()
	objective_records.clear()
	gate_unlocked = false
	_update_hud_counts()
	return {"ok": true, "code": "phase0j_state_reset", "mission_id": mission_id}


func get_count(category: String) -> int:
	var normalized_category := normalize_category(category)
	_ensure_category(normalized_category)
	return collected_by_category[normalized_category].size()


func get_all_counts() -> Dictionary:
	var counts := {}
	for category in _canonical_categories():
		_ensure_category(category)
		counts[category] = collected_by_category[category].size()
	return counts


func get_collected_ids(category: String) -> PackedStringArray:
	var normalized_category := normalize_category(category)
	_ensure_category(normalized_category)
	var out := PackedStringArray()
	for item_id in collected_by_category[normalized_category].keys():
		out.append(String(item_id))
	return out


func assert_monotonic_counts(previous_counts: Dictionary, new_counts: Dictionary) -> bool:
	for category in _canonical_categories():
		if int(new_counts.get(category, 0)) < int(previous_counts.get(category, 0)):
			push_warning("[Phase0J-C5] Count decreased unexpectedly for %s: %d -> %d" % [category, int(previous_counts.get(category, 0)), int(new_counts.get(category, 0))])
			return false
	return true


func mark_objective(objective_id: String, status: String) -> Dictionary:
	objective_flags[objective_id] = status
	objective_records[objective_id] = {
		"objective_id": objective_id,
		"status": status,
		"mission_id": mission_id,
	}
	var adapter := get_node_or_null(objective_adapter_path)
	var result := {}
	if adapter != null and adapter.has_method("mark_objective_complete"):
		result = adapter.call("mark_objective_complete", objective_id)
	_update_hud_counts()
	return result


func set_gate_unlocked(value: bool) -> void:
	gate_unlocked = value
	objective_flags["code_gate_unlocked"] = value
	_update_hud_counts()


func is_gate_unlocked() -> bool:
	return gate_unlocked


func sync_to_real_systems(item_id: String, category: String, payload: Dictionary = {}) -> Dictionary:
	return _sync_to_real_systems(item_id, normalize_category(category, item_id, payload), payload)


func get_summary_text() -> String:
	var parts: Array[String] = []
	var counts := get_all_counts()
	for key in _canonical_categories():
		parts.append("%s:%d" % [String(key), int(counts.get(key, 0))])
	return "C4 state | " + ", ".join(parts) + " | inspected:%d | gate:%s" % [inspected_ids.size(), "UNLOCKED" if gate_unlocked else "LOCKED"]


func _sync_to_real_systems(item_id: String, category: String, payload: Dictionary) -> Dictionary:
	var enriched := payload.duplicate(true)
	enriched["mission_id"] = String(enriched.get("mission_id", mission_id))
	enriched["display_name"] = String(enriched.get("display_name", _pretty_id(item_id)))
	enriched["category"] = category
	var menu_adapter := get_node_or_null(collectible_menu_adapter_path)
	var objective_adapter := get_node_or_null(objective_adapter_path)
	if item_id == "OBJ_bag_recovery" and objective_adapter != null and objective_adapter.has_method("mark_delivery_bag_collected"):
		var objective_result: Dictionary = objective_adapter.call("mark_delivery_bag_collected")
		var collect_result := {}
		if menu_adapter != null and menu_adapter.has_method("register_collectible"):
			collect_result = menu_adapter.call("register_collectible", item_id, "evidence_clue", enriched)
		collect_result["objective_result"] = objective_result
		return collect_result
	if category in ["evidence_clue", "intel"] and objective_adapter != null and objective_adapter.has_method("add_clue"):
		var clue_result: Dictionary = objective_adapter.call("add_clue", String(enriched.get("clue_id", item_id)), enriched)
		var typed_result := {}
		if menu_adapter != null and menu_adapter.has_method("register_collectible"):
			typed_result = menu_adapter.call("register_collectible", item_id, category, enriched)
			typed_result["clue_result"] = clue_result
			return typed_result
		return clue_result
	if menu_adapter != null and menu_adapter.has_method("register_collectible"):
		return menu_adapter.call("register_collectible", item_id, category, enriched)
	return {
		"success": true,
		"menu_updated": false,
		"manager_called": false,
		"manager_name": "",
		"message": "Local Phase0J state only.",
		"warning": "No adapter found.",
	}


func _track_category(item_id: String, category: String) -> void:
	match category:
		"evidence_clue":
			clues_collected[item_id] = true
		"polaroid":
			polaroids_collected[item_id] = true
		"poop_bag":
			poop_bags_collected[item_id] = true
		"bag":
			bags_collected[item_id] = true
			bag_items_collected[item_id] = true
		"tiny_icon":
			tiny_collected[item_id] = true
		"glow_guy":
			glow_collected[item_id] = true
		"objective_bag":
			objective_flags[item_id] = "collected"
		_:
			bag_items_collected[item_id] = true


func normalize_category(raw_category: String, item_id: String = "", payload: Dictionary = {}) -> String:
	var cat := raw_category.strip_edges().to_lower().replace(" ", "_")
	if item_id == "OBJ_bag_recovery":
		return "objective_bag"
	if cat in ["clue", "evidence_clue", "intel"]:
		return "evidence_clue"
	if cat in ["photo", "polaroid"]:
		return "polaroid"
	if cat in ["poop", "poop_bag"]:
		return "poop_bag"
	if cat == "bag" or cat == "bag_item":
		if String(payload.get("count_group", "")).to_lower() == "poop_bag" or String(payload.get("visual_type", "")).to_lower() == "bag":
			return "poop_bag"
		return "bag"
	if cat in ["glow", "glow_guy"]:
		return "glow_guy"
	if cat in ["tiny", "tiny_icon"]:
		return "tiny_icon"
	if cat in ["objective_bag", "delivery_bag"]:
		return "objective_bag"
	if cat == "objective" and String(payload.get("objective_id", "")).contains("bag"):
		return "objective_bag"
	return cat


func _message_for(item_id: String, category: String, menu_result: Dictionary) -> String:
	var menu_text := "menu updated" if bool(menu_result.get("menu_updated", false)) else "local/typed state only; menu API missing"
	var warning := String(menu_result.get("warning", ""))
	match category:
		"poop_bag":
			return "Collected poop bag: %s - %s" % [item_id, menu_text]
		"polaroid":
			return "Collected Polaroid: %s - %s" % [item_id, menu_text]
		"evidence_clue":
			return "Collected clue: %s - %s" % [item_id, menu_text]
		"glow_guy":
			return "Collected Glow Guy: %s - %s" % [item_id, menu_text]
		"tiny_icon":
			return "Collected tiny item: %s - %s" % [item_id, menu_text]
		"objective_bag":
			return "Objective collected: Delivery bag - objective/local state updated"
		_:
			return "Collected: %s (%s) - %s%s" % [item_id, category, menu_text, " - " + warning if warning != "" else ""]


func _update_hud_counts() -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null:
		if hud.has_method("set_phase0j_counts"):
			hud.call("set_phase0j_counts", get_all_counts(), get_summary_text())
		if hud.has_method("set_gate_state"):
			hud.call("set_gate_state", gate_unlocked)


func _result(success: bool, already_done: bool, message: String, real_system_updated: bool, real_system_name: String, menu_updated: bool, warning: String) -> Dictionary:
	return {
		"success": success,
		"already_done": already_done,
		"message": message,
		"real_system_updated": real_system_updated,
		"real_system_name": real_system_name,
		"menu_updated": menu_updated,
		"warning": warning,
	}


func _pretty_id(id: String) -> String:
	return id.replace("_", " ").capitalize()


func _canonical_categories() -> PackedStringArray:
	return PackedStringArray(["poop_bag", "bag", "evidence_clue", "polaroid", "glow_guy", "tiny_icon", "objective_bag"])


func _ensure_category(category: String) -> void:
	if not collected_by_category.has(category):
		collected_by_category[category] = {}
