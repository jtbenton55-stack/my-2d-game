extends Node

signal debug_logged(message)
signal game_state_changed
signal game_saved(slot)
signal game_loaded(slot)
signal mission_started(mission_id)
signal mission_completed(mission_id, rewards)
signal mission_failed(mission_id, reason)
signal mission_result_ready(result)
signal objective_updated(text)
signal show_objective_marker(show, position)
signal player_health_changed(current_health, max_health)
signal player_damaged(amount, current_health)
signal player_died
signal bentley_meter_changed(current_value, max_value)
signal bentley_ability_used(ability_id)
signal dialogue_started(lines)
signal dialogue_line_changed(speaker, text)
signal dialogue_ended
signal card_selection_changed(selected_cards)
signal card_unlocked(card_id)
signal polaroid_collected(polaroid_id)
signal friend_helped(friend_id)
signal pause_requested

var verbose := true
var log_history: Array[String] = []
const MAX_LOG_HISTORY := 200

func debug(message: String) -> void:
	var text := "[OpenClaw] " + message
	if verbose:
		print(text)
	log_history.append(text)
	if log_history.size() > MAX_LOG_HISTORY:
		log_history.pop_front()
	debug_logged.emit(text)

func warn(message: String) -> void:
	debug("WARNING: " + message)

func info(message: String) -> void:
	debug(message)
