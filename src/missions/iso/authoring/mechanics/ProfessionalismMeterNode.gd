@tool
class_name ProfessionalismMeterNode
extends Node

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export var mechanic_id: StringName = &"professionalism_meter"
@export var display_name: String = "Professionalism Meter"
@export var mission_id_override: String = ""
@export var meter_id: StringName = &"professionalism"
@export var initial_professionalism: int = 0
@export var initial_cleanliness: int = 0
@export var apply_initial_on_ready: bool = true


func _ready() -> void:
	if Engine.is_editor_hint() or not apply_initial_on_ready:
		return
	SocialStealthAdapterScript.set_professionalism(initial_professionalism, _context())
	SocialStealthAdapterScript.set_cleanliness(initial_cleanliness, _context())


func adjust_professionalism(delta: int) -> Dictionary:
	return SocialStealthAdapterScript.adjust_professionalism(delta, _context())


func adjust_cleanliness(delta: int) -> Dictionary:
	return SocialStealthAdapterScript.adjust_cleanliness(delta, _context())


func get_summary() -> Dictionary:
	return SocialStealthAdapterScript.get_summary(_resolved_mission_id())


func _context() -> Dictionary:
	return {"mission_id": _resolved_mission_id(), "source_id": String(meter_id), "mechanic": self}


func _resolved_mission_id() -> String:
	var override := mission_id_override.strip_edges()
	if override != "":
		return override
	return MissionFactBridge.resolve_mission_id({})
