extends "res://src/levels/LevelBase.gd"

enum MissionStep {
	INTRO,
	LOBBY_INFILTRATE,
	FILE_ROOM_ACCESS,
	SCREENPLAY_PUZZLE,
	LEGAL_PUZZLE,
	SECURITY_COMPLICATION,
	OPTIONAL_EMOTIONAL_ROOM,
	DOCUMENTS_SECURED,
	ESCAPE,
	COMPLETE
}

enum EntryRoute {
	VISITOR,
	SNEAK,
	DELIVERY
}

var current_step: int = MissionStep.INTRO
var entry_route: int = EntryRoute.VISITOR
var has_file_room_code: bool = false
var screenplay_solved: bool = false
var legal_puzzle_solved: bool = false
var documents_collected: bool = false
var emotional_room_visited: bool = false
var security_alert_active: bool = false
var lockdown_triggered: bool = false
var guards_defeated: int = 0

var file_room_door_unlocked: bool = false
var archive_route_open: bool = false

func _ready() -> void:
	mission_id = "rewrite_room"
	objective_text = "Infiltrate Sterling Tower law firm. Mere needs creative ownership proof."
	guard_count = 0  # We'll spawn guards manually with patrol paths
	super._ready()

	MissionMutationHelper.roll(mission_id, {"partner_patrol_variant": [0, 1, 2]})
	spawn_poop_bags_at_global_positions([Vector2(180, 840), Vector2(560, 520), Vector2(920, 680)])

	_setup_entry_route()
	_setup_file_room_door()
	_setup_screenplay_puzzle()
	_setup_legal_puzzle()
	_setup_security_complication()
	_setup_emotional_room()
	_setup_exit_zones()
	_setup_interactables()
	_setup_guards()
	_setup_polaroid()
	
	_advance_step(MissionStep.INTRO)

func _setup_entry_route() -> void:
	# Check for delivery card
	var has_delivery_card := _has_card("delivery_access")
	var mere_legal_eyes := _has_card("mere_legal_eyes")
	
	if has_delivery_card:
		entry_route = EntryRoute.DELIVERY
		QuestManager.set_objective("Delivery access granted. Service entrance is clear.", mission_id)
		_move_player_to_spawn("DeliverySpawn")
	elif mere_legal_eyes:
		entry_route = EntryRoute.SNEAK
		QuestManager.set_objective("Mere's eyes see blind spots. Find the service corridor.", mission_id)
		_move_player_to_spawn("SneakSpawn")
	else:
		entry_route = EntryRoute.VISITOR
		QuestManager.set_objective("Visitor entrance. You'll need to get creative.", mission_id)

func _has_card(card_id: String) -> bool:
	var card_effects := get_node_or_null("/root/CardEffects")
	if card_effects != null and card_effects.has_method("has_card"):
		return card_effects.has_card(card_id)
	return false

func _move_player_to_spawn(spawn_name: String) -> void:
	var spawn_points := get_node_or_null("SpawnPoints")
	if spawn_points:
		var spawn := spawn_points.get_node_or_null(spawn_name) as Node2D
		if spawn and player:
			player.global_position = spawn.global_position

func _setup_file_room_door() -> void:
	var door := get_node_or_null("FileRoomDoor")
	if door:
		door.add_to_group("interactable")

func _setup_screenplay_puzzle() -> void:
	var puzzle_area := get_node_or_null("ScreenplayPuzzleArea")
	if puzzle_area:
		puzzle_area.body_entered.connect(_on_screenplay_area_entered)

func _setup_legal_puzzle() -> void:
	var puzzle_area := get_node_or_null("LegalPuzzleArea")
	if puzzle_area:
		puzzle_area.body_entered.connect(_on_legal_area_entered)

func _setup_security_complication() -> void:
	var alert_zone := get_node_or_null("SecurityAlertZone")
	if alert_zone:
		alert_zone.body_entered.connect(_on_security_alert_triggered)

func _setup_emotional_room() -> void:
	var room_trigger := get_node_or_null("EmotionalRoomTrigger")
	if room_trigger:
		room_trigger.body_entered.connect(_on_emotional_room_entered)

func _setup_exit_zones() -> void:
	var main_exit := get_node_or_null("MainExit")
	if main_exit:
		main_exit.body_entered.connect(_on_main_exit_entered)
	
	var archive_exit := get_node_or_null("ArchiveExit")
	if archive_exit:
		archive_exit.body_entered.connect(_on_archive_exit_entered)

func _setup_interactables() -> void:
	# Email terminal in reception
	var email_terminal := get_node_or_null("EmailTerminal")
	if email_terminal:
		email_terminal.add_to_group("interactable")
	
	# Vent for Bentley
	var vent := get_node_or_null("ServiceVent")
	if vent:
		vent.add_to_group("interactable")
	
	# Documents container
	var docs_container := get_node_or_null("DocumentsContainer")
	if docs_container:
		docs_container.add_to_group("interactable")

func _setup_guards() -> void:
	# Spawn guards with patrol paths based on entry route
	var guard_scene: PackedScene = load("res://scenes/characters/guard.tscn")
	if guard_scene == null:
		return
	
	var patrol_points := get_node_or_null("GuardPatrolPoints")
	
	# Reception guard
	var guard1: Node2D = guard_scene.instantiate()
	add_child(guard1)
	guard1.global_position = Vector2(400, 300)
	if patrol_points:
		var p1 := patrol_points.get_node_or_null("Patrol1") as Node2D
		var p2 := patrol_points.get_node_or_null("Patrol2") as Node2D
		if p1 and p2 and guard1.has_method("set_patrol_path"):
			guard1.set_patrol_path([p1.global_position, p2.global_position])
	
	# File room guard
	var guard2: Node2D = guard_scene.instantiate()
	add_child(guard2)
	guard2.global_position = Vector2(1100, 400)
	if patrol_points:
		var p3 := patrol_points.get_node_or_null("Patrol3") as Node2D
		var p4 := patrol_points.get_node_or_null("Patrol4") as Node2D
		if p3 and p4 and guard2.has_method("set_patrol_path"):
			guard2.set_patrol_path([p3.global_position, p4.global_position])
	
	# Security guard (alerted after documents)
	var guard3: Node2D = guard_scene.instantiate()
	guard3.name = "SecurityGuard"
	add_child(guard3)
	guard3.global_position = Vector2(800, 700)
	guard3.visible = false  # Hidden until lockdown
	
	# Connect guard death tracking
	for guard in [guard1, guard2, guard3]:
		if guard.has_signal("died"):
			guard.died.connect(_on_guard_died)

func _setup_polaroid() -> void:
	var polaroid := get_node_or_null("MissionPolaroid")
	if polaroid:
		polaroid.add_to_group("interactable")

func _advance_step(new_step: int) -> void:
	current_step = new_step
	_update_objective_for_step()
	EventBus.debug("Rewrite Room step: " + str(MissionStep.keys()[new_step]))

func _update_objective_for_step() -> void:
	match current_step:
		MissionStep.INTRO:
			if entry_route == EntryRoute.DELIVERY:
				QuestManager.set_objective("Find the file room. The code is written on the service clipboard.", mission_id)
			elif entry_route == EntryRoute.SNEAK:
				QuestManager.set_objective("Mere marked a safe path. Watch for the visual highlights.", mission_id)
			else:
				QuestManager.set_objective("Reception ahead. Maybe there's an email with the file room code?", mission_id)
		
		MissionStep.LOBBY_INFILTRATE:
			QuestManager.set_objective("Infiltrate the law firm. Find a way to the file room.", mission_id)
		
		MissionStep.FILE_ROOM_ACCESS:
			if not file_room_door_unlocked:
				QuestManager.set_objective("The file room is locked. Find the code or another way in.", mission_id)
			else:
				QuestManager.set_objective("File room accessible. Look for the screenplay structure puzzle.", mission_id)
		
		MissionStep.SCREENPLAY_PUZZLE:
			QuestManager.set_objective("Solve the screenplay sequence: Opening Image to Final Image.", mission_id)
		
		MissionStep.LEGAL_PUZZLE:
			QuestManager.set_objective("Select the correct chain-of-title document. Mere's eyes can help spot fakes.", mission_id)
		
		MissionStep.SECURITY_COMPLICATION:
			if lockdown_triggered:
				QuestManager.set_objective("ALERT! Security lockdown. Fight through or find the archive route.", mission_id)
			else:
				QuestManager.set_objective("Security alerted. Move quickly to the exit.", mission_id)
		
		MissionStep.OPTIONAL_EMOTIONAL_ROOM:
			QuestManager.set_objective("A quiet room with stationery... perhaps a moment to reflect?", mission_id)
		
		MissionStep.DOCUMENTS_SECURED:
			QuestManager.set_objective("Creative ownership documents secured. Time to leave.", mission_id)
		
		MissionStep.ESCAPE:
			if archive_route_open:
				QuestManager.set_objective("Archive route clear. Slip out through the old tunnels.", mission_id)
			else:
				QuestManager.set_objective("Exit through main entrance or defeat security.", mission_id)

func interact_with(node: Node, _player: Node) -> void:
	var node_name := node.name
	
	match node_name:
		"FileRoomDoor":
			_attempt_file_room_access()
		"EmailTerminal":
			_read_email_terminal()
		"ServiceVent":
			_send_bentley_through_vent()
		"DocumentsContainer":
			_collect_documents()
		"MissionPolaroid":
			_collect_mission_polaroid(node)
		"EmotionalDesk":
			_interact_emotional_desk()

func _attempt_file_room_access() -> void:
	if file_room_door_unlocked:
		DialogueManager.show_dialogue("The door is already unlocked.")
		return
	
	if has_file_room_code:
		file_room_door_unlocked = true
		AudioManager.play_sfx("door_unlock")
		DialogueManager.show_dialogue("Code accepted. File room unlocked.")
		_advance_step(MissionStep.FILE_ROOM_ACCESS)
	else:
		DialogueManager.show_dialogue("Locked. Requires a 4-digit code.")
		if _has_card("mere_legal_eyes"):
			DialogueManager.show_dialogue("Mere's eyes note: Check the reception email or send Bentley through the vent.")

func _read_email_terminal() -> void:
	var email_text := """FROM: facilities@sterlingtower.legal
TO: all-staff

The file room door code has been reset to [1987]. 

Please do not share with visitors.

- Building Management

P.S. The screenplay writer's proofs are in Secure Cabinet B."""
	
	DialogueManager.show_dialogue(email_text)
	has_file_room_code = true
	QuestManager.set_objective("Code acquired: 1987. The file room awaits.", mission_id)

func _send_bentley_through_vent() -> void:
	if has_file_room_code:
		DialogueManager.show_dialogue("Bentley sniffs the vent but finds nothing new.")
		return
	
	DialogueManager.show_dialogue("Bentley squeezes through the vent...")
	AudioManager.play_sfx("dog_move")
	
	# Simulate Bentley fetching the code
	await get_tree().create_timer(2.0).timeout
	
	has_file_room_code = true
	DialogueManager.show_dialogue("Bentley returns with a crumpled sticky note: '1987 - don't forget again!'")
	QuestManager.set_objective("Bentley found the code: 1987.", mission_id)

func _on_screenplay_area_entered(body: Node) -> void:
	if body.is_in_group("player") and current_step < MissionStep.SCREENPLAY_PUZZLE:
		if file_room_door_unlocked:
			_advance_step(MissionStep.SCREENPLAY_PUZZLE)
			_show_screenplay_puzzle()

func _show_screenplay_puzzle() -> void:
	var puzzle_scene := load("res://src/puzzles/ScreenplaySequencePuzzle.tscn")
	if puzzle_scene == null:
		EventBus.warn("Screenplay puzzle scene missing")
		return
	
	var puzzle: Node = puzzle_scene.instantiate()
	puzzle.puzzle_solved.connect(_on_screenplay_solved)
	get_tree().current_scene.add_child(puzzle)

func _on_screenplay_solved() -> void:
	screenplay_solved = true
	AudioManager.play_sfx("puzzle_complete")
	DialogueManager.show_dialogue("The cabinet unlocks with a satisfying click. The screenplay structure is complete.")
	_advance_step(MissionStep.LEGAL_PUZZLE)
	
	# Show legal puzzle next
	await get_tree().create_timer(1.0).timeout
	_show_legal_puzzle()

func _on_legal_area_entered(body: Node) -> void:
	if body.is_in_group("player") and screenplay_solved and not legal_puzzle_solved:
		_show_legal_puzzle()

func _show_legal_puzzle() -> void:
	var puzzle_scene := load("res://src/puzzles/LegalDocumentPuzzle.tscn")
	if puzzle_scene == null:
		EventBus.warn("Legal document puzzle scene missing")
		return
	
	var mere_eyes_active := _has_card("mere_legal_eyes")
	var puzzle: Node = puzzle_scene.instantiate()
	puzzle.mere_eyes_active = mere_eyes_active
	puzzle.puzzle_solved.connect(_on_legal_puzzle_solved)
	get_tree().current_scene.add_child(puzzle)

func _on_legal_puzzle_solved() -> void:
	legal_puzzle_solved = true
	AudioManager.play_sfx("puzzle_complete")
	DialogueManager.show_dialogue("Chain of title verified. The creative theft is documented.")
	_advance_step(MissionStep.SECURITY_COMPLICATION)
	
	# Trigger security alert after delay
	await get_tree().create_timer(3.0).timeout
	_trigger_security_alert()

func _trigger_security_alert() -> void:
	security_alert_active = true
	lockdown_triggered = true
	AudioManager.play_sfx("alarm")
	
	# Activate hidden security guard
	var security_guard := get_node_or_null("SecurityGuard")
	if security_guard:
		security_guard.visible = true
		if security_guard.has_method("set_alerted"):
			security_guard.set_alerted(true)
	
	# Open archive route as alternative
	archive_route_open = true
	var archive_blocker := get_node_or_null("ArchiveBlocker")
	if archive_blocker:
		archive_blocker.queue_free()
	
	QuestManager.set_objective("ALERT! Security lockdown. Fight or find the archive route!", mission_id)

func _on_security_alert_triggered(body: Node) -> void:
	if body.is_in_group("player") and security_alert_active:
		_trigger_security_alert()

func _collect_documents() -> void:
	if documents_collected:
		return
	
	documents_collected = true
	AudioManager.play_sfx("item_pickup")
	
	var docs_container := get_node_or_null("DocumentsContainer")
	if docs_container:
		docs_container.visible = false
	
	DialogueManager.show_dialogue("The documents are in hand. Proof of creative theft. Mere can use these.")
	_advance_step(MissionStep.DOCUMENTS_SECURED)

func _on_emotional_room_entered(body: Node) -> void:
	if body.is_in_group("player") and not emotional_room_visited:
		emotional_room_visited = true
		_advance_step(MissionStep.OPTIONAL_EMOTIONAL_ROOM)
		_show_emotional_monologue()

func _show_emotional_monologue() -> void:
	var monologue := [
		{"speaker": "Parmida", "text": "A writer's desk... untouched for years."},
		{"speaker": "Parmida", "text": "I used to have a desk like this. Where I wrote my first screenplay."},
		{"speaker": "Parmida", "text": "The coffee rings. The crumpled pages. The hope."},
		{"speaker": "Parmida", "text": "Sterling didn't just steal scripts. He stole the spaces where they were born."},
		{"speaker": "Parmida", "text": "...I'm going to get them all back. Every desk. Every dream."}
	]
	
	DialogueManager.start_simple_dialogue(monologue)
	
	# Small stat boost for emotional moment
	if player and player.has_method("heal"):
		player.heal(10)

func _interact_emotional_desk() -> void:
	DialogueManager.show_dialogue("An old leather notebook. Filled with story ideas that never got made.")

func _collect_mission_polaroid(polaroid_node: Node) -> void:
	CollectibleManager.collect_polaroid("rewrite_room_polaroid")
	AudioManager.play_sfx("collect")
	polaroid_node.queue_free()
	DialogueManager.show_dialogue("A polaroid of the original writer's guild registration. Dated 1987.")

func _on_guard_died() -> void:
	guards_defeated += 1
	if lockdown_triggered and guards_defeated >= 1:
		# Clear main exit if security guard defeated
		QuestManager.set_objective("Security clear. Main exit accessible.", mission_id)

func _on_main_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if not documents_collected:
			DialogueManager.show_dialogue("Can't leave yet. The documents are still in the file room.")
			return
		
		if lockdown_triggered and guards_defeated < 1:
			var security_guard := get_node_or_null("SecurityGuard")
			if security_guard and security_guard.visible:
				DialogueManager.show_dialogue("Security guard blocking the exit. Fight or find another way.")
				return
		
		_advance_step(MissionStep.ESCAPE)
		complete_level()

func _on_archive_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if not documents_collected:
			DialogueManager.show_dialogue("The archive route leads out, but you don't have the documents yet.")
			return
		
		if not archive_route_open:
			DialogueManager.show_dialogue("Blocked by old file cabinets. Need to find another way.")
			return
		
		_advance_step(MissionStep.ESCAPE)
		DialogueManager.show_dialogue("Slipping through the archive tunnels... old paper and escape.")
		complete_level()

func complete_level() -> void:
	if is_complete or is_failed:
		return
	
	is_complete = true
	
	# Calculate result based on performance
	var was_detected := security_alert_active
	var emotional_bonus := emotional_room_visited
	var route_used := "main" if not archive_route_open else "archive"
	
	var result := GameState.complete_mission(get_mission_id())
	
	# Add bonus rewards
	if emotional_bonus:
		result["emotional_bonus"] = true
	if not was_detected:
		result["stealth_bonus"] = true
	
	SceneManager.show_mission_result(result)
