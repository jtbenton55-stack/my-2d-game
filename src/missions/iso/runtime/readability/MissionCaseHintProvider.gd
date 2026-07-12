class_name MissionCaseHintProvider
extends Node

const CaseHintDefinitionScript := preload("res://src/missions/iso/runtime/readability/CaseHintDefinition.gd")

@export var hints: Array[CaseHintDefinitionScript] = []

var _last_shown_msec: Dictionary = {}


func _ready() -> void:
	add_to_group("mission_case_hint_provider")


func request_hint(actor: Node, now_msec: int = -1) -> Dictionary:
	var result := select_hint(actor, now_msec)
	if not bool(result.get("ok", false)):
		return result
	var definition: CaseHintDefinitionScript = result.get("definition")
	var selected_time := Time.get_ticks_msec() if now_msec < 0 else now_msec
	_last_shown_msec[definition.get_instance_id()] = selected_time
	EventBus.case_hint_requested.emit(definition.text.strip_edges(), definition.speaker.strip_edges())
	return result


func select_hint(actor: Node, now_msec: int = -1) -> Dictionary:
	if not (actor is Node2D):
		return {"ok": false, "code": "invalid_actor"}
	var selected_time := Time.get_ticks_msec() if now_msec < 0 else now_msec
	var candidates: Array[Dictionary] = []
	for index in hints.size():
		var definition := hints[index]
		if not _is_eligible(definition, actor as Node2D, selected_time):
			continue
		candidates.append({"definition": definition, "index": index})
	if candidates.is_empty():
		return {"ok": false, "code": "no_available_hint"}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_hint: CaseHintDefinitionScript = a["definition"]
		var b_hint: CaseHintDefinitionScript = b["definition"]
		if a_hint.priority != b_hint.priority:
			return a_hint.priority > b_hint.priority
		return int(a["index"]) < int(b["index"])
	)
	return {
		"ok": true,
		"code": "hint_selected",
		"definition": candidates[0]["definition"],
		"authored_index": candidates[0]["index"],
	}


func _is_eligible(definition: CaseHintDefinitionScript, actor: Node2D, now_msec: int) -> bool:
	if definition == null or definition.text.strip_edges() == "":
		return false
	var context := {
		"actor": actor,
		"provider": self,
		"mission_id": String(GameState.current_mission_id),
	}
	if definition.requirements != null and not definition.requirements.passes(context):
		return false
	if definition.anchor_path != NodePath() and definition.max_distance > 0.0:
		var anchor := get_node_or_null(definition.anchor_path) as Node2D
		if anchor == null or actor.global_position.distance_to(anchor.global_position) > definition.max_distance:
			return false
	var last_shown := int(_last_shown_msec.get(definition.get_instance_id(), -1_000_000_000))
	return now_msec - last_shown >= int(maxf(definition.cooldown, 0.0) * 1000.0)
