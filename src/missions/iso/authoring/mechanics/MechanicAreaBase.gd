@tool
class_name MechanicAreaBase
extends Area2D

signal availability_changed(mechanic_id: String, available: bool)
signal activation_started(mechanic_id: String, actor: Node)
signal activation_succeeded(mechanic_id: String, result: Dictionary)
signal activation_failed(mechanic_id: String, result: Dictionary)
signal effects_applied(mechanic_id: String, result: Dictionary)

enum InteractionMode {
	AUTOMATIC_ON_ENTER,
	INTERACT_REQUIRED,
	SCRIPT_ONLY,
}

@export_group("Identity")
@export var mechanic_id: StringName = &"mechanic"
@export var display_name: String = ""
@export var enabled: bool = true
@export var mission_id_override: String = ""

@export_group("Interaction")
@export var interaction_mode: InteractionMode = InteractionMode.INTERACT_REQUIRED
@export var one_shot: bool = true
@export var starts_used: bool = false
@export var interaction_priority: int = 500
@export var prompt_text: String = "Press E: Interact"
@export var locked_prompt_text: String = "Unavailable"
@export var available_actor_group: StringName = &"player"
@export var action_interact: StringName = &"interact"

@export_group("Logic")
@export var requirements: RequirementSet
@export var success_effects: EffectSet
@export var failure_effects: EffectSet

@export_group("Shape")
@export var shape_size: Vector2 = Vector2(96.0, 96.0)
@export var collision_shape_path: NodePath = NodePath("CollisionShape2D")

@export_group("Debug")
@export var debug_enabled: bool = true
@export var show_debug_label: bool = true
@export var debug_label_path: NodePath = NodePath("DebugLabel")
@export var preview_color: Color = Color(0.3, 0.7, 1.0, 0.35)

var used: bool = false
var current_actor: Node = null
var last_requirement_result: Dictionary = {}
var last_activation_result: Dictionary = {}
var last_effect_result: Dictionary = {}

var _body_enter_connected: bool = false


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("mission_mechanic")
	used = starts_used
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = true
	_ensure_body_enter_connection()
	_apply_shape_size_if_possible()
	refresh_debug_label()
	_notify_availability()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_apply_shape_size_if_possible()
		refresh_debug_label()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var rect := Rect2(-shape_size * 0.5, shape_size)
	draw_rect(rect, preview_color, true)
	draw_rect(rect, Color(preview_color.r, preview_color.g, preview_color.b, minf(preview_color.a + 0.35, 1.0)), false, 2.0)


func interact(actor: Node = null) -> bool:
	return _route_activation(actor)


func on_interact(actor: Node = null) -> bool:
	return _route_activation(actor)


func use(actor: Node = null) -> bool:
	return _route_activation(actor)


func inspect_marker(actor: Node = null) -> bool:
	return _route_activation(actor)


func is_interaction_available(actor: Node = null) -> bool:
	if not enabled:
		return false
	if one_shot and used:
		return false
	if actor != null and not can_actor_use(actor):
		return false
	return _requirements_pass(actor)


func should_show_interaction_prompt() -> bool:
	return is_interaction_available() and get_interaction_text().strip_edges() != ""


func get_interaction_priority(_actor: Node = null) -> int:
	return interaction_priority


func is_completed() -> bool:
	return one_shot and used


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if one_shot and used:
		return ""
	if _requirements_pass():
		return prompt_text
	if requirements != null:
		var locked := requirements.locked_message.strip_edges()
		if locked != "":
			return locked
	return locked_prompt_text


func build_context(actor: Node = null) -> Dictionary:
	return {
		"mission_id": _resolved_mission_id(),
		"actor": actor,
		"mechanic": self,
		"source_id": String(mechanic_id),
		"source_path": str(get_path()),
		"position": global_position,
		"debug": debug_enabled,
	}


func evaluate_requirements(actor: Node = null) -> Dictionary:
	if requirements == null:
		return _result(true, "no_requirements", "No requirements assigned.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Requirements skipped in editor.")
	return requirements.evaluate(build_context(actor))


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	current_actor = actor
	activation_started.emit(String(mechanic_id), actor)

	if not enabled:
		last_activation_result = _result(false, "mechanic_disabled", "Mechanic is disabled.", String(mechanic_id), {"reason": reason})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	if one_shot and used:
		last_activation_result = _result(true, "already_used", "Mechanic already used.", String(mechanic_id), {"reason": reason})
		refresh_debug_label()
		return last_activation_result

	if actor != null and not can_actor_use(actor):
		last_activation_result = _result(false, "actor_not_allowed", "Actor cannot use this mechanic.", String(mechanic_id), {"reason": reason, "actor": actor})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	if Engine.is_editor_hint():
		last_activation_result = _result(true, "editor_preview", "Activation skipped in editor.", String(mechanic_id), {"reason": reason})
		refresh_debug_label()
		return last_activation_result

	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		effects_applied.emit(String(mechanic_id), last_effect_result)
		last_activation_result = _result(
			false,
			"requirements_failed",
			String(last_requirement_result.get("message", "Requirements failed.")),
			String(mechanic_id),
			{
				"reason": reason,
				"requirement_result": last_requirement_result,
				"effect_result": last_effect_result,
			}
		)
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	last_effect_result = apply_success_effects(context)
	effects_applied.emit(String(mechanic_id), last_effect_result)
	if one_shot:
		mark_used()
	last_activation_result = _result(
		true,
		"activation_succeeded",
		"Mechanic activated.",
		String(mechanic_id),
		{
			"reason": reason,
			"requirement_result": last_requirement_result,
			"effect_result": last_effect_result,
		}
	)
	activation_succeeded.emit(String(mechanic_id), last_activation_result)
	refresh_debug_label()
	return last_activation_result


func apply_success_effects(context: Dictionary) -> Dictionary:
	if success_effects == null or success_effects.is_empty():
		return _result(true, "no_success_effects", "No success effects assigned.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Success effects skipped in editor.")
	return success_effects.apply_all(context)


func apply_failure_effects(context: Dictionary) -> Dictionary:
	if failure_effects == null or failure_effects.is_empty():
		return _result(true, "no_failure_effects", "No failure effects assigned.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Failure effects skipped in editor.")
	return failure_effects.apply_all(context)


func mark_used() -> void:
	used = true
	refresh_debug_label()
	_notify_availability()


func can_actor_use(actor: Node) -> bool:
	if actor == null:
		return true
	var group_name := String(available_actor_group).strip_edges()
	if group_name == "":
		return true
	return actor.is_in_group(group_name)


func refresh_debug_label() -> void:
	if not show_debug_label:
		return
	var label := get_node_or_null(debug_label_path)
	if label == null or not label.has_method("set_text"):
		return
	label.call("set_text", _debug_label_text())


func designer_name() -> String:
	var custom := display_name.strip_edges()
	if custom != "":
		return custom
	return String(mechanic_id)


func _route_activation(actor: Node = null) -> bool:
	var result: Dictionary = activate(actor, "interact")
	return bool(result.get("ok", false))


func _requirements_pass(actor: Node = null) -> bool:
	if requirements == null:
		return true
	if Engine.is_editor_hint():
		return true
	return bool(evaluate_requirements(actor).get("ok", false))


func _resolved_mission_id() -> String:
	var override := mission_id_override.strip_edges()
	if override != "":
		return override
	return MissionFactBridge.resolve_mission_id({})


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if one_shot and used:
		return "USED"
	if _requirements_pass():
		return "READY"
	return "LOCKED"


func _ensure_body_enter_connection() -> void:
	if interaction_mode != InteractionMode.AUTOMATIC_ON_ENTER:
		return
	if _body_enter_connected:
		return
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_body_enter_connected = true


func _on_body_entered(body: Node) -> void:
	if Engine.is_editor_hint():
		return
	if interaction_mode != InteractionMode.AUTOMATIC_ON_ENTER:
		return
	if not enabled or (one_shot and used):
		return
	if not can_actor_use(body):
		return
	activate(body, "automatic_enter")


func _apply_shape_size_if_possible() -> void:
	var shape_node := get_node_or_null(collision_shape_path)
	if shape_node == null or not (shape_node is CollisionShape2D):
		return
	var collision_shape := shape_node as CollisionShape2D
	if collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = shape_size


func _notify_availability() -> void:
	availability_changed.emit(String(mechanic_id), is_interaction_available())


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id if source_id != "" else String(mechanic_id),
		"details": details,
	}
