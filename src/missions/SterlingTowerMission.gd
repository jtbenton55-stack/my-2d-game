# SterlingTowerMission.gd
# Mission 5: The Sterling Tower Heist — FINAL MISSION
# Multi-floor corporate tower infiltration with friend-favor system and boss fight.

extends LevelBase

# ============================================================================
# CONSTANTS & CONFIG
# ============================================================================
const MISSION_ID: String = "sterling_tower_heist"
const REWARD_POLAROID: String = "sterling_tower"
const REWARD_TRINKET: String = "sterling_syndicate_badge"

# Tower layout — 3 floors, each a distinct zone
enum TowerFloor {
	LOBBY,
	OFFICES,
	PENTHOUSE
}

# Mission phases
enum MissionPhase {
	START,
	INFILTRATE_LOBBY,
	ASCEND_OFFICES,
	REACH_PENTHOUSE,
	BOSS_FIGHT,
	BOSS_DEFEATED,
	COLLECT_EVIDENCE,
	ESCAPE,
	COMPLETE
}

# Friend-favor bypass types
enum BypassType {
	NONE,
	LOUIS_DELIVERY_ENTRANCE,      # Louis → delivery entrance (skip lobby guards)
	MERE_LEGAL_DEPARTMENT,        # Mere → legal dept keycard (skip office puzzles)
	YORDANO_JAZZ_DISTRACTION,     # Yordano → jazz distraction (disable some cameras)
	DOM_GETAWAY_VEHICLE,          # Dom → getaway van waiting (escape route)
	JAKE_RESIDENT_ORDERS          # Jake → resident access (elevator override)
}

# ============================================================================
# STATE
# ============================================================================
var current_floor: TowerFloor = TowerFloor.LOBBY
var current_phase: MissionPhase = MissionPhase.START
var evidence_collected: bool = false
var polaroid_collected: bool = false
var trinket_collected: bool = false
var boss_fight_started: bool = false

# Friend favors active in this run
var active_bypasses: Array[BypassType] = []
var friend_help_messages: Array[String] = []

# Security state
var cameras_disabled: bool = false
var laser_grids_active: bool = true
var keycard_doors_unlocked: bool = false
var guards_alerted: bool = false

# Spawn references (set in _ready from scene tree)
@onready var lobby_spawn: Marker2D = $LobbySpawn
@onready var office_spawn: Marker2D = $OfficeSpawn
@onready var penthouse_spawn: Marker2D = $PenthouseSpawn
@onready var boss_spawn: Marker2D = $BossSpawn
@onready var evidence_spawn: Marker2D = $EvidenceSpawn
@onready var escape_spawn: Marker2D = $EscapeSpawn

# Security systems
@onready var security_cameras: Node = $SecurityCameras
@onready var laser_grids: Node = $LaserGrids
@onready var keycard_doors: Node = $KeycardDoors
@onready var elevator_zone: Area2D = $ElevatorZone
@onready var penthouse_entrance: Area2D = $PenthouseEntrance
@onready var evidence_zone: Area2D = $EvidenceZone
@onready var escape_zone: Area2D = $EscapeZone

# Floor transition triggers
@onready var lobby_to_office_trigger: Area2D = $LobbyToOfficeTrigger
@onready var office_to_penthouse_trigger: Area2D = $OfficeToPenthouseTrigger

# Enemy spawns
@onready var lobby_guard_spawns: Node = $LobbyGuardSpawns
@onready var office_guard_spawns: Node = $OfficeGuardSpawns
@onready var penthouse_guard_spawns: Node = $PenthouseGuardSpawns
@onready var boss_room_spawn: Marker2D = $BossRoomSpawn

# Visual feedback nodes
@onready var friend_notification: Label = $UI/FriendNotification
@onready var floor_label: Label = $UI/FloorLabel
@onready var objective_label: Label = $UI/ObjectiveLabel
@onready var boss_health_bar: ProgressBar = $UI/BossHealthBar

# Boss reference
var victor_sterling: CharacterBody2D = null

# ============================================================================
# DIALOGUE LINES
# ============================================================================
const INTRO_LINES: Array[String] = [
	"This is it. Sterling Tower.",
	"Victor Sterling's corporate fortress.",
	"Every friend I've helped is counting on me.",
	"Time to end this."
]

const BOSS_INTRO_LINES: Array[String] = [
	"Victor Sterling: So you're the one causing all this trouble.",
	"Victor Sterling: You think you can just walk into MY tower?",
	"Victor Sterling: I've built an empire. You? You're nothing.",
	"Victor Sterling: Security! Deal with this pest!"
]

const BOSS_PHASE2_LINES: Array[String] = [
	"Victor Sterling: Impossible! How did you get past my security?",
	"Victor Sterling: No matter. I'll handle you myself."
]

const BOSS_PHASE3_LINES: Array[String] = [
	"Victor Sterling: This isn't over! The Sterling Syndicate will—",
	"Victor Sterling: No... NO!"
]

const EVIDENCE_LINES: Array[String] = [
	"The evidence. Everything.",
	"Blackmail ledgers, money laundering records, names...",
	"This will take down the whole Syndicate."
]

const ESCAPE_LINES: Array[String] = [
	"Alarm's blaring. Time to move!",
	"The evidence is secure. Now get out!"
]

# ============================================================================
# FRIEND-FAVOR CONFIG
# ============================================================================
const FRIEND_BYPASS_CONFIG: Dictionary = {
	"louis": {
		"bypass": BypassType.LOUIS_DELIVERY_ENTRANCE,
		"message": "Louis's delivery route lets you sneak in through the service entrance!",
		"effect": "skip_lobby_guards"
	},
	"mere": {
		"bypass": BypassType.MERE_LEGAL_DEPARTMENT,
		"message": "Mere's legal contacts provided a keycard to the executive offices!",
		"effect": "unlock_office_doors"
	},
	"yordano": {
		"bypass": BypassType.YORDANO_JAZZ_DISTRACTION,
		"message": "Yordano's jazz distraction is drawing security to the club!",
		"effect": "disable_cameras"
	},
	"dom": {
		"bypass": BypassType.DOM_GETAWAY_VEHICLE,
		"message": "Dom's getaway van is waiting at the south exit!",
		"effect": "fast_escape"
	},
	"jake": {
		"bypass": BypassType.JAKE_RESIDENT_ORDERS,
		"message": "Jake's resident credentials override the elevator locks!",
		"effect": "elevator_access"
	}
}

# ============================================================================
# READY & INITIALIZATION
# ============================================================================
func _ready() -> void:
	EventBus.debug("=== STERLING TOWER HEIST LOADED ===")
	
	# Start mission
	GameState.start_mission(MISSION_ID)
	
	# Evaluate friend favors BEFORE spawning anything
	_evaluate_friend_favors()
	
	# Spawn player, dog, setup camera
	_spawn_player()
	_spawn_dog()
	_setup_camera()
	
	# Connect zone triggers
	_connect_zone_triggers()
	
	# Spawn security systems
	_spawn_security_systems()
	
	# Spawn enemies based on floor + friend favors
	_spawn_floor_enemies()
	
	# Spawn collectibles
	_spawn_collectibles()
	
	# Setup UI
	_setup_ui()
	
	# Start intro sequence
	_start_intro_sequence()

# Evaluate which friend favors are active
func _evaluate_friend_favors() -> void:
	active_bypasses.clear()
	friend_help_messages.clear()
	
	for friend_id in FRIEND_BYPASS_CONFIG.keys():
		if GameState.is_friend_helped(friend_id):
			var config = FRIEND_BYPASS_CONFIG[friend_id]
			active_bypasses.append(config["bypass"])
			friend_help_messages.append(config["message"])
			EventBus.debug("Friend favor active: " + friend_id)
			_apply_bypass_effect(config["effect"])
	
	var helped_count := active_bypasses.size()
	EventBus.debug("Total friend favors active: " + str(helped_count))
	
	# Show friend help notification
	if helped_count > 0:
		_show_friend_notification("Friends helping: " + str(helped_count))

func _apply_bypass_effect(effect: String) -> void:
	match effect:
		"skip_lobby_guards":
			# Fewer guards in lobby
			EventBus.debug("Bypass: Lobby guards reduced")
		"unlock_office_doors":
			keycard_doors_unlocked = true
			EventBus.debug("Bypass: Office doors pre-unlocked")
		"disable_cameras":
			cameras_disabled = true
			EventBus.debug("Bypass: Cameras pre-disabled")
		"fast_escape":
			EventBus.debug("Bypass: Fast escape route available")
		"elevator_access":
			EventBus.debug("Bypass: Elevator access granted")

func _connect_zone_triggers() -> void:
	if lobby_to_office_trigger:
		lobby_to_office_trigger.body_entered.connect(_on_lobby_to_office_entered)
	if office_to_penthouse_trigger:
		office_to_penthouse_trigger.body_entered.connect(_on_office_to_penthouse_entered)
	if penthouse_entrance:
		penthouse_entrance.body_entered.connect(_on_penthouse_entered)
	if evidence_zone:
		evidence_zone.body_entered.connect(_on_evidence_entered)
	if escape_zone:
		escape_zone.body_entered.connect(_on_escape_entered)
	if elevator_zone:
		elevator_zone.body_entered.connect(_on_elevator_entered)

func _setup_ui() -> void:
	if friend_notification:
		friend_notification.visible = false
	if floor_label:
		floor_label.text = "FLOOR: LOBBY"
	if objective_label:
		objective_label.text = "Objective: Infiltrate Sterling Tower"
	if boss_health_bar:
		boss_health_bar.visible = false
		boss_health_bar.max_value = 100
		boss_health_bar.value = 100

# ============================================================================
# INTRO SEQUENCE
# ============================================================================
func _start_intro_sequence() -> void:
	current_phase = MissionPhase.START
	
	# Show intro dialogue
	for line in INTRO_LINES:
		EventBus.dialogue_started.emit("Jake", line)
		await get_tree().create_timer(2.0).timeout
	
	# Show friend help messages
	for msg in friend_help_messages:
		EventBus.dialogue_started.emit("Friend", msg)
		_show_friend_notification(msg)
		await get_tree().create_timer(2.5).timeout
	
	EventBus.dialogue_ended.emit()
	_start_infiltrate_phase()

func _start_infiltrate_phase() -> void:
	current_phase = MissionPhase.INFILTRATE_LOBBY
	current_floor = TowerFloor.LOBBY
	_update_floor_label("LOBBY")
	_update_objective("Find a way to the executive offices")
	EventBus.quest_started.emit(MISSION_ID, "Infiltrate Sterling Tower and reach the penthouse")
	
	# If Louis bypass active, player starts near service entrance
	if BypassType.LOUIS_DELIVERY_ENTRANCE in active_bypasses:
		if player:
			player.global_position = $ServiceEntranceSpawn.global_position if has_node("ServiceEntranceSpawn") else lobby_spawn.global_position
			EventBus.debug("Player spawned at service entrance (Louis bypass)")

# ============================================================================
# FLOOR TRANSITIONS
# ============================================================================
func _on_lobby_to_office_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_phase != MissionPhase.INFILTRATE_LOBBY:
		return
	
	EventBus.debug("Transition: Lobby -> Offices")
	_transition_to_offices()

func _transition_to_offices() -> void:
	current_floor = TowerFloor.OFFICES
	current_phase = MissionPhase.ASCEND_OFFICES
	_update_floor_label("EXECUTIVE OFFICES")
	_update_objective("Reach the penthouse elevator")
	
	# Move player to office spawn
	if player:
		player.global_position = office_spawn.global_position
	if dog:
		dog.global_position = office_spawn.global_position + Vector2(40, 0)
	
	# Spawn office enemies
	_spawn_office_enemies()
	
	# If Mere bypass active, doors are already unlocked
	if BypassType.MERE_LEGAL_DEPARTMENT in active_bypasses:
		_unlock_all_keycard_doors()
		EventBus.dialogue_started.emit("Mere", "The legal department keycard works! The doors are open.")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()
	
	EventBus.quest_updated.emit("Ascend to the penthouse")

func _on_office_to_penthouse_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_phase != MissionPhase.ASCEND_OFFICES:
		return
	
	EventBus.debug("Transition: Offices -> Penthouse")
	_transition_to_penthouse()

func _transition_to_penthouse() -> void:
	current_floor = TowerFloor.PENTHOUSE
	current_phase = MissionPhase.REACH_PENTHOUSE
	_update_floor_label("VICTOR'S PENTHOUSE")
	_update_objective("Confront Victor Sterling")
	
	# Move player to penthouse spawn
	if player:
		player.global_position = penthouse_spawn.global_position
	if dog:
		dog.global_position = penthouse_spawn.global_position + Vector2(40, 0)
	
	# Spawn penthouse guards
	_spawn_penthouse_enemies()
	
	EventBus.quest_updated.emit("Confront Victor Sterling")

func _on_penthouse_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_phase != MissionPhase.REACH_PENTHOUSE:
		return
	if boss_fight_started:
		return
	
	# Start boss fight
	_start_boss_fight()

func _on_elevator_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	# Elevator can be used for fast travel if Jake bypass active
	if BypassType.JAKE_RESIDENT_ORDERS in active_bypasses:
		EventBus.dialogue_started.emit("System", "Elevator override active. Fast travel available.")
		await get_tree().create_timer(1.5).timeout
		EventBus.dialogue_ended.emit()

# ============================================================================
# BOSS FIGHT
# ============================================================================
func _start_boss_fight() -> void:
	boss_fight_started = true
	current_phase = MissionPhase.BOSS_FIGHT
	_update_objective("Defeat Victor Sterling!")
	
	# Spawn Victor Sterling
	_spawn_victor_sterling()
	
	# Show boss health bar
	if boss_health_bar:
		boss_health_bar.visible = true
	
	# Boss intro dialogue
	for line in BOSS_INTRO_LINES:
		EventBus.dialogue_started.emit("Victor", line)
		await get_tree().create_timer(2.5).timeout
	EventBus.dialogue_ended.emit()
	
	# Start boss music / alert state
	guards_alerted = true
	EventBus.combat_started.emit()
	EventBus.quest_updated.emit("Defeat Victor Sterling")

func _spawn_victor_sterling() -> void:
	var boss_scene := preload("res://scenes/characters/VictorSterling.tscn")
	if not boss_scene:
		EventBus.debug("ERROR: VictorSterling scene not found!")
		# Fallback: create basic boss
		_create_fallback_boss()
		return
	
	victor_sterling = boss_scene.instantiate()
	victor_sterling.global_position = boss_spawn.global_position
	victor_sterling.name = "VictorSterling"
	
	# Connect boss signals
	if victor_sterling.has_signal("phase_changed"):
		victor_sterling.phase_changed.connect(_on_boss_phase_changed)
	if victor_sterling.has_signal("health_changed"):
		victor_sterling.health_changed.connect(_on_boss_health_changed)
	if victor_sterling.has_signal("died"):
		victor_sterling.died.connect(_on_boss_died)
	if victor_sterling.has_signal("summon_guards"):
		victor_sterling.summon_guards.connect(_on_boss_summon_guards)
	if victor_sterling.has_signal("activate_security"):
		victor_sterling.activate_security.connect(_on_boss_activate_security)
	
	add_child(victor_sterling)
	EventBus.debug("Victor Sterling spawned")

func _create_fallback_boss() -> void:
	# Create a simple fallback boss if scene doesn't exist yet
	victor_sterling = CharacterBody2D.new()
	victor_sterling.name = "VictorSterlingFallback"
	victor_sterling.global_position = boss_spawn.global_position
	victor_sterling.add_to_group("enemy")
	victor_sterling.add_to_group("boss")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	collision.shape = shape
	victor_sterling.add_child(collision)
	
	# Visual
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-20, -40), Vector2(20, -40),
		Vector2(24, 0), Vector2(-24, 0)
	])
	sprite.color = Color(0.8, 0.1, 0.1, 1.0)  # Deep red
	victor_sterling.add_child(sprite)
	
	# Name label
	var label := Label.new()
	label.text = "Victor Sterling"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -56)
	label.add_theme_font_size_override("font_size", 12)
	victor_sterling.add_child(label)
	
	# Simple health
	victor_sterling.set_meta("max_health", 200)
	victor_sterling.set_meta("health", 200)
	victor_sterling.set_meta("phase", 1)
	
	add_child(victor_sterling)
	EventBus.debug("Fallback Victor Sterling created")

func _on_boss_phase_changed(new_phase: int) -> void:
	EventBus.debug("Boss entered phase " + str(new_phase))
	
	match new_phase:
		2:
			# Phase 2 dialogue
			for line in BOSS_PHASE2_LINES:
				EventBus.dialogue_started.emit("Victor", line)
				await get_tree().create_timer(2.5).timeout
			EventBus.dialogue_ended.emit()
			# Summon guards
			_on_boss_summon_guards()
		3:
			# Phase 3 dialogue
			for line in BOSS_PHASE3_LINES:
				EventBus.dialogue_started.emit("Victor", line)
				await get_tree().create_timer(2.5).timeout
			EventBus.dialogue_ended.emit()
			# Activate all security
			_on_boss_activate_security()

func _on_boss_health_changed(current: int, maximum: int) -> void:
	if boss_health_bar:
		boss_health_bar.max_value = maximum
		boss_health_bar.value = current

func _on_boss_died() -> void:
	EventBus.debug("Victor Sterling defeated!")
	EventBus.combat_ended.emit()
	
	if boss_health_bar:
		boss_health_bar.visible = false
	
	current_phase = MissionPhase.BOSS_DEFEATED
	_update_objective("Collect the evidence")
	
	# Drop evidence
	_spawn_evidence_item()
	
	EventBus.quest_updated.emit("Collect the Syndicate evidence")

func _on_boss_summon_guards() -> void:
	EventBus.debug("Boss summoned guards!")
	# Spawn additional guards near boss
	var guard_scene := preload("res://scenes/characters/guard.tscn")
	if not guard_scene:
		return
	
	for i in range(2):
		var guard = guard_scene.instantiate()
		var offset := Vector2(100 + i * 80, 50 + (i % 2) * 80)
		guard.global_position = boss_spawn.global_position + offset
		guard.name = "SummonedGuard_" + str(i)
		add_child(guard)
		EventBus.debug("Summoned guard " + str(i))

func _on_boss_activate_security() -> void:
	EventBus.debug("Boss activated security systems!")
	# Re-enable lasers, enable all cameras
	laser_grids_active = true
	cameras_disabled = false
	guards_alerted = true
	
	# Spawn extra guards
	_spawn_penthouse_enemies()

# ============================================================================
# EVIDENCE & ESCAPE
# ============================================================================
func _spawn_evidence_item() -> void:
	var evidence := Area2D.new()
	evidence.name = "SyndicateEvidence"
	evidence.global_position = evidence_spawn.global_position
	evidence.add_to_group("collectible")
	evidence.add_to_group("evidence")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	evidence.add_child(collision)
	
	# Visual - document/briefcase
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-16, -12), Vector2(16, -12),
		Vector2(16, 12), Vector2(-16, 12)
	])
	sprite.color = Color(0.9, 0.9, 0.7, 1.0)  # Manilla folder
	evidence.add_child(sprite)
	
	# Label
	var label := Label.new()
	label.text = "EVIDENCE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -28)
	label.add_theme_font_size_override("font_size", 10)
	evidence.add_child(label)
	
	evidence.body_entered.connect(_on_evidence_entered)
	add_child(evidence)
	EventBus.debug("Evidence spawned")

func _on_evidence_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if evidence_collected:
		return
	
	# Check if this is the evidence item (not the zone trigger)
	var evidence = get_node_or_null("SyndicateEvidence")
	if body == evidence or current_phase == MissionPhase.BOSS_DEFEATED:
		_evidence_collected()

func _evidence_collected() -> void:
	evidence_collected = true
	current_phase = MissionPhase.COLLECT_EVIDENCE
	EventBus.debug("Evidence collected!")
	
	# Remove evidence item
	var evidence = get_node_or_null("SyndicateEvidence")
	if evidence:
		evidence.queue_free()
	
	# Dialogue
	for line in EVIDENCE_LINES:
		EventBus.dialogue_started.emit("Jake", line)
		await get_tree().create_timer(2.0).timeout
	EventBus.dialogue_ended.emit()
	
	# Start escape
	_start_escape_phase()

func _start_escape_phase() -> void:
	current_phase = MissionPhase.ESCAPE
	_update_objective("ESCAPE! Alarm triggered!")
	
	# Alarm effects
	guards_alerted = true
	laser_grids_active = true
	
	# Spawn escape enemies
	_spawn_escape_enemies()
	
	# Dialogue
	for line in ESCAPE_LINES:
		EventBus.dialogue_started.emit("Jake", line)
		await get_tree().create_timer(1.5).timeout
	EventBus.dialogue_ended.emit()
	
	# If Dom bypass active, show fast escape route
	if BypassType.DOM_GETAWAY_VEHICLE in active_bypasses:
		EventBus.dialogue_started.emit("Dom", "The van's ready! South exit, move!")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()
		# Move escape zone closer
		if escape_zone:
			escape_zone.global_position = $FastEscapeSpawn.global_position if has_node("FastEscapeSpawn") else escape_zone.global_position
	
	EventBus.quest_updated.emit("Escape Sterling Tower with the evidence")

func _on_escape_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not evidence_collected:
		return
	if current_phase != MissionPhase.ESCAPE:
		return
	
	_complete_mission()

# ============================================================================
# ENEMY SPAWNING
# ============================================================================
func _spawn_floor_enemies() -> void:
	# Spawn lobby guards (fewer if Louis bypass)
	_spawn_lobby_enemies()

func _spawn_lobby_enemies() -> void:
	if not lobby_guard_spawns:
		return
	
	var guard_scene := preload("res://scenes/characters/guard.tscn")
	if not guard_scene:
		return
	
	var spawn_count := lobby_guard_spawns.get_child_count()
	# Reduce by 2 if Louis bypass active (min 1)
	if BypassType.LOUIS_DELIVERY_ENTRANCE in active_bypasses:
		spawn_count = max(1, spawn_count - 2)
		EventBus.debug("Louis bypass: Reduced lobby guards to " + str(spawn_count))
	
	var spawned := 0
	for spawn in lobby_guard_spawns.get_children():
		if spawned >= spawn_count:
			break
		if spawn is Marker2D:
			var guard = guard_scene.instantiate()
			guard.global_position = spawn.global_position
			guard.name = "LobbyGuard_" + str(spawned)
			add_child(guard)
			spawned += 1

func _spawn_office_enemies() -> void:
	if not office_guard_spawns:
		return
	
	var guard_scene := preload("res://scenes/characters/guard.tscn")
	if not guard_scene:
		return
	
	for i in range(office_guard_spawns.get_child_count()):
		var spawn = office_guard_spawns.get_child(i)
		if spawn is Marker2D:
			var guard = guard_scene.instantiate()
			guard.global_position = spawn.global_position
			guard.name = "OfficeGuard_" + str(i)
			add_child(guard)

func _spawn_penthouse_enemies() -> void:
	if not penthouse_guard_spawns:
		return
	
	var guard_scene := preload("res://scenes/characters/guard.tscn")
	if not guard_scene:
		return
	
	for i in range(penthouse_guard_spawns.get_child_count()):
		var spawn = penthouse_guard_spawns.get_child(i)
		if spawn is Marker2D:
			var guard = guard_scene.instantiate()
			guard.global_position = spawn.global_position
			guard.name = "PenthouseGuard_" + str(i)
			add_child(guard)

func _spawn_escape_enemies() -> void:
	# Spawn reinforcements during escape
	var goon_scene := preload("res://scenes/characters/goon.tscn")
	if not goon_scene:
		return
	
	var escape_spawns = $EscapeGuardSpawns if has_node("EscapeGuardSpawns") else null
	if not escape_spawns:
		return
	
	for i in range(escape_spawns.get_child_count()):
		var spawn = escape_spawns.get_child(i)
		if spawn is Marker2D:
			var goon = goon_scene.instantiate()
			goon.global_position = spawn.global_position
			goon.name = "EscapeGoon_" + str(i)
			add_child(goon)

# ============================================================================
# SECURITY SYSTEMS
# ============================================================================
func _spawn_security_systems() -> void:
	_spawn_cameras()
	_spawn_laser_grids()
	_spawn_keycard_doors()

func _spawn_cameras() -> void:
	if not security_cameras:
		return
	
	if cameras_disabled:
		EventBus.debug("Cameras disabled via friend favor")
		for cam in security_cameras.get_children():
			cam.visible = false
			if cam.has_method("disable"):
				cam.disable()
		return
	
	for cam in security_cameras.get_children():
		if cam.has_method("enable"):
			cam.enable()
		EventBus.debug("Camera active: " + cam.name)

func _spawn_laser_grids() -> void:
	if not laser_grids:
		return
	
	for grid in laser_grids.get_children():
		if laser_grids_active:
			if grid.has_method("activate"):
				grid.activate()
		else:
			if grid.has_method("deactivate"):
				grid.deactivate()

func _spawn_keycard_doors() -> void:
	if not keycard_doors:
		return
	
	if keycard_doors_unlocked:
		EventBus.debug("Keycard doors pre-unlocked via friend favor")
		for door in keycard_doors.get_children():
			if door.has_method("unlock"):
				door.unlock()
		return
	
	for door in keycard_doors.get_children():
		if door.has_method("lock"):
			door.lock()

func _unlock_all_keycard_doors() -> void:
	keycard_doors_unlocked = true
	if keycard_doors:
		for door in keycard_doors.get_children():
			if door.has_method("unlock"):
				door.unlock()

# ============================================================================
# COLLECTIBLES
# ============================================================================
func _spawn_collectibles() -> void:
	# Polaroid
	var polaroid_pos := Vector2(600, 400)  # Default, override with spawn if exists
	if has_node("PolaroidSpawn"):
		polaroid_pos = $PolaroidSpawn.global_position
	_spawn_polaroid(polaroid_pos)
	
	# Trinket
	var trinket_pos := Vector2(200, 300)
	if has_node("TrinketSpawn"):
		trinket_pos = $TrinketSpawn.global_position
	_spawn_trinket(trinket_pos)

func _spawn_polaroid(pos: Vector2) -> void:
	var polaroid := Area2D.new()
	polaroid.name = "Polaroid_SterlingTower"
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
	trinket.name = "Trinket_SyndicateBadge"
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
		Vector2(-8, -8), Vector2(8, -8),
		Vector2(8, 8), Vector2(-8, 8)
	])
	sprite.color = Color(0.7, 0.1, 0.1, 1.0)  # Dark red badge
	trinket.add_child(sprite)
	
	trinket.body_entered.connect(_on_trinket_body_entered)
	add_child(trinket)

func _on_polaroid_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not polaroid_collected:
		polaroid_collected = true
		GameState.add_polaroid(REWARD_POLAROID)
		EventBus.debug("Polaroid collected: Sterling Tower")
		var polaroid = get_node_or_null("Polaroid_SterlingTower")
		if polaroid:
			polaroid.queue_free()

func _on_trinket_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not trinket_collected:
		trinket_collected = true
		GameState.add_trinket(REWARD_TRINKET)
		EventBus.debug("Trinket collected: Syndicate Badge")
		var trinket = get_node_or_null("Trinket_SyndicateBadge")
		if trinket:
			trinket.queue_free()

# ============================================================================
# UI HELPERS
# ============================================================================
func _update_floor_label(floor_name: String) -> void:
	if floor_label:
		floor_label.text = "FLOOR: " + floor_name

func _update_objective(text: String) -> void:
	if objective_label:
		objective_label.text = "Objective: " + text

func _show_friend_notification(text: String) -> void:
	if friend_notification:
		friend_notification.text = text
		friend_notification.visible = true
		# Auto-hide after 4 seconds
		await get_tree().create_timer(4.0).timeout
		friend_notification.visible = false

# ============================================================================
# MISSION COMPLETION
# ============================================================================
func _complete_mission() -> void:
	if is_complete:
		return
	
	is_complete = true
	current_phase = MissionPhase.COMPLETE
	EventBus.debug("=== STERLING TOWER HEIST COMPLETE ===")
	
	# Complete mission
	GameState.complete_mission(MISSION_ID)
	
	# Final dialogue
	EventBus.dialogue_started.emit("Jake", "It's done. The Sterling Syndicate is finished.")
	await get_tree().create_timer(2.5).timeout
	EventBus.dialogue_ended.emit()
	
	# Build rewards
	var rewards := {
		"polaroid": REWARD_POLAROID if polaroid_collected else "",
		"trinket": REWARD_TRINKET if trinket_collected else "",
		"intel": MissionData.get_intel_reward(MISSION_ID),
		"evidence": true
	}
	
	# Show mission result
	EventBus.show_mission_result.emit(true, rewards)
	
	# Save
	SaveManager.auto_save()
	
	# Trigger ending sequence after delay
	await get_tree().create_timer(4.0).timeout
	_trigger_ending_sequence()

func _trigger_ending_sequence() -> void:
	EventBus.debug("Triggering ending sequence...")
	# Set a dialogue flag for the ending
	GameState.set_dialogue_flag("sterling_defeated", true)
	GameState.set_dialogue_flag("game_completed", true)
	
	# Return to hideout for ending dialogue
	SceneManager.change_to_scene("hideout")

# ============================================================================
# FAILURE
# ============================================================================
func fail_mission(reason: String = "caught") -> void:
	if is_complete:
		return
	
	is_complete = true
	EventBus.debug("Sterling Tower Heist FAILED: " + reason)
	
	GameState.fail_mission(MISSION_ID, 20)  # Higher intel for final mission
	GameState.end_mission()
	
	# Calculate partial progress
	var partial_progress := 0.0
	match current_phase:
		MissionPhase.ASCEND_OFFICES:
			partial_progress = 0.25
		MissionPhase.REACH_PENTHOUSE:
			partial_progress = 0.5
		MissionPhase.BOSS_FIGHT:
			partial_progress = 0.75
		MissionPhase.BOSS_DEFEATED, MissionPhase.COLLECT_EVIDENCE:
			partial_progress = 0.9
		_:
			partial_progress = 0.1
	
	if evidence_collected:
		partial_progress = 0.95
	
	EventBus.show_failure_screen.emit("Mission Failed: " + reason, partial_progress)
	
	SaveManager.auto_save()
	
	await get_tree().create_timer(4.0).timeout
	SceneManager.change_to_scene("hideout")

# ============================================================================
# CLEANUP
# ============================================================================
func cleanup() -> void:
	EventBus.debug("Sterling Tower cleanup")
	
	# Disconnect all signals
	if lobby_to_office_trigger and lobby_to_office_trigger.body_entered.is_connected(_on_lobby_to_office_entered):
		lobby_to_office_trigger.body_entered.disconnect(_on_lobby_to_office_entered)
	if office_to_penthouse_trigger and office_to_penthouse_trigger.body_entered.is_connected(_on_office_to_penthouse_entered):
		office_to_penthouse_trigger.body_entered.disconnect(_on_office_to_penthouse_entered)
	if penthouse_entrance and penthouse_entrance.body_entered.is_connected(_on_penthouse_entered):
		penthouse_entrance.body_entered.disconnect(_on_penthouse_entered)
	if evidence_zone and evidence_zone.body_entered.is_connected(_on_evidence_entered):
		evidence_zone.body_entered.disconnect(_on_evidence_entered)
	if escape_zone and escape_zone.body_entered.is_connected(_on_escape_entered):
		escape_zone.body_entered.disconnect(_on_escape_entered)
	if elevator_zone and elevator_zone.body_entered.is_connected(_on_elevator_entered):
		elevator_zone.body_entered.disconnect(_on_elevator_entered)
	
	# Hide UI
	if boss_health_bar:
		boss_health_bar.visible = false
	
	super.cleanup()

# ============================================================================
# DEBUG
# ============================================================================
func _get_mission_id() -> String:
	return MISSION_ID

# Debug hotkeys (only in debug builds)
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	
	if event.is_action_pressed("ui_page_down"):
		# Instantly complete
		_evidence_collected()
	if event.is_action_pressed("ui_page_up"):
		# Instantly fail
		fail_mission("debug_fail")
	if event.is_action_pressed("ui_home"):
		# Skip to boss
		_transition_to_penthouse()
		_start_boss_fight()
