@tool
class_name EffectSet
extends Resource

@export var set_id: StringName = &"effects"
@export var enabled: bool = true
@export var effects: Array[MissionEffect] = []
@export var stop_on_failure: bool = false
@export var debug_note: String = ""


func apply_all(context: Dictionary = {}) -> Dictionary:
	if not enabled:
		return _result(true, "disabled_effect_set", "Effect set is disabled.", String(set_id))
	var results: Array = []
	var applied_count := 0
	var failed_count := 0
	for effect in effects:
		if effect == null or not effect.enabled:
			continue
		var result: Dictionary = effect.apply(context)
		results.append(result)
		if bool(result.get("ok", false)):
			applied_count += 1
		else:
			failed_count += 1
			if stop_on_failure:
				break
	var ok := failed_count == 0
	return _result(ok, "effect_set_applied" if ok else "effect_set_failed", "Applied %d effects, %d failed." % [applied_count, failed_count], String(set_id), {
		"applied_count": applied_count,
		"failed_count": failed_count,
		"results": results,
	})


func is_empty() -> bool:
	for effect in effects:
		if effect != null and effect.enabled:
			return false
	return true


func get_designer_summary() -> String:
	var parts: Array[String] = []
	for effect in effects:
		if effect != null:
			parts.append(effect.get_designer_summary())
	return "; ".join(parts)


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
