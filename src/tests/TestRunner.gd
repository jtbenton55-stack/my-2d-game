extends Control

# Simple test runner UI for all test suites

const SAVE_LOAD_TEST_PATH := "res://src/tests/SaveLoadTest.gd"

@onready var output_label: Label = $VBoxContainer/OutputLabel
@onready var run_button: Button = $VBoxContainer/RunButton
@onready var smoke_button: Button = $VBoxContainer/SmokeButton

func _ready() -> void:
    run_button.pressed.connect(_on_run_tests)
    smoke_button.pressed.connect(_on_smoke_test)
    output_label.text = "Click 'Run All Tests' to verify story unlock chain and save/load system."
    run_button.grab_focus()

func _on_run_tests() -> void:
    output_label.text = "Running all test suites...\n\n"
    
    var total_passed := 0
    var total_failed := 0
    var full_summary := ""
    
    # Run Story Unlock Tests
    output_label.text += "=== Story Unlock Tests ===\n"
    var unlock_test := StoryUnlockTest.new()
    add_child(unlock_test)
    var unlock_results := unlock_test.run_all_tests()
    total_passed += unlock_results.passed
    total_failed += unlock_results.failed
    full_summary += _format_suite_results("Story Unlock", unlock_results)
    unlock_test.queue_free()
    
    output_label.text += "Passed: %d | Failed: %d\n\n" % [unlock_results.passed, unlock_results.failed]
    
    # Run Save/Load Tests
    output_label.text += "=== Save/Load Tests ===\n"
    var SaveLoadTestClass := load(SAVE_LOAD_TEST_PATH)
    var save_test := SaveLoadTestClass.new()
    add_child(save_test)
    var save_results := save_test.run_all_tests()
    total_passed += save_results.passed
    total_failed += save_results.failed
    full_summary += _format_suite_results("Save/Load", save_results)
    save_test.queue_free()
    
    output_label.text += "Passed: %d | Failed: %d\n\n" % [save_results.passed, save_results.failed]
    
    # Final summary
    var final_summary := "=== FINAL RESULTS ===\n"
    final_summary += "Total Passed: %d | Total Failed: %d\n\n" % [total_passed, total_failed]
    final_summary += full_summary
    
    if total_failed == 0:
        final_summary += "\n✓ ALL TESTS PASSED!"
    else:
        final_summary += "\n✗ Some tests failed."
    
    output_label.text = final_summary

func _format_suite_results(suite_name: String, results: Dictionary) -> String:
    var text := suite_name + ":\n"
    for result in results.results:
        text += "  " + result + "\n"
    return text

func _on_smoke_test() -> void:
    output_label.text = "Running smoke tests...\n\n"
    
    var all_passed := true
    
    # Story Unlock smoke test
    var unlock_test := StoryUnlockTest.new()
    add_child(unlock_test)
    if unlock_test.smoke_test():
        output_label.text += "✓ Story Unlock smoke test passed\n"
    else:
        output_label.text += "✗ Story Unlock smoke test failed\n"
        all_passed = false
    unlock_test.queue_free()
    
    # Save/Load smoke test
    var SaveLoadTestClass := load(SAVE_LOAD_TEST_PATH)
    var save_test := SaveLoadTestClass.new()
    add_child(save_test)
    if save_test.smoke_test():
        output_label.text += "✓ Save/Load smoke test passed\n"
    else:
        output_label.text += "✗ Save/Load smoke test failed\n"
        all_passed = false
    save_test.queue_free()
    
    if all_passed:
        output_label.text += "\n✓ All smoke tests passed!"
    else:
        output_label.text += "\n✗ Some smoke tests failed."
