class_name ReactiveNpcFallbackDriver
extends RefCounted


static func execute_reaction(reaction_id: String, signal_event: Resource, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	var signal_id := String(signal_event.get("signal_id")) if signal_event != null else String(context.get("signal_id", ""))
	var signal_type := String(signal_event.get("signal_type")) if signal_event != null else String(context.get("signal_type", ""))
	var target_id := String(payload.get("target_investigation_point_id", payload.get("target_authority_id", "")))
	var details := payload.duplicate(true)
	details["signal_id"] = signal_id
	details["signal_type"] = signal_type
	details["fallback_driver"] = true
	match reaction_id:
		"ignore":
			return _result(true, "reaction_ignored", "Fallback ignored the signal safely.", signal_id, details)
		"look_toward":
			return _result(true, "reaction_look_toward", "Fallback recorded a look-toward reaction.", signal_id, details)
		"inspect_point":
			return _result(true, "reaction_inspect_point", "Fallback targeted investigation point %s." % target_id, signal_id, details)
		"question_player":
			return _result(true, "reaction_question_player", "Fallback recorded a bounded player question.", signal_id, details)
		"report_to_authority":
			return _result(true, "reaction_report_to_authority", "Fallback reported to authority %s." % target_id, signal_id, details)
		"block_route":
			return _result(true, "reaction_block_route", "Fallback recorded route block.", signal_id, details)
		"change_patrol":
			return _result(true, "reaction_change_patrol", "Fallback recorded routine/patrol change.", signal_id, details)
		"raise_local_suspicion":
			return _result(true, "reaction_raise_local_suspicion", "Fallback recorded local suspicion increase.", signal_id, details)
		"trigger_dialogue_bark":
			return MissionDialogueBridge.play_bark(String(payload.get("speaker", "Witness")), String(payload.get("bark_text", "I saw that.")), context)
		"request_encounter_meter_delta":
			return _adjust_encounter_meter(payload, context)
		"apply_effect_set":
			return _result(true, "reaction_apply_effect_set", "Fallback delegated to rule effect set.", signal_id, details)
	return _result(false, "unsupported_reaction", "Fallback does not support reaction: %s." % reaction_id, signal_id, details)


static func _adjust_encounter_meter(payload: Dictionary, context: Dictionary) -> Dictionary:
	var controller: Variant = context.get("encounter_controller", null)
	if controller == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			controller = tree.get_first_node_in_group("mission_encounter_controller")
	if controller == null or not controller.has_method("adjust_meter"):
		return _result(false, "encounter_controller_missing", "Encounter controller missing for fallback meter delta.")
	return controller.call("adjust_meter", String(payload.get("meter_id", "suspicion")), int(payload.get("meter_delta", 1)), payload)


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
