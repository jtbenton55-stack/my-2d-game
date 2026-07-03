extends CanvasLayer

@export var show_compact_control_hint := false

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
@onready var _mission_strip: Control = get_node_or_null("MissionHudStrip")
@onready var _stamina_bar: ProgressBar = get_node_or_null("MissionHudStrip/SprintStaminaBar") as ProgressBar
@onready var _stamina_caption: Label = get_node_or_null("MissionHudStrip/StaminaCaption") as Label
@onready var _poop_label: Label = get_node_or_null("MissionHudStrip/PoopBagLabel") as Label
@onready var _control_hint: Label = get_node_or_null("MissionHudStrip/ControlHint") as Label

var objective_position := Vector2.ZERO
var has_marker := false

var _card_status_labels: Dictionary = {} # card_id -> Label
var _toast_timer: SceneTreeTimer = null
var _mission_hud_refresh_acc := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.bentley_meter_changed.connect(_on_bentley_meter_changed)
	EventBus.show_objective_marker.connect(_on_show_objective_marker)
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.card_selection_changed.connect(_on_cards_changed)
	EventBus.card_triggered.connect(_on_card_triggered)
	EventBus.combat_style_changed.connect(_on_combat_style_changed)
	EventBus.detection_state_changed.connect(_on_detection_state_changed)
	if not EventBus.game_state_changed.is_connected(_on_game_state_changed):
		EventBus.game_state_changed.connect(_on_game_state_changed)
	if not EventBus.mission_started.is_connected(_on_mission_started):
		EventBus.mission_started.connect(_on_mission_started)
	_on_health_changed(GameState.player_health, GameState.player_max_health)
	if objective_marker:
		objective_marker.visible = false
	var cards_column := get_node_or_null("CardsColumn") as CanvasItem
	if cards_column != null:
		cards_column.visible = false
	_setup_objective_ticker()
	_setup_mission_compact_strip()
	_refresh_mission_compact_hud()
	call_deferred("_refresh_mission_compact_hud")

func _exit_tree() -> void:
	if EventBus.card_triggered.is_connected(_on_card_triggered):
		EventBus.card_triggered.disconnect(_on_card_triggered)
	if EventBus.combat_style_changed.is_connected(_on_combat_style_changed):
		EventBus.combat_style_changed.disconnect(_on_combat_style_changed)
	if EventBus.detection_state_changed.is_connected(_on_detection_state_changed):
		EventBus.detection_state_changed.disconnect(_on_detection_state_changed)
	if EventBus.game_state_changed.is_connected(_on_game_state_changed):
		EventBus.game_state_changed.disconnect(_on_game_state_changed)
	if EventBus.mission_started.is_connected(_on_mission_started):
		EventBus.mission_started.disconnect(_on_mission_started)

func _on_mission_started(_mission_id: String) -> void:
	_refresh_mission_compact_hud()

func _setup_objective_ticker() -> void:
	if objective_label == null:
		return
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.clip_text = true
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP


func _setup_mission_compact_strip() -> void:
	if _control_hint != null:
		_control_hint.visible = show_compact_control_hint
		if show_compact_control_hint:
			_control_hint.text = MissionHudDataProvider.get_hud_payload(self).get("control_hint", "")


func _on_game_state_changed() -> void:
	_refresh_mission_compact_hud()


func _process(_delta: float) -> void:
	if objective_marker and has_marker:
		objective_marker.global_position = objective_position
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player and distance_label:
			distance_label.text = str(int(player.global_position.distance_to(objective_position))) + "m"
	_mission_hud_refresh_acc += _delta
	if _mission_hud_refresh_acc >= 0.12:
		_mission_hud_refresh_acc = 0.0
		_refresh_mission_compact_hud()


func _refresh_mission_compact_hud() -> void:
	var payload := MissionHudDataProvider.get_hud_payload(self)
	var in_mission := GameState.is_in_mission
	if _mission_strip != null:
		_mission_strip.visible = in_mission
	if not in_mission:
		if objective_label != null:
			objective_label.text = ""
		return
	if objective_label != null:
		objective_label.text = _player_facing_objective_line(String(payload.get("objective_text", "")))
	if _mission_strip == null:
		return
	if _stamina_bar != null:
		if payload.get("stamina_visible", false):
			_stamina_bar.visible = true
			if _stamina_caption != null:
				_stamina_caption.visible = true
			_stamina_bar.max_value = maxf(1.0, float(payload.get("stamina_max", 100.0)))
			_stamina_bar.value = clampf(float(payload.get("stamina_current", 0.0)), 0.0, _stamina_bar.max_value)
			if bool(payload.get("stamina_fallback", false)):
				_stamina_bar.tooltip_text = "Sprint stamina (updating…)"
			else:
				_stamina_bar.tooltip_text = "Sprint stamina — hold Ctrl while moving"
		else:
			_stamina_bar.visible = false
			if _stamina_caption != null:
				_stamina_caption.visible = false
	if _poop_label != null:
		if bool(payload.get("poop_bags_visible", false)):
			_poop_label.visible = true
			var collected := int(payload.get("poop_bags_collected_this_attempt", 0))
			var target := int(payload.get("poop_bag_bonus_target", 3))
			_poop_label.text = "Bags: %d | Run: %d/%d" % [int(payload.get("poop_bags_available", 0)), mini(collected, target), target]
			_poop_label.tooltip_text = String(payload.get("poop_bag_status_text", ""))
		else:
			_poop_label.visible = false


func _player_facing_objective_line(body: String) -> String:
	var t := body.strip_edges()
	if t == "":
		return ""
	if t.to_lower().begins_with("objective:"):
		return t
	return "Objective: %s" % t

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
	var shown := MissionHudDataProvider.sanitize_objective_line(text)
	if objective_label:
		objective_label.text = _player_facing_objective_line(shown)
	if detection_meter:
		detection_meter.tooltip_text = shown
	_refresh_mission_compact_hud()


func _on_detection_state_changed(current: float, max_value: float, state: String, modifier: float, source_id: String) -> void:
	if detection_meter == null:
		return
	detection_meter.max_value = max_value
	detection_meter.value = maxf(0.0, max_value - current)
	detection_meter.tooltip_text = "Stealth %s | modifier=%.2f | source=%s" % [
		state,
		modifier,
		source_id
	]
	var label := detection_meter.get_node_or_null("Label") as Label
	if label != null:
		label.text = "STEALTH: %s" % state.to_upper()

func _on_cards_changed(_cards: Array) -> void:
	# Main HUD no longer shows always-on card list; card detail stays in dedicated menus/debug.
	pass

func _on_card_triggered(card_id: String, status: String, message: String) -> void:
	var _unused := [card_id, status]
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
