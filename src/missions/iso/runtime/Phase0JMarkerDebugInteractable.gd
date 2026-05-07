@tool
class_name Phase0JMarkerDebugInteractable
extends Area2D

@export var marker_id: String = ""
@export var category: String = "DEBUG"
@export var subcategory: String = ""
@export_multiline var deferred_mechanic: String = "Debug marker. Final mechanic deferred."
@export var prompt_text: String = "Inspect marker"
@export var debug_hud_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JDebugHUD")
@export var mission_state_adapter_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JMissionStateAdapter")
@export var mechanic_router_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JMechanicRouter")
@export var interaction_priority: int = 250
@export var debug_enabled := true


func _ready() -> void:
	add_to_group("phase0j_marker_debug")
	add_to_group("phase0j_interactable")
	add_to_group("interactable")
	collision_layer = 8
	collision_mask = 1
	set_meta("generated_by", "Phase0J-C2")
	set_meta("marker_id", marker_id)
	set_meta("category", category)


func interact(player: Node = null) -> bool:
	return inspect_marker(player)


func on_interact(player: Node = null) -> bool:
	return inspect_marker(player)


func use(player: Node = null) -> bool:
	return inspect_marker(player)


func inspect_marker(_player: Node = null) -> bool:
	var router := get_node_or_null(mechanic_router_path)
	if router != null and router.has_method("route_marker"):
		router.call("route_marker", marker_id, category, {
			"subcategory": subcategory,
			"deferred_mechanic": deferred_mechanic,
		})
		return true
	var text := "%s - %s marker. %s" % [marker_id, category, deferred_mechanic]
	var adapter := get_node_or_null(mission_state_adapter_path)
	if adapter != null and adapter.has_method("inspect_marker"):
		adapter.call("inspect_marker", marker_id, category, {"deferred_mechanic": deferred_mechanic})
	var hud := get_node_or_null(debug_hud_path)
	if hud != null:
		if hud.has_method("show_message"):
			hud.call("show_message", text, 4.0)
		if hud.has_method("increment_inspected"):
			hud.call("increment_inspected", category)
	if debug_enabled:
		print("[Phase0J-C2] " + text)
	return true


func is_interaction_available(_player: Node = null) -> bool:
	return true


func should_show_interaction_prompt() -> bool:
	return true


func get_interaction_priority(_player: Node = null) -> int:
	return interaction_priority


func is_completed() -> bool:
	return false
