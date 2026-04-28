extends "res://src/levels/LevelBase.gd"

enum MissionStep {
	INTRO,
	FIND_ENTRANCE,
	SOCIAL_STEALTH,
	MUSIC_PUZZLE,
	BACKSTAGE_SEARCH,
	LEDGER_PICKUP,
	ESCAPE,
	COMPLETE
}

var current_step: MissionStep = MissionStep.INTRO
var ledger_collected := false
var music_puzzle_solved := false
var wrong_puzzle_attempts := 0
var clues_found := 0
const TOTAL_CLUES := 2
var bouncer_alerted := false
var yordano_triggered := false
var active_puzzle: Control = null

func _ready() -> void:
	mission_id = "velvet_paw_jazz_club"
	objective_text = "Find a way into the Velvet Paw Jazz Club."
	guard_count = 0
	super._ready()
	
	_setup_mission_zones()
	_setup_bouncer_patrols()
	_setup_readable_notes()
	_setup_music_puzzle_trigger()
	_setup_ledger_zone()
	_setup_polaroid()
	
	var card_effects := get_node_or_null("/root/CardEffects")
	if card_effects != null and card_effects.has_method("show_sniff_trail") and card_effects.show_sniff_trail():
		_create_sniff_trail()
	
	_advance_step(MissionStep.INTRO)

func _setup_mission_zones() -> void:
	var entrance_zone := get_node_or_null("EntranceZone")
	if entrance_zone:
		entrance_zone.body_entered.connect(_on_entrance_entered)
	
	var music_area := get_node_or_null("MusicPuzzleArea")
	if music_area:
		music_area.body_entered.connect(_on_music_area_entered)
	
	var backstage_area := get_node_or_null("BackstageArea")
	if backstage_area:
		backstage_area.body_entered.connect(_on_backstage_entered)
	
	var escape_zone := get_node_or_null("EscapeZone")
	if escape_zone:
		escape_zone.body_entered.connect(_on_escape_entered)
	
	var yordano_zone := get_node_or_null("YordanoTriggerZone")
	if yordano_zone:
		yordano_zone.body_entered.connect(_on_yordano_triggered)

func _setup_bouncer_patrols() -> void:
	for i in range(1, 4):
		var path := get_node_or_null("BouncerPath" + str(i))
		var bouncer := get_node_or_null("Bouncer" + str(i))
		if path and bouncer:
			var patrol := preload("res://src/enemies/components/patrol_component.gd").new()
			patrol.path = path
			patrol.speed = 80.0
			patrol.wait_time = 1.5
			bouncer.add_child(patrol)

func _setup_readable_notes() -> void:
	var clue1 := get_node_or_null("Clue1")
	if clue1:
		clue1.add_to_group("interactable")
		clue1.note_title = "Crumpled Setlist Fragment"
		clue1.note_text = "...first set always opens with something personal. The boss says start with 'Naked Hug My Son' - gets the crowd vulnerable. End with the crowd-pleaser about that crime dog..."
		clue1.polaroid_id = ""
	
	var clue2 := get_node_or_null("Clue2")
	if clue2:
		clue2.add_to_group("interactable")
		clue2.note_title = "Stage Manager's Notes"
		clue2.note_text = "Song order for tonight:\n1. Open with intimacy\n2. Keep it light (bathroom humor always works)\n3. Kids love the Wee-Woo\n4. Dental blues for the working crowd\n5. Two Letters Away - the ballad\n6. Close with Raincoat for a Crime Dog - crowd goes wild"
		clue2.polaroid_id = ""

func _setup_music_puzzle_trigger() -> void:
	var puzzle_zone := get_node_or_null("MusicPuzzleArea")
	if puzzle_zone:
		puzzle_zone.add_to_group("interactable")

func _setup_ledger_zone() -> void:
	var ledger := get_node_or_null("LedgerZone")
	if ledger:
		ledger.visible = false
		ledger.add_to_group("interactable")
		ledger.body_entered.connect(_on_ledger_body_entered)

func _setup_polaroid() -> void:
	var polaroid := get_node_or_null("PolaroidPickup")
	if polaroid:
		polaroid.add_to_group("interactable")

func _advance_step(new_step: MissionStep) -> void:
	current_step = new_step
	match current_step:
		MissionStep.INTRO:
			QuestManager.set_objective("The Velvet Paw is hopping tonight. Find a way inside. Bentley smells something important.", mission_id)
		MissionStep.FIND_ENTRANCE:
			QuestManager.set_objective("The front is too crowded. Look for a side entrance or staff door.", mission_id)
		MissionStep.SOCIAL_STEALTH:
			QuestManager.set_objective("Avoid the bouncers on the social floor. They do not welcome uninvited guests.", mission_id)
		MissionStep.MUSIC_PUZZLE:
			QuestManager.set_objective("The stage area has a song list puzzle. Put the setlist in the correct order to unlock backstage.", mission_id)
		MissionStep.BACKSTAGE_SEARCH:
			QuestManager.set_objective("Search backstage for clues about where the ledger is hidden. Bentley can sniff out the real one.", mission_id)
		MissionStep.LEDGER_PICKUP:
			QuestManager.set_objective("Grab the blackmail ledger. Yordano is waiting for his cue.", mission_id)
		MissionStep.ESCAPE:
			QuestManager.set_objective("Bass drop time. Escape through the basement exit before the bouncers regroup.", mission_id)
		MissionStep.COMPLETE:
			complete_level()

func _on_entrance_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step <= MissionStep.FIND_ENTRANCE:
		_advance_step(MissionStep.SOCIAL_STEALTH)

func _on_music_area_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step == MissionStep.SOCIAL_STEALTH:
		_advance_step(MissionStep.MUSIC_PUZZLE)
		_show_music_puzzle_prompt()

func _on_backstage_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step == MissionStep.MUSIC_PUZZLE and music_puzzle_solved:
		_advance_step(MissionStep.BACKSTAGE_SEARCH)
		_check_clues_and_reveal_ledger()
	elif current_step <= MissionStep.BACKSTAGE_SEARCH and music_puzzle_solved:
		_advance_step(MissionStep.BACKSTAGE_SEARCH)

func _on_escape_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step == MissionStep.ESCAPE and ledger_collected:
		_advance_step(MissionStep.COMPLETE)

func _on_yordano_triggered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if yordano_triggered:
		return
	yordano_triggered = true
	
	if GameState.has_selected_card("yordano_bass_drop"):
		_trigger_bass_drop_stun()
	else:
		_show_yordano_dialogue()

func _trigger_bass_drop_stun() -> void:
	QuestManager.set_objective("YORDANO BASS DROP! The bouncers are stunned!", mission_id)
	AudioManager.play_sfx("bass_drop_explosion")
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("stun"):
			enemy.stun(5.0)
		elif enemy.has_method("set_stunned"):
			enemy.set_stunned(true)
			enemy.set_deferred("is_stunned", false)
			enemy.call_deferred("_resume_after_delay", 5.0)

func _show_yordano_dialogue() -> void:
	var lines := [
		{"speaker": "Yordano", "text": "That's my cue. Time for the exit solo."},
		{"speaker": "Bentley", "text": "Woof! (The bass is about to drop!)"}
	]
	DialogueManager.start_simple_dialogue(lines)

func _on_clue_found() -> void:
	clues_found += 1
	AudioManager.play_sfx("note_read")
	QuestManager.set_objective("Clue found: %d/%d. Bentley is getting closer to the ledger's scent." % [clues_found, TOTAL_CLUES], mission_id)
	_check_clues_and_reveal_ledger()

func _check_clues_and_reveal_ledger() -> void:
	if clues_found >= TOTAL_CLUES and current_step == MissionStep.BACKSTAGE_SEARCH:
		var ledger := get_node_or_null("LedgerZone")
		if ledger and not ledger.visible:
			ledger.visible = true
			QuestManager.set_objective("The ledger is revealed. Bentley's nose never lies.", mission_id)
			_advance_step(MissionStep.LEDGER_PICKUP)

func _on_ledger_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if ledger_collected:
		return
	
	var ledger := get_node_or_null("LedgerZone")
	if not ledger or not ledger.visible:
		return
	
	ledger_collected = true
	ledger.visible = false
	AudioManager.play_sfx("item_pickup")
	
	QuestManager.set_objective("Ledger secured. Yordano is tuning up for your exit.", mission_id)
	_advance_step(MissionStep.ESCAPE)

func _show_music_puzzle_prompt() -> void:
	if music_puzzle_solved or active_puzzle != null:
		return
	
	var lines := [
		{"speaker": "Bentley", "text": "Woof! (There's a setlist on the stage...)"},
		{"speaker": "Parmida", "text": "The songs are out of order. If I fix the setlist, it should unlock the backstage area."}
	]
	DialogueManager.start_simple_dialogue(lines)

func start_music_puzzle() -> void:
	if music_puzzle_solved or active_puzzle != null:
		return
	
	var puzzle_scene := preload("res://src/puzzles/music/music_puzzle.tscn")
	active_puzzle = puzzle_scene.instantiate()
	
	active_puzzle.puzzle_solved.connect(_on_music_puzzle_solved)
	active_puzzle.puzzle_failed.connect(_on_music_puzzle_failed)
	
	add_child(active_puzzle)

func _on_music_puzzle_solved() -> void:
	music_puzzle_solved = true
	active_puzzle = null
	AudioManager.play_sfx("puzzle_solved")
	QuestManager.set_objective("The stage unlocks. Backstage access granted.", mission_id)
	
	var blocker := get_node_or_null("BackstageBlocker")
	if blocker:
		blocker.queue_free()

func _on_music_puzzle_failed() -> void:
	wrong_puzzle_attempts += 1
	bouncer_alerted = true
	active_puzzle = null
	AudioManager.play_sfx("alert")
	QuestManager.set_objective("Wrong order! The bouncer heard the dissonance. Stay hidden!", mission_id)
	
	_alert_nearby_bouncers()

func _alert_nearby_bouncers() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("alert"):
			enemy.alert(player.global_position if player else Vector2.ZERO)
		elif enemy.has_method("set_alerted"):
			enemy.set_alerted(true)

func _create_sniff_trail() -> void:
	var trail := Line2D.new()
	trail.name = "BentleySniffTrail"
	
	var sniff_points := PackedVector2Array()
	var start_point := Vector2(150, 650)
	var clue1 := get_node_or_null("Clue1")
	var clue2 := get_node_or_null("Clue2")
	var ledger := get_node_or_null("LedgerZone")
	
	if clue1:
		sniff_points.append(clue1.global_position)
	if clue2:
		sniff_points.append(clue2.global_position)
	if ledger:
		sniff_points.append(ledger.global_position)
	
	if sniff_points.is_empty():
		sniff_points = PackedVector2Array([
			Vector2(150, 650), Vector2(300, 550),
			Vector2(450, 400), Vector2(600, 300),
			Vector2(800, 200)
		])
	
	trail.points = sniff_points
	trail.width = 4.0
	trail.default_color = Color(0.4, 0.8, 0.4, 0.6)
	add_child(trail)

func complete_level() -> void:
	if not ledger_collected:
		QuestManager.set_objective("The ledger stays. We do not leave witnesses.", mission_id)
		return
	CollectibleManager.collect_polaroid("jazz_club_polaroid")
	super.complete_level()

func _process(_delta: float) -> void:
	super._process(_delta)
	
	if current_step == MissionStep.BACKSTAGE_SEARCH and clues_found >= TOTAL_CLUES:
		var ledger := get_node_or_null("LedgerZone")
		if ledger and not ledger.visible:
			ledger.visible = true

func on_bentley_sniff() -> void:
	if current_step == MissionStep.BACKSTAGE_SEARCH:
		var ledger := get_node_or_null("LedgerZone")
		if ledger and clues_found >= TOTAL_CLUES:
			EventBus.show_objective_marker.emit(true, ledger.global_position)
			QuestManager.set_objective("Bentley smells the real ledger! Follow the marker.", mission_id)

func interact(_player: Node) -> void:
	if current_step == MissionStep.MUSIC_PUZZLE and not music_puzzle_solved:
		start_music_puzzle()
