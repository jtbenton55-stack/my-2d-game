# EventBus.gd
# Signal hub for decoupled communication between systems - V2 for Untitled Heist RPG

extends Node

# ===== PLAYER SIGNALS =====
signal player_health_changed(new_health, max_health)
signal player_died
signal player_dodged
signal player_stealth_changed(is_stealth)
signal player_upgraded(upgrade_id)

# ===== ENEMY SIGNALS =====
signal enemy_spotted_player(enemy, player)
signal enemy_lost_player(enemy)
signal enemy_died(enemy)

# ===== COMBAT SIGNALS =====
signal damage_dealt(source, target, amount)
signal damage_received(target, source, amount)
signal combat_started
signal combat_ended

# ===== MISSION SIGNALS (V2) =====
signal mission_started(mission_id)
signal mission_completed(mission_id, success)
signal mission_ended(mission_id)
signal objective_completed(objective_id)

# ===== SCHEME CARD SIGNALS =====
signal card_unlocked(card_id)
signal cards_selected(card_ids)
signal card_effect_activated(card_id, effect_key)

# ===== FRIEND/FAVOR SIGNALS =====
signal friend_helped(friend_id)
signal favor_triggered(friend_id, mission_id)

# ===== COLLECTIBLE SIGNALS =====
signal polaroid_collected(polaroid_id)
signal trinket_collected(trinket_id)
signal stationery_collected(stationery_id)
signal polaroid_wall_updated

# ===== BENTLEY SIGNALS =====
signal bentley_upgraded(upgrade_id)
signal bentley_ability_used(ability_id)
signal bentley_mood_changed(mood)

# ===== DIALOGUE SIGNALS =====
signal dialogue_started(speaker, text)
signal dialogue_choice_selected(choice_id)
signal dialogue_ended
signal dialogue_flag_set(flag, value)

# ===== QUEST SIGNALS =====
signal quest_started(quest_id, objective)
signal quest_updated(objective_text)
signal quest_completed(quest_id)

# ===== INTEL/CURRENCY SIGNALS =====
signal intel_changed(amount)
signal intel_spent(amount, reason)

# ===== UI SIGNALS =====
signal show_detection_meter(visible)
signal update_detection_meter(value)
signal show_objective_marker(visible, position)

# ===== PUZZLE SIGNALS =====
signal puzzle_started(question, context, choices)
signal puzzle_feedback(is_correct, message)
signal puzzle_ended(success)
signal show_scheme_card_menu
signal hide_scheme_card_menu
signal show_mission_select
signal hide_mission_select
signal show_mission_result(success, rewards)
signal show_failure_screen(message, partial_progress)
signal update_polaroid_wall

# ===== SCENE/NAVIGATION SIGNALS =====
signal scene_change_requested(scene_path)
signal return_to_hideout
signal enter_city_hub

# ===== SAVE/LOAD SIGNALS =====
signal game_saved(slot)
signal game_loaded(slot)
signal auto_save_triggered

# ===== SETTINGS SIGNALS =====
signal settings_changed(category, key, value)

# ===== DEBUG SIGNALS =====
signal debug_message(message)

# Helper function to emit debug messages
func debug(msg: String) -> void:
	debug_message.emit(msg)
	print("[EventBus] ", msg)

# ===== CONVENIENCE FUNCTIONS =====

func start_mission(mission_id: String) -> void:
	mission_started.emit(mission_id)
	debug("Mission started: " + mission_id)

func complete_mission(mission_id: String, success: bool) -> void:
	mission_completed.emit(mission_id, success)
	debug("Mission completed: " + mission_id + " (success: " + str(success) + ")")

func unlock_card(card_id: String) -> void:
	card_unlocked.emit(card_id)
	debug("Card unlocked: " + card_id)

func collect_polaroid(polaroid_id: String) -> void:
	polaroid_collected.emit(polaroid_id)
	debug("Polaroid collected: " + polaroid_id)

func help_friend(friend_id: String) -> void:
	friend_helped.emit(friend_id)
	debug("Friend helped: " + friend_id)

func update_intel(amount: int) -> void:
	intel_changed.emit(amount)
	debug("Intel updated: " + str(amount))

func request_scene_change(scene_path: String) -> void:
	scene_change_requested.emit(scene_path)
	debug("Scene change requested: " + scene_path)

func request_return_to_hideout() -> void:
	return_to_hideout.emit()
	debug("Return to hideout requested")