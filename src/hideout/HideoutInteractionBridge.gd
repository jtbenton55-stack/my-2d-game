extends Node
class_name HideoutInteractionBridge

@export var player_path: NodePath
@export var radius := 144.0
@export var debug_enabled := true

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _panel_is_open():
		return
	var player := _find_player()
	if player == null:
		return
	var nearest := _nearest_interactable(player)
	if nearest == null:
		return
	var distance := player.global_position.distance_to(nearest.global_position)
	if debug_enabled:
		var station_key := String(nearest.get("station_id")) if _has_property(nearest, "station_id") else String(nearest.get_meta("station_id", nearest.name))
		print("[HideoutInteractionBridge] Interacting with %s at distance %.1f" % [station_key, distance])
	nearest.call("interact", player)
	get_viewport().set_input_as_handled()

func _panel_is_open() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var panel := scene.get_node_or_null("UI/ScrollableStationPanel")
	return panel != null and panel.visible

func _find_player() -> Node2D:
	if player_path != NodePath(""):
		var direct := get_node_or_null(player_path)
		if direct is Node2D:
			return direct
	var grouped := get_tree().get_first_node_in_group("player")
	if grouped is Node2D:
		return grouped
	var scene := get_tree().current_scene
	if scene != null:
		var by_path := scene.get_node_or_null("GameplayRoot/Characters/Player")
		if by_path is Node2D:
			return by_path
		var by_name := scene.find_child("Player", true, false)
		if by_name is Node2D:
			return by_name
	return null

func _nearest_interactable(player: Node2D) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("hideout_interactable"):
		if not (node is Node2D):
			continue
		if not node.visible:
			continue
		if not node.has_method("interact"):
			continue
		if node.has_method("is_interaction_available") and not bool(node.call("is_interaction_available", player)):
			continue
		var distance := player.global_position.distance_to(node.global_position)
		if distance > radius:
			continue
		if distance < best_distance:
			best = node
			best_distance = distance
	return best

func _has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false
