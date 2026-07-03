class_name MissionPauseDataProvider
extends RefCounted
## Mission-agnostic pause payload builder (0M-D2). Not an autoload.


static func get_provider_id() -> String:
	return "MissionPauseDataProvider"


static func has_mission_context(mission_id: String = "", mission_node: Node = null) -> bool:
	var mid := _effective_mission_id(mission_id, mission_node)
	return mid != ""


static func get_objective_snapshot(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var warnings: Array[String] = []
	var mid := _effective_mission_id(mission_id, mission_node)
	var items: Array[Dictionary] = []
	if mid == "":
		warnings.append("empty_mission_id")
		return {"ok": true, "mission_id": "", "items": items, "warnings": warnings}
	var snap := MissionObjectiveBridge.get_objective_snapshot(mid)
	for line in snap.get("quest_active_list", []):
		items.append({"kind": "active", "text": String(line)})
	for line in snap.get("quest_completed_list", []):
		items.append({"kind": "completed", "text": String(line)})
	return {"ok": true, "mission_id": mid, "items": items, "warnings": warnings, "raw": snap}


static func get_scheme_card_snapshot(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var mid := _effective_mission_id(mission_id, mission_node)
	var snap := MissionSchemeBridge.get_scheme_snapshot(mid)
	var items: Array[Dictionary] = []
	for row in snap.get("equipped", []):
		if row is Dictionary:
			items.append(row)
	return {
		"ok": snap.get("ok", false),
		"mission_id": mid,
		"items": items,
		"warnings": snap.get("warnings", []),
		"loadout_slots": snap.get("loadout_slots", []),
		"legacy_selected_card_ids": snap.get("legacy_selected_card_ids", []),
		"scheme_debug_note": snap.get("scheme_debug_note", ""),
		"unlocked_ids": snap.get("unlocked_ids", []),
	}


static func get_clue_snapshot(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var mid := _effective_mission_id(mission_id, mission_node)
	var raw := MissionClueBridge.get_clue_snapshot(mid)
	var items: Array[Dictionary] = []
	for clue in raw.get("items", []):
		if clue is Dictionary and clue.get("discovered", false) == true:
			items.append(
				{
					"id": String(clue.get("clue_id", "")),
					"title": String(clue.get("title", "")),
					"description": String(clue.get("description", "")),
				}
			)
	return {"ok": raw.get("ok", false), "mission_id": mid, "items": items, "warnings": raw.get("warnings", [])}


## Plain-English heat line for pause (D6-01). No raw API identifiers in the string.
static func get_heat_security_pause_line(mission_id: String = "", mission_node: Node = null) -> String:
	var mid := _effective_mission_id(mission_id, mission_node)
	if mid == "" or not MissionAutoloadResolver.has_game_state():
		return ""
	var heat := GameState.get_mission_heat(mid)
	return "Heat: %d/5 — failed runs make this mission more guarded on replay. Current alarms affect only this attempt." % heat


static func get_pause_payload(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var mid := _effective_mission_id(mission_id, mission_node)
	var warnings: Array[String] = []
	var obj := get_objective_snapshot(mid, mission_node)
	var sch := get_scheme_card_snapshot(mid, mission_node)
	var clu := get_clue_snapshot(mid, mission_node)
	var ctx := get_attempt_context_snapshot(mid, mission_node)
	warnings.append_array(obj.get("warnings", []))
	warnings.append_array(sch.get("warnings", []))
	warnings.append_array(clu.get("warnings", []))
	warnings.append_array(ctx.get("warnings", []))
	return {
		"ok": true,
		"mission_id": mid,
		"mission_name": _mission_name(mid),
		"objectives": obj.get("items", []),
		"scheme_cards": sch.get("items", []),
		"clues": clu.get("items", []),
		"attempt_context": ctx.get("items", []),
		"attempt_facts": ctx.get("facts", {}),
		"warnings": warnings,
		"heat_security_line": get_heat_security_pause_line(mid, mission_node),
	}


static func get_attempt_context_snapshot(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var mid := _effective_mission_id(mission_id, mission_node)
	var warnings: Array[String] = []
	var runtime_summary: Dictionary = {}
	var attempt_state: Dictionary = {}
	if mission_node != null and mission_node.has_method("get_runtime_debug_summary"):
		runtime_summary = mission_node.call("get_runtime_debug_summary") as Dictionary
		attempt_state = runtime_summary.get("attempt_runtime_state", {}) as Dictionary
	var phase0k := _phase0k_controller(mission_node)
	var delivery_bag_collected := _node_bool(phase0k, "delivery_bag_collected") or QuestManager.is_objective_completed("recover_delivery_bag", mid)
	var code_gate_unlocked := _node_bool(phase0k, "code_gate_unlocked") or QuestManager.is_objective_completed("open_garage_code_gate", mid)
	var exit_unlocked := _node_bool(phase0k, "exit_unlocked") or QuestManager.is_objective_completed("return_to_louis", mid)
	var louis_route_available := _has_louis_route_available()
	var louis_route_selected := MissionAutoloadResolver.has_game_state() and GameState.has_selected_card("louis_delivery_route")
	var beam_triggered := bool(runtime_summary.get("garage_beam_triggered", false))
	var beam_bypassed := bool(runtime_summary.get("garage_beam_bypassed", false)) or bool(attempt_state.get("louis_route_beam_bypass_used", false))
	var facts := {
		"delivery_bag_collected": delivery_bag_collected,
		"code_gate_unlocked": code_gate_unlocked,
		"exit_unlocked": exit_unlocked,
		"louis_route_available": louis_route_available,
		"louis_route_selected": louis_route_selected,
		"garage_beam_armed": bool(runtime_summary.get("garage_beam_armed", true)),
		"garage_beam_triggered": beam_triggered,
		"garage_beam_bypassed": beam_bypassed,
	}
	var items: Array[Dictionary] = []
	items.append({"id": "mission", "label": "Mission", "text": _mission_name(mid), "status": "active" if mid != "" else "missing"})
	items.append({"id": "delivery_bag", "label": "Delivery bag", "text": "Collected" if delivery_bag_collected else "Not collected", "status": "done" if delivery_bag_collected else "pending"})
	items.append({"id": "code_gate", "label": "Garage code gate", "text": "Open" if code_gate_unlocked else "Locked", "status": "done" if code_gate_unlocked else "pending"})
	items.append({"id": "louis_exit", "label": "Louis exit", "text": "Ready" if exit_unlocked else "Locked", "status": "done" if exit_unlocked else "pending"})
	items.append({"id": "louis_route", "label": "Louis delivery route", "text": "Available" if louis_route_available else "Unavailable", "status": "active" if louis_route_available else "locked"})
	items.append({"id": "garage_beam", "label": "Garage beam", "text": _beam_context_text(beam_triggered, beam_bypassed), "status": "bypassed" if beam_bypassed else ("tripped" if beam_triggered else "armed")})
	return {"ok": true, "mission_id": mid, "items": items, "facts": facts, "warnings": warnings}


static func _effective_mission_id(mission_id: String, mission_node: Node) -> String:
	if mission_id != "":
		return mission_id
	if mission_node != null and mission_node.has_method("get_mission_id"):
		return String(mission_node.call("get_mission_id"))
	if MissionAutoloadResolver.has_game_state():
		return String(GameState.current_mission_id)
	return ""


static func _mission_name(mission_id: String) -> String:
	if mission_id == "":
		return "Unknown mission"
	if MissionAutoloadResolver.has_game_state():
		return String(GameState.get_mission_info(mission_id).get("name", mission_id))
	return mission_id


static func _phase0k_controller(mission_node: Node) -> Node:
	if mission_node == null:
		return null
	return mission_node.get_node_or_null("GameplayRoot/RuntimeHelpers/Phase0KMissionCompletionController")


static func _node_bool(node: Node, property_name: String) -> bool:
	if node == null:
		return false
	var value: Variant = node.get(property_name)
	return bool(value) if value != null else false


static func _has_louis_route_available() -> bool:
	if not MissionAutoloadResolver.has_game_state():
		return false
	return GameState.has_scheme_card("louis_delivery_route") or GameState.has_selected_card("louis_delivery_route")


static func _beam_context_text(triggered: bool, bypassed: bool) -> String:
	if bypassed:
		return "Bypassed by Louis delivery route"
	if triggered:
		return "Tripped"
	return "Armed"
