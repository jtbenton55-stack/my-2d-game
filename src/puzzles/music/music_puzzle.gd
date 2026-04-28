extends Control

@export var song_titles: Array[String] = [
	"Naked Hug My Son",
	"Bathroom Snacks",
	"Wee-Woo Lullaby",
	"Dental Boy Blues",
	"Two Letters Away",
	"Raincoat for a Crime Dog"
]

@export var correct_order: Array[int] = [0, 1, 2, 3, 4, 5]
@export var max_slots: int = 6

var slots: Array[Control] = []
var tiles: Array[Control] = []
var placed_songs: Array[int] = []
var solved := false
var failed := false

signal puzzle_solved
signal puzzle_failed

@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var instruction_label: Label = $Panel/VBoxContainer/InstructionLabel
@onready var slot_container: HBoxContainer = $Panel/VBoxContainer/SlotContainer
@onready var tile_container: VBoxContainer = $Panel/VBoxContainer/TileContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var check_button: Button = $Panel/VBoxContainer/CheckButton

func _ready() -> void:
	prompt_label.text = "The Velvet Paw Setlist"
	instruction_label.text = "Drag songs to arrange tonight's performance order.\nHint: Start with intimacy, end with justice."
	close_button.pressed.connect(_on_close)
	check_button.pressed.connect(_on_check_solution)
	
	placed_songs.resize(max_slots)
	placed_songs.fill(-1)
	
	_create_slots()
	_create_song_tiles()
	
	close_button.grab_focus()

func _create_slots() -> void:
	for child in slot_container.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(max_slots):
		var slot := _create_slot(i)
		slot_container.add_child(slot)
		slots.append(slot)

func _create_slot(index: int) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(120, 60)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style.border_width_all = 2
	style.border_color = Color(0.4, 0.4, 0.5, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	slot.add_theme_stylebox_override("panel", style)
	
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 4
	label.offset_top = 4
	label.offset_right = -4
	label.offset_bottom = -4
	slot.add_child(label)
	
	var slot_number := Label.new()
	slot_number.text = str(index + 1)
	slot_number.add_theme_font_size_override("font_size", 10)
	slot_number.modulate = Color(0.6, 0.6, 0.6, 1.0)
	slot_number.position = Vector2(4, 2)
	slot.add_child(slot_number)
	
	return slot

func _create_song_tiles() -> void:
	for child in tile_container.get_children():
		child.queue_free()
	tiles.clear()
	
	var shuffled_indices := range(song_titles.size())
	shuffled_indices.shuffle()
	
	for song_idx in shuffled_indices:
		var tile := _create_song_tile(song_idx)
		tile_container.add_child(tile)
		tiles.append(tile)

func _create_song_tile(song_index: int) -> Button:
	var tile := Button.new()
	var title := song_titles[song_index]
	
	tile.text = title
	tile.custom_minimum_size = Vector2(200, 40)
	tile.add_theme_font_size_override("font_size", 12)
	
	tile.pressed.connect(_on_tile_clicked.bind(tile, song_index))
	
	return tile

var selected_slot_index: int = -1
var selected_song_index: int = -1

func _on_tile_clicked(tile: Button, song_index: int) -> void:
	if solved or failed:
		return
	
	selected_song_index = song_index
	
	var existing_slot := _find_slot_with_song(song_index)
	if existing_slot >= 0:
		selected_slot_index = existing_slot
		_highlight_slot(existing_slot)
	else:
		var empty_slot := _find_first_empty_slot()
		if empty_slot >= 0:
			selected_slot_index = empty_slot
			_place_song_in_slot(song_index, empty_slot)
			_highlight_slot(empty_slot)

func _find_slot_with_song(song_index: int) -> int:
	for i in range(max_slots):
		if placed_songs[i] == song_index:
			return i
	return -1

func _find_first_empty_slot() -> int:
	for i in range(max_slots):
		if placed_songs[i] == -1:
			return i
	return -1

func _place_song_in_slot(song_index: int, slot_index: int) -> void:
	if slot_index < 0 or slot_index >= max_slots:
		return
	
	var old_song := placed_songs[slot_index]
	if old_song >= 0:
		_tiles_visible(true)
	
	placed_songs[slot_index] = song_index
	
	var slot := slots[slot_index]
	var label := slot.get_node("Label")
	label.text = song_titles[song_index]
	
	for tile in tiles:
		if tile.text == song_titles[song_index]:
			tile.visible = false
			break

func _tiles_visible(visible: bool) -> void:
	for tile in tiles:
		tile.visible = visible

func _highlight_slot(index: int) -> void:
	for i in range(slots.size()):
		var style := StyleBoxFlat.new()
		if i == index:
			style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
			style.border_color = Color(0.6, 0.6, 0.8, 1.0)
		else:
			style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
			style.border_color = Color(0.4, 0.4, 0.5, 1.0)
		style.border_width_all = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		slots[i].add_theme_stylebox_override("panel", style)

func _on_check_solution() -> void:
	if solved or failed:
		return
	
	var is_complete := true
	for i in range(max_slots):
		if placed_songs[i] == -1:
			is_complete = false
			break
	
	if not is_complete:
		instruction_label.text = "Fill all slots first!"
		instruction_label.modulate = Color(1.0, 0.8, 0.4, 1.0)
		return
	
	var is_correct := true
	for i in range(max_slots):
		if placed_songs[i] != correct_order[i]:
			is_correct = false
			break
	
	if is_correct:
		solved = true
		instruction_label.text = "Perfect setlist! The stage opens."
		instruction_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		_show_solution_feedback(true)
		puzzle_solved.emit()
		close_button.text = "Continue"
	else:
		failed = true
		instruction_label.text = "Wrong order! The bouncer heard the dissonance..."
		instruction_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
		_show_solution_feedback(false)
		puzzle_failed.emit()
		close_button.text = "Hide!"

func _show_solution_feedback(correct: bool) -> void:
	for i in range(max_slots):
		var style := StyleBoxFlat.new()
		if correct:
			style.bg_color = Color(0.2, 0.5, 0.3, 1.0)
			style.border_color = Color(0.4, 0.9, 0.5, 1.0)
		else:
			if placed_songs[i] == correct_order[i]:
				style.bg_color = Color(0.2, 0.5, 0.3, 1.0)
				style.border_color = Color(0.4, 0.9, 0.5, 1.0)
			else:
				style.bg_color = Color(0.5, 0.2, 0.2, 1.0)
				style.border_color = Color(0.9, 0.4, 0.4, 1.0)
		style.border_width_all = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		slots[i].add_theme_stylebox_override("panel", style)

func _on_close() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_close()
