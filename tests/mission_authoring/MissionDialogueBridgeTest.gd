# GdUnit4 smoke tests for Packet 2A mission dialogue bridge.
extends GdUnitTestSuite

const MissionDialogueBridgeScript := preload("res://src/missions/iso/authoring/core/MissionDialogueBridge.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")


func test_play_simple_line_starts_dialogue_with_one_line() -> void:
	var snapshot := _snapshot_dialogue_manager()
	var result: Dictionary = MissionDialogueBridgeScript.play_simple_line({"speaker": "Louis", "text": "Delivery entrance is yours."})
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(DialogueManager.is_in_dialogue).is_true()
	assert_int(DialogueManager.current_lines.size()).is_equal(1)
	assert_str(String(DialogueManager.current_lines[0].get("speaker", ""))).is_equal("Louis")
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Delivery entrance is yours.")
	_restore_dialogue_manager(snapshot)


func test_play_simple_line_supports_lines_payload() -> void:
	var snapshot := _snapshot_dialogue_manager()
	var result: Dictionary = MissionDialogueBridgeScript.play_simple_line({
		"lines": [
			{"speaker": "Bentley", "text": "Bark."},
			{"speaker": "Louis", "text": "He makes a point."},
		]
	})
	assert_bool(result.get("ok", false)).is_true()
	assert_int(DialogueManager.current_lines.size()).is_equal(2)
	assert_str(String(DialogueManager.current_lines[1].get("speaker", ""))).is_equal("Louis")
	_restore_dialogue_manager(snapshot)


func test_play_dialogue_key_uses_fallback_text() -> void:
	var snapshot := _snapshot_dialogue_manager()
	var result: Dictionary = MissionDialogueBridgeScript.play_dialogue_key("louis_loading_dock", {
		"payload": {"speaker": "Louis", "fallback_text": "Try the delivery entrance."}
	})
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("speaker", ""))).is_equal("Louis")
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Try the delivery entrance.")
	_restore_dialogue_manager(snapshot)


func test_play_dialogue_key_without_fallback_fails_cleanly() -> void:
	var result: Dictionary = MissionDialogueBridgeScript.play_dialogue_key("missing_dialogue_key")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("dialogue_key_unresolved")


func test_trigger_simple_dialogue_effect_routes_through_applier() -> void:
	var snapshot := _snapshot_dialogue_manager()
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.TRIGGER_SIMPLE_DIALOGUE
	effect.payload = {"speaker": "Bentley", "text": "Important bark."}
	var result: Dictionary = effect.apply({"mission_id": "test_mission"})
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("speaker", ""))).is_equal("Bentley")
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Important bark.")
	_restore_dialogue_manager(snapshot)


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
	if not (raw_lines is Array):
		DialogueManager.current_index = int(snapshot.get("current_index", -1))
		return
	for line in raw_lines as Array:
		if line is Dictionary:
			DialogueManager.current_lines.append((line as Dictionary).duplicate(true))
	DialogueManager.current_index = int(snapshot.get("current_index", -1))
