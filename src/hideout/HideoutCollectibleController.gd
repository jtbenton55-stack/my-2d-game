extends Node
class_name HideoutCollectibleController

const DISPLAY_MAP := {
	"polaroid_wall": ["polaroid_taco_bell"],
	"glow_guy_shelf": ["glow_guy_taco_bell"],
	"tiny_icon_shelf": ["tiny_icon_sauce_packet", "tiny_icon_drive_thru_bell"],
	"poop_bag_care_display": ["poop_bag_fire_sauce_roll"],
	"mission_trophy_display": ["trophy_taco_bell_drop"],
}

func get_panel_data(station_id: String, state_controller: Node = null, view_id: String = "summary") -> Dictionary:
	return {
		"title": _title_for(station_id),
		"body": get_panel_body(station_id, state_controller, view_id),
		"buttons": [
			{"id": "view_found", "label": "View Found", "action": "show_collection", "view": "found"},
			{"id": "view_missing", "label": "View Missing", "action": "show_collection", "view": "missing"},
			{"id": "arrange_later", "label": "Arrange Later", "action": "show_collection", "view": "arrange"},
			{"id": "back", "label": "Back", "action": "close"},
		],
	}

func get_panel_body(station_id: String, state_controller = null, view_id: String = "summary") -> String:
	match station_id:
		"polaroid_wall":
			return _display_body(station_id, "Polaroid Wall", state_controller, view_id)
		"glow_guy_shelf":
			return _display_body(station_id, "Glow Guy Shelf", state_controller, view_id)
		"tiny_icon_shelf":
			return _display_body(station_id, "Tiny Icon Shelf", state_controller, view_id)
		"poop_bag_care_display":
			return _display_body(station_id, "Poop Bag Display", state_controller, view_id)
		_:
			return "Collectible display scaffold."

func _display_body(station_id: String, title: String, state_controller: Node = null, view_id: String = "summary") -> String:
	var lines: Array[String] = [title, ""]
	if view_id == "arrange":
		return "%s\n\nDecoration placement comes in a later pass." % title
	var collectibles: Dictionary = _collectibles(state_controller)
	for item_id in DISPLAY_MAP.get(station_id, []):
		var item: Dictionary = collectibles.get(item_id, {})
		var found := bool(item.get("found", false))
		if view_id == "found" and not found:
			continue
		if view_id == "missing" and found:
			continue
		lines.append("- %s: %s" % [String(item.get("display", item_id)), "Found" if found else "Missing"])
		lines.append("  %s" % String(item.get("found_text" if found else "missing_text", "")))
	if lines.size() == 2:
		lines.append("No entries in this filtered view yet.")
	if state_controller != null and String(state_controller.get("heat_state")) == "high":
		lines.append("")
		lines.append("High heat warning: the display lights look more accusatory than usual.")
	return "\n".join(lines)

func _collectibles(state_controller: Node = null) -> Dictionary:
	if state_controller != null and state_controller.has_method("get_collectible_state"):
		return state_controller.get_collectible_state()
	return {}

func _title_for(station_id: String) -> String:
	match station_id:
		"polaroid_wall":
			return "Polaroid Wall"
		"glow_guy_shelf":
			return "Glow Guy Shelf"
		"tiny_icon_shelf":
			return "Tiny Icon Shelf"
		"poop_bag_care_display":
			return "Poop Bag Display"
		_:
			return "Collectible Display"
