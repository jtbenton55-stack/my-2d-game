# GdUnit4 tests for Phase 12A-12H narrative and presentation bridges.
extends GdUnitTestSuite

const MissionDialogueBridgeScript := preload("res://src/missions/iso/authoring/core/MissionDialogueBridge.gd")
const DialogueTriggerZoneScript := preload("res://src/missions/iso/presentation/DialogueTriggerZone.gd")
const BarkTriggerScript := preload("res://src/missions/iso/presentation/BarkTrigger.gd")
const PresentationSequencePlayerScript := preload("res://src/missions/iso/presentation/PresentationSequencePlayer.gd")
const CameraBridgeScript := preload("res://src/missions/iso/presentation/CameraBridge.gd")
const PlayerControlBridgeScript := preload("res://src/missions/iso/presentation/PlayerControlBridge.gd")
const AudioVisualBridgeScript := preload("res://src/missions/iso/presentation/AudioVisualBridge.gd")


class TestDialogueProvider:
	extends RefCounted

	func get_dialogue_line(dialogue_id: String, _context: Dictionary = {}) -> Dictionary:
		if dialogue_id == "provider_line":
			return {"ok": true, "speaker": "Louis", "text": "Provider line landed."}
		return {"ok": false, "speaker": "", "text": ""}

	func has_dialogue(dialogue_id: String) -> bool:
		return dialogue_id == "provider_line"

	func get_provider_id() -> String:
		return "test_provider"


class TestPlayer:
	extends Node2D
	var can_control := true


func test_dialogue_bridge_registry_provider_and_fallback_lookup() -> void:
	var snapshot := _snapshot_dialogue_manager()
	MissionDialogueBridgeScript.clear_dialogue_registry()
	var registered: Dictionary = MissionDialogueBridgeScript.register_dialogue_key("registered_line", {"speaker": "Mere", "text": "Registered line."})
	assert_bool(registered.get("ok", false)).is_true()
	var registry_result: Dictionary = MissionDialogueBridgeScript.play_dialogue_key("registered_line")
	assert_bool(registry_result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("speaker", ""))).is_equal("Mere")

	var provider := TestDialogueProvider.new()
	var provider_result: Dictionary = MissionDialogueBridgeScript.play_dialogue_key("provider_line", {"dialogue_provider": provider})
	assert_bool(provider_result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Provider line landed.")

	var fallback_result: Dictionary = MissionDialogueBridgeScript.play_dialogue_key("fallback_line", {"payload": {"speaker": "Mission", "fallback_text": "Fallback still works."}})
	assert_bool(fallback_result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Fallback still works.")
	MissionDialogueBridgeScript.clear_dialogue_registry()
	_restore_dialogue_manager(snapshot)


func test_dialogue_and_bark_triggers_prevent_spam() -> void:
	var snapshot := _snapshot_dialogue_manager()
	var dialogue := DialogueTriggerZoneScript.new()
	dialogue.mission_id_override = "test_mission"
	dialogue.mechanic_id = &"phase12_dialogue"
	dialogue.dialogue_key = &"phase12_dialogue"
	dialogue.fallback_speaker = "Louis"
	dialogue.fallback_text = "Trigger line."
	dialogue.cooldown_seconds = 10.0
	dialogue.one_shot = false
	add_child(dialogue)
	var result: Dictionary = dialogue.activate(null, "test")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Trigger line.")
	var cooldown: Dictionary = dialogue.activate(null, "test")
	assert_bool(cooldown.get("ok", true)).is_false()
	assert_str(String(cooldown.get("code", ""))).is_equal("dialogue_cooldown")

	var bark := BarkTriggerScript.new()
	bark.mission_id_override = "test_mission"
	bark.mechanic_id = &"phase12_bark"
	bark.bark_id = &"phase12_bark"
	bark.bark_text = "Important bark."
	bark.cooldown_seconds = 0.0
	add_child(bark)
	var bark_result: Dictionary = bark.activate(null, "test")
	assert_bool(bark_result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("speaker", ""))).is_equal("Bentley")
	_free_node(dialogue)
	_free_node(bark)
	_restore_dialogue_manager(snapshot)


func test_camera_player_and_audio_visual_bridges_fail_safe_and_restore() -> void:
	var root := Node2D.new()
	add_child(root)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.global_position = Vector2(4, 5)
	root.add_child(camera)
	var target := Marker2D.new()
	target.name = "FocusTarget"
	target.global_position = Vector2(40, 50)
	root.add_child(target)
	var camera_bridge := CameraBridgeScript.new()
	camera_bridge.name = "CameraBridge"
	camera_bridge.camera_path = NodePath("../Camera2D")
	camera_bridge.named_target_paths = {"focus": NodePath("../FocusTarget")}
	camera_bridge.default_blend_seconds = 0.0
	root.add_child(camera_bridge)
	var focus_result: Dictionary = camera_bridge.focus_named_target("focus", 0.0)
	assert_bool(focus_result.get("ok", false)).is_true()
	assert_vector(camera.global_position).is_equal(Vector2(40, 50))
	var restore_result: Dictionary = camera_bridge.restore_camera(0.0)
	assert_bool(restore_result.get("ok", false)).is_true()
	assert_vector(camera.global_position).is_equal(Vector2(4, 5))

	var player := TestPlayer.new()
	player.name = "Player"
	root.add_child(player)
	var player_bridge := PlayerControlBridgeScript.new()
	player_bridge.name = "PlayerControlBridge"
	player_bridge.player_path = NodePath("../Player")
	root.add_child(player_bridge)
	assert_bool(player.can_control).is_true()
	assert_bool(player_bridge.lock_input("test").get("ok", false)).is_true()
	assert_bool(player.can_control).is_false()
	assert_bool(player_bridge.restore_input().get("ok", false)).is_true()
	assert_bool(player.can_control).is_true()

	var av_bridge := AudioVisualBridgeScript.new()
	av_bridge.named_cue_payloads = {"safe_cue": {"sfx_id": "phase12_safe", "shake_intensity": 0.2, "shake_duration": 0.01}}
	root.add_child(av_bridge)
	var cue_result: Dictionary = av_bridge.play_cue("safe_cue")
	assert_bool(cue_result.get("ok", false)).is_true()
	_free_node(root)


func test_sequence_player_coordinates_bridges_without_gameplay_ownership() -> void:
	var snapshot := _snapshot_dialogue_manager()
	var root := Node2D.new()
	add_child(root)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	root.add_child(camera)
	var target := Marker2D.new()
	target.name = "FocusTarget"
	target.global_position = Vector2(12, 24)
	root.add_child(target)
	var player := TestPlayer.new()
	player.name = "Player"
	root.add_child(player)

	var camera_bridge := CameraBridgeScript.new()
	camera_bridge.name = "CameraBridge"
	camera_bridge.camera_path = NodePath("../Camera2D")
	camera_bridge.named_target_paths = {"focus": NodePath("../FocusTarget")}
	camera_bridge.default_blend_seconds = 0.0
	root.add_child(camera_bridge)
	var player_bridge := PlayerControlBridgeScript.new()
	player_bridge.name = "PlayerControlBridge"
	player_bridge.player_path = NodePath("../Player")
	root.add_child(player_bridge)
	var av_bridge := AudioVisualBridgeScript.new()
	av_bridge.name = "AudioVisualBridge"
	av_bridge.named_cue_payloads = {"sting": {"sfx_id": "phase12_sting"}}
	root.add_child(av_bridge)
	var sequence := PresentationSequencePlayerScript.new()
	sequence.name = "PresentationSequencePlayer"
	sequence.sequence_steps = [
		{"type": "dialogue_key", "key": "phase12_sequence", "fallback_speaker": "Louis", "fallback_text": "Sequence line."},
		{"type": "camera_focus", "target": "focus", "blend_seconds": 0.0},
		{"type": "player_lock"},
		{"type": "audio_visual", "cue": "sting"},
		{"type": "player_restore"},
		{"type": "camera_restore", "blend_seconds": 0.0},
	]
	root.add_child(sequence)
	var result: Dictionary = sequence.play_sequence("phase12_test", {"mission_id": "test_mission"})
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(player.can_control).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Sequence line.")
	_free_node(root)
	_restore_dialogue_manager(snapshot)


func test_templates_and_dev_scene_contain_phase12_nodes() -> void:
	assert_object(load("res://scenes/missions/iso/authoring/DialogueTriggerZoneTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/BarkTriggerTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/PresentationSequencePlayerTemplate.tscn")).is_not_null()
	var scene := load("res://scenes/dev/mission_authoring/Phase12PresentationProofRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("MissionMechanics/DialogueTriggerZone_phase12a_intro_line")).is_instanceof(DialogueTriggerZoneScript)
	assert_object(root.get_node_or_null("MissionMechanics/BarkTrigger_phase12b_bentley_bark")).is_instanceof(BarkTriggerScript)
	assert_object(root.get_node_or_null("PresentationHelpers/PresentationSequencePlayer")).is_instanceof(PresentationSequencePlayerScript)
	assert_object(root.get_node_or_null("PresentationHelpers/CameraBridge")).is_instanceof(CameraBridgeScript)
	assert_object(root.get_node_or_null("PresentationHelpers/PlayerControlBridge")).is_instanceof(PlayerControlBridgeScript)
	assert_object(root.get_node_or_null("PresentationHelpers/AudioVisualBridge")).is_instanceof(AudioVisualBridgeScript)
	_free_node(root)


func _snapshot_dialogue_manager() -> Dictionary:
	return {
		"is_in_dialogue": DialogueManager.is_in_dialogue,
		"current_lines": DialogueManager.current_lines.duplicate(true),
		"current_index": DialogueManager.current_index,
	}


func _restore_dialogue_manager(snapshot: Dictionary) -> void:
	DialogueManager.is_in_dialogue = bool(snapshot.get("is_in_dialogue", false))
	DialogueManager.current_lines.clear()
	var raw_lines: Variant = snapshot.get("current_lines", [])
	if raw_lines is Array:
		for line in raw_lines as Array:
			if line is Dictionary:
				DialogueManager.current_lines.append((line as Dictionary).duplicate(true))
	DialogueManager.current_index = int(snapshot.get("current_index", -1))


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
