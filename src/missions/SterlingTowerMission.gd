extends "res://src/levels/LevelBase.gd"

enum MissionStep {
	PRE_HEIST,
	DELIVERY_ENTRANCE,
	LEGAL_TRAP_FLOOR,
	VAULT_TIMING_FLOOR,
	BASS_BLACKOUT,
	COMBAT_HOLDOFF,
	BENTLEY_MASTER_KEY,
	VICTOR_CONFRONTATION,
	ENDING_TRANSITION,
	COMPLETE
}

# Mission state
var current_step: int = MissionStep.PRE_HEIST
var step_data: Dictionary = {}

# Friend contribution flags
var louis_helped := false
var mere_helped := false
var yordano_helped := false
var bryce_helped := false
var bentley_master_key_retrieved := false
var victor_confronted := false

# Ending flow
var ending_dialogue_shown := false
var mission_completing := false

# Victor confrontation
var victor_choice_made := false
var victor_choice_index := -1

func _ready() -> void:
	mission_id = "sterling_tower_heist"
	objective_text = "The Sterling Tower. Every favor comes due."
	guard_count = 0  # We'll spawn guards manually per floor
	super._ready()
	
	# Start the pre-heist briefing after a short delay
	call_deferred("_start_pre_heist_briefing")
	
	# Connect zone signals
	_setup_mission_zones()

func _setup_mission_zones() -> void:
	# Delivery entrance zone
	var delivery_zone := get_node_or_null("DeliveryEntranceZone")
	if delivery_zone:
		delivery_zone.body_entered.connect(_on_delivery_entrance_entered)
	
	# Legal trap zone
	var legal_zone := get_node_or_null("LegalTrapZone")
	if legal_zone:
		legal_zone.body_entered.connect(_on_legal_trap_entered)
	
	# Vault timing zone
	var vault_zone := get_node_or_null("VaultTimingZone")
	if vault_zone:
		vault_zone.body_entered.connect(_on_vault_timing_entered)
	
	# Bass blackout zone
	var bass_zone := get_node_or_null("BassBlackoutZone")
	if bass_zone:
		bass_zone.body_entered.connect(_on_bass_blackout_entered)
	
	# Combat zone
	var combat_zone := get_node_or_null("CombatHoldoffZone")
	if combat_zone:
		combat_zone.body_entered.connect(_on_combat_entered)
	
	# Bentley vent zone
	var vent_zone := get_node_or_null("BentleyVentZone")
	if vent_zone:
		vent_zone.body_entered.connect(_on_vent_entered)
	
	# Victor confrontation zone
	var victor_zone := get_node_or_null("VictorConfrontationZone")
	if victor_zone:
		victor_zone.body_entered.connect(_on_victor_confrontation_entered)
	
	# Exit zone override
	var exit_zone := get_node_or_null("ExitZone")
	if exit_zone:
		if exit_zone.body_entered.is_connected(_on_exit_zone_body_entered):
			exit_zone.body_entered.disconnect(_on_exit_zone_body_entered)
		exit_zone.body_entered.connect(_on_tower_exit_entered)

# ============================================================================
# PRE-HEIST BRIEFING
# ============================================================================

func _start_pre_heist_briefing() -> void:
	current_step = MissionStep.PRE_HEIST
	
	# Build briefing dialogue based on unlocked crew members
	var briefing_lines: Array[Dictionary] = [
		{"speaker": "Jake", "text": "This is it. Sterling Tower. The final job."},
		{"speaker": "Bentley", "text": "*intense dental stare*"}
	]
	
	# Add Louis's contribution if he's in the crew
	if _is_crew_member("louis"):
		briefing_lines.append({"speaker": "Louis", "text": "I mapped the delivery entrance. We go in through the loading dock—no cameras, no guards."})
		louis_helped = true
	
	# Add Mere's contribution
	if _is_crew_member("mere"):
		briefing_lines.append({"speaker": "Mere", "text": "The legal floor has a contract trap. I'll spot the bad clauses before you sign anything."})
	
	# Add Yordano's contribution
	if _is_crew_member("yordano"):
		briefing_lines.append({"speaker": "Yordano", "text": "When we hit the security floor, I'll drop the bass. Lights out, guards down."})
	
	# Add Dom's contribution
	if _is_crew_member("dom"):
		briefing_lines.append({"speaker": "Dom", "text": "Getaway's idling in the alley. Fast family doesn't leave family behind."})
	
	# Add Bryce's contribution
	if _is_crew_member("bryce"):
		briefing_lines.append({"speaker": "Bryce", "text": "The vault has Swiss timing. I've studied the mechanism—I'll slow it down when we get there."})
	
	# Add Jake's closing
	briefing_lines.append({"speaker": "Jake", "text": "Every person we helped is here with us. Let's finish this."})
	briefing_lines.append({"speaker": "Bentley", "text": "*determined woof*"})
	
	DialogueManager.start_simple_dialogue(briefing_lines)
	QuestManager.set_objective("Enter through the delivery entrance.", mission_id)

func _is_crew_member(friend_id: String) -> bool:
	return GameState.crew_members.has(friend_id) or GameState.friend_favors.get(friend_id, {}).get("helped", false)

# ============================================================================
# STEP 1: DELIVERY ENTRANCE (Louis)
# ============================================================================

func _on_delivery_entrance_entered(body: Node) -> void:
	if not body.is_in_group("player") or current_step != MissionStep.PRE_HEIST:
		return
	
	current_step = MissionStep.DELIVERY_ENTRANCE
	
	if _is_crew_member("louis") and not louis_helped:
		louis_helped = true
		DialogueManager.start_simple_dialogue([
			{"speaker": "Louis", "text": "See? Told you. My delivery routes are solid gold."},
			{"speaker": "Jake", "text": "Gold would've been heavier. Let's move."}
		])
	else:
		DialogueManager.start_simple_dialogue([
			{"speaker": "Jake", "text": "Loading dock is clear. Moving in."}
		])
	
	QuestManager.set_objective("Take the elevator to the legal floor. Watch for traps.", mission_id)
	
	# Disable this zone
	var zone := get_node_or_null("DeliveryEntranceZone")
	if zone:
		zone.set_deferred("monitoring", false)

# ============================================================================
# STEP 2: LEGAL TRAP FLOOR (Mere)
# ============================================================================

func _on_legal_trap_entered(body: Node) -> void:
	if not body.is_in_group("player") or current_step != MissionStep.DELIVERY_ENTRANCE:
		return
	
	current_step = MissionStep.LEGAL_TRAP_FLOOR
	
	if _is_crew_member("mere"):
		# Mere helps identify the trap
		DialogueManager.start_simple_dialogue([
			{"speaker": "Mere", "text": "Stop! That contract on the desk—it's a trap. Clause 7B activates an alarm if you touch the wrong paper."},
			{"speaker": "Jake", "text": "Which one do I need?"},
			{"speaker": "Mere", "text": "The blue folder. 'Prior Art Affidavit.' That's Sterling's actual weakness."}
		])
		mere_helped = true
	else:
		DialogueManager.start_simple_dialogue([
			{"speaker": "Jake", "text": "Legal floor. Lots of paperwork... one of these must be important."},
			{"speaker": "Bentley", "text": "*nudges the blue folder*"},
			{"speaker": "Jake", "text": "Good nose, buddy."}
		])
	
	QuestManager.set_objective("Take the elevator to the vault floor. Time is tight.", mission_id)
	
	var zone := get_node_or_null("LegalTrapZone")
	if zone:
		zone.set_deferred("monitoring", false)

# ============================================================================
# STEP 3: VAULT TIMING FLOOR (Bryce)
# ============================================================================

func _on_vault_timing_entered(body: Node) -> void:
	if not body.is_in_group("player") or current_step != MissionStep.LEGAL_TRAP_FLOOR:
		return
	
	current_step = MissionStep.VAULT_TIMING_FLOOR
	
	var vault_lines: Array[Dictionary] = [
		{"speaker": "Jake", "text": "The vault door. Swiss engineering, biometric locks..."}
	]
	
	if _is_crew_member("bryce") and GameState.has_selected_card("bryce_swiss_timing"):
		bryce_helped = true
		vault_lines.append({"speaker": "Bryce", "text": "I've got this. The timing mechanism has a 3-second delay pattern. Watch..."})
		vault_lines.append({"speaker": "Jake", "text": "The tumblers are slowing down!"})
		vault_lines.append({"speaker": "Bryce", "text": "You have 30 seconds instead of 10. Go!"})
	else:
		vault_lines.append({"speaker": "Jake", "text": "I need to crack this fast. Bentley, keep watch."})
		vault_lines.append({"speaker": "Bentley", "text": "*nervous pacing*"})
	
	DialogueManager.start_simple_dialogue(vault_lines)
	QuestManager.set_objective("Vault access gained. Head to the security floor.", mission_id)
	
	var zone := get_node_or_null("VaultTimingZone")
	if zone:
		zone.set_deferred("monitoring", false)

# ============================================================================
# STEP 4: BASS BLACKOUT (Yordano)
# ============================================================================

func _on_bass_blackout_entered(body: Node) -> void:
	if not body.is_in_group("player") or current_step != MissionStep.VAULT_TIMING_FLOOR:
		return
	
	current_step = MissionStep.BASS_BLACKOUT
	
	if _is_crew_member("yordano"):
		yordano_helped = true
		DialogueManager.start_simple_dialogue([
			{"speaker": "Yordano", "text": "Security floor ahead. Time for the bass drop."},
			{"speaker": "Jake", "text": "How does music help us—"},
			{"speaker": "Yordano", "text": "Not music. Resonance frequency. Cover your ears!"},
			{"speaker": "Jake", "text": "The lights! The guards are stunned!"},
			{"speaker": "Yordano", "text": "The rhythm of revenge, my friend. Move!"}
		])
		# Stun all guards in the security floor
		_stun_security_guards()
	else:
		DialogueManager.start_simple_dialogue([
			{"speaker": "Jake", "text": "Security floor. Guards everywhere."},
			{"speaker": "Bentley", "text": "*low growl*"}
		])
		# Spawn guards for combat
		_spawn_security_guards()
	
	QuestManager.set_objective("Move through the security floor. Bentley needs to reach the vents.", mission_id)
	
	var zone := get_node_or_null("BassBlackoutZone")
	if zone:
		zone.set_deferred("monitoring", false)

func _stun_security_guards() -> void:
	# Find and stun all guards in the security floor area
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.name.begins_with("SecurityGuard"):
			if enemy.has_method("stun"):
				enemy.stun(5.0)
			elif enemy.has_method("set_disabled"):
				enemy.set_disabled(true)
			# Visual indication
			var sprite := enemy.get_node_or_null("Sprite2D")
			if sprite:
				sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)

func _spawn_security_guards() -> void:
	var guard_scene: PackedScene = load("res://scenes/characters/guard.tscn")
	if guard_scene == null:
		return
		
	var spawn_points := get_node_or_null("SecurityGuardSpawns")
	if spawn_points:
		for spawn in spawn_points.get_children():
			var guard: Node2D = guard_scene.instantiate()
			guard.name = "SecurityGuard_" + spawn.name
			add_child(guard)
			guard.global_position = spawn.global_position

# ============================================================================
# STEP 5: COMBAT HOLDOFF
# ============================================================================

func _on_combat_entered(body: Node) -> void:
	if not body.is_in_group("player") or current_step != MissionStep.BASS_BLACKOUT:
		return
	
	current_step = MissionStep.COMBAT_HOLDOFF
	
	# Ellie makes an unexpected appearance
	DialogueManager.start_simple_dialogue([
		{"speaker": "Jake", "text": "Wait—is that Ellie?"},
		{"speaker": "Bentley", "text": "*frantic barking*"},
		{"speaker": "Ellie", "text": "(The pink elephant plush sits conspicuously on a desk. Her button eyes seem to judge the security systems.)"},
		{"speaker": "Jake", "text": "She... rolled into the security panel?"},
		{"speaker": "Ellie", "text": "(A soft *boop* as her trunk hits the override switch.)"},
		{"speaker": "Jake", "text": "The alarms are disabled. Ellie, you brilliant pink nightmare."},
		{"speaker": "Bentley", "text": "*proud woof*"}
	])
	
	QuestManager.set_objective("Ellie cleared the path. Find the vent access for Bentley.", mission_id)
	
	var zone := get_node_or_null("CombatHoldoffZone")
	if zone:
		zone.set_deferred("monitoring", false)

# ============================================================================
# STEP 6: BENTLEY MASTER KEY (Required)
# ============================================================================

func _on_vent_entered(body: Node) -> void:
	if not body.is_in_group("player") or current_step != MissionStep.COMBAT_HOLDOFF:
		return
	
	current_step = MissionStep.BENTLEY_MASTER_KEY
	
	DialogueManager.start_simple_dialogue([
		{"speaker": "Jake", "text": "There's the vent, Bentley. The master key should be in Sterling's private office."},
		{"speaker": "Bentley", "text": "*determined stare*"},
		{"speaker": "Jake", "text": "Small spaces, big stakes. You got this, Dental Boy."},
		{"speaker": "Bentley", "text": "*disappears into the vent*"},
		{"speaker": "Jake", "text": "..."},
		{"speaker": "Bentley", "text": "*distant sounds of chewing, then a triumphant bark*"},
		{"speaker": "Jake", "text": "He's got it! The master key!"},
		{"speaker": "Bentley", "text": "*emerges with key in mouth, judges carpet*"}
	])
	
	bentley_master_key_retrieved = true
	AudioManager.play_sfx("item_pickup")
	
	QuestManager.set_objective("Master key retrieved. Sterling's office is next. End this.", mission_id)
	
	var zone := get_node_or_null("BentleyVentZone")
	if zone:
		zone.set_deferred("monitoring", false)

# ============================================================================
# STEP 7: VICTOR CONFRONTATION
# ============================================================================

func _on_victor_confrontation_entered(body: Node) -> void:
	if not body.is_in_group("player") or current_step != MissionStep.BENTLEY_MASTER_KEY:
		return
	if victor_confronted:
		return
	
	current_step = MissionStep.VICTOR_CONFRONTATION
	victor_confronted = true
	
	# Spawn Victor Sterling
	_spawn_victor_sterling()
	
	# Start confrontation dialogue, then show choice when done
	var confrontation_lines: Array[Dictionary] = [
		{"speaker": "Victor Sterling", "text": "So the delivery thief finally shows her face. Alone, I presume?"},
		{"speaker": "Jake", "text": "I'm not alone. I brought every person you stepped on to get here."},
		{"speaker": "Victor Sterling", "text": "Sentiment. The weakness of small minds."},
		{"speaker": "Bentley", "text": "*growls with key in mouth*"},
		{"speaker": "Victor Sterling", "text": "A dog? You brought a dog to a corporate takeover?"},
		{"speaker": "Jake", "text": "I brought friends. Something you wouldn't understand."}
	]
	
	# Connect to dialogue ended to show choice
	if not EventBus.dialogue_ended.is_connected(_on_confrontation_dialogue_ended):
		EventBus.dialogue_ended.connect(_on_confrontation_dialogue_ended)
	
	DialogueManager.start_simple_dialogue(confrontation_lines)

func _on_confrontation_dialogue_ended() -> void:
	if EventBus.dialogue_ended.is_connected(_on_confrontation_dialogue_ended):
		EventBus.dialogue_ended.disconnect(_on_confrontation_dialogue_ended)
	# Show choice after confrontation dialogue
	_show_victor_choice()

func _spawn_victor_sterling() -> void:
	var victor_scene: PackedScene = load("res://scenes/characters/VictorSterling.tscn")
	if victor_scene:
		var victor = victor_scene.instantiate()
		victor.name = "VictorSterlingBoss"
		add_child(victor)
		var spawn := get_node_or_null("VictorSpawn")
		if spawn:
			victor.global_position = spawn.global_position

func _show_victor_choice() -> void:
	var choice_panel = load("res://src/dialogue/choice_panel.tscn")
	if choice_panel:
		var panel = choice_panel.instantiate()
		panel.setup("Victor sneers. 'You think friendship scales? Empires need ruthlessness.'", [
			"You built an empire out of fear. I built mine out of favors.",
			"My friends chose to be here. Your employees can't wait to leave."
		])
		panel.choice_made.connect(_on_victor_choice_made)
		add_child(panel)

func _on_victor_choice_made(index: int) -> void:
	victor_choice_made = true
	victor_choice_index = index
	
	var response_lines: Array[Dictionary]
	
	if index == 0:
		# "Favors" choice
		response_lines = [
			{"speaker": "Jake", "text": "You built an empire out of fear. I built mine out of favors."},
			{"speaker": "Victor Sterling", "text": "Favors don't scale."},
			{"speaker": "Jake", "text": "They don't need to. They just need to matter."}
		]
	else:
		# "Friends" choice
		response_lines = [
			{"speaker": "Jake", "text": "My friends chose to be here. Your employees can't wait to leave."},
			{"speaker": "Victor Sterling", "text": "Loyalty can be bought."},
			{"speaker": "Jake", "text": "Not the kind that shows up at 3 AM with a getaway car."}
		]
	
	# Add final lines
	response_lines.append({"speaker": "Victor Sterling", "text": "..."})
	response_lines.append({"speaker": "Victor Sterling", "text": "The master key. Take it. Take the evidence. It won't change anything."})
	response_lines.append({"speaker": "Jake", "text": "It already has."})
	response_lines.append({"speaker": "Bentley", "text": "*drops key, judges Victor's life choices*"})
	
	DialogueManager.start_simple_dialogue(response_lines)
	
	QuestManager.set_objective("Victor is defeated. Exit through the lobby when ready.", mission_id)
	current_step = MissionStep.ENDING_TRANSITION

# ============================================================================
# STEP 8: ENDING TRANSITION
# ============================================================================

func _on_tower_exit_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if not bentley_master_key_retrieved:
		QuestManager.set_objective("We need the master key first. Check the vent area.", mission_id)
		return
	
	if not victor_confronted:
		QuestManager.set_objective("Sterling is still in his office. We finish this properly.", mission_id)
		return
	
	if not ending_dialogue_shown:
		_ending_dialogue()
		return
	
	# Second press - complete the mission
	_complete_final_mission()

func _ending_dialogue() -> void:
	ending_dialogue_shown = true
	
	# Build final crew dialogue
	var final_lines: Array[Dictionary] = [
		{"speaker": "Jake", "text": "We did it. Sterling's empire has a very big hole in it now."}
	]
	
	# Add each crew member's contribution
	if _is_crew_member("louis"):
		final_lines.append({"speaker": "Louis", "text": "Delivery routes for the win! Called it!"})
	
	if _is_crew_member("mere"):
		final_lines.append({"speaker": "Mere", "text": "Legal traps disarmed. Creative collaboration wins, even in a heist."})
	
	if _is_crew_member("yordano"):
		final_lines.append({"speaker": "Yordano", "text": "The bass drop heard 'round the tower. Beautiful."})
	
	if _is_crew_member("dom"):
		final_lines.append({"speaker": "Dom", "text": "Fast family forever. Now can we actually use the getaway?"})
	
	if _is_crew_member("bryce"):
		final_lines.append({"speaker": "Bryce", "text": "Swiss timing, meet better timing."})
	
	if _is_crew_member("violet"):
		final_lines.append({"speaker": "Violet", "text": "The counterpunch nobody saw coming."})
	
	if _is_crew_member("jinx"):
		final_lines.append({"speaker": "Jinx", "text": "Clean job. Real clean."})
	
	if _is_crew_member("eren"):
		final_lines.append({"speaker": "Eren", "text": "Family recipe secret: it was never about the sauce."})
	
	# Always include Jake and Bentley closing
	final_lines.append({"speaker": "Jake", "text": "Every favor came due tonight. And every single one paid back."})
	final_lines.append({"speaker": "Bentley", "text": "*happy bark*"})
	final_lines.append({"speaker": "Jake", "text": "Ready when you are, buddy. Press the exit one more time to see the final photo."})
	
	DialogueManager.start_simple_dialogue(final_lines)
	QuestManager.set_objective("Press the exit again when ready for the final photo.", mission_id)

func _complete_final_mission() -> void:
	if mission_completing:
		return
	mission_completing = true
	
	is_complete = true
	
	# Mark as complete (with duplicate protection)
	GameState.complete_mission(mission_id)
	
	# Transition to ending scene
	SceneManager.show_ending()

# ============================================================================
# OVERRIDE: Prevent double completion
# ============================================================================

func complete_level() -> void:
	# Sterling Tower uses custom exit flow, not the default
	# The exit zone calls _on_tower_exit_entered instead
	pass
