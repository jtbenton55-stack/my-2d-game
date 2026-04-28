extends CanvasLayer

@onready var health_bar := get_node_or_null("HealthBar") as ProgressBar
@onready var bentley_bar := get_node_or_null("BentleyBar") as ProgressBar
@onready var detection_meter := get_node_or_null("DetectionMeter") as ProgressBar
@onready var objective_marker := get_node_or_null("ObjectiveMarker") as Node2D
@onready var distance_label := get_node_or_null("ObjectiveMarker/Distance") as Label
@onready var objective_label := get_node_or_null("ObjectiveLabel") as Label
@onready var cards_label := get_node_or_null("CardsLabel") as Label

var objective_position := Vector2.ZERO
var has_marker := false

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.bentley_meter_changed.connect(_on_bentley_meter_changed)
	EventBus.show_objective_marker.connect(_on_show_objective_marker)
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.card_selection_changed.connect(_on_cards_changed)
	_on_health_changed(GameState.player_health, GameState.player_max_health)
	if objective_marker:
		objective_marker.visible = false
	_update_cards_display()

func _process(_delta: float) -> void:
	if objective_marker and has_marker:
		objective_marker.global_position = objective_position
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player and distance_label:
			distance_label.text = str(int(player.global_position.distance_to(objective_position))) + "m"

func _on_health_changed(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _on_bentley_meter_changed(current: float, max_val: float) -> void:
	if bentley_bar:
		bentley_bar.max_value = max_val
		bentley_bar.value = current

func _on_show_objective_marker(should_show: bool, position: Vector2) -> void:
	has_marker = should_show
	objective_position = position
	if objective_marker:
		objective_marker.visible = should_show

func _on_objective_updated(text: String) -> void:
	if objective_label:
		objective_label.text = text
	if detection_meter:
		detection_meter.tooltip_text = text

func _on_cards_changed(_cards: Array) -> void:
	_update_cards_display()

func _update_cards_display() -> void:
	if cards_label:
		var card_names: Array[String] = []
		for card_id in GameState.selected_cards:
			var card = CardManager.get_card(card_id)
			if card:
				card_names.append(card.display_name)
		if card_names.is_empty():
			cards_label.text = "No Cards"
		else:
			cards_label.text = "Cards: " + ", ".join(card_names)
