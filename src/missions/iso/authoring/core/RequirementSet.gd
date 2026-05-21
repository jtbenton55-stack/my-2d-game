@tool
class_name RequirementSet
extends Resource

enum MatchMode {
	ALL,
	ANY,
	NONE,
}

@export var set_id: StringName = &"requirements"
@export var enabled: bool = true
@export var match_mode: MatchMode = MatchMode.ALL
@export var requirements: Array[MissionRequirement] = []
@export var empty_set_passes: bool = true
@export var locked_message: String = ""
@export var debug_note: String = ""


func evaluate(context: Dictionary = {}) -> Dictionary:
	if not enabled:
		return _result(true, "disabled_requirement_set", "Requirement set is disabled.", String(set_id))
	var results: Array = []
	for requirement in requirements:
		if requirement == null or not requirement.enabled:
			continue
		results.append(requirement.evaluate(context))
	if results.is_empty():
		return _result(empty_set_passes, "empty_requirement_set", "Requirement set is empty." if empty_set_passes else "Requirement set is empty and configured to fail.", String(set_id), _details(results))
	var passed_count := 0
	for result in results:
		if bool(result.get("ok", false)):
			passed_count += 1
	var failed_count := results.size() - passed_count
	var ok := _passes(passed_count, results.size())
	var code := "requirements_passed" if ok else "requirements_failed"
	var message := "Requirements passed." if ok else get_failure_message_from_results(results)
	return _result(ok, code, message, String(set_id), _details(results, passed_count, failed_count))


func passes(context: Dictionary = {}) -> bool:
	return bool(evaluate(context).get("ok", false))


func get_failure_message(context: Dictionary = {}) -> String:
	return String(evaluate(context).get("message", locked_message))


func get_failure_message_from_results(results: Array) -> String:
	if locked_message.strip_edges() != "":
		return locked_message
	for result in results:
		if not bool(result.get("ok", false)):
			return String(result.get("message", "Requirement failed."))
	return "Requirements failed."


func get_designer_summary() -> String:
	var parts: Array[String] = []
	for requirement in requirements:
		if requirement != null:
			parts.append(requirement.get_designer_summary())
	return "%s: %s" % [_match_mode_label(), "; ".join(parts)]


func _passes(passed_count: int, total_count: int) -> bool:
	match match_mode:
		MatchMode.ALL:
			return passed_count == total_count
		MatchMode.ANY:
			return passed_count > 0
		MatchMode.NONE:
			return passed_count == 0
	return false


func _match_mode_label() -> String:
	match match_mode:
		MatchMode.ANY:
			return "ANY"
		MatchMode.NONE:
			return "NONE"
		_:
			return "ALL"


func _details(results: Array, passed_count: int = 0, failed_count: int = 0) -> Dictionary:
	if not results.is_empty() and passed_count == 0 and failed_count == 0:
		for result in results:
			if bool(result.get("ok", false)):
				passed_count += 1
		failed_count = results.size() - passed_count
	return {
		"match_mode": _match_mode_label(),
		"passed_count": passed_count,
		"failed_count": failed_count,
		"results": results,
	}


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
