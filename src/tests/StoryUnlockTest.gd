extends Node
class_name StoryUnlockTest

# Story Unlock Chain Test Suite
# Tests the clue-gated mission progression system

var _test_results: Array[String] = []
var _tests_passed: int = 0
var _tests_failed: int = 0

# Run all tests and return results
func run_all_tests() -> Dictionary:
    var prev_debug := GameState.debug_unlock_all_missions
    GameState.debug_unlock_all_missions = false
    _test_results.clear()
    _tests_passed = 0
    _tests_failed = 0
    
    print("\n=== Story Unlock Chain Tests ===\n")
    
    # Core progression tests
    _test_initial_state()
    _test_taco_bell_completion()
    _test_clean_job_completion()
    _test_jazz_club_completion()
    _test_rewrite_room_completion()
    _test_parallel_branch_combination()
    _test_diamond_vault_completion()
    _test_getaway_completion()
    _test_arm_wrestling_completion()
    _test_persian_tea_completion()
    _test_elephant_room_completion()
    _test_shadow_solo_completion()
    _test_sterling_tower_gating()
    
    # Edge case tests
    _test_completion_order_independence()
    _test_duplicate_completion_handling()
    _test_fail_mission_handling()
    
    # Print summary
    print("\n=== Test Summary ===")
    print("Passed: %d | Failed: %d" % [_tests_passed, _tests_failed])
    for result in _test_results:
        print("  " + result)
    
    GameState.debug_unlock_all_missions = prev_debug
    return {
        "passed": _tests_passed,
        "failed": _tests_failed,
        "results": _test_results.duplicate()
    }

# Test 1: Initial game state
func _test_initial_state() -> void:
    _reset_game_state()
    
    var assert_result = _assert_array_equals(GameState.available_missions, ["taco_bell_drop"], 
        "Only Taco Bell should be available initially")
    
    _record_result("Initial State", assert_result)

# Test 2: Complete Taco Bell Drop - unlocks Clean Job and Jazz Club
func _test_taco_bell_completion() -> void:
    _reset_game_state()
    
    GameState.complete_mission("taco_bell_drop")
    
    var has_clean_job = GameState.available_missions.has("clean_job")
    var has_jazz_club = GameState.available_missions.has("velvet_paw_jazz_club")
    var taco_completed = GameState.completed_missions.has("taco_bell_drop")
    
    var conditions := [
        [taco_completed, "Taco Bell should be in completed_missions"],
        [has_clean_job, "Clean Job should unlock after Taco Bell"],
        [has_jazz_club, "Jazz Club should unlock after Taco Bell"],
        [not GameState.available_missions.has("sterling_tower_heist"), "Sterling Tower should NOT unlock yet"]
    ]
    
    _record_result("Taco Bell Completion", _evaluate_conditions(conditions))

# Test 3: Complete Clean Job - unlocks Rewrite Room
func _test_clean_job_completion() -> void:
    _reset_game_state()
    
    # Complete prerequisites
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    
    var has_rewrite_room = GameState.available_missions.has("rewrite_room")
    
    var conditions := [
        [has_rewrite_room, "Rewrite Room should unlock after Clean Job"],
        [GameState.available_missions.has("clean_job"), "Clean Job should remain available (completed missions don't disappear)"]
    ]
    
    _record_result("Clean Job Completion", _evaluate_conditions(conditions))

# Test 4: Complete Velvet Paw Jazz Club - unlocks Arm Wrestling Underground
func _test_jazz_club_completion() -> void:
    _reset_game_state()
    
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("velvet_paw_jazz_club")
    
    var has_arm_wrestling = GameState.available_missions.has("arm_wrestling_underground")
    
    var conditions := [
        [has_arm_wrestling, "Arm Wrestling Underground should unlock after Jazz Club"],
        [not GameState.available_missions.has("diamond_a_year_job"), "Diamond Vault should NOT unlock from Jazz Club alone"]
    ]
    
    _record_result("Jazz Club Completion", _evaluate_conditions(conditions))

# Test 5: Complete Rewrite Room - unlocks Diamond Vault and Fast Family Getaway
func _test_rewrite_room_completion() -> void:
    _reset_game_state()
    
    # Complete prerequisites
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.complete_mission("rewrite_room")
    
    var has_diamond_vault = GameState.available_missions.has("diamond_a_year_job")
    var has_getaway = GameState.available_missions.has("fast_family_getaway")
    
    var conditions := [
        [has_diamond_vault, "Diamond a Year Job should unlock after Rewrite Room"],
        [has_getaway, "Fast Family Getaway should unlock after Rewrite Room"]
    ]
    
    _record_result("Rewrite Room Completion", _evaluate_conditions(conditions))

# Test 6: Parallel branch combination - need both branches for final unlock
func _test_parallel_branch_combination() -> void:
    _reset_game_state()
    
    # Complete left branch only
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.complete_mission("rewrite_room")
    GameState.complete_mission("diamond_a_year_job")
    GameState.complete_mission("persian_tea_poison_ink")
    GameState.complete_mission("shadow_solo_contract")
    
    var has_sterling_from_left_only = GameState.available_missions.has("sterling_tower_heist")
    
    # Reset and complete right branch only
    _reset_game_state()
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("velvet_paw_jazz_club")
    GameState.complete_mission("arm_wrestling_underground")
    GameState.complete_mission("rewrite_room")
    GameState.complete_mission("fast_family_getaway")
    GameState.complete_mission("elephant_in_the_room")
    
    var has_sterling_from_right_only = GameState.available_missions.has("sterling_tower_heist")
    
    var conditions := [
        [not has_sterling_from_left_only, "Sterling Tower should NOT unlock with only left branch"],
        [not has_sterling_from_right_only, "Sterling Tower should NOT unlock with only right branch"]
    ]
    
    _record_result("Parallel Branch Combination", _evaluate_conditions(conditions))

# Test 7: Complete Diamond Vault - unlocks Persian Tea
func _test_diamond_vault_completion() -> void:
    _reset_game_state()
    
    # Complete prerequisites
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.complete_mission("rewrite_room")
    GameState.complete_mission("diamond_a_year_job")
    
    var has_persian_tea = GameState.available_missions.has("persian_tea_poison_ink")
    
    _record_result("Diamond Vault Completion", _assert_true(has_persian_tea, 
        "Persian Tea and Poison Ink should unlock after Diamond a Year Job"))

# Test 8: Complete Fast Family Getaway - unlocks Elephant in the Room
func _test_getaway_completion() -> void:
    _reset_game_state()
    
    # Complete prerequisites
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.complete_mission("rewrite_room")
    GameState.complete_mission("fast_family_getaway")
    
    var has_elephant_room = GameState.available_missions.has("elephant_in_the_room")
    
    _record_result("Fast Family Getaway Completion", _assert_true(has_elephant_room,
        "Elephant in the Room should unlock after Fast Family Getaway"))

# Test 9: Complete Arm Wrestling Underground - no new unlocks but favor granted
func _test_arm_wrestling_completion() -> void:
    _reset_game_state()
    
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("velvet_paw_jazz_club")
    
    var available_before = GameState.available_missions.duplicate()
    
    GameState.complete_mission("arm_wrestling_underground")
    
    # Check that no new missions unlocked from arm wrestling
    var new_missions: Array[String] = []
    for mission in GameState.available_missions:
        if not available_before.has(mission):
            new_missions.append(mission)
    
    var violet_helped = GameState.friend_favors.get("violet", {}).get("helped", false)
    
    var conditions := [
        [violet_helped, "Violet should be marked as helped after completing Arm Wrestling"],
        [new_missions.is_empty(), "Arm Wrestling should not unlock new missions directly"]
    ]
    
    _record_result("Arm Wrestling Completion", _evaluate_conditions(conditions))

# Test 10: Complete Persian Tea - unlocks Shadow Solo Contract
func _test_persian_tea_completion() -> void:
    _reset_game_state()
    
    # Complete left branch up to Persian Tea
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.complete_mission("rewrite_room")
    GameState.complete_mission("diamond_a_year_job")
    GameState.complete_mission("persian_tea_poison_ink")
    
    var has_shadow_solo = GameState.available_missions.has("shadow_solo_contract")
    
    _record_result("Persian Tea Completion", _assert_true(has_shadow_solo,
        "Shadow Solo Contract should unlock after Persian Tea and Poison Ink"))

# Test 11: Complete Elephant in the Room - emotional milestone
func _test_elephant_room_completion() -> void:
    _reset_game_state()
    
    # Complete right branch up to Elephant Room
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.complete_mission("rewrite_room")
    GameState.complete_mission("fast_family_getaway")
    GameState.complete_mission("elephant_in_the_room")
    
    var bentley_helped = GameState.friend_favors.get("bentley", {}).get("helped", false)
    @warning_ignore("unused_variable")
    var _ellie_polaroid = GameState.collected_polaroids.has("ellie_polaroid")
    
    var conditions := [
        [bentley_helped, "Bentley should be marked as helped"],
        [not GameState.available_missions.has("sterling_tower_heist"), "Sterling Tower should NOT unlock yet (missing Shadow Solo)"]
    ]
    
    _record_result("Elephant in the Room Completion", _evaluate_conditions(conditions))

# Test 12: Complete Shadow Solo Contract - final preparation
func _test_shadow_solo_completion() -> void:
    _reset_game_state()
    
    # Complete left branch up to Shadow Solo
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.complete_mission("rewrite_room")
    GameState.complete_mission("diamond_a_year_job")
    GameState.complete_mission("persian_tea_poison_ink")
    GameState.complete_mission("shadow_solo_contract")
    
    var kiro_helped = GameState.friend_favors.get("kiro", {}).get("helped", false) or \
                      GameState.friend_favors.get("jin", {}).get("helped", false)
    var has_sterling = GameState.available_missions.has("sterling_tower_heist")
    
    var conditions := [
        [not has_sterling, "Sterling Tower should NOT unlock yet (missing Elephant Room)"]
    ]
    
    _record_result("Shadow Solo Completion", _evaluate_conditions(conditions))

# Test 13: Sterling Tower gating - requires ALL 9 story missions
func _test_sterling_tower_gating() -> void:
    _reset_game_state()
    
    # Complete all 9 required missions
    var required_missions: Array[String] = [
        "taco_bell_drop",
        "clean_job",
        "velvet_paw_jazz_club",
        "rewrite_room",
        "fast_family_getaway",
        "diamond_a_year_job",
        "persian_tea_poison_ink",
        "elephant_in_the_room",
        "shadow_solo_contract"
    ]
    
    for mission_id in required_missions:
        GameState.complete_mission(mission_id)
    
    var has_sterling = GameState.available_missions.has("sterling_tower_heist")
    var can_unlock_method = GameState._can_unlock_sterling_tower()
    
    var conditions := [
        [has_sterling, "Sterling Tower should unlock after all 9 story missions"],
        [can_unlock_method, "_can_unlock_sterling_tower() should return true"],
        [GameState.mission_catalog.has("sterling_tower_heist"), "Sterling Tower mission should exist in catalog"]
    ]
    
    _record_result("Sterling Tower Gating", _evaluate_conditions(conditions))

# Test 14: Completion order independence - different orders should work
func _test_completion_order_independence() -> void:
    var required_missions: Array[String] = [
        "taco_bell_drop",
        "clean_job", 
        "velvet_paw_jazz_club",
        "rewrite_room",
        "diamond_a_year_job",
        "arm_wrestling_underground",
        "fast_family_getaway",
        "persian_tea_poison_ink",
        "shadow_solo_contract",
        "elephant_in_the_room"
    ]
    
    # Test random order
    _reset_game_state()
    
    var shuffled: Array[String] = required_missions.duplicate()
    shuffled.shuffle()
    
    for mission_id in shuffled:
        GameState.complete_mission(mission_id)
    
    var has_sterling = GameState.available_missions.has("sterling_tower_heist")
    
    _record_result("Completion Order Independence", _assert_true(has_sterling,
        "Sterling Tower should unlock regardless of completion order"))

# Test 15: Duplicate completion handling - shouldn't duplicate unlocks
func _test_duplicate_completion_handling() -> void:
    _reset_game_state()
    
    GameState.complete_mission("taco_bell_drop")
    var available_count_after_first = GameState.available_missions.size()
    
    # Try to complete again (should be idempotent for unlocks)
    GameState.complete_mission("taco_bell_drop")
    var available_count_after_duplicate = GameState.available_missions.size()
    
    var conditions := [
        [available_count_after_first == available_count_after_duplicate, "Duplicate completion shouldn't add duplicate missions"],
        [GameState.completed_missions.count("taco_bell_drop") == 1, "Mission should only appear once in completed_missions"]
    ]
    
    _record_result("Duplicate Completion Handling", _evaluate_conditions(conditions))

# Test 16: Fail mission handling - shouldn't break unlock chain
func _test_fail_mission_handling() -> void:
    _reset_game_state()
    
    GameState.complete_mission("taco_bell_drop")
    var available_after_success = GameState.available_missions.size()
    
    _reset_game_state()
    
    GameState.complete_mission("taco_bell_drop")
    GameState.fail_mission("clean_job")  # Fail a mission that would unlock
    
    var has_clean_job = GameState.available_missions.has("clean_job")
    var has_intel = GameState.intel_points > 0
    
    var conditions := [
        [has_clean_job, "Clean Job should still be available (failure doesn't block unlocks)"],
        [has_intel, "Intel points should be awarded for failure"],
        [GameState.failed_attempts.has("clean_job"), "Failure should be logged in failed_attempts"]
    ]
    
    _record_result("Fail Mission Handling", _evaluate_conditions(conditions))

# Helper: Reset game state for clean tests
func _reset_game_state() -> void:
    GameState.reset_for_new_game()

# Helper: Record test result
func _record_result(test_name: String, passed: bool, message: String = "") -> void:
    var status = "PASS" if passed else "FAIL"
    var result_str = "[%s] %s" % [status, test_name]
    if not message.is_empty():
        result_str += ": " + message
    
    _test_results.append(result_str)
    
    if passed:
        _tests_passed += 1
        print("✓ " + test_name)
    else:
        _tests_failed += 1
        print("✗ " + result_str)

# Helper: Assert array equality
func _assert_array_equals(actual: Array, expected: Array, description: String) -> bool:
    if actual.size() != expected.size():
        return false
    
    for item in expected:
        if not actual.has(item):
            return false
    
    for item in actual:
        if not expected.has(item):
            return false
    
    return true

# Helper: Assert true
func _assert_true(value: bool, description: String) -> bool:
    return value

# Helper: Evaluate multiple conditions
func _evaluate_conditions(conditions: Array) -> bool:
    var all_passed = true
    var failures: Array[String] = []
    
    for condition in conditions:
        var passed: bool = condition[0]
        var message: String = condition[1]
        
        if not passed:
            all_passed = false
            failures.append(message)
    
    return all_passed

# Run quick smoke test - can be called from console
func smoke_test() -> bool:
    print("\n=== Story Unlock Smoke Test ===\n")
    
    _reset_game_state()
    
    # Quick smoke: Initial state
    if not _assert_array_equals(GameState.available_missions, ["taco_bell_drop"], ""):
        print("✗ Initial state failed")
        return false
    print("✓ Initial state correct")
    
    # Quick smoke: First completion unlocks
    GameState.complete_mission("taco_bell_drop")
    if not GameState.available_missions.has("clean_job"):
        print("✗ Clean Job unlock failed")
        return false
    print("✓ First unlock chain works")
    
    # Quick smoke: Sterling Tower gating
    var required: Array[String] = [
        "taco_bell_drop", "clean_job", "velvet_paw_jazz_club", "rewrite_room",
        "fast_family_getaway", "diamond_a_year_job", "persian_tea_poison_ink",
        "elephant_in_the_room", "shadow_solo_contract"
    ]
    
    _reset_game_state()
    for mission in required:
        GameState.complete_mission(mission)
    
    if not GameState.available_missions.has("sterling_tower_heist"):
        print("✗ Sterling Tower unlock failed")
        return false
    print("✓ Sterling Tower properly gated")
    
    print("\n=== Smoke Test PASSED ===\n")
    return true
