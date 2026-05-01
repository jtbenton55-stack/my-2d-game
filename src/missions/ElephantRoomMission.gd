extends "res://src/missions/InteractiveMission.gd"

# The Elephant in the Room - Mission 5
# Bentley emotional spotlight - Ellie rescue mission

var scent_clues_collected := {"pink_thread": false, "fish_treat": false, "squeaker": false}
var ellie_rescued := false
var opening_dialogue_played := false
var loyalty_moment_triggered := false
var bentley_serious_moment_triggered := false
var funny_payoff_triggered := false

func _ready() -> void:
	super._ready()

	spawn_poop_bags_at_global_positions([Vector2(300, 640), Vector2(560, 480), Vector2(740, 720)])

	_setup_opening_dialogue()
	_setup_bentley_serious_moment()
	_setup_ellie_rescue()
	_setup_loyalty_reward()

func _setup_opening_dialogue() -> void:
	var opening := get_node_or_null("OpeningDialogue")
	if opening:
		var trigger := opening.get_node_or_null("TriggerZone")
		if trigger:
			trigger.body_entered.connect(_on_opening_triggered)

func _on_opening_triggered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if opening_dialogue_played:
		return
	opening_dialogue_played = true
	
	var opening := get_node_or_null("OpeningDialogue")
	if opening and opening.has_method("start_dialogue"):
		opening.start_dialogue()
		QuestManager.set_objective("Follow the scent clues to find Ellie. Bentley is counting on you.", get_mission_id())

func _setup_bentley_serious_moment() -> void:
	var serious_zone := get_node_or_null("BentleySeriousMoment")
	if serious_zone:
		serious_zone.body_entered.connect(_on_serious_moment)

func _on_serious_moment(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if bentley_serious_moment_triggered:
		return
	bentley_serious_moment_triggered = true
	
	# Bentley's serious mood shift dialogue
	DialogueManager.show_dialogue("Bentley", "*low growl, eyes fixed ahead* ...Grr.")
	DialogueManager.show_dialogue("You", "I've never seen you like this, buddy.")
	DialogueManager.show_dialogue("Bentley", "*single-minded determination* Woof.")
	
	QuestManager.set_objective("Bentley is tracking seriously. Follow his lead.", get_mission_id())

func _on_required_entered(body: Node, zone: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	
	var zone_name := zone.name
	if zone_name == "Objective_ScentOne":
		scent_clues_collected["pink_thread"] = true
		DialogueManager.show_dialogue("Bentley", "*excited sniffing* Woof! Woof!")
		DialogueManager.show_dialogue("You", "Pink thread from Ellie's stitching. Good nose, Bentley.")
	elif zone_name == "Objective_ScentTwo":
		scent_clues_collected["fish_treat"] = true
		DialogueManager.show_dialogue("Bentley", "*intense sniffing, tail wagging slightly* ...Woof.")
		DialogueManager.show_dialogue("You", "Fish treats. Someone's been feeding her to keep her quiet.")
	elif zone_name == "Objective_ScentThree":
		scent_clues_collected["squeaker"] = true
		DialogueManager.show_dialogue("Bentley", "*whimper* ...Ruff.")
		DialogueManager.show_dialogue("You", "Her squeaker toy. We're getting close, buddy.")
	elif zone_name == "Objective_Ellie":
		_ellie_found()
		return  # Don't call super for Ellie - we handle it specially
	
	super._on_required_entered(body, zone)
	
	# Check if all clues collected
	var all_clues: bool = scent_clues_collected["pink_thread"] and scent_clues_collected["fish_treat"] and scent_clues_collected["squeaker"]
	if all_clues and not ellie_rescued:
		QuestManager.set_objective("All clues lead to the storage cage. Ellie is close.", get_mission_id())
		# Reveal the cage
		var cage := get_node_or_null("ElliesCage")
		if cage:
			cage.visible = true
		var cage_label := get_node_or_null("ElliesCage/CageLabel")
		if cage_label:
			cage_label.visible = true

func _ellie_found() -> void:
	if ellie_rescued:
		return
	ellie_rescued = true
	
	# Reveal cage visual
	var cage := get_node_or_null("ElliesCage")
	if cage:
		cage.visible = true
	
	# Rescue dialogue
	DialogueManager.show_dialogue("You", "There she is. Hold on, Ellie.")
	DialogueManager.show_dialogue("Bentley", "*urgent whining* Woof! Woof!")
	
	# Play unlock sound
	AudioManager.play_sfx("item_craft")
	
	QuestManager.set_objective("Ellie rescued! Bentley's loyalty has surged. Time to leave.", get_mission_id())
	
	# Make polaroid collectable
	var polaroid := get_node_or_null("Polaroid_Reunion")
	if polaroid:
		polaroid.visible = true
	
	# Trigger loyalty moment after rescue
	EventBus.dialogue_ended.connect(_trigger_loyalty_moment, CONNECT_ONE_SHOT)

func _setup_ellie_rescue() -> void:
	var rescue_zone := get_node_or_null("RescueMoment")
	if rescue_zone:
		rescue_zone.body_entered.connect(_on_rescue_interact)

func _on_rescue_interact(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not ellie_rescued:
		return
	if loyalty_moment_triggered:
		return
	_trigger_loyalty_moment()

func _setup_loyalty_reward() -> void:
	var loyalty_zone := get_node_or_null("LoyaltyDialogue")
	if loyalty_zone:
		var trigger := loyalty_zone.get_node_or_null("TriggerZone")
		if trigger:
			trigger.body_entered.connect(_on_loyalty_triggered)

func _on_loyalty_triggered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_trigger_loyalty_moment()

func _trigger_loyalty_moment() -> void:
	if loyalty_moment_triggered:
		return
	loyalty_moment_triggered = true
	
	var loyalty := get_node_or_null("LoyaltyDialogue")
	if loyalty and loyalty.has_method("start_dialogue"):
		loyalty.start_dialogue()
	
	# Apply Bentley loyalty buff - unlocks free save/favor behavior
	GameState.set_meta("bentley_loyalty_unlocked", true)
	GameState.intel_points += 2
	
	EventBus.dialogue_ended.connect(_bentley_funny_payoff, CONNECT_ONE_SHOT)

func _bentley_funny_payoff() -> void:
	if funny_payoff_triggered:
		return
	funny_payoff_triggered = true
	
	# Emotional but funny payoff
	DialogueManager.show_dialogue("Bentley", "*curling around Ellie protectively* ...*farts*")
	DialogueManager.show_dialogue("You", "Bentley! We're having a moment here!")
	DialogueManager.show_dialogue("Bentley", "*completely unbothered, licking Ellie's trunk* Woof.")

func complete_level() -> void:
	if not ellie_rescued:
		QuestManager.set_objective("Bentley will NOT leave without Ellie. Find her first.", get_mission_id())
		DialogueManager.show_dialogue("Bentley", "*sits stubbornly, refusing to move* ...*stares at you*")
		return
	
	# Final emotional sign-off
	if loyalty_moment_triggered:
		DialogueManager.show_dialogue("Bentley", "*carrying Ellie gently in mouth, trotting proudly* Woof.")
	
	super.complete_level()
