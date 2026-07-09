@tool
class_name ExtractionZone
extends MechanicAreaBase

@export_group("Extraction")
@export var extraction_tag: StringName = &"default_exit"
@export var extraction_flag: StringName = &""
@export var starts_extracted: bool = false
@export var complete_mission_on_success: bool = true
@export var show_result_screen_on_success: bool = false
@export var stay_available_after_extract: bool = false

@export_group("Objectives")
@export var required_objective_ids: Array[StringName] = []
@export var optional_objective_ids: Array[StringName] = []

@export_group("Alert Handling")
@export var fail_if_alerted: bool = false
@export var messy_if_alerted: bool = true
@export var alerted_state_value: StringName = &"alerted"

@export_group("Exit Effects")
@export var clean_exit_effects: EffectSet
@export var messy_exit_effects: EffectSet

@export_group("Feedback")
@export var extracted_prompt_text: String = "Already extracted"
@export var missing_objective_message: String = "Finish the required objective first."
@export var clean_exit_message: String = "Extracted cleanly."
@export var messy_exit_message: String = "Extracted under pressure."
@export var failed_exit_message: String = "Extraction failed."
@export var extraction_sound_key: StringName = &""
@export var emit_eventbus_debug: bool = false

var extracted: bool = false
var last_extraction_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	extracted = starts_extracted


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["extraction_tag"] = String(extraction_tag)
	context["extraction_flag"] = String(extraction_flag)
	context["extracted"] = extracted
	return context


func extract(actor: Node = null, reason: String = "interact") -> Dictionary:
	if extracted:
		if not stay_available_after_extract:
			last_extraction_result = _extraction_result(
				true,
				"already_extracted",
				extracted_prompt_text if extracted_prompt_text.strip_edges() != "" else "Already extracted.",
				{"reason": reason, "reapplied_effects": false}
			)
			return last_extraction_result
		last_extraction_result = _extraction_result(
			true,
			"already_extracted",
			extracted_prompt_text if extracted_prompt_text.strip_edges() != "" else "Already extracted.",
			{"reason": reason, "reapplied_effects": false, "stay_available": true}
		)
		return last_extraction_result

	var context := build_context(actor)
	var can_result := can_extract(actor, context)
	if not bool(can_result.get("ok", false)):
		var fail_code := String(can_result.get("code", ""))
		if fail_code == "requirements_failed":
			var activation_failure: Dictionary = activate(actor, reason)
			last_extraction_result = _merge_extraction_details(
				_enrich_extraction_result(activation_failure, actor, reason, context),
				{"can_extract": can_result}
			)
			return last_extraction_result
		last_extraction_result = _enrich_extraction_result(can_result, actor, reason, context)
		return last_extraction_result

	var activation_result: Dictionary = activate(actor, reason)
	if not bool(activation_result.get("ok", false)):
		last_extraction_result = _enrich_extraction_result(activation_result, actor, reason, context)
		return last_extraction_result
	if String(activation_result.get("code", "")) != "activation_succeeded":
		last_extraction_result = _enrich_extraction_result(activation_result, actor, reason, context)
		return last_extraction_result

	var alert_state := _read_alert_state(context)
	var outcome := _resolve_extraction_outcome(alert_state)
	context["alert_state"] = alert_state
	context["extraction_outcome"] = outcome

	var required_status: Dictionary = get_required_objective_status(context)
	var optional_status: Dictionary = get_optional_objective_status(context)

	if outcome == "failed_alerted":
		var failure_effect_result: Dictionary = apply_failure_effects(context)
		last_extraction_result = _extraction_result(
			false,
			"extraction_failed_alerted",
			failed_exit_message if failed_exit_message.strip_edges() != "" else "Extraction failed while alerted.",
			{
				"reason": reason,
				"outcome": outcome,
				"alert_state": alert_state,
				"activation_result": activation_result,
				"failure_effect_result": failure_effect_result,
				"required_objectives": required_status,
				"optional_objectives": optional_status,
			}
		)
		_emit_extraction_debug(last_extraction_result)
		_notify_availability()
		refresh_debug_label()
		return last_extraction_result

	extracted = true
	var flag_result: Dictionary = set_extraction_flag(context)
	var exit_effect_result: Dictionary = {}
	var message := clean_exit_message
	var result_code := "extraction_clean"

	if outcome == "messy":
		exit_effect_result = _apply_exit_effects(messy_exit_effects, context)
		message = messy_exit_message if messy_exit_message.strip_edges() != "" else "Extracted under pressure."
		result_code = "extraction_messy"
	else:
		exit_effect_result = _apply_exit_effects(clean_exit_effects, context)
		message = clean_exit_message if clean_exit_message.strip_edges() != "" else "Extracted cleanly."

	var completion_result: Dictionary = {}
	if complete_mission_on_success:
		completion_result = MissionCompletionBridge.request_complete(_mission_id_from_context(context), context)

	last_extraction_result = _extraction_result(
		true,
		result_code,
		message,
		{
			"reason": reason,
			"outcome": outcome,
			"alert_state": alert_state,
			"activation_result": activation_result,
			"extraction_flag_result": flag_result,
			"exit_effect_result": exit_effect_result,
			"completion_result": completion_result,
			"required_objectives": required_status,
			"optional_objectives": optional_status,
		}
	)
	_emit_extraction_debug(last_extraction_result)
	_show_result_screen_if_requested(completion_result)
	_notify_availability()
	refresh_debug_label()
	return last_extraction_result


func reset_extraction() -> void:
	extracted = false
	_notify_availability()
	refresh_debug_label()


func is_extracted() -> bool:
	return extracted


func can_extract(actor: Node = null, context: Dictionary = {}) -> Dictionary:
	if not enabled:
		return _extraction_result(false, "mechanic_disabled", "Extraction zone is disabled.")
	if extracted and not stay_available_after_extract:
		return _extraction_result(true, "already_extracted", "Already extracted.")
	var working_context := context if not context.is_empty() else build_context(actor)
	if actor != null:
		working_context["actor"] = actor
		if not can_actor_use(actor):
			return _extraction_result(false, "actor_not_allowed", "Actor cannot use this extraction zone.")
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		return _extraction_result(
			false,
			"requirements_failed",
			String(last_requirement_result.get("message", "Requirements failed.")),
			{"requirement_result": last_requirement_result}
		)
	var required_status: Dictionary = get_required_objective_status(working_context)
	if not bool(required_status.get("ok", false)):
		return _extraction_result(
			false,
			"missing_required_objectives",
			missing_objective_message if missing_objective_message.strip_edges() != "" else "Required objectives are incomplete.",
			{
				"required_objectives": required_status,
				"missing_required_objectives": required_status.get("missing", []),
			}
		)
	return _extraction_result(true, "can_extract", "Extraction is allowed.", {"required_objectives": required_status})


func get_required_objective_status(context: Dictionary = {}) -> Dictionary:
	var mid := _mission_id_from_context(context)
	var missing: Array[String] = []
	var completed: Array[String] = []
	for objective_id: StringName in required_objective_ids:
		var oid := String(objective_id).strip_edges()
		if oid == "":
			continue
		if ObjectiveStepController.is_objective_completed(oid, mid, context):
			completed.append(oid)
		else:
			missing.append(oid)
	return {
		"ok": missing.is_empty(),
		"mission_id": mid,
		"required": _string_name_array(required_objective_ids),
		"completed": completed,
		"missing": missing,
	}


func get_optional_objective_status(context: Dictionary = {}) -> Dictionary:
	var mid := _mission_id_from_context(context)
	var completed: Array[String] = []
	var incomplete: Array[String] = []
	for objective_id: StringName in optional_objective_ids:
		var oid := String(objective_id).strip_edges()
		if oid == "":
			continue
		if ObjectiveStepController.is_objective_completed(oid, mid, context):
			completed.append(oid)
		else:
			incomplete.append(oid)
	return {
		"ok": true,
		"mission_id": mid,
		"optional": _string_name_array(optional_objective_ids),
		"completed": completed,
		"incomplete": incomplete,
	}


func set_extraction_flag(context: Dictionary) -> Dictionary:
	if extraction_flag == &"":
		return _result(true, "no_extraction_flag", "No extraction_flag configured.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Extraction flag skipped in editor.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(extraction_flag), true, context)


func interact(actor: Node = null) -> bool:
	return bool(extract(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(extract(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(extract(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(extract(actor, "interact").get("ok", false))


func is_interaction_available(actor: Node = null) -> bool:
	if not enabled:
		return false
	if extracted and not stay_available_after_extract:
		return false
	if extracted and stay_available_after_extract:
		return true
	var context := build_context(actor)
	var required_status: Dictionary = get_required_objective_status(context)
	if not required_objective_ids.is_empty() and not bool(required_status.get("ok", false)):
		return false
	return super.is_interaction_available(actor)


func is_completed() -> bool:
	if extracted and not stay_available_after_extract:
		return true
	return super.is_completed()


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if extracted:
		if not stay_available_after_extract:
			return ""
		return extracted_prompt_text
	var context := build_context(null)
	var required_status: Dictionary = get_required_objective_status(context)
	if not required_objective_ids.is_empty() and not bool(required_status.get("ok", false)):
		return missing_objective_message
	if not _requirements_pass():
		if requirements != null:
			var locked := requirements.locked_message.strip_edges()
			if locked != "":
				return locked
		return locked_prompt_text
	return prompt_text


func _read_alert_state(context: Dictionary) -> String:
	var mid := _mission_id_from_context(context)
	if mid == "":
		return "normal"
	return String(MissionFactBridge.get_fact_value(&"alert_state", mid, context))


func _resolve_extraction_outcome(alert_state: String) -> String:
	var normalized := alert_state.strip_edges().to_lower()
	var alert_target := String(alerted_state_value).strip_edges().to_lower()
	if alert_target == "":
		alert_target = "alerted"
	if normalized != alert_target:
		return "clean"
	if fail_if_alerted:
		return "failed_alerted"
	if messy_if_alerted:
		return "messy"
	return "clean"


func _apply_exit_effects(effect_set: EffectSet, context: Dictionary) -> Dictionary:
	if effect_set == null or effect_set.is_empty():
		return _result(true, "no_exit_effects", "No exit effects assigned.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Exit effects skipped in editor.")
	return effect_set.apply_all(context)


func _mission_id_from_context(context: Dictionary) -> String:
	var override := mission_id_override.strip_edges()
	if override != "":
		return override
	return MissionFactBridge.resolve_mission_id(context)


func _enrich_extraction_result(result: Dictionary, actor: Node, reason: String, context: Dictionary) -> Dictionary:
	var details: Dictionary = (result.get("details", {}) as Dictionary).duplicate(true)
	details["reason"] = reason
	details["extraction_tag"] = String(extraction_tag)
	details["extraction_flag"] = String(extraction_flag)
	details["extracted"] = extracted
	details["alert_state"] = _read_alert_state(context)
	if actor != null:
		details["actor"] = actor
	return {
		"ok": bool(result.get("ok", false)),
		"code": String(result.get("code", "")),
		"message": String(result.get("message", "")),
		"source_id": String(result.get("source_id", String(mechanic_id))),
		"details": details,
	}


func _extraction_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	var merged := details.duplicate(true)
	merged["extraction_tag"] = String(extraction_tag)
	merged["extraction_flag"] = String(extraction_flag)
	merged["extracted"] = extracted
	return _result(ok, code, message, String(mechanic_id), merged)


func _merge_extraction_details(base: Dictionary, extra: Dictionary) -> Dictionary:
	var details: Dictionary = (base.get("details", {}) as Dictionary).duplicate(true)
	for key: String in extra.keys():
		details[key] = extra[key]
	base["details"] = details
	return base


func _string_name_array(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value: StringName in values:
		var text := String(value).strip_edges()
		if text != "":
			out.append(text)
	return out


func _emit_extraction_debug(result: Dictionary) -> void:
	if Engine.is_editor_hint() or not emit_eventbus_debug:
		return
	var event_bus := get_tree().root.get_node_or_null("EventBus") if get_tree() != null else null
	if event_bus == null or not event_bus.has_method("debug"):
		return
	var status := "ok" if bool(result.get("ok", false)) else "fail"
	event_bus.call(
		"debug",
		"ExtractionZone %s (%s) %s: %s" % [String(mechanic_id), String(extraction_tag), status, String(result.get("code", ""))]
	)


func _show_result_screen_if_requested(completion_result: Dictionary) -> void:
	if Engine.is_editor_hint() or not show_result_screen_on_success:
		return
	if not complete_mission_on_success or not bool(completion_result.get("ok", false)):
		return
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager == null or not scene_manager.has_method("show_mission_result"):
		return
	var game_state := get_node_or_null("/root/GameState")
	var result_payload: Dictionary = (game_state.get("last_mission_result") as Dictionary) if game_state != null else {}
	scene_manager.call_deferred("show_mission_result", result_payload)


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if extracted:
		return "EXTRACTED"
	if not get_required_objective_status(build_context(null)).get("ok", true):
		return "WAITING"
	if _requirements_pass():
		return "READY"
	return "LOCKED"
