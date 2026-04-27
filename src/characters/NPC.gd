# NPC.gd
# Reusable NPC base for Untitled Heist RPG
# Supports dialogue via DialogueManager V2 (JSON-based)
# Shows interaction indicator when player is near

extends CharacterBody2D

# ===== EXPORTS =====
@export var npc_id: String = ""          # Must match a dialogue JSON character_id
@export var npc_name: String = ""
@export var portrait_path: String = ""
@export var interaction_radius: float = 60.0
@export var start_node_id: String = ""   # Override start node (empty = auto-detect)
@export var face_player: bool = true

# ===== NODE REFERENCES =====
@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var interaction_indicator: Label = $InteractionIndicator
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_collision: CollisionShape2D = $InteractionZone/CollisionShape2D

# ===== STATE =====
var _player_in_range: bool = false
var _player_ref: Node2D = null
var _is_interacting: bool = false

# ===== LIFECYCLE =====

func _ready() -> void:
	if npc_name == "" and npc_id != "":
		npc_name = npc_id.capitalize()
	
	_setup_interaction_zone()
	_setup_indicator()
	
	# Connect signals
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	
	# Connect to dialogue ended to reset interaction state
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	EventBus.debug("NPC ready: " + npc_name + " (id: " + npc_id + ")")

func _physics_process(_delta: float) -> void:
	if face_player and _player_ref != null and _player_in_range:
		_face_target(_player_ref.position)

func _input(event: InputEvent) -> void:
	if not _player_in_range or _is_interacting:
		return
	
	if event.is_action_pressed("interact"):
		_interact()

# ===== PUBLIC API =====

func interact() -> void:
	_interact()

func is_interacting() -> bool:
	return _is_interacting

# ===== INTERNAL =====

func _setup_interaction_zone() -> void:
	if interaction_collision == null:
		return
	var shape := CircleShape2D.new()
	shape.radius = interaction_radius
	interaction_collision.shape = shape

func _setup_indicator() -> void:
	if interaction_indicator == null:
		return
	interaction_indicator.text = "E"
	interaction_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_indicator.add_theme_font_size_override("font_size", 20)
	interaction_indicator.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	interaction_indicator.position = Vector2(-10, -interaction_radius - 20)
	interaction_indicator.hide()

func _interact() -> void:
	if _is_interacting:
		return
	
	_is_interacting = true
	_hide_indicator()
	
	# Use DialogueManager V2 — start dialogue by character_id
	if npc_id != "" and DialogueManager.has_dialogue(npc_id):
		var start_node := start_node_id
		if start_node == "":
			start_node = DialogueManager.get_npc_greeting(npc_id)
		DialogueManager.start_dialogue(npc_id, start_node)
		# Mark as met
		DialogueManager.set_dialogue_flag("met_" + npc_id, true)
		return
	
	# No dialogue configured
	EventBus.debug("NPC " + npc_name + " has no dialogue configured")
	_is_interacting = false

func _face_target(target_pos: Vector2) -> void:
	if sprite == null:
		return
	var direction := target_pos - position
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

func _show_indicator() -> void:
	if interaction_indicator != null:
		interaction_indicator.show()

func _hide_indicator() -> void:
	if interaction_indicator != null:
		interaction_indicator.hide()

# ===== SIGNAL HANDLERS =====

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_in_range = true
		_player_ref = body
		if not _is_interacting:
			_show_indicator()
		EventBus.debug("NPC " + npc_name + ": player entered range")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_in_range = false
		_player_ref = null
		_hide_indicator()
		EventBus.debug("NPC " + npc_name + ": player left range")

func _on_dialogue_ended() -> void:
	_is_interacting = false
	if _player_in_range:
		_show_indicator()
