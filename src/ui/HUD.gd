extends CanvasLayer

@onready var health_bar := get_node_or_null("HealthBar") as ProgressBar
@onready var bentley_bar := get_node_or_null("BentleyBar") as ProgressBar
@onready var style_bar := get_node_or_null("StyleBar") as ProgressBar
@onready var style_finisher_hint := get_node_or_null("StyleBar/StyleFinisherHint") as Label
@onready var detection_meter := get_node_or_null("DetectionMeter") as ProgressBar
@onready var objective_marker := get_node_or_null("ObjectiveMarker") as Node2D
@onready var distance_label := get_node_or_null("ObjectiveMarker/Distance") as Label
@onready var objective_label := get_node_or_null("ObjectiveLabel") as Label
@onready var card_toast := get_node_or_null("CardsColumn/CardToast") as Label
@onready var cards_panel := get_node_or_null("CardsColumn/CardsPanel") as VBoxContainer

var objective_position := Vector2.ZERO
var has_marker := false

var _card_status_labels: Dictionary = {} # card_id -> Label
var _toast_timer: SceneTreeTimer = null

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.bentley_meter_changed.connect(_on_bentley_meter_changed)
	EventBus.show_objective_marker.connect(_on_show_objective_marker)
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.card_selection_changed.connect(_on_cards_changed)
	EventBus.card_triggered.connect(_on_card_triggered)
	EventBus.combat_style_changed.connect(_on_combat_style_changed)
	EventBus.detection_state_changed.connect(_on_detection_state_changed)
	_on_health_changed(GameState.player_health, GameState.player_max_health)
	if objective_marker:
		objective_marker.visible = false
	_rebuild_cards_panel()

func _exit_tree() -> void:
	if EventBus.card_triggered.is_connected(_on_card_triggered):
		EventBus.card_triggered.disconnect(_on_card_triggered)
	if EventBus.combat_style_changed.is_connected(_on_combat_style_changed):
		EventBus.combat_style_changed.disconnect(_on_combat_style_changed)
	if EventBus.detection_state_changed.is_connected(_on_detection_state_changed):
		EventBus.detection_state_changed.disconnect(_on_detection_state_changed)

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


func _on_combat_style_changed(current: float, max_style: float) -> void:
	if style_bar == null:
		return
	style_bar.max_value = max_style
	style_bar.value = current
	if max_style <= 0.001:
		return
	if current >= max_style - 0.75:
		style_bar.modulate = Color(1.0, 0.88, 0.4, 1.0)
		if style_finisher_hint:
			var fin_key := "R"
			if InputMap.has_action("finisher"):
				for ev in InputMap.action_get_events("finisher"):
					if ev is InputEventKey:
						var kc: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
						fin_key = OS.get_keycode_string(kc)
						break
			style_finisher_hint.text = "Finisher ready — press %s" % fin_key
	else:
		style_bar.modulate = Color.WHITE
		if style_finisher_hint:
			style_finisher_hint.text = ""

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


func _on_detection_state_changed(current: float, max_value: float, state: String, modifier: float, source_id: String) -> void:
	if detection_meter == null:
		return
	detection_meter.max_value = max_value
	detection_meter.value = current
	detection_meter.tooltip_text = "Detection %.2f/%s | state=%s | mod=%.2f | source=%s" % [
		current,
		str(max_value),
		state,
		modifier,
		source_id
	]

func _on_cards_changed(_cards: Array) -> void:
	_rebuild_cards_panel()

func _on_card_triggered(card_id: String, status: String, message: String) -> void:
	var status_lbl := _card_status_labels.get(card_id) as Label
	if status_lbl:
		status_lbl.text = _display_status(status)
	if message != "":
		_show_card_toast(message)

func _display_status(bus_status: String) -> String:
	match bus_status:
		"used":
			return "USED"
		"active":
			return "ACTIVE"
		"ready":
			return "READY"
		_:
			return String(bus_status).to_upper()

func _rebuild_cards_panel() -> void:
	_card_status_labels.clear()
	if cards_panel == null:
		return
	for child in cards_panel.get_children():
		child.queue_free()
	for card_id in GameState.selected_cards:
		var card = CardManager.get_card(card_id)
		if card == null:
			continue
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(248, 0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.1, 0.14, 0.88)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 8
		sb.content_margin_top = 6
		sb.content_margin_right = 8
		sb.content_margin_bottom = 6
		chip.add_theme_stylebox_override("panel", sb)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 2)
		var title := Label.new()
		title.text = card.display_name
		title.add_theme_font_size_override("font_size", 12)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var desc := Label.new()
		desc.text = card.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 10)
		desc.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
		desc.custom_minimum_size = Vector2(232, 0)
		var status_row := Label.new()
		status_row.name = "StatusLabel"
		status_row.text = "READY"
		status_row.add_theme_font_size_override("font_size", 10)
		status_row.add_theme_color_override("font_color", Color(0.55, 0.95, 0.65))
		_card_status_labels[card_id] = status_row
		inner.add_child(title)
		inner.add_child(desc)
		inner.add_child(status_row)
		chip.add_child(inner)
		cards_panel.add_child(chip)

func _show_card_toast(message: String) -> void:
	if card_toast == null:
		return
	card_toast.text = message
	card_toast.visible = true
	if _toast_timer != null and is_instance_valid(_toast_timer):
		_toast_timer.timeout.disconnect(_hide_card_toast)
	_toast_timer = get_tree().create_timer(2.0)
	_toast_timer.timeout.connect(_hide_card_toast)

func _hide_card_toast() -> void:
	if card_toast:
		card_toast.visible = false
