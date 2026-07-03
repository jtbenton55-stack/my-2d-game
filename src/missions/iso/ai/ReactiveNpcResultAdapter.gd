class_name ReactiveNpcResultAdapter
extends RefCounted

const BrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")


static func annotate_mission_result(result: Dictionary) -> Dictionary:
	return BrainAdapterScript.annotate_mission_result(result)


static func get_active_summary(mission_id: String = "") -> Dictionary:
	return BrainAdapterScript.get_summary(mission_id)
