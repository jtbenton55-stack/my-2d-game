extends Node

const CARD_DIR := "res://resources/cards"
var cards: Dictionary = {}

func _ready() -> void:
	load_cards()
	EventBus.debug("CardManager ready with " + str(cards.size()) + " cards")

func load_cards() -> void:
	cards.clear()
	var dir := DirAccess.open(CARD_DIR)
	if dir == null:
		EventBus.warn("Card directory missing: " + CARD_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := CARD_DIR + "/" + file_name
			var resource := load(path)
			if resource != null and resource.has_method("get_summary"):
				cards[resource.id] = resource
		file_name = dir.get_next()
	dir.list_dir_end()

func get_card(card_id: String):
	return cards.get(card_id, null)

func has_card(card_id: String) -> bool:
	return cards.has(card_id)

func get_unlocked_cards() -> Array:
	var out: Array = []
	for card_id in GameState.unlocked_cards:
		if cards.has(card_id):
			out.append(cards[card_id])
	return out

func get_selected_cards() -> Array:
	var out: Array = []
	for card_id in GameState.selected_cards:
		if cards.has(card_id):
			out.append(cards[card_id])
	return out

func unlock_card(card_id: String) -> bool:
	return GameState.unlock_card(card_id)

func is_selected(card_id: String) -> bool:
	return GameState.has_selected_card(card_id)

func selected_value(effect_key: String, default_value: float = 0.0) -> float:
	var value := default_value
	for card in get_selected_cards():
		if card.effect_key == effect_key:
			value += float(card.effect_value)
	return value

func selected_has(card_id: String) -> bool:
	return GameState.has_selected_card(card_id)
