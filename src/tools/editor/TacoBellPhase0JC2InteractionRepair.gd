@tool
class_name TacoBellPhase0JC2InteractionRepair
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/taco_bell_phase_0jc2_interaction_repair.md"
const REPORT_JSON := "res://docs/reports/taco_bell_phase_0jc2_interaction_repair.json"


static func phase_summary() -> Dictionary:
	return {
		"phase": "0J-C2",
		"target_scene": TARGET_SCENE,
		"source_scene": SOURCE_SCENE,
		"scope": "live interaction repair, marker labels, debug HUD, code input UI",
		"wall_collision_policy": "preserve Phase0J-B2 WallCollision exactly",
		"report_md": REPORT_MD,
		"report_json": REPORT_JSON,
	}
