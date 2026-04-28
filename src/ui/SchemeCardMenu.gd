extends Control

@onready var cards_container := get_node_or_null("MenuContainer/VBoxContainer/CardsContainer") as GridContainer
@onready var selected_count := get_node_or_null("MenuContainer/VBoxContainer/SelectedCount") as Label
@onready var confirm_button := get_node_or_null("MenuContainer/VBoxContainer/ButtonContainer/ConfirmButton") as Button
@onready var back_button := get_node_or_null("MenuContainer/VBoxContainer/ButtonContainer/BackButton") as Button

var selected: Array[String] = []
var buttons_by_card: Dictionary = {}

func _ready() -> void:
	selected = GameState.selected_cards.duplicate()
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if back_button:
		back_button.pressed.connect(SceneManager.open_mission_select)
	_build_cards()
	_update_status()

func _build_cards() -> void:
	if cards_container == null:
		return
	for child in cards_container.get_children():
		child.queue_free()
	buttons_by_card.clear()
	var cards := CardManager.get_unlocked_cards()
	for card in cards:
		var button := Button.new()
		button.custom_minimum_size = Vector2(240, 110)
		button.text = card.display_name + "\n" + card.description
		button.toggle_mode = true
		button.button_pressed = selected.has(card.id)
		button.pressed.connect(func(): _toggle_card(card.id))
		buttons_by_card[card.id] = button
		cards_container.add_child(button)

func _toggle_card(card_id: String) -> void:
	if selected.has(card_id):
		selected.erase(card_id)
	elif selected.size() < GameState.MAX_SELECTED_CARDS:
		selected.append(card_id)
	for id in buttons_by_card.keys():
		buttons_by_card[id].button_pressed = selected.has(id)
	_update_status()

func _update_status() -> void:
	if selected_count:
		selected_count.text = "%d/%d cards selected" % [selected.size(), GameState.MAX_SELECTED_CARDS]
	if confirm_button:
		confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	GameState.set_selected_cards(selected)
	SceneManager.start_pending_mission()
