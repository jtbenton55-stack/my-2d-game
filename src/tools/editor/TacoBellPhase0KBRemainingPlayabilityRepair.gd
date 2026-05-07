@tool
class_name TacoBellPhase0KBRemainingPlayabilityRepair
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/taco_bell_phase_0kb_remaining_playability_repair.md"
const REPORT_JSON := "res://docs/reports/taco_bell_phase_0kb_remaining_playability_repair.json"


static func summary() -> Dictionary:
	return {
		"phase": "0K-B",
		"target_scene": TARGET_SCENE,
		"source_scene": SOURCE_SCENE,
		"repairs": [
			"delivery bag moved to reachable bag-room floor cell",
			"Phase0K camera/guard spawner global-position parenting fix",
			"wrong-code attack guard threshold spawner",
			"runtime hiding for out-of-floor debug-only labels/interactables"
		],
		"report_md": REPORT_MD,
		"report_json": REPORT_JSON,
	}
