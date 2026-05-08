extends Node
class_name HideoutDialogicAdapter

const DialogueBank = preload("res://src/hideout/HideoutDialogueBank.gd")

static func is_dialogic_available(tree: SceneTree = null) -> bool:
	if Engine.has_singleton("Dialogic"):
		return true
	if tree != null and tree.root.get_node_or_null("Dialogic") != null:
		return true
	return ResourceLoader.exists("res://addons/dialogic/plugin.cfg")

static func line_for(context_id: String, state_id: String = "", tree: SceneTree = null) -> String:
	if is_dialogic_available(tree):
		var timeline_path := _timeline_path(context_id, state_id)
		if timeline_path != "" and ResourceLoader.exists(timeline_path):
			return "Dialogic timeline ready: %s" % timeline_path
	return DialogueBank.get_random_line(context_id, state_id)

static func start_timeline_or_fallback(context_id: String, state_id: String = "", tree: SceneTree = null) -> String:
	var timeline_path := _timeline_path(context_id, state_id)
	if timeline_path != "" and ResourceLoader.exists(timeline_path) and tree != null:
		var dialogic := tree.root.get_node_or_null("Dialogic")
		if dialogic != null and dialogic.has_method("start"):
			dialogic.start(timeline_path)
			return ""
	return DialogueBank.get_random_line(context_id, state_id)

static func _timeline_path(context_id: String, state_id: String = "") -> String:
	var key := context_id if state_id == "" else "%s_%s" % [context_id, state_id]
	var timeline_map := {
		"jake_fresh": "res://dialogic/timelines/hideout/jake_fresh.dtl",
		"jake_taco_bell_completed": "res://dialogic/timelines/hideout/jake_taco_bell_completed.dtl",
		"jake_high_heat": "res://dialogic/timelines/hideout/jake_high_heat.dtl",
		"mere_fresh": "res://dialogic/timelines/hideout/mere_fresh.dtl",
		"mere_taco_bell_completed": "res://dialogic/timelines/hideout/mere_taco_bell_completed.dtl",
		"mere_high_heat": "res://dialogic/timelines/hideout/mere_high_heat.dtl",
		"bentley_bed_fresh": "res://dialogic/timelines/hideout/bentley_general.dtl",
		"louis_unlocked": "res://dialogic/timelines/hideout/louis_unlocked.dtl",
	}
	return String(timeline_map.get(key, ""))
