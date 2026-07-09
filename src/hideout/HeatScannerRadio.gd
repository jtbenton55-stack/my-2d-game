class_name HeatScannerRadio
extends RefCounted

## Replan Packet 6: the hideout Heat Scanner is a diegetic police-band radio.
## It reads GameState venue heat (fed by Investigation Reports) per venue with
## a 0-5 dial and chatter lines, and offers cool-down shifts at venues the
## crew has already worked.

const MAX_HEAT := 5
const COOLDOWN_SHIFT_AMOUNT := 2


static func build_scanner_readout() -> Dictionary:
	var game_state := _game_state()
	if game_state == null:
		return {"venues": [], "text": "The radio crackles. Nothing but static.", "hottest_mission_id": ""}
	var venues: Array[Dictionary] = []
	var hottest_id := ""
	var hottest_heat := 0
	for mission_id in _known_venues(game_state):
		var heat := int(game_state.call("get_mission_heat", mission_id))
		venues.append({
			"mission_id": mission_id,
			"display_name": _pretty_name(mission_id),
			"heat": heat,
			"dial": _dial(heat),
			"chatter": _chatter(mission_id, heat),
			"can_cool_down": _can_cool_down(game_state, mission_id, heat),
		})
		if heat > hottest_heat:
			hottest_heat = heat
			hottest_id = mission_id
	venues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("heat", 0)) > int(b.get("heat", 0))
	)
	return {
		"venues": venues,
		"text": _readout_text(venues),
		"hottest_mission_id": hottest_id,
	}


static func run_cooldown_shift(mission_id: String) -> Dictionary:
	var game_state := _game_state()
	if game_state == null:
		return {"ok": false, "code": "game_state_missing", "message": "The radio is unplugged."}
	var mid := mission_id.strip_edges()
	if mid == "":
		return {"ok": false, "code": "mission_id_missing", "message": "Pick a venue first."}
	var completed: Array = game_state.get("completed_missions") if game_state.get("completed_missions") is Array else []
	if not completed.has(mid):
		return {"ok": false, "code": "venue_not_worked", "message": "You have never worked %s. Nothing to cool down." % _pretty_name(mid)}
	var heat_before := int(game_state.call("get_mission_heat", mid))
	if heat_before <= 0:
		return {"ok": false, "code": "venue_already_cool", "message": "%s is already quiet. Save the mop." % _pretty_name(mid)}
	game_state.call("cool_venue_heat", mid, COOLDOWN_SHIFT_AMOUNT)
	var heat_after := int(game_state.call("get_mission_heat", mid))
	return {
		"ok": true,
		"code": "cooldown_shift_complete",
		"message": "You work a quiet, spotless shift at %s. Believable tasks only. Heat %d -> %d." % [_pretty_name(mid), heat_before, heat_after],
		"heat_before": heat_before,
		"heat_after": heat_after,
	}


static func _readout_text(venues: Array[Dictionary]) -> String:
	if venues.is_empty():
		return "The radio crackles. No chatter about the crew. Yet."
	var text := "POLICE BAND - LIVE\n"
	for venue in venues:
		text += "\n%s  %s\n  \"%s\"\n" % [
			String(venue.get("dial", "")),
			String(venue.get("display_name", "")),
			String(venue.get("chatter", "")),
		]
	return text


static func _dial(heat: int) -> String:
	var clamped := clampi(heat, 0, MAX_HEAT)
	return "[%s%s]" % ["#".repeat(clamped), "-".repeat(MAX_HEAT - clamped)]


static func _chatter(_mission_id: String, heat: int) -> String:
	match clampi(heat, 0, MAX_HEAT):
		0:
			return "All quiet. Nothing to report."
		1:
			return "Minor incident logged. No leads."
		2:
			return "Units did a walkthrough. File stays open."
		3:
			return "Still investigating that establishment. Extra patrols requested."
		4:
			return "Detective assigned. They are asking about a dog."
		_:
			return "Full task force. Do NOT go back there yet."


static func _can_cool_down(game_state: Node, mission_id: String, heat: int) -> bool:
	if heat <= 0:
		return false
	var completed: Array = game_state.get("completed_missions") if game_state.get("completed_missions") is Array else []
	return completed.has(mission_id)


static func _known_venues(game_state: Node) -> Array[String]:
	var seen: Dictionary = {}
	var out: Array[String] = []
	var sources: Array = []
	if game_state.get("completed_missions") is Array:
		sources.append_array(game_state.get("completed_missions"))
	if game_state.get("venue_heat") is Dictionary:
		sources.append_array((game_state.get("venue_heat") as Dictionary).keys())
	if game_state.get("failed_attempts") is Dictionary:
		sources.append_array((game_state.get("failed_attempts") as Dictionary).keys())
	for value in sources:
		var mid := String(value).strip_edges()
		if mid == "" or seen.has(mid):
			continue
		seen[mid] = true
		out.append(mid)
	return out


static func _pretty_name(mission_id: String) -> String:
	var parts := mission_id.split("_")
	for i in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)


static func _game_state() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null("GameState")
