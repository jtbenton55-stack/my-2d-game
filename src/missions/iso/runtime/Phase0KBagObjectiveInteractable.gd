@tool
class_name Phase0KBagObjectiveInteractable
extends Area2D

@export var mission_state_adapter_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JMissionStateAdapter")
@export var objective_adapter_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JObjectiveAdapter")
@export var completion_controller_path: NodePath = NodePath("../../RuntimeHelpers/Phase0KMissionCompletionController")
@export var debug_hud_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JDebugHUD")

var collected := false
var _label: Label


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("phase0k_delivery_bag")
	collision_layer = 8
	collision_mask = 1
	set_meta("generated_by", "Phase0K")
	set_meta("candidate_id", "OBJ_bag_recovery")
	set_meta("category", "objective_bag")
	_build_visual()


func interact(player: Node = null) -> bool:
	return _collect(player)


func on_interact(player: Node = null) -> bool:
	return _collect(player)


func use(player: Node = null) -> bool:
	return _collect(player)


func get_interaction_text() -> String:
	return "Recover delivery bag"


func reset_attempt_state() -> Dictionary:
	collected = false
	set_meta("collected", false)
	monitoring = true
	monitorable = true
	collision_layer = 8
	collision_mask = 1
	if _label != null:
		_label.text = "DELIVERY BAG\nObjective\nE/Q"
	modulate = Color(1, 1, 1, 1)
	return {"ok": true, "code": "delivery_bag_reset", "node": str(get_path())}


func _collect(_player: Node = null) -> bool:
	if collected:
		_show("Delivery bag already recovered.")
		return true
	var state := get_node_or_null(mission_state_adapter_path)
	if state != null and state.has_method("collect_item"):
		var result: Dictionary = state.call("collect_item", "OBJ_bag_recovery", "objective_bag", {
			"objective_id": "recover_delivery_bag",
			"display_name": "Recover the delivery bag",
			"mission_id": "taco_bell_drop",
		})
		if bool(result.get("already_done", false)):
			collected = true
		elif not bool(result.get("success", false)):
			_show(String(result.get("message", "Delivery bag collection failed.")))
			return false
	var objective := get_node_or_null(objective_adapter_path)
	if objective != null and objective.has_method("mark_delivery_bag_collected"):
		objective.call("mark_delivery_bag_collected")
	var completion := get_node_or_null(completion_controller_path)
	if completion != null and completion.has_method("set_delivery_bag_collected"):
		completion.call("set_delivery_bag_collected", true)
	collected = true
	set_meta("collected", true)
	if _label != null:
		_label.text = "DELIVERY BAG\nCOLLECTED"
	modulate = Color(0.65, 0.65, 0.65, 0.75)
	_show("Delivery bag recovered.")
	return true


func _build_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 42
		shape.shape = circle
		add_child(shape)
	var bag := Polygon2D.new()
	bag.name = "DeliveryBagToken"
	bag.color = Color(0.95, 0.65, 0.1, 0.95)
	bag.polygon = PackedVector2Array([Vector2(-28, -18), Vector2(28, -18), Vector2(34, 28), Vector2(-34, 28)])
	add_child(bag)
	_label = Label.new()
	_label.name = "Label"
	_label.position = Vector2(-72, -74)
	_label.text = "DELIVERY BAG\nObjective\nE/Q"
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)


func _show(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 4.0)
	if has_node("/root/EventBus"):
		EventBus.objective_updated.emit(text)
