class_name TypedMissionCollectible
extends RefCounted

const FLAG_PREFIX := "mission_collectible:"


static func collect(
	collectible_id: String,
	collectible_type: String,
	mission_id: String,
	display_name: String = ""
) -> bool:
	var normalized_id := String(collectible_id).strip_edges()
	var normalized_type := String(collectible_type).strip_edges()
	if normalized_id == "" or normalized_type == "":
		return false
	var flag_key := FLAG_PREFIX + normalized_id
	if GameState.dialogue_flags.get(flag_key, false) == true:
		return false
	if GameState.typed_collectibles.has(normalized_id):
		var existing: Dictionary = GameState.typed_collectibles.get(normalized_id, {})
		if existing.get("discovered", false) == true:
			return false
	match normalized_type:
		"polaroid":
			CollectibleManager.collect_polaroid(normalized_id)
		"poop_bag":
			GameState.add_poop_bag()
		"evidence_clue":
			GameState.ensure_and_discover_sterling_clue(normalized_id, {
				"title": display_name if display_name != "" else normalized_id.capitalize(),
				"description": "Placeholder evidence clue from " + mission_id + ".",
				"category": "Mission Bible",
				"mission_id": mission_id,
				"connects_to": "Sterling Tower",
				"unlocks_or_modifies": "Final tower dependency",
			})
		_:
			# Glow Guys / Desk Spirits / Tiny Icons / Shelf Goblins are tracked as saved flags for now.
			pass
	GameState.record_typed_collectible(normalized_id, normalized_type, {
		"mission_id": mission_id,
		"display_name": display_name if display_name != "" else normalized_id.capitalize(),
		"collectible_type": normalized_type,
		"collection_group": normalized_type,
		"discovered": true,
		"hidden": normalized_type == "polaroid" and normalized_id.contains("hidden"),
	})
	if mission_id != "":
		GameState.record_mission_performance_event(mission_id, "collectibles_found", 1)
		var scene: Node = null
		if Engine.get_main_loop() is SceneTree:
			scene = (Engine.get_main_loop() as SceneTree).current_scene
		if scene != null and scene.has_method("increment_attempt_counter"):
			match normalized_type:
				"tiny_icon":
					scene.call("increment_attempt_counter", "tiny_icon", 1)
				"glow_guy":
					scene.call("increment_attempt_counter", "glow_guy", 1)
				"polaroid":
					scene.call("increment_attempt_counter", "polaroid", 1)
				"poop_bag":
					scene.call("increment_attempt_counter", "poop_bags_collected", 1)
	GameState.dialogue_flags[flag_key] = true
	EventBus.game_state_changed.emit()
	return true
