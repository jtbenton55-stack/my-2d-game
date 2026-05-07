extends Node
class_name HideoutCareController

var flags := {
	"bentley_wiped": false,
	"bentley_brushed": false,
	"treat_packed": false,
	"poop_bags_stocked": false,
}

func get_panel_data(state_controller: Node = null) -> Dictionary:
	return {
		"title": "Bentley Care Station",
		"body": get_panel_body(state_controller),
		"buttons": [
			{"id": "wipe_paws", "label": "Wipe Paws", "action": "care_wipe_paws"},
			{"id": "give_treat", "label": "Give Treat", "action": "care_give_treat"},
			{"id": "brush_bentley", "label": "Brush Bentley", "action": "care_brush"},
			{"id": "restock_poop_bags", "label": "Restock Poop Bags", "action": "care_restock_poop_bags"},
			{"id": "view_poop_bags", "label": "View Poop Bag Collection", "action": "care_view_poop_bags"},
			{"id": "back", "label": "Back", "action": "close"},
		],
	}

func get_panel_body(state_controller = null) -> String:
	var care := _care_state(state_controller)
	var lines: Array[String] = [
		"Bentley Care Station",
		"",
		"Current mood: %s" % String(care.get("bentley_mood", "curious")).capitalize(),
		"",
		"Care Checklist:",
		"- Paws wiped: %s" % _yes(care.get("bentley_wiped", false)),
		"- Brushed: %s" % _yes(care.get("bentley_brushed", false)),
		"- Treat packed: %s" % _yes(care.get("treat_packed", false)),
		"- Poop bags stocked: %s" % _yes(care.get("poop_bags_stocked", false)),
		"- Sauce paw cleanup available: %s" % _yes(care.get("sauce_paw_cleanup_available", false)),
		"",
		"Care tools: wipes, poop bag supply, treat jar, brush, towel, leash hook.",
	]
	return "\n".join(lines)

func wipe_paws(state_controller: Node = null) -> String:
	flags["bentley_wiped"] = true
	if state_controller != null:
		state_controller.set("bentley_wiped", true)
		state_controller.set("bentley_mood", "relieved")
	return "Paws wiped. No crime feet on the couch."

func give_treat(state_controller: Node = null) -> String:
	flags["treat_packed"] = true
	if state_controller != null:
		state_controller.set("treat_packed", true)
		state_controller.set("bentley_mood", "focused")
	return "Bentley accepts the treat with the seriousness of a witness protection deal."

func brush_bentley(state_controller: Node = null) -> String:
	flags["bentley_brushed"] = true
	if state_controller != null:
		state_controller.set("bentley_brushed", true)
		state_controller.set("bentley_mood", "fluffy")
	return "Bentley has been brushed. The operation is now 12% softer."

func restock_poop_bags(state_controller: Node = null) -> String:
	flags["poop_bags_stocked"] = true
	if state_controller != null:
		state_controller.set("poop_bags_stocked", true)
	return "Poop bags restocked. Tactical readiness improved."

func poop_bag_summary(state_controller: Node = null) -> String:
	var collection := {}
	if state_controller != null and state_controller.has_method("get_collectible_state"):
		collection = state_controller.get_collectible_state()
	var item: Dictionary = collection.get("poop_bag_fire_sauce_roll", {})
	return "Poop Bag Collection\n\n- %s: %s\n  %s" % [String(item.get("display", "Fire Sauce Emergency Roll")), "Found" if item.get("found", false) else "Missing", String(item.get("found_text" if item.get("found", false) else "missing_text", "Standard bags are stocked."))]

func _care_state(state_controller: Node = null) -> Dictionary:
	if state_controller != null and state_controller.has_method("get_care_state"):
		return state_controller.get_care_state()
	return flags.duplicate()

func _yes(value) -> String:
	return "yes" if bool(value) else "no"
