extends Phase0JInteractablePickup
## D6-06 authored collectible — uses Phase0J E-interact flow; defers persistence to mission commit.


func _payload() -> Dictionary:
	var payload := super._payload()
	payload["hideout_collection_key"] = String(get_meta("hideout_collection_key", ""))
	payload["collectible_type"] = String(get_meta("collectible_type", category))
	if has_meta("money_amount"):
		payload["amount"] = int(get_meta("money_amount"))
	if has_meta("currency_type"):
		payload["currency_type"] = String(get_meta("currency_type"))
	if has_meta("poop_count"):
		payload["poop_count"] = int(get_meta("poop_count"))
	if has_meta("polaroid_id"):
		payload["polaroid_id"] = String(get_meta("polaroid_id"))
	if has_meta("icon_id"):
		payload["icon_id"] = String(get_meta("icon_id"))
	if has_meta("glow_guy_id"):
		payload["glow_guy_id"] = String(get_meta("glow_guy_id"))
	if has_meta("clue_id"):
		payload["clue_id"] = String(get_meta("clue_id"))
	if has_meta("clue_title"):
		payload["clue_title"] = String(get_meta("clue_title"))
	if has_meta("clue_text"):
		payload["clue_text"] = String(get_meta("clue_text"))
	if has_meta("case_id"):
		payload["case_id"] = String(get_meta("case_id"))
	if has_meta("commits_as_case_cash"):
		payload["commits_as_case_cash"] = bool(get_meta("commits_as_case_cash"))
	return payload


func _collect_with_state_adapter() -> Dictionary:
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("record_authored_collectible_attempt"):
		var payload := _payload()
		payload["interaction_source"] = "phase0j_interact"
		payload["node_path"] = str(get_path())
		return mission.call("record_authored_collectible_attempt", candidate_id, category, payload, self)
	return super._collect_with_state_adapter()
