extends GdUnitTestSuite

const TACO_PLAYABLE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const CORNER_PLAYABLE := "res://scenes/missions_iso/CornerStoreCashout_Editable.tscn"
const VELVET_PAW_PLAYABLE := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"

var _catalog_snapshot: Dictionary = {}


func before() -> void:
	_catalog_snapshot = GameState.mission_catalog.duplicate(true)


func after() -> void:
	GameState.mission_catalog = _catalog_snapshot.duplicate(true)


func test_existing_playable_iso_catalog_entries_resolve() -> void:
	assert_str(MissionSceneResolver.resolve_playable_scene_path("taco_bell_drop")).is_equal(TACO_PLAYABLE)
	assert_str(MissionSceneResolver.get_debug_scene_path("taco_bell_drop")).is_equal(TACO_PLAYABLE)
	assert_str(MissionSceneResolver.resolve_playable_scene_path("corner_store_cashout")).is_equal(CORNER_PLAYABLE)
	assert_str(MissionSceneResolver.get_debug_scene_path("corner_store_cashout")).is_equal(CORNER_PLAYABLE)
	assert_str(MissionSceneResolver.resolve_playable_scene_path("velvet_paw_jazz_club")).is_equal(VELVET_PAW_PLAYABLE)
	assert_str(MissionSceneResolver.get_debug_scene_path("velvet_paw_jazz_club")).is_equal(VELVET_PAW_PLAYABLE)


func test_unknown_mission_falls_back_to_game_state_default() -> void:
	var mission_id := "unknown_catalog_mission"
	assert_str(MissionSceneResolver.resolve_playable_scene_path(mission_id)).is_equal(GameState.get_mission_scene_path(mission_id))


func test_temporary_catalog_playable_iso_scene_resolves_without_resolver_edit() -> void:
	GameState.mission_catalog["resolver_temp_mission"] = {
		"name": "Resolver Temp",
		"description": "Temporary resolver test mission.",
		"scene_path": "res://scenes/missions/TestMissionRoom.tscn",
		"playable_iso_scene": "res://scenes/dev/mission_authoring/NewMissionStarterTemplate.tscn",
		"reward_cards": [],
		"reward_polaroids": [],
		"friend": "",
	}
	assert_str(MissionSceneResolver.resolve_playable_scene_path("resolver_temp_mission")).is_equal("res://scenes/dev/mission_authoring/NewMissionStarterTemplate.tscn")
	var roles: Dictionary = MissionSceneResolver.get_scene_roles("resolver_temp_mission")
	assert_str(String(roles.get("playable_expanded_iso", ""))).is_equal("res://scenes/dev/mission_authoring/NewMissionStarterTemplate.tscn")


func test_resolution_report_warns_on_missing_playable_iso_scene() -> void:
	GameState.mission_catalog["resolver_missing_scene"] = {
		"name": "Resolver Missing Scene",
		"description": "Temporary missing-scene resolver test mission.",
		"scene_path": "res://scenes/missions/TestMissionRoom.tscn",
		"playable_iso_scene": "res://scenes/dev/mission_authoring/DefinitelyMissingMilestoneA.tscn",
		"reward_cards": [],
		"reward_polaroids": [],
		"friend": "",
	}
	var report: Dictionary = MissionSceneResolver.get_resolution_report("resolver_missing_scene")
	var warnings: Array = report.get("warnings", [])
	assert_bool(warnings.size() > 0).is_true()
	assert_str(String(warnings[0])).contains("playable_iso_scene")
