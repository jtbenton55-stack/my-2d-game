extends "res://src/levels/LevelBase.gd"

enum MissionStep {
	INTRO,
	FIND_ENTRANCE,
	SOCIAL_STEALTH,
	MUSIC_PUZZLE,
	BACKSTAGE_SEARCH,
	LEDGER_PICKUP,
	ESCAPE,
	COMPLETE
}

var current_step: MissionStep = MissionStep.INTRO
var ledger_collected := false
var music_puzzle_solved := false
var wrong_puzzle_attempts := 0
var clues_found := 0
const TOTAL_CLUES := 2
const GUARD_SCENE_PATH := "res://scenes/characters/guard.tscn"
const OWNER_ARENA_SCENE := "res://scenes/missions/JazzClubOwnerArena.tscn"
var bouncer_alerted := false
var yordano_triggered := false
var active_puzzle: Control = null

var staff_badge_secured := false
var sound_check_done := false
var ledger_decoy_cleared := false
var staff_route_announced := false
var social_floor_reacted := false
var _read_clue_names: Array[StringName] = []
var secret_velvet_collectible := false

## Wrong-setlist alarm hunt (temporary reinforcements + overlay).
var setlist_alarm_active := false
var _alarm_overlay: CanvasLayer = null
var _alarm_guards: Array[Node] = []

## Owner fight happens in `JazzClubOwnerArena.tscn`; briefcase unlocks on victory.
var club_owner_spawned := false
var club_owner_defeated := false

func _ready() -> void:
	mission_id = "velvet_paw_jazz_club"
	objective_text = "Find a way into the Velvet Paw Jazz Club."
	guard_count = 0
	super._ready()
	
	_setup_mission_zones()
	_setup_bouncer_patrols()
	_setup_readable_notes()
	_setup_music_puzzle_trigger()
	_setup_ledger_zone()
	_setup_polaroid()
	_setup_velvet_props_and_decoy()
	if not EventBus.polaroid_collected.is_connected(_on_polaroid_collected):
		EventBus.polaroid_collected.connect(_on_polaroid_collected)
	
	_setup_alarm_safe_zones()
	_setup_owner_suite_stairs()
	
	if GameState.has_velvet_paw_resume_data():
		_apply_velvet_paw_resume_data(GameState.take_velvet_paw_resume_data())
	else:
		_advance_step(MissionStep.INTRO)

func _setup_velvet_props_and_decoy() -> void:
	var decoy := get_node_or_null("LedgerDecoy")
	if decoy:
		decoy.visible = false
		## Old decoy flow is replaced by upstairs boss + briefcase; keep node for rollback
		## but do not let invisible decoy steal [E] near backstage or show a fake ledger.
		decoy.remove_from_group("interactable")
		decoy.monitoring = false
		decoy.monitorable = false
		var dshape := decoy.get_node_or_null("CollisionShape2D")
		if dshape:
			dshape.disabled = true
	var staff_gate := get_node_or_null("StaffSouthGate")
	if staff_gate:
		staff_gate.collision_layer = 2
	var staff_zone := get_node_or_null("StaffRouteZone")
	if staff_zone and not staff_zone.body_entered.is_connected(_on_staff_route_zone_entered):
		staff_zone.body_entered.connect(_on_staff_route_zone_entered)

func _setup_mission_zones() -> void:
	var entrance_zone := get_node_or_null("EntranceZone")
	if entrance_zone:
		entrance_zone.body_entered.connect(_on_entrance_entered)
	
	var music_area := get_node_or_null("MusicPuzzleArea")
	if music_area:
		music_area.body_entered.connect(_on_music_area_entered)
	
	var backstage_area := get_node_or_null("BackstageArea")
	if backstage_area:
		backstage_area.body_entered.connect(_on_backstage_entered)
	
	var escape_zone := get_node_or_null("EscapeZone")
	if escape_zone:
		escape_zone.body_entered.connect(_on_escape_entered)
	
	var yordano_zone := get_node_or_null("YordanoTriggerZone")
	if yordano_zone:
		yordano_zone.body_entered.connect(_on_yordano_triggered)
	
	var social_zone := get_node_or_null("SocialFloorZone")
	if social_zone and not social_zone.body_entered.is_connected(_on_social_floor_entered):
		social_zone.body_entered.connect(_on_social_floor_entered)


func _setup_alarm_safe_zones() -> void:
	for spot_name in [&"SafeSpotBar", &"SafeSpotDance"]:
		var spot := get_node_or_null(String(spot_name))
		if spot and spot.has_signal("body_entered"):
			spot.body_entered.connect(_on_alarm_safe_spot_entered.bind(spot_name))


func _on_alarm_safe_spot_entered(spot_name: StringName, body: Node) -> void:
	if body != player or not setlist_alarm_active:
		return
	match spot_name:
		&"SafeSpotBar":
			QuestManager.set_objective("Yordano: tuck behind the bar—the rails swallow the bass spikes.", mission_id)
		&"SafeSpotDance":
			QuestManager.set_objective("Yordano: melt into the dance floor silhouette until the strobes lie for you.", mission_id)
		_:
			pass


func _setup_owner_suite_stairs() -> void:
	var stairs := get_node_or_null("OwnerSuiteStairs")
	if stairs and stairs.has_signal("body_entered"):
		stairs.body_entered.connect(_on_stairs_body_entered)


func _on_stairs_body_entered(body: Node) -> void:
	if body.is_in_group("player") and music_puzzle_solved and not club_owner_defeated:
		EventBus.objective_updated.emit("Press E at the rig stairs to enter the owner suite (boss fight).")


func try_enter_owner_suite() -> void:
	if not music_puzzle_solved:
		QuestManager.set_objective("Solve the setlist on stage before you pick a fight upstairs.", mission_id)
		return
	if clues_found < TOTAL_CLUES:
		QuestManager.set_objective("Find both clue notes—the suite won't open until Bentley has the scent.", mission_id)
		return
	if club_owner_defeated:
		QuestManager.set_objective("Suite's clear. Grab the briefcase on the balcony.", mission_id)
		return
	if DialogueManager.is_in_dialogue:
		return
	if not ResourceLoader.exists(OWNER_ARENA_SCENE):
		push_error("JazzClubMission: missing owner arena scene")
		return
	GameState.set_velvet_paw_resume_data(_build_velvet_resume_payload())
	SceneManager.change_scene(OWNER_ARENA_SCENE)


func _build_velvet_resume_payload() -> Dictionary:
	var names: Array = []
	for n in _read_clue_names:
		names.append(String(n))
	return {
		"current_step": int(current_step),
		"ledger_collected": ledger_collected,
		"music_puzzle_solved": music_puzzle_solved,
		"clues_found": clues_found,
		"wrong_puzzle_attempts": wrong_puzzle_attempts,
		"bouncer_alerted": bouncer_alerted,
		"yordano_triggered": yordano_triggered,
		"staff_badge_secured": staff_badge_secured,
		"sound_check_done": sound_check_done,
		"ledger_decoy_cleared": ledger_decoy_cleared,
		"staff_route_announced": staff_route_announced,
		"social_floor_reacted": social_floor_reacted,
		"read_clue_names": names,
		"secret_velvet_collectible": secret_velvet_collectible,
		"club_owner_defeated": club_owner_defeated,
		"club_owner_spawned": club_owner_spawned,
	}


func _apply_velvet_paw_resume_data(d: Dictionary) -> void:
	var raw_step := int(d.get("current_step", int(MissionStep.INTRO)))
	current_step = clampi(raw_step, 0, int(MissionStep.COMPLETE)) as MissionStep
	ledger_collected = bool(d.get("ledger_collected", false))
	music_puzzle_solved = bool(d.get("music_puzzle_solved", false))
	clues_found = int(d.get("clues_found", 0))
	wrong_puzzle_attempts = int(d.get("wrong_puzzle_attempts", 0))
	bouncer_alerted = bool(d.get("bouncer_alerted", false))
	yordano_triggered = bool(d.get("yordano_triggered", false))
	staff_badge_secured = bool(d.get("staff_badge_secured", false))
	sound_check_done = bool(d.get("sound_check_done", false))
	ledger_decoy_cleared = bool(d.get("ledger_decoy_cleared", false))
	staff_route_announced = bool(d.get("staff_route_announced", false))
	social_floor_reacted = bool(d.get("social_floor_reacted", false))
	secret_velvet_collectible = bool(d.get("secret_velvet_collectible", false))
	club_owner_defeated = bool(d.get("club_owner_defeated", false))
	club_owner_spawned = bool(d.get("club_owner_spawned", false))
	_read_clue_names.clear()
	for s in d.get("read_clue_names", []):
		_read_clue_names.append(StringName(String(s)))
	if music_puzzle_solved:
		var bb := get_node_or_null("BackstageBlocker")
		if is_instance_valid(bb):
			bb.queue_free()
		var sb := get_node_or_null("StairsBlocker")
		if is_instance_valid(sb):
			sb.queue_free()
		var wf := get_node_or_null("StairsWayfinding")
		if wf:
			wf.visible = true
		var sl := get_node_or_null("OwnerSuiteStairs/StairsInteractLabel") as Label
		if sl:
			sl.visible = true
	if staff_badge_secured:
		var badge := get_node_or_null("StaffBadgePickup")
		if is_instance_valid(badge):
			badge.queue_free()
		var gate := get_node_or_null("StaffSouthGate")
		if is_instance_valid(gate):
			gate.queue_free()
	if club_owner_defeated:
		_place_ledger_after_boss_victory()
	else:
		match current_step:
			MissionStep.INTRO:
				QuestManager.set_objective("The Velvet Paw is hopping tonight. Find a way inside. Bentley smells something important.", mission_id)
			MissionStep.FIND_ENTRANCE:
				QuestManager.set_objective("The front is too crowded. Look for a side entrance or staff door.", mission_id)
			MissionStep.SOCIAL_STEALTH:
				QuestManager.set_objective("Avoid the bouncers on the social floor. Micro-objectives: grab the staff badge (dressing area) and run the sound check (stage wing).", mission_id)
			MissionStep.MUSIC_PUZZLE:
				QuestManager.set_objective("The stage area has a song list puzzle. Put the setlist in the correct order to unlock backstage.", mission_id)
			MissionStep.BACKSTAGE_SEARCH:
				if clues_found >= TOTAL_CLUES:
					QuestManager.set_objective("Ledger isn't crate dressing—the owner's suite upstairs holds the briefcase. Press E on the rig stairs.", mission_id)
				else:
					QuestManager.set_objective("Search backstage for clues about where the ledger is hidden. Bentley can sniff out the real one.", mission_id)
			MissionStep.LEDGER_PICKUP:
				QuestManager.set_objective("Briefcase on the balcony. Grab it and don't admire the view.", mission_id)
			MissionStep.ESCAPE:
				QuestManager.set_objective("Bass drop time. Escape through the basement exit before the bouncers regroup.", mission_id)
			_:
				pass


func _place_ledger_after_boss_victory() -> void:
	club_owner_defeated = true
	club_owner_spawned = false
	var ledger := get_node_or_null("LedgerZone")
	var mk := get_node_or_null("LedgerBriefcaseMarker")
	if ledger and mk:
		ledger.global_position = mk.global_position
		ledger.visible = true
		ledger.set_deferred("monitoring", true)
	_advance_step(MissionStep.LEDGER_PICKUP)
	QuestManager.set_objective("Briefcase on the balcony. Grab it and don't admire the view.", mission_id)


func _setup_bouncer_patrols() -> void:
	for i in range(1, 4):
		var path := get_node_or_null("BouncerPath" + str(i))
		var bouncer := get_node_or_null("Bouncer" + str(i))
		if path and bouncer:
			var patrol := preload("res://src/enemies/components/patrol_component.gd").new()
			patrol.path = path
			patrol.speed = 80.0
			patrol.wait_time = 1.5
			bouncer.add_child(patrol)

func _setup_readable_notes() -> void:
	var clue1 := get_node_or_null("Clue1")
	if clue1:
		clue1.add_to_group("interactable")
		clue1.note_title = "Crumpled Setlist Fragment"
		clue1.note_text = "Tour laminate scribble: 'Album arc tonight—start where we started hungry, ballad in the middle breath, end where the jury listens.' (Smells like taco grease and ambition.)"
		clue1.polaroid_id = ""
		if clue1.has_signal("note_read") and not clue1.note_read.is_connected(_on_clue_note_read):
			clue1.note_read.connect(_on_clue_note_read)
	
	var clue2 := get_node_or_null("Clue2")
	if clue2:
		clue2.add_to_group("interactable")
		clue2.note_title = "Stage Manager's Notes"
		clue2.note_text = "Setlist policy: five songs only—follow the release timeline, not the merch table. If an extra title sneaks in, it's wrong even when it rhymes."
		clue2.polaroid_id = ""
		if clue2.has_signal("note_read") and not clue2.note_read.is_connected(_on_clue_note_read):
			clue2.note_read.connect(_on_clue_note_read)
	
	var poster := get_node_or_null("NightPoster")
	if poster and poster.has_signal("note_read") and not poster.note_read.is_connected(_on_night_poster_read):
		poster.note_read.connect(_on_night_poster_read)

func _on_clue_note_read(note: Node) -> void:
	var n := StringName(note.name)
	if n in _read_clue_names:
		return
	_read_clue_names.append(n)
	clues_found += 1
	AudioManager.play_sfx("note_read")
	QuestManager.set_objective("Clue found: %d/%d. Bentley is getting closer to the ledger's scent." % [clues_found, TOTAL_CLUES], mission_id)
	_check_clues_and_reveal_ledger()

func _on_night_poster_read(_note: Node) -> void:
	_play_reactive_dialogue([
		{"speaker": "Parmida", "text": "Sterling sponsored the 'Raincoat' encore. Of course he did."}
	])

func _setup_music_puzzle_trigger() -> void:
	# MusicPuzzleTrigger (child) is interactable; do not add MusicPuzzleArea — it has no interact() and would steal E.
	pass

func _setup_ledger_zone() -> void:
	var ledger := get_node_or_null("LedgerZone")
	if ledger:
		ledger.visible = false
		# Pickup uses body_entered, not interact(); do not add to interactable or it blocks nearby E targets.
		if not ledger.body_entered.is_connected(_on_ledger_body_entered):
			ledger.body_entered.connect(_on_ledger_body_entered)

func _setup_polaroid() -> void:
	var polaroid := get_node_or_null("PolaroidPickup")
	if polaroid:
		polaroid.add_to_group("interactable")

func _on_polaroid_collected(polaroid_id: String) -> void:
	if polaroid_id == "velvet_smiskis" and not secret_velvet_collectible:
		secret_velvet_collectible = true
		EventBus.objective_updated.emit("Optional: Velvet Smiski stash secured.")

func _advance_step(new_step: MissionStep) -> void:
	current_step = new_step
	match current_step:
		MissionStep.INTRO:
			QuestManager.set_objective("The Velvet Paw is hopping tonight. Find a way inside. Bentley smells something important.", mission_id)
		MissionStep.FIND_ENTRANCE:
			QuestManager.set_objective("The front is too crowded. Look for a side entrance or staff door.", mission_id)
		MissionStep.SOCIAL_STEALTH:
			QuestManager.set_objective("Avoid the bouncers on the social floor. Micro-objectives: grab the staff badge (dressing area) and run the sound check (stage wing).", mission_id)
		MissionStep.MUSIC_PUZZLE:
			QuestManager.set_objective("The stage area has a song list puzzle. Put the setlist in the correct order to unlock backstage.", mission_id)
		MissionStep.BACKSTAGE_SEARCH:
			QuestManager.set_objective("Search backstage for clues about where the ledger is hidden. Bentley can sniff out the real one.", mission_id)
		MissionStep.LEDGER_PICKUP:
			QuestManager.set_objective("Grab the blackmail ledger. Yordano is waiting for his cue.", mission_id)
		MissionStep.ESCAPE:
			QuestManager.set_objective("Bass drop time. Escape through the basement exit before the bouncers regroup.", mission_id)
		MissionStep.COMPLETE:
			complete_level()

func _play_reactive_dialogue(lines: Array) -> void:
	if DialogueManager.is_in_dialogue:
		return
	DialogueManager.start_simple_dialogue(lines)

func _on_entrance_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step <= MissionStep.FIND_ENTRANCE:
		_advance_step(MissionStep.SOCIAL_STEALTH)
		_play_reactive_dialogue([
			{"speaker": "Bentley", "text": "*sniff* (Too many colognes. The bass line is honest, though.)"}
		])

func _on_social_floor_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if social_floor_reacted:
		return
	social_floor_reacted = true
	_play_reactive_dialogue([
		{"speaker": "Parmida", "text": "Eyes up. Velvet ropes are not decoration—they're jurisdiction."}
	])

func _on_music_area_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step == MissionStep.SOCIAL_STEALTH:
		_advance_step(MissionStep.MUSIC_PUZZLE)
		_show_music_puzzle_prompt()

func _on_backstage_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step == MissionStep.MUSIC_PUZZLE and music_puzzle_solved:
		_advance_step(MissionStep.BACKSTAGE_SEARCH)
		_check_clues_and_reveal_ledger()
	elif music_puzzle_solved and current_step < MissionStep.BACKSTAGE_SEARCH:
		_advance_step(MissionStep.BACKSTAGE_SEARCH)
		_check_clues_and_reveal_ledger()
	elif current_step == MissionStep.BACKSTAGE_SEARCH:
		_check_clues_and_reveal_ledger()

func _on_staff_route_zone_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not staff_badge_secured:
		return
	if staff_route_announced:
		return
	staff_route_announced = true
	_play_reactive_dialogue([
		{"speaker": "Parmida", "text": "Staff hatch. We didn't sneak past the velvet—we walked through the payroll."}
	])

func _on_escape_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step == MissionStep.ESCAPE and ledger_collected:
		_advance_step(MissionStep.COMPLETE)

func _on_yordano_triggered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if yordano_triggered:
		return
	yordano_triggered = true
	
	if GameState.has_selected_card("yordano_bass_drop"):
		_trigger_bass_drop_stun()
	else:
		_show_yordano_dialogue()

func _trigger_bass_drop_stun() -> void:
	QuestManager.set_objective("YORDANO BASS DROP! The bouncers are stunned!", mission_id)
	AudioManager.play_sfx("bass_drop_explosion")
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("stun"):
			enemy.stun(5.0)
		elif enemy.has_method("set_stunned"):
			enemy.set_stunned(true)
			enemy.set_deferred("is_stunned", false)
			enemy.call_deferred("_resume_after_delay", 5.0)

func _show_yordano_dialogue() -> void:
	var lines := [
		{"speaker": "Yordano", "text": "That's my cue. Time for the exit solo."},
		{"speaker": "Bentley", "text": "Woof! (The bass is about to drop!)"}
	]
	DialogueManager.start_simple_dialogue(lines)

func _check_clues_and_reveal_ledger() -> void:
	if clues_found < TOTAL_CLUES:
		return
	if current_step != MissionStep.BACKSTAGE_SEARCH:
		return
	QuestManager.set_objective("Ledger isn't crate dressing—the briefcase waits past the rig stairs. Press E on the stairs to enter the owner suite.", mission_id)
	_play_reactive_dialogue([
		{"speaker": "Bentley", "text": "*low growl* (Ink upstairs. Cologne downstairs.)"}
	])

func on_ledger_decoy_interacted() -> void:
	var decoy_node := get_node_or_null("LedgerDecoy")
	if decoy_node == null or not decoy_node.monitoring:
		return
	if ledger_decoy_cleared:
		return
	if clues_found < TOTAL_CLUES:
		return
	ledger_decoy_cleared = true
	var decoy := get_node_or_null("LedgerDecoy")
	if decoy:
		decoy.visible = false
		decoy.remove_from_group("interactable")
		decoy.set_deferred("monitoring", false)
	var ledger := get_node_or_null("LedgerZone")
	if ledger:
		ledger.global_position = Vector2(1085, 88)
		ledger.visible = true
	AudioManager.play_sfx("note_read")
	_play_reactive_dialogue([
		{"speaker": "Parmida", "text": "Blank pages. Sterling's crew planted a prop ledger."},
		{"speaker": "Louis", "text": "Real one's taped under the amp. Classic cheap trick."}
	])
	QuestManager.set_objective("Twist: decoy ledger. Grab the real blackmail book under the backstage amp.", mission_id)
	_advance_step(MissionStep.LEDGER_PICKUP)

func velvet_prop_interacted(prop_id: String) -> void:
	match prop_id:
		"staff_badge":
			if staff_badge_secured:
				return
			staff_badge_secured = true
			var badge_node := get_node_or_null("StaffBadgePickup")
			if badge_node:
				badge_node.queue_free()
			var gate := get_node_or_null("StaffSouthGate")
			if gate:
				gate.queue_free()
			AudioManager.play_sfx("item_pickup")
			_play_reactive_dialogue([
				{"speaker": "Parmida", "text": "Borrowed badge. Return it with a thank-you note—or don't."}
			])
			QuestManager.set_objective("Staff badge acquired. Optional: backstage service hatch below the green room.", mission_id)
		"sound_board":
			if sound_check_done:
				return
			sound_check_done = true
			_play_reactive_dialogue([
				{"speaker": "Parmida", "text": "Monitors are flat. If the bouncers had souls, they'd thank us."}
			])
			QuestManager.set_objective("Sound check done. House mix is clean.", mission_id)
		"vip_phone":
			_play_reactive_dialogue([
				{"speaker": "Parmida", "text": "Voicemail from Sterling's assistant: 'Shred before midnight.' Too late."}
			])
		_:
			pass

func _on_ledger_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if current_step != MissionStep.LEDGER_PICKUP:
		return
	if ledger_collected:
		return
	if not club_owner_defeated:
		return
	
	var ledger := get_node_or_null("LedgerZone")
	if not ledger or not ledger.visible:
		return
	
	ledger_collected = true
	ledger.visible = false
	ledger.set_deferred("monitoring", false)
	AudioManager.play_sfx("item_pickup")
	
	QuestManager.set_objective("Ledger secured. Yordano is tuning up for your exit.", mission_id)
	_advance_step(MissionStep.ESCAPE)

func _show_music_puzzle_prompt() -> void:
	if music_puzzle_solved or active_puzzle != null:
		return
	
	var lines := [
		{"speaker": "Bentley", "text": "Woof! (There's a setlist on the stage...)"},
		{"speaker": "Parmida", "text": "The songs are out of order. If I fix the setlist, it should unlock the backstage area."}
	]
	if sound_check_done:
		lines.append({"speaker": "Parmida", "text": "Board's dialed in—listen for the crowd cues in the manager's notes."})
	DialogueManager.start_simple_dialogue(lines)

func start_music_puzzle() -> void:
	if music_puzzle_solved or active_puzzle != null:
		return
	
	var puzzle_scene := preload("res://src/puzzles/music/music_puzzle.tscn")
	active_puzzle = puzzle_scene.instantiate()
	active_puzzle.puzzle_solved.connect(_on_music_puzzle_solved)
	active_puzzle.puzzle_failed.connect(_on_music_puzzle_failed)
	# Full-screen Control must not be a direct child of Node2D (mission root): invalid UI
	# canvas breaks layout/focus and can hard-crash when opening the setlist puzzle.
	var puzzle_canvas := CanvasLayer.new()
	puzzle_canvas.name = "MusicPuzzleCanvas"
	puzzle_canvas.layer = 90
	puzzle_canvas.add_to_group("blocking_ui")
	add_child(puzzle_canvas)
	puzzle_canvas.add_child(active_puzzle)
	active_puzzle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_puzzle.tree_exiting.connect(_free_music_puzzle_canvas.bind(puzzle_canvas))


func _free_music_puzzle_canvas(host: CanvasLayer) -> void:
	if is_instance_valid(host):
		host.remove_from_group("blocking_ui")
		host.call_deferred("queue_free")


func _on_music_puzzle_solved() -> void:
	music_puzzle_solved = true
	active_puzzle = null
	AudioManager.play_sfx("puzzle_solved")
	QuestManager.set_objective("Stage cleared. Slip backstage—then press E on the rig stairs to enter the owner suite (boss fight).", mission_id)
	_play_reactive_dialogue([
		{"speaker": "Yordano", "text": "House lights love you. Don't waste the downbeat."}
	])
	
	var blocker := get_node_or_null("BackstageBlocker")
	if blocker:
		blocker.queue_free()
	var stairs_block := get_node_or_null("StairsBlocker")
	if stairs_block:
		stairs_block.queue_free()
	var wayfinding := get_node_or_null("StairsWayfinding")
	if wayfinding:
		wayfinding.visible = true
	var sl := get_node_or_null("OwnerSuiteStairs/StairsInteractLabel") as Label
	if sl:
		sl.visible = true


func _on_music_puzzle_failed() -> void:
	active_puzzle = null
	_begin_setlist_alarm()


func _begin_setlist_alarm() -> void:
	if setlist_alarm_active:
		return
	setlist_alarm_active = true
	wrong_puzzle_attempts += 1
	bouncer_alerted = true
	AudioManager.play_sfx("alert")
	AudioManager.play_sfx("bass_drop_explosion")
	_show_alarm_overlay()
	_spawn_alarm_reinforcements()
	QuestManager.set_objective("BASS ALARM: Stay low—try the BAR corner or DANCE FLOOR shadow until Yordano steals the noise.", mission_id)
	_play_reactive_dialogue([
		{"speaker": "Yordano", "text": "Hold four counts—I’m folding this feedback into the bridge."}
	])
	get_tree().create_timer(8.0).timeout.connect(_resolve_setlist_alarm)


func _show_alarm_overlay() -> void:
	if _alarm_overlay != null:
		return
	var layer := CanvasLayer.new()
	layer.name = "SetlistAlarmOverlay"
	layer.layer = 88
	var dim := ColorRect.new()
	dim.color = Color(0.85, 0.08, 0.08, 0.38)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	add_child(layer)
	_alarm_overlay = layer


func _spawn_alarm_reinforcements() -> void:
	var packed := load(GUARD_SCENE_PATH)
	if packed == null or not (packed is PackedScene):
		push_error("JazzClubMission: missing guard scene at %s" % GUARD_SCENE_PATH)
		return
	var guard_scene := packed as PackedScene
	for marker_name in [&"AlarmSpawn1", &"AlarmSpawn2"]:
		var m := get_node_or_null(String(marker_name))
		if m == null:
			continue
		var g: Node = guard_scene.instantiate()
		add_child(g)
		g.global_position = m.global_position
		g.aggro_range = 2000.0
		g.chase_speed = max(float(g.chase_speed), 220.0)
		g.speed = max(float(g.speed), 185.0)
		_alarm_guards.append(g)


func _resolve_setlist_alarm() -> void:
	if not setlist_alarm_active:
		return
	setlist_alarm_active = false
	if _alarm_overlay != null and is_instance_valid(_alarm_overlay):
		_alarm_overlay.queue_free()
	_alarm_overlay = null
	for g in _alarm_guards:
		if is_instance_valid(g):
			g.queue_free()
	_alarm_guards.clear()
	QuestManager.set_objective("House mix swallows the alarm—adjust the setlist when you're ready.", mission_id)
	_play_reactive_dialogue([
		{"speaker": "Yordano", "text": "Crowd thinks that red wash was gel—not security."}
	])

func complete_level() -> void:
	if not ledger_collected:
		QuestManager.set_objective("The ledger stays. We do not leave witnesses.", mission_id)
		return
	CollectibleManager.collect_polaroid("jazz_club_polaroid")
	if secret_velvet_collectible:
		GameState.intel_points += 1
		EventBus.objective_updated.emit("Bonus: Velvet Smiski stash. +1 intel.")
	super.complete_level()

func _process(_delta: float) -> void:
	super._process(_delta)

func on_bentley_sniff() -> void:
	if current_step == MissionStep.BACKSTAGE_SEARCH or current_step == MissionStep.LEDGER_PICKUP:
		var ledger := get_node_or_null("LedgerZone")
		if ledger and clues_found >= TOTAL_CLUES and club_owner_defeated and ledger.visible:
			EventBus.show_objective_marker.emit(true, ledger.global_position)
			QuestManager.set_objective("Bentley smells the briefcase—follow the marker.", mission_id)

func interact(_player: Node) -> void:
	if current_step == MissionStep.MUSIC_PUZZLE and not music_puzzle_solved:
		start_music_puzzle()
