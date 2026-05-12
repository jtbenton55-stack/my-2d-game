@tool
class_name Phase0JDebugHUD
extends CanvasLayer

@export var visible_by_default := false
## When true (default), keeps this layer hidden during play even if the scene overrides visible_by_default. Counters live under F10 (IsoMissionDebugPanel).
@export var force_playfield_hidden := true
@export var temp_code_hint := "0420"
@export var mission_state_adapter_path: NodePath = NodePath("../Phase0JMissionStateAdapter")
@export var debug_text_color := Color(1.0, 0.0, 0.0, 1.0)
@export var debug_outline_color := Color(0.0, 0.0, 0.0, 1.0)
@export var debug_outline_size := 3

var collected_count := 0
var inspected_count := 0
var phase0j_category_counts: Dictionary = {}
var phase0j_summary := ""
var _message_timer := 0.0
var _message_label: Label
var _nearest_label: Label
var _counter_label: Label
var _gate_label: Label
var _state_label: Label


func _ready() -> void:
	layer = 90
	set_meta("generated_by", "Phase0J-C2")
	set_meta("scene_local_only", true)
	_build_ui()
	show_message("Phase0J debug layer ready. E/Q: interact/inspect Phase0J marker. Code: %s" % temp_code_hint, 4.0)
	if force_playfield_hidden:
		visible_by_default = false
	visible = visible_by_default
	hide()


func _process(delta: float) -> void:
	_refresh_counts_from_adapter()
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			clear_message()


func show_message(text: String, seconds: float = 3.0) -> void:
	if _message_label == null:
		_build_ui()
	_apply_red_debug_style(self)
	_message_label.text = text
	if force_playfield_hidden:
		_message_timer = 0.0
		EventBus.debug("[Phase0JDebugHUD] " + text)
		return
	_message_timer = seconds
	if visible_by_default:
		visible = true


func set_nearest_marker(id: String, category: String, distance: float) -> void:
	if _nearest_label == null:
		_build_ui()
	if id == "":
		_nearest_label.text = "Nearest: none"
	else:
		_nearest_label.text = "Nearest: %s [%s] %.0f px" % [id, category, distance]


func increment_collected(category: String) -> void:
	collected_count += 1
	_refresh_counts_from_adapter()
	_update_counters("")


func increment_inspected(category: String) -> void:
	inspected_count += 1
	_update_counters(category)


func set_phase0j_counts(counts: Dictionary, summary: String = "") -> void:
	phase0j_category_counts = counts.duplicate(true)
	phase0j_summary = summary
	_update_counters("")


func set_gate_state(unlocked: bool) -> void:
	if _gate_label == null:
		_build_ui()
	_gate_label.text = "Gate: %s" % ("UNLOCKED" if unlocked else "LOCKED")


func clear_message() -> void:
	if _message_label != null:
		_message_label.text = "E/Q: interact/inspect Phase0J marker. Code gate temp code: %s" % temp_code_hint


func is_code_ui_open() -> bool:
	var ui := get_node_or_null("../Phase0JCodeInputUI")
	return ui != null and ui.has_method("is_open") and bool(ui.call("is_open"))


func _build_ui() -> void:
	if _message_label != null:
		return
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.offset_left = 12
	panel.offset_top = 12
	panel.offset_right = 620
	panel.offset_bottom = 190
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.72)
	style.border_color = Color(0.5, 0, 0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.name = "DebugScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(580, 132)
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.name = "VBox"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	_message_label = Label.new()
	_message_label.name = "Message"
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_message_label)
	_nearest_label = Label.new()
	_nearest_label.name = "Nearest"
	_nearest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nearest_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_nearest_label)
	_counter_label = Label.new()
	_counter_label.name = "Counters"
	_counter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_counter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_counter_label)
	_gate_label = Label.new()
	_gate_label.name = "Gate"
	_gate_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_gate_label)
	_state_label = Label.new()
	_state_label.name = "Phase0JState"
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_state_label)
	_update_counters("")
	set_gate_state(false)
	_apply_red_debug_style(self)


func _update_counters(_category: String) -> void:
	if _counter_label == null:
		return
	_counter_label.text = "Collected: %d | Inspected: %d" % [collected_count, inspected_count]
	if _state_label != null:
		var parts: Array[String] = []
		for key in ["poop_bag", "bag", "evidence_clue", "polaroid", "glow_guy", "tiny_icon", "objective_bag"]:
			parts.append("%s:%d" % [key, int(phase0j_category_counts.get(key, 0))])
		_state_label.text = "C5 counts (source: Phase0JMissionStateAdapter)\n" + " | ".join(parts)
	_apply_red_debug_style(self)


func _refresh_counts_from_adapter() -> void:
	var adapter := get_node_or_null(mission_state_adapter_path)
	if adapter != null and adapter.has_method("get_all_counts"):
		phase0j_category_counts = adapter.call("get_all_counts")
		if adapter.has_method("get_summary_text"):
			phase0j_summary = String(adapter.call("get_summary_text"))


func _apply_red_debug_style(node: Node) -> void:
	for child in node.get_children():
		if child is Label:
			var label := child as Label
			label.add_theme_color_override("font_color", debug_text_color)
			label.add_theme_color_override("font_outline_color", debug_outline_color)
			label.add_theme_constant_override("outline_size", debug_outline_size)
		elif child is RichTextLabel:
			var rich := child as RichTextLabel
			rich.add_theme_color_override("default_color", debug_text_color)
			rich.add_theme_color_override("font_outline_color", debug_outline_color)
			rich.add_theme_constant_override("outline_size", debug_outline_size)
		_apply_red_debug_style(child)
