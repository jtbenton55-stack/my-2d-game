class_name PlayerSprintDebugOverlay
extends CanvasLayer
## 0M-D2A-FIX2: On-screen sprint signal chain (debug / editor builds only; parented by Player).
## 0M-D5-02A: Hidden by default; press F11 to toggle. Text is in a bounded RichTextLabel with scroll.

var _player: CharacterBody2D = null
var _rich: RichTextLabel = null


func setup(player: CharacterBody2D) -> void:
	_player = player


func _ready() -> void:
	# 0M-D5-02B-FIX1: keep F11 overlay in debug tier (below pause at 120+), above player HUD (40–80).
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.custom_minimum_size = Vector2(420, 200)
	panel.clip_contents = true
	add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(400, 176)
	margin.add_child(scroll)
	_rich = RichTextLabel.new()
	_rich.bbcode_enabled = false
	_rich.fit_content = false
	_rich.scroll_active = true
	_rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rich.add_theme_font_size_override("normal_font_size", 12)
	scroll.add_child(_rich)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 and not event.alt_pressed and not event.ctrl_pressed and not event.meta_pressed:
			visible = not visible
			get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if not visible or _rich == null:
		return
	if _player == null or not is_instance_valid(_player):
		_rich.text = "[F11] Sprint debug (hidden by default)\nSprintDebug: no player"
		return
	if _player.has_method("get_sprint_runtime_debug"):
		var d: Dictionary = _player.get_sprint_runtime_debug()
		_rich.text = "[F11] toggle | hidden by default (0M-D5-02A)\n" + _format_debug(d)
	else:
		_rich.text = "[F11] Sprint debug\nSprintDebug: get_sprint_runtime_debug missing"
	call_deferred("_fit_rich_height")


func _fit_rich_height() -> void:
	if _rich == null:
		return
	var scroll := _rich.get_parent() as ScrollContainer
	if scroll == null:
		return
	var w := maxf(80.0, scroll.size.x - 4.0)
	if w <= 80.0:
		w = 360.0
	_rich.custom_minimum_size = Vector2(w, maxf(120.0, _rich.get_content_height()))


func _format_debug(d: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== SPRINT CHAIN (0M-D2A-FIX2) ===")
	lines.append("ctrl_phys: %s  ctrl_key: %s  sprint_act: %s  str: %.3f" % [
		d.get("ctrl_physical_pressed", "?"),
		d.get("ctrl_key_pressed", "?"),
		d.get("sprint_action_pressed", "?"),
		float(d.get("sprint_action_strength", 0.0)),
	])
	lines.append("space_phys: %s  dodge_act: %s" % [d.get("space_physical_pressed", "?"), d.get("dodge_action_pressed", "?")])
	lines.append("---")
	lines.append("requested: %s  active: %s  can_sprint: %s  mult: %s" % [
		d.get("is_sprint_requested", "?"),
		d.get("is_sprint_active", "?"),
		d.get("can_sprint", "?"),
		d.get("speed_multiplier", "?"),
	])
	lines.append("stamina: %.1f / %.1f  draining: %s" % [
		float(d.get("current_stamina", 0.0)),
		float(d.get("max_stamina", 0.0)),
		d.get("stamina_draining", "?"),
	])
	lines.append("--- MOVEMENT ---")
	lines.append("input len: %.3f  is_moving: %s" % [float(d.get("input_vector_length", 0.0)), d.get("is_moving", "?")])
	lines.append("base_move_speed: %.1f  final_move_speed: %.1f  sprint_mult: %.3f" % [
		float(d.get("base_move_speed", 0.0)),
		float(d.get("final_move_speed", 0.0)),
		float(d.get("sprint_multiplier_applied", 1.0)),
	])
	lines.append("vel len: %.1f  vel_pre_slide len: %.1f" % [
		float(d.get("velocity_length_post_slide", 0.0)),
		float(d.get("velocity_length_pre_slide", 0.0)),
	])
	lines.append("--- GATES ---")
	lines.append("combat_on: %s  dash_active: %s  dodge_timer: %.3f  legacy_burst: %s" % [
		d.get("combat_on", "?"),
		d.get("dash_active", "?"),
		float(d.get("dodge_timer", 0.0)),
		d.get("legacy_dodge_burst", "?"),
	])
	lines.append("stealth: %s  suppressed: %s" % [d.get("is_stealth", "?"), d.get("sprint_suppressed_reason", "")])
	lines.append("run_anim_required: %s" % str(d.get("run_animation_required", false)))
	lines.append("CHAIN: CTRL→ACT→REQ→ACTV→MULT→VEL")
	return "\n".join(lines)
