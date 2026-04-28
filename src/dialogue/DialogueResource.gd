class_name DialogueResource
extends Resource

@export var character_id: String = ""
@export var nodes: Dictionary = {}

func get_node_data(node_id: String) -> Dictionary:
	return nodes.get(node_id, {})
