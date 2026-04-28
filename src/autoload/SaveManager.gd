extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3
const AUTO_SAVE_SLOT := 0
var current_slot := AUTO_SAVE_SLOT
var auto_save_enabled := true

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	EventBus.debug("SaveManager ready")

func save_game(slot = AUTO_SAVE_SLOT) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		EventBus.warn("Invalid save slot: " + str(slot))
		return false
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		EventBus.warn("Could not open save file: " + path)
		return false
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	file.close()
	current_slot = slot
	EventBus.game_saved.emit(slot)
	return true

func load_game(slot = AUTO_SAVE_SLOT) -> bool:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		EventBus.warn("Could not parse save file: " + path)
		return false
	var data = json.get_data()
	if data is Dictionary:
		GameState.from_dict(data)
		current_slot = slot
		EventBus.game_loaded.emit(slot)
		return true
	return false

func auto_save() -> void:
	if auto_save_enabled:
		save_game(AUTO_SAVE_SLOT)

func has_save(slot = AUTO_SAVE_SLOT) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func has_any_save() -> bool:
	for slot in range(MAX_SLOTS):
		if has_save(slot):
			return true
	return false

func delete_save(slot = AUTO_SAVE_SLOT) -> bool:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path) == OK
	return false

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot
