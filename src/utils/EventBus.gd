extends Node

@warning_ignore("unused_signal")
signal debug_logged(message)
@warning_ignore("unused_signal")
signal game_state_changed
@warning_ignore("unused_signal")
signal game_saved(slot)
@warning_ignore("unused_signal")
signal game_loaded(slot)
@warning_ignore("unused_signal")
signal mission_started(mission_id)
@warning_ignore("unused_signal")
signal mission_completed(mission_id, rewards)
@warning_ignore("unused_signal")
signal mission_failed(mission_id, reason)
@warning_ignore("unused_signal")
signal mission_result_ready(result)
@warning_ignore("unused_signal")
signal objective_updated(text)
@warning_ignore("unused_signal")
signal show_objective_marker(show, position)
@warning_ignore("unused_signal")
signal player_health_changed(current_health, max_health)
@warning_ignore("unused_signal")
signal player_damaged(amount, current_health)
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal bentley_meter_changed(current_value, max_value)
@warning_ignore("unused_signal")
signal bentley_ability_used(ability_id)
@warning_ignore("unused_signal")
signal dialogue_started(lines)
@warning_ignore("unused_signal")
signal dialogue_line_changed(speaker, text)
@warning_ignore("unused_signal")
signal dialogue_ended
@warning_ignore("unused_signal")
signal card_selection_changed(selected_cards)
@warning_ignore("unused_signal")
signal card_triggered(card_id: String, status: String, message: String)
@warning_ignore("unused_signal")
signal card_unlocked(card_id)
@warning_ignore("unused_signal")
signal polaroid_collected(polaroid_id)
@warning_ignore("unused_signal")
signal friend_helped(friend_id)
@warning_ignore("unused_signal")
signal pause_requested
@warning_ignore("unused_signal")
signal screen_shake(intensity: float, duration: float)
@warning_ignore("unused_signal")
signal combat_style_changed(current_style: float, max_style: float)

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
