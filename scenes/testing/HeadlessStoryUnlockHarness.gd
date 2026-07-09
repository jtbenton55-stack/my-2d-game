extends Node

## Headless harness: runs StoryUnlockTest + SaveLoadTest and quits with a
## non-zero exit code on failure. Usage:
##   godot --headless --path . res://scenes/testing/HeadlessStoryUnlockHarness.tscn

const SaveLoadTestScript := preload("res://src/tests/SaveLoadTest.gd")


func _ready() -> void:
	var total_failed := 0

	var unlock_test := StoryUnlockTest.new()
	add_child(unlock_test)
	var unlock_results: Dictionary = unlock_test.run_all_tests()
	total_failed += int(unlock_results.get("failed", 0))
	unlock_test.queue_free()

	var save_test: Node = SaveLoadTestScript.new()
	add_child(save_test)
	var save_results: Dictionary = save_test.run_all_tests()
	total_failed += int(save_results.get("failed", 0))
	save_test.queue_free()

	if total_failed == 0:
		print("HEADLESS_HARNESS_RESULT: PASS")
	else:
		print("HEADLESS_HARNESS_RESULT: FAIL (%d failures)" % total_failed)
	get_tree().quit(0 if total_failed == 0 else 1)
