extends "res://src/missions/InteractiveMission.gd"

# The Clean Job - A mission where cleanliness reveals secrets
# Purpose: Cleanliness as tactical advantage

var mirror_cleaned := false
var case_cleaned := false
var vent_cleaned := false
var evidence_wiped := false
var showroom_code_found := false
var bentley_moment_shown := false
var jinx_moment_shown := false
var exit_unlocked := false

func _ready() -> void:
	mission_id = "clean_job"
	objective_text = "Clean the showroom surfaces to reveal Sterling's security code."
	guard_count = 3
	completion_item_name = "clean surface"
	completion_line = "All surfaces cleaned. The code is yours. Exit through the service door."
	missing_item_line = "Bentley refuses to leave while the showroom is this filthy."
	super._ready()

	spawn_poop_bags_at_global_positions([Vector2(220, 740), Vector2(520, 340), Vector2(780, 620)])

	# Set up interactable zones
	_setup_interactables()
	
	# Show opening dialogue
	_show_opening_dialogue()

func _setup_interactables() -> void:
	# Mirror zone - reveals keypad code
	var mirror_zone := get_node_or_null("MirrorZone")
	if mirror_zone:
		mirror_zone.add_to_group("interactable")
		mirror_zone.body_entered.connect(_on_mirror_body_entered)
	
	# Display case - reveals fingerprints
	var case_zone := get_node_or_null("DisplayCaseZone")
	if case_zone:
		case_zone.add_to_group("interactable")
		case_zone.body_entered.connect(_on_case_body_entered)
	
	# Vent - clean so Bentley can enter
	var vent_zone := get_node_or_null("VentZone")
	if vent_zone:
		vent_zone.add_to_group("interactable")
		vent_zone.body_entered.connect(_on_vent_body_entered)
	
	# Optional evidence wipe
	var evidence_zone := get_node_or_null("EvidenceWipeZone")
	if evidence_zone:
		evidence_zone.add_to_group("interactable")
		evidence_zone.body_entered.connect(_on_evidence_body_entered)
	
	# Optional intel
	var intel_zone := get_node_or_null("OptionalIntelZone")
	if intel_zone:
		intel_zone.add_to_group("interactable")
		intel_zone.body_entered.connect(_on_intel_body_entered)
	
	# Friend moment - Jinx appears
	var jinx_zone := get_node_or_null("JinxZone")
	if jinx_zone:
		jinx_zone.add_to_group("interactable")
		jinx_zone.body_entered.connect(_on_jinx_body_entered)
	
	# Bentley moment zone
	var bentley_zone := get_node_or_null("BentleyMomentZone")
	if bentley_zone:
		bentley_zone.add_to_group("interactable")
		bentley_zone.body_entered.connect(_on_bentley_moment_entered)
	
	# Polaroid pickup
	var polaroid_zone := get_node_or_null("PolaroidZone")
	if polaroid_zone:
		polaroid_zone.add_to_group("interactable")
		polaroid_zone.body_entered.connect(_on_polaroid_body_entered)

func _show_opening_dialogue() -> void:
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Jake", "text": "Sterling's luxury showroom. The code to his private elevator is hidden somewhere in the dust." },
		{ "speaker": "Bentley", "text": "*sniffs disdainfully at a smudge on the floor*" },
		{ "speaker": "Jake", "text": "I know, buddy. We'll clean this place until it talks." }
	])

func _on_mirror_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not mirror_cleaned:
		mirror_cleaned = true
		AudioManager.play_sfx("cleaning")
		QuestManager.set_objective("Mirror cleaned! A reflection reveals: 7-4-2...", mission_id)
		
		# Check for card effect
		if GameState.has_selected_card("clorox_wipe_protocol"):
			QuestManager.set_objective("Clorox Protocol active! Full code revealed: 7-4-2-9-1", mission_id)
			showroom_code_found = true
			_check_all_cleaned()
		
		_show_mirror_dialogue()
		_update_mirror_visual()

func _show_mirror_dialogue() -> void:
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Jake", "text": "There it is. Sterling's vanity left fingerprints in the mirror dust." },
		{ "speaker": "Bentley", "text": "*approving woof at the now-visible numbers*" },
		{ "speaker": "Jake", "text": "7-4-2... need the rest of the code." }
	])

func _on_case_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not case_cleaned:
		case_cleaned = true
		AudioManager.play_sfx("cleaning")
		QuestManager.set_objective("Display case cleaned! Fingerprints show: ...9-1", mission_id)
		
		if mirror_cleaned:
			showroom_code_found = true
			QuestManager.set_objective("Full code confirmed: 7-4-2-9-1. Clean the vent for Bentley.", mission_id)
		
		_show_case_dialogue()
		_update_case_visual()
		_check_all_cleaned()

func _show_case_dialogue() -> void:
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Jake", "text": "Sterling's fingerprints on the display glass. The man touches everything he owns." },
		{ "speaker": "Bentley", "text": "*sniffs the case, then sneezes dramatically*" },
		{ "speaker": "Jake", "text": "Bless you. Also... 9-1. That's the end of the code." }
	])

func _on_vent_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not vent_cleaned:
		vent_cleaned = true
		AudioManager.play_sfx("cleaning")
		QuestManager.set_objective("Vent cleaned! Bentley can now access the crawlspace.", mission_id)
		
		_show_vent_dialogue()
		_update_vent_visual()
		_check_all_cleaned()

func _show_vent_dialogue() -> void:
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Jake", "text": "Vent's clear. Bentley, can you fit?" },
		{ "speaker": "Bentley", "text": "*proud woof, squeezes into the vent*" },
		{ "speaker": "Jake", "text": "Good dog. Find me something useful in there." }
	])

func _on_evidence_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not evidence_wiped:
		evidence_wiped = true
		AudioManager.play_sfx("cleaning")
		GameState.intel_points += 1
		QuestManager.set_objective("Evidence wiped! +1 intel. Our visit remains secret.", mission_id)
		
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Jake", "text": "Wiped our footprints from the security log. Sterling will never know we were here." },
			{ "speaker": "Bentley", "text": "*satisfied grunt*" }
		])
		_update_evidence_visual()

func _on_intel_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var intel_zone := get_node_or_null("OptionalIntelZone")
		if intel_zone:
			intel_zone.queue_free()
		GameState.intel_points += 1
		AudioManager.play_sfx("intel_collect")
		QuestManager.set_objective("Hidden showroom records found! +1 intel.", mission_id)

func _on_jinx_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not jinx_moment_shown:
		jinx_moment_shown = true
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Jinx", "text": "Fancy meeting you here, Jake. Heard you were doing some... spring cleaning." },
			{ "speaker": "Jake", "text": "Jinx. You after Sterling's codes too?" },
			{ "speaker": "Jinx", "text": "I'm after justice. But I'll take the codes as a down payment." },
			{ "speaker": "Jake", "text": "Help me clean this vent and I'll share what we find." },
			{ "speaker": "Jinx", "text": "Deal. But only because I hate dust more than I hate you." }
		])

func _on_bentley_moment_entered(body: Node) -> void:
	if body.is_in_group("player") and not bentley_moment_shown:
		bentley_moment_shown = true
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Bentley", "text": "*emerges from vent with a torn receipt in mouth*" },
			{ "speaker": "Jake", "text": "What'd you find, buddy?" },
			{ "speaker": "Bentley", "text": "*drops receipt, wags tail*" },
			{ "speaker": "Jake", "text": "Sterling's dry cleaning bill. $800 for one suit. The man has priorities." }
		])

func _on_polaroid_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var polaroid_zone := get_node_or_null("PolaroidZone")
		if polaroid_zone:
			polaroid_zone.queue_free()
		CollectibleManager.collect_polaroid("clean_job_polaroid")
		AudioManager.play_sfx("collect")
		QuestManager.set_objective("Polaroid secured! The cleanest heist photo ever taken.", mission_id)

func _check_all_cleaned() -> void:
	if mirror_cleaned and case_cleaned and vent_cleaned:
		exit_unlocked = true
		if showroom_code_found:
			QuestManager.set_objective("Showroom code 7-4-2-9-1 confirmed. Exit through the service door!", mission_id)
		else:
			QuestManager.set_objective("All surfaces cleaned. The exit is open.", mission_id)
		
		# Show completion dialogue
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Jake", "text": "This showroom is spotless and we've got the code. Time to go." },
			{ "speaker": "Bentley", "text": "*happy bark, looking pleased at the gleaming surfaces*" }
		])

func _update_mirror_visual() -> void:
	var mirror_visual := get_node_or_null("MirrorVisual")
	if mirror_visual:
		mirror_visual.modulate = Color(0.9, 0.95, 1.0, 0.8)

func _update_case_visual() -> void:
	var case_visual := get_node_or_null("DisplayCaseVisual")
	if case_visual:
		case_visual.modulate = Color(1.0, 1.0, 1.0, 0.95)

func _update_vent_visual() -> void:
	var vent_visual := get_node_or_null("VentVisual")
	if vent_visual:
		vent_visual.modulate = Color(0.7, 0.7, 0.75, 1.0)

func _update_evidence_visual() -> void:
	var evidence_visual := get_node_or_null("EvidenceVisual")
	if evidence_visual:
		evidence_visual.visible = false

func complete_level() -> void:
	if not mirror_cleaned or not case_cleaned or not vent_cleaned:
		var missing := []
		if not mirror_cleaned:
			missing.append("mirror")
		if not case_cleaned:
			missing.append("display case")
		if not vent_cleaned:
			missing.append("vent")
		QuestManager.set_objective("Still need to clean: " + ", ".join(missing), mission_id)
		return
	
	# Collect polaroid if not already collected
	CollectibleManager.collect_polaroid("clean_job_polaroid")
	super.complete_level()
