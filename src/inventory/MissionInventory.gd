class_name MissionInventory
extends RefCounted

const ItemDataScript := preload("res://src/inventory/items/ItemData.gd")
const InventoryEntryScript := preload("res://src/inventory/items/InventoryEntry.gd")

static var _entries: Dictionary = {}


static func add_item(item: Variant, amount: int = 1, data: Dictionary = {}) -> Dictionary:
	var item_id := _item_id_from(item, data)
	if item_id == "":
		return _result(false, "item_id_missing", "Cannot add an inventory item without an item id.")
	var entry: Resource = _entry_for(item_id, item, data)
	var added: int = int(entry.call("add_count", maxi(1, amount)))
	_entries[item_id] = entry
	_emit_game_state_changed()
	return _result(added > 0, "item_added" if added > 0 else "item_stack_full", "Added %d %s." % [added, item_id], item_id, entry.call("to_summary"))


static func remove_item(item_id: String, amount: int = 1) -> Dictionary:
	var id := item_id.strip_edges()
	if id == "":
		return _result(false, "item_id_missing", "Cannot remove an inventory item without an item id.")
	if not _entries.has(id):
		return _result(false, "item_missing", "Mission inventory does not contain %s." % id, id)
	var entry: Resource = _entries[id]
	var removed: int = int(entry.call("remove_count", maxi(1, amount)))
	if bool(entry.call("is_empty")):
		_entries.erase(id)
	_emit_game_state_changed()
	return _result(removed > 0, "item_removed" if removed > 0 else "item_missing", "Removed %d %s." % [removed, id], id, entry.call("to_summary"))


static func clear_mission_items() -> Dictionary:
	var removed_ids: Array[String] = []
	for key in _entries.keys():
		var entry: Resource = _entries[key]
		if entry == null or bool(entry.get("mission_only")):
			removed_ids.append(String(key))
	for id in removed_ids:
		_entries.erase(id)
	if not removed_ids.is_empty():
		_emit_game_state_changed()
	return _result(true, "mission_items_cleared", "Cleared %d mission inventory entries." % removed_ids.size(), "", {"removed_ids": removed_ids})


static func clear_all() -> void:
	_entries.clear()
	_emit_game_state_changed()


static func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_count(item_id) >= maxi(1, amount)


static func get_item_count(item_id: String) -> int:
	var id := item_id.strip_edges()
	if id == "" or not _entries.has(id):
		return 0
	var entry: Resource = _entries[id]
	return entry.count if entry != null else 0


static func has_category(category_id: String) -> bool:
	return get_category_count(category_id) > 0


static func get_category_count(category_id: String) -> int:
	var wanted := category_id.strip_edges()
	if wanted == "":
		return 0
	var total := 0
	for entry in _entries.values():
		if entry is Resource and entry.has_method("get_category") and entry.call("get_category") == wanted:
			total += int(entry.get("count"))
	return total


static func get_snapshot() -> Dictionary:
	var items: Dictionary = {}
	for key in _entries.keys():
		var entry: Resource = _entries[key]
		if entry != null:
			items[String(key)] = entry.call("to_summary")
	return {"items": items, "count": items.size()}


static func _entry_for(item_id: String, item: Variant, data: Dictionary) -> Resource:
	if _entries.has(item_id) and _entries[item_id] is Resource:
		var existing: Resource = _entries[item_id]
		if _is_item_data(item):
			existing.configure_from_item(item, data)
		return existing
	var entry: Resource = InventoryEntryScript.new()
	entry.item_id = StringName(item_id)
	if _is_item_data(item):
		entry.configure_from_item(item, data)
	else:
		entry.configure_from_item(null, data)
	return entry


static func _item_id_from(item: Variant, data: Dictionary) -> String:
	if _is_item_data(item):
		return item.call("get_item_id")
	var explicit := String(data.get("item_id", "")).strip_edges()
	if explicit != "":
		return explicit
	return String(item).strip_edges()


static func _is_item_data(item: Variant) -> bool:
	return item is Resource and (item as Resource).get_script() == ItemDataScript


static func _emit_game_state_changed() -> void:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return
	var event_bus := (main_loop as SceneTree).root.get_node_or_null("EventBus")
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
