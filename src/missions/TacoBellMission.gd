extends "res://src/levels/LevelBase.gd"

enum MissionStep {
	INTRO,
	INVESTIGATE,
	SNIFF_TRAIL,
	STEALTH_YARD,
	GARAGE_PUZZLE,
	RECOVER_BAG,
	ESCAPE,
	COMPLETE
}

var current_step: int = MissionStep.INTRO
var bag_collected := false
var garage_door_opened := false
var spotted_by_guard := false
var intel_receipt_found := false
var intel_dumpster_found := false
var scent_trail_complete := false

const GARAGE_CODE_RECEIPT := "7429"
const GARAGE_CODE_GUESS_1 := "1234"
const GARAGE_CODE_GUESS_2 := "0000"
const GARAGE_CODE_GUESS_3 := "7429"

func _ready() -> void:
	mission_id = "taco_bell_drop"
	objective_text = "Meet Louis in the alley."
	guard_count = 0
	super._ready()
	
	# Connect bag pickup
	var bag := get_node_or_null("BagPickupZone")
	if bag:
		bag.add_to_group("interactable")
		if not bag.body_entered.is_connected(_on_bag_body_entered):
			bag.body_entered.connect(_on_bag_body_entered)
	
	# Connect Louis dialogue trigger - listen to EventBus for dialogue end
	if not EventBus.dialogue_ended.is_connected(_on_louis_dialogue_finished):
		EventBus.dialogue_ended.connect(_on_louis_dialogue_finished)
	
	# Connect scent trail markers
	_setup_scent_trail()
	
	# Connect garage puzzle
	var garage := get_node_or_null("GaragePuzzleTrigger")
	if garage:
		garage.add_to_group("interactable")
		if garage.has_signal("puzzle_solved"):
			if not garage.puzzle_solved.is_connected(_on_garage_solved):
				garage.puzzle_solved.connect(_on_garage_solved)
		if garage.has_signal("puzzle_failed"):
			if not garage.puzzle_failed.is_connected(_on_garage_failed):
				garage.puzzle_failed.connect(_on_garage_failed)
	
	# Connect intel pickups - node is named "ReceiptIntel" not "ReceiptPickup"
	var receipt := get_node_or_null("ReceiptIntel")
	if receipt:
		receipt.add_to_group("interactable")
		if receipt.has_signal("intel_collected"):
			if not receipt.intel_collected.is_connected(_on_receipt_collected):
				receipt.intel_collected.connect(_on_receipt_collected)
	
	var dumpster_intel := get_node_or_null("DumpsterIntel")
	if dumpster_intel:
		dumpster_intel.add_to_group("interactable")
		if dumpster_intel.has_signal("intel_collected"):
			if not dumpster_intel.intel_collected.is_connected(_on_dumpster_intel_collected):
				dumpster_intel.intel_collected.connect(_on_dumpster_intel_collected)
	
	# Connect yard entrance
	var yard := get_node_or_null("YardEntrance")
	if yard:
		if yard.has_signal("player_entered"):
			if not yard.player_entered.is_connected(_on_yard_entered):
				yard.player_entered.connect(_on_yard_entered)
	
	# Connect exit zone - use body_entered directly
	var exit_zone := get_node_or_null("ExitZone")
	if exit_zone:
		if not exit_zone.body_entered.is_connected(_on_exit_zone_body_entered):
			exit_zone.body_entered.connect(_on_exit_zone_body_entered)
	
	# Start the mission after a brief delay
	call_deferred("_start_mission")

func _spawn_default_enemies() -> void:
	var enemy_scene: PackedScene = load("res://scenes/characters/guard.tscn")
	if enemy_scene == null:
		return
	var yard_guard: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	add_child(yard_guard)
	var spawn_pt := get_node_or_null("GoonSpawns/GoonSpawn1") as Node2D
	if spawn_pt:
		yard_guard.global_position = spawn_pt.global_position
	else:
		yard_guard.global_position = Vector2(950, 280)
	if yard_guard.has_signal("spotted_player"):
		if not yard_guard.spotted_player.is_connected(_on_guard_spotted_player):
			yard_guard.spotted_player.connect(_on_guard_spotted_player)

func _advance_to(step: int) -> void:
	current_step = step
	match step:
		MissionStep.INTRO:
			QuestManager.set_objective("Meet Louis in the alley. Find out what happened to the bag.", mission_id)
			_show_louis_dialogue()
		
		MissionStep.INVESTIGATE:
			QuestManager.set_objective("Search the alley. Look behind the dumpster for clues.", mission_id)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.SNIFF_TRAIL:
			QuestManager.set_objective("Bentley smells something. Follow the scent trail.", mission_id)
			AudioManager.play_sfx("objective_update")
			_activate_scent_trail()
		
		MissionStep.STEALTH_YARD:
			if spotted_by_guard:
				QuestManager.set_objective("GUARDS SPOTTED YOU! Move fast to the garage!", mission_id)
				AudioManager.play_sfx("alert")
			else:
				QuestManager.set_objective("Sneak through the yard. Avoid the guards.", mission_id)
				AudioManager.play_sfx("objective_update")
		
		MissionStep.GARAGE_PUZZLE:
			QuestManager.set_objective("East end: gray EMPLOYEE GARAGE. Press E on the green KEYPAD. Code hint: receipt near yard (7429) or pick from the menu.", mission_id)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.RECOVER_BAG:
			QuestManager.set_objective("Bag is inside the east garage (brown rectangle). Walk onto it or press E to grab it, then head to the green EXIT near Louis.", mission_id)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.ESCAPE:
			QuestManager.set_objective("Louis is waiting at the exit. Don't get caught!", mission_id)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.COMPLETE:
			QuestManager.set_objective("Mission complete! Heading back to the hideout.", mission_id)

func _start_mission() -> void:
	_advance_to(MissionStep.INTRO)

func _show_louis_dialogue() -> void:
	# Auto-start dialogue on mission begin
	var louis := get_node_or_null("LouisDialogueTrigger")
	if louis and louis.has_method("start_dialogue"):
		louis.start_dialogue()

func _on_louis_dialogue_finished() -> void:
	# Only advance if we're still in intro
	if current_step == MissionStep.INTRO:
		_advance_to(MissionStep.INVESTIGATE)

func _setup_scent_trail() -> void:
	for i in range(1, 5):
		var marker := get_node_or_null("ScentMarker" + str(i))
		if marker:
			marker.add_to_group("scent_trail")
			if marker.has_signal("sniffed"):
				marker.sniffed.connect(_on_scent_marker_sniffed.bind(i))
			marker.visible = false

func _activate_scent_trail() -> void:
	for marker in get_tree().get_nodes_in_group("scent_trail"):
		marker.visible = true
	
	# Bentley barks to indicate trail
	var bentley := get_tree().get_first_node_in_group("bentley")
	if bentley and bentley.has_method("sniff"):
		bentley.sniff()

var scent_markers_found := 0

func _on_scent_marker_sniffed(_marker_index: int) -> void:
	scent_markers_found += 1
	AudioManager.play_sfx("bentley_sniff")
	
	if scent_markers_found >= 3:
		scent_trail_complete = true
		if current_step == MissionStep.SNIFF_TRAIL:
			_advance_to(MissionStep.STEALTH_YARD)

func _on_yard_entered() -> void:
	if current_step == MissionStep.SNIFF_TRAIL and scent_trail_complete:
		_advance_to(MissionStep.STEALTH_YARD)
	elif current_step < MissionStep.STEALTH_YARD:
		# Player found yard early, skip to stealth
		_advance_to(MissionStep.STEALTH_YARD)

func _on_guard_spotted_player() -> void:
	if not spotted_by_guard:
		spotted_by_guard = true
		if current_step == MissionStep.STEALTH_YARD or current_step == MissionStep.GARAGE_PUZZLE:
			# Fail-forward mechanic: change objective instead of hard fail
			QuestManager.set_objective("GUARDS SPOTTED YOU! Move fast to the garage!", mission_id)
			AudioManager.play_sfx("alert")

func _on_receipt_collected() -> void:
	intel_receipt_found = true
	QuestManager.set_objective("Receipt found: Garage code is " + GARAGE_CODE_RECEIPT + ".", mission_id)
	AudioManager.play_sfx("intel_pickup")

func _on_dumpster_intel_collected() -> void:
	intel_dumpster_found = true
	AudioManager.play_sfx("intel_pickup")

func _on_garage_solved() -> void:
	garage_door_opened = true
	AudioManager.play_sfx("door_open")
	
	# Reveal bag visuals only — keep Area2D active for collision (hidden Area2D can stop overlap detection).
	var bag := get_node_or_null("BagPickupZone")
	if bag:
		var vis := bag.get_node_or_null("BagVisual")
		if vis:
			vis.visible = true
		var lbl := bag.get_node_or_null("BagLabel")
		if lbl:
			lbl.text = "Louis's bag — walk onto it or press E"
			lbl.visible = true
	
	_advance_to(MissionStep.RECOVER_BAG)

func _on_garage_failed() -> void:
	# Wrong code - guards get alerted
	QuestManager.set_objective("Wrong code! The noise attracted guards!", mission_id)
	_on_guard_spotted_player()

func try_collect_bag_from_interact(body: Node) -> void:
	_on_bag_body_entered(body)

func _on_bag_body_entered(body: Node) -> void:
	if body.is_in_group("player") and current_step >= MissionStep.RECOVER_BAG:
		bag_collected = true
		QuestManager.set_objective("Bag secured! Get to the exit.", mission_id)
		
		# Hide bag visual
		var bag_zone := get_node_or_null("BagPickupZone")
		if bag_zone:
			var visual := bag_zone.get_node_or_null("BagVisual")
			if visual:
				visual.visible = false
			var label := bag_zone.get_node_or_null("BagLabel")
			if label:
				label.visible = false
		
		AudioManager.play_sfx("item_pickup")
		
		# Show first Sterling clue note
		_show_sterling_clue()
		
		_advance_to(MissionStep.ESCAPE)

func _show_sterling_clue() -> void:
	var note := get_node_or_null("SterlingClueNote")
	if note and note.has_method("show_note"):
		note.show_note()

func _on_exit_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if not bag_collected:
			QuestManager.set_objective("Bentley insists: Grab Louis's bag first!", mission_id)
			AudioManager.play_sfx("bentley_bark")
			return
		complete_level()

func complete_level() -> void:
	if is_complete or is_failed:
		return
	
	# Collect polaroid on completion
	CollectibleManager.collect_polaroid("taco_bell_polaroid")
	
	# Grant extra intel for optional objectives
	if intel_receipt_found and intel_dumpster_found:
		GameState.intel_points += 2
		EventBus.objective_updated.emit("Bonus: All intel found! +2 intel points.")
	
	is_complete = true
	var result := GameState.complete_mission(get_mission_id())
	SceneManager.show_mission_result(result)

func get_garage_code_options() -> Array[String]:
	if intel_receipt_found:
		return [GARAGE_CODE_RECEIPT]
	return [GARAGE_CODE_GUESS_1, GARAGE_CODE_GUESS_2, GARAGE_CODE_GUESS_3]

func is_garage_code_valid(code: String) -> bool:
	return code == GARAGE_CODE_RECEIPT
