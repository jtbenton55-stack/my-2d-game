@tool
class_name TacoBellPhase0JCInteractables
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const MANIFEST_PATH := "res://assets/missions/layouts/taco_bell_expanded_layout_v6.json"
const PICKUP_SCRIPT := "res://src/missions/iso/runtime/Phase0JInteractablePickup.gd"
const BRIDGE_SCRIPT := "res://src/missions/iso/runtime/Phase0JInteractionBridge.gd"
const CODE_GATE_SCRIPT := "res://src/missions/iso/runtime/Phase0JCodeGateController.gd"

const COLLECTIBLE_CATEGORIES := PackedStringArray(["BAG", "CLUE", "PHOTO", "GLOW", "TINY"])
const GENERATED_BY := "Phase0J-C"


static func is_collectible_like(category: String, manifest_id: String) -> bool:
	if COLLECTIBLE_CATEGORIES.has(category):
		return true
	if manifest_id == "OBJ_bag_recovery":
		return true
	return false


static func interaction_contract_summary() -> Dictionary:
	return {
		"player_script": "res://src/player/Player.gd",
		"interact_action": "interact",
		"q_action": "case_the_joint",
		"strategy": "hybrid_existing_player_contract_plus_scene_local_q_bridge",
		"required_group": "interactable",
		"phase0j_bridge_group": "phase0j_interactable",
		"required_method": "interact(player)",
		"player_distance_px": 72.0,
		"bridge_distance_px": 88.0,
		"interactable_collision_layer_bitmask": 8,
		"interactable_collision_mask_bitmask": 1,
	}
