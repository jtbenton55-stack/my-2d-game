extends Node
class_name HideoutEvidenceBoardController

func get_panel_data(state_controller: Node = null, view_id: String = "summary") -> Dictionary:
	return {
		"title": "The Big Case",
		"body": get_panel_body(state_controller, view_id),
		"buttons": [
			{"id": "review_taco_bell_clues", "label": "Review Taco Bell Clues", "action": "show_evidence"},
			{"id": "mark_reviewed", "label": "Mark Board Reviewed", "action": "mark_evidence_reviewed"},
			{"id": "missing_evidence", "label": "View Missing Evidence", "action": "show_missing_evidence"},
			{"id": "back", "label": "Back", "action": "close"},
		],
	}

func get_panel_body(state_controller = null, view_id: String = "summary") -> String:
	var lines: Array[String] = [
		"The Big Case",
		"",
		"A larger pattern is forming.",
		"More pieces are connected.",
		"Something bigger is behind this.",
		"The map is becoming less comforting.",
		"The board is starting to argue back.",
		"",
		"Clues:",
	]
	var evidence := _evidence(state_controller)
	for clue_id in evidence.keys():
		var clue: Dictionary = evidence[clue_id]
		var state := String(clue.get("state", "unknown"))
		if view_id == "missing" and not (state in ["unknown", "known_missing", "missing"]):
			continue
		lines.append("- %s: %s" % [String(clue.get("display", clue_id)), state])
		if view_id == "details" or view_id == "missing":
			lines.append("  %s" % String(clue.get("description", "")))
	if state_controller != null and state_controller.get("clue_connections_reviewed"):
		lines.append("")
		lines.append("Reviewed: the pieces are not random anymore.")
	if view_id == "missing":
		lines.append("")
		lines.append("Missing evidence hints: silhouettes remain where sauce, route notes, and security paperwork should make everyone less comfortable.")
	elif view_id == "details":
		lines.append("")
		lines.append("Review notes: the delivery path, token, and paw-marked clue all point at a larger pattern without naming it yet.")
	else:
		lines.append("")
		lines.append("Use Review Taco Bell Clues or View Missing Evidence for a more focused board read.")
	return "\n".join(lines)

func mark_reviewed(state_controller: Node = null) -> void:
	if state_controller != null:
		state_controller.set("clue_connections_reviewed", true)

func _evidence(state_controller: Node = null) -> Dictionary:
	if state_controller != null and state_controller.has_method("get_evidence_state"):
		return state_controller.get_evidence_state()
	return {}
