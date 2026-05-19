# GdUnit4 smoke tests for D6-06 authored collectible persistence helpers.
extends GdUnitTestSuite

const PERSIST := preload("res://src/missions/iso/runtime/MissionAuthoredCollectiblePersistence.gd")


func test_persist_flag_key_uses_collectible_id() -> void:
	assert_str(
		PERSIST.persist_flag_key("d6_06_proof_poop", "poop_bag")
	).is_equal("d6_06_authored_committed:d6_06_proof_poop")


func test_is_already_persisted_reads_dialogue_flag() -> void:
	var prev := GameState.dialogue_flags.duplicate(true)
	GameState.dialogue_flags.clear()
	GameState.dialogue_flags["d6_06_authored_committed:test_id"] = true
	assert_bool(PERSIST.is_already_persisted("test_id", "polaroid")).is_true()
	GameState.dialogue_flags = prev


func test_mark_persisted_sets_flag() -> void:
	var prev := GameState.dialogue_flags.duplicate(true)
	GameState.dialogue_flags.erase("d6_06_authored_committed:mark_test")
	PERSIST.mark_persisted("mark_test", "tiny_icon")
	assert_bool(GameState.dialogue_flags.get("d6_06_authored_committed:mark_test", false)).is_true()
	GameState.dialogue_flags = prev


func test_commit_case_cash_banks_when_no_hideout_controller() -> void:
	const HIDEOUT_SYNC := preload("res://src/missions/iso/runtime/MissionCollectibleHideoutSync.gd")
	var prev := GameState.dialogue_flags.duplicate(true)
	GameState.dialogue_flags.erase("d6_06_case_cash_bank")
	var added := HIDEOUT_SYNC.commit_case_cash(12, {"collectible_id": "test_cash"})
	assert_int(added).is_equal(12)
	assert_int(GameState.dialogue_flags.get("d6_06_case_cash_bank", 0)).is_equal(12)
	GameState.dialogue_flags = prev
