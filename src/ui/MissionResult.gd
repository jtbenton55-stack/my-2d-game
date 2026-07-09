extends Control

@onready var result_scroll: ScrollContainer = $Panel/ScrollContainer
@onready var result_label: Label = $Panel/ScrollContainer/ResultLabel
@onready var title_label: Label = $TitleLabel
@onready var continue_button: Button = $ContinueButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_update_result_display()
	continue_button.grab_focus()

func _update_result_display() -> void:
	var result: Dictionary = GameState.last_mission_result
	if result.size() == 0:
		result_label.text = "Mission completed!"
		return
	
	var title: String = String(result.get("title", "Mission Complete"))
	var subtitle: String = String(result.get("subtitle", ""))
	var rewards: Array = Array(result.get("rewards", []))
	var success: bool = result.get("success", false) == true
	var rank: String = String(result.get("rank", ""))
	continue_button.text = String(result.get("continue_label", "Return to Hideout"))
	
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4, 1) if success else Color(1, 0.72, 0.35, 1))
	AudioManager.play_music("victory" if success else "cozy_hideout")
	
	var text := subtitle + "\n\n"
	var mission_name := String(result.get("mission_name", ""))
	if mission_name != "":
		text += "Mission: " + mission_name + "\n"
	if success and rank != "":
		text += "Mission Rank: " + rank + "\n"
	var poop_status: Dictionary = result.get("poop_bag_status", {}) as Dictionary
	if not poop_status.is_empty():
		text += String(poop_status.get("line", "")) + "\n"
	text += "\n"
	
	if rewards.size() > 0:
		text += "Progress:\n"
		for reward in rewards:
			text += "- " + str(reward) + "\n"

	var evidence_clues: Array = Array(result.get("evidence_clues", []))
	if not evidence_clues.is_empty():
		text += "\nEvidence Board:\n"
		for clue in evidence_clues:
			if clue is Dictionary:
				text += "- %s: %s\n" % [String(clue.get("title", clue.get("clue_id", ""))), String(clue.get("description", ""))]

	var next_steps: Array = Array(result.get("next_steps", []))
	if not next_steps.is_empty():
		text += "\nNext:\n"
		for step in next_steps:
			text += "- " + String(step) + "\n"

	var investigation: Dictionary = result.get("investigation_report", {})
	if not investigation.is_empty():
		text += "\n=== INVESTIGATION REPORT ===\n"
		text += "%s\n" % String(investigation.get("headline", ""))
		text += "Prime suspect: %s\n" % String(investigation.get("prime_suspect", "unknown"))
		for line in Array(investigation.get("lines", [])):
			text += "- %s\n" % String(line)
		var heat_delta := int(investigation.get("heat_delta", 0))
		if heat_delta > 0:
			text += "Venue heat: +%d\n" % heat_delta
		else:
			text += "Venue heat: unchanged\n"

	var paper_trail: Dictionary = result.get("paper_trail", {})
	if not paper_trail.is_empty():
		text += "\nPaper Trail:\n"
		text += "- %s\n" % String(paper_trail.get("result_line", "No paper-trail summary."))
		text += "- Active: %d  Cleaned: %d  Redirected: %d\n" % [
			int(paper_trail.get("active_events", 0)),
			int(paper_trail.get("cleaned_events", 0)),
			int(paper_trail.get("redirected_events", 0)),
		]

	var social_stealth: Dictionary = result.get("social_stealth", {})
	if not social_stealth.is_empty():
		text += "\nSocial Stealth:\n"
		text += "- State: %s\n" % String(result.get("social_stealth_state", "unproven")).capitalize()
		text += "- Cover stories: %d  Credentials: %d  Passed: %d  Questioned: %d\n" % [
			int(social_stealth.get("cover_story_count", 0)),
			int(social_stealth.get("credential_count", 0)),
			int(social_stealth.get("inspections_passed", 0)),
			int(social_stealth.get("inspections_failed", 0)),
		]
		text += "- Professionalism: %d  Cleanliness: %d\n" % [
			int(social_stealth.get("professionalism", 0)),
			int(social_stealth.get("cleanliness", 0)),
		]

	var encounter: Dictionary = result.get("encounter", {})
	if not encounter.is_empty():
		text += "\nEncounter Challenge:\n"
		text += "- State: %s  Phase: %s\n" % [String(result.get("encounter_state", "unstarted")).capitalize(), String(encounter.get("current_phase_id", ""))]
		var route_label := String(encounter.get("last_route_label", encounter.get("last_route_id", "")))
		if route_label.strip_edges() != "":
			text += "- Route: %s\n" % route_label
		var route_style := String(encounter.get("last_route_style_label", ""))
		if route_style.strip_edges() != "":
			text += "- Style: %s\n" % route_style
		var meters: Dictionary = encounter.get("meters", {})
		for meter_id in meters.keys():
			var meter: Dictionary = meters.get(meter_id, {})
			text += "- %s: %d (%s)\n" % [String(meter.get("display_name", meter_id)), int(meter.get("value", 0)), String(meter.get("status", "stable"))]

	var reactive_npc: Dictionary = result.get("reactive_npc", {})
	if not reactive_npc.is_empty():
		text += "\nReactive NPC Consequences:\n"
		text += "- State: %s\n" % String(result.get("reactive_npc_state", "quiet")).capitalize()
		text += "- Signals: %d  Reactions: %d  Authority reports: %d\n" % [
			int(reactive_npc.get("signal_count", 0)),
			int(reactive_npc.get("reaction_count", 0)),
			int(reactive_npc.get("authority_reports", 0)),
		]
		text += "- LimboAI adapter used: %s\n" % ("yes" if bool(reactive_npc.get("limbo_adapter_used", false)) else "no")
	
	if not success:
		text += "\nJake: As your doctor, I recommend fewer rooftop fistfights.\n"
		text += "Bentley refuses to discuss it, but stays close.\n"
	
	text += "\nTotal Intel: %d" % GameState.intel_points
	
	if success and GameState.crew_members.size() > 2:
		text += "\n\nCrew members: %d" % GameState.crew_members.size()
	
	result_label.text = text
	result_scroll.scroll_vertical = 0

func _on_continue_pressed() -> void:
	GameState.last_mission_result = {}
	SceneManager.return_to_hideout()
