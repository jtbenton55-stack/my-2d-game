class_name VelvetPawJazzClubMissionController
extends Node

const MISSION_ID := "velvet_paw_jazz_club"
const RETURN_TELEPORT_PATH := NodePath("../MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_02")

@export var mission_id: String = MISSION_ID
@export var return_teleport_path: NodePath = RETURN_TELEPORT_PATH

var eavesdrop_done: bool = false
var alley_intro_done: bool = false
var entered_club: bool = false
var bar_task_done: bool = false
var vip_voicemail_found: bool = false
var staff_badge_collected: bool = false
var staff_gate_open: bool = false
var clue_setlist_read: bool = false
var clue_manager_read: bool = false
var soundcheck_done: bool = false
var decoy_ledger_found: bool = false
var setlist_solved: bool = false
var backstage_hatch_open: bool = false
var yordano_briefed: bool = false
var vault_power_rerouted: bool = false
var server_vault_open: bool = false
var shard_collected: bool = false
var basement_keycard_collected: bool = false
var returned_upstairs_with_shard: bool = false
var owner_stairs_open: bool = false
var owner_defeated: bool = false
var briefcase_collected: bool = false
var escape_hatch_open: bool = false
var secret_collectible_found: bool = false
var completed_objectives: Dictionary = {}

var _last_primary_objective: String = ""


func _ready() -> void:
	set_meta("scene_local_only", true)
	_seed_objectives()
	_connect_return_teleport()
	if not Engine.is_editor_hint():
		set_process(true)


func _process(_delta: float) -> void:
	sync_from_mission_facts()


func reset_attempt_state() -> Dictionary:
	eavesdrop_done = false
	alley_intro_done = false
	entered_club = false
	bar_task_done = false
	vip_voicemail_found = false
	staff_badge_collected = false
	staff_gate_open = false
	clue_setlist_read = false
	clue_manager_read = false
	soundcheck_done = false
	decoy_ledger_found = false
	setlist_solved = false
	backstage_hatch_open = false
	yordano_briefed = false
	vault_power_rerouted = false
	server_vault_open = false
	shard_collected = false
	basement_keycard_collected = false
	returned_upstairs_with_shard = false
	owner_stairs_open = false
	owner_defeated = false
	briefcase_collected = false
	escape_hatch_open = false
	secret_collectible_found = false
	completed_objectives.clear()
	_last_primary_objective = ""
	return _seed_objectives()


func sync_from_mission_facts() -> void:
	_sync_authored_clue_flags()
	var context := {"mission_id": mission_id}
	eavesdrop_done = _mission_flag_set("vpj_eavesdrop_done", context)
	alley_intro_done = _mission_flag_set("vpj_alley_intro_done", context)
	entered_club = _mission_flag_set("vpj_entered_club", context)
	bar_task_done = _mission_flag_set("vpj_bar_task_done", context)
	vip_voicemail_found = _mission_flag_set("vpj_vip_voicemail_found", context)
	staff_badge_collected = _mission_flag_set("vpj_staff_badge_collected", context)
	staff_gate_open = _mission_flag_set("vpj_staff_gate_open", context)
	clue_setlist_read = _mission_flag_set("vpj_clue_setlist_read", context)
	clue_manager_read = _mission_flag_set("vpj_clue_manager_read", context)
	soundcheck_done = _mission_flag_set("vpj_soundcheck_done", context)
	decoy_ledger_found = _mission_flag_set("vpj_decoy_ledger_found", context)
	setlist_solved = _mission_flag_set("vpj_setlist_solved", context)
	backstage_hatch_open = _mission_flag_set("vpj_backstage_hatch_open", context)
	yordano_briefed = _mission_flag_set("vpj_yordano_briefed", context)
	vault_power_rerouted = _mission_flag_set("vpj_vault_power_rerouted", context)
	server_vault_open = _mission_flag_set("vpj_server_vault_open", context)
	shard_collected = _mission_flag_set("vpj_shard_collected", context)
	basement_keycard_collected = bool(MissionFactBridge.get_fact_value(&"inventory_has_item", "velvet_paw_basement_keycard", context))
	owner_stairs_open = _mission_flag_set("vpj_owner_stairs_open", context)
	owner_defeated = _mission_flag_set("vpj_owner_defeated", context)
	briefcase_collected = _mission_flag_set("vpj_briefcase_collected", context)
	escape_hatch_open = _mission_flag_set("vpj_escape_hatch_open", context)
	secret_collectible_found = _mission_flag_set("secret_velvet_collectible", context)
	_apply_game_state_side_effects()
	_sync_objective_chain()


func mark_returned_upstairs() -> void:
	if not shard_collected:
		return
	returned_upstairs_with_shard = true
	_apply_game_state_side_effects()
	_sync_objective_chain()


func trigger_wrong_note_alarm(payload: Dictionary, _context: Dictionary = {}) -> void:
	var mission := get_tree().current_scene
	if mission == null or not mission.has_method("get_security_event_router"):
		return
	var router: Variant = mission.call("get_security_event_router")
	if router is Node and (router as Node).has_method("emit_event"):
		var event_id := StringName(String(payload.get("event_id", "wrong_note_alarm")))
		(router as Node).call("emit_event", event_id, payload)


func _mission_flag_set(flag_id: String, context: Dictionary) -> bool:
	return bool(MissionFactBridge.get_fact_value(&"mission_flag", flag_id, context))


func _apply_game_state_side_effects() -> void:
	var changed := false
	if shard_collected and not GameState.velvet_paw_basement_shard_collected:
		GameState.velvet_paw_basement_shard_collected = true
		changed = true
	if basement_keycard_collected and not GameState.velvet_paw_basement_keycard_collected:
		GameState.velvet_paw_basement_keycard_collected = true
		changed = true
	if shard_collected and returned_upstairs_with_shard and not GameState.velvet_paw_club_hostile:
		GameState.velvet_paw_club_hostile = true
		changed = true
	if changed:
		EventBus.game_state_changed.emit()


func _sync_authored_clue_flags() -> void:
	var mission := get_tree().current_scene
	if mission == null or not mission.has_method("get_authored_collectible_attempt_snapshot"):
		return
	var snapshot: Dictionary = mission.call("get_authored_collectible_attempt_snapshot")
	for clue_value: Variant in snapshot.get("clues", []):
		if not (clue_value is Dictionary):
			continue
		var clue_id := String((clue_value as Dictionary).get("id", ""))
		if clue_id == "velvet_paw_jazz_club.clue_author.01":
			_set_mission_flag("vpj_clue_setlist_read")
		elif clue_id == "velvet_paw_jazz_club.clue_author.02":
			_set_mission_flag("vpj_clue_manager_read")


func _set_mission_flag(flag_id: String) -> void:
	MissionFactBridge.set_fact_value(&"mission_flag", flag_id, true, {"mission_id": mission_id})


func _connect_return_teleport() -> void:
	var return_zone := get_node_or_null(return_teleport_path)
	if return_zone == null or not return_zone.has_signal("activation_succeeded"):
		return
	if not return_zone.activation_succeeded.is_connected(_on_return_teleport_succeeded):
		return_zone.activation_succeeded.connect(_on_return_teleport_succeeded)


func _on_return_teleport_succeeded(_mechanic_id: String, _result: Dictionary) -> void:
	sync_from_mission_facts()
	mark_returned_upstairs()


func _sync_objective_chain() -> void:
	if entered_club and _complete_once("enter_club"):
		ObjectiveStepController.activate_objective("collect_staff_badge", "Grab the staff badge from the dressing area.", mission_id)
	if staff_badge_collected and _complete_once("collect_staff_badge"):
		ObjectiveStepController.activate_objective("open_staff_gate", "Swipe into the stage wing.", mission_id)
	if staff_gate_open and _complete_once("open_staff_gate"):
		ObjectiveStepController.activate_objective("read_setlist_clues", "Read both setlist clues backstage.", mission_id)
	if clue_setlist_read and clue_manager_read and _complete_once("read_setlist_clues"):
		ObjectiveStepController.activate_objective("solve_setlist", "Solve the five-song stage setlist.", mission_id)
	if setlist_solved and _complete_once("solve_setlist"):
		ObjectiveStepController.activate_objective("recover_shard", "Reach the basement server vault and recover Sterling's shard.", mission_id)
	if shard_collected and _complete_once("recover_shard"):
		ObjectiveStepController.activate_objective("return_upstairs", "Get back upstairs with the ledger shard.", mission_id)
	if GameState.velvet_paw_club_hostile and _complete_once("return_upstairs"):
		ObjectiveStepController.activate_objective("defeat_owner", "Reach the rig stairs and clear the owner suite.", mission_id)
	if owner_defeated and _complete_once("defeat_owner"):
		ObjectiveStepController.activate_objective("recover_briefcase", "Grab the blackmail briefcase on the balcony.", mission_id)
	if briefcase_collected and _complete_once("recover_briefcase"):
		ObjectiveStepController.activate_objective("open_escape", "Release the basement escape hatch.", mission_id)
	if escape_hatch_open and _complete_once("open_escape"):
		ObjectiveStepController.activate_objective("extract_basement", "Escape on Yordano's bass drop.", mission_id)
	_set_primary_objective(_current_primary_objective())


func _complete_once(objective_id: String) -> bool:
	if completed_objectives.has(objective_id):
		return false
	completed_objectives[objective_id] = true
	ObjectiveStepController.complete_objective(objective_id, "", mission_id)
	return true


func _current_primary_objective() -> String:
	if not entered_club:
		return "The Velvet Paw is hopping tonight. Find the propped staff entrance."
	if not staff_gate_open:
		return "Avoid the bouncers, find the green-room staff badge, and reach the stage wing."
	if not setlist_solved:
		return "Read both backstage clues, then solve the five-song setlist on stage."
	if not shard_collected:
		return "Open the service hatch and recover Sterling's shard from the basement server vault."
	if not GameState.velvet_paw_club_hostile:
		return "Get back upstairs with the ledger shard."
	if not owner_defeated:
		return "The club has gone hostile. Use the rig stairs and clear the owner suite."
	if not briefcase_collected:
		return "Briefcase on the balcony. Grab it and don't admire the view."
	if not escape_hatch_open:
		return "Release the basement escape hatch."
	return "Bass drop time. Escape through the basement exit before the bouncers regroup."


func _set_primary_objective(text: String) -> void:
	if text == _last_primary_objective:
		return
	_last_primary_objective = text
	QuestManager.set_objective(text, mission_id)


func _seed_objectives() -> Dictionary:
	return MissionObjectiveBridge.seed_runtime_objectives_for_mission(mission_id, [
		{"id": "enter_club", "text": "Find the propped staff entrance.", "status": "active"},
		{"id": "collect_staff_badge", "text": "Grab the staff badge from the dressing area.", "status": "locked"},
		{"id": "open_staff_gate", "text": "Swipe into the stage wing.", "status": "locked"},
		{"id": "read_setlist_clues", "text": "Read both setlist clues backstage.", "status": "locked"},
		{"id": "solve_setlist", "text": "Solve the five-song stage setlist.", "status": "locked"},
		{"id": "recover_shard", "text": "Recover Sterling's shard from the basement server vault.", "status": "locked"},
		{"id": "return_upstairs", "text": "Get back upstairs with the ledger shard.", "status": "locked"},
		{"id": "defeat_owner", "text": "Clear the owner suite.", "status": "locked"},
		{"id": "recover_briefcase", "text": "Grab the blackmail briefcase.", "status": "locked"},
		{"id": "open_escape", "text": "Release the basement escape hatch.", "status": "locked"},
		{"id": "extract_basement", "text": "Escape on Yordano's bass drop.", "status": "locked"},
	])
