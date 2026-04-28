extends "res://src/missions/InteractiveMission.gd"

# The Arm-Wrestling Underground - Funny strength challenge with Violet
# Purpose: Win matches, earn Violet's respect, unlock Counterpunch

var opponent_1_beaten := false
var opponent_2_beaten := false
var opponent_3_beaten := false
var violet_beaten := false
var violet_moment_shown := false
var bentley_moment_shown := false
var poster_read := false
var training_tip_found := false
var current_match := 0
var match_in_progress := false

func _ready() -> void:
	mission_id = "arm_wrestling_underground"
	objective_text = "Beat three opponents at the strength table, then face Violet for the Counterpunch technique."
	guard_count = 2
	completion_item_name = "round"
	completion_line = "All opponents defeated! Counterpunch technique unlocked! Exit through the back alley."
	missing_item_line = "The table is not impressed yet. Beat all three opponents first."
	super._ready()
	
	_setup_interactables()
	_show_opening_dialogue()

func _setup_interactables() -> void:
	# Opponent zones - Big Mike
	var big_mike := get_node_or_null("BigMikeZone")
	if big_mike:
		big_mike.add_to_group("interactable")
		big_mike.body_entered.connect(_on_big_mike_entered)
	
	# Protein Baron
	var protein_baron := get_node_or_null("ProteinBaronZone")
	if protein_baron:
		protein_baron.add_to_group("interactable")
		protein_baron.body_entered.connect(_on_protein_baron_entered)
	
	# The Blender
	var blender := get_node_or_null("BlenderZone")
	if blender:
		blender.add_to_group("interactable")
		blender.body_entered.connect(_on_blender_entered)
	
	# Violet's challenge
	var violet := get_node_or_null("VioletZone")
	if violet:
		violet.add_to_group("interactable")
		violet.body_entered.connect(_on_violet_entered)
	
	# Optional poster
	var poster := get_node_or_null("GymPosterZone")
	if poster:
		poster.add_to_group("interactable")
		poster.body_entered.connect(_on_poster_entered)
	
	# Training tip
	var tip := get_node_or_null("TrainingTipZone")
	if tip:
		tip.add_to_group("interactable")
		tip.body_entered.connect(_on_training_tip_entered)
	
	# Bentley moment
	var bentley_zone := get_node_or_null("BentleyMomentZone")
	if bentley_zone:
		bentley_zone.add_to_group("interactable")
		bentley_zone.body_entered.connect(_on_bentley_moment_entered)
	
	# Polaroid
	var polaroid_zone := get_node_or_null("PolaroidZone")
	if polaroid_zone:
		polaroid_zone.add_to_group("interactable")
		polaroid_zone.body_entered.connect(_on_polaroid_entered)

func _show_opening_dialogue() -> void:
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Violet", "text": "Jake Sully. In my underground. Looking for the Counterpunch technique." },
		{ "speaker": "Jake", "text": "Violet. Heard you teach a move that turns defense into knockout." },
		{ "speaker": "Violet", "text": "I teach it to people who earn it. Three opponents. My table. My rules." },
		{ "speaker": "Jake", "text": "Arm wrestling? That's it?" },
		{ "speaker": "Violet", "text": "It's never just arm wrestling. You'll see." },
		{ "speaker": "Bentley", "text": "*looks at the strength table, unimpressed*" }
	])

func _count_beaten() -> int:
	var count := 0
	if opponent_1_beaten:
		count += 1
	if opponent_2_beaten:
		count += 1
	if opponent_3_beaten:
		count += 1
	return count

func _on_big_mike_entered(body: Node) -> void:
	if body.is_in_group("player") and not opponent_1_beaten and not match_in_progress:
		if current_match != 0:
			QuestManager.set_objective("Beat the current opponent before moving to the next!", mission_id)
			return
		
		current_match = 1
		_start_arm_wrestle_match("Big Mike", "The bouncer who bounces back.")

func _on_protein_baron_entered(body: Node) -> void:
	if body.is_in_group("player") and not opponent_2_beaten and not match_in_progress:
		if not opponent_1_beaten:
			QuestManager.set_objective("Beat Big Mike first! Follow the table order.", mission_id)
			return
		if current_match != 1:
			QuestManager.set_objective("Beat the current opponent before moving to the next!", mission_id)
			return
		
		current_match = 2
		_start_arm_wrestle_match("Protein Baron", "90% whey, 10% ego.")

func _on_blender_entered(body: Node) -> void:
	if body.is_in_group("player") and not opponent_3_beaten and not match_in_progress:
		if not opponent_1_beaten or not opponent_2_beaten:
			QuestManager.set_objective("Beat the earlier opponents first!", mission_id)
			return
		if current_match != 2:
			QuestManager.set_objective("Beat the current opponent before moving to the next!", mission_id)
			return
		
		current_match = 3
		_start_arm_wrestle_match("The Blender", "He doesn't just win. He purees.")

func _start_arm_wrestle_match(opponent_name: String, opponent_tagline: String) -> void:
	match_in_progress = true
	
	DialogueManager.start_simple_dialogue([
		{ "speaker": opponent_name, "text": "You think you can take me, doc?" },
		{ "speaker": "Jake", "text": "I'm not here to think. I'm here to win." },
		{ "speaker": "Violet", "text": "Contestants ready. Winner takes the point." }
	])
	
	# Simple approach: Enter objective zone to win (can be expanded with timing bar minigame)
	QuestManager.set_objective("ARM WRESTLE: Stay in the zone! Use technique over strength!", mission_id)
	
	# Start a brief timer or wait for player to stay in zone
	_start_match_timer(opponent_name)

func _start_match_timer(opponent_name: String) -> void:
	# Create a timer for the match duration
	var match_timer := get_tree().create_timer(2.0)
	match_timer.timeout.connect(func(): _complete_match(opponent_name))

func _complete_match(opponent_name: String) -> void:
	match_in_progress = false
	AudioManager.play_sfx("success")
	
	match opponent_name:
		"Big Mike":
			opponent_1_beaten = true
			QuestManager.set_objective("Big Mike defeated! (%d/3) The Protein Baron awaits!" % _count_beaten(), mission_id)
			DialogueManager.start_simple_dialogue([
				{ "speaker": "Big Mike", "text": "No one's beaten me in three years..." },
				{ "speaker": "Jake", "text": "Fourth year's the charm." },
				{ "speaker": "Violet", "text": "One down. Don't get cocky." }
			])
		"Protein Baron":
			opponent_2_beaten = true
			QuestManager.set_objective("Protein Baron blended! (%d/3) The final opponent waits!" % _count_beaten(), mission_id)
			DialogueManager.start_simple_dialogue([
				{ "speaker": "Protein Baron", "text": "My macros! My beautiful macros!" },
				{ "speaker": "Jake", "text": "Your protein shake fund just became my victory lap." },
				{ "speaker": "Violet", "text": "Two down. The Blender doesn't lose gracefully." }
			])
		"The Blender":
			opponent_3_beaten = true
			QuestManager.set_objective("All three opponents beaten! Violet's challenge awaits at the champion's table!", mission_id)
			DialogueManager.start_simple_dialogue([
				{ "speaker": "The Blender", "text": "I... I didn't even break a sweat... wait, yes I did. All of it." },
				{ "speaker": "Jake", "text": "Told you. Technique over strength." },
				{ "speaker": "Violet", "text": "Impressive. But the real challenge was always me." }
			])

func _on_violet_entered(body: Node) -> void:
	if body.is_in_group("player") and not violet_beaten:
		if not opponent_1_beaten or not opponent_2_beaten or not opponent_3_beaten:
			var beaten := _count_beaten()
			QuestManager.set_objective("Beat all three opponents first! (%d/3 done)" % beaten, mission_id)
			
			if not violet_moment_shown:
				violet_moment_shown = true
				DialogueManager.start_simple_dialogue([
					{ "speaker": "Violet", "text": "You want the Counterpunch? Beat the table first. Three opponents. Then we talk." }
				])
			return
		
		# Start Violet's challenge
		_start_violet_challenge()

func _start_violet_challenge() -> void:
	violet_beaten = true
	
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Violet", "text": "You beat my table. Now prove you deserve my technique." },
		{ "speaker": "Jake", "text": "I'm ready." },
		{ "speaker": "Violet", "text": "Counterpunch isn't about hitting first. It's about making them miss, then making them pay." },
		{ "speaker": "Jake", "text": "Defense into offense. I understand." },
		{ "speaker": "Violet", "text": "No. You don't. Not yet. But you will." }
	])
	
	# Unlock Counterpunch
	GameState.player_upgrades["counterpunch"] = true
	AudioManager.play_sfx("unlock")
	
	QuestManager.set_objective("COUNTERPUNCH UNLOCKED! You can now counter enemy attacks! Exit through the alley!", mission_id)
	
	# Final Violet dialogue
	var final_timer := get_tree().create_timer(0.5)
	final_timer.timeout.connect(_show_violet_final_dialogue)

func _show_violet_final_dialogue() -> void:
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Violet", "text": "The Counterpunch is yours. Use it when an enemy attacks - time it right, and their strength becomes their weakness." },
		{ "speaker": "Jake", "text": "Thank you, Violet." },
		{ "speaker": "Violet", "text": "Don't thank me. Thank Sterling. Without his cruelty, none of us would be this strong." },
		{ "speaker": "Bentley", "text": "*respectful nod at Violet*" }
	])

func _on_poster_entered(body: Node) -> void:
	if body.is_in_group("player") and not poster_read:
		poster_read = true
		GameState.intel_points += 1
		
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Jake", "text": "'PROTEIN BARON'S 30-DAY BULK: Become the muscle you were meant to be.'" },
			{ "speaker": "Jake", "text": "'Day 1: Cry. Day 15: Cry harder. Day 30: Forget why you were crying because you're now mostly creatine.'" },
			{ "speaker": "Bentley", "text": "*confused head tilt*" },
			{ "speaker": "Jake", "text": "I know, buddy. The fitness industry has problems." }
		])
		
		QuestManager.set_objective("Gym poster read! +1 intel for psychological profiling!", mission_id)

func _on_training_tip_entered(body: Node) -> void:
	if body.is_in_group("player") and not training_tip_found:
		training_tip_found = true
		var zone := get_node_or_null("TrainingTipZone")
		if zone:
			zone.queue_free()
		GameState.intel_points += 1
		AudioManager.play_sfx("intel_collect")
		
		QuestManager.set_objective("Training tip found! +1 intel.", mission_id)

func _on_bentley_moment_entered(body: Node) -> void:
	if body.is_in_group("player") and not bentley_moment_shown:
		bentley_moment_shown = true
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Bentley", "text": "*spots a discarded protein bar wrapper, sniffs it*" },
			{ "speaker": "Jake", "text": "No, Bentley. Don't eat that." },
			{ "speaker": "Bentley", "text": "*disappointed woof, drops wrapper*" },
			{ "speaker": "Jake", "text": "I'll get you a real treat after we win. Promise." }
		])

func _on_polaroid_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var zone := get_node_or_null("PolaroidZone")
		if zone:
			zone.queue_free()
		CollectibleManager.collect_polaroid("arm_wrestling_polaroid")
		AudioManager.play_sfx("collect")
		QuestManager.set_objective("Victory photo captured! This belongs on the crew board.", mission_id)

func complete_level() -> void:
	if not opponent_1_beaten or not opponent_2_beaten or not opponent_3_beaten:
		var beaten := _count_beaten()
		QuestManager.set_objective("Only %d/3 opponents beaten. Beat them all, then face Violet!" % beaten, mission_id)
		return
	
	if not violet_beaten:
		QuestManager.set_objective("All opponents beaten! Now face Violet at the champion's table!", mission_id)
		return
	
	CollectibleManager.collect_polaroid("arm_wrestling_polaroid")
	super.complete_level()
