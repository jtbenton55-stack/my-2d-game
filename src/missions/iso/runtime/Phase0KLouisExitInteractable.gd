@tool
class_name Phase0KLouisExitInteractable
extends Area2D

@export var completion_controller_path: NodePath = NodePath("../../RuntimeHelpers/Phase0KMissionCompletionController")
@export var debug_hud_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JDebugHUD")
@export var interaction_priority := 900

var _label: Label


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("phase0k_louis_exit")
	collision_layer = 8
	collision_mask = 1
	set_meta("generated_by", "Phase0K")
	set_meta("marker_id", "LOUIS_exit_token")
	_build_visual()


func interact(player: Node = null) -> bool:
	return _do_interact(player)


func on_interact(player: Node = null) -> bool:
	return _do_interact(player)


func use(player: Node = null) -> bool:
	return _do_interact(player)


func get_interaction_priority(_player: Node = null) -> int:
	return interaction_priority


func is_interaction_available(_player: Node = null) -> bool:
	return true


func should_show_interaction_prompt() -> bool:
	return true


func is_completed() -> bool:
	return false


func get_interaction_text() -> String:
	return "Talk to Louis"


func _do_interact(_player: Node = null) -> bool:
	var controller := get_node_or_null(completion_controller_path)
	if controller == null:
		_show("Louis: Exit check unavailable.")
		return true
	if controller.has_method("are_exit_requirements_met") and bool(controller.call("are_exit_requirements_met")):
		_show("Louis: You got the bag. Let's get out of here.")
		if controller.has_method("complete_mission_and_exit"):
			controller.call("complete_mission_and_exit")
		elif controller.has_method("unlock_exit"):
			controller.call("unlock_exit")
		return true
	var missing: Array = controller.call("get_missing_requirements") if controller.has_method("get_missing_requirements") else []
	_show("Louis: Exit's locked until we get the bag and finish the job. Missing: %s" % ", ".join(missing))
	return true


func _build_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 44
		shape.shape = circle
		add_child(shape)
	var token := Polygon2D.new()
	token.name = "LouisToken"
	token.color = Color(0.2, 0.55, 1.0, 0.92)
	token.polygon = PackedVector2Array([Vector2(0, -28), Vector2(24, 16), Vector2(0, 32), Vector2(-24, 16)])
	add_child(token)
	_label = Label.new()
	_label.name = "Label"
	_label.position = Vector2(-52, -76)
	_label.text = "LOUIS\nExit Check\nE/Q"
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)


func _show(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 5.0)
	if has_node("/root/EventBus"):
		EventBus.objective_updated.emit(text)
