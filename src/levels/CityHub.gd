# CityHub.gd
# Walkable city hub connecting mission contacts

extends Node2D

# ===== NODE REFERENCES =====

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var hideout_entrance: Area2D = $HideoutEntrance
@onready var mission_triggers: Dictionary = {}  # mission_id: Area2D

# Contact NPCs
@onready var louis_npc: Area2D = $LouisNPC if has_node("LouisNPC") else null
@onready var yordano_npc: Area2D = $YordanoNPC if has_node("YordanoNPC") else null
@onready var mere_npc: Area2D = $MereNPC if has_node("MereNPC") else null
@onready var dom_npc: Area2D = $DomNPC if has_node("DomNPC") else null
@onready var jake_npc: Area2D = $JakeNPC if has_node("JakeNPC") else null

var _player_instance: Node2D = null
var _dog_instance: Node2D = null
var _nearby_interactable: String = ""

# ===== LIFECYCLE =====

func _ready() -> void:
	# Spawn player and dog
	_spawn_player()
	_spawn_dog()
	
	# Connect signals
	hideout_entrance.body_entered.connect(_on_hideout_entrance_entered)
	
	# Setup mission triggers
	_setup_mission_triggers()
	
	# Setup NPC interactions
	_setup_npcs()
	
	# Connect to EventBus
	EventBus.return_to_city.connect(_on_return_to_city)
	EventBus.debug("CityHub loaded")

func _physics_process(_delta: float) -> void:
	# Check proximity to interactables
	_check_proximity()

func _input(event: InputEvent) -> void:
	"""Handle input"""
	if event.is_action_pressed("interact"):
		if _nearby_interactable != "":
			_interact_with(_nearby_interactable)
			return
	
	if event.is_action_pressed("ui_cancel"):
		# Return to hideout
		EventBus.return_to_hideout.emit()

# ===== SPAWNING =====

func _spawn_player() -> void:
	"""Spawn player at spawn point"""
	var player_scene = load("res://scenes/characters/player.tscn")
	if player_scene:
		_player_instance = player_scene.instantiate()
		_player_instance.position = player_spawn.position
		add_child(_player_instance)
		EventBus.debug("Player spawned in city hub")
	else:
		EventBus.debug("Failed to load player scene")

func _spawn_dog() -> void:
	"""Spawn dog companion"""
	var dog_scene = load("res://scenes/characters/dog.tscn")
	if dog_scene:
		_dog_instance = dog_scene.instantiate()
		_dog_instance.position = player_spawn.position + Vector2(50, 0)
		add_child(_dog_instance)
		EventBus.debug("Dog spawned in city hub")
	else:
		EventBus.debug("Failed to load dog scene")

# ===== MISSION TRIGGERS =====

func _setup_mission_triggers() -> void:
	"""Find and connect all mission trigger areas"""
	# Look for mission trigger nodes
	for child in get_children():
		if child is Area2D and child.name.begins_with("MissionTrigger_"):
			var mission_id = child.name.replace("MissionTrigger_", "").to_lower()
			mission_triggers[mission_id] = child
			child.body_entered.connect(_on_mission_trigger_entered.bind(mission_id))
			EventBus.debug("Connected mission trigger: " + mission_id)

func _on_mission_trigger_entered(body: Node2D, mission_id: String) -> void:
	"""Player entered mission trigger area"""
	if body == _player_instance:
		EventBus.debug("Player entered mission trigger: " + mission_id)
		
		# Check if mission is available
		var game_state = get_node("/root/GameState")
		if game_state and game_state.is_mission_available(mission_id):
			EventBus.show_mission_select.emit(mission_id)
		else:
			EventBus.debug("Mission not available: " + mission_id)

# ===== NPC INTERACTIONS =====

func _setup_npcs() -> void:
	"""Connect NPC interaction signals"""
	var npcs = {
		"louis": louis_npc,
		"yordano": yordano_npc,
		"mere": mere_npc,
		"dom": dom_npc,
		"jake": jake_npc
	}
	
	for npc_name, npc_node in npcs:
		if npc_node:
			npc_node.body_entered.connect(_on_npc_entered.bind(npc_name))
			npc_node.body_exited.connect(_on_npc_exited.bind(npc_name))

func _on_npc_entered(body: Node2D, npc_name: String) -> void:
	"""Player entered NPC area"""
	if body == _player_instance:
		_nearby_interactable = npc_name
		EventBus.show_interaction_prompt.emit("Talk to " + npc_name.capitalize())

func _on_npc_exited(body: Node2D, npc_name: String) -> void:
	"""Player exited NPC area"""
	if body == _player_instance and _nearby_interactable == npc_name:
		_nearby_interactable = ""
		EventBus.hide_interaction_prompt.emit()

# ===== INTERACTIONS =====

func _check_proximity() -> void:
	"""Check what the player is near"""
	if not _player_instance:
		return
	
	# Check hideout entrance
	if _player_instance.position.distance_to(hideout_entrance.position) < 50:
		if _nearby_interactable != "hideout":
			_nearby_interactable = "hideout"
			EventBus.show_interaction_prompt.emit("Enter Hideout")
		return
	
	# Check NPCs
	var npc_positions = {
		"louis": louis_npc.position if louis_npc else Vector2.ZERO,
		"yordano": yordano_npc.position if yordano_npc else Vector2.ZERO,
		"mere": mere_npc.position if mere_npc else Vector2.ZERO,
		"dom": dom_npc.position if dom_npc else Vector2.ZERO,
		"jake": jake_npc.position if jake_npc else Vector2.ZERO
	}
	
	for npc_name, npc_pos in npc_positions:
		if npc_pos != Vector2.ZERO:
			if _player_instance.position.distance_to(npc_pos) < 60:
				if _nearby_interactable != npc_name:
					_nearby_interactable = npc_name
					EventBus.show_interaction_prompt.emit("Talk to " + npc_name.capitalize())
				return
	
	# Not near anything
	if _nearby_interactable != "":
		_nearby_interactable = ""
		EventBus.hide_interaction_prompt.emit()

func _interact_with(interactable: String) -> void:
	"""Handle interaction with nearby object"""
	match interactable:
		"hideout":
			EventBus.return_to_hideout.emit()
		
		"louis", "yordano", "mere", "dom", "jake":
			_start_npc_dialogue(interactable)
		
		_:
			EventBus.debug("Unknown interactable: " + interactable)

func _start_npc_dialogue(npc_name: String) -> void:
	"""Start dialogue with NPC"""
	var dialogue_id = "city_" + npc_name
	EventBus.start_dialogue.emit(dialogue_id, npc_name)

# ===== SIGNAL HANDLERS =====

func _on_hideout_entrance_entered(body: Node2D) -> void:
	"""Player entered hideout entrance"""
	if body == _player_instance:
		EventBus.return_to_hideout.emit()

func _on_return_to_city() -> void:
	"""Return to city from hideout or mission"""
	# This would be called when returning from hideout
	# Player would already be spawned
	EventBus.debug("Returned to city hub")

# ===== DEBUG =====

func _process(_delta: float) -> void:
	# Debug: Show nearby interactable
	if Engine.is_editor_hint():
		if _nearby_interactable != "":
			print("Nearby: " + _nearby_interactable)