extends Node

enum Transition { NONE, FADE }

const TITLE_SCENE := "res://scenes/MainMenu.tscn"
const HIDEOUT_SCENE := "res://scenes/hideout/hideout.tscn"
const CITY_HUB_SCENE := "res://scenes/CityHub.tscn"
const MISSION_SELECT_SCENE := "res://scenes/ui/MissionSelect.tscn"
const SCHEME_CARD_SCENE := "res://scenes/ui/SchemeCardMenu.tscn"
const MISSION_RESULT_SCENE := "res://scenes/ui/MissionResult.tscn"
const POLAROID_GALLERY_SCENE := "res://scenes/ui/PolaroidGallery.tscn"
const GLOW_COLLECTIBLE_SHELF_SCENE := "res://scenes/ui/GlowCollectibleShelf.tscn"
const CREW_MENU_SCENE := "res://scenes/ui/CrewMenu.tscn"
const EVIDENCE_BOARD_SCENE := "res://src/ui/evidence_board/evidence_board.tscn"
const ENDING_SCENE := "res://scenes/ui/Ending.tscn"

var transition_in_progress := false

func _ready() -> void:
	EventBus.debug("SceneManager ready")

func change_scene(scene_path: String, _transition_type = Transition.NONE, _transition_time = 0.2) -> void:
	if scene_path == "":
		return
	if transition_in_progress:
		EventBus.warn("Scene change already in progress: " + scene_path)
		return
	transition_in_progress = true
	call_deferred("_change_scene_deferred", scene_path)

func _change_scene_deferred(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		EventBus.warn("Scene file not found: " + scene_path)
		transition_in_progress = false
		return
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		EventBus.warn("Scene change failed: " + scene_path + " error=" + str(err))
		if GameState.is_in_mission:
			GameState.is_in_mission = false
			GameState.current_mission_id = ""
	else:
		if GameState.is_in_mission and GameState.current_mission_id != "" and scene_path == GameState.get_mission_scene_path(GameState.current_mission_id):
			GameState.pending_mission_id = ""
	transition_in_progress = false

func change_to_scene(scene_name: String, _transition_type = Transition.NONE, _transition_time = 0.2) -> void:
	match scene_name:
		"title": change_scene(TITLE_SCENE)
		"hideout": change_scene(HIDEOUT_SCENE)
		"city_hub": change_scene(CITY_HUB_SCENE)
		"mission_select": change_scene(MISSION_SELECT_SCENE)
		"scheme_cards": change_scene(SCHEME_CARD_SCENE)
		"mission_result": change_scene(MISSION_RESULT_SCENE)
		_: change_scene(scene_name)

func start_new_game() -> void:
	GameState.reset_for_new_game()
	SaveManager.auto_save()
	change_scene(HIDEOUT_SCENE)

func continue_game() -> void:
	if SaveManager.load_game():
		change_scene(HIDEOUT_SCENE)
	else:
		start_new_game()

func open_mission_select() -> void:
	change_scene(MISSION_SELECT_SCENE)

func open_city_hub() -> void:
	change_scene(CITY_HUB_SCENE)

func open_scheme_card_menu(mission_id: String) -> void:
	GameState.set_pending_mission(mission_id)
	change_scene(SCHEME_CARD_SCENE)

func start_pending_mission() -> void:
	var mission_id := GameState.pending_mission_id
	if mission_id == "":
		mission_id = "test_mission"
	start_mission(mission_id)

func start_mission(mission_id: String) -> void:
	var scene_path := GameState.get_mission_scene_path(mission_id)
	if OS.is_debug_build() and mission_id == "taco_bell_drop" and bool(GameState.dialogue_flags.get("dev_force_iso_taco_bell", true)):
		scene_path = "res://scenes/missions_iso/TacoBellIsoBlockout.tscn"
	GameState.start_mission(mission_id)
	change_scene(scene_path)

func show_mission_result(result: Dictionary = {}) -> void:
	if result.size() > 0:
		GameState.last_mission_result = result
	SaveManager.auto_save()
	change_scene(MISSION_RESULT_SCENE)

func return_to_hideout() -> void:
	SaveManager.auto_save()
	change_scene(HIDEOUT_SCENE)

func return_to_title() -> void:
	change_scene(TITLE_SCENE)

func open_polaroid_gallery() -> void:
	change_scene(POLAROID_GALLERY_SCENE)

func open_glow_collectible_shelf() -> void:
	change_scene(GLOW_COLLECTIBLE_SHELF_SCENE)

func open_crew_menu() -> void:
	change_scene(CREW_MENU_SCENE)

func open_evidence_board() -> void:
	change_scene(EVIDENCE_BOARD_SCENE)

func show_ending() -> void:
	SaveManager.auto_save()
	change_scene(ENDING_SCENE)
