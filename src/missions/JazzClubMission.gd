# JazzClubMission.gd
# Mission 2: The Velvet Paw Jazz Club
# Steal the Sterling blackmail ledger

extends LevelBase

# Mission state
enum MissionPhase {
	START,
	ENTER_CLUB,
	TALK_YORDANO,
	FIND_LEDGER,
	PUZZLE_SOLVED,
	HAS_LEDGER,
	ESCAPE,
	COMPLETE
}
var current_phase: MissionPhase = MissionPhase.START

# Mission data
const MISSION_ID: String = "velvet_paw_jazz_club"
const REWARD_CARD: String = "yordano_bass_drop"
const REWARD_POLAROID: String = "jazz_club"
const REWARD_TRINKET: String = "yordanos_drumstick"

# Music puzzle sequence (1-4 = note buttons)
const PUZZLE_SEQUENCE: Array[int] = [2, 4, 1, 3]  # D, G, C, E
const PUZZLE_HINT: String = "The bass line goes D-G-C-E. That's the key."

# Spawn points
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var yordano_spawn: Marker2D = $YordanoSpawn
@onready var ledger_spawn: Marker2D = $LedgerSpawn
@onready var bouncer_spawns: Node = $BouncerSpawns
@onready var bruiser_spawns: Node = $BruiserSpawns
@onready var collectible_spawns: Node = $CollectibleSpawns
@onready var music_puzzle_area: Area2D = $MusicPuzzleArea
@onready var ledger_pickup_zone: Area2D = $LedgerPickupZone
@onready var backstage_exit_zone: Area2D = $BackstageExitZone
@onready var puzzle_ui: Control = $MusicPuzzleUI

# NPC and interactables
var yordano_npc: Area2D = null
var ledger_collected: bool = false
var polaroid_collected: bool = false
var trinket_collected: bool = false
var yordano_helped: bool = false
var puzzle_solved: bool = false

# Puzzle state
var current_sequence: Array[int] = []
var puzzle_attempts: int = 0
var max_attempts: int = 3
var can_retry: bool = true  # Stationery Queen card effect

# Dialogue lines
const YORDANO_INTRO_LINES: Array[String] = [
	"Hey. You look like you're not here for the music.",
	"Sterling's ledger? Yeah, I know where it is.",
	"VIP room. But the door's locked with a music puzzle.",
	"The sequence is D-G-C-E. Don't ask how I know.",
	"Get the ledger and get out. I'll cover your exit if things go loud."
]

const YORDANO_HELP_LINES: Array[String] = [
	"Need help? The puzzle plays a bass line.",
	"D, then G, then C, then E. Four notes.",
	"If you mess up, try again. You've got Bentley with you, right?"
]

const YORDANO_ESCAPE_LINES: Array[String] = [
	"Go! Backstage exit! I'll hold them off!",
	"And hey — thanks for not making this boring."
]

func _ready() -> void:
	EventBus.debug("Velvet Paw Jazz Club mission loaded")
	
	# Start mission
	GameState.start_mission(MISSION_ID)
	
	# Check for Stationery Queen card (allows infinite retries)
	can_retry = GameState.has_card("stationery_queen")
	if can_retry:
		max_attempts = 99
		EventBus.debug("Stationery Queen active - unlimited puzzle retries")
	
	# Setup puzzle area
	if music_puzzle_area:
		music_puzzle_area.body_entered.connect(_on_puzzle_area_entered)
		music_puzzle_area.body_exited.connect(_on_puzzle_area_exited)
	
	# Setup ledger pickup
	if ledger_pickup_zone:
		ledger_pickup_zone.body_entered.connect(_on_ledger_zone_body_entered)
		ledger_pickup_zone.monitoring = puzzle_solved
	
	# Setup backstage exit
	if backstage_exit_zone:
		backstage_exit_zone.body_entered.connect(_on_backstage_exit_entered)
	
	# Setup puzzle UI
	if puzzle_ui:
		puzzle_ui.visible = false
		_setup_puzzle_ui()
	
	# Base spawns
	_spawn_player()
	_spawn_dog()
	_spawn_enemies()
	_setup_camera()
	
	# Spawn Yordano
	_spawn_yordano()
	
	# Spawn collectibles
	_spawn_collectibles()
	
	# Connect main exit (disabled until ledger collected)
	if exit_zone:
		exit_zone.body_entered.disconnect(_on_exit_zone_body_entered)
		exit_zone.body_entered.connect(_on_main_exit_entered)
	
	# Show initial objective
	EventBus.show_objective_marker.emit(true, yordano_spawn.global_position)
	
	# Start phase
	await get_tree().create_timer(0.5).timeout
	_start_enter_club_phase()

# ===== SPAWNS =====

func _spawn_yordano() -> void:
	yordano_npc = Area2D.new()
	yordano_npc.name = "YordanoNPC"
	yordano_npc.global_position = yordano_spawn.global_position
	yordano_npc.add_to_group("npc")
	yordano_npc.add_to_group("yordano")
	
	# Collision
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 36.0
	collision.shape = shape
	yordano_npc.add_child(collision)
	
	# Visual
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-14, -36), Vector2(14, -36),
		Vector2(14, 0), Vector2(-14, 0)
	])
	sprite.color = Color(0.15, 0.35, 0.6, 1.0)  # Blue-purple for Yordano
	yordano_npc.add_child(sprite)
	
	# Name label
	var label := Label.new()
	label.text = "Yordano"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-24, -52)
	label.add_theme_font_size_override("font_size", 12)
	yordano_npc.add_child(label)
	
	# Interaction trigger
	var interact_zone := Area2D.new()
	interact_zone.name = "InteractionZone"
	var interact_collision := CollisionShape2D.new()
	var interact_shape := CircleShape2D.new()
	interact_shape.radius = 50.0
	interact_collision.shape = interact_shape
	interact_zone.add_child(interact_collision)
	yordano_npc.add_child(interact_zone)
	
	interact_zone.body_entered.connect(_on_yordano_area_entered)
	
	add_child(yordano_npc)
	EventBus.debug("Yordano spawned at bar")

func _spawn_enemies() -> void:
	# Spawn bouncers (Guards with patrol)
	if bouncer_spawns:
		var guard_scene := preload("res://scenes/characters/guard.tscn")
		var spawn_index := 0
		for spawn in bouncer_spawns.get_children():
			if spawn is Marker2D:
				var guard = guard_scene.instantiate()
				guard.global_position = spawn.global_position
				guard.name = "Bouncer_" + str(spawn_index)
				# Bouncers are tougher than normal guards
				guard.max_health = 75
				guard.health = 75
				guard.attack_damage = 12
				guard.speed = 120
				guard.chase_speed = 200
				add_child(guard)
				spawn_index += 1
	
	# Spawn bruisers
	if bruiser_spawns:
		var bruiser_scene := preload("res://scenes/characters/bruiser.tscn")
		var spawn_index := 0
		for spawn in bruiser_spawns.get_children():
			if spawn is Marker2D:
				var bruiser = bruiser_scene.instantiate()
				bruiser.global_position = spawn.global_position
				bruiser.name = "Bruiser_" + str(spawn_index)
				add_child(bruiser)
				spawn_index += 1

func _spawn_collectibles() -> void:
	if not collectible_spawns:
		return
	
	var spawn_index := 0
	for spawn in collectible_spawns.get_children():
		if spawn is Marker2D:
			if spawn_index == 0:
				_spawn_polaroid(spawn.global_position)
			elif spawn_index == 1:
				_spawn_trinket(spawn.global_position)
			spawn_index += 1

func _spawn_polaroid(pos: Vector2) -> void:
	var polaroid := Area2D.new()
	polaroid.name = "Polaroid_JazzClub"
	polaroid.global_position = pos
	polaroid.add_to_group("collectible")
	polaroid.add_to_group("polaroid")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	polaroid.add_child(collision)
	
	# Polaroid visual
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-12, -16), Vector2(12, -16),
		Vector2(12, 16), Vector2(-12, 16)
	])
	sprite.color = Color(0.95, 0.95, 0.95, 1.0)
	polaroid.add_child(sprite)
	
	var border := Line2D.new()
	border.points = PackedVector2Array([
		Vector2(-12, -16), Vector2(12, -16),
		Vector2(12, 16), Vector2(-12, 16),
		Vector2(-12, -16)
	])
	border.width = 2
	border.default_color = Color(0.3, 0.3, 0.3, 1.0)
	polaroid.add_child(border)
	
	polaroid.body_entered.connect(_on_polaroid_body_entered)
	add_child(polaroid)

func _spawn_trinket(pos: Vector2) -> void:
	var trinket := Area2D.new()
	trinket.name = "Trinket_Drumstick"
	trinket.global_position = pos
	trinket.add_to_group("collectible")
	trinket.add_to_group("trinket")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	trinket.add_child(collision)
	
	# Drumstick visual - brown stick shape
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-4, -16), Vector2(4, -16),
		Vector2(6, 8), Vector2(-6, 8)
	])
	sprite.color = Color(0.55, 0.27, 0.07, 1.0)  # Wood color
	trinket.add_child(sprite)
	
	# Tip
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(-6, 8), Vector2(6, 8),
		Vector2(8, 14), Vector2(-8, 14)
	])
	tip.color = Color(0.9, 0.9, 0.85, 1.0)
	trinket.add_child(tip)
	
	trinket.body_entered.connect(_on_trinket_body_entered)
	add_child(trinket)

# ===== PHASES =====

func _start_enter_club_phase() -> void:
	current_phase = MissionPhase.ENTER_CLUB
	EventBus.debug("Phase: ENTER_CLUB")
	EventBus.quest_started.emit(MISSION_ID, "Infiltrate the Velvet Paw Jazz Club")

func _start_talk_yordano_phase() -> void:
	current_phase = MissionPhase.TALK_YORDANO
	EventBus.debug("Phase: TALK_YORDANO")
	EventBus.quest_updated.emit("Talk to Yordano at the bar")
	EventBus.show_objective_marker.emit(true, yordano_spawn.global_position)

func _start_find_ledger_phase() -> void:
	current_phase = MissionPhase.FIND_LEDGER
	EventBus.debug("Phase: FIND_LEDGER")
	EventBus.quest_updated.emit("Solve the music puzzle to access the VIP room")
	if music_puzzle_area:
		EventBus.show_objective_marker.emit(true, music_puzzle_area.global_position)

func _start_has_ledger_phase() -> void:
	ledger_collected = true
	current_phase = MissionPhase.HAS_LEDGER
	EventBus.debug("Phase: HAS_LEDGER")
	EventBus.objective_completed.emit("find_ledger")
	EventBus.quest_updated.emit("Escape through the backstage exit")
	if backstage_exit_zone:
		EventBus.show_objective_marker.emit(true, backstage_exit_zone.global_position)

func _start_escape_phase() -> void:
	current_phase = MissionPhase.ESCAPE
	EventBus.debug("Phase: ESCAPE")
	
	# Yordano helps if friend favor earned (or if this is first time helping him)
	if not yordano_helped:
		yordano_helped = true
		GameState.set_friend_helped("yordano", REWARD_CARD)
		EventBus.friend_helped.emit("yordano")
		
		# Yordano covers escape - spawn a distraction or help fight
		_yordano_help_escape()
	
	# Start Yordano escape dialogue
	for line in YORDANO_ESCAPE_LINES:
		EventBus.dialogue_started.emit("Yordano", line)
		await get_tree().create_timer(2.0).timeout
	EventBus.dialogue_ended.emit()

func _yordano_help_escape() -> void:
	EventBus.debug("Yordano is helping with the escape!")
	# Yordano's help: stuns nearby enemies briefly
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.global_position.distance_to(yordano_spawn.global_position) < 300:
			if enemy.has_method("take_damage"):
				enemy.take_damage(15, null)
			EventBus.debug("Yordano stunned " + enemy.name)
	
	# Unlock Yordano's card
	GameState.unlock_card(REWARD_CARD)
	EventBus.debug("Unlocked card: " + REWARD_CARD)

# ===== YORDANO INTERACTION =====

func _on_yordano_area_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if current_phase == MissionPhase.ENTER_CLUB or current_phase == MissionPhase.TALK_YORDANO:
		_start_yordano_dialogue()
	elif current_phase == MissionPhase.FIND_LEDGER and not puzzle_solved:
		_start_yordano_help_dialogue()

func _start_yordano_dialogue() -> void:
	current_phase = MissionPhase.TALK_YORDANO
	
	for line in YORDANO_INTRO_LINES:
		EventBus.dialogue_started.emit("Yordano", line)
		await get_tree().create_timer(2.0).timeout
	EventBus.dialogue_ended.emit()
	
	_start_find_ledger_phase()

func _start_yordano_help_dialogue() -> void:
	for line in YORDANO_HELP_LINES:
		EventBus.dialogue_started.emit("Yordano", line)
		await get_tree().create_timer(2.0).timeout
	EventBus.dialogue_ended.emit()

# ===== MUSIC PUZZLE =====

var _player_in_puzzle_area: bool = false

func _on_puzzle_area_entered(body: Node) -> void:
	if body.is_in_group("player") and current_phase == MissionPhase.FIND_LEDGER and not puzzle_solved:
		_player_in_puzzle_area = true
		_show_puzzle_ui()

func _on_puzzle_area_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_puzzle_area = false
		_hide_puzzle_ui()

func _setup_puzzle_ui() -> void:
	if puzzle_ui == null:
		return
	
	# Clear existing
	for child in puzzle_ui.get_children():
		child.queue_free()
	
	# Background panel
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-160, -100)
	panel.size = Vector2(320, 200)
	puzzle_ui.add_child(panel)
	
	# Title
	var title := Label.new()
	title.text = "Music Puzzle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 10)
	title.size = Vector2(320, 30)
	title.add_theme_font_size_override("font_size", 18)
	puzzle_ui.add_child(title)
	
	# Instructions
	var instr := Label.new()
	instr.text = "Play the bass line: D-G-C-E"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.position = Vector2(0, 45)
	instr.size = Vector2(320, 20)
	puzzle_ui.add_child(instr)
	
	# Note buttons
	var note_names := ["C", "D", "E", "G"]
	var note_colors := [Color(1, 0.3, 0.3), Color(0.3, 1, 0.3), Color(0.3, 0.3, 1), Color(1, 0.8, 0.3)]
	
	for i in range(4):
		var btn := Button.new()
		btn.text = note_names[i]
		btn.position = Vector2(40 + i * 70, 90)
		btn.size = Vector2(50, 50)
		btn.add_theme_font_size_override("font_size", 16)
		
		# Style override for color
		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = note_colors[i]
		btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover := StyleBoxFlat.new()
		style_hover.bg_color = note_colors[i].lightened(0.3)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		var style_pressed := StyleBoxFlat.new()
		style_pressed.bg_color = note_colors[i].darkened(0.3)
		btn.add_theme_stylebox_override("pressed", style_pressed)
		
		btn.pressed.connect(_on_note_button_pressed.bind(i + 1))
		puzzle_ui.add_child(btn)
	
	# Status label
	var status := Label.new()
	status.name = "PuzzleStatus"
	status.text = "Attempts: 0 / " + str(max_attempts)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.position = Vector2(0, 155)
	status.size = Vector2(320, 20)
	puzzle_ui.add_child(status)
	
	# Close hint
	var close_hint := Label.new()
	close_hint.text = "Press E or walk away to close"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.position = Vector2(0, 175)
	close_hint.size = Vector2(320, 20)
	close_hint.add_theme_font_size_override("font_size", 10)
	close_hint.modulate = Color(0.7, 0.7, 0.7)
	puzzle_ui.add_child(close_hint)

func _show_puzzle_ui() -> void:
	if puzzle_ui:
		puzzle_ui.visible = true
		_update_puzzle_status()
		EventBus.debug("Music puzzle UI shown")

func _hide_puzzle_ui() -> void:
	if puzzle_ui:
		puzzle_ui.visible = false
		EventBus.debug("Music puzzle UI hidden")

func _on_note_button_pressed(note_index: int) -> void:
	if puzzle_solved:
		return
	
	current_sequence.append(note_index)
	EventBus.debug("Puzzle note pressed: " + str(note_index))
	
	# Visual feedback - flash the button (handled by Godot's pressed state)
	# Audio feedback placeholder
	
	# Check sequence
	var seq_len := current_sequence.size()
	if seq_len > PUZZLE_SEQUENCE.size():
		# Too many notes - fail
		_puzzle_fail()
		return
	
	# Check each entered note so far
	for i in range(seq_len):
		if current_sequence[i] != PUZZLE_SEQUENCE[i]:
			_puzzle_fail()
			return
	
	# If complete and correct
	if seq_len == PUZZLE_SEQUENCE.size():
		_puzzle_solved()

func _puzzle_fail() -> void:
	puzzle_attempts += 1
	current_sequence.clear()
	EventBus.debug("Puzzle failed! Attempt " + str(puzzle_attempts) + "/" + str(max_attempts))
	
	_update_puzzle_status()
	
	if puzzle_attempts >= max_attempts and not can_retry:
		EventBus.dialogue_started.emit("System", "Puzzle locked! Need Stationery Queen card to retry.")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()
		_hide_puzzle_ui()
	else:
		# Show fail feedback
		var status = puzzle_ui.get_node_or_null("PuzzleStatus")
		if status:
			status.text = "Wrong sequence! Try again..."
			status.modulate = Color(1, 0.3, 0.3)
			await get_tree().create_timer(1.0).timeout
			status.modulate = Color(1, 1, 1)
			_update_puzzle_status()

func _puzzle_solved() -> void:
	puzzle_solved = true
	EventBus.debug("Music puzzle solved!")
	
	# Unlock ledger pickup
	if ledger_pickup_zone:
		ledger_pickup_zone.monitoring = true
	
	# Update UI
	var status = puzzle_ui.get_node_or_null("PuzzleStatus")
	if status:
		status.text = "Correct! VIP room unlocked!"
		status.modulate = Color(0.3, 1, 0.3)
	
	# Delay then hide
	await get_tree().create_timer(1.5).timeout
	_hide_puzzle_ui()
	
	# Update objective
	EventBus.quest_updated.emit("The ledger is in the VIP room. Grab it!")
	if ledger_spawn:
		EventBus.show_objective_marker.emit(true, ledger_spawn.global_position)
	
	current_phase = MissionPhase.PUZZLE_SOLVED

func _update_puzzle_status() -> void:
	var status = puzzle_ui.get_node_or_null("PuzzleStatus")
	if status:
		if can_retry or max_attempts >= 99:
			status.text = "Attempts: " + str(puzzle_attempts) + " (unlimited)"
		else:
			status.text = "Attempts: " + str(puzzle_attempts) + " / " + str(max_attempts)

# ===== LEDGER =====

func _on_ledger_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player") and puzzle_solved and not ledger_collected:
		_ledger_collected()

func _ledger_collected() -> void:
	ledger_collected = true
	EventBus.debug("Ledger collected!")
	EventBus.objective_completed.emit("collect_ledger")
	
	# Hide ledger visual
	var ledger_visual = get_node_or_null("LedgerVisual")
	if ledger_visual:
		ledger_visual.queue_free()
	
	# Disable pickup zone
	if ledger_pickup_zone:
		ledger_pickup_zone.monitoring = false
	
	_start_has_ledger_phase()

# ===== EXITS =====

func _on_backstage_exit_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if ledger_collected:
		_start_escape_phase()
		await get_tree().create_timer(1.0).timeout
		complete_level()
	else:
		EventBus.dialogue_started.emit("System", "You need the ledger first!")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()

func _on_main_exit_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if ledger_collected:
		EventBus.dialogue_started.emit("System", "Use the backstage exit!")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()
	else:
		EventBus.dialogue_started.emit("System", "Can't leave without the ledger!")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()

# ===== COLLECTIBLES =====

func _on_polaroid_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not polaroid_collected:
		polaroid_collected = true
		GameState.add_polaroid(REWARD_POLAROID)
		EventBus.debug("Polaroid collected: Jazz Club")
		var polaroid = get_node_or_null("Polaroid_JazzClub")
		if polaroid:
			polaroid.queue_free()

func _on_trinket_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not trinket_collected:
		trinket_collected = true
		GameState.add_trinket(REWARD_TRINKET)
		EventBus.debug("Trinket collected: Yordano's Drumstick")
		var trinket = get_node_or_null("Trinket_Drumstick")
		if trinket:
			trinket.queue_free()

# ===== COMPLETION =====

func complete_level() -> void:
	if is_complete:
		return
	
	is_complete = true
	EventBus.debug("Velvet Paw Jazz Club completed!")
	
	GameState.complete_mission(MISSION_ID)
	
	# Unlock reward card
	if REWARD_CARD != "":
		GameState.unlock_card(REWARD_CARD)
		EventBus.debug("Unlocked card: " + REWARD_CARD)
	
	# Set friend helped
	GameState.set_friend_helped("yordano", REWARD_CARD)
	EventBus.friend_helped.emit("yordano")
	
	# Give intel
	var intel_reward := MissionData.get_intel_reward(MISSION_ID)
	if intel_reward > 0:
		GameState.add_intel_points(intel_reward)
	
	# Show mission result
	var rewards := {
		"card": REWARD_CARD,
		"polaroid": REWARD_POLAROID if polaroid_collected else "",
		"trinket": REWARD_TRINKET if trinket_collected else "",
		"intel": intel_reward
	}
	EventBus.show_mission_result.emit(true, rewards)
	
	SaveManager.auto_save()
	
	await get_tree().create_timer(3.0).timeout
	SceneManager.change_to_scene("hideout")

func fail_mission() -> void:
	EventBus.debug("Velvet Paw Jazz Club failed")
	GameState.fail_mission(MISSION_ID)
	
	var partial_progress := 0.0
	if ledger_collected:
		partial_progress = 0.6
	elif puzzle_solved:
		partial_progress = 0.4
	elif polaroid_collected or trinket_collected:
		partial_progress = 0.2
	
	EventBus.show_failure_screen.emit("Mission Failed - You were caught!", partial_progress)
	
	await get_tree().create_timer(3.0).timeout
	SceneManager.change_to_scene("hideout")

# ===== CLEANUP =====

func cleanup() -> void:
	super.cleanup()
	EventBus.debug("Velvet Paw Jazz Club cleanup complete")

# Input handling for puzzle close
func _input(event: InputEvent) -> void:
	if puzzle_ui and puzzle_ui.visible and event.is_action_pressed("interact"):
		# Check if mouse is NOT over a button
		var mouse_pos = puzzle_ui.get_global_mouse_position()
		var over_button = false
		for child in puzzle_ui.get_children():
			if child is Button and child.get_global_rect().has_point(mouse_pos):
				over_button = true
				break
		if not over_button:
			_hide_puzzle_ui()
