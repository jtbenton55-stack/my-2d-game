extends SceneTree

const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"
const BLUEPRINT_PATH := "res://docs/blueprints/velvet_paw_jazz_club.blueprint.json"
const MISSION_ID := "velvet_paw_jazz_club"
const Spec := preload("res://src/tools/authoring/LevelBlueprintSpec.gd")
const EFFECT_SET_MISSION_FLAG := 0
const EFFECT_COMPLETE_OBJECTIVE := 4
const EFFECT_GRANT_EVIDENCE_CLUE := 9
const EFFECT_SET_ALERT_STATE := 12
const EFFECT_TRIGGER_SIMPLE_DIALOGUE := 15
const EFFECT_CALL_METHOD := 20

const SCRIPTS: Dictionary = {
	"SearchZone": "res://src/missions/iso/authoring/mechanics/SearchZone.gd",
	"RewardNode": "res://src/missions/iso/authoring/mechanics/RewardNode.gd",
	"InventoryPickupNode": "res://src/missions/iso/authoring/mechanics/InventoryPickupNode.gd",
	"BentleyCrawlspaceConnector": "res://src/missions/iso/authoring/mechanics/BentleyCrawlspaceConnector.gd",
	"BentleyWaitMarker": "res://src/missions/iso/authoring/mechanics/BentleyWaitMarker.gd",
	"NoiseEmitterNode": "res://src/missions/iso/runtime/noise/NoiseEmitterNode.gd",
	"DistractionObject": "res://src/missions/iso/authoring/mechanics/DistractionObject.gd",
	"LockedInteractionNode": "res://src/missions/iso/authoring/mechanics/LockedInteractionNode.gd",
	"TerminalHackNode": "res://src/missions/iso/authoring/mechanics/TerminalHackNode.gd",
	"PowerCircuitNode": "res://src/missions/iso/authoring/mechanics/PowerCircuitNode.gd",
	"DeadDropNode": "res://src/missions/iso/authoring/mechanics/DeadDropNode.gd",
	"BugPlantNode": "res://src/missions/iso/authoring/mechanics/BugPlantNode.gd",
	"EavesdropZone": "res://src/missions/iso/authoring/mechanics/EavesdropZone.gd",
	"AuditTrailCleanupNode": "res://src/missions/iso/authoring/mechanics/AuditTrailCleanupNode.gd",
	"HeatSinkObject": "res://src/missions/iso/authoring/mechanics/HeatSinkObject.gd",
	"InspectionZone": "res://src/missions/iso/authoring/mechanics/InspectionZone.gd",
	"BelievableTaskZone": "res://src/missions/iso/authoring/mechanics/BelievableTaskZone.gd",
	"ProtocolZone": "res://src/missions/iso/authoring/mechanics/ProtocolZone.gd",
	"ProfessionalismMeterNode": "res://src/missions/iso/authoring/mechanics/ProfessionalismMeterNode.gd",
	"EncounterController": "res://src/missions/iso/encounters/EncounterController.gd",
	"ChallengeObjectiveNode": "res://src/missions/iso/authoring/mechanics/ChallengeObjectiveNode.gd",
	"DisruptionActionNode": "res://src/missions/iso/authoring/mechanics/DisruptionActionNode.gd",
	"SchemeCardTriggerNode": "res://src/missions/iso/authoring/mechanics/SchemeCardTriggerNode.gd",
	"HideSpotNode": "res://src/missions/iso/authoring/mechanics/HideSpotNode.gd",
	"InvestigationPointNode": "res://src/missions/iso/authoring/mechanics/InvestigationPointNode.gd",
	"PresentationSequencePlayer": "res://src/missions/iso/presentation/PresentationSequencePlayer.gd",
	"PlayerStartMarker": "res://src/missions/iso/authoring/mechanics/PlayerStartMarker.gd",
	"TeleportZone": "res://src/missions/iso/authoring/mechanics/TeleportZone.gd",
	"TeleportTargetMarker": "res://src/missions/iso/authoring/mechanics/TeleportTargetMarker.gd",
	"MusicTriggerZone": "res://src/missions/iso/authoring/mechanics/MusicTriggerZone.gd",
	"SecurityBeamAuthor": "res://src/missions/iso/authoring/SecurityBeamAuthor.gd",
	"SecurityCameraAuthor": "res://src/missions/iso/authoring/SecurityCameraAuthor.gd",
	"GuardSpawnAuthor": "res://src/missions/iso/authoring/GuardSpawnAuthor.gd",
	"GuardPatrolRouteAuthor": "res://src/missions/iso/authoring/GuardPatrolRouteAuthor.gd",
	"SecurityEffectSetAuthor": "res://src/missions/iso/authoring/SecurityEffectSetAuthor.gd",
	"PoopBagAuthor": "res://src/missions/iso/authoring/PoopBagAuthor.gd",
	"CaseCashAuthor": "res://src/missions/iso/authoring/CaseCashAuthor.gd",
	"ClueAuthor": "res://src/missions/iso/authoring/ClueAuthor.gd",
	"GlowGuyAuthor": "res://src/missions/iso/authoring/GlowGuyAuthor.gd",
	"DialogueTriggerZone": "res://src/missions/iso/presentation/DialogueTriggerZone.gd",
	"BarkTrigger": "res://src/missions/iso/presentation/BarkTrigger.gd",
	"RouteUnlockNode": "res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd",
	"InteractiveContainer": "res://src/missions/iso/authoring/mechanics/InteractiveContainer.gd",
	"ExtractionZone": "res://src/missions/iso/authoring/mechanics/ExtractionZone.gd",
	"SideObjectiveNode": "res://src/missions/iso/authoring/mechanics/SideObjectiveNode.gd",
	"TriggerZone": "res://src/missions/iso/authoring/mechanics/TriggerZone.gd",
}

const ID_PROPERTY_BY_TYPE: Dictionary = {
	"EncounterController": "encounter_id",
	"PresentationSequencePlayer": "intro_sequence_id",
	"SecurityBeamAuthor": "beam_id",
	"SecurityCameraAuthor": "camera_id",
	"GuardSpawnAuthor": "spawn_id",
	"GuardPatrolRouteAuthor": "route_id",
	"SecurityEffectSetAuthor": "effect_id",
	"PoopBagAuthor": "collectible_id",
	"CaseCashAuthor": "collectible_id",
	"ClueAuthor": "collectible_id",
	"GlowGuyAuthor": "collectible_id",
	"PlayerStartMarker": "marker_id",
	"TeleportTargetMarker": "target_id",
}

const NODE_TYPES: Array[String] = ["ProfessionalismMeterNode", "EncounterController"]
const MARKER_TYPES: Array[String] = ["PlayerStartMarker", "TeleportTargetMarker"]
const NODE2D_TYPES: Array[String] = [
	"PresentationSequencePlayer", "SecurityBeamAuthor", "SecurityCameraAuthor",
	"GuardSpawnAuthor", "GuardPatrolRouteAuthor", "SecurityEffectSetAuthor",
	"PoopBagAuthor", "CaseCashAuthor", "ClueAuthor", "GlowGuyAuthor",
]


func _initialize() -> void:
	var result := _place_stubs()
	print(JSON.stringify(result))
	quit(0 if bool(result.get("ok", false)) else 1)


func _place_stubs() -> Dictionary:
	var packed := load(SCENE_PATH) as PackedScene
	var loaded := Spec.load_spec(BLUEPRINT_PATH)
	if packed == null or not bool(loaded.get("ok", false)):
		return {"ok": false, "error": "scene_or_blueprint_load_failed", "details": loaded}
	var root := packed.instantiate()
	var placed := 0
	var updated := 0
	var skipped := 0
	var failed: Array[String] = []
	var by_slot: Dictionary = {}
	for entry: Variant in Spec.mechanic_slots(loaded.get("spec", {})):
		var slot := entry as Dictionary
		var mechanic_type := String(slot.get("mechanic_type", ""))
		var suggested_id := String(slot.get("suggested_id", ""))
		var node_name := "%s_%s" % [mechanic_type, suggested_id.replace(".", "_")]
		var existing := root.find_child(node_name, true, false)
		if existing != null:
			_configure_node(existing, root, slot)
			by_slot[String(slot.get("slot_id", ""))] = existing
			updated += 1
			continue
		var parent := root.get_node_or_null(_parent_path(mechanic_type))
		var script := load(String(SCRIPTS.get(mechanic_type, ""))) as Script
		if parent == null or script == null:
			failed.append(String(slot.get("slot_id", suggested_id)))
			continue
		var node := _new_node(mechanic_type)
		node.name = node_name
		node.set_script(script)
		parent.add_child(node)
		node.owner = root
		_configure_node(node, root, slot)
		by_slot[String(slot.get("slot_id", ""))] = node
		if node is Area2D:
			_add_shape(node as Area2D, root, Spec.slot_size(slot))
		placed += 1
	_wire_mission(root, by_slot)
	var save_error := ResourceSaver.save(_pack(root), SCENE_PATH)
	root.free()
	return {
		"ok": failed.is_empty() and save_error == OK,
		"placed": placed,
		"updated": updated,
		"skipped": skipped,
		"failed": failed,
		"save_error": save_error,
		"order": "blueprint_source_order",
	}


func _new_node(mechanic_type: String) -> Node:
	if mechanic_type in NODE_TYPES:
		return Node.new()
	if mechanic_type in MARKER_TYPES:
		return Marker2D.new()
	if mechanic_type in NODE2D_TYPES:
		return Node2D.new()
	return Area2D.new()


func _parent_path(mechanic_type: String) -> String:
	if mechanic_type in Spec.SECURITY_PARENT_TYPES:
		return "GameplayRoot/SecurityAuthoringRoot"
	if mechanic_type == "PlayerStartMarker":
		return "GameplayRoot/MarkerRoot/Spawns"
	return "GameplayRoot/MissionMechanics"


func _configure_node(node: Node, root: Node, slot: Dictionary) -> void:
	var mechanic_type := String(slot.get("mechanic_type", ""))
	var suggested_id := String(slot.get("suggested_id", ""))
	if node is Node2D:
		(node as Node2D).position = Spec.slot_position(slot)
	var id_property := String(ID_PROPERTY_BY_TYPE.get(mechanic_type, "mechanic_id"))
	if id_property in node:
		node.set(id_property, StringName(suggested_id))
	if mechanic_type == "ClueAuthor" and "clue_id" in node:
		node.set("clue_id", StringName(suggested_id))
	if mechanic_type == "GlowGuyAuthor" and "glow_guy_id" in node:
		node.set("glow_guy_id", StringName(suggested_id))
	if "mission_id_override" in node:
		node.set("mission_id_override", MISSION_ID)
	if "display_name" in node:
		node.set("display_name", String(slot.get("slot_id", mechanic_type)).replace("_", " ").capitalize())
	var zone_size := Spec.slot_size(slot)
	if zone_size == Vector2.ZERO:
		zone_size = Vector2(96, 96)
	if "shape_size" in node:
		node.set("shape_size", zone_size)
	if node.owner == null and node != root:
		node.owner = root


func _add_shape(area: Area2D, root: Node, requested_size: Vector2) -> void:
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		area.add_child(shape_node)
		shape_node.owner = root
	var rectangle := RectangleShape2D.new()
	rectangle.size = requested_size if requested_size != Vector2.ZERO else Vector2(96, 96)
	shape_node.shape = rectangle


func _wire_mission(root: Node, nodes: Dictionary) -> void:
	_ensure_mission_controller(root)
	_wire_flags_and_requirements(nodes)
	_wire_teleports(nodes)
	_wire_security(root, nodes)
	_wire_optional_mechanics(nodes)
	_wire_dialogue(nodes)


func _ensure_mission_controller(root: Node) -> void:
	var runtime_helpers := root.get_node_or_null("GameplayRoot/RuntimeHelpers")
	if runtime_helpers == null:
		return
	var controller := runtime_helpers.get_node_or_null("VelvetPawJazzClubMissionController")
	if controller == null:
		controller = Node.new()
		controller.name = "VelvetPawJazzClubMissionController"
		controller.set_script(load("res://src/missions/iso/runtime/VelvetPawJazzClubMissionController.gd"))
		runtime_helpers.add_child(controller)
		controller.owner = root
	controller.set("mission_id", MISSION_ID)


func _wire_flags_and_requirements(nodes: Dictionary) -> void:
	_configure_mechanic(nodes, "queue_eavesdrop", [], ["vpj_eavesdrop_done"], "Listen to the front-queue patrons.")
	_set_values(nodes.get("queue_eavesdrop"), {"completed_flag": &"vpj_eavesdrop_done"})
	_configure_mechanic(nodes, "alley_dialogue", [], ["vpj_alley_intro_done"], "Check the alley with Bentley.")
	_configure_mechanic(nodes, "side_door_entry", [], ["vpj_entered_club"], "Enter through the propped staff door.")
	_configure_mechanic(nodes, "bar_task", [], ["vpj_bar_task_done"], "Clear glasses and look like you belong.")
	_configure_mechanic(nodes, "floor_inspection", ["vpj_bar_task_done"], [], "Pass the floor inspection.", "Look professional first: clear glasses at the bar.")
	_configure_mechanic(nodes, "vip_phone_search", [], ["vpj_vip_voicemail_found"], "Check the VIP phone.")
	_set_values(nodes.get("vip_phone_search"), {"searched_flag": &"vpj_vip_voicemail_found", "found_message": "Sterling's assistant: Shred before midnight; badge hangs in the green room."})
	_configure_mechanic(nodes, "staff_badge_pickup", [], ["vpj_staff_badge_collected"], "Take the staff badge.")
	_set_values(nodes.get("staff_badge_pickup"), {"item_id": &"velvet_paw_staff_badge", "item_category": "credential", "collected_flag": &"vpj_staff_badge_collected", "reward_id": &"velvet_paw_staff_badge", "requirements": _soft_requirements("req_staff_badge_voicemail_soft", "vpj_vip_voicemail_found", "The voicemail points to the badge in the green room.")})
	_configure_mechanic(nodes, "staff_gate", ["vpj_staff_badge_collected"], ["vpj_staff_gate_open"], "Swipe the staff badge.", "The stage wing requires a staff badge.")
	_set_values(nodes.get("staff_gate"), {"unlocked_flag": &"vpj_staff_gate_open", "lock_kind": "gate"})
	_set_values(nodes.get("clue_setlist"), {"objective_id": &"read_setlist_clue", "pickup_event_id": &"vpj_clue_setlist_collected", "hideout_collection_key": &"velvet_paw_setlist_fragment", "clue_title": "Crumpled Setlist Fragment", "clue_text": "Album arc tonight - start where we started hungry, ballad in the middle breath, end where the jury listens."})
	_set_values(nodes.get("clue_manager_notes"), {"objective_id": &"read_manager_clue", "pickup_event_id": &"vpj_clue_manager_collected", "hideout_collection_key": &"velvet_paw_manager_notes", "clue_title": "Stage Manager's Notes", "clue_text": "Five songs only. Follow the release timeline, not the merch table. An extra title is wrong even when it rhymes."})
	_configure_mechanic(nodes, "soundcheck_task", ["vpj_staff_gate_open"], ["vpj_soundcheck_done"], "Run the stage-wing sound check.")
	_set_values(nodes.get("soundcheck_task"), {"objective_id": &"velvet_paw_soundcheck", "objective_text": "Run the stage-wing sound check.", "objective_flag": &"vpj_soundcheck_done"})
	_configure_mechanic(nodes, "backstage_crate_search", ["vpj_clue_setlist_read", "vpj_clue_manager_read"], ["vpj_decoy_ledger_found"], "Search the backstage prop crates.", "Read both setlist clues first.")
	_set_values(nodes.get("backstage_crate_search"), {"searched_flag": &"vpj_decoy_ledger_found", "found_message": "The ledger is a prop: blank pages, planted by Sterling's crew. The real route points below the stage."})
	_configure_mechanic(nodes, "setlist_terminal", ["vpj_clue_setlist_read", "vpj_clue_manager_read"], ["vpj_setlist_solved"], "Decode the five-song setlist.", "Two setlist clues are still missing.", "solve_setlist")
	_set_values(nodes.get("setlist_terminal"), {"completed_flag": &"vpj_setlist_solved", "hack_id": &"velvet_paw_setlist_sequence", "failure_effects": _alert_effects("vpj_wrong_note_failure")})
	var terminal_effects: Resource = nodes.get("setlist_terminal").get("success_effects")
	terminal_effects.effects.append(_effect("grant_jazz_club_encoded_setlist", EFFECT_GRANT_EVIDENCE_CLUE, "jazz_club_encoded_setlist", "dictionary", {"title": "Yordano's Encoded Setlist", "description": "The five-song order decodes Sterling's blackmail routing.", "connects_to": "Rewrite Room", "mission_id": MISSION_ID}))
	_configure_mechanic(nodes, "backstage_hatch", ["vpj_setlist_solved"], ["vpj_backstage_hatch_open"], "Open the service hatch.")
	_set_values(nodes.get("backstage_hatch"), {"route_id": &"velvet_paw_basement_hatch", "route_flag": &"vpj_backstage_hatch_open"})
	_configure_mechanic(nodes, "basement_teleport", ["vpj_backstage_hatch_open"], [], "Drop into the basement.")
	_configure_mechanic(nodes, "yordano_dialogue", ["vpj_backstage_hatch_open"], ["vpj_yordano_briefed"], "Listen to Yordano's vault briefing.")
	_configure_mechanic(nodes, "vault_power", ["vpj_yordano_briefed"], ["vpj_vault_power_rerouted"], "Reroute power on the bass swell.")
	_set_values(nodes.get("vault_power"), {"circuit_id": &"velvet_paw_vault_power", "circuit_flag": &"vpj_vault_power_rerouted"})
	_configure_mechanic(nodes, "server_vault", ["vpj_vault_power_rerouted"], ["vpj_server_vault_open"], "Release the server-vault maglock.", "Reroute vault power first.")
	_set_values(nodes.get("server_vault"), {"unlocked_flag": &"vpj_server_vault_open", "lock_kind": "safe"})
	_configure_mechanic(nodes, "ledger_shard", ["vpj_server_vault_open"], ["vpj_shard_collected"], "Take Sterling's purple ledger shard.", "Open the server vault first.", "recover_shard")
	_set_values(nodes.get("ledger_shard"), {"item_id": &"velvet_paw_ledger_shard", "item_category": "evidence", "collected_flag": &"vpj_shard_collected", "reward_id": &"velvet_paw_ledger_shard"})
	_configure_mechanic(nodes, "basement_keycard", ["vpj_server_vault_open"], [], "Take the Black Ledger keycard.")
	_set_values(nodes.get("basement_keycard"), {"item_id": &"velvet_paw_basement_keycard", "item_category": "credential", "collected_flag": &"", "reward_id": &"velvet_paw_basement_keycard"})
	_configure_mechanic(nodes, "return_teleport", ["vpj_shard_collected"], [], "Climb back to the club.", "Take the ledger shard before returning.")
	_configure_mechanic(nodes, "owner_stairs", [], ["vpj_owner_stairs_open"], "Use the keycard on the rig stairs.", "The hostile club route needs the basement keycard.")
	nodes.get("owner_stairs").set("requirements", _owner_stairs_requirements())
	_set_values(nodes.get("owner_stairs"), {"unlocked_flag": &"vpj_owner_stairs_open", "lock_kind": "scanner"})
	_configure_mechanic(nodes, "suite_teleport", ["vpj_owner_stairs_open"], [], "Climb to the owner suite.")
	_configure_mechanic(nodes, "owner_encounter", ["vpj_owner_stairs_open"], ["vpj_owner_defeated"], "Clear the owner's challenge.", "Reach the suite first.", "defeat_owner")
	_set_values(nodes.get("owner_encounter"), {"encounter_controller_path": NodePath("../EncounterController_velvet_paw_jazz_club_encounter_controller_01"), "event_id": &"velvet_paw_owner_cleared", "result_tag": &"owner_defeated", "wins_encounter": true, "advances_phase": false})
	_configure_mechanic(nodes, "briefcase_reward", ["vpj_owner_defeated"], ["vpj_briefcase_collected"], "Grab it and don't admire the view.", "The owner still controls the suite.", "recover_briefcase")
	_set_values(nodes.get("briefcase_reward"), {"reward_kind": "evidence", "reward_id": &"velvet_paw_blackmail_briefcase", "collected_flag": &"vpj_briefcase_collected"})
	_configure_mechanic(nodes, "shelf_goblin_secret", ["vpj_briefcase_collected"], ["secret_velvet_collectible"], "Search the balcony shelf.")
	_set_values(nodes.get("shelf_goblin_secret"), {"searched_flag": &"secret_velvet_collectible", "found_message": "A tiny velvet Shelf Goblin. Evidence can be tasteful."})
	_configure_mechanic(nodes, "escape_route", ["vpj_briefcase_collected"], ["vpj_escape_hatch_open"], "Release the basement escape hatch.", "Take the blackmail briefcase first.", "open_escape")
	_set_values(nodes.get("escape_route"), {"route_id": &"velvet_paw_escape_hatch", "route_flag": &"vpj_escape_hatch_open"})
	_configure_mechanic(nodes, "extraction", ["vpj_escape_hatch_open", "vpj_briefcase_collected"], [], "Escape on Yordano's bass drop.", "Open the escape hatch and recover the briefcase.")
	_set_values(nodes.get("extraction"), {"extraction_tag": &"velvet_paw_basement_escape", "extraction_flag": &"", "complete_mission_on_success": true, "required_objective_ids": [&"solve_setlist", &"recover_shard", &"defeat_owner", &"recover_briefcase", &"open_escape"], "missing_objective_message": "Finish the setlist, shard, owner, briefcase, and escape objectives first."})


func _wire_teleports(nodes: Dictionary) -> void:
	_link_teleport(nodes, "basement_teleport", "basement_arrival")
	_link_teleport(nodes, "return_teleport", "return_marker")
	_link_teleport(nodes, "suite_teleport", "suite_arrival")


func _link_teleport(nodes: Dictionary, zone_slot: String, target_slot: String) -> void:
	var zone: Node = nodes.get(zone_slot)
	var target: Node = nodes.get(target_slot)
	if zone == null or target == null:
		return
	zone.set("target_marker_path", zone.get_path_to(target))
	zone.set("require_prior_interaction", true)


func _wire_security(root: Node, nodes: Dictionary) -> void:
	_add_waypoints(root, nodes.get("bouncer_route_a"), [Vector2(-256, -128), Vector2(192, 64), Vector2(-128, 192)])
	_add_waypoints(root, nodes.get("bouncer_route_b"), [Vector2(-256, 0), Vector2(192, -192), Vector2(256, 128)])
	_set_values(nodes.get("bouncer_spawn_a"), {"trigger_events": [&"velvet_paw_patrol_start"], "initial_behavior": &"patrol", "fallback_behavior": &"patrol", "patrol_route_id": nodes.get("bouncer_route_a").get("route_id"), "one_shot": true})
	_set_values(nodes.get("bouncer_spawn_b"), {"trigger_events": [&"velvet_paw_patrol_start"], "initial_behavior": &"patrol", "fallback_behavior": &"patrol", "patrol_route_id": nodes.get("bouncer_route_b").get("route_id"), "one_shot": true})
	_set_values(nodes.get("alarm_spawn"), {"trigger_events": [&"wrong_note_alarm"], "initial_behavior": &"attack_player", "spawn_count": 1, "max_alive_from_this_spawn": 1, "cooldown_seconds": 8.0, "one_shot": false})
	_set_values(nodes.get("wrong_note_alarm"), {"trigger_events": [&"wrong_note_alarm"], "effects": _alert_effects("wrong_note_alarm_effects"), "mission_id_override": MISSION_ID, "one_shot": false, "cooldown_seconds": 8.0, "debug_chain_label": "wrong_note_alarm -> alerted + reinforcement"})
	_set_values(nodes.get("camera_vip"), {"direction_degrees": 90.0, "range_px": 360.0, "fov_degrees": 52.0, "sweep_enabled": true, "sweep_arc_degrees": 65.0, "sweep_speed_degrees": 28.0, "on_alarm_event": &"camera_alarm"})
	_set_values(nodes.get("camera_basement"), {"direction_degrees": 90.0, "range_px": 300.0, "fov_degrees": 48.0, "sweep_enabled": true, "sweep_arc_degrees": 45.0, "sweep_speed_degrees": 22.0, "on_alarm_event": &"camera_alarm"})
	_set_values(nodes.get("beam_suite"), {"alarm_id": &"velvet_paw_suite_beam", "on_trip_event": &"suite_beam_tripped", "visual_height": 192.0, "visual_width": 24.0, "trigger_width": 56.0})
	_set_values(nodes.get("encounter_controller"), {"mission_id_override": MISSION_ID, "display_name": "Velvet Paw Hostile Return", "start_on_ready": false, "initial_phase_id": &"hostile_return"})


func _wire_optional_mechanics(nodes: Dictionary) -> void:
	_set_values(nodes.get("bathroom_glow_guy"), {"glow_guy_id": &"velvet_bathroom_glow_guy", "hideout_collection_key": &"velvet_bathroom_glow_guy", "display_name": "Bathroom Glow Guy"})
	_set_values(nodes.get("suite_stash"), {"hideout_collection_key": &"velvet_suite_stash", "display_name": "Owner Suite Stash"})
	_configure_mechanic(nodes, "dead_drop", ["vpj_vip_voicemail_found"], [], "Leave a copy of the voicemail for Mere.")
	_configure_mechanic(nodes, "bug_plant", ["vpj_owner_defeated"], [], "Plant a bug in the owner's desk phone.")
	_configure_mechanic(nodes, "lights_disruption", ["vpj_shard_collected"], [], "Cut the club strobes.")
	_configure_mechanic(nodes, "hidden_polaroid", ["vpj_setlist_solved"], [], "Capture Bentley in the stage-wing spotlight.")
	_configure_mechanic(nodes, "escape_music", ["vpj_briefcase_collected"], [], "Cue the escape bass drop.")
	_set_values(nodes.get("scheme_card_bassdrop"), {"require_matching_modifier": true, "missing_card_message": "Equip Yordano's Bass Drop scheme card."})
	for slot in ["poop_bag_alley", "poop_bag_basement", "poop_bag_floor"]:
		_set_values(nodes.get(slot), {"hideout_collection_key": StringName(slot), "display_name": "Bentley Poop Bag"})


func _wire_dialogue(nodes: Dictionary) -> void:
	_set_values(nodes.get("alley_dialogue"), {
		"fallback_speaker": "Bentley",
		"fallback_text": "(Too many colognes. The bass line is honest, though.)",
	})
	_set_values(nodes.get("queue_eavesdrop"), {
		"prompt_text": "Listen: the staff side door stays propped open between sets.",
	})
	_set_values(nodes.get("vip_phone_search"), {
		"found_message": "Assistant voicemail: Shred before midnight. The badge is in the green room.",
	})
	_set_values(nodes.get("clue_setlist"), {
		"clue_text": "Album arc tonight - start where we started hungry, ballad in the middle breath, end where the jury listens.",
	})
	_set_values(nodes.get("clue_manager_notes"), {
		"clue_text": "Setlist policy: five songs only - follow the release timeline, not the merch table. If an extra title sneaks in, it's wrong even when it rhymes.",
	})
	var stage_steps: Array[Dictionary] = [{
		"id": "stage_downbeat",
		"type": "simple_dialogue",
		"speaker": "Yordano",
		"text": "House lights love you. Don't waste the downbeat.",
	}]
	_set_values(nodes.get("stage_presentation"), {
		"sequence_steps": stage_steps,
	})
	var terminal: Node = nodes.get("setlist_terminal")
	if terminal != null:
		var success_effects: Resource = terminal.get("success_effects")
		if success_effects != null:
			success_effects.effects.append(_simple_dialogue_effect(
				"stage_downbeat_dialogue",
				"Yordano",
				"House lights love you. Don't waste the downbeat."
			))
		var failure_effects: Resource = terminal.get("failure_effects")
		if failure_effects != null:
			failure_effects.effects.append(_simple_dialogue_effect(
				"wrong_note_coaching",
				"Yordano",
				"Tuck behind the bar - the rails swallow the bass spikes. Or melt into the dance floor silhouette until the strobes lie for you."
			))
			var alarm_event := _effect("emit_wrong_note_alarm", EFFECT_CALL_METHOD, "")
			alarm_event.target_path = NodePath("../../RuntimeHelpers/VelvetPawJazzClubMissionController")
			alarm_event.method_name = &"trigger_wrong_note_alarm"
			alarm_event.payload = {"event_id": "wrong_note_alarm"}
			failure_effects.effects.append(alarm_event)
	_set_values(nodes.get("yordano_dialogue"), {
		"fallback_speaker": "Yordano",
		"fallback_text": "That hum is the vault handshake. I green-lit it - go pull Sterling's purple shard before lawyers remote-wipe.",
	})
	_set_values(nodes.get("bathroom_bark"), {
		"fallback_speaker": "Bentley",
		"fallback_text": "(Bentley respects the grout lines.)",
		"bark_speaker": "Bentley",
		"bark_text": "(Bentley respects the grout lines.)",
	})
	_set_values(nodes.get("briefcase_reward"), {
		"prompt_text": "Grab it and don't admire the view.",
	})
	_set_values(nodes.get("return_teleport"), {
		"prompt_text": "Return upstairs. The club has turned hostile - every bouncer is looking for you.",
	})
	_set_values(nodes.get("escape_route"), {
		"prompt_text": "Yordano: Bass drop. Release the escape hatch and move.",
	})
	_set_values(nodes.get("backstage_crate_search"), {
		"found_message": "Blank pages. Sterling's crew planted a prop ledger. The real route points below the stage.",
	})


func _simple_dialogue_effect(effect_id: String, speaker: String, text: String) -> Resource:
	return _effect(
		effect_id,
		EFFECT_TRIGGER_SIMPLE_DIALOGUE,
		"",
		"dictionary",
		{"speaker": speaker, "text": text, "fallback_speaker": speaker, "fallback_text": text}
	)


func _configure_mechanic(nodes: Dictionary, slot: String, required_flags: Array[String], success_flags: Array[String], prompt: String, locked: String = "Unavailable", objective_id: String = "") -> void:
	var node: Node = nodes.get(slot)
	if node == null:
		return
	if "prompt_text" in node:
		node.set("prompt_text", prompt)
	if "locked_prompt_text" in node:
		node.set("locked_prompt_text", locked)
	if "requirements" in node and not required_flags.is_empty():
		node.set("requirements", _requirements("req_%s" % slot, required_flags, locked))
	if "success_effects" in node and (not success_flags.is_empty() or objective_id != ""):
		node.set("success_effects", _success_effects("effects_%s" % slot, success_flags, objective_id))


func _requirements(set_id: String, flags: Array[String], locked: String) -> Resource:
	var requirement_script := load("res://src/missions/iso/authoring/core/MissionRequirement.gd") as Script
	var set_script := load("res://src/missions/iso/authoring/core/RequirementSet.gd") as Script
	var rows := Array([], TYPE_OBJECT, &"Resource", requirement_script)
	for flag in flags:
		var requirement: Resource = requirement_script.new()
		requirement.requirement_id = StringName("requires_%s" % flag)
		requirement.fact_type = &"mission_flag"
		requirement.key = flag
		requirement.operator = 2 # MissionRequirement.Operator.EXISTS
		requirement.expected_value_type = "exists"
		requirement.fail_message = locked
		rows.append(requirement)
	var result: Resource = set_script.new()
	result.set_id = StringName(set_id)
	result.set("requirements", rows)
	result.locked_message = locked
	return result


func _soft_requirements(set_id: String, flag: String, note: String) -> Resource:
	var requirement_script := load("res://src/missions/iso/authoring/core/MissionRequirement.gd") as Script
	var set_script := load("res://src/missions/iso/authoring/core/RequirementSet.gd") as Script
	var requirement: Resource = requirement_script.new()
	requirement.requirement_id = StringName("soft_requires_%s" % flag)
	requirement.enabled = false
	requirement.fact_type = &"mission_flag"
	requirement.key = flag
	requirement.operator = 2 # MissionRequirement.Operator.EXISTS
	requirement.expected_value_type = "exists"
	requirement.debug_note = note
	var rows := Array([], TYPE_OBJECT, &"Resource", requirement_script)
	rows.append(requirement)
	var result: Resource = set_script.new()
	result.set_id = StringName(set_id)
	result.set("requirements", rows)
	result.debug_note = "Soft narrative dependency; it documents the intended route without blocking pickup."
	return result


func _owner_stairs_requirements() -> Resource:
	var requirement_script := load("res://src/missions/iso/authoring/core/MissionRequirement.gd") as Script
	var set_script := load("res://src/missions/iso/authoring/core/RequirementSet.gd") as Script
	var shard: Resource = requirement_script.new()
	shard.requirement_id = &"requires_hostile_shard_return"
	shard.fact_type = &"mission_flag"
	shard.key = "vpj_shard_collected"
	shard.operator = 2 # MissionRequirement.Operator.EXISTS
	shard.expected_value_type = "exists"
	shard.fail_message = "Return upstairs with the ledger shard first."
	var keycard: Resource = requirement_script.new()
	keycard.requirement_id = &"requires_basement_keycard"
	keycard.fact_type = &"inventory_has_item"
	keycard.key = "velvet_paw_basement_keycard"
	keycard.operator = 0 # MissionRequirement.Operator.EQUALS
	keycard.expected_value_type = "bool"
	keycard.expected_bool = true
	keycard.fail_message = "The hostile club route needs the basement keycard."
	var rows := Array([], TYPE_OBJECT, &"Resource", requirement_script)
	rows.append(shard)
	rows.append(keycard)
	var result: Resource = set_script.new()
	result.set_id = &"req_owner_stairs_hostile_keycard"
	result.set("requirements", rows)
	result.locked_message = "Return with the shard and basement keycard."
	return result


func _success_effects(set_id: String, flags: Array[String], objective_id: String = "") -> Resource:
	var set_script := load("res://src/missions/iso/authoring/core/EffectSet.gd") as Script
	var effect_script := load("res://src/missions/iso/authoring/core/MissionEffect.gd") as Script
	var rows := Array([], TYPE_OBJECT, &"Resource", effect_script)
	for flag in flags:
		rows.append(_effect("set_%s" % flag, EFFECT_SET_MISSION_FLAG, flag))
	if objective_id != "":
		rows.append(_effect("complete_%s" % objective_id, EFFECT_COMPLETE_OBJECTIVE, objective_id, "string", {}, objective_id.replace("_", " ").capitalize()))
	var result: Resource = set_script.new()
	result.set_id = StringName(set_id)
	result.set("effects", rows)
	return result


func _alert_effects(set_id: String) -> Resource:
	var set_script := load("res://src/missions/iso/authoring/core/EffectSet.gd") as Script
	var alert := _effect("set_alerted", EFFECT_SET_ALERT_STATE, MISSION_ID, "string", {}, "alerted")
	var effect_script := load("res://src/missions/iso/authoring/core/MissionEffect.gd") as Script
	var rows := Array([], TYPE_OBJECT, &"Resource", effect_script)
	rows.append(alert)
	var result: Resource = set_script.new()
	result.set_id = StringName(set_id)
	result.set("effects", rows)
	return result


func _effect(effect_id: String, effect_type: int, key: String, value_type: String = "bool", payload: Dictionary = {}, value_string: String = "") -> Resource:
	var effect_script := load("res://src/missions/iso/authoring/core/MissionEffect.gd") as Script
	var effect: Resource = effect_script.new()
	effect.effect_id = StringName(effect_id)
	effect.effect_type = effect_type
	effect.key = key
	effect.value_type = value_type
	effect.payload = payload
	effect.value_string = value_string
	return effect


func _set_values(node: Node, values: Dictionary) -> void:
	if node == null:
		return
	for property: String in values:
		if property in node:
			node.set(property, values[property])


func _add_waypoints(root: Node, route: Node, offsets: Array[Vector2]) -> void:
	if route == null:
		return
	for index in offsets.size():
		var waypoint_name := "Waypoint%d" % index
		var waypoint := route.get_node_or_null(waypoint_name) as Node2D
		if waypoint == null:
			waypoint = Node2D.new()
			waypoint.name = waypoint_name
			route.add_child(waypoint)
			waypoint.owner = root
		waypoint.position = offsets[index]


func _pack(root: Node) -> PackedScene:
	var packed := PackedScene.new()
	packed.pack(root)
	return packed
