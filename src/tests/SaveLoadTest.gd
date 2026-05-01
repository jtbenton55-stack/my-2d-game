extends Node
class_name SaveLoadTest

# Save/Load System Test Suite

var _test_results: Array[String] = []
var _tests_passed: int = 0
var _tests_failed: int = 0

# Run all save/load tests
func run_all_tests() -> Dictionary:
    var prev_debug := GameState.debug_unlock_all_missions
    GameState.debug_unlock_all_missions = false
    _test_results.clear()
    _tests_passed = 0
    _tests_failed = 0
    
    print("\n=== Save/Load System Tests ===\n")
    
    _test_save_to_dict()
    _test_load_from_dict()
    _test_mission_unlock_persistence()
    _test_sterling_tower_unlock_after_load()
    _test_save_version_handling()
    _test_missing_mission_unlock_repair()
    _test_equipped_items_persistence()
    _test_evidence_board_persistence()
    
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

# Test 1: to_dict() captures all fields
func _test_save_to_dict() -> void:
    GameState.reset_for_new_game()
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.equipped_items = ["lockpick", "smoke_grenade"]
    GameState.evidence_board_data = {"clue_1": true, "clue_2": false}
    GameState.velvet_paw_resume_data = {"step": "LEDGER_PICKUP"}
    GameState.mission_mutation_state = {"taco_bell_drop": {"keypad_code": "2174"}}
    GameState.sterling_clues = {"sterling_delivery_token": {"title": "Token", "discovered": true}}
    GameState.poop_bag_count = 2
    
    var data := GameState.to_dict()
    
    var conditions := [
        [data.has("save_version"), "save_version should be present"],
        [data.has("available_missions"), "available_missions should be present"],
        [data.has("completed_missions"), "completed_missions should be present"],
        [data.has("equipped_items"), "equipped_items should be present"],
        [data.has("evidence_board_data"), "evidence_board_data should be present"],
        [data.save_version == GameState.SAVE_VERSION, "save_version should match current version"],
        [data.completed_missions.has("taco_bell_drop"), "completed_missions should contain taco_bell_drop"],
        [data.completed_missions.has("clean_job"), "completed_missions should contain clean_job"],
        [data.equipped_items.has("lockpick"), "equipped_items should contain lockpick"],
        [data.has("velvet_paw_resume_data"), "velvet_paw_resume_data should serialize"],
        [data.has("mission_mutation_state"), "mission_mutation_state should serialize"],
        [data.has("sterling_clues"), "sterling_clues should serialize"],
        [int(data.get("poop_bag_count", 0)) == 2, "poop_bag_count should serialize"]
    ]
    
    _record_result("Save to Dict", _evaluate_conditions(conditions))

# Test 2: from_dict() restores all fields
func _test_load_from_dict() -> void:
    var test_data := {
        "save_version": GameState.SAVE_VERSION,
        "available_missions": ["taco_bell_drop", "clean_job", "velvet_paw_jazz_club"],
        "completed_missions": ["taco_bell_drop"],
        "failed_attempts": {"taco_bell_drop": 2},
        "unlocked_cards": ["card_1", "card_2"],
        "selected_cards": ["card_1"],
        "collected_polaroids": ["polaroid_1"],
        "crew_members": ["jake", "bentley", "louis"],
        "friend_favors": {"louis": {"helped": true, "favors_owed": 1}},
        "player_upgrades": {"health": 10},
        "bentley_upgrades": {"speed": 5},
        "dialogue_flags": {"flag_1": true},
        "intel_points": 5,
        "player_max_health": 110,
        "player_health": 100,
        "settings": {"audio": {"master_volume": 0.8}},
        "next_spawn": "spawn_point_1",
        "evidence_board_data": {"clue_a": true},
        "equipped_items": ["item_1"],
        "velvet_paw_resume_data": {"foo": "bar"},
        "mission_mutation_state": {"velvet_paw_jazz_club": {"vip_alt_route": true}},
        "sterling_clues": {"c1": {"discovered": false}},
        "poop_bag_count": 4
    }
    
    GameState.from_dict(test_data)
    
    var conditions := [
        [GameState.available_missions.has("clean_job"), "available_missions should restore clean_job"],
        [GameState.completed_missions.has("taco_bell_drop"), "completed_missions should restore taco_bell_drop"],
        [GameState.failed_attempts.get("taco_bell_drop") == 2, "failed_attempts should restore attempt count"],
        [GameState.crew_members.has("louis"), "crew_members should restore louis"],
        [GameState.intel_points == 5, "intel_points should restore to 5"],
        [GameState.player_max_health == 110, "player_max_health should restore to 110"],
        [GameState.next_spawn == "spawn_point_1", "next_spawn should restore correctly"],
        [GameState.equipped_items.has("item_1"), "equipped_items should restore item_1"],
        [GameState.evidence_board_data.has("clue_a"), "evidence_board_data should restore clue_a"],
        [GameState.velvet_paw_resume_data.get("foo", "") == "bar", "velvet_paw_resume_data should restore"],
        [GameState.mission_mutation_state.has("velvet_paw_jazz_club"), "mission_mutation_state should restore"],
        [GameState.sterling_clues.has("c1"), "sterling_clues should restore"],
        [GameState.poop_bag_count == 4, "poop_bag_count should restore"]
    ]
    
    _record_result("Load from Dict", _evaluate_conditions(conditions))

# Test 3: Mission unlocks persist correctly
func _test_mission_unlock_persistence() -> void:
    GameState.reset_for_new_game()
    
    # Complete missions in order
    GameState.complete_mission("taco_bell_drop")
    GameState.complete_mission("clean_job")
    GameState.complete_mission("rewrite_room")
    
    var original_available := GameState.available_missions.duplicate()
    var original_completed := GameState.completed_missions.duplicate()
    
    # Simulate save and load
    var save_data := GameState.to_dict()
    GameState.reset_for_new_game(false)
    GameState.from_dict(save_data)
    
    var all_unlocks_restored := true
    for mission in original_available:
        if not GameState.available_missions.has(mission):
            all_unlocks_restored = false
            break
    
    var conditions := [
        [GameState.completed_missions.has("taco_bell_drop"), "completed taco_bell_drop should persist"],
        [GameState.completed_missions.has("clean_job"), "completed clean_job should persist"],
        [GameState.completed_missions.has("rewrite_room"), "completed rewrite_room should persist"],
        [all_unlocks_restored, "all available mission unlocks should persist"]
    ]
    
    _record_result("Mission Unlock Persistence", _evaluate_conditions(conditions))

# Test 4: Sterling Tower unlocks after loading if all prerequisites met
func _test_sterling_tower_unlock_after_load() -> void:
    var required_missions: Array[String] = [
        "taco_bell_drop", "clean_job", "velvet_paw_jazz_club",
        "rewrite_room", "fast_family_getaway", "diamond_a_year_job",
        "persian_tea_poison_ink", "elephant_in_the_room", "shadow_solo_contract"
    ]
    
    # Create a save with all required missions completed
    var test_data := {
        "save_version": GameState.SAVE_VERSION,
        "available_missions": ["taco_bell_drop"],
        "completed_missions": required_missions,
        "failed_attempts": {},
        "unlocked_cards": [],
        "selected_cards": [],
        "collected_polaroids": [],
        "crew_members": ["jake", "bentley"],
        "friend_favors": {},
        "player_upgrades": {},
        "bentley_upgrades": {},
        "dialogue_flags": {},
        "intel_points": 0,
        "player_max_health": 100,
        "player_health": 100,
        "settings": {},
        "next_spawn": "default",
        "evidence_board_data": {},
        "equipped_items": []
    }
    
    GameState.from_dict(test_data)
    
    var has_sterling := GameState.available_missions.has("sterling_tower_heist")
    
    _record_result("Sterling Tower After Load", _assert_true(has_sterling,
        "Sterling Tower should unlock after loading save with all prerequisites"))

# Test 5: Save version handling
func _test_save_version_handling() -> void:
    # Test loading old version save
    var old_version_save := {
        "save_version": "0.2.0",
        "available_missions": ["taco_bell_drop"],
        "completed_missions": []
    }
    
    GameState.from_dict(old_version_save)
    
    var conditions := [
        [GameState.SAVE_VERSION != "0.2.0", "current save version should be newer"],
        [GameState.available_missions.has("taco_bell_drop"), "data should still load from old version"]
    ]
    
    _record_result("Save Version Handling", _evaluate_conditions(conditions))

# Test 6: Missing mission unlock repair
func _test_missing_mission_unlock_repair() -> void:
    # Simulate a corrupted save where completed missions exist but unlocks are missing
    var corrupted_save := {
        "save_version": GameState.SAVE_VERSION,
        "available_missions": ["taco_bell_drop"],  # Only initial mission
        "completed_missions": ["taco_bell_drop", "clean_job"],  # But clean_job is completed
        "failed_attempts": {},
        "unlocked_cards": [],
        "selected_cards": [],
        "collected_polaroids": [],
        "crew_members": ["jake", "bentley"],
        "friend_favors": {},
        "player_upgrades": {},
        "bentley_upgrades": {},
        "dialogue_flags": {},
        "intel_points": 0,
        "player_max_health": 100,
        "player_health": 100,
        "settings": {},
        "next_spawn": "default",
        "evidence_board_data": {},
        "equipped_items": []
    }
    
    GameState.from_dict(corrupted_save)
    
    # The validation should fix the missing unlocks
    var has_rewrite_room := GameState.available_missions.has("rewrite_room")
    
    _record_result("Missing Unlock Repair", _assert_true(has_rewrite_room,
        "Validation should restore rewrite_room unlock from clean_job completion"))

# Test 7: Equipped items persistence
func _test_equipped_items_persistence() -> void:
    GameState.reset_for_new_game()
    GameState.equipped_items = ["lockpick", "smoke_grenade", "grappling_hook"]
    
    var save_data := GameState.to_dict()
    GameState.equipped_items = []
    GameState.from_dict(save_data)
    
    var conditions := [
        [GameState.equipped_items.has("lockpick"), "lockpick should persist"],
        [GameState.equipped_items.has("smoke_grenade"), "smoke_grenade should persist"],
        [GameState.equipped_items.size() == 3, "all 3 equipped items should persist"]
    ]
    
    _record_result("Equipped Items Persistence", _evaluate_conditions(conditions))

# Test 8: Evidence board data persistence
func _test_evidence_board_persistence() -> void:
    GameState.reset_for_new_game()
    GameState.evidence_board_data = {
        "sterling_photo_placed": true,
        "louis_clue_connected": true,
        "vault_location_revealed": false,
        "crew_notes": "Meet at midnight"
    }
    
    var save_data := GameState.to_dict()
    GameState.evidence_board_data = {}
    GameState.from_dict(save_data)
    
    var conditions := [
        [GameState.evidence_board_data.get("sterling_photo_placed") == true, "sterling_photo_placed should persist"],
        [GameState.evidence_board_data.get("louis_clue_connected") == true, "louis_clue_connected should persist"],
        [GameState.evidence_board_data.get("vault_location_revealed") == false, "vault_location_revealed should persist"],
        [GameState.evidence_board_data.get("crew_notes") == "Meet at midnight", "crew_notes string should persist"]
    ]
    
    _record_result("Evidence Board Persistence", _evaluate_conditions(conditions))

# Quick smoke test for save/load
func smoke_test() -> bool:
    print("\n=== Save/Load Smoke Test ===\n")
    
    GameState.reset_for_new_game()
    
    # Complete a mission
    GameState.complete_mission("taco_bell_drop")
    var original_count := GameState.available_missions.size()
    
    # Save and reset
    var save_data := GameState.to_dict()
    GameState.reset_for_new_game(false)
    
    # Load and verify
    GameState.from_dict(save_data)
    
    if not GameState.completed_missions.has("taco_bell_drop"):
        print("✗ Completed mission not restored")
        return false
    print("✓ Mission completion restored")
    
    if GameState.available_missions.size() != original_count:
        print("✗ Mission unlocks not restored correctly")
        return false
    print("✓ Mission unlocks restored")
    
    print("\n=== Smoke Test PASSED ===\n")
    return true

# Helper: Reset game state
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
    
    if not all_passed and failures.size() > 0:
        print("    Failed conditions: " + ", ".join(failures))
    
    return all_passed
