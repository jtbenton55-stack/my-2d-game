extends "res://src/missions/InteractiveMission.gd"

# The Diamond a Year Job - Vault/timing/diamond fantasy
# Purpose: Crack the vault, avoid lasers, collect tribute diamonds

var year_one_collected := false
var year_two_collected := false
var year_three_collected := false
var vault_key_found := false
var timed_lock_solved := false
var hidden_diamond_found := false
var bryce_moment_shown := false
var bentley_moment_shown := false
var laser_a_active := true
var laser_b_active := true
var laser_timer := 0.0
var laser_phase := 0.0

@export var laser_rotation_speed := 0.5
@export var laser_damage := 15

func _ready() -> void:
	mission_id = "diamond_a_year_job"
	objective_text = "Find the vault key, solve the timed lock, and collect Sterling's tribute diamonds."
	guard_count = 5
	completion_item_name = "diamond"
	completion_line = "All diamonds secured. The vault is ours. Exit through the loading dock!"
	missing_item_line = "Bryce says the timing is still wrong. We need all three Year diamonds."
	super._ready()

	spawn_poop_bags_at_global_positions([Vector2(200, 820), Vector2(560, 360), Vector2(780, 520)])

	_setup_interactables()
	_setup_lasers()
	_show_opening_dialogue()

func _setup_interactables() -> void:
	# Year diamonds
	var year_one := get_node_or_null("YearOneZone")
	if year_one:
		year_one.add_to_group("interactable")
		year_one.body_entered.connect(_on_year_one_entered)
	
	var year_two := get_node_or_null("YearTwoZone")
	if year_two:
		year_two.add_to_group("interactable")
		year_two.body_entered.connect(_on_year_two_entered)
	
	var year_three := get_node_or_null("YearThreeZone")
	if year_three:
		year_three.add_to_group("interactable")
		year_three.body_entered.connect(_on_year_three_entered)
	
	# Vault key
	var key_zone := get_node_or_null("VaultKeyZone")
	if key_zone:
		key_zone.add_to_group("interactable")
		key_zone.body_entered.connect(_on_key_entered)
	
	# Timed lock
	var lock_zone := get_node_or_null("TimedLockZone")
	if lock_zone:
		lock_zone.add_to_group("interactable")
		lock_zone.body_entered.connect(_on_lock_entered)
	
	# Hidden diamond (optional)
	var hidden_zone := get_node_or_null("HiddenDiamondZone")
	if hidden_zone:
		hidden_zone.add_to_group("interactable")
		hidden_zone.body_entered.connect(_on_hidden_diamond_entered)
	
	# Intel
	var intel_zone := get_node_or_null("VaultNoteZone")
	if intel_zone:
		intel_zone.add_to_group("interactable")
		intel_zone.body_entered.connect(_on_intel_entered)
	
	# Bryce moment
	var bryce_zone := get_node_or_null("BryceZone")
	if bryce_zone:
		bryce_zone.add_to_group("interactable")
		bryce_zone.body_entered.connect(_on_bryce_entered)
	
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

func _setup_lasers() -> void:
	var laser_a := get_node_or_null("LaserLineA")
	var laser_b := get_node_or_null("LaserLineB")
	
	# Check for card effects
	if GameState.has_selected_card("bryce_swiss_timing"):
		laser_rotation_speed *= 0.5  # Slower lasers with Bryce's card
		QuestManager.set_objective("Bryce Swiss Timing active. Lasers moving at reduced speed.", mission_id)

func _process(delta: float) -> void:
	super._process(delta)
	_update_lasers(delta)

func _update_lasers(delta: float) -> void:
	laser_timer += delta
	laser_phase = fmod(laser_timer * laser_rotation_speed, PI * 2)
	
	var laser_a := get_node_or_null("LaserLineA")
	var laser_b := get_node_or_null("LaserLineB")
	
	if laser_a and laser_a_active:
		# Rotate laser A
		var base_points = PackedVector2Array([
			Vector2(420, 300), Vector2(1280, 760)
		])
		var center = Vector2(850, 530)
		var rotated_points := PackedVector2Array()
		for p in base_points:
			var offset = p - center
			var rotated_x = offset.x * cos(laser_phase) - offset.y * sin(laser_phase)
			var rotated_y = offset.x * sin(laser_phase) + offset.y * cos(laser_phase)
			rotated_points.append(center + Vector2(rotated_x, rotated_y))
		laser_a.points = rotated_points
		
		# Check collision with player
		if player and _is_point_near_line(player.global_position, laser_a.points[0], laser_a.points[1], 10.0):
			_damage_player_from_laser()
	
	if laser_b and laser_b_active:
		# Rotate laser B (opposite direction)
		var base_points = PackedVector2Array([
			Vector2(1280, 300), Vector2(420, 760)
		])
		var center = Vector2(850, 530)
		var rotated_points := PackedVector2Array()
		for p in base_points:
			var offset = p - center
			var rotated_x = offset.x * cos(-laser_phase) - offset.y * sin(-laser_phase)
			var rotated_y = offset.x * sin(-laser_phase) + offset.y * cos(-laser_phase)
			rotated_points.append(center + Vector2(rotated_x, rotated_y))
		laser_b.points = rotated_points
		
		# Check collision with player
		if player and _is_point_near_line(player.global_position, laser_b.points[0], laser_b.points[1], 10.0):
			_damage_player_from_laser()

func _is_point_near_line(point: Vector2, line_start: Vector2, line_end: Vector2, threshold: float) -> bool:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len_sq = line_vec.length_squared()
	
	if line_len_sq == 0:
		return point_vec.length() < threshold
	
	var t = clamp(point_vec.dot(line_vec) / line_len_sq, 0.0, 1.0)
	var closest = line_start + line_vec * t
	return point.distance_to(closest) < threshold

var _laser_damage_cooldown := 0.0

func _damage_player_from_laser() -> void:
	if _laser_damage_cooldown > 0:
		return
	_laser_damage_cooldown = 1.0
	GameState.damage_player(laser_damage)
	AudioManager.play_sfx("damage")
	QuestManager.set_objective("Watch the lasers! They're timed to Swiss precision.", mission_id)
	
	# Start cooldown timer
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(func(): _laser_damage_cooldown = 0.0)

func _show_opening_dialogue() -> void:
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Bryce", "text": "Sterling's vault. Swiss timing, laser grids, and three tribute diamonds. One for each year he crushed someone." },
		{ "speaker": "Jake", "text": "Whose diamonds are these?" },
		{ "speaker": "Bryce", "text": "Year One: a restaurant owner who refused to sell. Year Two: a jeweler who questioned his books. Year Three: you know what, let's just take them back." },
		{ "speaker": "Bentley", "text": "*determined woof*" }
	])

func _on_key_entered(body: Node) -> void:
	if body.is_in_group("player") and not vault_key_found:
		vault_key_found = true
		AudioManager.play_sfx("item_pickup")
		QuestManager.set_objective("Vault key secured! Now solve the timed lock.", mission_id)
		
		var key_zone := get_node_or_null("VaultKeyZone")
		if key_zone:
			key_zone.queue_free()
		
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Jake", "text": "Got the vault key. Hidden in the security desk." },
			{ "speaker": "Bryce", "text": "Good. Now the timed lock. You have 30 seconds to align the tumblers when you activate it." }
		])

func _on_lock_entered(body: Node) -> void:
	if body.is_in_group("player") and not timed_lock_solved:
		if not vault_key_found:
			QuestManager.set_objective("Need the vault key first! Check the security desk.", mission_id)
			return
		
		# Start timed lock challenge
		_start_timed_lock_challenge()

func _start_timed_lock_challenge() -> void:
	var time_limit := 30.0
	
	# Apply Bryce's card effect
	if GameState.has_selected_card("bryce_swiss_timing"):
		time_limit = 45.0
		QuestManager.set_objective("Bryce Swiss Timing: 45 seconds to solve the lock!", mission_id)
	else:
		QuestManager.set_objective("TIMED LOCK: 30 seconds! Align the tumblers!", mission_id)
	
	# For now, auto-complete the timed lock on entry (can be expanded with minigame)
	timed_lock_solved = true
	AudioManager.play_sfx("vault_open")
	
	# Disable lasers
	laser_a_active = false
	laser_b_active = false
	
	var laser_a := get_node_or_null("LaserLineA")
	var laser_b := get_node_or_null("LaserLineB")
	if laser_a:
		laser_a.default_color = Color(0.2, 0.8, 0.2, 0.4)  # Green, disabled
	if laser_b:
		laser_b.default_color = Color(0.2, 0.8, 0.2, 0.4)
	
	DialogueManager.start_simple_dialogue([
		{ "speaker": "Jake", "text": "Lock's open! Lasers are down!" },
		{ "speaker": "Bryce", "text": "Swiss timing, Jake. Always respect the clock." },
		{ "speaker": "Jake", "text": "Now let's get those diamonds." }
	])

func _on_year_one_entered(body: Node) -> void:
	if body.is_in_group("player") and not year_one_collected:
		if not timed_lock_solved:
			QuestManager.set_objective("The diamond is behind an active laser grid. Solve the lock first!", mission_id)
			return
		
		year_one_collected = true
		AudioManager.play_sfx("collect")
		
		var zone := get_node_or_null("YearOneZone")
		if zone:
			zone.queue_free()
		
		QuestManager.set_objective("Year One diamond collected! The restaurant owner's revenge begins. (%d/3)" % _count_diamonds(), mission_id)
		_check_all_diamonds()

func _on_year_two_entered(body: Node) -> void:
	if body.is_in_group("player") and not year_two_collected:
		if not timed_lock_solved:
			QuestManager.set_objective("The diamond is behind an active laser grid. Solve the lock first!", mission_id)
			return
		
		year_two_collected = true
		AudioManager.play_sfx("collect")
		
		var zone := get_node_or_null("YearTwoZone")
		if zone:
			zone.queue_free()
		
		QuestManager.set_objective("Year Two diamond collected! The jeweler's books are avenged. (%d/3)" % _count_diamonds(), mission_id)
		_check_all_diamonds()

func _on_year_three_entered(body: Node) -> void:
	if body.is_in_group("player") and not year_three_collected:
		if not timed_lock_solved:
			QuestManager.set_objective("The diamond is behind an active laser grid. Solve the lock first!", mission_id)
			return
		
		year_three_collected = true
		AudioManager.play_sfx("collect")
		
		var zone := get_node_or_null("YearThreeZone")
		if zone:
			zone.queue_free()
		
		QuestManager.set_objective("Year Three diamond collected! All tribute reclaimed! (%d/3)" % _count_diamonds(), mission_id)
		_check_all_diamonds()

func _on_hidden_diamond_entered(body: Node) -> void:
	if body.is_in_group("player") and not hidden_diamond_found:
		hidden_diamond_found = true
		GameState.intel_points += 2
		AudioManager.play_sfx("collect")
		
		var zone := get_node_or_null("HiddenDiamondZone")
		if zone:
			zone.queue_free()
		
		QuestManager.set_objective("Hidden vault diamond found! +2 intel! Bryce will want to hear about this.", mission_id)
		
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Jake", "text": "There's a fourth diamond. Hidden behind a false panel." },
			{ "speaker": "Bryce", "text": "Sterling's contingency. Always have a secret stash." },
			{ "speaker": "Jake", "text": "Not anymore." }
		])

func _count_diamonds() -> int:
	var count := 0
	if year_one_collected:
		count += 1
	if year_two_collected:
		count += 1
	if year_three_collected:
		count += 1
	return count

func _check_all_diamonds() -> void:
	if year_one_collected and year_two_collected and year_three_collected:
		QuestManager.set_objective("All three tribute diamonds secured! Exit through the loading dock!", mission_id)
		
		# Check for diamond_a_year card bonus
		if GameState.has_selected_card("diamond_a_year"):
			QuestManager.set_objective("Diamond a Year bonus active! Extra intel on extraction!", mission_id)
		
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Bryce", "text": "Three years of tribute, reclaimed. Every victim gets a piece of this back." },
			{ "speaker": "Jake", "text": "Sterling's empire runs on theft. We're just returning the favor." },
			{ "speaker": "Bentley", "text": "*proud woof*" }
		])

func _on_intel_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var zone := get_node_or_null("VaultNoteZone")
		if zone:
			zone.queue_free()
		GameState.intel_points += 1
		AudioManager.play_sfx("intel_collect")
		QuestManager.set_objective("Vault schematics found! +1 intel.", mission_id)

func _on_bryce_entered(body: Node) -> void:
	if body.is_in_group("player") and not bryce_moment_shown:
		bryce_moment_shown = true
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Bryce", "text": "You know why I know so much about Swiss vaults?" },
			{ "speaker": "Jake", "text": "Enlighten me." },
			{ "speaker": "Bryce", "text": "Because Sterling tried to bury my family's business in paperwork. Swiss accounts, offshore shells. I learned his system to destroy it." },
			{ "speaker": "Jake", "text": "And now we're using that knowledge." },
			{ "speaker": "Bryce", "text": "Knowledge is only valuable when it's used against the people who hoarded it." }
		])

func _on_bentley_moment_entered(body: Node) -> void:
	if body.is_in_group("player") and not bentley_moment_shown:
		bentley_moment_shown = true
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Bentley", "text": "*stares at a laser beam, head tilted*" },
			{ "speaker": "Jake", "text": "Don't even think about it, buddy. No chasing the lasers." },
			{ "speaker": "Bentley", "text": "*sad whine, but steps back*" },
			{ "speaker": "Jake", "text": "Good dog. We'll find you a tennis ball that doesn't cut you in half." }
		])

func _on_polaroid_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var zone := get_node_or_null("PolaroidZone")
		if zone:
			zone.queue_free()
		CollectibleManager.collect_polaroid("diamond_vault_polaroid")
		AudioManager.play_sfx("collect")
		QuestManager.set_objective("Vault heist captured! This one's going on the crew board.", mission_id)

func complete_level() -> void:
	if not year_one_collected or not year_two_collected or not year_three_collected:
		var missing := []
		if not year_one_collected:
			missing.append("Year One")
		if not year_two_collected:
			missing.append("Year Two")
		if not year_three_collected:
			missing.append("Year Three")
		QuestManager.set_objective("Missing diamonds: " + ", ".join(missing), mission_id)
		return
	
	CollectibleManager.collect_polaroid("diamond_vault_polaroid")
	super.complete_level()
