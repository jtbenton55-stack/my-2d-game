@tool
class_name TeleportZone
extends TriggerZone

@export_group("Teleport")
@export var target_marker_path: NodePath
@export var player_path: NodePath
@export var require_prior_interaction: bool = true
@export var warn_on_missing_target: bool = true

var last_teleport_result: Dictionary = {}


func _init() -> void:
	super._init()
	prompt_text = "Press E: Teleport"
	trigger_on_enter = false
	interaction_mode = InteractionMode.INTERACT_REQUIRED


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["target_marker_path"] = str(target_marker_path)
	context["require_prior_interaction"] = require_prior_interaction
	return context


func evaluate_requirements(actor: Node = null) -> Dictionary:
	if not require_prior_interaction:
		return _result(true, "prior_interaction_not_required", "Teleport does not require prior mechanic state.")
	return super.evaluate_requirements(actor)


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
		last_activation_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	last_teleport_result = _teleport_actor(actor)
	if not bool(last_teleport_result.get("ok", false)):
		last_activation_result = _result(false, String(last_teleport_result.get("code", "teleport_failed")), String(last_teleport_result.get("message", "Teleport failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "teleport_result": last_teleport_result})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	last_effect_result = apply_success_effects(build_context(_resolve_player(actor)))
	effects_applied.emit(String(mechanic_id), last_effect_result)
	if one_shot:
		mark_used()
	last_activation_result = _result(true, "teleported", "Teleported player.", String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "teleport_result": last_teleport_result, "effect_result": last_effect_result})
	activation_succeeded.emit(String(mechanic_id), last_activation_result)
	refresh_debug_label()
	return last_activation_result


func _teleport_actor(actor: Node = null) -> Dictionary:
	var target := get_node_or_null(target_marker_path) as Node2D
	if target == null:
		return _warn_and_result("missing_target_marker", "TeleportZone target_marker_path is missing or invalid.")
	var player := _resolve_player(actor)
	if player == null:
		return _warn_and_result("missing_player", "TeleportZone could not resolve a player Node2D.")
	player.global_position = target.global_position
	return _result(true, "teleport_applied", "Player moved to teleport target.", String(mechanic_id), {"player_path": _safe_node_path(player), "target_path": _safe_node_path(target), "target_position": target.global_position})


func _resolve_player(actor: Node = null) -> Node2D:
	if actor is Node2D:
		return actor as Node2D
	if player_path != NodePath():
		var explicit := get_node_or_null(player_path) as Node2D
		if explicit != null:
			return explicit
	if get_tree() != null:
		return get_tree().get_first_node_in_group("player") as Node2D
	return null


func _warn_and_result(code: String, message: String) -> Dictionary:
	if warn_on_missing_target and not Engine.is_editor_hint():
		EventBus.debug(message)
	return _result(false, code, message, String(mechanic_id))


func _safe_node_path(node: Node) -> String:
	if node == null:
		return ""
	return str(node.get_path()) if node.is_inside_tree() else node.name
