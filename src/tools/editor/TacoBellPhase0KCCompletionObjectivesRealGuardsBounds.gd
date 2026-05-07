@tool
class_name TacoBellPhase0KCCompletionObjectivesRealGuardsBounds
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/taco_bell_phase_0kc_completion_objectives_real_guards_bounds.md"
const REPORT_JSON := "res://docs/reports/taco_bell_phase_0kc_completion_objectives_real_guards_bounds.json"
const CONTRACT_MD := "res://docs/reports/taco_bell_phase_0kc_marker_authoring_contract.md"


static func summary() -> Dictionary:
	return {
		"phase": "0K-C",
		"target_scene": TARGET_SCENE,
		"source_scene": SOURCE_SCENE,
		"repairs": [
			"Louis mission completion",
			"running active/completed objective lists",
			"real guard-style patrol and attack visuals",
			"expanded runtime marker bounds cleanup"
		],
		"reports": [REPORT_MD, REPORT_JSON, CONTRACT_MD],
	}
