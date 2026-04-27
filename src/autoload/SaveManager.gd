# SaveManager.gd
# JSON save/load with 3 slots, auto-save flag
# V2: Uses GameState.to_dict() / from_dict() for persistence

extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3
const AUTO_SAVE_SLOT := 0  # Slot 0 is auto-save
const SAVE_VERSION := "0.2.0"

var auto_save_enabled: bool = true
var current_slot: int = -1

func _ready() -> void:
	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	EventBus.debug("SaveManager V2 loaded")

# Save game to a specific slot
func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		EventBus.debug("Invalid save slot: " + str(slot))
		return false
	
	var save_data := _collect_save_data()
	var file_path := SAVE_DIR + "save_" + str(slot) + ".json"
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var error := FileAccess.get_open_error()
		EventBus.debug("Failed to open save file: " + str(error))
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	current_slot = slot
	EventBus.game_saved.emit(slot)
	EventBus.debug("Game saved to slot " + str(slot))
	return true

# Load game from a specific slot
func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		EventBus.debug("Invalid load slot: " + str(slot))
		return false
	
	var file_path := SAVE_DIR + "save_" + str(slot) + ".json"
	
	if not FileAccess.file_exists(file_path):
		EventBus.debug("Save file doesn't exist: " + file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error := FileAccess.get_open_error()
		EventBus.debug("Failed to open save file: " + str(error))
		return false
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		EventBus.debug("Failed to parse save JSON: " + json.get_error_message())
		return false
	
	var save_data: Dictionary = json.get_data()
	_apply_save_data(save_data)
	
	current_slot = slot
	EventBus.game_loaded.emit(slot)
	EventBus.debug("Game loaded from slot " + str(slot))
	return true

# Auto-save (if enabled)
func auto_save() -> void:
	if auto_save_enabled:
		if save_game(AUTO_SAVE_SLOT):
			EventBus.auto_save_triggered.emit()

# Check if a slot has a save file
func has_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	
	var file_path := SAVE_DIR + "save_" + str(slot) + ".json"
	return FileAccess.file_exists(file_path)

# Get save metadata (timestamp, player health, etc.)
func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	
	var file_path := SAVE_DIR + "save_" + str(slot) + ".json"
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return {}
	
	var save_data: Dictionary = json.get_data()
	var game_state_data: Dictionary = save_data.get("game_state", {})
	
	return {
		"timestamp": save_data.get("timestamp", 0),
		"version": save_data.get("version", "unknown"),
		"player_health": game_state_data.get("player_health", 0),
		"player_max_health": game_state_data.get("player_max_health", 0),
		"current_mission": game_state_data.get("current_mission", ""),
		"completed_missions": game_state_data.get("completed_missions", []).size(),
		"intel_points": game_state_data.get("intel_points", 0),
		"failure_count": _count_total_failures(game_state_data.get("failed_attempts", {}))
	}

# Delete a save file
func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	
	var file_path := SAVE_DIR + "save_" + str(slot) + ".json"
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		EventBus.debug("Deleted save slot " + str(slot))
		return true
	
	return false

# Collect all game state into a save dictionary
func _collect_save_data() -> Dictionary:
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"version": SAVE_VERSION,
		"game_state": GameState.to_dict()
	}

# Apply save data to game state
func _apply_save_data(save_data: Dictionary) -> void:
	var version = save_data.get("version", "0.1.0")
	
	# Version compatibility check
	if version != SAVE_VERSION:
		EventBus.debug("Save version mismatch: " + version + " vs " + SAVE_VERSION)
		# In future, add migration logic here
	
	if save_data.has("game_state"):
		GameState.from_dict(save_data.game_state)
	else:
		EventBus.debug("Save data missing game_state field")
		return
	
	# Emit signals to update UI
	EventBus.player_health_changed.emit(
		GameState.player_health,
		GameState.player_max_health
	)
	EventBus.intel_changed.emit(GameState.intel_points)

# Helper: count total failures across all missions
func _count_total_failures(failed_attempts: Dictionary) -> int:
	var total := 0
	for count in failed_attempts.values():
		total += int(count)
	return total
