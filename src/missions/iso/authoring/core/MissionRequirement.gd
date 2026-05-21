@tool
class_name MissionRequirement
extends Resource

enum Operator {
	EQUALS,
	NOT_EQUALS,
	EXISTS,
	NOT_EXISTS,
	GREATER_THAN,
	GREATER_OR_EQUAL,
	LESS_THAN,
	LESS_OR_EQUAL,
}

@export var requirement_id: StringName = &"requirement"
@export var enabled: bool = true
@export var fact_type: StringName = &"always"
@export var key: String = ""
@export var operator: Operator = Operator.EQUALS
@export var expected_bool: bool = true
@export var expected_int: int = 1
@export var expected_float: float = 1.0
@export var expected_string: String = ""
@export_enum("bool", "int", "float", "string", "exists") var expected_value_type: String = "bool"
@export var fail_message: String = ""
@export var debug_note: String = ""


func evaluate(context: Dictionary = {}) -> Dictionary:
	if not enabled:
		return _result(true, "disabled_requirement", "Requirement is disabled.", String(requirement_id))
	if not MissionFactBridge.is_known_fact_type(fact_type):
		return _result(false, "unknown_fact_type", "Unknown fact type: %s." % String(fact_type), String(requirement_id), {"fact_type": String(fact_type)})
	var actual: Variant = MissionFactBridge.get_fact_value(fact_type, key, context)
	var expected: Variant = get_expected_value()
	var ok := _compare(actual, expected)
	var message := get_designer_summary() if ok else _failure_message(actual, expected)
	return _result(ok, "requirement_passed" if ok else "requirement_failed", message, String(requirement_id), {
		"fact_type": String(fact_type),
		"key": key,
		"operator": operator,
		"expected": expected,
		"actual": actual,
	})


func get_expected_value() -> Variant:
	match expected_value_type:
		"int":
			return expected_int
		"float":
			return expected_float
		"string":
			return expected_string
		"exists":
			return true
		_:
			return expected_bool


func get_designer_summary() -> String:
	return "Requires %s %s %s %s" % [String(fact_type), key, _operator_label(), str(get_expected_value())]


func _compare(actual: Variant, expected: Variant) -> bool:
	match operator:
		Operator.EXISTS:
			return _exists(actual)
		Operator.NOT_EXISTS:
			return not _exists(actual)
		Operator.EQUALS:
			return _values_equal(actual, expected)
		Operator.NOT_EQUALS:
			return not _values_equal(actual, expected)
		Operator.GREATER_THAN:
			return _numeric(actual) > _numeric(expected)
		Operator.GREATER_OR_EQUAL:
			return _numeric(actual) >= _numeric(expected)
		Operator.LESS_THAN:
			return _numeric(actual) < _numeric(expected)
		Operator.LESS_OR_EQUAL:
			return _numeric(actual) <= _numeric(expected)
	return false


func _failure_message(actual: Variant, expected: Variant) -> String:
	if fail_message.strip_edges() != "":
		return fail_message
	return "%s failed. Expected %s, got %s." % [get_designer_summary(), str(expected), str(actual)]


func _operator_label() -> String:
	match operator:
		Operator.NOT_EQUALS:
			return "!="
		Operator.EXISTS:
			return "exists"
		Operator.NOT_EXISTS:
			return "does not exist"
		Operator.GREATER_THAN:
			return ">"
		Operator.GREATER_OR_EQUAL:
			return ">="
		Operator.LESS_THAN:
			return "<"
		Operator.LESS_OR_EQUAL:
			return "<="
		_:
			return "=="


func _exists(value: Variant) -> bool:
	if value == null:
		return false
	match typeof(value):
		TYPE_BOOL:
			return bool(value)
		TYPE_STRING, TYPE_STRING_NAME:
			return String(value).strip_edges() != ""
		TYPE_ARRAY:
			return (value as Array).size() > 0
		TYPE_DICTIONARY:
			return (value as Dictionary).size() > 0
		_:
			return true


func _values_equal(actual: Variant, expected: Variant) -> bool:
	if typeof(actual) in [TYPE_INT, TYPE_FLOAT] or typeof(expected) in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(actual), float(expected))
	return actual == expected


func _numeric(value: Variant) -> float:
	match typeof(value):
		TYPE_BOOL:
			return 1.0 if bool(value) else 0.0
		TYPE_INT, TYPE_FLOAT:
			return float(value)
		TYPE_STRING, TYPE_STRING_NAME:
			return float(String(value))
		_:
			return 0.0


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
