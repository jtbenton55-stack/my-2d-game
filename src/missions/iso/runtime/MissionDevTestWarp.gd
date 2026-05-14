extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"
## D6_FIX4_TEMP_TEST_WARP_REMOVE_IN_FINAL_LEVEL_PASS — dev-only E-interact warp to garage code area.


func _ready() -> void:
	once_only = false
	allow_repeat_interaction = true
	interaction_priority = 125
	interaction_text = "Garage Test Warp: press E to jump to the keypad test spot."
	display_name = "Garage Test Warp"
	super._ready()
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 38.0
	shape.shape = circ
	add_child(shape)
	_add_purple_warp_ring()
	var tag := Label.new()
	tag.name = "WarpLabel"
	tag.text = "Garage Test Warp\n(E)"
	tag.position = Vector2(-52, -58)
	tag.add_theme_font_size_override("font_size", 11)
	add_child(tag)
	set_meta("D6_FIX4_TEMP_TEST_WARP_REMOVE_IN_FINAL_LEVEL_PASS", true)


func _add_purple_warp_ring() -> void:
	var fill := Polygon2D.new()
	fill.name = "D6_FIX4_TEMP_WARP_VISUAL_REMOVE_IN_FINAL_LEVEL_PASS"
	fill.z_index = 50
	fill.color = Color(0.62, 0.18, 0.95, 0.62)
	var pts := PackedVector2Array()
	var steps := 22
	var r := 40.0
	for i in range(steps):
		var t := TAU * float(i) / float(steps)
		pts.append(Vector2(cos(t), sin(t)) * r)
	fill.polygon = pts
	add_child(fill)


func interact(player: Node) -> void:
	if not is_interaction_available(player):
		return
	if player is Node2D:
		(player as Node2D).global_position = resolve_garage_warp_position(get_tree().current_scene)
	if has_node("/root/EventBus"):
		EventBus.debug("D6_FIX4_TEMP_TEST_WARP_REMOVE_IN_FINAL_LEVEL_PASS: garage code warp used")


static func resolve_garage_warp_position(scene: Node) -> Vector2:
	if scene == null:
		return Vector2.ZERO
	var zone := scene.get_node_or_null("GameplayRoot/GeneratedRuntimeInteractables/Interactable_SAFE_CODE_INPUT_ZONE")
	if zone is Node2D:
		return (zone as Node2D).global_position + Vector2(0, 56)
	var lbl := scene.get_node_or_null("GameplayRoot/GeneratedRuntimeMarkerLabels/Label_SAFE_CODE_INPUT_ZONE")
	if lbl is Node2D:
		return (lbl as Node2D).global_position + Vector2(0, 56)
	return Vector2.ZERO
