# Hideout.gd - V2 Update
# Hideout hub for Untitled Heist RPG

extends Node2D

# ===== NODE REFERENCES =====

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var crew_member: Area2D = $CrewMember
@onready var heist_start_zone: Area2D = $HeistStartZone

# V2 interactables (optional — hideout scene may or may not have these nodes)
@onready var mission_board: Area2D = $MissionBoard if has_node("MissionBoard") else null
@onready var card_table: Area2D = $CardTable if has_node("CardTable") else null
@onready var polaroid_wall: Area2D = $PolaroidWall if has_node("PolaroidWall") else null
@onready var jake_npc: Node2D = $JakeNPC if has_node("JakeNPC") else null
@onready var bentley_bed: Area2D = $BentleyBed if has_node("BentleyBed") else null

# ===== STATE =====

var _player_instance: Node2D = null
var _dog_instance: Node2D = null
var _nearby_interactable: String = ""  # "mission_board", "card_table", "polaroid_wall", "bentley_bed", "jake"

# ===== LIFECYCLE =====

func _ready() -> void:
	# Spawn player and dog
	_spawn_player()
	_spawn_dog()
	
	# Connect legacy signals
	crew_member.body_entered.connect(_on_crew_member_entered)
	heist_start_zone.body_entered.connect(_on_heist_start_entered)
	
	# Connect to EventBus
	EventBus.return_to_hideout.connect(_on_return_to_hideout)
	EventBus.show_mission_select.connect(_on_show_mission_select)
	
	# Setup V2 interactables
	_setup_v2_interactables()
	
	# Update hideout state based on progression
	_update_hideout_state()
	
	EventBus.debug("Hideout V2 loaded")

func _physics_process(_delta: float) -> void:
	# Check proximity to V2 interactables
	_check_proximity()

func _input(event: InputEvent) -> void:
	"""Handle input"""
	if event.is_action_pressed("interact"):
		# Check V2 interactables first
		if _nearby_interactable != "":
			_interact_with(_nearby_interactable)
			return
		
		# Legacy: Check if player is near crew member
		if _player_instance:
			var player_pos = _player_instance.position
			var crew_pos = crew_member.position
			if player_pos.distance_to(crew_pos) < 50:
				_on_crew_member_entered(_player_instance)
	
	if event.is_action_pressed("ui_cancel"):
		# Escape to show mission select (temporary fallback)
		_on_show_mission_select()

# ===== SPAWNING =====

func _spawn_player() -> void:
	"""Spawn player at spawn point"""
	var player_scene = load("res://scenes/characters/player.tscn")
	if player_scene:
		_player_instance = player_scene.instantiate()
		_player_instance.position = player_spawn.position
		add_child(_player_instance)
		EventBus.debug("Player spawned in hideout")
	else:
		EventBus.debug("Failed to load player scene")

func _spawn_dog() -> void:
	"""Spawn dog companion"""
	var dog_scene = load("res://scenes/characters/dog.tscn")
	if dog_scene:
		_dog_instance = dog_scene.instantiate()
		_dog_instance.position = player_spawn.position + Vector2(50, 0)
		add_child(_dog_instance)
		EventBus.debug("Dog spawned in hideout")
	else:
		EventBus.debug("Failed to load dog scene")

# ===== LEGACY SIGNAL HANDLERS =====

func _on_crew_member_entered(body: Node2D) -> void:
	"""Crew member interaction (legacy)"""
	if body == _player_instance:
		EventBus.debug("Player interacting with crew member")
		var dialogue_manager = get_node("/root/DialogueManager")
		if dialogue_manager:
			dialogue_manager.start_dialogue("jake_intro")

func _on_heist_start_entered(body: Node2D) -> void:
	"""Heist start zone entered (legacy)"""
	if body == _player_instance:
		EventBus.debug("Player entered heist start zone")
		_on_show_mission_select()

func _on_return_to_hideout() -> void:
	"""Return to hideout from mission or menu"""
	EventBus.debug("Returning to hideout")
	_update_hideout_state()

func _on_show_mission_select() -> void:
	"""Show mission select menu"""
	EventBus.debug("Showing mission select from hideout")
	
	var mission_select = get_node_or_null("/root/MissionSelect")
	if not mission_select:
		var scene = load("res://scenes/ui/MissionSelect.tscn")
		if scene:
			mission_select = scene.instantiate()
			get_tree().root.add_child(mission_select)
			mission_select.name = "MissionSelect"
	
	if mission_select:
		mission_select.show_menu()
	else:
		EventBus.debug("Failed to show MissionSelect")

# ===== V2 INTERACTABLES =====

func _setup_v2_interactables() -> void:
	"""Connect signals for V2 interactable areas."""
	if mission_board:
		mission_board.body_entered.connect(_on_mission_board_entered)
		mission_board.body_exited.connect(_on_mission_board_exited)
	
	if card_table:
		card_table.body_entered.connect(_on_card_table_entered)
		card_table.body_exited.connect(_on_card_table_exited)
	
	if polaroid_wall:
		polaroid_wall.body_entered.connect(_on_polaroid_wall_entered)
		polaroid_wall.body_exited.connect(_on_polaroid_wall_exited)
	
	if bentley_bed:
		bentley_bed.body_entered.connect(_on_bentley_bed_entered)
		bentley_bed.body_exited.connect(_on_bentley_bed_exited)

func _check_proximity() -> void:
	"""Check which interactable the player is closest to."""
	if not _player_instance:
		return
	
	var player_pos := _player_instance.position
	var closest := ""
	var closest_dist := 80.0
	
	# Check Jake NPC
	if jake_npc:
		var dist := player_pos.distance_to(jake_npc.position)
		if dist < closest_dist:
			closest = "jake"
			closest_dist = dist
	
	# Check mission board
	if mission_board:
		var dist := player_pos.distance_to(mission_board.position)
		if dist < closest_dist:
			closest = "mission_board"
			closest_dist = dist
	
	# Check card table
	if card_table:
		var dist := player_pos.distance_to(card_table.position)
		if dist < closest_dist:
			closest = "card_table"
			closest_dist = dist
	
	# Check polaroid wall
	if polaroid_wall:
		var dist := player_pos.distance_to(polaroid_wall.position)
		if dist < closest_dist:
			closest = "polaroid_wall"
			closest_dist = dist
	
	# Check bentley bed
	if bentley_bed:
		var dist := player_pos.distance_to(bentley_bed.position)
		if dist < closest_dist:
			closest = "bentley_bed"
			closest_dist = dist
	
	_nearby_interactable = closest

func _interact_with(interactable: String) -> void:
	"""Interact with a named interactable."""
	EventBus.debug("Hideout: Interacting with " + interactable)
	
	match interactable:
		"mission_board":
			_on_show_mission_select()
		"card_table":
			_show_scheme_card_viewer()
		"polaroid_wall":
			_show_polaroid_wall()
		"jake":
			_interact_jake()
		"bentley_bed":
			_interact_bentley_bed()

# ===== MISSION BOARD =====

func _on_mission_board_entered(body: Node2D) -> void:
	if body == _player_instance:
		EventBus.debug("Player near mission board")

func _on_mission_board_exited(body: Node2D) -> void:
	if body == _player_instance:
		EventBus.debug("Player left mission board")

# ===== CARD TABLE =====

func _on_card_table_entered(body: Node2D) -> void:
	if body == _player_instance:
		EventBus.debug("Player near card table")

func _on_card_table_exited(body: Node2D) -> void:
	if body == _player_instance:
		EventBus.debug("Player left card table")

func _show_scheme_card_viewer() -> void:
	"""Show SchemeCardMenu in viewer mode (no mission selection)."""
	EventBus.debug("Showing Scheme Card viewer")
	
	var scheme_menu = get_node_or_null("/root/SchemeCardMenu")
	if not scheme_menu:
		var scene = load("res://scenes/ui/SchemeCardMenu.tscn")
		if scene:
			scheme_menu = scene.instantiate()
			get_tree().root.add_child(scheme_menu)
			scheme_menu.name = "SchemeCardMenu"
	
	if scheme_menu:
		# Show menu without a mission ID — this puts it in "viewer" mode
		scheme_menu.show_menu("")
		
		# Disable confirm button since we're just viewing
		if scheme_menu.has_node("MenuContainer/VBoxContainer/ButtonContainer/ConfirmButton"):
			var confirm_btn = scheme_menu.get_node("MenuContainer/VBoxContainer/ButtonContainer/ConfirmButton")
			confirm_btn.text = "Close"
			confirm_btn.disabled = false
			# Disconnect old signal and connect close
			if confirm_btn.pressed.is_connected(scheme_menu._on_confirm_pressed):
				confirm_btn.pressed.disconnect(scheme_menu._on_confirm_pressed)
			confirm_btn.pressed.connect(_on_card_viewer_close.bind(scheme_menu))
	else:
		EventBus.debug("Failed to show SchemeCardMenu")

func _on_card_viewer_close(scheme_menu: Control) -> void:
	"""Close the card viewer."""
	scheme_menu.hide_menu()
	
	# Restore confirm button
	if scheme_menu.has_node("MenuContainer/VBoxContainer/ButtonContainer/ConfirmButton"):
		var confirm_btn = scheme_menu.get_node("MenuContainer/VBoxContainer/ButtonContainer/ConfirmButton")
		confirm_btn.text = "Confirm"
		if confirm_btn.pressed.is_connected(_on_card_viewer_close):
			confirm_btn.pressed.disconnect(_on_card_viewer_close)
		confirm_btn.pressed.connect(scheme_menu._on_confirm_pressed)

# ===== POLAROID WALL =====

func _on_polaroid_wall_entered(body: Node2D) -> void:
	if body == _player_instance:
		EventBus.debug("Player near polaroid wall")

func _on_polaroid_wall_exited(body: Node2D) -> void:
	if body == _player_instance:
		EventBus.debug("Player left polaroid wall")

func _show_polaroid_wall() -> void:
	"""Show the polaroid wall display."""
	EventBus.debug("Showing polaroid wall")
	
	var collectible_manager := get_node_or_null("/root/CollectibleManager")
	if not collectible_manager:
		EventBus.debug("CollectibleManager not found")
		return
	
	var polaroids := collectible_manager.get_polaroid_wall_data()
	EventBus.debug("Polaroid wall: " + str(polaroids.size()) + " polaroids collected")
	
	# TODO: Instantiate a PolaroidWall UI scene when available
	# For now, show a simple dialogue with the count
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		var count := polaroids.size()
		if count == 0:
			dialogue_manager.start_dialogue("polaroid_wall_empty")
		else:
			# Add a temporary dialogue for the wall
			dialogue_manager.add_dialogue("polaroid_wall_view", {
				"speaker": "Narrator",
				"text": "The wall shows " + str(count) + " captured moment(s). Each one a story.",
				"choices": [
					{"text": "Close", "next": ""}
				]
			})
			dialogue_manager.start_dialogue("polaroid_wall_view")

# ===== JAKE CORNER =====

func _interact_jake() -> void:
	"""Interact with Jake in his corner."""
	EventBus.debug("Interacting with Jake")
	
	if jake_npc and jake_npc.has_method("interact"):
		jake_npc.interact()
	else:
		# Fallback to DialogueManager
		var dialogue_manager := get_node_or_null("/root/DialogueManager")
		if dialogue_manager:
			dialogue_manager.start_dialogue("jake_intro")

# ===== BENTLEY BED =====

func _on_bentley_bed_entered(body: Node2D) -> void:
	if body == _player_instance:
		EventBus.debug("Player near Bentley's bed")

func _on_bentley_bed_exited(body: Node2D) -> void:
	if body == _player_instance:
		EventBus.debug("Player left Bentley's bed")

func _interact_bentley_bed() -> void:
	"""Interact with Bentley's bed."""
	EventBus.debug("Interacting with Bentley's bed")
	
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		# Add temporary bentley bed dialogue
		dialogue_manager.add_dialogue("bentley_bed", {
			"speaker": "Bentley",
			"text": "Bentley looks at you with the expression of a dog who knows exactly how much you messed up on the last heist.",
			"choices": [
				{"text": "Pet Bentley", "next": "bentley_pet"},
				{"text": "Leave", "next": ""}
			]
		})
		dialogue_manager.add_dialogue("bentley_pet", {
			"speaker": "Bentley",
			"text": "He grumbles approvingly. His tail thumps twice. That's basically a five-star review.",
			"choices": [
				{"text": "Good boy", "next": ""}
			]
		})
		dialogue_manager.start_dialogue("bentley_bed")

# ===== HIDEOUT STATE =====

func _update_hideout_state() -> void:
	"""Update hideout based on game state."""
	var game_state := get_node_or_null("/root/GameState")
	if not game_state:
		return
	
	# Update Jake NPC dialogue based on progression
	if jake_npc and jake_npc.has_method("set_dialogue_id"):
		if game_state.get_failure_count("taco_bell_drop") >= 3:
			jake_npc.set_dialogue_id("jake_many_failures")
		elif game_state.completed_missions.size() > 0:
			jake_npc.set_dialogue_id("jake_post_mission")
	
	# Update polaroid wall visibility
	if polaroid_wall:
		var collectible_manager := get_node_or_null("/root/CollectibleManager")
		if collectible_manager:
			var count := collectible_manager.get_collected_count(CollectibleManager.CollectibleType.POLAROID)
			polaroid_wall.visible = count > 0 or game_state.completed_missions.size() > 0
	
	EventBus.debug("Hideout state updated")