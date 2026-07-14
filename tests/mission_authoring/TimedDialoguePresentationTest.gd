# Focused regression tests for timed dialogue presentation metadata and triggers.
extends GdUnitTestSuite

const DialogueTriggerZoneScript := preload("res://src/missions/iso/presentation/DialogueTriggerZone.gd")
const DialogueBoxScene := preload("res://scenes/ui/DialogueBox.tscn")


func test_timed_sequence_advances_and_ends() -> void:
	DialogueManager.start_simple_dialogue([
		{"speaker": "Mere", "text": "First.", "auto_advance_seconds": 0.05},
		{"speaker": "Louis", "text": "Second.", "auto_advance_seconds": 0.05},
	])
	assert_int(DialogueManager.current_index).is_equal(0)
	await get_tree().create_timer(0.08, true).timeout
	assert_int(DialogueManager.current_index).is_equal(1)
	await get_tree().create_timer(0.08, true).timeout
	assert_bool(DialogueManager.is_in_dialogue).is_false()


func test_manual_advance_is_suppressed_and_metadata_defaults_are_additive() -> void:
	DialogueManager.start_simple_dialogue([
		{"speaker": "Mission", "text": "Hold.", "auto_advance_seconds": 0.2, "allow_manual_advance": false},
		{"speaker": "Mission", "text": "Next."},
	])
	DialogueManager.next_line()
	assert_int(DialogueManager.current_index).is_equal(0)
	assert_bool(DialogueManager.current_lines[0].get("allow_manual_advance", true)).is_false()
	assert_bool(DialogueManager.current_lines[0].get("allow_skip", false)).is_true()
	assert_float(DialogueManager.current_lines[1].get("auto_advance_seconds", -1.0)).is_equal(0.0)
	assert_bool(DialogueManager.current_lines[1].get("allow_manual_advance", false)).is_true()
	DialogueManager.end_dialogue()


func test_untimed_dialogue_still_advances_manually_and_skips() -> void:
	DialogueManager.start_simple_dialogue(["One.", "Two."])
	await get_tree().create_timer(0.05, true).timeout
	DialogueManager.next_line()
	assert_int(DialogueManager.current_index).is_equal(1)
	DialogueManager.skip_dialogue()
	assert_bool(DialogueManager.is_in_dialogue).is_false()


func test_old_timer_cannot_advance_replacement_dialogue() -> void:
	DialogueManager.start_simple_dialogue([
		{"speaker": "Old", "text": "Expiring.", "auto_advance_seconds": 0.08},
	])
	await get_tree().create_timer(0.02, true).timeout
	DialogueManager.start_simple_dialogue([
		{"speaker": "New", "text": "Replacement."},
		{"speaker": "New", "text": "Must remain hidden."},
	])
	await get_tree().create_timer(0.12, true).timeout
	assert_bool(DialogueManager.is_in_dialogue).is_true()
	assert_int(DialogueManager.current_index).is_equal(0)
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Replacement.")
	DialogueManager.end_dialogue()


func test_timed_dialogue_waits_while_scene_tree_is_paused() -> void:
	DialogueManager.start_simple_dialogue([
		{"speaker": "Mission", "text": "Paused.", "auto_advance_seconds": 0.05},
	])
	get_tree().paused = true
	await get_tree().create_timer(0.1, true).timeout
	assert_bool(DialogueManager.is_in_dialogue).is_true()
	get_tree().paused = false
	await get_tree().create_timer(0.08, true).timeout
	assert_bool(DialogueManager.is_in_dialogue).is_false()


func test_dialogue_box_replaces_disallowed_controls_with_enter_close_hint() -> void:
	var dialogue_box := DialogueBoxScene.instantiate()
	add_child(dialogue_box)
	DialogueManager.start_simple_dialogue([
		{"speaker": "Mission", "text": "Hands off.", "allow_manual_advance": false, "allow_skip": false},
	])
	var next_indicator := dialogue_box.get_node("DialoguePanel/MarginContainer/HBox/ContentContainer/NextIndicator") as Label
	var skip_button := dialogue_box.get_node("DialoguePanel/SkipButton") as Button
	assert_bool(next_indicator.visible).is_true()
	assert_str(next_indicator.text).is_equal("B / Escape: Close")
	assert_bool(skip_button.visible).is_false()
	DialogueManager.start_simple_dialogue([{"speaker": "Mission", "text": "Normal."}])
	assert_bool(next_indicator.visible).is_true()
	assert_str(next_indicator.text).is_equal("A / E: Advance | B / Escape: Close")
	assert_bool(skip_button.visible).is_true()
	DialogueManager.end_dialogue()
	dialogue_box.queue_free()


func test_enter_closes_dialogue_even_when_manual_advance_and_skip_are_disabled() -> void:
	var dialogue_box := DialogueBoxScene.instantiate()
	add_child(dialogue_box)
	DialogueManager.start_simple_dialogue([
		{"speaker": "Mission", "text": "Timed.", "allow_manual_advance": false, "allow_skip": false},
	])
	var enter_event := InputEventKey.new()
	enter_event.keycode = KEY_ENTER
	enter_event.pressed = true
	dialogue_box.call("_input", enter_event)
	assert_bool(DialogueManager.is_in_dialogue).is_false()
	dialogue_box.queue_free()


func test_no_key_trigger_supplies_fallback_text_and_preserves_explicit_lines() -> void:
	var fallback_zone := _new_dialogue_zone("fallback_zone")
	fallback_zone.fallback_speaker = "Mission"
	fallback_zone.fallback_text = "Fallback line."
	var fallback_result: Dictionary = fallback_zone.activate(null, "test")
	assert_bool(fallback_result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Fallback line.")

	var lines_zone := _new_dialogue_zone("lines_zone")
	lines_zone.fallback_text = "Must not replace lines."
	lines_zone.dialogue_payload = {
		"lines": [
			{"speaker": "Bentley", "text": "First authored line.", "auto_advance_seconds": 0.1},
			{"speaker": "Louis", "text": "Second authored line."},
		]
	}
	var lines_result: Dictionary = lines_zone.activate(null, "test")
	assert_bool(lines_result.get("ok", false)).is_true()
	assert_int(DialogueManager.current_lines.size()).is_equal(2)
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("First authored line.")
	assert_float(DialogueManager.current_lines[0].get("auto_advance_seconds", 0.0)).is_equal(0.1)
	_free_zone(fallback_zone)
	_free_zone(lines_zone)
	DialogueManager.end_dialogue()


func test_one_shot_guard_does_not_replace_active_dialogue() -> void:
	var zone := _new_dialogue_zone("one_shot_zone")
	zone.one_shot = true
	zone.fallback_text = "Only once."
	assert_bool(zone.activate(null, "test").get("ok", false)).is_true()
	DialogueManager.start_simple_dialogue([{"speaker": "Mission", "text": "Keep me."}])
	var second_result: Dictionary = zone.activate(null, "test")
	assert_str(String(second_result.get("code", ""))).is_equal("already_used")
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).is_equal("Keep me.")
	_free_zone(zone)
	DialogueManager.end_dialogue()


func _new_dialogue_zone(id: String) -> DialogueTriggerZone:
	var zone := DialogueTriggerZoneScript.new() as DialogueTriggerZone
	zone.mission_id_override = "timed_dialogue_test"
	zone.mechanic_id = StringName(id)
	zone.cooldown_seconds = 0.0
	zone.one_shot = false
	add_child(zone)
	return zone


func _free_zone(zone: Node) -> void:
	if is_instance_valid(zone):
		zone.queue_free()
