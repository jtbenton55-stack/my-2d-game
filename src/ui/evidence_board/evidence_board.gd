extends Control

const CARD_SCENE := preload("res://src/ui/evidence_board/evidence_card.tscn")

var cards: Array[Control] = []
var is_link_mode := false
var selected_card: Control
var links: Array[Dictionary] = []

@onready var board_area: Control = $BoardArea
@onready var add_card_button: Button = $TopBar/AddCardButton
@onready var link_mode_toggle: Button = $TopBar/LinkModeToggle
@onready var close_button: Button = $TopBar/CloseButton


func _ready() -> void:
	add_card_button.pressed.connect(_on_add_card)
	link_mode_toggle.pressed.connect(_on_toggle_link_mode)
	close_button.pressed.connect(_on_close)
	load_state(GameState.evidence_board_data)
	_import_discovered_sterling_clues()
	add_card_button.grab_focus()


func _process(_delta: float) -> void:
	if links.size() > 0:
		queue_redraw()


func _draw() -> void:
	if board_area == null:
		return
	for link in links:
		var c1 := link.get("from") as Control
		var c2 := link.get("to") as Control
		if c1 == null or c2 == null:
			continue
		var p1 := get_global_transform().affine_inverse() * c1.get_global_rect().get_center()
		var p2 := get_global_transform().affine_inverse() * c2.get_global_rect().get_center()
		draw_line(p1, p2, Color(0.55, 0.78, 1.0, 0.55), 2.5)


func _on_add_card() -> void:
	var count := cards.size() + 1
	var card := _create_card("Clue %d" % count, "Drop this card near related evidence.", Vector2(randi() % 420 + 24, randi() % 260 + 72), "")
	cards.append(card)
	_save()


func _create_card(card_title: String, card_description: String, card_position: Vector2, sterling_clue_id: String = "") -> Control:
	var card := CARD_SCENE.instantiate() as Control
	board_area.add_child(card)
	if card.has_method("setup"):
		card.setup(board_area, card_title, card_description)
	card.position = card_position
	if sterling_clue_id != "":
		card.set_meta("sterling_clue_id", sterling_clue_id)
	if card.has_signal("card_clicked"):
		card.connect("card_clicked", _on_card_clicked)
	return card


func _on_card_clicked(card: Control) -> void:
	if is_link_mode:
		_handle_link(card)


func _handle_link(card: Control) -> void:
	if selected_card == null:
		selected_card = card
		card.highlight = true
		return
	if selected_card != card:
		_create_link(selected_card, card)
	selected_card.highlight = false
	selected_card = null


func _create_link(card1: Control, card2: Control) -> void:
	links.append({"from": card1, "to": card2})
	EventBus.debug("Evidence linked.")
	_save()


func _on_toggle_link_mode() -> void:
	is_link_mode = not is_link_mode
	link_mode_toggle.text = "Link Mode: ON" if is_link_mode else "Link Mode: OFF"
	if not is_link_mode and selected_card != null:
		selected_card.highlight = false
		selected_card = null


func _on_close() -> void:
	_save()
	SceneManager.return_to_hideout()


func _save() -> void:
	var data := {"cards": [], "links": []}
	for card in cards:
		var entry := {
			"position": [card.position.x, card.position.y],
			"title": String(card.get("title")),
			"description": String(card.get("description")),
		}
		if card.has_meta("sterling_clue_id"):
			entry["sterling_clue_id"] = String(card.get_meta("sterling_clue_id"))
		data["cards"].append(entry)
	for link in links:
		var from_idx := cards.find(link["from"])
		var to_idx := cards.find(link["to"])
		if from_idx >= 0 and to_idx >= 0:
			data["links"].append([from_idx, to_idx])
	GameState.evidence_board_data = data


func load_state(data: Dictionary) -> void:
	for card in cards:
		card.queue_free()
	cards.clear()
	links.clear()
	for raw_card_data in data.get("cards", []):
		var card_data := Dictionary(raw_card_data)
		var position_data: Array = card_data.get("position", [24.0, 72.0])
		var card_position := Vector2(float(position_data[0]), float(position_data[1]))
		var clue_key := String(card_data.get("sterling_clue_id", ""))
		var card := _create_card(String(card_data.get("title", "Evidence")), String(card_data.get("description", "A clue from the city.")), card_position, clue_key)
		cards.append(card)
	for link_data in data.get("links", []):
		if link_data is Array and link_data.size() >= 2:
			var from_idx := int(link_data[0])
			var to_idx := int(link_data[1])
			if from_idx >= 0 and from_idx < cards.size() and to_idx >= 0 and to_idx < cards.size():
				links.append({"from": cards[from_idx], "to": cards[to_idx]})


func _import_discovered_sterling_clues() -> void:
	for clue_id in GameState.sterling_clues.keys():
		var d: Dictionary = GameState.sterling_clues[clue_id]
		if not bool(d.get("discovered", false)):
			continue
		if _board_has_clue_card(clue_id):
			continue
		var cat := String(d.get("category", "Sterling"))
		var title := "[%s] %s" % [cat, String(d.get("title", clue_id))]
		var desc := String(d.get("description", ""))
		var card := _create_card(title, desc, Vector2(40 + randi() % 260, 80 + randi() % 180), clue_id)
		cards.append(card)
	_save()


func _board_has_clue_card(clue_id: String) -> bool:
	for card in cards:
		if card.has_meta("sterling_clue_id") and String(card.get_meta("sterling_clue_id")) == clue_id:
			return true
	return false
