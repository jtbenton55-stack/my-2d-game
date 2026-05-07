extends Area2D
class_name HideoutInteractable

signal interacted(interactable_id: String)

@export var interactable_id := ""
@export var station_id := ""
@export var display_name := ""
@export var station_type := "panel"
@export_multiline var prompt_text := "Press E to interact"
@export var panel_title := ""
@export_multiline var panel_body := ""
@export var panel_buttons: Array = []
@export var manager_path: NodePath
@export var interaction_radius := 144.0
@export var interaction_priority := 120
@export var enabled_in_fresh := true
@export var enabled_in_louis_unlocked := true
@export var disabled := false

var _manager: Node = null

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("hideout_interactable")
	add_to_group("hideout_station")
	monitoring = true
	monitorable = true
	_manager = get_node_or_null(manager_path) if manager_path != NodePath("") else _find_manager()

func is_interaction_available(player: Node = null) -> bool:
	if disabled or not visible:
		return false
	if player is Node2D:
		return global_position.distance_to((player as Node2D).global_position) <= interaction_radius
	return true

func should_show_interaction_prompt() -> bool:
	return visible and not disabled

func get_interaction_priority(_player: Node = null) -> int:
	return interaction_priority

func is_completed() -> bool:
	return false

func interact(player: Node = null) -> void:
	if not is_interaction_available(player):
		return
	var key := station_id if station_id != "" else interactable_id
	interacted.emit(key)
	if _manager == null:
		_manager = _find_manager()
	if _manager != null and _manager.has_method("open_station"):
		_manager.call("open_station", key, self, player)
		return
	var panel := _find_panel()
	if panel != null and panel.has_method("open_panel"):
		panel.call("open_panel", panel_title if panel_title != "" else display_name, panel_body, panel_buttons)
		return
	push_warning("HideoutInteractable could not route station '%s' from %s" % [key, get_path()])

func get_prompt_text() -> String:
	return prompt_text if prompt_text != "" else "Press E: " + display_name

func _find_manager() -> Node:
	var managers := get_tree().get_nodes_in_group("hideout_manager")
	return managers[0] if not managers.is_empty() else null

func _find_panel() -> Node:
	var root := get_tree().current_scene
	if root != null:
		var panel := root.get_node_or_null("UI/ScrollableStationPanel")
		if panel != null:
			return panel
	return null
