extends "res://src/levels/LevelBase.gd"

## Separate boss arena for Velvet Paw; returns to JazzClubMission with resume data on victory.
const JAZZ_MISSION_SCENE := "res://scenes/missions/JazzClubMission.tscn"
const CLUB_OWNER_BOSS_SCENE := "res://scenes/characters/club_owner_boss.tscn"

var _boss: Node = null

#region agent log
func _agent_debug_log(hypothesis_id: String, message: String, data: Dictionary = {}) -> void:
	var payload := {
		"sessionId": "755971",
		"runId": "initial",
		"hypothesisId": hypothesis_id,
		"location": "src/missions/JazzClubOwnerArena.gd",
		"message": message,
		"data": data,
		"timestamp": Time.get_ticks_msec()
	}
	var path := "res://debug-755971.log"
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE_READ)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(payload))
		file.close()
#endregion

func _ready() -> void:
	mission_id = "velvet_paw_jazz_club"
	auto_start_mission = false
	objective_text = "The suite muscle answers to Sterling. Put him down—then the briefcase is yours."
	guard_count = 0
	super._ready()
	_agent_debug_log("H2,H4", "arena ready after LevelBase", {
		"player_valid": is_instance_valid(player),
		"player_pos": player.global_position if is_instance_valid(player) else Vector2.ZERO,
		"enemy_count": get_tree().get_nodes_in_group("enemy").size(),
		"children": get_child_count()
	})
	AudioManager.play_music("nocturne_city")
	_spawn_boss()
	call_deferred("_begin_boss_intro")


func _spawn_boss() -> void:
	var packed := load(CLUB_OWNER_BOSS_SCENE)
	if packed == null or not (packed is PackedScene):
		_agent_debug_log("H1", "boss packed scene failed to load", {"path": CLUB_OWNER_BOSS_SCENE, "packed": str(packed)})
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
	_agent_debug_log("H1,H2,H3,H4", "boss spawned and disabled before intro", {
		"boss_valid": is_instance_valid(_boss),
		"boss_type": _boss.get_class(),
		"boss_pos": (_boss as Node2D).global_position if _boss is Node2D else Vector2.ZERO,
		"boss_process_mode": _boss.process_mode,
		"has_died_signal": _boss.has_signal("died"),
		"enemy_count": get_tree().get_nodes_in_group("enemy").size()
	})


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
	_agent_debug_log("H3,H4", "intro finished, boss process enabled", {
		"boss_valid": is_instance_valid(_boss),
		"boss_process_mode": _boss.process_mode if is_instance_valid(_boss) else -1,
		"boss_pos": (_boss as Node2D).global_position if _boss is Node2D else Vector2.ZERO,
		"player_pos": player.global_position if is_instance_valid(player) else Vector2.ZERO,
		"enemy_count": get_tree().get_nodes_in_group("enemy").size()
	})
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
