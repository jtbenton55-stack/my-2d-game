class_name MissionCutsceneDefinition
extends Resource

enum CutsceneType {
	MICRO,
	MISSION_BEAT,
	EMOTIONAL
}

@export var cutscene_id: String = ""
@export var type: CutsceneType = CutsceneType.MICRO
@export var trigger_id: String = ""
@export var once_only: bool = true
@export var objective_update: String = ""
@export var pause_seconds: float = 0.0
@export var lines: Array[Dictionary] = []
