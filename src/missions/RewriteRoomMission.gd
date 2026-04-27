# RewriteRoomMission.gd
# Mission 3: The Rewrite Room
# Location: Law firm office (reception, offices, document room)
# Objective: Recover stolen screenplay documents
# Unique mechanic: Screenwriting puzzle - multiple choice dialogue/decision puzzle

extends LevelBase

# ===== MISSION CONSTANTS =====
const MISSION_ID: String = "rewrite_room"
const REWARD_CARD: String = "stationery_queen"
const REWARD_POLAROID: String = "rewrite_room"
const REWARD_TRINKET: String = "mere_contract_pen"

# ===== MISSION PHASES =====
enum MissionPhase {
	START,
	INFILTRATE,           # Enter the law firm
	FIND_MERE,            # Locate Mere in her office
	MERE_DIALOGUE,        # Talk to Mere for legal advice
	ACCESS_DOCUMENTS,     # Get to the document room
	SCREENWRITING_PUZZLE, # Solve the puzzle
	HAS_DOCUMENT,         # Retrieved the real screenplay
	ESCAPE,               # Get out with the evidence
	COMPLETE
}
var current_phase: MissionPhase = MissionPhase.START

# ===== SPAWN POINTS =====
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var mere_spawn: Marker2D = $MereSpawn
@onready var document_room_spawn: Marker2D = $DocumentRoomSpawn
@onready var guard_spawns: Node2D = $GuardSpawns
@onready var collectible_spawns: Node2D = $CollectibleSpawns
@onready var document_interact_zone: Area2D = $DocumentInteractZone
@onready var mere_office_zone: Area2D = $MereOfficeZone
@onready var reception_desk: Polygon2D = $ReceptionDesk
@onready var exit_zone: Area2D = $ExitZone

# ===== STATE =====
var mere_npc: Area2D = null
var document_collected: bool = false
var polaroid_collected: bool = false
var trinket_collected: bool = false
var stationery_collected: Dictionary = {}  # id -> bool
var puzzle_attempts: int = 0
var puzzle_solved: bool = false
var mere_met: bool = false
var has_mere_advice: bool = false

# ===== SCREENWRITING PUZZLE DATA =====
# The player must identify the real screenplay among fakes by choosing
# correct legal arguments and plot points.
const PUZZLE_QUESTIONS: Array[Dictionary] = [
	{
		"question": "Three screenplays sit on the desk. Which one is the authentic stolen document?",
		"context": "The real screenplay was filed with the Copyright Office. The fakes have telltale errors.",
		"choices": [
			{"text": "'Love in the Time of Litigation' — has a WGA registration number", "correct": false, "hint": "WGA numbers can be faked. The Copyright Office filing is the legal proof."},
			{"text": "'The Partners' Clause' — has a Library of Congress seal and chain-of-title", "correct": true, "hint": "Correct! Chain-of-title documentation is only filed with the Copyright Office."},
			{"text": "'Objection: Romance' — has a notarized studio cover page", "correct": false, "hint": "Studio notarization means nothing without federal registration."},
			{"text": "'Sustained Hearts' — has a timestamped email from the writer", "correct": false, "hint": "Emails are evidence, not legal filing. Easily fabricated."}
		]
	},
	{
		"question": "A clause in the contract gives away the thief. Which clause is the smoking gun?",
		"context": "The real contract has an assignment clause that transfers rights to Sterling Holdings.",
		"choices": [
			{"text": "The 'Work for Hire' clause — standard in entertainment law", "correct": false, "hint": "Work for hire is common. Not evidence of theft."},
			{"text": "The 'Morality Clause' — prevents the writer from disparaging the studio", "correct": false, "hint": "A red herring. Morality clauses are standard."},
			{"text": "The 'Assignment to Sterling Holdings' clause — transfers all rights for $1", "correct": true, "hint": "Correct! A $1 assignment to Sterling Holdings is the smoking gun."},
			{"text": "The 'Sequel Option' — gives the studio first right of refusal", "correct": false, "hint": "Sequel options are normal. Not evidence of wrongdoing."}
		]
	},
	{
		"question": "The document has a watermark. What does the authentic watermark reveal?",
		"context": "Real copyright filings have a specific watermark pattern. Fakes use generic ones.",
		"choices": [
			{"text": "A faint 'CONFIDENTIAL' diagonal watermark", "correct": false, "hint": "Generic. Anyone can add this in Word."},
			{"text": "A micro-printed 'LOC-CO' that appears when held to light", "correct": true, "hint": "Correct! Library of Congress micro-printing is hard to fake."},
			{"text": "A holographic studio logo in the corner", "correct": false, "hint": "Studios add these to drafts. Not a legal document feature."},
			{"text": "A UV-reactive ink border", "correct": false, "hint": "Impressive, but not standard for copyright filings."}
		]
	}
]

var current_puzzle_question: int = 0
var puzzle_ui_active: bool = false

# ===== DIALOGUE LINES =====
const MERE_INTRO_LINES: Array[String] = [
	"You actually came. I wasn't sure you'd have the... let's call it 'attention to detail' for this.",
	"Sterling's lawyers have the real screenplay locked in the document room.",
	"Three fakes, one real. The fakes are good — they had a Hollywood prop house make them.",
	"But they don't understand copyright law. That's our edge."
]

const MERE_ADVICE_LINES: Array[String] = [
	"Listen carefully. The real document was filed with the Copyright Office.",
	"Look for chain-of-title documentation. That's the legal proof of ownership.",
	"If you have my Legal Eyes card equipped, it'll highlight the dangerous choices.",
	"And if you mess up... well, that's what the Stationery Queen card is for. Retries."
]

const MERE_SUCCESS_LINES: Array[String] = [
	"You found it. The 'Partners' Clause' — with the Sterling Holdings assignment.",
	"This is enough to prove theft in court. Or at least enough to make Sterling settle.",
	"Here. Take this. The Stationery Queen card. For when you need a second chance.",
	"And take my pen. It's signed more NDAs than treaties. Consider it a memento."
]

const MERE_FAILURE_LINES: Array[String] = [
	"That's... not the right document. You just grabbed a fake.",
	"The alarm is going to trigger in about ten seconds.",
	"Run. We'll try again later. And maybe study copyright law first?"
]

# ===== LIFECYCLE =====

func _ready() -> void:
	EventBus.debug("Rewrite Room mission loaded")
	
	# Start mission
	GameState.start_mission(MISSION_ID)
	
	# Setup zones
	if document_interact_zone:
		document_interact_zone.body_entered.connect(_on_document_zone_body_entered)
		# Hide until puzzle is accessible
		document_interact_zone.monitoring = false
	
	if mere_office_zone:
		mere_office_zone.body_entered.connect(_on_mere_office_body_entered)
	
	# Spawn entities
	_spawn_player()
	_spawn_dog()
	_spawn_enemies()
	_setup_camera()
	_spawn_mere()
	_spawn_collectibles()
	
	# Connect exit
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_zone_body_entered)
	
	# Show objective
	EventBus.show_objective_marker.emit(true, mere_spawn.global_position)
	
	# Start infiltration phase
	await get_tree().create_timer(0.5).timeout
	_start_infiltrate_phase()

# ===== SPAWNING =====

func _spawn_mere() -> void:
	mere_npc = Area2D.new()
	mere_npc.name = "MereNPC"
	mere_npc.global_position = mere_spawn.global_position
	mere_npc.add_to_group("npc")
	mere_npc.add_to_group("mere")
	
	# Collision
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 32.0
	collision.shape = shape
	mere_npc.add_child(collision)
	
	# Visual - professional blue-grey for lawyer
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-16, -32), Vector2(16, -32),
		Vector2(16, 0), Vector2(-16, 0)
	])
	sprite.color = Color(0.25, 0.35, 0.55, 1.0)
	mere_npc.add_child(sprite)
	
	# Name label
	var label := Label.new()
	label.text = "Mere"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-20, -48)
	label.add_theme_font_size_override("font_size", 12)
	mere_npc.add_child(label)
	
	# Interaction prompt
	var prompt := Label.new()
	prompt.text = "[E] Talk"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(-28, -64)
	prompt.add_theme_font_size_override("font_size", 10)
	prompt.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	prompt.name = "Prompt"
	prompt.hide()
	mere_npc.add_child(prompt)
	
	add_child(mere_npc)
	EventBus.debug("Mere spawned at " + str(mere_spawn.global_position))

func _spawn_enemies() -> void:
	if not guard_spawns:
		return
	
	var guard_scene := preload("res://scenes/characters/guard.tscn")
	var spawn_index := 0
	
	for spawn in guard_spawns.get_children():
		if spawn is Marker2D:
			var guard = guard_scene.instantiate()
			guard.global_position = spawn.global_position
			guard.name = "Guard_" + str(spawn_index)
			# Set patrol points if provided
			if spawn.has_meta("patrol_points"):
				guard.patrol_points = spawn.get_meta("patrol_points") as Array[Vector2]
			add_child(guard)
			spawn_index += 1
			EventBus.debug("Guard spawned at " + str(spawn.global_position))

func _spawn_collectibles() -> void:
	if not collectible_spawns:
		return
	
	var spawn_index := 0
	for spawn in collectible_spawns.get_children():
		if spawn is Marker2D:
			match spawn_index:
				0: _spawn_polaroid(spawn.global_position)
				1: _spawn_trinket(spawn.global_position)
				2: _spawn_stationery(spawn.global_position, "rewrite_memo")
				3: _spawn_stationery(spawn.global_position, "redlined_contract")
			spawn_index += 1

func _spawn_polaroid(pos: Vector2) -> void:
	var polaroid := Area2D.new()
	polaroid.name = "Polaroid_RewriteRoom"
	polaroid.global_position = pos
	polaroid.add_to_group("collectible")
	polaroid.add_to_group("polaroid")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	polaroid.add_child(collision)
	
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
	trinket.name = "Trinket_Pen"
	trinket.global_position = pos
	trinket.add_to_group("collectible")
	trinket.add_to_group("trinket")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	trinket.add_child(collision)
	
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-4, -12), Vector2(4, -12),
		Vector2(4, 12), Vector2(-4, 12)
	])
	sprite.color = Color(0.2, 0.2, 0.3, 1.0)  # Dark pen
	trinket.add_child(sprite)
	
	# Gold nib
	var nib := Polygon2D.new()
	nib.polygon = PackedVector2Array([
		Vector2(-2, 12), Vector2(2, 12),
		Vector2(0, 16)
	])
	nib.color = Color(1.0, 0.84, 0.0, 1.0)
	trinket.add_child(nib)
	
	trinket.body_entered.connect(_on_trinket_body_entered)
	add_child(trinket)

func _spawn_stationery(pos: Vector2, id: String) -> void:
	var item := Area2D.new()
	item.name = "Stationery_" + id
	item.global_position = pos
	item.add_to_group("collectible")
	item.add_to_group("stationery")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	item.add_child(collision)
	
	# Paper visual
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-10, -12), Vector2(10, -12),
		Vector2(10, 12), Vector2(-10, 12)
	])
	sprite.color = Color(0.98, 0.95, 0.9, 1.0)
	item.add_child(sprite)
	
	# Lines to look like paper
	var lines := Line2D.new()
	lines.points = PackedVector2Array([
		Vector2(-8, -4), Vector2(8, -4),
		Vector2(-8, 2), Vector2(8, 2),
		Vector2(-8, 8), Vector2(4, 8)
	])
	lines.width = 1
	lines.default_color = Color(0.6, 0.6, 0.7, 0.5)
	item.add_child(lines)
	
	item.body_entered.connect(func(body): _on_stationery_body_entered(body, id))
	add_child(item)

# ===== PHASE TRANSITIONS =====

func _start_infiltrate_phase() -> void:
	current_phase = MissionPhase.INFILTRATE
	EventBus.debug("Phase: INFILTRATE")
	EventBus.quest_started.emit(MISSION_ID, "Infiltrate the law firm and find Mere")

func _start_find_mere_phase() -> void:
	current_phase = MissionPhase.FIND_MERE
	EventBus.debug("Phase: FIND_MERE")
	EventBus.quest_updated.emit("Find Mere in her office for legal advice")
	EventBus.show_objective_marker.emit(true, mere_spawn.global_position)

func _start_mere_dialogue() -> void:
	current_phase = MissionPhase.MERE_DIALOGUE
	EventBus.debug("Phase: MERE_DIALOGUE")
	
	# Show prompt
	var prompt = mere_npc.get_node_or_null("Prompt")
	if prompt:
		prompt.hide()
	
	for line in MERE_INTRO_LINES:
		EventBus.dialogue_started.emit("Mere", line)
		await get_tree().create_timer(2.5).timeout
	
	EventBus.dialogue_ended.emit()
	
	# Mark Mere as met
	mere_met = true
	DialogueManager.set_dialogue_flag("met_mere_mission", true)
	
	_start_access_documents_phase()

func _start_access_documents_phase() -> void:
	current_phase = MissionPhase.ACCESS_DOCUMENTS
	EventBus.debug("Phase: ACCESS_DOCUMENTS")
	EventBus.quest_updated.emit("Access the document room and find the real screenplay")
	EventBus.show_objective_marker.emit(true, document_room_spawn.global_position)
	
	# Enable document interaction
	if document_interact_zone:
		document_interact_zone.monitoring = true

func _start_screenwriting_puzzle() -> void:
	current_phase = MissionPhase.SCREENWRITING_PUZZLE
	EventBus.debug("Phase: SCREENWRITING_PUZZLE")
	EventBus.quest_updated.emit("Solve the screenwriting puzzle to identify the real document")
	
	current_puzzle_question = 0
	puzzle_attempts += 1
	_show_puzzle_question()

func _show_puzzle_question() -> void:
	if current_puzzle_question >= PUZZLE_QUESTIONS.size():
		# All questions answered correctly
		_puzzle_complete()
		return
	
	puzzle_ui_active = true
	var q = PUZZLE_QUESTIONS[current_puzzle_question]
	
	# Emit puzzle UI event
	EventBus.puzzle_started.emit(q["question"], q["context"], q["choices"])
	EventBus.debug("Puzzle question " + str(current_puzzle_question + 1) + "/" + str(PUZZLE_QUESTIONS.size()))

func submit_puzzle_answer(choice_index: int) -> void:
	if not puzzle_ui_active:
		return
	
	var q = PUZZLE_QUESTIONS[current_puzzle_question]
	if choice_index < 0 or choice_index >= q["choices"].size():
		return
	
	var choice = q["choices"][choice_index]
	var has_legal_eyes = GameState.has_card("mere_legal_eyes") and "mere_legal_eyes" in GameState.selected_cards
	var has_stationery_queen = GameState.has_card("stationery_queen") and "stationery_queen" in GameState.selected_cards
	
	if choice["correct"]:
		# Correct answer
		EventBus.puzzle_feedback.emit(true, choice.get("hint", "Correct!"))
		await get_tree().create_timer(1.5).timeout
		current_puzzle_question += 1
		_show_puzzle_question()
	else:
		# Wrong answer
		var feedback = choice.get("hint", "Incorrect.")
		
		# Legal Eyes card highlights dangerous choices
		if has_legal_eyes:
			feedback += " [Legal Eyes: This choice has legal vulnerabilities.]"
		
		EventBus.puzzle_feedback.emit(false, feedback)
		await get_tree().create_timer(2.0).timeout
		
		# Stationery Queen card allows retry
		if has_stationery_queen and puzzle_attempts == 1:
			EventBus.puzzle_feedback.emit(false, "Stationery Queen activated! You get one retry.")
			puzzle_attempts += 1
			current_puzzle_question = 0
			await get_tree().create_timer(1.5).timeout
			_show_puzzle_question()
			return
		
		_puzzle_failed()

func _puzzle_complete() -> void:
	puzzle_ui_active = false
	puzzle_solved = true
	EventBus.puzzle_ended.emit(true)
	EventBus.debug("Puzzle solved!")
	
	# Brief delay then show success dialogue
	await get_tree().create_timer(0.5).timeout
	
	for line in MERE_SUCCESS_LINES:
		EventBus.dialogue_started.emit("Mere", line)
		await get_tree().create_timer(2.5).timeout
	
	EventBus.dialogue_ended.emit()
	_document_found()

func _puzzle_failed() -> void:
	puzzle_ui_active = false
	EventBus.puzzle_ended.emit(false)
	EventBus.debug("Puzzle failed!")
	
	for line in MERE_FAILURE_LINES:
		EventBus.dialogue_started.emit("Mere", line)
		await get_tree().create_timer(2.5).timeout
	
	EventBus.dialogue_ended.emit()
	
	# Trigger alarm - guards go to alert
	_alert_all_guards()
	
	# Player can still retry by re-interacting with documents
	current_phase = MissionPhase.ACCESS_DOCUMENTS
	EventBus.quest_updated.emit("The alarm triggered! Try again when it's safe.")

func _alert_all_guards() -> void:
	for guard in get_tree().get_nodes_in_group("enemy"):
		if guard.has_method("_change_state"):
			guard._change_state(2)  # ALERT state enum value
	EventBus.debug("All guards alerted!")

func _document_found() -> void:
	document_collected = true
	current_phase = MissionPhase.HAS_DOCUMENT
	EventBus.debug("Document collected!")
	EventBus.objective_completed.emit("find_screenplay")
	EventBus.quest_updated.emit("Escape with the screenplay evidence!")
	
	# Disable document zone
	if document_interact_zone:
		document_interact_zone.monitoring = false
	
	# Update objective to exit
	if exit_zone:
		EventBus.show_objective_marker.emit(true, exit_zone.global_position)

# ===== ZONE HANDLERS =====

func _on_mere_office_body_entered(body: Node) -> void:
	if body.is_in_group("player") and current_phase == MissionPhase.FIND_MERE:
		_start_mere_dialogue()

func _on_document_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player") and current_phase == MissionPhase.ACCESS_DOCUMENTS:
		_start_screenwriting_puzzle()

func _on_exit_zone_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if current_phase == MissionPhase.HAS_DOCUMENT:
		_mere_outro_dialogue()
	elif current_phase == MissionPhase.ACCESS_DOCUMENTS:
		EventBus.dialogue_started.emit("Mere", "You can't leave yet. The screenplay is still in the document room.")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()
	elif current_phase == MissionPhase.FIND_MERE or current_phase == MissionPhase.INFILTRATE:
		EventBus.dialogue_started.emit("Mere", "Running already? At least talk to me first.")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()

# ===== COLLECTIBLE HANDLERS =====

func _on_polaroid_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not polaroid_collected:
		polaroid_collected = true
		GameState.add_polaroid(REWARD_POLAROID)
		EventBus.debug("Polaroid collected: Rewrite Room")
		var node = get_node_or_null("Polaroid_RewriteRoom")
		if node:
			node.queue_free()

func _on_trinket_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not trinket_collected:
		trinket_collected = true
		GameState.add_trinket(REWARD_TRINKET)
		EventBus.debug("Trinket collected: Mere's Pen")
		var node = get_node_or_null("Trinket_Pen")
		if node:
			node.queue_free()

func _on_stationery_body_entered(body: Node, id: String) -> void:
	if body.is_in_group("player") and not stationery_collected.get(id, false):
		stationery_collected[id] = true
		GameState.add_stationery(id)
		EventBus.debug("Stationery collected: " + id)
		var node = get_node_or_null("Stationery_" + id)
		if node:
			node.queue_free()

# ===== DIALOGUE & COMPLETION =====

func _mere_outro_dialogue() -> void:
	current_phase = MissionPhase.COMPLETE
	
	var outro_lines = [
		"Good work. Sterling's going to hate this.",
		"With this evidence, we can prove the screenplay was stolen.",
		"Come on. Let's get back to the hideout before they realize what happened."
	]
	
	for line in outro_lines:
		EventBus.dialogue_started.emit("Mere", line)
		await get_tree().create_timer(2.5).timeout
	
	EventBus.dialogue_ended.emit()
	complete_level()

# Override completion for mission rewards
func complete_level() -> void:
	if is_complete:
		return
	
	is_complete = true
	EventBus.debug("Rewrite Room completed!")
	
	# Complete mission in GameState
	GameState.complete_mission(MISSION_ID)
	
	# Unlock reward card
	if REWARD_CARD != "" and REWARD_CARD not in GameState.unlocked_cards:
		GameState.unlock_card(REWARD_CARD)
		EventBus.debug("Unlocked card: " + REWARD_CARD)
	
	# Set friend helped
	GameState.set_friend_helped("mere", REWARD_CARD)
	EventBus.friend_helped.emit("mere")
	
	# Give intel reward
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
	
	# Save game
	SaveManager.auto_save()
	
	# Return to hideout after delay
	await get_tree().create_timer(3.0).timeout
	SceneManager.change_to_scene("hideout")

# Mission failure (player died or caught)
func fail_mission(reason: String = "You were caught!") -> void:
	EventBus.debug("Rewrite Room failed: " + reason)
	GameState.fail_mission(MISSION_ID)
	
	var partial_progress := 0.0
	if document_collected:
		partial_progress = 0.5
	elif puzzle_solved:
		partial_progress = 0.4
	elif mere_met:
		partial_progress = 0.2
	elif polaroid_collected or trinket_collected:
		partial_progress = 0.1
	
	EventBus.show_failure_screen.emit("Mission Failed - " + reason, partial_progress)
	
	await get_tree().create_timer(3.0).timeout
	SceneManager.change_to_scene("hideout")

# Cleanup override
func cleanup() -> void:
	super.cleanup()
	EventBus.debug("Rewrite Room cleanup complete")

# ===== INPUT HANDLING FOR PUZZLE =====

func _input(event: InputEvent) -> void:
	if not puzzle_ui_active:
		return
	
	if event.is_action_pressed("interact"):
		# In a real implementation, this would be handled by a puzzle UI scene
		# For now, we rely on the puzzle UI to call submit_puzzle_answer()
		pass

# ===== PUBLIC API FOR PUZZLE UI =====

func get_current_puzzle_question() -> Dictionary:
	if current_puzzle_question >= PUZZLE_QUESTIONS.size():
		return {}
	return PUZZLE_QUESTIONS[current_puzzle_question]

func get_puzzle_progress() -> Dictionary:
	return {
		"current": current_puzzle_question,
		"total": PUZZLE_QUESTIONS.size(),
		"attempts": puzzle_attempts,
		"has_legal_eyes": GameState.has_card("mere_legal_eyes") and "mere_legal_eyes" in GameState.selected_cards,
		"has_stationery_queen": GameState.has_card("stationery_queen") and "stationery_queen" in GameState.selected_cards
	}
