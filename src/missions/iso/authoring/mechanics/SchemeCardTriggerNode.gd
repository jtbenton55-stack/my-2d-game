@tool
class_name SchemeCardTriggerNode
extends MechanicAreaBase

@export_group("Scheme Card")
@export var modifier_sets: Array[Resource] = []
@export var require_matching_modifier: bool = true
@export var apply_all_matching_modifiers: bool = true
@export var apply_on_ready: bool = false
@export var refresh_mechanics_after_apply: bool = true
@export var missing_card_message: String = "Requires a matching scheme card."

var last_scheme_card_result: Dictionary = {}
var last_modifier_results: Array[Dictionary] = []
var last_matched_card_ids: Array[String] = []


func _ready() -> void:
	super._ready()
	if apply_on_ready and not Engine.is_editor_hint():
		call_deferred("_apply_on_ready")


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["active_scheme_card_ids"] = _active_scheme_card_ids()
	context["scheme_card_trigger_id"] = String(mechanic_id)
	return context


func trigger_scheme_cards(actor: Node = null, reason: String = "interact") -> Dictionary:
	return activate(actor, reason)


func set_modifier_sets(value: Array) -> void:
	modifier_sets.clear()
	for item in value:
		if item is Resource:
			modifier_sets.append(item)
	refresh_debug_label()


func trigger(actor: Node = null, reason: String = "interact") -> Dictionary:
	return trigger_scheme_cards(actor, reason)


func interact(actor: Node = null) -> bool:
	return bool(trigger_scheme_cards(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(trigger_scheme_cards(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(trigger_scheme_cards(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(trigger_scheme_cards(actor, "interact").get("ok", false))


func is_interaction_available(actor: Node = null) -> bool:
	if not super.is_interaction_available(actor):
		return false
	if Engine.is_editor_hint() or not require_matching_modifier:
		return true
	return _has_ready_modifier(build_context(actor))


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if one_shot and used:
		return ""
	if _requirements_pass() and (Engine.is_editor_hint() or not require_matching_modifier or _has_ready_modifier(build_context())):
		return prompt_text
	return missing_card_message if missing_card_message.strip_edges() != "" else locked_prompt_text


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
		return _fail_activation(context, reason, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), last_requirement_result)

	last_scheme_card_result = apply_matching_modifiers(context)
	if not bool(last_scheme_card_result.get("ok", false)):
		return _fail_activation(context, reason, String(last_scheme_card_result.get("code", "scheme_card_trigger_failed")), String(last_scheme_card_result.get("message", "No scheme-card modifier applied.")), last_scheme_card_result)

	var local_effect_result := apply_success_effects(context)
	last_effect_result = _combine_effect_results(last_scheme_card_result, local_effect_result)
	var ok := bool(last_effect_result.get("ok", false))
	if one_shot and ok:
		mark_used()
	last_activation_result = _result(
		ok,
		"scheme_card_trigger_applied" if ok else "scheme_card_trigger_failed",
		"Scheme-card trigger applied." if ok else "Scheme-card trigger failed.",
		String(mechanic_id),
		{
			"reason": reason,
			"requirement_result": last_requirement_result,
			"effect_result": last_effect_result,
			"scheme_card_result": last_scheme_card_result,
		}
	)
	if ok:
		activation_succeeded.emit(String(mechanic_id), last_activation_result)
	else:
		activation_failed.emit(String(mechanic_id), last_activation_result)
	_refresh_after_apply()
	refresh_debug_label()
	return last_activation_result


func apply_matching_modifiers(context: Dictionary) -> Dictionary:
	last_modifier_results.clear()
	last_matched_card_ids.clear()
	var active_ids: Array = context.get("active_scheme_card_ids", [])
	var matched_count := 0
	var applied_count := 0
	var failed_count := 0

	for raw_modifier in modifier_sets:
		var modifier := raw_modifier as MissionModifierSet
		if modifier == null:
			continue
		var matched_card_id := _matched_card_id(modifier, active_ids)
		if matched_card_id == "":
			continue
		matched_count += 1
		if not last_matched_card_ids.has(matched_card_id):
			last_matched_card_ids.append(matched_card_id)
		var modifier_context := context.duplicate(true)
		modifier_context["matched_card_id"] = matched_card_id
		var requirement_result := modifier.evaluate_requirements(modifier_context)
		if not bool(requirement_result.get("ok", false)):
			failed_count += 1
			last_modifier_results.append(_modifier_result(false, "modifier_requirements_failed", modifier, matched_card_id, requirement_result, {}))
			continue
		var effect_result := modifier.apply_setup_effects(modifier_context)
		var effect_ok := bool(effect_result.get("ok", false))
		if effect_ok:
			applied_count += 1
		else:
			failed_count += 1
		last_modifier_results.append(_modifier_result(effect_ok, "modifier_applied" if effect_ok else "modifier_effects_failed", modifier, matched_card_id, requirement_result, effect_result))
		if effect_ok and not apply_all_matching_modifiers:
			break

	if matched_count == 0 and require_matching_modifier:
		return _result(false, "no_matching_scheme_card_modifier", missing_card_message, String(mechanic_id), _modifier_details(active_ids, matched_count, applied_count, failed_count))
	var ok := failed_count == 0 and (matched_count > 0 or not require_matching_modifier)
	return _result(
		ok,
		"scheme_card_modifiers_applied" if ok else "scheme_card_modifiers_failed",
		"Applied %d scheme-card modifiers." % applied_count if ok else "One or more scheme-card modifiers failed.",
		String(mechanic_id),
		_modifier_details(active_ids, matched_count, applied_count, failed_count)
	)


func _apply_on_ready() -> void:
	if is_inside_tree() and not (one_shot and used):
		trigger_scheme_cards(null, "ready")


func _has_ready_modifier(context: Dictionary) -> bool:
	var active_ids: Array = context.get("active_scheme_card_ids", [])
	for raw_modifier in modifier_sets:
		var modifier := raw_modifier as MissionModifierSet
		if modifier == null:
			continue
		var matched_card_id := _matched_card_id(modifier, active_ids)
		if matched_card_id == "":
			continue
		var modifier_context := context.duplicate(true)
		modifier_context["matched_card_id"] = matched_card_id
		var requirement_result := modifier.evaluate_requirements(modifier_context)
		if bool(requirement_result.get("ok", false)):
			return true
	return false


func _active_scheme_card_ids() -> Array[String]:
	var out: Array[String] = []
	for card in MissionSchemeBridge.get_active_scheme_cards(_resolved_mission_id()):
		var card_id := String(card.get("id")).strip_edges() if card != null else ""
		if card_id != "" and not out.has(card_id):
			out.append(card_id)
	return out


func _matched_card_id(modifier: MissionModifierSet, active_ids: Array) -> String:
	var source := String(modifier.source_card_id).strip_edges()
	if source == "":
		return String(active_ids[0]) if not active_ids.is_empty() else ""
	return source if active_ids.has(source) else ""


func _modifier_result(ok: bool, code: String, modifier: MissionModifierSet, matched_card_id: String, requirement_result: Dictionary, effect_result: Dictionary) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": "Modifier %s %s." % [String(modifier.modifier_id), "applied" if ok else "failed"],
		"source_id": String(modifier.modifier_id),
		"details": {
			"modifier_id": String(modifier.modifier_id),
			"source_card_id": String(modifier.source_card_id),
			"matched_card_id": matched_card_id,
			"requirement_result": requirement_result,
			"effect_result": effect_result,
		},
	}


func _modifier_details(active_ids: Array, matched_count: int, applied_count: int, failed_count: int) -> Dictionary:
	return {
		"active_scheme_card_ids": active_ids,
		"matched_card_ids": last_matched_card_ids.duplicate(),
		"matched_count": matched_count,
		"applied_count": applied_count,
		"failed_count": failed_count,
		"modifier_results": last_modifier_results.duplicate(true),
	}


func _combine_effect_results(modifier_result: Dictionary, local_effect_result: Dictionary) -> Dictionary:
	var modifier_ok := bool(modifier_result.get("ok", false))
	var local_ok := bool(local_effect_result.get("ok", false))
	return _result(
		modifier_ok and local_ok,
		"scheme_card_effects_applied" if modifier_ok and local_ok else "scheme_card_effects_failed",
		"Scheme-card and local effects applied." if modifier_ok and local_ok else "Scheme-card or local effects failed.",
		String(mechanic_id),
		{
			"modifier_result": modifier_result,
			"local_effect_result": local_effect_result,
		}
	)


func _fail_activation(context: Dictionary, reason: String, code: String, message: String, failure_result: Dictionary) -> Dictionary:
	last_effect_result = apply_failure_effects(context)
	effects_applied.emit(String(mechanic_id), last_effect_result)
	last_activation_result = _result(false, code, message, String(mechanic_id), {
		"reason": reason,
		"failure_result": failure_result,
		"effect_result": last_effect_result,
	})
	activation_failed.emit(String(mechanic_id), last_activation_result)
	_refresh_after_apply()
	refresh_debug_label()
	return last_activation_result


func _refresh_after_apply() -> void:
	_notify_availability()
	if not refresh_mechanics_after_apply or not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("mission_mechanic"):
		if node != null and node.has_method("refresh_debug_label"):
			node.call("refresh_debug_label")


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if one_shot and used:
		return "USED"
	if not _requirements_pass():
		return "LOCKED"
	return "CARD READY" if Engine.is_editor_hint() or not require_matching_modifier or _has_ready_modifier(build_context()) else "CARD LOCKED"
