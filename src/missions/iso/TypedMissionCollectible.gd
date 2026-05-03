class_name TypedMissionCollectible
extends RefCounted

const FLAG_PREFIX := "mission_collectible:"


static func collect(
	collectible_id: String,
	collectible_type: String,
	mission_id: String,
	display_name: String = ""
) -> bool:
	if collectible_id == "":
		return false
	var flag_key := FLAG_PREFIX + collectible_id
	if bool(GameState.dialogue_flags.get(flag_key, false)):
		return false
	match collectible_type:
		"polaroid":
			CollectibleManager.collect_polaroid(collectible_id)
		"poop_bag":
			GameState.add_poop_bag()
		"evidence_clue":
			GameState.ensure_and_discover_sterling_clue(collectible_id, {
				"title": display_name if display_name != "" else collectible_id.capitalize(),
				"description": "Placeholder evidence clue from " + mission_id + ".",
				"category": "Mission Bible",
				"mission_id": mission_id,
				"connects_to": "Sterling Tower",
				"unlocks_or_modifies": "Final tower dependency",
			})
		_:
			# Glow Guys / Desk Spirits / Tiny Icons / Shelf Goblins are tracked as saved flags for now.
			pass
	GameState.record_typed_collectible(collectible_id, collectible_type, {
		"mission_id": mission_id,
		"display_name": display_name if display_name != "" else collectible_id.capitalize(),
		"collection_group": collectible_type,
		"hidden": collectible_type == "polaroid" and collectible_id.contains("hidden"),
	})
	if mission_id != "":
		GameState.record_mission_performance_event(mission_id, "collectibles_found", 1)
	GameState.dialogue_flags[flag_key] = true
	EventBus.game_state_changed.emit()
	return true
