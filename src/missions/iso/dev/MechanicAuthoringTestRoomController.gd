extends Node2D

const DEV_MISSION_ID := "mechanic_authoring_test"
const MOVE_SPEED := 220.0

@export var status_label_path: NodePath = NodePath("UI/StatusLabel")

@onready var _player: Node2D = $Player
@onready var _bridge: Node = $MissionInteractionBridge
@onready var _status_label: Label = get_node_or_null(status_label_path) as Label

var _game_state_snapshot: Dictionary = {}


func _ready() -> void:
	_snapshot_game_state()
	GameState.current_mission_id = DEV_MISSION_ID
	GameState.pending_mission_id = ""
	GameState.dialogue_flags.clear()
	if _bridge != null:
		_bridge.set("player_path", _bridge.get_path_to(_player))
	_configure_triggers()
	_configure_locks()
	_configure_searches()
	_configure_exits()
	_configure_containers()
	_configure_rewards()
	_configure_routes()
	_configure_side_objectives()
	_configure_multi_instance()
	_refresh_status()


func _exit_tree() -> void:
	_restore_game_state()


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if direction != Vector2.ZERO:
		_player.position += direction.normalized() * MOVE_SPEED * delta
	_refresh_status()


func get_dev_mission_id() -> String:
	return DEV_MISSION_ID


func get_flag_state(flag_id: String) -> bool:
	var key := "mission_flag:%s:%s" % [DEV_MISSION_ID, flag_id]
	return bool(GameState.dialogue_flags.get(key, false))


func _configure_triggers() -> void:
	var triggers_root := get_node_or_null("Triggers")
	if triggers_root == null:
		return
	for child: Node in triggers_root.get_children():
		if not child is Area2D:
			continue
		_apply_trigger_config(child as Area2D)


func _configure_locks() -> void:
	var locks_root := get_node_or_null("Locks")
	if locks_root == null:
		return
	for child: Node in locks_root.get_children():
		if not child is Area2D:
			continue
		_apply_lock_config(child as Area2D)


func _configure_searches() -> void:
	var searches_root := get_node_or_null("Searches")
	if searches_root == null:
		return
	for child: Node in searches_root.get_children():
		if not child is Area2D:
			continue
		_apply_search_config(child as Area2D)


func _configure_multi_instance() -> void:
	var multi_root := get_node_or_null("MultiInstance")
	if multi_root == null:
		return
	for child: Node in multi_root.get_children():
		if not child is Area2D:
			continue
		match String(child.name):
			"RewardA", "RewardB":
				_apply_multi_reward_config(child as Area2D)
			"SearchA", "SearchB":
				_apply_multi_search_config(child as Area2D)
			"RouteA", "RouteB":
				_apply_multi_route_config(child as Area2D)


func _apply_multi_reward_config(reward_node: Area2D) -> void:
	reward_node.set("mission_id_override", DEV_MISSION_ID)
	reward_node.set("interaction_mode", 1)
	reward_node.set("one_shot", false)
	reward_node.set("mark_collected_on_success", true)
	reward_node.set("stay_available_after_collect", false)
	match String(reward_node.name):
		"RewardA":
			reward_node.set("mechanic_id", &"dev_multi_reward_a")
			reward_node.set("reward_id", &"dev_multi_reward_a")
			reward_node.set("prompt_text", "Press E: Collect reward A")
			reward_node.set("requirements", null)
			reward_node.set("success_effects", _make_flag_effect_set("dev_multi_reward_a_effect"))
			reward_node.set("collected_flag", &"dev_multi_reward_a_collected")
		"RewardB":
			reward_node.set("mechanic_id", &"dev_multi_reward_b")
			reward_node.set("reward_id", &"dev_multi_reward_b")
			reward_node.set("prompt_text", "Press E: Collect reward B")
			reward_node.set("requirements", null)
			reward_node.set("success_effects", _make_flag_effect_set("dev_multi_reward_b_effect"))
			reward_node.set("collected_flag", &"dev_multi_reward_b_collected")


func _apply_multi_search_config(search_node: Area2D) -> void:
	search_node.set("mission_id_override", DEV_MISSION_ID)
	search_node.set("interaction_mode", 1)
	search_node.set("one_shot", true)
	search_node.set("mark_searched_on_success", true)
	search_node.set("stay_available_after_search", false)
	match String(search_node.name):
		"SearchA":
			search_node.set("mechanic_id", &"dev_multi_search_a")
			search_node.set("search_kind", "crate")
			search_node.set("prompt_text", "Press E: Search crate A")
			search_node.set("requirements", null)
			search_node.set("success_effects", null)
			search_node.set("searched_flag", &"dev_multi_search_a_searched")
			search_node.set("target_visual_path", NodePath("SearchClosedVisual"))
		"SearchB":
			search_node.set("mechanic_id", &"dev_multi_search_b")
			search_node.set("search_kind", "crate")
			search_node.set("prompt_text", "Press E: Search crate B")
			search_node.set("requirements", null)
			search_node.set("success_effects", null)
			search_node.set("searched_flag", &"dev_multi_search_b_searched")
			search_node.set("target_visual_path", NodePath("SearchClosedVisual"))


func _apply_multi_route_config(route_node: Area2D) -> void:
	route_node.set("mission_id_override", DEV_MISSION_ID)
	route_node.set("interaction_mode", 1)
	route_node.set("one_shot", false)
	route_node.set("mark_unlocked_on_success", true)
	route_node.set("stay_available_after_unlock", false)
	match String(route_node.name):
		"RouteA":
			route_node.set("mechanic_id", &"dev_multi_route_a")
			route_node.set("route_id", &"dev_multi_route_a")
			route_node.set("prompt_text", "Press E: Unlock route A")
			route_node.set("requirements", null)
			route_node.set("success_effects", _make_flag_effect_set("dev_multi_route_a_effect"))
			route_node.set("route_flag", &"dev_multi_route_a_open")
		"RouteB":
			route_node.set("mechanic_id", &"dev_multi_route_b")
			route_node.set("route_id", &"dev_multi_route_b")
			route_node.set("prompt_text", "Press E: Unlock route B")
			route_node.set("requirements", null)
			route_node.set("success_effects", _make_flag_effect_set("dev_multi_route_b_effect"))
			route_node.set("route_flag", &"dev_multi_route_b_open")


func _configure_side_objectives() -> void:
	ObjectiveStepController.activate_objective(
		"dev_side_objective",
		"Complete the dev side objective",
		DEV_MISSION_ID
	)
	var objectives_root := get_node_or_null("Objectives")
	if objectives_root == null:
		return
	for child: Node in objectives_root.get_children():
		if not child is Area2D:
			continue
		_apply_side_objective_config(child as Area2D)


func _configure_routes() -> void:
	var routes_root := get_node_or_null("Routes")
	if routes_root == null:
		return
	for child: Node in routes_root.get_children():
		if not child is Area2D:
			continue
		_apply_route_config(child as Area2D)


func _configure_rewards() -> void:
	var rewards_root := get_node_or_null("Rewards")
	if rewards_root == null:
		return
	for child: Node in rewards_root.get_children():
		if not child is Area2D:
			continue
		_apply_reward_config(child as Area2D)


func _configure_containers() -> void:
	var containers_root := get_node_or_null("Containers")
	if containers_root == null:
		return
	for child: Node in containers_root.get_children():
		if not child is Area2D:
			continue
		_apply_container_config(child as Area2D)


func _configure_exits() -> void:
	var exits_root := get_node_or_null("Exits")
	if exits_root == null:
		return
	for child: Node in exits_root.get_children():
		if not child is Area2D:
			continue
		_apply_extraction_config(child as Area2D)


func _apply_search_config(search_node: Area2D) -> void:
	search_node.set("mission_id_override", DEV_MISSION_ID)
	search_node.set("interaction_mode", 1) # INTERACT_REQUIRED
	search_node.set("one_shot", true)
	search_node.set("mark_searched_on_success", true)
	search_node.set("stay_available_after_search", false)
	match String(search_node.name):
		"DevSearchDrawer":
			search_node.set("mechanic_id", &"dev_search_drawer")
			search_node.set("search_kind", "drawer")
			search_node.set("prompt_text", "Press E: Search dev drawer")
			search_node.set("requirements", null)
			search_node.set("success_effects", _make_multi_flag_effect_set(["dev_drawer_searched", "dev_drawer_found_clue"]))
			search_node.set("failure_effects", null)
			search_node.set("searched_flag", &"dev_drawer_searched")
			search_node.set("target_visual_path", NodePath("DrawerClosedVisual"))
			var show_paths: Array[NodePath] = [NodePath("DrawerFoundVisual")]
			search_node.set("nodes_to_show_on_search", show_paths)


func _apply_extraction_config(exit_node: Area2D) -> void:
	exit_node.set("mission_id_override", DEV_MISSION_ID)
	exit_node.set("interaction_mode", 1) # INTERACT_REQUIRED
	exit_node.set("one_shot", false)
	exit_node.set("complete_mission_on_success", false)
	exit_node.set("stay_available_after_extract", false)
	match String(exit_node.name):
		"DevExtractionZone":
			exit_node.set("mechanic_id", &"dev_extraction_zone")
			exit_node.set("prompt_text", "Press E: Extract")
			exit_node.set("locked_prompt_text", "Search the drawer for a clue first")
			exit_node.set("missing_objective_message", "Search the drawer for a clue first")
			exit_node.set("requirements", _make_flag_requirement_set("dev_drawer_found_clue", "Search the drawer for a clue first"))
			exit_node.set("success_effects", null)
			exit_node.set("failure_effects", null)
			exit_node.set("extraction_flag", &"dev_extraction_used")
			exit_node.set("clean_exit_effects", _make_flag_effect_set("dev_clean_extraction"))
			exit_node.set("messy_exit_effects", null)
			exit_node.set("fail_if_alerted", false)
			exit_node.set("messy_if_alerted", false)


func _apply_container_config(container_node: Area2D) -> void:
	container_node.set("mission_id_override", DEV_MISSION_ID)
	container_node.set("interaction_mode", 1) # INTERACT_REQUIRED
	container_node.set("one_shot", false)
	container_node.set("mark_searched_on_success", true)
	container_node.set("stay_available_after_search", false)
	container_node.set("mark_open_on_success", true)
	container_node.set("close_after_search", false)
	match String(container_node.name):
		"DevLocker":
			container_node.set("mechanic_id", &"dev_locker")
			container_node.set("container_kind", "locker")
			container_node.set("prompt_text", "Press E: Open dev locker")
			container_node.set("requirements", null)
			container_node.set("success_effects", _make_flag_effect_set("dev_locker_found_item"))
			container_node.set("failure_effects", null)
			container_node.set("opened_flag", &"dev_locker_opened")
			container_node.set("searched_flag", &"dev_locker_searched")
			container_node.set("closed_visual_path", NodePath("LockerClosedVisual"))
			container_node.set("open_visual_path", NodePath("LockerOpenVisual"))


func _apply_reward_config(reward_node: Area2D) -> void:
	reward_node.set("mission_id_override", DEV_MISSION_ID)
	reward_node.set("interaction_mode", 1) # INTERACT_REQUIRED
	reward_node.set("one_shot", false)
	reward_node.set("mark_collected_on_success", true)
	reward_node.set("stay_available_after_collect", false)
	match String(reward_node.name):
		"DevRewardPickup":
			reward_node.set("mechanic_id", &"dev_reward_pickup")
			reward_node.set("reward_kind", "clue")
			reward_node.set("reward_id", &"dev_reward_pickup")
			reward_node.set("prompt_text", "Press E: Collect dev reward")
			reward_node.set("requirements", null)
			reward_node.set("success_effects", _make_flag_effect_set("dev_reward_effect_applied"))
			reward_node.set("failure_effects", null)
			reward_node.set("collected_flag", &"dev_reward_collected")
			reward_node.set("target_visual_path", NodePath("RewardVisual"))
			var show_paths: Array[NodePath] = [NodePath("RewardCollectedVisual")]
			reward_node.set("nodes_to_show_on_collect", show_paths)


func _apply_route_config(route_node: Area2D) -> void:
	route_node.set("mission_id_override", DEV_MISSION_ID)
	route_node.set("interaction_mode", 1) # INTERACT_REQUIRED
	route_node.set("one_shot", false)
	route_node.set("mark_unlocked_on_success", true)
	route_node.set("stay_available_after_unlock", false)
	match String(route_node.name):
		"DevRouteUnlock":
			route_node.set("mechanic_id", &"dev_route_unlock")
			route_node.set("route_id", &"dev_shortcut")
			route_node.set("prompt_text", "Press E: Unlock dev route")
			route_node.set("locked_route_message", "Collect the dev reward first")
			route_node.set("requirements", _make_flag_requirement_set("dev_reward_collected", "Collect the dev reward first"))
			route_node.set("success_effects", _make_flag_effect_set("dev_route_effect_applied"))
			route_node.set("failure_effects", null)
			route_node.set("route_flag", &"dev_route_open")
			var show_paths: Array[NodePath] = [NodePath("RouteOpenVisual")]
			var hide_paths: Array[NodePath] = [NodePath("RouteBlockedVisual")]
			var disable_paths: Array[NodePath] = [NodePath("RouteBlocker")]
			var enable_paths: Array[NodePath] = [NodePath("RoutePassageShape")]
			route_node.set("nodes_to_show", show_paths)
			route_node.set("nodes_to_hide", hide_paths)
			route_node.set("collisions_to_disable", disable_paths)
			route_node.set("collisions_to_enable", enable_paths)


func _apply_side_objective_config(side_node: Area2D) -> void:
	side_node.set("mission_id_override", DEV_MISSION_ID)
	side_node.set("interaction_mode", 1) # INTERACT_REQUIRED
	side_node.set("one_shot", false)
	side_node.set("mark_handled_on_success", true)
	side_node.set("stay_available_after_handled", false)
	match String(side_node.name):
		"DevSideObjective":
			side_node.set("mechanic_id", &"dev_side_objective")
			side_node.set("objective_id", &"dev_side_objective")
			side_node.set("objective_text", "Complete the dev side objective")
			side_node.set("objective_action", 1) # COMPLETE
			side_node.set("prompt_text", "Press E: Complete side objective")
			side_node.set("locked_route_message", "Unlock the dev route first")
			side_node.set("requirements", _make_flag_requirement_set("dev_route_open", "Unlock the dev route first"))
			side_node.set("success_effects", _make_flag_effect_set("dev_side_objective_effect_applied"))
			side_node.set("failure_effects", null)
			side_node.set("objective_flag", &"dev_side_objective_handled")


func _apply_lock_config(lock_node: Area2D) -> void:
	lock_node.set("mission_id_override", DEV_MISSION_ID)
	lock_node.set("interaction_mode", 1) # INTERACT_REQUIRED
	lock_node.set("one_shot", true)
	lock_node.set("open_on_success", true)
	lock_node.set("stay_available_after_unlock", false)
	match String(lock_node.name):
		"DevLockedGate":
			lock_node.set("mechanic_id", &"dev_locked_gate")
			lock_node.set("lock_kind", "gate")
			lock_node.set("prompt_text", "Press E: Open dev gate")
			lock_node.set("locked_prompt_text", "Gate needs dev_unlock_flag")
			lock_node.set("requirements", _make_flag_requirement_set("dev_unlock_flag", "Gate needs dev_unlock_flag"))
			lock_node.set("success_effects", _make_flag_effect_set("dev_locked_gate_open"))
			lock_node.set("failure_effects", null)
			lock_node.set("unlocked_flag", &"dev_locked_gate_open")
			lock_node.set("target_visual_path", NodePath("GateVisual"))
			lock_node.set("target_collision_path", NodePath("GateBlocker"))


func _apply_trigger_config(trigger: Area2D) -> void:
	trigger.set("mission_id_override", DEV_MISSION_ID)
	trigger.set("interaction_mode", 1) # INTERACT_REQUIRED
	trigger.set("one_shot", false)
	match String(trigger.name):
		"AlwaysTrigger":
			trigger.set("mechanic_id", &"dev_always_trigger")
			trigger.set("prompt_text", "Press E: Fire always trigger")
			trigger.set("requirements", null)
			trigger.set("success_effects", _make_flag_effect_set("dev_always_trigger_fired"))
			trigger.set("failure_effects", null)
		"LockedTrigger":
			trigger.set("mechanic_id", &"dev_locked_trigger")
			trigger.set("prompt_text", "Press E: Fire locked trigger")
			trigger.set("locked_prompt_text", "Locked until dev_unlock_flag is set")
			trigger.set("requirements", _make_flag_requirement_set("dev_unlock_flag"))
			trigger.set("success_effects", _make_flag_effect_set("dev_locked_trigger_fired"))
		"UnlockTrigger":
			trigger.set("mechanic_id", &"dev_unlock_trigger")
			trigger.set("prompt_text", "Press E: Set dev unlock flag")
			trigger.set("requirements", null)
			trigger.set("success_effects", _make_flag_effect_set("dev_unlock_flag"))
		"FailureTrigger":
			trigger.set("mechanic_id", &"dev_failure_trigger")
			trigger.set("prompt_text", "Press E: Fire failure trigger")
			trigger.set("one_shot", true)
			trigger.set("requirements", _make_flag_requirement_set("dev_missing_flag"))
			trigger.set("success_effects", _make_flag_effect_set("dev_should_not_fire"))
			trigger.set("failure_effects", _make_flag_effect_set("dev_failure_effect_fired"))
		"DialogueTrigger":
			trigger.set("mechanic_id", &"dev_dialogue_trigger")
			trigger.set("prompt_text", "Press E: Play dev dialogue")
			trigger.set("requirements", null)
			trigger.set("success_effects", _make_dialogue_effect_set())


func _make_flag_requirement_set(flag_id: String, locked_message: String = "") -> RequirementSet:
	var requirement := MissionRequirement.new()
	requirement.fact_type = &"mission_flag"
	requirement.key = flag_id
	requirement.operator = MissionRequirement.Operator.EXISTS
	requirement.expected_value_type = "exists"
	var req_set := RequirementSet.new()
	req_set.requirements = [requirement]
	var message := locked_message.strip_edges()
	if message == "":
		message = "Locked until %s is set." % flag_id
	req_set.locked_message = message
	return req_set


func _make_multi_flag_effect_set(flag_ids: Array[String]) -> EffectSet:
	var effects: Array[MissionEffect] = []
	for flag_id: String in flag_ids:
		var effect := MissionEffect.new()
		effect.effect_type = MissionEffect.EffectType.SET_MISSION_FLAG
		effect.key = flag_id
		effect.value_type = "bool"
		effect.value_bool = true
		effects.append(effect)
	var effect_set := EffectSet.new()
	effect_set.effects = effects
	return effect_set


func _make_flag_effect_set(flag_id: String) -> EffectSet:
	var effect := MissionEffect.new()
	effect.effect_type = MissionEffect.EffectType.SET_MISSION_FLAG
	effect.key = flag_id
	effect.value_type = "bool"
	effect.value_bool = true
	var effect_set := EffectSet.new()
	effect_set.effects = [effect]
	return effect_set


func _make_dialogue_effect_set() -> EffectSet:
	var effect := MissionEffect.new()
	effect.effect_type = MissionEffect.EffectType.TRIGGER_SIMPLE_DIALOGUE
	effect.payload = {"speaker": "Dev Guide", "text": "Mechanic authoring dialogue test."}
	var effect_set := EffectSet.new()
	effect_set.effects = [effect]
	return effect_set


func _refresh_status() -> void:
	if _status_label == null:
		return
	var lines: PackedStringArray = PackedStringArray([
		"Mission: %s" % DEV_MISSION_ID,
		"Move: Arrow keys | Interact: E | Scan: Q",
		"dev_always_trigger_fired: %s" % str(get_flag_state("dev_always_trigger_fired")),
		"dev_unlock_flag: %s" % str(get_flag_state("dev_unlock_flag")),
		"dev_locked_trigger_fired: %s" % str(get_flag_state("dev_locked_trigger_fired")),
		"dev_locked_gate_open: %s" % str(get_flag_state("dev_locked_gate_open")),
		"dev_drawer_searched: %s" % str(get_flag_state("dev_drawer_searched")),
		"dev_drawer_found_clue: %s" % str(get_flag_state("dev_drawer_found_clue")),
		"dev_extraction_used: %s" % str(get_flag_state("dev_extraction_used")),
		"dev_clean_extraction: %s" % str(get_flag_state("dev_clean_extraction")),
		"dev_locker_opened: %s" % str(get_flag_state("dev_locker_opened")),
		"dev_locker_searched: %s" % str(get_flag_state("dev_locker_searched")),
		"dev_locker_found_item: %s" % str(get_flag_state("dev_locker_found_item")),
		"dev_reward_collected: %s" % str(get_flag_state("dev_reward_collected")),
		"dev_reward_effect_applied: %s" % str(get_flag_state("dev_reward_effect_applied")),
		"dev_route_open: %s" % str(get_flag_state("dev_route_open")),
		"dev_route_effect_applied: %s" % str(get_flag_state("dev_route_effect_applied")),
		"dev_side_objective_handled: %s" % str(get_flag_state("dev_side_objective_handled")),
		"dev_side_objective_effect_applied: %s" % str(get_flag_state("dev_side_objective_effect_applied")),
		"dev_side_objective_completed: %s" % str(_is_dev_side_objective_completed()),
		"dev_failure_effect_fired: %s" % str(get_flag_state("dev_failure_effect_fired")),
		"--- multi-instance ---",
		"dev_multi_reward_a_collected: %s" % str(get_flag_state("dev_multi_reward_a_collected")),
		"dev_multi_reward_b_collected: %s" % str(get_flag_state("dev_multi_reward_b_collected")),
		"dev_multi_search_a_searched: %s" % str(get_flag_state("dev_multi_search_a_searched")),
		"dev_multi_search_b_searched: %s" % str(get_flag_state("dev_multi_search_b_searched")),
		"dev_multi_route_a_open: %s" % str(get_flag_state("dev_multi_route_a_open")),
		"dev_multi_route_b_open: %s" % str(get_flag_state("dev_multi_route_b_open")),
	])
	_status_label.text = "\n".join(lines)


func _is_dev_side_objective_completed() -> bool:
	return ObjectiveStepController.is_objective_completed("dev_side_objective", DEV_MISSION_ID)


func _snapshot_game_state() -> void:
	_game_state_snapshot = {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"selected_cards": GameState.selected_cards.duplicate(),
		"current_scheme_loadout": GameState.get_current_scheme_loadout() if GameState.has_method("get_current_scheme_loadout") else GameState.get("current_scheme_loadout"),
		"quest_manager": _snapshot_quest_manager_state(),
	}


func _restore_game_state() -> void:
	if _game_state_snapshot.is_empty():
		return
	GameState.current_mission_id = String(_game_state_snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(_game_state_snapshot.get("pending_mission_id", ""))
	GameState.dialogue_flags = (_game_state_snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	_restore_string_array(GameState.selected_cards, _game_state_snapshot.get("selected_cards", []))
	var loadout: Variant = _game_state_snapshot.get("current_scheme_loadout", {})
	if loadout is Dictionary:
		if GameState.has_method("set_current_scheme_loadout"):
			GameState.set_current_scheme_loadout(loadout as Dictionary)
		else:
			GameState.set("current_scheme_loadout", (loadout as Dictionary).duplicate(true))
	_restore_quest_manager_state(_game_state_snapshot.get("quest_manager", {}))


func _restore_string_array(target: Array[String], previous: Variant) -> void:
	target.clear()
	if not (previous is Array):
		return
	for item in previous:
		target.append(String(item))


func _snapshot_quest_manager_state() -> Dictionary:
	return {
		"active_quest_id": QuestManager.active_quest_id,
		"active_objective": QuestManager.active_objective,
		"objectives": QuestManager.objectives.duplicate(true),
		"objective_records": QuestManager.objective_records.duplicate(true),
		"active_objectives": QuestManager.active_objectives.duplicate(true),
		"completed_objectives": QuestManager.completed_objectives.duplicate(true),
	}


func _restore_quest_manager_state(snapshot: Variant) -> void:
	if not (snapshot is Dictionary):
		return
	var data := snapshot as Dictionary
	QuestManager.active_quest_id = String(data.get("active_quest_id", ""))
	QuestManager.active_objective = String(data.get("active_objective", ""))
	QuestManager.objectives = (data.get("objectives", {}) as Dictionary).duplicate(true)
	QuestManager.objective_records = (data.get("objective_records", {}) as Dictionary).duplicate(true)
	QuestManager.active_objectives = (data.get("active_objectives", {}) as Dictionary).duplicate(true)
	QuestManager.completed_objectives = (data.get("completed_objectives", {}) as Dictionary).duplicate(true)
