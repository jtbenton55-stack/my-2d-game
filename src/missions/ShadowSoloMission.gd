extends "res://src/missions/InteractiveMission.gd"

# The Shadow Solo Contract - Mission 6
# Stylish combat arena homage with Kiro and Jin
# Bentley is an "unimpressed spectator"

var trials_completed := {"kiro": false, "jin": false, "shadow_core": false}
var kiro_dialogue_triggered := false
var jin_dialogue_triggered := false
var all_trials_complete := false
var completion_dialogue_triggered := false
var reward_claimed := false

func _ready() -> void:
	super._ready()

	MissionMutationHelper.roll(get_mission_id(), {"trial_order_seed": [0, 1, 2]})
	spawn_poop_bags_at_global_positions([Vector2(320, 420), Vector2(580, 380), Vector2(720, 520)])

	_setup_kiro_dialogue()
	_setup_jin_dialogue()
	_setup_bentley_spectator()
	_setup_trials()

func _setup_kiro_dialogue() -> void:
	var kiro := get_node_or_null("KiroIntro")
	if kiro:
		var interact := kiro.get_node_or_null("InteractZone")
		if interact:
			interact.body_entered.connect(_on_kiro_triggered)
			interact.add_to_group("interactable")

func _on_kiro_triggered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if kiro_dialogue_triggered:
		return
	kiro_dialogue_triggered = true
	
	var kiro := get_node_or_null("KiroIntro")
	if kiro and kiro.has_method("start_dialogue"):
		kiro.start_dialogue()
		QuestManager.set_objective("Kiro awaits. Complete his speed trial in the west arena.", get_mission_id())

func _setup_jin_dialogue() -> void:
	var jin := get_node_or_null("JinIntro")
	if jin:
		var interact := jin.get_node_or_null("InteractZone")
		if interact:
			interact.body_entered.connect(_on_jin_triggered)
			interact.add_to_group("interactable")

func _on_jin_triggered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if jin_dialogue_triggered:
		return
	jin_dialogue_triggered = true
	
	var jin := get_node_or_null("JinIntro")
	if jin and jin.has_method("start_dialogue"):
		jin.start_dialogue()
		QuestManager.set_objective("Jin challenges you. Complete her precision trial in the east arena.", get_mission_id())

func _setup_bentley_spectator() -> void:
	var spectator := get_node_or_null("BentleySpectator")
	if spectator:
		spectator.body_entered.connect(_on_bentley_spectator_comment)

func _on_bentley_spectator_comment(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	# Bentley remains unimpressed - he's already visible here
	DialogueManager.show_dialogue("Bentley", "*looks at arena, looks at you, sighs* ...Woof.")

func _setup_trials() -> void:
	# Trials are handled through the objective system
	pass

func _on_required_entered(body: Node, zone: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	
	var zone_name := zone.name
	if zone_name == "Objective_Kiro":
		trials_completed["kiro"] = true
		DialogueManager.show_dialogue("Kiro", "Speed trial: cleared. Your reflexes are... acceptable.")
		DialogueManager.show_dialogue("Bentley", "*sniffs Kiro's shoe and walks away* ...")
		AudioManager.play_sfx("trial_complete")
	elif zone_name == "Objective_Jin":
		trials_completed["jin"] = true
		DialogueManager.show_dialogue("Jin", "Precision trial: passed. You move like water.")
		DialogueManager.show_dialogue("Bentley", "*licks paw* Woof.")
		AudioManager.play_sfx("trial_complete")
	elif zone_name == "Objective_ShadowCore":
		trials_completed["shadow_core"] = true
		DialogueManager.show_dialogue("Kiro", "The Shadow Core trial... you conquered the shadows themselves.")
		DialogueManager.show_dialogue("Jin", "We haven't seen that in years.")
		AudioManager.play_sfx("trial_complete")
	
	super._on_required_entered(body, zone)
	_check_all_trials()

func _check_all_trials() -> void:
	if all_trials_complete:
		return
	
	var complete: bool = trials_completed["kiro"] and trials_completed["jin"] and trials_completed["shadow_core"]
	if complete:
		all_trials_complete = true
		QuestManager.set_objective("All trials complete! Speak with Kiro and Jin for your reward.", get_mission_id())
		
		# Reveal reward zone
		var reward := get_node_or_null("RewardZone")
		if reward:
			reward.visible = true
			var visual := reward.get_node_or_null("Visual")
			if visual:
				visual.visible = true
			var label := reward.get_node_or_null("Label")
			if label:
				label.visible = true
		
		# Trigger completion dialogue
		EventBus.dialogue_ended.connect(_trigger_completion_dialogue, CONNECT_ONE_SHOT)

func _trigger_completion_dialogue() -> void:
	if completion_dialogue_triggered:
		return
	completion_dialogue_triggered = true
	
	var completion := get_node_or_null("CompletionDialogue")
	if completion and completion.has_method("start_dialogue"):
		completion.start_dialogue()
	
	# Bentley's final unimpressed comment
	EventBus.dialogue_ended.connect(_bentley_final_comment, CONNECT_ONE_SHOT)

func _bentley_final_comment() -> void:
	DialogueManager.show_dialogue("Bentley", "*finally gets up, tail wagging slightly at your success, then immediately tries to leave* Woof!")
	DialogueManager.show_dialogue("You", "He's saying 'good job, now let's go home.'")
	DialogueManager.show_dialogue("Jin", "...I think I like him.")

func complete_level() -> void:
	if not all_trials_complete:
		var remaining := []
		if not trials_completed["kiro"]:
			remaining.append("Kiro's speed trial")
		if not trials_completed["jin"]:
			remaining.append("Jin's precision trial")
		if not trials_completed["shadow_core"]:
			remaining.append("the Shadow Core")
		
		var remaining_text := " and ".join(remaining)
		QuestManager.set_objective("Complete " + remaining_text + " before leaving.", get_mission_id())
		DialogueManager.show_dialogue("Kiro", "The trials are not complete. We cannot let you pass.")
		return
	
	# Apply dash upgrade reward
	if not reward_claimed:
		reward_claimed = true
		GameState.set_meta("shadow_dash_unlocked", true)
		GameState.intel_points += 3
		AudioManager.play_sfx("upgrade_get")
	
	# Final shadow bow
	DialogueManager.show_dialogue("Kiro", "The shadows will remember you. Travel with pride.")
	DialogueManager.show_dialogue("Bentley", "*already at the exit, waiting impatiently* ...Woof!")
	
	super.complete_level()
