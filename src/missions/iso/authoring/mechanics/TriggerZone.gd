@tool
class_name TriggerZone
extends MechanicAreaBase

@export_group("Trigger")
@export var trigger_on_enter: bool = true
@export var trigger_on_exit: bool = false
@export var trigger_event_id: StringName = &""
@export var emit_eventbus_debug: bool = false
@export var include_trigger_event_in_context: bool = true

var entered_actor: Node = null
var last_trigger_reason: String = ""

var _body_exit_connected: bool = false


func _init() -> void:
	interaction_mode = InteractionMode.AUTOMATIC_ON_ENTER


func _ready() -> void:
	super._ready()
	_ensure_trigger_body_connections()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	if include_trigger_event_in_context:
		context["trigger_event_id"] = String(trigger_event_id)
		context["trigger_reason"] = last_trigger_reason
	return context


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	last_trigger_reason = reason
	if actor != null:
		current_actor = actor
	var result: Dictionary = super.activate(actor, reason)
	_emit_eventbus_debug(result)
	return result


func trigger(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func interact(actor: Node = null) -> bool:
	return bool(trigger(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(trigger(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(trigger(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(trigger(actor, "interact").get("ok", false))


func handle_body_entered(body: Node) -> void:
	_on_body_entered(body)


func handle_body_exited(body: Node) -> void:
	_on_body_exited(body)


func _on_body_entered(body: Node) -> void:
	if Engine.is_editor_hint():
		return
	if not can_actor_use(body):
		return
	entered_actor = body
	current_actor = body
	match interaction_mode:
		InteractionMode.SCRIPT_ONLY:
			return
		InteractionMode.INTERACT_REQUIRED:
			return
		InteractionMode.AUTOMATIC_ON_ENTER:
			if trigger_on_enter:
				trigger(body, "body_entered")


func _on_body_exited(body: Node) -> void:
	if Engine.is_editor_hint():
		return
	if entered_actor == body:
		entered_actor = null
	if current_actor == body:
		current_actor = null
	if not trigger_on_exit:
		return
	if not can_actor_use(body):
		return
	if interaction_mode == InteractionMode.AUTOMATIC_ON_ENTER:
		trigger(body, "body_exited")


func _ensure_trigger_body_connections() -> void:
	if interaction_mode != InteractionMode.AUTOMATIC_ON_ENTER:
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
	if trigger_on_exit and not _body_exit_connected:
		if not body_exited.is_connected(_on_body_exited):
			body_exited.connect(_on_body_exited)
		_body_exit_connected = true


func _emit_eventbus_debug(result: Dictionary) -> void:
	if Engine.is_editor_hint() or not emit_eventbus_debug:
		return
	var event_bus := Engine.get_main_loop()
	if event_bus == null or not (event_bus is SceneTree):
		return
	var bus := (event_bus as SceneTree).root.get_node_or_null("EventBus")
	if bus == null or not bus.has_method("debug"):
		return
	var event_label := String(trigger_event_id)
	if event_label == "":
		event_label = String(mechanic_id)
	var status := "ok" if bool(result.get("ok", false)) else "fail"
	bus.call(
		"debug",
		"TriggerZone %s (%s) %s: %s" % [String(mechanic_id), event_label, status, String(result.get("code", ""))]
	)
