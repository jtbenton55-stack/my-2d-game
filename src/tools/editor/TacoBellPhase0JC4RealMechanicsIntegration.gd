@tool
class_name TacoBellPhase0JC4RealMechanicsIntegration
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/taco_bell_phase_0jc4_real_mechanics_integration.md"
const REPORT_JSON := "res://docs/reports/taco_bell_phase_0jc4_real_mechanics_integration.json"


static func phase_summary() -> Dictionary:
	return {
		"phase": "0J-C4",
		"target_scene": TARGET_SCENE,
		"source_scene": SOURCE_SCENE,
		"scope": "real mechanic integration for Phase0J pickups, state adapters, code gate, and marker parity audit",
		"wall_collision_policy": "preserve Phase0J-B2 WallCollision exactly",
		"report_md": REPORT_MD,
		"report_json": REPORT_JSON,
	}
