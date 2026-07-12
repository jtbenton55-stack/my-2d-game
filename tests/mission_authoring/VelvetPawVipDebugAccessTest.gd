# GdUnit4 tests for Velvet Paw's attempt-local F12 VIP access control.
extends GdUnitTestSuite

const MISSION_ID := "velvet_paw_jazz_club"
const COVER_ID := "velvet_paw_vip_guest"
const CREDENTIAL_ID := "velvet_paw_vip_wristband"
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const QAPanelScript := preload("res://src/missions/iso/runtime/MissionQAChecklistPanel.gd")


func before() -> void:
	GameState.current_mission_id = MISSION_ID
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission(MISSION_ID)


func after() -> void:
	SocialStealthAdapterScript.clear_all()
	GameState.current_mission_id = ""


func test_targeted_removal_preserves_unrelated_social_state() -> void:
	var context := {"mission_id": MISSION_ID}
	SocialStealthAdapterScript.set_cover_story(COVER_ID, {}, context)
	SocialStealthAdapterScript.set_cover_story("staff_member", {}, context)
	SocialStealthAdapterScript.grant_credential("staff_badge", {}, context)
	SocialStealthAdapterScript.grant_credential(CREDENTIAL_ID, {}, context)
	SocialStealthAdapterScript.complete_protocol("vip_etiquette", {}, context)
	SocialStealthAdapterScript.set_professionalism(3, context)

	assert_bool(SocialStealthAdapterScript.clear_cover_story(COVER_ID, context).get("ok", false)).is_true()
	assert_bool(SocialStealthAdapterScript.revoke_credential(CREDENTIAL_ID, context).get("ok", false)).is_true()
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, COVER_ID, context)).is_false()
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, "staff_member", context)).is_true()
	assert_str(String(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, "", context))).is_equal("staff_member")
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, CREDENTIAL_ID, context)).is_false()
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, "staff_badge", context)).is_true()
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_PROTOCOL_COMPLETE, "vip_etiquette", context)).is_true()
	assert_int(int(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_PROFESSIONALISM_SCORE, "", context))).is_equal(3)


func test_velvet_dropdown_applies_and_removes_only_vip_facts() -> void:
	var context := {"mission_id": MISSION_ID}
	SocialStealthAdapterScript.set_cover_story("staff_member", {}, context)
	SocialStealthAdapterScript.grant_credential("staff_badge", {}, context)
	var panel := QAPanelScript.new()
	add_child(panel)
	var checklist := panel.get_node("ChecklistSelector") as OptionButton
	var selector := panel.get_node("VelvetVipAccessSelector") as OptionButton
	assert_bool(selector.visible).is_true()
	assert_int(selector.get_selected_id()).is_equal(0)
	var checklist_count := checklist.item_count
	var checklist_selected := checklist.selected

	selector.select(selector.get_item_index(1))
	selector.item_selected.emit(selector.selected)
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, COVER_ID, context)).is_true()
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, CREDENTIAL_ID, context)).is_true()
	assert_int(checklist.item_count).is_equal(checklist_count)
	assert_int(checklist.selected).is_equal(checklist_selected)

	selector.select(selector.get_item_index(0))
	selector.item_selected.emit(selector.selected)
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, COVER_ID, context)).is_false()
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, "staff_member", context)).is_true()
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, CREDENTIAL_ID, context)).is_false()
	assert_bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, "staff_badge", context)).is_true()
	panel.queue_free()


func test_dropdown_visibility_and_initial_state_derive_from_current_mission_facts() -> void:
	var context := {"mission_id": MISSION_ID}
	SocialStealthAdapterScript.set_cover_story(COVER_ID, {}, context)
	SocialStealthAdapterScript.grant_credential(CREDENTIAL_ID, {}, context)
	var panel := QAPanelScript.new()
	add_child(panel)
	var selector := panel.get_node("VelvetVipAccessSelector") as OptionButton
	assert_bool(selector.visible).is_true()
	assert_int(selector.get_selected_id()).is_equal(1)

	GameState.current_mission_id = "taco_bell_drop"
	panel.call("_refresh")
	assert_bool(selector.visible).is_false()
	panel.queue_free()
