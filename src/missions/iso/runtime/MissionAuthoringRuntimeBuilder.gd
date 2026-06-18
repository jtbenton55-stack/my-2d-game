extends RefCounted

## Wires SecurityAuthoringRoot children to mission-local SecurityEventRouter at runtime.


static func setup(mission: Node, authoring_root: Node2D) -> Node:
	if mission == null or authoring_root == null:
		return null
	var router := _ensure_router_on_mission(mission)
	if router == null:
		return null
	_register_guard_spawn_listeners(router, authoring_root)
	_register_effect_listeners(router, authoring_root, mission)
	_setup_area_triggers(mission, router, authoring_root)
	_setup_authored_cameras(mission, router, authoring_root)
	_store_effect_author_counts(mission, authoring_root)
	return router


static func _ensure_router_on_mission(mission: Node) -> Node:
	if mission.has_method("get_security_event_router"):
		var existing: Variant = mission.call("get_security_event_router")
		if existing is Node:
			return existing as Node
	var systems := mission.get_node_or_null("GameplayRoot/RuntimeSystems")
	if systems == null:
		systems = mission
	var router := systems.get_node_or_null("SecurityEventRouter")
	if router == null:
		router = load("res://src/missions/iso/runtime/SecurityEventRouter.gd").new()
		router.name = "SecurityEventRouter"
		systems.add_child(router)
	if mission.has_method("set_security_event_router"):
		mission.call("set_security_event_router", router)
	return router


static func _register_guard_spawn_listeners(router: Node, authoring_root: Node2D) -> void:
	if not authoring_root.has_method("collect_guard_spawn_authors"):
		return
	var spawns: Array = authoring_root.call("collect_guard_spawn_authors")
	for author in spawns:
		if author == null or not (author is Node):
			continue
		if not bool(author.get("enabled")):
			continue
		var events_v: Variant = author.get("trigger_events")
		if not (events_v is Array):
			continue
		for ev in events_v as Array:
			var eid := String(ev).strip_edges()
			if eid != "":
				router.call("register_listener", StringName(eid), author as Node)


static func _setup_area_triggers(mission: Node, router: Node, authoring_root: Node2D) -> void:
	if not authoring_root.has_method("collect_area_trigger_authors"):
		return
	var triggers: Array = authoring_root.call("collect_area_trigger_authors")
	for author in triggers:
		if author == null or not (author is Node2D):
			continue
		if author.get("enabled") != null and not bool(author.get("enabled")):
			continue
		if author.has_method("setup_runtime_trigger"):
			author.call("setup_runtime_trigger", mission, router)


static func _register_effect_listeners(router: Node, authoring_root: Node2D, mission: Node) -> void:
	if not authoring_root.has_method("collect_effect_authors"):
		return
	var effects: Array = authoring_root.call("collect_effect_authors")
	for author in effects:
		if author == null or not (author is Node):
			continue
		if not bool(author.get("enabled")):
			continue
		if author.has_method("bind_mission"):
			author.call("bind_mission", mission)
		var events_v: Variant = author.get("trigger_events")
		if not (events_v is Array):
			continue
		for ev in events_v as Array:
			var eid := String(ev).strip_edges()
			if eid != "":
				router.call("register_listener", StringName(eid), author as Node)


static func _store_effect_author_counts(mission: Node, authoring_root: Node2D) -> void:
	if mission == null or not mission.has_method("_store_d6_05_effect_author_counts"):
		return
	var door_n := 0
	var lockdown_n := 0
	var objective_n := 0
	var toggle_n := 0
	var effect_set_n := 0
	if authoring_root.has_method("collect_door_lock_effect_authors"):
		door_n = authoring_root.call("collect_door_lock_effect_authors").size()
	if authoring_root.has_method("collect_lockdown_effect_authors"):
		lockdown_n = authoring_root.call("collect_lockdown_effect_authors").size()
	if authoring_root.has_method("collect_objective_effect_authors"):
		objective_n = authoring_root.call("collect_objective_effect_authors").size()
	if authoring_root.has_method("collect_node_toggle_effect_authors"):
		toggle_n = authoring_root.call("collect_node_toggle_effect_authors").size()
	if authoring_root.has_method("collect_effect_set_authors"):
		effect_set_n = authoring_root.call("collect_effect_set_authors").size()
	mission.call("_store_d6_05_effect_author_counts", door_n, lockdown_n, objective_n, toggle_n)
	if mission.has_method("_store_d6_05_effect_set_author_count"):
		mission.call("_store_d6_05_effect_set_author_count", effect_set_n)


static func _setup_authored_cameras(mission: Node, router: Node, authoring_root: Node2D) -> void:
	if not authoring_root.has_method("collect_camera_authors"):
		return
	var cameras: Array = authoring_root.call("collect_camera_authors")
	for author in cameras:
		if author == null or not (author is Node2D):
			continue
		if not bool(author.get("enabled")):
			continue
		if author.has_method("setup_runtime_camera"):
			author.call("setup_runtime_camera", mission, router)
