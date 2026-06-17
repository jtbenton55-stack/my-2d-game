@tool
class_name MissionModifierSet
extends Resource

@export var modifier_id: StringName = &"modifier"
@export var source_card_id: StringName = &""
@export var requirements: RequirementSet
@export var setup_effects: EffectSet
@export var debug_note: String = ""


func evaluate_requirements(context: Dictionary = {}) -> Dictionary:
	if requirements == null:
		return _result(true, "no_modifier_requirements", "Modifier has no requirements.")
	return requirements.evaluate(_modifier_context(context))


func passes_requirements(context: Dictionary = {}) -> bool:
	return bool(evaluate_requirements(context).get("ok", false))


func has_setup_effects() -> bool:
	return setup_effects != null and not setup_effects.is_empty()


func apply_setup_effects(context: Dictionary = {}) -> Dictionary:
	if not has_setup_effects():
		return _result(true, "no_setup_effects", "Modifier has no setup effects.")
	return setup_effects.apply_all(_modifier_context(context))


func matches_source_card(card_id: String) -> bool:
	var source := String(source_card_id).strip_edges()
	return source == "" or source == card_id.strip_edges()


func get_designer_summary() -> String:
	var source := String(source_card_id).strip_edges()
	if source == "":
		source = "any card"
	var requirement_summary := "no requirements" if requirements == null else requirements.get_designer_summary()
	var effect_summary := "no setup effects" if not has_setup_effects() else setup_effects.get_designer_summary()
	return "%s from %s: %s -> %s" % [String(modifier_id), source, requirement_summary, effect_summary]


func _modifier_context(context: Dictionary) -> Dictionary:
	var out := context.duplicate(true)
	out["modifier_id"] = String(modifier_id)
	out["source_card_id"] = String(source_card_id)
	return out


func _result(ok: bool, code: String, message: String) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": String(modifier_id),
		"details": {
			"modifier_id": String(modifier_id),
			"source_card_id": String(source_card_id),
		},
	}
