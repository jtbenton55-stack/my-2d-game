extends Node

func _ready() -> void:
	EventBus.debug("CardEffects ready")

func get_player_max_health() -> int:
	var base := 100
	if GameState.has_selected_card("jakes_resident_orders"):
		base += 20
	return base

func get_player_speed_multiplier() -> float:
	var mult := 1.0
	if GameState.has_selected_card("doms_getaway_keys"):
		mult += 0.15
	if GameState.has_selected_card("yordano_bass_drop"):
		mult += 0.10
	return mult

func get_player_stealth_multiplier() -> float:
	var mult := 1.0
	if GameState.has_selected_card("persian_tea_focus"):
		mult -= 0.25
	return mult

func get_bentley_recharge_multiplier() -> float:
	var mult := 1.0
	if GameState.has_selected_card("fish_treat_focus"):
		mult += 0.60
	if GameState.has_selected_card("two_letters_away"):
		mult += 0.30
	return mult

func get_bentley_bark_radius_multiplier() -> float:
	var mult := 1.0
	if GameState.has_selected_card("bryce_swiss_timing"):
		mult += 0.25
	return mult

func get_bentley_sniff_cooldown_multiplier() -> float:
	var mult := 1.0
	if GameState.has_selected_card("fish_treat_focus"):
		mult -= 0.35
	if GameState.has_selected_card("two_letters_away"):
		mult -= 0.15
	return maxf(0.1, mult)

func get_bentley_fetch_cooldown_multiplier() -> float:
	var mult := 1.0
	if GameState.has_selected_card("fish_treat_focus"):
		mult -= 0.25
	return maxf(0.1, mult)

func get_bentley_fetch_range_multiplier() -> float:
	var mult := 1.0
	if GameState.has_selected_card("fish_treat_focus"):
		mult += 0.50
	if GameState.has_selected_card("two_letters_away"):
		mult += 0.25
	return mult

func has_med_kit() -> bool:
	return GameState.has_selected_card("jakes_resident_orders")

func has_dental_boy_save() -> bool:
	return GameState.has_selected_card("bentley_dental_boy")

func has_delivery_route() -> bool:
	return GameState.has_selected_card("louis_delivery_route")

func has_legal_protection() -> bool:
	return GameState.has_selected_card("mere_legal_eyes")

func has_clorox_protocol() -> bool:
	return GameState.has_selected_card("clorox_wipe_protocol")

func get_attack_damage_bonus() -> int:
	var bonus := 0
	if GameState.has_selected_card("violet_counterpunch"):
		bonus += 5
	return bonus

func get_intel_bonus() -> int:
	var bonus := 0
	if GameState.has_selected_card("polaroid_proof"):
		bonus += 1
	return bonus

func show_sniff_trail() -> bool:
	return GameState.has_selected_card("fish_treat_focus") or GameState.has_selected_card("two_letters_away")

func can_see_loot_through_walls() -> bool:
	return GameState.has_selected_card("diamond_a_year")

func get_guard_detection_reduction() -> float:
	var reduction := 0.0
	if GameState.has_selected_card("stationery_queen"):
		reduction += 0.15
	return reduction

func get_cooldown_reduction() -> float:
	var reduction := 0.0
	if GameState.has_selected_card("jc_london_contact"):
		reduction += 0.10
	return reduction


func get_combo_window_multiplier() -> float:
	var mult := 1.0
	if GameState.has_selected_card("jc_london_contact"):
		mult += 0.12
	return mult


func get_style_decay_reduction() -> float:
	var reduction := 0.0
	if GameState.has_selected_card("persian_tea_focus"):
		reduction += 0.22
	return reduction


func get_finisher_damage_bonus() -> float:
	var bonus := 0.0
	if GameState.has_selected_card("violet_counterpunch"):
		bonus += 12.0
	return bonus
