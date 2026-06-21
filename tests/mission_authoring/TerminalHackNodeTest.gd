# GdUnit4 tests for Phase 9A TerminalHackNode.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const LockedInteractionNodeScript := preload("res://src/missions/iso/authoring/mechanics/LockedInteractionNode.gd")
const TerminalHackNodeScript := preload("res://src/missions/iso/authoring/mechanics/TerminalHackNode.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_terminal_hack_node_extends_locked_interaction_node() -> void:
	var node := TerminalHackNodeScript.new()
	assert_object(node).is_instanceof(LockedInteractionNodeScript)
	assert_object(node).is_instanceof(MechanicAreaBaseScript)
	node.free()


func test_terminal_hack_sets_completion_flag_and_effects() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var node := _spawn_terminal()
	node.mission_id_override = "test_mission"
	node.terminal_id = &"phase9a_terminal"
	node.hack_completed_flag = &"terminal_hacked"
	node.success_effects = _set_mission_flag_effect_set("terminal_effect_done")

	var result: Dictionary = node.hack(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("activation_succeeded")
	assert_bool(node.unlocked).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:terminal_hacked", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:terminal_effect_done", false)).is_true()
	assert_str(String(node.get_hack_summary().get("terminal_id", ""))).is_equal("phase9a_terminal")

	_restore_game_state(snapshot)
	_free_node(node)


func test_interface_methods_route_to_hack() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var node := _spawn_terminal()
	node.mission_id_override = "test_mission"
	node.hack_completed_flag = &"terminal_interacted"
	node.one_shot = false

	assert_bool(node.interact()).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:terminal_interacted", false)).is_true()
	node.lock()
	assert_bool(node.use()).is_true()

	_restore_game_state(snapshot)
	_free_node(node)


func test_template_and_dev_scene_contain_terminal_hack() -> void:
	var template := load("res://scenes/missions/iso/authoring/TerminalHackNodeTemplate.tscn") as PackedScene
	assert_object(template).is_not_null()
	var template_root := template.instantiate()
	assert_object(template_root).is_instanceof(TerminalHackNodeScript)
	template_root.queue_free()

	var scene := load("res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	var terminal := root.get_node_or_null("MissionMechanics/TerminalHackNode_phase9a_terminal")
	assert_object(terminal).is_instanceof(TerminalHackNodeScript)
	assert_str(String(terminal.get("terminal_id"))).is_equal("phase9a_terminal")
	assert_str(String(terminal.get("hack_completed_flag"))).is_equal("phase9a_terminal_hacked")
	root.queue_free()


func _spawn_terminal() -> Node:
	var node: Node = TerminalHackNodeScript.new()
	node.name = "TerminalHackUnderTest"
	node.interaction_mode = MechanicAreaBaseScript.InteractionMode.INTERACT_REQUIRED
	add_child(node)
	return node


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func _set_mission_flag_effect_set(flag_key: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_key
	effect.value_type = "bool"
	effect.value_bool = true
	var effect_set := EffectSetScript.new()
	effect_set.effects = [effect]
	return effect_set


func _snapshot_game_state() -> Dictionary:
	return {
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
