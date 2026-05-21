class_name ObjectiveStepController
extends RefCounted

## Thin static helper over QuestManager for authored mission mechanics.


static func activate_objective(
	objective_id: String,
	text: String = "",
	mission_id: String = "",
	context: Dictionary = {}
) -> Dictionary:
	var oid := objective_id.strip_edges()
	if oid == "":
		return _result(false, "objective_id_missing", "Objective id is required.", "", {"objective_id": oid})
	var mid := _resolve_mission_id(mission_id, context)
	if mid == "":
		return _result(
			false,
			"mission_id_missing",
			"Mission id is required to activate an objective.",
			oid,
			{"objective_id": oid}
		)
	var quest_manager := _get_quest_manager()
	if quest_manager == null:
		return _result(
			false,
			"quest_manager_missing",
			"QuestManager autoload is missing.",
			oid,
			{"objective_id": oid, "mission_id": mid}
		)
	var objective_text := _resolve_objective_text(oid, text)
	var record: Dictionary = quest_manager.add_objective(oid, objective_text, "active", mid)
	return _result(
		true,
		"objective_activated",
		"Activated objective: %s" % oid,
		oid,
		{
			"mission_id": mid,
			"objective_id": oid,
			"text": objective_text,
			"record": record,
		}
	)


static func complete_objective(
	objective_id: String,
	text: String = "",
	mission_id: String = "",
	context: Dictionary = {}
) -> Dictionary:
	var oid := objective_id.strip_edges()
	if oid == "":
		return _result(false, "objective_id_missing", "Objective id is required.", "", {"objective_id": oid})
	var mid := _resolve_mission_id(mission_id, context)
	if mid == "":
		return _result(
			false,
			"mission_id_missing",
			"Mission id is required to complete an objective.",
			oid,
			{"objective_id": oid}
		)
	var quest_manager := _get_quest_manager()
	if quest_manager == null:
		return _result(
			false,
			"quest_manager_missing",
			"QuestManager autoload is missing.",
			oid,
			{"objective_id": oid, "mission_id": mid}
		)
	var objective_text := _resolve_objective_text(oid, text)
	var record: Dictionary = quest_manager.complete_objective_id(oid, objective_text, mid)
	return _result(
		true,
		"objective_completed",
		"Completed objective: %s" % oid,
		oid,
		{
			"mission_id": mid,
			"objective_id": oid,
			"text": objective_text,
			"record": record,
		}
	)


static func fail_objective(
	objective_id: String,
	text: String = "",
	mission_id: String = "",
	context: Dictionary = {}
) -> Dictionary:
	var oid := objective_id.strip_edges()
	if oid == "":
		return _result(false, "objective_id_missing", "Objective id is required.", "", {"objective_id": oid})
	var mid := _resolve_mission_id(mission_id, context)
	if mid == "":
		return _result(
			false,
			"mission_id_missing",
			"Mission id is required to fail an objective.",
			oid,
			{"objective_id": oid}
		)
	var quest_manager := _get_quest_manager()
	if quest_manager == null:
		return _result(
			false,
			"quest_manager_missing",
			"QuestManager autoload is missing.",
			oid,
			{"objective_id": oid, "mission_id": mid}
		)
	if not quest_manager.has_method("add_objective"):
		return _result(
			false,
			"objective_fail_not_supported",
			"QuestManager does not support failing objectives.",
			oid,
			{"objective_id": oid, "mission_id": mid}
		)
	var objective_text := _resolve_objective_text(oid, text)
	var record: Dictionary = quest_manager.add_objective(oid, objective_text, "failed", mid)
	_remove_from_active_objectives(quest_manager, mid, oid)
	return _result(
		true,
		"objective_failed",
		"Failed objective: %s" % oid,
		oid,
		{
			"mission_id": mid,
			"objective_id": oid,
			"text": objective_text,
			"record": record,
		}
	)


static func is_objective_active(objective_id: String, mission_id: String = "", context: Dictionary = {}) -> bool:
	var oid := objective_id.strip_edges()
	if oid == "":
		return false
	if is_objective_completed(oid, mission_id, context):
		return false
	var record := get_objective_record(oid, mission_id, context)
	if record.is_empty():
		return false
	return bool(record.get("active", false))


static func is_objective_completed(objective_id: String, mission_id: String = "", context: Dictionary = {}) -> bool:
	var oid := objective_id.strip_edges()
	if oid == "":
		return false
	var mid := _resolve_mission_id(mission_id, context)
	if mid == "":
		return false
	var quest_manager := _get_quest_manager()
	if quest_manager == null:
		return false
	if quest_manager.has_method("is_objective_completed"):
		return bool(quest_manager.call("is_objective_completed", oid, mid))
	var record := _get_raw_record(quest_manager, mid, oid)
	return String(record.get("status", "")) == "completed"


static func get_objective_record(objective_id: String, mission_id: String = "", context: Dictionary = {}) -> Dictionary:
	var oid := objective_id.strip_edges()
	if oid == "":
		return {}
	var mid := _resolve_mission_id(mission_id, context)
	if mid == "":
		return {}
	var quest_manager := _get_quest_manager()
	if quest_manager == null:
		return {}
	var raw := _get_raw_record(quest_manager, mid, oid)
	if raw.is_empty():
		return {}
	var status := String(raw.get("status", ""))
	var completed := status == "completed"
	var active := not completed and status == "active" and _is_in_active_objectives(quest_manager, mid, oid)
	return {
		"objective_id": oid,
		"mission_id": mid,
		"active": active,
		"completed": completed,
		"text": String(raw.get("text", "")),
		"status": status,
		"raw": raw,
	}


static func _resolve_mission_id(mission_id: String = "", context: Dictionary = {}) -> String:
	var explicit := mission_id.strip_edges()
	if explicit != "":
		return explicit
	var from_context := String(context.get("mission_id", "")).strip_edges()
	if from_context != "":
		return from_context
	var resolved := MissionFactBridge.resolve_mission_id(context)
	if resolved != "":
		return resolved
	var game_state := _get_game_state()
	if game_state != null:
		var current := String(game_state.get("current_mission_id")).strip_edges()
		if current != "":
			return current
	return ""


static func _has_quest_manager() -> bool:
	return _get_quest_manager() != null


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}


static func _resolve_objective_text(objective_id: String, text: String) -> String:
	var objective_text := text.strip_edges()
	if objective_text != "":
		return objective_text
	return objective_id.replace("_", " ").capitalize()


static func _get_quest_manager() -> Node:
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	return (tree as SceneTree).root.get_node_or_null("QuestManager")


static func _get_game_state() -> Node:
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	return (tree as SceneTree).root.get_node_or_null("GameState")


static func _get_raw_record(quest_manager: Node, mission_id: String, objective_id: String) -> Dictionary:
	if quest_manager == null or mission_id == "" or objective_id == "":
		return {}
	if quest_manager.has_method("has_objective") and not bool(quest_manager.call("has_objective", objective_id, mission_id)):
		return {}
	var records_value: Variant = quest_manager.get("objective_records")
	if not (records_value is Dictionary):
		return {}
	var records := records_value as Dictionary
	if not records.has(mission_id):
		return {}
	var mission_records_value: Variant = records[mission_id]
	if not (mission_records_value is Dictionary):
		return {}
	var mission_records := mission_records_value as Dictionary
	if not mission_records.has(objective_id):
		return {}
	var record_value: Variant = mission_records[objective_id]
	if record_value is Dictionary:
		return (record_value as Dictionary).duplicate(true)
	return {}


static func _is_in_active_objectives(quest_manager: Node, mission_id: String, objective_id: String) -> bool:
	if quest_manager == null or mission_id == "" or objective_id == "":
		return false
	var active_value: Variant = quest_manager.get("active_objectives")
	if not (active_value is Dictionary):
		return false
	var active := active_value as Dictionary
	if not active.has(mission_id):
		return false
	var mission_active_value: Variant = active[mission_id]
	if not (mission_active_value is Dictionary):
		return false
	return (mission_active_value as Dictionary).has(objective_id)


static func _remove_from_active_objectives(quest_manager: Node, mission_id: String, objective_id: String) -> void:
	if quest_manager == null or mission_id == "" or objective_id == "":
		return
	var active_value: Variant = quest_manager.get("active_objectives")
	if not (active_value is Dictionary):
		return
	var active := active_value as Dictionary
	if not active.has(mission_id):
		return
	var mission_active_value: Variant = active[mission_id]
	if mission_active_value is Dictionary:
		(mission_active_value as Dictionary).erase(objective_id)
