@tool
class_name MissionEffect
extends Resource

enum EffectType {
	SET_MISSION_FLAG,
	CLEAR_MISSION_FLAG,
	SET_DIALOGUE_FLAG,
	ACTIVATE_OBJECTIVE,
	COMPLETE_OBJECTIVE,
	FAIL_OBJECTIVE,
	SET_PRIMARY_OBJECTIVE_TEXT,
	GRANT_CARD,
	GRANT_TYPED_COLLECTIBLE,
	GRANT_EVIDENCE_CLUE,
	ADD_POOP_BAG,
	CONSUME_POOP_BAG,
	SET_ALERT_STATE,
	ADD_ALERT_EXPOSURE,
	TRIGGER_DIALOGUE_KEY,
	TRIGGER_SIMPLE_DIALOGUE,
	EMIT_EVENTBUS_DEBUG,
	REQUEST_MISSION_COMPLETE,
	REQUEST_MISSION_FAIL,
	TOGGLE_NODE,
	CALL_METHOD,
	GRANT_ITEM,
	REMOVE_ITEM,
	CLEAR_MISSION_ITEMS,
}

@export var effect_id: StringName = &"effect"
@export var enabled: bool = true
@export var effect_type: EffectType = EffectType.SET_MISSION_FLAG
@export var key: String = ""
@export var value_bool: bool = true
@export var value_int: int = 1
@export var value_float: float = 1.0
@export var value_string: String = ""
@export_enum("bool", "int", "float", "string", "dictionary") var value_type: String = "bool"
@export var payload: Dictionary = {}
@export var target_path: NodePath
@export var method_name: StringName = &""
@export var debug_note: String = ""


func apply(context: Dictionary = {}) -> Dictionary:
	return MissionEffectApplier.apply_effect(self, context)


func get_value() -> Variant:
	match value_type:
		"int":
			return value_int
		"float":
			return value_float
		"string":
			return value_string
		"dictionary":
			return payload.duplicate(true)
		_:
			return value_bool


func get_designer_summary() -> String:
	return "%s %s -> %s" % [EffectType.keys()[effect_type], key, str(get_value())]
