@tool
extends Node2D

@export var show_previews := true
@export var runtime_enabled := true
@export var debug_authoring := false


func collect_beam_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for child in get_children():
		if child is Node2D and child.has_method("build_runtime_config"):
			out.append(child as Node2D)
	return out


func get_enabled_beam_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for author in collect_beam_authors():
		if bool(author.get("enabled")):
			out.append(author)
	return out


func collect_area_trigger_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	_collect_area_trigger_authors_deep(self, out)
	return out


func _collect_area_trigger_authors_deep(node: Node, out: Array[Node2D]) -> void:
	for child in node.get_children():
		if child is Node2D and child.has_method("setup_runtime_trigger"):
			if child.get("on_enter_event") != null:
				out.append(child as Node2D)
		if child.get_child_count() > 0:
			_collect_area_trigger_authors_deep(child, out)


func get_enabled_area_trigger_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for author in collect_area_trigger_authors():
		if bool(author.get("enabled")):
			out.append(author)
	return out


func collect_camera_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for child in get_children():
		if child is Node2D and child.get("camera_id") != null:
			out.append(child as Node2D)
	return out


func collect_guard_spawn_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for child in get_children():
		if child is Node2D and child.get("spawn_id") != null and child.has_method("on_security_event"):
			out.append(child as Node2D)
	return out


func get_enabled_guard_spawn_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for author in collect_guard_spawn_authors():
		if bool(author.get("enabled")):
			out.append(author)
	return out


func collect_patrol_route_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for child in get_children():
		if child is Node2D and child.has_method("get_patrol_points_global"):
			out.append(child as Node2D)
	return out


func get_enabled_patrol_route_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for author in collect_patrol_route_authors():
		if bool(author.get("enabled")):
			out.append(author)
	return out


func find_enabled_beam_author(beam_id: StringName) -> Node2D:
	var want := str(beam_id).strip_edges()
	if want == "":
		return null
	for author in collect_beam_authors():
		if not bool(author.get("enabled")):
			continue
		if str(author.get("beam_id")).strip_edges() == want:
			return author
	return null


func collect_effect_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for child in get_children():
		if child is Node2D and child.has_method("is_downstream_effect_author"):
			out.append(child as Node2D)
	return out


func get_enabled_effect_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for author in collect_effect_authors():
		if bool(author.get("enabled")):
			out.append(author)
	return out


func collect_door_lock_effect_authors() -> Array[Node2D]:
	return _collect_effect_authors_by_type("door_lock")


func collect_lockdown_effect_authors() -> Array[Node2D]:
	return _collect_effect_authors_by_type("lockdown")


func collect_objective_effect_authors() -> Array[Node2D]:
	return _collect_effect_authors_by_type("objective")


func collect_node_toggle_effect_authors() -> Array[Node2D]:
	return _collect_effect_authors_by_type("node_toggle")


func collect_effect_set_authors() -> Array[Node2D]:
	return _collect_effect_authors_by_type("effect_set")


func _collect_effect_authors_by_type(effect_type: String) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for author in collect_effect_authors():
		if author.has_method("get_effect_type") and str(author.call("get_effect_type")) == effect_type:
			out.append(author)
	return out


func find_patrol_route(route_id: StringName) -> Node2D:
	var want := str(route_id).strip_edges()
	if want == "":
		return null
	for author in collect_patrol_route_authors():
		if not bool(author.get("enabled")):
			continue
		if str(author.get("route_id")).strip_edges() == want:
			return author
	return null


func collect_collectible_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	_collect_collectible_authors_deep(self, out)
	return out


func _collect_collectible_authors_deep(node: Node, out: Array[Node2D]) -> void:
	for child in node.get_children():
		if child is Node2D and child.has_method("is_collectible_author"):
			if bool(child.call("is_collectible_author")):
				out.append(child as Node2D)
		if child.get_child_count() > 0:
			_collect_collectible_authors_deep(child, out)


func get_enabled_collectible_authors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for author in collect_collectible_authors():
		if bool(author.get("enabled")):
			out.append(author)
	return out


func count_collectible_authors_by_kind(kind: String) -> int:
	var want := kind.strip_edges()
	var n := 0
	for author in collect_collectible_authors():
		if not bool(author.get("enabled")):
			continue
		if author.has_method("get_author_kind") and str(author.call("get_author_kind")) == want:
			n += 1
	return n
