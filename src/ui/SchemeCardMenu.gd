extends Control

const MAX_SELECTED_CARDS := 3

var selected_cards: Array[String] = []
var is_closing := false

@onready var cards_container: HBoxContainer = $CardsPanel/ScrollContainer/CardsContainer
@onready var start_button: Button = $StartButton
@onready var back_button: Button = $BackButton
@onready var subtitle_label: Label = $SubtitleLabel

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_populate_cards()
	_update_selection_display()
	start_button.grab_focus()
	AudioManager.play_music("card_select")

func _populate_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	
	# Wait for CardManager to be ready
	await get_tree().create_timer(0.1).timeout
	if is_closing or not is_inside_tree():
		return
	
	for card_id in GameState.unlocked_cards:
		var card = CardManager.get_card(card_id)
		if card == null:
			# Try loading directly
			var path = "res://resources/cards/" + card_id + ".tres"
			card = load(path)
		
		if card:
			var button = Button.new()
			button.custom_minimum_size = Vector2(200, 280)
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			button.toggle_mode = true
			# Get display name - handle both display_name and name properties
			var card_name = card.display_name if card.get("display_name") else card.get("name", card_id)
			var card_desc = card.description if card.get("description") else ""
			button.text = "%s\n\n%s" % [card_name, card_desc]
			button.pressed.connect(_on_card_toggled.bind(card_id, button))
			cards_container.add_child(button)

func _on_card_toggled(card_id: String, button: Button) -> void:
	if button.button_pressed:
		if selected_cards.size() < MAX_SELECTED_CARDS:
			selected_cards.append(card_id)
			button.modulate = Color(0.8, 0.4, 1, 1)
		else:
			button.button_pressed = false
	else:
		selected_cards.erase(card_id)
		button.modulate = Color(1, 1, 1, 1)
	
	_update_selection_display()

func _update_selection_display() -> void:
	subtitle_label.text = "Choose up to 3 cards (%d/%d selected)" % [selected_cards.size(), MAX_SELECTED_CARDS]
	# Allow starting even with 0 cards for now

func _on_start_pressed() -> void:
	if is_closing:
		return
	if GameState.pending_mission_id == "":
		EventBus.warn("Start Mission pressed with no pending mission.")
		return
	is_closing = true
	start_button.disabled = true
	back_button.disabled = true
	GameState.set_selected_cards(selected_cards)
	SceneManager.start_pending_mission()
	_reenable_if_scene_did_not_change()

func _on_back_pressed() -> void:
	if is_closing:
		return
	is_closing = true
	start_button.disabled = true
	back_button.disabled = true
	SceneManager.open_mission_select()

func _reenable_if_scene_did_not_change() -> void:
	await get_tree().create_timer(0.75).timeout
	if not is_inside_tree():
		return
	is_closing = false
	start_button.disabled = false
	back_button.disabled = false
	start_button.grab_focus()
