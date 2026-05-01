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
var secret_glow_guys_found := false
var hunter_guard_spawned := false
var legal_eyes_used := false

## Which scent color family leads to the garage this run (0 orange, 1 blue, 2 green). Rolled in mutations.
var _real_trail_family: int = 2
var _sniffs_on_real_trail: int = 0
var _fake_trail_reactions: int = 0
var _raccoon_flavor_done := false
var _decoy_flavor_done := false
var _garage_ambush_spawned := false

## Correct keypad code for this run (Mission Bible mutations + receipt intel).
var _correct_garage_code: String = "2174"
const GARAGE_CODE_GUESS_1 := "1234"
const GARAGE_CODE_GUESS_2 := "0000"

const SCENT_MARKER_NAMES: Array[String] = [
	"ScentMarker_O1", "ScentMarker_O2", "ScentMarker_B1", "ScentMarker_B2", "ScentMarker_G1", "ScentMarker_G2",
]

const _TRAIL_FAMILY_NAMES: Array[String] = ["orange food", "blue chemical", "green uncertain"]

func _ready() -> void:
	mission_id = "taco_bell_drop"
	objective_text = "Meet Louis on Midnight Market Street."
	guard_count = 0
	_apply_taco_bell_mutations()
	super._ready()
	_spawn_taco_heat_extras()
	
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

	var decoy_intel := get_node_or_null("DecoyBagIntel")
	if decoy_intel and decoy_intel.has_signal("intel_collected"):
		if not decoy_intel.intel_collected.is_connected(_on_decoy_bag_intel_collected):
			decoy_intel.intel_collected.connect(_on_decoy_bag_intel_collected)
	var sauce_intel := get_node_or_null("SaucePacketInspect")
	if sauce_intel and sauce_intel.has_signal("intel_collected"):
		if not sauce_intel.intel_collected.is_connected(_on_sauce_packet_intel_collected):
			sauce_intel.intel_collected.connect(_on_sauce_packet_intel_collected)

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
	call_deferred("_connect_flavor_zones")
	call_deferred("_style_keypad_note_for_card")
	call_deferred("_maybe_louis_failure_hint")


func _apply_taco_bell_mutations() -> void:
	var pool := {
		"keypad_code": ["2174", "4312", "9021", "7429"],
		"glow_slot": [0, 1, 2],
		"real_trail_family": [0, 1, 2],
	}
	var m := MissionMutationHelper.roll(mission_id, pool)
	_correct_garage_code = String(m.get("keypad_code", "2174"))
	_real_trail_family = clampi(int(m.get("real_trail_family", 2)), 0, 2)
	var slot := int(m.get("glow_slot", 0))
	var glow := get_node_or_null("GlowGuyPickup") as Node2D
	var mk := get_node_or_null("MutationSlots/GlowGuySlot%d" % slot) as Node2D
	if glow and mk:
		glow.global_position = mk.global_position
	var heat := GameState.get_mission_heat(mission_id)
	if heat >= 3:
		EventBus.objective_updated.emit("Heat level high — garage lights flicker; assume cameras are live.")
	if heat >= 5:
		call_deferred("_emit_louis_heat_hint")


func _emit_louis_heat_hint() -> void:
	var fam: String = _TRAIL_FAMILY_NAMES[clampi(_real_trail_family, 0, 2)]
	QuestManager.set_objective(
		"Louis texts: real trail is the %s line; keypad %s; cameras may be live." % [fam, _correct_garage_code],
		mission_id,
	)


func _spawn_taco_heat_extras() -> void:
	var heat := GameState.get_mission_heat(mission_id)
	if heat < 1:
		return
	var enemy_scene: PackedScene = load("res://scenes/characters/guard.tscn")
	if enemy_scene == null:
		return
	var spawn3 := get_node_or_null("GoonSpawns/GoonSpawn3") as Node2D
	var path_c := get_node_or_null("GuardPath3") as Path2D
	_spawn_yard_guard(enemy_scene, spawn3, path_c, Vector2(1180, 320))
	if heat >= 4:
		var bruiser_scene: PackedScene = load("res://scenes/characters/bruiser.tscn")
		var spawn4 := get_node_or_null("GoonSpawns/GoonSpawn4") as Node2D
		if bruiser_scene and spawn4:
			var br = bruiser_scene.instantiate()
			if br:
				add_child(br)
				br.global_position = spawn4.global_position
				if br.has_signal("spotted_player") and not br.spotted_player.is_connected(_on_guard_spotted_player):
					br.spotted_player.connect(_on_guard_spotted_player)


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
			QuestManager.set_objective("Midnight Market → talk to Louis. Something's wrong with the delivery.", mission_id)
			_show_louis_dialogue()
		
		MissionStep.INVESTIGATE:
			QuestManager.set_objective("Delivery Alley: inspect clues. Dumpster note starts Bentley's nose.", mission_id)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.SNIFF_TRAIL:
			QuestManager.set_objective(
				"Scent split: orange (food), blue (Sterling chemical), green (uncertain). Follow the trail where Bentley's ears perk—not the sneeze trails.",
				mission_id,
			)
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
			QuestManager.set_objective(
				"Parking garage F1: keycard in security booth, alarm panel, or send Bentley through the vent. Cars = cover.",
				mission_id,
			)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.GARAGE_PUZZLE:
			QuestManager.set_objective(
				"Garage office keypad — 4 digits from the route board (receipt matches). Code this run: %s." % _correct_garage_code,
				mission_id,
			)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.RECOVER_BAG:
			QuestManager.set_objective(
				"Bag recovery room: grab Louis's bag in the garage. Expect an ambush when the lights snap on.",
				mission_id,
			)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.ESCAPE:
			QuestManager.set_objective("Escape back to Louis at the green exit — keep the bag.", mission_id)
			AudioManager.play_sfx("objective_update")
		
		MissionStep.COMPLETE:
			QuestManager.set_objective("Mission complete! Heading back to the hideout.", mission_id)

func _start_mission() -> void:
	if CardManager.is_selected("polaroid_proof"):
		intel_receipt_found = true
		EventBus.card_triggered.emit("polaroid_proof", "active", "Receipt evidence in hand.")
	if GameState.get_mission_heat(mission_id) >= 5:
		call_deferred("_emit_louis_heat_hint")
	_advance_to(MissionStep.INTRO)

func _apply_diamond_year_highlights() -> void:
	if not CardEffects.can_see_loot_through_walls():
		return
	var bag_vis := get_node_or_null("BagPickupZone/BagVisual") as CanvasItem
	var glow_vis := get_node_or_null("GlowGuyPickup/GlowVisual") as CanvasItem
	if bag_vis:
		bag_vis.modulate = Color(0.35, 1.0, 1.0, 1.0)
	if glow_vis:
		glow_vis.modulate = Color(1.0, 0.45, 0.95, 1.0)
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
	for path in SCENT_MARKER_NAMES:
		var marker := get_node_or_null(path)
		if marker == null:
			continue
		marker.add_to_group("scent_trail")
		if marker.has_signal("sniffed"):
			marker.sniffed.connect(_on_scent_marker_sniffed)
		marker.visible = false


func _activate_scent_trail() -> void:
	for marker in get_tree().get_nodes_in_group("scent_trail"):
		if marker is CanvasItem:
			marker.visible = true
	
	var bentley := get_tree().get_first_node_in_group("bentley")
	if bentley and bentley.has_method("sniff"):
		bentley.sniff()


func _on_scent_marker_sniffed(marker_id: int, trail_family: int) -> void:
	AudioManager.play_sfx("bentley_sniff")
	if trail_family == _real_trail_family:
		_sniffs_on_real_trail += 1
		if _sniffs_on_real_trail == 1:
			_play_reactive_dialogue([
				{"speaker": "Bentley", "text": "*ears perk, lean forward*"},
				{"speaker": "Parmida", "text": "That's the one. Stay on this color."},
			])
		if _sniffs_on_real_trail >= 2:
			scent_trail_complete = true
			_play_reactive_dialogue([
				{"speaker": "Bentley", "text": "*tiny bark toward the loading yard*"},
				{"speaker": "Parmida", "text": "Garage. Of course it's a garage."},
			])
			if current_step == MissionStep.SNIFF_TRAIL:
				_advance_to(MissionStep.ACCESS_PREP)
	else:
		_fake_trail_reactions += 1
		if _fake_trail_reactions <= 2:
			_play_reactive_dialogue([
				{"speaker": "Bentley", "text": "*pause… sneeze… side-eye*"},
				{"speaker": "Parmida", "text": "Not that trail. He's judging you."},
			])


func _connect_flavor_zones() -> void:
	var rp := get_node_or_null("RaccoonPit") as Area2D
	if rp and not rp.body_entered.is_connected(_on_raccoon_pit_entered):
		rp.body_entered.connect(_on_raccoon_pit_entered)
	var dp := get_node_or_null("DecoyStaging") as Area2D
	if dp and not dp.body_entered.is_connected(_on_decoy_staging_entered):
		dp.body_entered.connect(_on_decoy_staging_entered)


func _on_raccoon_pit_entered(body: Node) -> void:
	if not body.is_in_group("player") or _raccoon_flavor_done:
		return
	_raccoon_flavor_done = true
	DialogueManager.show_simple_dialogue([
		{"speaker": "Parmida", "text": "Orange trail dead-ends at raccoons fighting over fries. Not Sterling — just chaos."},
	])


func _on_decoy_staging_entered(body: Node) -> void:
	if not body.is_in_group("player") or _decoy_flavor_done:
		return
	_decoy_flavor_done = true
	DialogueManager.show_simple_dialogue([
		{"speaker": "Parmida", "text": "Decoy bag. Napkins and theater. The chemical blue trail was a lure."},
	])


func try_vent_unlock(vent: Node2D = null) -> void:
	if keycard_found:
		EventBus.objective_updated.emit("Already have the booth keycard.")
		return
	var dog := get_tree().get_first_node_in_group("bentley") as Node2D
	var vpos: Vector2 = vent.global_position if vent else Vector2.ZERO
	if dog == null or vpos.distance_to(dog.global_position) > 140.0:
		_play_reactive_dialogue([{"speaker": "Parmida", "text": "Need Bentley at the vent."}])
		return
	keycard_found = true
	AudioManager.play_sfx("objective_update")
	EventBus.objective_updated.emit("Bentley wriggled through the vent and dropped the staff keycard.")
	_play_reactive_dialogue([
		{"speaker": "Louis", "text": "(whisper) That's my dog's tax return in action."},
	])
	_try_advance_from_access_prep()


func _maybe_louis_failure_hint() -> void:
	if int(GameState.failed_attempts.get(mission_id, 0)) < 2:
		return
	var fam: String = _TRAIL_FAMILY_NAMES[clampi(_real_trail_family, 0, 2)]
	QuestManager.set_objective(
		"Louis texts a hint: trust the %s trail where Bentley perks — keypad this week %s." % [fam, _correct_garage_code],
		mission_id,
	)


func _style_keypad_note_for_card() -> void:
	if not GameState.has_selected_card("two_letters_away"):
		return
	var n := get_node_or_null("KeypadRouteNote/NoteHighlight") as CanvasItem
	if n:
		n.visible = true
	if get_node_or_null("KeypadRouteNote/Visual"):
		(get_node_or_null("KeypadRouteNote/Visual") as CanvasItem).modulate = Color(1.0, 0.95, 0.35, 1.0)


func _on_yard_entered() -> void:
	if current_step == MissionStep.SNIFF_TRAIL and scent_trail_complete:
		_advance_to(MissionStep.ACCESS_PREP)
	elif current_step < MissionStep.ACCESS_PREP:
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
	QuestManager.set_objective("Receipt found: Garage code is " + _correct_garage_code + ".", mission_id)
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
	call_deferred("_spawn_garage_ambush")
	call_deferred("_play_ambush_intro_line")


func _spawn_garage_ambush() -> void:
	if _garage_ambush_spawned:
		return
	_garage_ambush_spawned = true
	var goon_scene: PackedScene = load("res://scenes/characters/goon.tscn")
	if goon_scene == null:
		return
	var s1 := get_node_or_null("AmbushSpawns/Ambush1") as Node2D
	var s2 := get_node_or_null("AmbushSpawns/Ambush2") as Node2D
	var s3 := get_node_or_null("AmbushSpawns/AmbushBottle") as Node2D
	_spawn_goon_at(goon_scene, s1, Vector2(1280, 320))
	_spawn_goon_at(goon_scene, s2, Vector2(1320, 440))
	_spawn_goon_at(goon_scene, s3, Vector2(1180, 380))


func _spawn_goon_at(packed: PackedScene, spawn: Node2D, fallback: Vector2) -> void:
	var g = packed.instantiate()
	if g == null:
		return
	add_child(g)
	g.global_position = spawn.global_position if spawn else fallback
	if g.has_signal("spotted_player") and not g.spotted_player.is_connected(_on_guard_spotted_player):
		g.spotted_player.connect(_on_guard_spotted_player)


func _play_ambush_intro_line() -> void:
	var t := get_tree().create_timer(0.75)
	t.timeout.connect(func():
		DialogueManager.show_simple_dialogue([
			{"speaker": "Goon", "text": "That bag belongs to Sterling now."},
			{"speaker": "Parmida", "text": "Then Sterling should have tipped better."},
		])
	)


func _on_decoy_bag_intel_collected(_intel_id: String) -> void:
	GameState.intel_points += 1
	EventBus.objective_updated.emit("Decoy bag documented for Sterling's theater. +1 intel.")


func _on_sauce_packet_intel_collected(_intel_id: String) -> void:
	GameState.ensure_and_discover_sterling_clue("sauce_packet_vp_hint", {
		"title": "Sauce packet — V.P.",
		"description": "Initials on foil point toward the Velvet Paw.",
		"category": "Hint",
		"mission_id": "taco_bell_drop",
		"connects_to": "velvet_paw_jazz_club",
	})

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
	var nid := GameState.normalize_polaroid_id(polaroid_id)
	if nid == "taco_bell_glow_guys" and not secret_glow_guys_found:
		secret_glow_guys_found = true
		EventBus.objective_updated.emit("Optional collectible found: Glow Guy stash.")
	elif nid == "taco_bell_midnight_market_rain":
		EventBus.objective_updated.emit("Hidden polaroid: Midnight Market rain.")

func _play_reactive_dialogue(lines: Array[Dictionary]) -> void:
	if DialogueManager.is_in_dialogue:
		return
	DialogueManager.start_simple_dialogue(lines)

func _show_sterling_clue() -> void:
	var note := get_node_or_null("SterlingClueNote")
	if note and note.has_method("show_note"):
		note.show_note()
	GameState.ensure_and_discover_sterling_clue("sterling_delivery_token", {
		"title": "Sterling Delivery Token",
		"description": "Sterling moves secret packets through ordinary delivery networks.",
		"category": "Logistics",
		"mission_id": "taco_bell_drop",
		"connects_to": "Velvet Paw Jazz Club",
		"unlocks_or_modifies": "Delivery entrance options",
	})
	GameState.ensure_and_discover_sterling_clue("velvet_paw_envelope_stamp", {
		"title": "Velvet Paw Club Stamp",
		"description": "Black envelope — club mark points to the Velvet Paw.",
		"category": "Network",
		"mission_id": "taco_bell_drop",
		"connects_to": "velvet_paw_jazz_club",
	})
	GameState.ensure_and_discover_sterling_clue("route_manifest_half", {
		"title": "Half-burned route manifest",
		"description": "Garage dispatch overlaps with Dom's getaway routes later.",
		"category": "Logistics",
		"mission_id": "taco_bell_drop",
		"connects_to": "fast_family_getaway",
	})
	call_deferred("_play_louis_bag_reveal_phone")


func _play_louis_bag_reveal_phone() -> void:
	DialogueManager.show_simple_dialogue([
		{"speaker": "Louis", "text": "(phone, whisper) That's not a delivery route. That's a map of safehouses."},
		{"speaker": "Parmida", "text": "Camera in on the token. Sterling's not stealing meals — he's stealing corridors."},
	])

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

	if not alarm_tripped and not spotted_by_guard:
		CollectibleManager.collect_polaroid("taco_bell_perfect_ambush")

	# Collect polaroid on completion
	CollectibleManager.collect_polaroid("taco_bell_polaroid")
	
	# Grant extra intel for optional objectives
	if intel_receipt_found and intel_dumpster_found:
		GameState.intel_points += 2
		EventBus.objective_updated.emit("Bonus: All intel found! +2 intel points.")
	if secret_glow_guys_found:
		GameState.intel_points += 1
		EventBus.objective_updated.emit("Bonus: Glow Guy stash recovered! +1 intel point.")
	
	is_complete = true
	var result := GameState.complete_mission(get_mission_id())
	SceneManager.show_mission_result(result)

func get_garage_code_options() -> Array[String]:
	if intel_receipt_found:
		return [_correct_garage_code]
	return [_correct_garage_code, GARAGE_CODE_GUESS_1, GARAGE_CODE_GUESS_2]

func is_garage_code_valid(code: String) -> bool:
	return code == _correct_garage_code
