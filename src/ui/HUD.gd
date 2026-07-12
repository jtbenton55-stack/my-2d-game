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
@onready var _social_status_panel: Control = get_node_or_null("SocialStatusPanel")
@onready var _social_status_label: Label = get_node_or_null("SocialStatusPanel/Status") as Label

var objective_position := Vector2.ZERO
var has_marker := false

var _card_status_labels: Dictionary = {} # card_id -> Label
var _toast_timer: SceneTreeTimer = null
var _case_hint_label: Label = null
var _case_hint_timer: SceneTreeTimer = null
var _mission_hud_refresh_acc := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.bentley_meter_changed.connect(_on_bentley_meter_changed)
	EventBus.show_objective_marker.connect(_on_show_objective_marker)
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.case_hint_requested.connect(_on_case_hint_requested)
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
	if EventBus.case_hint_requested.is_connected(_on_case_hint_requested):
		EventBus.case_hint_requested.disconnect(_on_case_hint_requested)

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
		if _social_status_panel != null:
			_social_status_panel.visible = false
		if objective_label != null:
			objective_label.text = ""
		return
	_refresh_social_status()
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


func _refresh_social_status() -> void:
	if _social_status_panel == null or _social_status_label == null:
		return
	_social_status_panel.visible = true
	var mission_id := String(GameState.current_mission_id)
	var social := SocialStealthAdapter.get_summary(mission_id)
	var cover := String(social.get("active_cover_story_id", ""))
	cover = "None" if cover == "" else cover.replace("_", " ").capitalize()
	var believability := "Unproven"
	if int(social.get("inspections_failed", 0)) > 0:
		believability = "Questioned"
	elif int(social.get("inspections_passed", 0)) > 0:
		believability = "Credible"
	elif int(social.get("task_count", 0)) + int(social.get("protocol_count", 0)) > 0:
		believability = "Believable"
	var alert := get_tree().get_first_node_in_group("iso_alert_controller")
	var alert_state := String(alert.get("alert_state")) if alert != null else "normal"
	var camera_state := "Clear"
	if alert != null and alert.has_method("get_camera_policy_debug_state"):
		var camera_debug: Dictionary = alert.call("get_camera_policy_debug_state")
		if not (camera_debug.get("active_actions", {}) as Dictionary).is_empty():
			camera_state = "Action exposed"
		var last_eval: Dictionary = camera_debug.get("last_evaluation", {})
		if bool(last_eval.get("actionable", false)):
			camera_state = "Watched"
	var player := get_tree().get_first_node_in_group("player")
	var stealth := "Standing"
	if player != null and player.is_in_group("mission_hidden"):
		stealth = "Hidden"
	elif player != null and player.has_method("is_stealth_active") and bool(player.call("is_stealth_active")):
		stealth = "Sneaking"
	var bentley_state := "Following"
	var bentley := get_tree().get_first_node_in_group("bentley")
	if bentley != null and bentley.has_method("get_command_state"):
		var command_state: Dictionary = bentley.call("get_command_state")
		if bool(command_state.get("staying", false)):
			bentley_state = "Parked"
	_social_status_label.text = "COVER  %s\nBELIEF  %s   PRO  %d\nHEAT  %d   ALERT  %s\nSTEALTH  %s   CAM  %s\nBENTLEY  %s" % [
		cover, believability, int(social.get("professionalism", 0)),
		GameState.get_mission_heat(mission_id), alert_state.to_upper(), stealth, camera_state, bentley_state,
	]


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


func _on_case_hint_requested(text: String, speaker: String) -> void:
	if _case_hint_label == null:
		_case_hint_label = Label.new()
		_case_hint_label.name = "CaseHintToast"
		_case_hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_case_hint_label.offset_left = -260.0
		_case_hint_label.offset_top = -116.0
		_case_hint_label.offset_right = 260.0
		_case_hint_label.offset_bottom = -68.0
		_case_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_case_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_case_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_case_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_case_hint_label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.78))
		_case_hint_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
		_case_hint_label.add_theme_constant_override("shadow_offset_x", 2)
		_case_hint_label.add_theme_constant_override("shadow_offset_y", 2)
		_case_hint_label.add_theme_font_size_override("font_size", 16)
		add_child(_case_hint_label)
	var clean_text := text.strip_edges()
	var clean_speaker := speaker.strip_edges()
	_case_hint_label.text = "%s: %s" % [clean_speaker, clean_text] if clean_speaker != "" else clean_text
	_case_hint_label.visible = clean_text != ""
	if _case_hint_timer != null and is_instance_valid(_case_hint_timer) and _case_hint_timer.timeout.is_connected(_hide_case_hint):
		_case_hint_timer.timeout.disconnect(_hide_case_hint)
	_case_hint_timer = get_tree().create_timer(3.0, true)
	_case_hint_timer.timeout.connect(_hide_case_hint)


func _hide_case_hint() -> void:
	if _case_hint_label != null:
		_case_hint_label.visible = false


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
