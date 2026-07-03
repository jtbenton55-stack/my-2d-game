class_name MissionEffectApplier
extends RefCounted

const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const SocialSignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")


static func apply_effect(effect: Resource, context: Dictionary = {}) -> Dictionary:
	if effect == null:
		return _result(false, "missing_effect", "Effect resource is missing.")
	if not bool(effect.get("enabled")):
		return _result(true, "disabled_effect", "Effect is disabled.", String(effect.get("effect_id")))
	match int(effect.get("effect_type")):
		MissionEffect.EffectType.SET_MISSION_FLAG:
			return MissionFactBridge.set_fact_value(&"mission_flag", String(effect.get("key")), effect.call("get_value"), context)
		MissionEffect.EffectType.CLEAR_MISSION_FLAG:
			return MissionFactBridge.clear_fact_value(&"mission_flag", String(effect.get("key")), context)
		MissionEffect.EffectType.SET_DIALOGUE_FLAG:
			return MissionFactBridge.set_fact_value(&"dialogue_flag", String(effect.get("key")), effect.call("get_value"), context)
		MissionEffect.EffectType.ACTIVATE_OBJECTIVE:
			return _apply_objective(effect, context, "active")
		MissionEffect.EffectType.COMPLETE_OBJECTIVE:
			return _apply_objective(effect, context, "completed")
		MissionEffect.EffectType.FAIL_OBJECTIVE:
			return _apply_objective(effect, context, "failed")
		MissionEffect.EffectType.SET_PRIMARY_OBJECTIVE_TEXT:
			return _apply_primary_objective_text(effect, context)
		MissionEffect.EffectType.GRANT_CARD:
			return MissionFactBridge.set_fact_value(&"unlocked_card", String(effect.get("key")), true, context)
		MissionEffect.EffectType.GRANT_TYPED_COLLECTIBLE:
			var typed_context := context.duplicate(true)
			typed_context["payload"] = _payload(effect)
			return MissionFactBridge.set_fact_value(&"typed_collectible", String(effect.get("key")), true, typed_context)
		MissionEffect.EffectType.GRANT_EVIDENCE_CLUE:
			var clue_context := context.duplicate(true)
			clue_context["payload"] = _payload(effect)
			return MissionFactBridge.set_fact_value(&"evidence_clue", String(effect.get("key")), true, clue_context)
		MissionEffect.EffectType.ADD_POOP_BAG:
			return _apply_poop_bag(true, effect)
		MissionEffect.EffectType.CONSUME_POOP_BAG:
			return _apply_poop_bag(false, effect)
		MissionEffect.EffectType.SET_ALERT_STATE:
			return _apply_alert_state(effect, context)
		MissionEffect.EffectType.ADD_ALERT_EXPOSURE:
			return _apply_alert_exposure(effect, context)
		MissionEffect.EffectType.EMIT_EVENTBUS_DEBUG:
			return _apply_eventbus_debug(effect)
		MissionEffect.EffectType.TOGGLE_NODE:
			return _apply_toggle_node(effect, context)
		MissionEffect.EffectType.CALL_METHOD:
			return _apply_call_method(effect, context)
		MissionEffect.EffectType.GRANT_ITEM:
			return _apply_grant_item(effect)
		MissionEffect.EffectType.REMOVE_ITEM:
			return _apply_remove_item(effect)
		MissionEffect.EffectType.CLEAR_MISSION_ITEMS:
			return MissionInventoryScript.clear_mission_items()
		MissionEffect.EffectType.RECORD_PAPER_TRACE:
			return _apply_record_paper_trace(effect, context)
		MissionEffect.EffectType.CLEANUP_PAPER_TRACE:
			return _apply_cleanup_paper_trace(effect, context)
		MissionEffect.EffectType.REDIRECT_PAPER_TRACE:
			return _apply_redirect_paper_trace(effect, context)
		MissionEffect.EffectType.ACTIVATE_COVER_STORY:
			return SocialStealthAdapterScript.set_cover_story(String(effect.get("key")), _payload(effect), context)
		MissionEffect.EffectType.GRANT_CREDENTIAL:
			return SocialStealthAdapterScript.grant_credential(String(effect.get("key")), _payload(effect), context)
		MissionEffect.EffectType.COMPLETE_PROTOCOL:
			return SocialStealthAdapterScript.complete_protocol(String(effect.get("key")), _payload(effect), context)
		MissionEffect.EffectType.COMPLETE_BELIEVABLE_TASK:
			return SocialStealthAdapterScript.complete_task(String(effect.get("key")), _payload(effect), context)
		MissionEffect.EffectType.ADJUST_PROFESSIONALISM:
			return SocialStealthAdapterScript.adjust_professionalism(int(effect.call("get_value")), context)
		MissionEffect.EffectType.SET_PROFESSIONALISM:
			return SocialStealthAdapterScript.set_professionalism(int(effect.call("get_value")), context)
		MissionEffect.EffectType.ADJUST_CLEANLINESS:
			return SocialStealthAdapterScript.adjust_cleanliness(int(effect.call("get_value")), context)
		MissionEffect.EffectType.SET_CLEANLINESS:
			return SocialStealthAdapterScript.set_cleanliness(int(effect.call("get_value")), context)
		MissionEffect.EffectType.RECORD_ENCOUNTER_EVENT:
			return _apply_encounter_event(effect, context)
		MissionEffect.EffectType.SET_ENCOUNTER_PHASE:
			return _apply_set_encounter_phase(effect, context)
		MissionEffect.EffectType.ADJUST_ENCOUNTER_METER:
			return _apply_adjust_encounter_meter(effect, context)
		MissionEffect.EffectType.SET_ENCOUNTER_RESULT_TAG:
			return _apply_set_encounter_result_tag(effect, context)
		MissionEffect.EffectType.RECORD_SOCIAL_SIGNAL:
			return _apply_record_social_signal(effect, context)
		MissionEffect.EffectType.EVALUATE_REACTIVE_NPC_SIGNAL:
			return _apply_evaluate_reactive_signal(effect, context)
		MissionEffect.EffectType.SET_REACTIVE_NPC_RESULT_TAG:
			return ReactiveNpcBrainAdapterScript.set_result_tag(String(effect.get("key")), bool(effect.call("get_value")), context)
		MissionEffect.EffectType.TRIGGER_DIALOGUE_KEY:
			return _apply_dialogue_key(effect, context)
		MissionEffect.EffectType.TRIGGER_SIMPLE_DIALOGUE:
			return _apply_simple_dialogue(effect, context)
		MissionEffect.EffectType.REQUEST_MISSION_COMPLETE:
			return _apply_mission_complete(effect, context)
		MissionEffect.EffectType.REQUEST_MISSION_FAIL:
			return _apply_mission_fail(effect, context)
	return _result(false, "unknown_effect_type", "Unknown effect type.", String(effect.get("effect_id")))


static func _apply_objective(effect: Resource, context: Dictionary, action: String) -> Dictionary:
	var quest_manager := _autoload("QuestManager")
	if quest_manager == null:
		return _result(false, "quest_manager_missing", "QuestManager autoload is missing.", String(effect.get("effect_id")))
	var mission_id: String = MissionFactBridge.resolve_mission_id(context)
	var objective_id := String(effect.get("key"))
	var text := String(effect.get("value_string"))
	if objective_id == "":
		return _result(false, "objective_id_missing", "Objective effect is missing key/objective_id.", String(effect.get("effect_id")))
	match action:
		"active":
			if quest_manager.has_method("add_objective"):
				quest_manager.call("add_objective", objective_id, text, "active", mission_id)
		"completed":
			if quest_manager.has_method("complete_objective_id"):
				quest_manager.call("complete_objective_id", objective_id, text, mission_id)
		"failed":
			if quest_manager.has_method("add_objective"):
				quest_manager.call("add_objective", objective_id, text, "failed", mission_id)
	return _result(true, "objective_%s" % action, "Objective %s: %s." % [action, objective_id], String(effect.get("effect_id")), {"mission_id": mission_id, "objective_id": objective_id})


static func _apply_primary_objective_text(effect: Resource, context: Dictionary) -> Dictionary:
	var quest_manager := _autoload("QuestManager")
	if quest_manager == null or not quest_manager.has_method("set_objective"):
		return _result(false, "quest_manager_missing", "QuestManager objective API is missing.", String(effect.get("effect_id")))
	var mission_id: String = MissionFactBridge.resolve_mission_id(context)
	var text := String(effect.call("get_value"))
	quest_manager.call("set_objective", text, mission_id)
	return _result(true, "primary_objective_set", "Primary objective text set.", String(effect.get("effect_id")), {"mission_id": mission_id, "text": text})


static func _apply_poop_bag(add: bool, effect: Resource) -> Dictionary:
	var game_state := _autoload("GameState")
	if game_state == null:
		return _result(false, "game_state_missing", "GameState autoload is missing.", String(effect.get("effect_id")))
	if add and game_state.has_method("add_poop_bag"):
		game_state.call("add_poop_bag")
		return _result(true, "poop_bag_added", "Poop bag added.", String(effect.get("effect_id")))
	if not add and game_state.has_method("try_consume_poop_bag"):
		var consumed := bool(game_state.call("try_consume_poop_bag"))
		return _result(consumed, "poop_bag_consumed" if consumed else "poop_bag_unavailable", "Poop bag consumed." if consumed else "No poop bag available.", String(effect.get("effect_id")))
	return _result(false, "poop_bag_api_missing", "Poop bag API is missing.", String(effect.get("effect_id")))


static func _apply_grant_item(effect: Resource) -> Dictionary:
	var item_id := String(effect.get("key")).strip_edges()
	if item_id == "":
		return _result(false, "item_id_missing", "Grant item effect is missing key/item_id.", String(effect.get("effect_id")))
	var data := _payload(effect)
	data["item_id"] = item_id
	return MissionInventoryScript.add_item(item_id, _item_amount(effect), data)


static func _apply_remove_item(effect: Resource) -> Dictionary:
	var item_id := String(effect.get("key")).strip_edges()
	if item_id == "":
		return _result(false, "item_id_missing", "Remove item effect is missing key/item_id.", String(effect.get("effect_id")))
	return MissionInventoryScript.remove_item(item_id, _item_amount(effect))


static func _apply_record_paper_trace(effect: Resource, context: Dictionary) -> Dictionary:
	var data := _payload(effect)
	var source_id := String(data.get("source_id", context.get("source_id", effect.get("effect_id"))))
	var trace_type := String(data.get("trace_type", "generic"))
	var severity := int(data.get("severity", effect.get("value_int") if String(effect.get("value_type")) == "int" else 1))
	return PaperTrailAdapterScript.record_trace(
		String(effect.get("key")),
		source_id,
		trace_type,
		severity,
		bool(data.get("can_cleanup", true)),
		String(data.get("cleanup_requirement", "")),
		context,
		data
	)


static func _apply_cleanup_paper_trace(effect: Resource, context: Dictionary) -> Dictionary:
	var data := _payload(effect)
	data["trace_id"] = String(effect.get("key")) if String(effect.get("key")).strip_edges() != "" else String(data.get("trace_id", ""))
	if not data.has("cleanup_strength") and String(effect.get("value_type")) == "int":
		data["cleanup_strength"] = int(effect.get("value_int"))
	return PaperTrailAdapterScript.cleanup_traces(data, context)


static func _apply_redirect_paper_trace(effect: Resource, context: Dictionary) -> Dictionary:
	var data := _payload(effect)
	data["trace_id"] = String(effect.get("key")) if String(effect.get("key")).strip_edges() != "" else String(data.get("trace_id", ""))
	var explanation := String(data.get("explanation_id", effect.get("value_string")))
	return PaperTrailAdapterScript.redirect_traces(data, explanation, context)


static func _apply_alert_state(effect: Resource, context: Dictionary) -> Dictionary:
	var controller := _find_alert_controller()
	var state := String(effect.call("get_value"))
	if controller != null and controller.has_method("set_alert_state"):
		controller.call("set_alert_state", state)
		return _result(true, "alert_state_set", "Alert controller state set to %s." % state, String(effect.get("effect_id")))
	return MissionFactBridge.set_fact_value(&"alert_state", String(effect.get("key")), state, context)


static func _apply_alert_exposure(effect: Resource, context: Dictionary) -> Dictionary:
	var controller := _find_alert_controller()
	if controller == null or not controller.has_method("accumulate_exposure"):
		return _result(false, "alert_controller_missing", "MissionAlertController is missing.", String(effect.get("effect_id")))
	var source_id := String(context.get("source_id", effect.get("effect_id")))
	var kind := String(_payload(effect).get("kind", "authored_effect"))
	controller.call("accumulate_exposure", source_id, float(effect.call("get_value")), kind)
	return _result(true, "alert_exposure_added", "Alert exposure added.", String(effect.get("effect_id")), {"source_id": source_id, "kind": kind})


static func _apply_eventbus_debug(effect: Resource) -> Dictionary:
	var event_bus := _autoload("EventBus")
	if event_bus != null and event_bus.has_method("debug"):
		event_bus.call("debug", String(effect.call("get_value")))
		return _result(true, "debug_emitted", "Debug message emitted.", String(effect.get("effect_id")))
	return _result(false, "event_bus_missing", "EventBus autoload is missing.", String(effect.get("effect_id")))


static func _apply_dialogue_key(effect: Resource, context: Dictionary) -> Dictionary:
	var dialogue_context := context.duplicate(true)
	dialogue_context["payload"] = _payload(effect)
	return MissionDialogueBridge.play_dialogue_key(String(effect.get("key")), dialogue_context)


static func _apply_simple_dialogue(effect: Resource, context: Dictionary) -> Dictionary:
	return MissionDialogueBridge.play_simple_line(_payload(effect), context)


static func _apply_mission_complete(effect: Resource, context: Dictionary) -> Dictionary:
	var mission_id := String(effect.get("key")).strip_edges()
	return MissionCompletionBridge.request_complete(mission_id, context)


static func _apply_mission_fail(effect: Resource, context: Dictionary) -> Dictionary:
	var mission_id := String(effect.get("key")).strip_edges()
	var payload := _payload(effect)
	var reason := String(payload.get("reason", "")).strip_edges()
	if reason == "":
		reason = String(effect.get("value_string")).strip_edges()
	if reason == "":
		reason = "The job went sideways."
	return MissionCompletionBridge.request_fail(mission_id, reason, context)


static func _apply_encounter_event(effect: Resource, context: Dictionary) -> Dictionary:
	var controller := _find_encounter_controller(context)
	if controller == null or not controller.has_method("record_event"):
		return _result(false, "encounter_controller_missing", "EncounterController is missing.", String(effect.get("effect_id")))
	var event_id := String(effect.get("key")).strip_edges()
	if event_id == "":
		event_id = String(effect.get("effect_id"))
	return controller.call("record_event", event_id, _payload(effect))


static func _apply_set_encounter_phase(effect: Resource, context: Dictionary) -> Dictionary:
	var controller := _find_encounter_controller(context)
	if controller == null or not controller.has_method("set_phase"):
		return _result(false, "encounter_controller_missing", "EncounterController is missing.", String(effect.get("effect_id")))
	var phase_id := String(effect.get("key")).strip_edges()
	if phase_id == "":
		phase_id = String(effect.call("get_value")).strip_edges()
	return controller.call("set_phase", phase_id, String(effect.get("effect_id")))


static func _apply_adjust_encounter_meter(effect: Resource, context: Dictionary) -> Dictionary:
	var controller := _find_encounter_controller(context)
	if controller == null or not controller.has_method("adjust_meter"):
		return _result(false, "encounter_controller_missing", "EncounterController is missing.", String(effect.get("effect_id")))
	return controller.call("adjust_meter", String(effect.get("key")), int(effect.call("get_value")), _payload(effect))


static func _apply_set_encounter_result_tag(effect: Resource, context: Dictionary) -> Dictionary:
	var controller := _find_encounter_controller(context)
	if controller == null or not controller.has_method("set_result_tag"):
		return _result(false, "encounter_controller_missing", "EncounterController is missing.", String(effect.get("effect_id")))
	return controller.call("set_result_tag", String(effect.get("key")), bool(effect.call("get_value")))


static func _apply_record_social_signal(effect: Resource, context: Dictionary) -> Dictionary:
	var event := _signal_from_effect(effect, context)
	return ReactiveNpcBrainAdapterScript.record_signal(event, context)


static func _apply_evaluate_reactive_signal(effect: Resource, context: Dictionary) -> Dictionary:
	var event := _signal_from_effect(effect, context)
	var rule_sets: Array = []
	var raw_rules: Variant = context.get("reaction_rule_sets", [])
	if raw_rules is Array:
		rule_sets = raw_rules as Array
	var budget: Resource = context.get("attention_budget", null) as Resource
	return ReactiveNpcBrainAdapterScript.evaluate_signal(event, rule_sets, budget, context)


static func _signal_from_effect(effect: Resource, context: Dictionary) -> Resource:
	var data := _payload(effect)
	if String(effect.get("key")).strip_edges() != "":
		data["signal_id"] = String(effect.get("key"))
	if not data.has("signal_type"):
		data["signal_type"] = String(SocialSignalEventScript.SIGNAL_SUSPICIOUS_ACTION_SEEN)
	if not data.has("source_id"):
		data["source_id"] = String(context.get("source_id", effect.get("effect_id")))
	if not data.has("mission_id"):
		data["mission_id"] = MissionFactBridge.resolve_mission_id(context)
	if not data.has("severity") and String(effect.get("value_type")) == "int":
		data["severity"] = int(effect.get("value_int"))
	return SocialSignalEventScript.from_dictionary(data)


static func _apply_toggle_node(effect: Resource, context: Dictionary) -> Dictionary:
	var target := _resolve_target(effect, context)
	if target == null:
		return _result(false, "target_missing", "Toggle target node is missing.", String(effect.get("effect_id")))
	var data := _payload(effect)
	if data.has("visible") and target is CanvasItem:
		(target as CanvasItem).visible = bool(data.get("visible"))
	if data.has("process_mode"):
		target.process_mode = int(data.get("process_mode"))
	if data.has("monitoring") and target is Area2D:
		(target as Area2D).monitoring = bool(data.get("monitoring"))
	if data.has("disabled") and target is CollisionShape2D:
		(target as CollisionShape2D).disabled = bool(data.get("disabled"))
	return _result(true, "node_toggled", "Node toggled: %s." % str(target.get_path()), String(effect.get("effect_id")))


static func _apply_call_method(effect: Resource, context: Dictionary) -> Dictionary:
	var target := _resolve_target(effect, context)
	var method := StringName(effect.get("method_name"))
	if target == null or method == &"" or not target.has_method(method):
		return _result(false, "method_target_missing", "Call method target or method is missing.", String(effect.get("effect_id")))
	target.call(method, _payload(effect), context)
	return _result(true, "method_called", "Called %s on %s." % [String(method), str(target.get_path())], String(effect.get("effect_id")))


static func _resolve_target(effect: Resource, context: Dictionary) -> Node:
	var path_value: Variant = effect.get("target_path")
	if not (path_value is NodePath):
		return null
	var path := path_value as NodePath
	if path == NodePath():
		return null
	var mechanic: Variant = context.get("mechanic", null)
	if mechanic is Node:
		var target := (mechanic as Node).get_node_or_null(path)
		if target != null:
			return target
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree and (main_loop as SceneTree).current_scene != null:
		return (main_loop as SceneTree).current_scene.get_node_or_null(path)
	return null


static func _find_alert_controller() -> Node:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null
	var tree := main_loop as SceneTree
	var grouped := tree.get_first_node_in_group("iso_alert_controller")
	if grouped != null:
		return grouped
	if tree.current_scene != null:
		return tree.current_scene.find_child("MissionAlertController", true, false)
	return null


static func _find_encounter_controller(context: Dictionary = {}) -> Node:
	var contextual: Variant = context.get("encounter_controller", null)
	if contextual is Node:
		return contextual as Node
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null
	var tree := main_loop as SceneTree
	var grouped := tree.get_first_node_in_group("mission_encounter_controller")
	if grouped != null:
		return grouped
	if tree.current_scene != null:
		return tree.current_scene.find_child("EncounterController", true, false)
	return null


static func _payload(effect: Resource) -> Dictionary:
	var value: Variant = effect.get("payload")
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _item_amount(effect: Resource) -> int:
	var data := _payload(effect)
	if data.has("count"):
		return maxi(1, int(data.get("count")))
	if String(effect.get("value_type")) == "int":
		return maxi(1, int(effect.get("value_int")))
	return 1


static func _autoload(name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null(name)


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
