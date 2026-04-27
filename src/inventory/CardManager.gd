# CardManager.gd
# Manages Scheme Cards for Untitled Heist RPG

extends Node

# Card definitions - these would ideally be loaded from resources
var _all_cards: Dictionary = {}

func _ready() -> void:
	_initialize_cards()
	EventBus.debug("CardManager loaded")

func _initialize_cards() -> void:
	# Define all Scheme Cards
	_all_cards = {
		# Default cards (available from start)
		"bentley_dental_boy": SchemeCard.create(
			"bentley_dental_boy",
			"Bentley's Dental Boy",
			"Bentley gets one free defensive save",
			"boolean",
			"has_dental_boy",
			1.0,
			"default"
		),
		"fish_treat_focus": SchemeCard.create(
			"fish_treat_focus",
			"Fish Treat Focus",
			"Bentley ability meter recharges faster",
			"stat_mod",
			"bentley_recharge_rate",
			1.5,
			"default"
		),
		"jakes_resident_orders": SchemeCard.create(
			"jakes_resident_orders",
			"Jake's Resident Orders",
			"Start with one med kit",
			"boolean",
			"has_med_kit",
			1.0,
			"default"
		),
		
		# Mission reward cards
		"louis_delivery_route": SchemeCard.create(
			"louis_delivery_route",
			"Louis Delivery Route",
			"Reveals a side entrance or shortcut",
			"boolean",
			"has_delivery_route",
			1.0,
			"taco_bell_drop"
		),
		"mere_legal_eyes": SchemeCard.create(
			"mere_legal_eyes",
			"Mere's Legal Eyes",
			"Highlights dangerous dialogue choices",
			"boolean",
			"has_legal_eyes",
			1.0,
			"rewrite_room"
		),
		"yordano_bass_drop": SchemeCard.create(
			"yordano_bass_drop",
			"Yordano Bass Drop",
			"One area stun in music rooms",
			"boolean",
			"has_bass_drop",
			1.0,
			"velvet_paw_jazz_club"
		),
		"stationery_queen": SchemeCard.create(
			"stationery_queen",
			"Stationery Queen",
			"Retry one failed puzzle",
			"boolean",
			"has_stationery_queen",
			1.0,
			"rewrite_room"
		),
		"doms_getaway_keys": SchemeCard.create(
			"doms_getaway_keys",
			"Dom's Getaway Keys",
			"Improved escape speed",
			"stat_mod",
			"escape_speed",
			1.3,
			"fast_family_getaway"
		),
		
		# Stretch goal cards
		"persian_tea_focus": SchemeCard.create(
			"persian_tea_focus",
			"Persian Tea Focus",
			"Briefly slows time during puzzles/dodges",
			"stat_mod",
			"time_slow",
			0.7,
			"persian_tea_mission"
		),
		"jcs_london_contact": SchemeCard.create(
			"jcs_london_contact",
			"JC's London Contact",
			"Reduces elite security, opens luxury routes",
			"boolean",
			"has_london_contact",
			1.0,
			"london_mission"
		),
		"bryce_swiss_timing": SchemeCard.create(
			"bryce_swiss_timing",
			"Bryce's Swiss Timing",
			"Slows timed hazards/vaults/patrols",
			"stat_mod",
			"hazard_slow",
			0.6,
			"diamond_mission"
		),
		"clorox_wipe_protocol": SchemeCard.create(
			"clorox_wipe_protocol",
			"Clorox Wipe Protocol",
			"Cleans hazard tiles, reveals codes",
			"boolean",
			"has_clorox_wipe",
			1.0,
			"clean_job"
		),
		"two_letters_away": SchemeCard.create(
			"two_letters_away",
			"Two Letters Away",
			"Auto-decodes one cipher per heist",
			"boolean",
			"has_two_letters",
			1.0,
			"jazz_club_hidden"
		),
		"diamond_a_year": SchemeCard.create(
			"diamond_a_year",
			"Diamond a Year",
			"Increases vault rewards",
			"stat_mod",
			"vault_reward",
			1.5,
			"diamond_mission"
		),
		"polaroid_proof": SchemeCard.create(
			"polaroid_proof",
			"Polaroid Proof",
			"Captures evidence remotely",
			"boolean",
			"has_polaroid_proof",
			1.0,
			"evidence_mission"
		),
		"violet_counterpunch": SchemeCard.create(
			"violet_counterpunch",
			"Violet's Counterpunch",
			"Boosts melee, parry after perfect dodge",
			"stat_mod",
			"melee_damage",
			1.3,
			"arm_wrestling"
		)
	}

# ===== PUBLIC API =====

func get_all_cards() -> Array[SchemeCard]:
	"""Get all card definitions"""
	return _all_cards.values()

func get_card(card_id: String) -> SchemeCard:
	"""Get specific card by ID"""
	return _all_cards.get(card_id)

func get_unlocked_cards() -> Array[SchemeCard]:
	"""Get cards unlocked in GameState"""
	var unlocked = []
	var game_state = get_node("/root/GameState")
	
	if not game_state:
		EventBus.debug("CardManager: GameState not found")
		return unlocked
	
	for card_id in game_state.unlocked_cards:
		var card = get_card(card_id)
		if card:
			unlocked.append(card)
	
	return unlocked

func get_unlocked_card_ids() -> Array[String]:
	"""Get card IDs unlocked in GameState"""
	var game_state = get_node("/root/GameState")
	if not game_state:
		return []
	return game_state.unlocked_cards.duplicate()

func select_cards(card_ids: Array[String]) -> void:
	"""Select up to 3 cards for current mission"""
	var game_state = get_node("/root/GameState")
	if not game_state:
		EventBus.debug("CardManager: GameState not found for select_cards")
		return
	
	game_state.select_cards(card_ids)

func get_selected_cards() -> Array[SchemeCard]:
	"""Get currently selected cards"""
	var game_state = get_node("/root/GameState")
	if not game_state:
		return []
	
	var selected = []
	for card_id in game_state.selected_cards:
		var card = get_card(card_id)
		if card:
			selected.append(card)
	
	return selected

func get_selected_card_ids() -> Array[String]:
	"""Get IDs of currently selected cards"""
	var game_state = get_node("/root/GameState")
	if not game_state:
		return []
	return game_state.selected_cards.duplicate()

func has_card_effect(effect_key: String) -> bool:
	"""Check if any selected card has this effect"""
	var selected_cards = get_selected_cards()
	for card in selected_cards:
		if card.effect_key == effect_key:
			return true
	return false

func get_card_value(effect_key: String) -> float:
	"""Get modifier value for effect from selected cards"""
	var selected_cards = get_selected_cards()
	for card in selected_cards:
		if card.effect_key == effect_key:
			return card.effect_value
	return 0.0

func get_card_effects() -> Dictionary:
	"""Get all active effects from selected cards"""
	var effects = {}
	var selected_cards = get_selected_cards()
	
	for card in selected_cards:
		if card.effect_type == "boolean":
			effects[card.effect_key] = true
		elif card.effect_type == "stat_mod":
			effects[card.effect_key] = card.effect_value
		# "special" effects handled elsewhere
	
	return effects

func is_card_unlocked(card_id: String) -> bool:
	"""Check if card is unlocked"""
	var game_state = get_node("/root/GameState")
	if not game_state:
		return false
	return card_id in game_state.unlocked_cards

func unlock_card(card_id: String) -> void:
	"""Unlock a card"""
	var game_state = get_node("/root/GameState")
	if not game_state:
		EventBus.debug("CardManager: GameState not found for unlock_card")
		return
	
	game_state.unlock_card(card_id)

func clear_selected_cards() -> void:
	"""Clear selected cards"""
	var game_state = get_node("/root/GameState")
	if not game_state:
		EventBus.debug("CardManager: GameState not found for clear_selected_cards")
		return
	
	game_state.clear_selected_cards()

# ===== CARD EFFECT APPLICATIONS =====

func apply_card_effects_to_player(player: Node) -> void:
	"""Apply card effects to player node"""
	if not player:
		return
	
	var effects = get_card_effects()
	
	# Apply boolean effects
	if effects.get("has_med_kit", false):
		# Player starts with med kit
		EventBus.debug("Card effect: Player has med kit")
		# This would be handled by player inventory system
	
	if effects.get("has_dental_boy", false):
		# Bentley gets one free save
		EventBus.debug("Card effect: Bentley has dental boy")
		# This would be handled by Bentley's ability system
	
	# Apply stat modifiers
	var escape_speed_mod = effects.get("escape_speed", 1.0)
	if escape_speed_mod != 1.0:
		EventBus.debug("Card effect: Escape speed x" + str(escape_speed_mod))
		# This would modify player movement speed during escapes
	
	var bentley_recharge_mod = effects.get("bentley_recharge_rate", 1.0)
	if bentley_recharge_mod != 1.0:
		EventBus.debug("Card effect: Bentley recharge rate x" + str(bentley_recharge_mod))
		# This would modify Bentley's ability cooldown
	
	# Stretch card effects
	var time_slow_mod = effects.get("time_slow", 1.0)
	if time_slow_mod != 1.0:
		EventBus.debug("Card effect: Time slow x" + str(time_slow_mod))
		# This would modify puzzle/dodge timing
	
	var vault_reward_mod = effects.get("vault_reward", 1.0)
	if vault_reward_mod != 1.0:
		EventBus.debug("Card effect: Vault reward x" + str(vault_reward_mod))
		# This would modify vault rewards
	
	var hazard_slow_mod = effects.get("hazard_slow", 1.0)
	if hazard_slow_mod != 1.0:
		EventBus.debug("Card effect: Hazard slow x" + str(hazard_slow_mod))
		# This would modify hazard timing
	
	var melee_damage_mod = effects.get("melee_damage", 1.0)
	if melee_damage_mod != 1.0:
		EventBus.debug("Card effect: Melee damage x" + str(melee_damage_mod))
		# This would modify melee damage
	
	# Boolean stretch effects
	if effects.get("has_clorox_wipe", false):
		EventBus.debug("Card effect: Has Clorox Wipe")
		# Cleans hazard tiles
	
	if effects.get("has_two_letters", false):
		EventBus.debug("Card effect: Has Two Letters Away")
		# Auto-decodes ciphers
	
	if effects.get("has_london_contact", false):
		EventBus.debug("Card effect: Has JC's London Contact")
		# Reduces elite security
	
	if effects.get("has_polaroid_proof", false):
		EventBus.debug("Card effect: Has Polaroid Proof")
		# Captures evidence remotely

func check_card_effect_for_mission(mission_id: String) -> Dictionary:
	"""Check which card effects are relevant for a mission"""
	var relevant_effects = {}
	var selected_cards = get_selected_cards()
	
	# Mission-specific card benefits
	match mission_id:
		"taco_bell_drop":
			# Louis Delivery Route reveals shortcuts
			if has_card_effect("has_delivery_route"):
				relevant_effects["shortcut_revealed"] = true
		
		"velvet_paw_jazz_club":
			# Yordano Bass Drop stuns in music rooms
			if has_card_effect("has_bass_drop"):
				relevant_effects["area_stun_available"] = true
		
		"rewrite_room":
			# Mere's Legal Eyes highlights dangerous choices
			if has_card_effect("has_legal_eyes"):
				relevant_effects["danger_highlighted"] = true
			# Stationery Queen allows puzzle retry
			if has_card_effect("has_stationery_queen"):
				relevant_effects["puzzle_retry"] = true
		
		"fast_family_getaway":
			# Dom's Getaway Keys improves escape speed
			var speed_mod = get_card_value("escape_speed")
			if speed_mod > 1.0:
				relevant_effects["escape_speed_mod"] = speed_mod
		
		# Stretch mission effects
		"persian_tea_mission":
			# Persian Tea Focus slows time
			var time_mod = get_card_value("time_slow")
			if time_mod < 1.0:
				relevant_effects["time_slow_mod"] = time_mod
		
		"diamond_mission":
			# Diamond a Year increases vault rewards
			var vault_mod = get_card_value("vault_reward")
			if vault_mod > 1.0:
				relevant_effects["vault_reward_mod"] = vault_mod
			# Bryce's Swiss Timing slows hazards
			var hazard_mod = get_card_value("hazard_slow")
			if hazard_mod < 1.0:
				relevant_effects["hazard_slow_mod"] = hazard_mod
		
		"clean_job":
			# Clorox Wipe Protocol cleans hazards
			if has_card_effect("has_clorox_wipe"):
				relevant_effects["hazard_clean"] = true
		
		"jazz_club_hidden":
			# Two Letters Away auto-decodes ciphers
			if has_card_effect("has_two_letters"):
				relevant_effects["auto_decode"] = true
		
		"london_mission":
			# JC's London Contact reduces elite security
			if has_card_effect("has_london_contact"):
				relevant_effects["elite_security_reduced"] = true
		
		"evidence_mission":
			# Polaroid Proof captures evidence remotely
			if has_card_effect("has_polaroid_proof"):
				relevant_effects["remote_capture"] = true
		
		"arm_wrestling":
			# Violet's Counterpunch boosts melee
			var melee_mod = get_card_value("melee_damage")
			if melee_mod > 1.0:
				relevant_effects["melee_damage_mod"] = melee_mod
	
	return relevant_effects