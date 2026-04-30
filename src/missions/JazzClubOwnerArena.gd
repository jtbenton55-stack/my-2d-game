extends "res://src/levels/LevelBase.gd"

## Separate boss arena for Velvet Paw; returns to JazzClubMission with resume data on victory.
const JAZZ_MISSION_SCENE := "res://scenes/missions/JazzClubMission.tscn"
const CLUB_OWNER_BOSS_SCENE := "res://scenes/characters/club_owner_boss.tscn"

var _boss: Node = null

func _ready() -> void:
	mission_id = "velvet_paw_jazz_club"
	auto_start_mission = false
	objective_text = "The suite muscle answers to Sterling. Put him down—then the briefcase is yours."
	guard_count = 0
	super._ready()
	AudioManager.play_music("nocturne_city")
	_spawn_boss()
	call_deferred("_begin_boss_intro")


func _spawn_boss() -> void:
	var packed := load(CLUB_OWNER_BOSS_SCENE)
	if packed == null or not (packed is PackedScene):
		push_error("JazzClubOwnerArena: missing club owner boss scene")
		return
	_boss = (packed as PackedScene).instantiate()
	_boss.name = "ClubOwner"
	add_child(_boss)
	var mk := get_node_or_null("BossSpawn") as Node2D
	if mk:
		_boss.global_position = mk.global_position
	else:
		_boss.global_position = Vector2(400, 260)
	if _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)
	_boss.process_mode = Node.PROCESS_MODE_DISABLED


func _begin_boss_intro() -> void:
	if not EventBus.dialogue_ended.is_connected(_on_intro_dialogue_finished):
		EventBus.dialogue_ended.connect(_on_intro_dialogue_finished, CONNECT_ONE_SHOT)
	var lines: Array[Dictionary] = [
		{"speaker": "Club Owner", "text": "This suite isn't on the guest list. You want Sterling's book—you pay Sterling's cover."},
		{"speaker": "Parmida", "text": "He's not hospitality—he's collection. The briefcase is the door prize."},
		{"speaker": "Club Owner", "text": "House rules: you bleed out quiet, or the crowd never hears a thing."},
		{"speaker": "Bentley", "text": "*growl* (Wrong cologne. Right fight.)"}
	]
	DialogueManager.start_simple_dialogue(lines)


func _on_intro_dialogue_finished() -> void:
	if is_instance_valid(_boss):
		_boss.process_mode = Node.PROCESS_MODE_INHERIT
	QuestManager.set_objective("Dodge the slam. Strike between wind-ups.", mission_id)


func _on_boss_died(_enemy: Node) -> void:
	_boss = null
	if not EventBus.dialogue_ended.is_connected(_on_victory_dialogue_finished):
		EventBus.dialogue_ended.connect(_on_victory_dialogue_finished, CONNECT_ONE_SHOT)
	var outro: Array[Dictionary] = [
		{"speaker": "Parmida", "text": "Sterling's muscle just choked on his own velvet rope. The briefcase is back on the balcony."},
		{"speaker": "Yordano", "text": "I'll ride the stair rumble—move before the house mix swallows the evidence."},
		{"speaker": "Bentley", "text": "Woof! (Ink's waiting. Don't admire the view.)"}
	]
	DialogueManager.start_simple_dialogue(outro)


func _on_victory_dialogue_finished() -> void:
	var rd := GameState.velvet_paw_resume_data.duplicate(true)
	rd["club_owner_defeated"] = true
	rd["club_owner_spawned"] = false
	GameState.set_velvet_paw_resume_data(rd)
	GameState.next_spawn = "ReturnFromOwnerSuite"
	SceneManager.change_scene(JAZZ_MISSION_SCENE)


func _on_player_died() -> void:
	GameState.clear_velvet_paw_resume_data()
	super._on_player_died()
