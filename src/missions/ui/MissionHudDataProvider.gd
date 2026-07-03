class_name MissionHudDataProvider
extends RefCounted
## Read-only mission HUD payload for player-facing compact strip (0M-D5-02B). Does not mutate GameState, Player, or mission nodes.


const _MAX_OBJECTIVE_CHARS := 160


static func sanitize_objective_line(raw: String) -> String:
	var s := String(raw).strip_edges()
	if s == "":
		return "Follow the mission goals."
	if s == "No active objective.":
		return "No objective text yet. Check the pause menu for details."
	if _looks_like_internal_objective(s):
		return "Follow the mission goals."
	# Drop internal-looking noise but keep normal sentences.
	var cleaned := s
	if cleaned.length() > _MAX_OBJECTIVE_CHARS:
		cleaned = cleaned.substr(0, _MAX_OBJECTIVE_CHARS - 1) + "…"
	return cleaned


static func _looks_like_internal_objective(s: String) -> bool:
	var t := String(s).strip_edges()
	if t == "":
		return false
	if t.contains("uid://"):
		return true
	if t.contains("res://"):
		return true
	if t.contains("::") and (t.contains("(") or t.contains(")")):
		return true
	return false


static func get_hud_payload(_context_node: Node = null) -> Dictionary:
	var warnings: Array[String] = []
	if not MissionAutoloadResolver.has_game_state():
		return {
			"ok": false,
			"mission_id": "",
			"objective_text": "Follow the mission goals.",
			"stamina_current": 0.0,
			"stamina_max": 100.0,
			"stamina_visible": false,
			"stamina_fallback": false,
			"poop_bags_available": 0,
			"poop_bags_collected_this_attempt": 0,
			"poop_bag_bonus_target": 3,
			"poop_bag_status_text": "",
			"poop_bags_visible": false,
			"control_hint": "",
			"warnings": ["GameState unavailable"],
		}
	var mid := String(GameState.current_mission_id)
	var in_mission := GameState.is_in_mission
	var obj := ""
	var next_obj := MissionPauseDataProvider.get_next_objective_text(mid, _context_node)
	if next_obj != "":
		obj = next_obj
	elif MissionAutoloadResolver.get_root_autoload("QuestManager") != null:
		obj = String(QuestManager.get_current_objective(mid))
	obj = sanitize_objective_line(obj)
	var stamina_cur := 0.0
	var stamina_max := 100.0
	var stamina_vis := false
	var stamina_fallback := false
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var pnode := tree.get_first_node_in_group("player")
		if pnode != null and pnode.has_method("get_sprint_runtime_debug"):
			var dbg: Dictionary = pnode.call("get_sprint_runtime_debug")
			# Player.get_sprint_runtime_debug() replaces the initial {"ok": ...} dict with the stamina
			# controller chain dict, which does not re-include "ok" — so never rely on ok alone.
			var chain_ok := bool(dbg.get("ok", false))
			var has_stamina_snapshot := dbg.has("current_stamina") and dbg.has("max_stamina")
			if chain_ok or has_stamina_snapshot:
				stamina_cur = float(dbg.get("current_stamina", 0.0))
				stamina_max = maxf(1.0, float(dbg.get("max_stamina", 100.0)))
				stamina_vis = in_mission
			elif in_mission:
				stamina_vis = true
				stamina_cur = 100.0
				stamina_max = 100.0
				stamina_fallback = true
				warnings.append("stamina_bar_placeholder_no_runtime_snapshot")
		elif in_mission:
			stamina_vis = true
			stamina_cur = 100.0
			stamina_max = 100.0
			stamina_fallback = true
			warnings.append("stamina_bar_placeholder_no_player_node")
	var poop_status := GameState.get_poop_bag_bonus_status(mid) if GameState.has_method("get_poop_bag_bonus_status") else {}
	var poop := int(GameState.get_poop_bag_count()) if GameState.has_method("get_poop_bag_count") else int(GameState.poop_bag_count)
	var poop_collected := int(poop_status.get("collected_this_attempt", GameState.poop_bags_this_mission_attempt))
	var poop_target := int(poop_status.get("target", 3))
	var poop_vis := in_mission
	var hint := "Ctrl sprint · Space dash · T bag · Esc pause"
	return {
		"ok": true,
		"mission_id": mid,
		"objective_text": obj,
		"stamina_current": stamina_cur,
		"stamina_max": stamina_max,
		"stamina_visible": stamina_vis,
		"stamina_fallback": stamina_fallback,
		"poop_bags_available": poop,
		"poop_bags_collected_this_attempt": poop_collected,
		"poop_bag_bonus_target": poop_target,
		"poop_bag_status_text": String(poop_status.get("line", "")),
		"poop_bags_visible": poop_vis,
		"control_hint": hint,
		"warnings": warnings,
	}
