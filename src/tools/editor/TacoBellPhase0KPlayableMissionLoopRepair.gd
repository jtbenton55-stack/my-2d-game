@tool
class_name TacoBellPhase0KPlayableMissionLoopRepair
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/taco_bell_phase_0k_playable_mission_loop_repair.md"
const REPORT_JSON := "res://docs/reports/taco_bell_phase_0k_playable_mission_loop_repair.json"


static func summary() -> Dictionary:
	return {
		"phase": "0K v2",
		"target_scene": TARGET_SCENE,
		"source_scene": SOURCE_SCENE,
		"features": [
			"QuestManager objective pause-menu getters",
			"safe Bentley fetch property reads",
			"three-option code gate UI without in-game hint",
			"Louis exit token",
			"visible delivery bag objective",
			"runtime camera spawner",
			"runtime guard patrol spawner"
		],
		"report_md": REPORT_MD,
		"report_json": REPORT_JSON,
	}
