extends "res://src/levels/LevelBase.gd"

enum MissionStep {
	INTRO,
	INVESTIGATE,
	SNIFF_TRAIL,
	STEALTH_YARD,
	ACCESS_PREP,
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
var keycard_found := false
var alarm_disabled := false
var alarm_tripped := false
var used_service_route := false
var decoy_bag_revealed := false
var secret_smiskis_found := false
var hunter_guard_spawned := false
var legal_eyes_used := false

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
	
	var keycard := get_node_or_null("KeycardIntel")
	if keycard:
		keycard.add_to_group("interactable")
		if keycard.has_signal("intel_collected"):
			if not keycard.intel_collected.is_connected(_on_keycard_collected):
				keycard.intel_collected.connect(_on_keycard_collected)

	var alarm_panel := get_node_or_null("AlarmPanel")
	if alarm_panel:
		alarm_panel.add_to_group("interactable")
		if alarm_panel.has_signal("intel_collected"):
			if not alarm_panel.intel_collected.is_connected(_on_alarm_panel_used):
				alarm_panel.intel_collected.connect(_on_alarm_panel_used)

	var service_door := get_node_or_null("ServiceDoorTrigger")
	if service_door:
		service_door.add_to_group("interactable")
		if service_door.has_signal("activated"):
			if not service_door.activated.is_connected(_on_service_door_used):
				service_door.activated.connect(_on_service_door_used)
	
	var trip_zone := get_node_or_null("AlarmTripZone")
	if trip_zone:
		if not trip_zone.body_entered.is_connected(_on_alarm_trip_zone_entered):
			trip_zone.body_entered.connect(_on_alarm_trip_zone_entered)

	if not EventBus.polaroid_collected.is_connected(_on_polaroid_collected):
		EventBus.polaroid_collected.connect(_on_polaroid_collected)
	
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
	
	_apply_diamond_year_highlights()
	# Start the mission after a brief delay (before passive card HUD pings)
	call_deferred("_start_mission")
	call_deferred("_announce_passive_cards")

func _spawn_default_enemies() -> void:
	var enemy_scene: PackedScene = load("res://scenes/characters/guard.tscn")
	if enemy_scene == null:
		return
	var path_a := get_node_or_null("GuardPath1") as Path2D
	var path_b := get_node_or_null("GuardPath2") as Path2D
	var spawn1 := get_node_or_null("GoonSpawns/GoonSpawn1") as Node2D
	var spawn2 := get_node_or_null("GoonSpawns/GoonSpawn2") as Node2D
	_spawn_yard_guard(enemy_scene, spawn1, path_a, Vector2(900, 250))
	_spawn_yard_guard(enemy_scene, spawn2, path_b, Vector2(1100, 400))

func _spawn_yard_guard(packed: PackedScene, spawn: Node2D, path: Path2D, fallback_pos: Vector2) -> void:
	var yard_guard = packed.instantiate()
	if yard_guard == null:
		return
	add_child(yard_guard)
	if spawn:
		yard_guard.global_position = spawn.global_position
	else:
		yard_guard.global_position = fallback_pos
	if yard_guard.has_method("assign_patrol_path"):
		yard_guard.assign_patrol_path(path)
	if yard_guard.has_signal("spotted_player") and not yard_guard.spotted_player.is_connected(_on_guard_spotted_player):
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

		MissionStep.ACCESS_PREP:
			QuestManager.set_objective("Micro-objectives: get the blue keycard and disable the alarm panel. Alternate route: open the service door with the keycard.", mission_id)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.GARAGE_PUZZLE:
			QuestManager.set_objective("Use keypad route at the garage (7429). If alarm is active, this may trip security.", mission_id)
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
	if CardManager.is_selected("polaroid_proof"):
		intel_receipt_found = true
		EventBus.card_triggered.emit("polaroid_proof", "active", "Receipt evidence in hand.")
	_advance_to(MissionStep.INTRO)

func _apply_diamond_year_highlights() -> void:
	if not CardEffects.can_see_loot_through_walls():
		return
	var bag_vis := get_node_or_null("BagPickupZone/BagVisual") as CanvasItem
	var smiski_vis := get_node_or_null("SmiskiPickup/SmiskiVisual") as CanvasItem
	if bag_vis:
		bag_vis.modulate = Color(0.35, 1.0, 1.0, 1.0)
	if smiski_vis:
		smiski_vis.modulate = Color(1.0, 0.45, 0.95, 1.0)
	var real_spawn := get_node_or_null("RealBagSpawn") as Node2D
	if real_spawn:
		EventBus.show_objective_marker.emit(true, real_spawn.global_position)
	EventBus.card_triggered.emit("diamond_a_year", "active", "X-ray sight on loot.")

func _announce_passive_cards() -> void:
	var infos := {
		"jakes_resident_orders": "Bonus HP and med kit passive.",
		"doms_getaway_keys": "Movement speed boost.",
		"yordano_bass_drop": "Movement speed boost.",
		"persian_tea_focus": "Stealth speed tuning.",
		"fish_treat_focus": "Bentley meter recharges faster.",
		"two_letters_away": "Bentley meter bonus.",
		"bryce_swiss_timing": "Bark radius bonus.",
		"stationery_queen": "Guards detect you slower.",
		"violet_counterpunch": "Melee hits harder.",
		"jc_london_contact": "Ability cooldowns shorter.",
	}
	for cid in infos.keys():
		if CardManager.is_selected(cid):
			EventBus.card_triggered.emit(cid, "active", infos[cid])

func _try_mere_legal_bypass() -> bool:
	if legal_eyes_used:
		return false
	if not CardEffects.has_legal_protection():
		return false
	legal_eyes_used = true
	EventBus.card_triggered.emit("mere_legal_eyes", "used", "Mere argued the alarm down.")
	return true

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
		_play_reactive_dialogue([
			{"speaker": "Bentley", "text": "*sharp bark* This trail splits. One scent is fake."},
			{"speaker": "Parmida", "text": "Great. We follow the one that smells like panic."}
		])
		if current_step == MissionStep.SNIFF_TRAIL:
			_advance_to(MissionStep.ACCESS_PREP)

func _on_yard_entered() -> void:
	if current_step == MissionStep.SNIFF_TRAIL and scent_trail_complete:
		_advance_to(MissionStep.ACCESS_PREP)
	elif current_step < MissionStep.ACCESS_PREP:
		# Player found yard early, skip to stealth
		_advance_to(MissionStep.ACCESS_PREP)

func _on_guard_spotted_player() -> void:
	if not spotted_by_guard:
		spotted_by_guard = true
		if current_step == MissionStep.STEALTH_YARD or current_step == MissionStep.ACCESS_PREP or current_step == MissionStep.GARAGE_PUZZLE:
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
	if current_step == MissionStep.INVESTIGATE:
		_advance_to(MissionStep.SNIFF_TRAIL)

func _on_keycard_collected(_intel_id := "") -> void:
	keycard_found = true
	EventBus.objective_updated.emit("Keycard acquired. Service door route unlocked.")
	_play_reactive_dialogue([
		{"speaker": "Louis", "text": "Nice. That card opens the side service door."}
	])
	_try_advance_from_access_prep()

func _on_alarm_panel_used(_intel_id := "") -> void:
	alarm_disabled = true
	EventBus.objective_updated.emit("Alarm panel disabled. Security won't auto-trigger.")
	AudioManager.play_sfx("objective_update")
	_try_advance_from_access_prep()

func _on_service_door_used() -> void:
	if not keycard_found and CardEffects.has_delivery_route():
		used_service_route = true
		garage_door_opened = true
		EventBus.card_triggered.emit("louis_delivery_route", "used", "Louis waved you through the service door.")
		_play_reactive_dialogue([
			{"speaker": "Louis", "text": "Service route works. That's our quiet entry."}
		])
		_on_garage_solved()
		return
	if not keycard_found:
		_play_reactive_dialogue([
			{"speaker": "Parmida", "text": "Locked. We need a keycard for this door."}
		])
		return
	used_service_route = true
	garage_door_opened = true
	_play_reactive_dialogue([
		{"speaker": "Louis", "text": "Service route works. That's our quiet entry."}
	])
	_on_garage_solved()

func _on_alarm_trip_zone_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if alarm_tripped:
		return
	if keycard_found and alarm_disabled:
		return
	if _try_mere_legal_bypass():
		return
	_trip_security("Crossed a live security lane.")

func _trip_security(reason: String) -> void:
	if alarm_tripped:
		return
	alarm_tripped = true
	QuestManager.set_objective("SECURITY TRIPPED: " + reason + " Guards are moving faster!", mission_id)
	AudioManager.play_sfx("alert")
	_play_reactive_dialogue([
		{"speaker": "Louis", "text": "Alarm is hot now. Move, move, move!"},
		{"speaker": "Bentley", "text": "*urgent growl*"}
	])
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is CharacterBody2D:
			enemy.chase_speed = float(enemy.chase_speed) + 40.0
			var patrol_value = enemy.get("patrol_speed")
			if typeof(patrol_value) == TYPE_FLOAT or typeof(patrol_value) == TYPE_INT:
				enemy.set("patrol_speed", float(patrol_value) + 20.0)
	_spawn_hunter_guard()

func _spawn_hunter_guard() -> void:
	if hunter_guard_spawned:
		return
	hunter_guard_spawned = true
	var enemy_scene: PackedScene = load("res://scenes/characters/guard.tscn")
	if enemy_scene == null:
		return
	var hunter = enemy_scene.instantiate()
	if hunter == null:
		return
	add_child(hunter)
	hunter.global_position = Vector2(1320, 230)
	hunter.aggro_range = 2000.0
	hunter.chase_speed = max(float(hunter.chase_speed), 230.0)
	hunter.speed = max(float(hunter.speed), 200.0)
	if hunter.has_signal("spotted_player") and not hunter.spotted_player.is_connected(_on_guard_spotted_player):
		hunter.spotted_player.connect(_on_guard_spotted_player)

func _try_advance_from_access_prep() -> void:
	if current_step != MissionStep.ACCESS_PREP:
		return
	if keycard_found and alarm_disabled:
		_advance_to(MissionStep.GARAGE_PUZZLE)

func _on_garage_solved() -> void:
	garage_door_opened = true
	AudioManager.play_sfx("door_open")
	if not alarm_disabled and not alarm_tripped:
		if not _try_mere_legal_bypass():
			_trip_security("Garage keypad raised an alarm.")
	
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
		if not decoy_bag_revealed:
			decoy_bag_revealed = true
			var decoy_zone := get_node_or_null("BagPickupZone")
			var real_spawn := get_node_or_null("RealBagSpawn") as Node2D
			if CardEffects.has_clorox_protocol():
				if decoy_zone and real_spawn:
					decoy_zone.global_position = real_spawn.global_position
				EventBus.card_triggered.emit("clorox_wipe_protocol", "used", "Clean swap — no decoy.")
				QuestManager.set_objective("Bag secured at the real drop (Clorox Protocol). Get to the exit.", mission_id)
			else:
				_play_reactive_dialogue([
					{"speaker": "Parmida", "text": "This bag is a decoy. It's stuffed with napkins."},
					{"speaker": "Louis", "text": "Aw, damn it! Sorry Parm. I mixed up the deliveries. The real bag is outside the garage!"}
				])
				if decoy_zone and real_spawn:
					decoy_zone.global_position = real_spawn.global_position
				QuestManager.set_objective("Twist: decoy bag found. Grab the real bag outside the garage.", mission_id)
				return
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

func _on_polaroid_collected(polaroid_id: String) -> void:
	if polaroid_id == "taco_bell_smiskis" and not secret_smiskis_found:
		secret_smiskis_found = true
		EventBus.objective_updated.emit("Optional collectible found: Smiski stash.")

func _play_reactive_dialogue(lines: Array[Dictionary]) -> void:
	if DialogueManager.is_in_dialogue:
		return
	DialogueManager.start_simple_dialogue(lines)

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
	if secret_smiskis_found:
		GameState.intel_points += 1
		EventBus.objective_updated.emit("Bonus: Smiski stash recovered! +1 intel point.")
	
	is_complete = true
	var result := GameState.complete_mission(get_mission_id())
	SceneManager.show_mission_result(result)

func get_garage_code_options() -> Array[String]:
	if intel_receipt_found:
		return [GARAGE_CODE_RECEIPT]
	return [GARAGE_CODE_GUESS_1, GARAGE_CODE_GUESS_2, GARAGE_CODE_GUESS_3]

func is_garage_code_valid(code: String) -> bool:
	return code == GARAGE_CODE_RECEIPT
