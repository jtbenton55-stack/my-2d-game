@tool
class_name ChallengeMeterData
extends Resource

@export var meter_id: StringName = &"meter"
@export var display_name: String = "Challenge Meter"
@export var min_value: int = 0
@export var max_value: int = 10
@export var initial_value: int = 0
@export var warning_value: int = 3
@export var danger_value: int = 1
@export var favorable_when_high: bool = true
@export var result_tag: StringName = &""


func clamp_value(value: int) -> int:
	return clampi(value, min_value, max_value)


func get_initial_value() -> int:
	return clamp_value(initial_value)


func get_status(value: int) -> String:
	var clamped := clamp_value(value)
	if favorable_when_high:
		if clamped <= danger_value:
			return "danger"
		if clamped <= warning_value:
			return "warning"
		return "stable"
	if clamped >= danger_value:
		return "danger"
	if clamped >= warning_value:
		return "warning"
	return "stable"


func to_summary(value: int) -> Dictionary:
	return {
		"meter_id": String(meter_id),
		"display_name": display_name,
		"value": clamp_value(value),
		"min_value": min_value,
		"max_value": max_value,
		"status": get_status(value),
		"favorable_when_high": favorable_when_high,
		"result_tag": String(result_tag),
	}
