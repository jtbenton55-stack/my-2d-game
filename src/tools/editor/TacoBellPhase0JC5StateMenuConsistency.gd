@tool
class_name TacoBellPhase0JC5StateMenuConsistency
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/taco_bell_phase_0jc5_state_menu_consistency.md"
const REPORT_JSON := "res://docs/reports/taco_bell_phase_0jc5_state_menu_consistency.json"


static func monotonic_sequence_spec() -> Array[Dictionary]:
	return [
		{"id": "GLOW_market_shop", "category": "glow_guy"},
		{"id": "BAG_dog_station", "category": "poop_bag"},
		{"id": "TINY_market_corner", "category": "tiny_icon"},
		{"id": "CLUE_security_memo", "category": "evidence_clue"},
		{"id": "OBJ_bag_recovery", "category": "objective_bag"},
	]


static func phase_summary() -> Dictionary:
	return {
		"phase": "0J-C5",
		"target_scene": TARGET_SCENE,
		"source_scene": SOURCE_SCENE,
		"scope": "set-derived counts, red debug HUD text, pause objective audit, code UI instruction clarity",
		"report_md": REPORT_MD,
		"report_json": REPORT_JSON,
	}
