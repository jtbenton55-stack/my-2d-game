@tool
class_name MessSpotNode
extends "res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd"

## Replan Packet 4: physical mess is evidence everyone can see right now.
## A mess spot is a world object NPCs can react to; cleaning it is a
## hold-interact that restores cleanliness, counts as a believable task
## (alibi), and -- with the Clorox protocol -- also wipes nearby paper traces.

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")

const CLOROX_CARD_ID := "clorox_wipe_protocol"
const CLOROX_DEFAULT_RADIUS := 96.0

@export_group("Mess")
@export_enum("spill", "broken_glass", "mud_prints", "knocked_display", "dog_poop") var mess_type: String = "spill"
## Cleanliness returned when this mess is cleaned (spawn already charged -1).
@export var cleanup_cleanliness_delta: int = 1
## Cleaning in public reads as janitor work: professionalism credit + alibi.
@export var count_as_believable_task: bool = true
@export var alibi_window_seconds: float = 6.0
## Radius in which cleaning also wipes paper traces. 0 = only with Clorox card.
@export var clean_traces_radius: float = 0.0
## Charge -1 cleanliness while this mess exists (skip for pre-authored set dressing).
@export var applies_mess_debt: bool = true
@export var hide_on_cleanup: bool = true

var cleaned: bool = false
var last_cleanup_result: Dictionary = {}


func _init() -> void:
	prompt_text = "Press E: Clean up"
	locked_prompt_text = "Can't clean this right now"
	preview_color = Color(0.62, 0.45, 0.25, 0.4)
	interact_duration = 1.2
	one_shot = true


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	add_to_group("mission_mess")
	if applies_mess_debt:
		SocialStealthAdapterScript.adjust_cleanliness(-1, build_context(null))


func _draw() -> void:
	super._draw()
	if Engine.is_editor_hint() or cleaned:
		return
	draw_circle(Vector2.ZERO, 10.0, Color(0.62, 0.45, 0.25, 0.55))
	draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 20, Color(0.45, 0.3, 0.15, 0.8), 2.0)


func get_mess_label() -> String:
	return mess_type


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result := super.activate(actor, reason)
	if not bool(result.get("ok", false)) or String(result.get("code", "")) != "activation_succeeded":
		return result
	last_cleanup_result = _apply_cleanup(actor)
	var details: Dictionary = (result.get("details", {}) as Dictionary).duplicate(true)
	details["cleanup_result"] = last_cleanup_result
	result["details"] = details
	last_activation_result = result
	return result


func clean_up(actor: Node = null) -> Dictionary:
	return activate(actor, "script")


func _apply_cleanup(actor: Node) -> Dictionary:
	cleaned = true
	var context := build_context(actor)
	SocialStealthAdapterScript.adjust_cleanliness(cleanup_cleanliness_delta, context)
	if count_as_believable_task:
		SocialStealthAdapterScript.complete_task("clean_%s" % String(mechanic_id), {"mess_type": mess_type}, context)
		SocialStealthAdapterScript.adjust_professionalism(1, context)
		_register_alibi_window()
	var traces_cleaned := _clean_nearby_traces(context)
	remove_from_group("mission_mess")
	if hide_on_cleanup:
		visible = false
		monitoring = false
		monitorable = false
	queue_redraw()
	EventBus.objective_updated.emit("Cleaned up the %s." % mess_type.replace("_", " "))
	return {
		"ok": true,
		"code": "mess_cleaned",
		"mess_type": mess_type,
		"traces_cleaned": traces_cleaned,
	}


func _register_alibi_window() -> void:
	if alibi_window_seconds <= 0.0 or get_tree() == null:
		return
	var runtime := get_tree().get_first_node_in_group("cover_meter_runtime")
	if runtime != null and runtime.has_method("register_alibi_window"):
		runtime.call("register_alibi_window", alibi_window_seconds)


func _clean_nearby_traces(context: Dictionary) -> Array:
	var radius := clean_traces_radius
	if radius <= 0.0 and _clorox_card_selected():
		radius = CLOROX_DEFAULT_RADIUS
	if radius <= 0.0:
		return []
	var mission_id := String(context.get("mission_id", ""))
	var cleaned_ids: Array = []
	for event in PaperTrailAdapterScript.get_trace_events(mission_id):
		if not event.has("position"):
			continue
		var trace_pos: Vector2 = event.get("position", Vector2.ZERO)
		if trace_pos.distance_to(global_position) > radius:
			continue
		var cleanup := PaperTrailAdapterScript.cleanup_traces(
			{"trace_id": String(event.get("trace_id", ""))},
			context
		)
		if bool(cleanup.get("ok", false)):
			cleaned_ids.append(String(event.get("trace_id", "")))
	return cleaned_ids


func _clorox_card_selected() -> bool:
	var game_state := _autoload_node("GameState")
	if game_state == null or not game_state.has_method("has_selected_card"):
		return false
	return bool(game_state.call("has_selected_card", CLOROX_CARD_ID))


func _autoload_node(autoload_name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null(autoload_name)


static func spawn_mess(parent: Node, mess_type_value: String, position: Vector2, options: Dictionary = {}) -> Node:
	var mess_script: Script = load("res://src/missions/iso/runtime/mess/MessSpotNode.gd") as Script
	var mess := mess_script.new() as Area2D
	mess.set("mess_type", mess_type_value)
	mess.set("mechanic_id", StringName("mess_%s_%d" % [mess_type_value, Time.get_ticks_msec()]))
	for key in options.keys():
		mess.set(String(key), options[key])
	parent.add_child(mess)
	mess.global_position = position
	return mess
