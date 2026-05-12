class_name MissionAutoloadResolver
extends RefCounted
## Resolves /root autoload nodes from static RefCounted helpers. Godot 4 autoloads are NOT Engine.has_singleton().


static func get_root_autoload(autoload_name: String) -> Node:
	if autoload_name.strip_edges() == "":
		return null
	var ml := Engine.get_main_loop()
	if ml == null or not (ml is SceneTree):
		return null
	var root := (ml as SceneTree).root
	if root == null:
		return null
	return root.get_node_or_null(NodePath(autoload_name))


static func has_game_state() -> bool:
	return get_root_autoload("GameState") != null


static func has_card_manager() -> bool:
	return get_root_autoload("CardManager") != null
