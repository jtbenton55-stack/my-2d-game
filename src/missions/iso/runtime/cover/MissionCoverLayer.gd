class_name MissionCoverLayer
extends Node

## Replan Packet 3 composer: live cover meter runtime plus the challenge
## prompt. IsoMissionBase auto-mounts one per mission. RoamingInspectorNpc
## nodes are placed per-scene by level designers.

const CoverMeterRuntimeScript := preload("res://src/missions/iso/runtime/cover/CoverMeterRuntime.gd")
const CoverChallengePromptScript := preload("res://src/missions/iso/runtime/cover/CoverChallengePrompt.gd")

@export var enable_cover_meter: bool = true
@export var enable_challenge_prompt: bool = true

var cover_meter: Node = null
var challenge_prompt: CanvasLayer = null


func _ready() -> void:
	add_to_group("mission_cover_layer")
	if enable_cover_meter and cover_meter == null:
		cover_meter = CoverMeterRuntimeScript.new()
		cover_meter.name = "CoverMeterRuntime"
		add_child(cover_meter)
	if enable_challenge_prompt and challenge_prompt == null:
		challenge_prompt = CoverChallengePromptScript.new() as CanvasLayer
		challenge_prompt.name = "CoverChallengePrompt"
		add_child(challenge_prompt)


func get_cover_layer_summary() -> Dictionary:
	return {
		"cover_meter": cover_meter != null,
		"challenge_prompt": challenge_prompt != null,
		"alibi_active": cover_meter != null and bool(cover_meter.call("is_alibi_active")),
	}
