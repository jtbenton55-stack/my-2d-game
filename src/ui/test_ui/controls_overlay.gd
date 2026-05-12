extends CanvasLayer

## Simple overlay that shows the main controls.
## Can be toggled with a hotkey (F1) or left always visible.
## 0M-D5-02A: Bounded ScrollContainer + RichTextLabel so long bindings never run off-screen.

@export var hotkey: Key = KEY_F1
@export var always_visible: bool = false

@onready var info_rich: RichTextLabel = $PanelRoot/MarginContainer/Panel/InfoScroll/InfoRichText
@onready var info_scroll: ScrollContainer = $PanelRoot/MarginContainer/Panel/InfoScroll
@onready var minimize_button: Button = $PanelRoot/MarginContainer/Panel/MinimizeButton

var is_minimized: bool = false
var full_text: String = ""


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_update_label()
	full_text = info_rich.text
	if info_rich != null:
		info_rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		call_deferred("_fit_controls_text_height")

	if minimize_button:
		minimize_button.pressed.connect(_on_minimize_pressed)

	if not always_visible:
		visible = false
	else:
		visible = true


func _fit_controls_text_height() -> void:
	if info_rich == null or info_scroll == null:
		return
	var w := maxf(80.0, info_scroll.size.x - 4.0)
	if w <= 80.0:
		w = 220.0
	info_rich.custom_minimum_size = Vector2(w, maxf(120.0, info_rich.get_content_height()))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == hotkey and event.pressed and not event.echo:
		if is_minimized:
			is_minimized = false
			info_rich.text = full_text
			if minimize_button:
				minimize_button.text = "-"
			call_deferred("_fit_controls_text_height")
		else:
			visible = !visible
		get_viewport().set_input_as_handled()


func _on_minimize_pressed() -> void:
	is_minimized = !is_minimized
	if is_minimized:
		info_rich.text = "[F1] Controls"
		if minimize_button:
			minimize_button.text = "+"
	else:
		info_rich.text = full_text
		if minimize_button:
			minimize_button.text = "-"
	call_deferred("_fit_controls_text_height")


func _update_label() -> void:
	var text := "[F1] Toggle | [ESC] Pause\n\n"
	text += _action_bindings("move_left", "Move left")
	text += _action_bindings("move_right", "Move right")
	text += _action_bindings("move_up", "Move up")
	text += _action_bindings("move_down", "Move down")
	text += _action_bindings("interact", "Interact / dialogue")
	text += _action_bindings("attack", "Light attack / combo")
	text += _action_bindings("case_the_joint", "Case the Joint")
	text += _action_bindings("dodge", "Dash")
	text += _action_bindings("finisher", "Finisher (style full)")
	text += _action_bindings("stealth", "Stealth walk (hold + WASD)")
	text += "Stealth takedown: stealth + behind unaware + light attack\n"
	text += _action_bindings("bentley_bark", "Bentley Bark")
	text += _action_bindings("bentley_sniff", "Bentley Sniff")
	text += _action_bindings("bentley_fetch", "Bentley Fetch")
	text += _action_bindings("bentley_toggle_stay", "Bentley Stay/Heel")
	text += _action_bindings("poop_bag_targeting", "Poop bag throw mode")
	text += _action_bindings("bentley_ability", "Bentley bark (fallback)")

	info_rich.text = text


func _action_bindings(action_name: String, label: String) -> String:
	if not InputMap.has_action(action_name):
		return ""
	var keys: Array[InputEvent] = InputMap.action_get_events(action_name)
	var key_strs: PackedStringArray = []
	for ev in keys:
		if ev is InputEventKey:
			var kc: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			key_strs.append(OS.get_keycode_string(kc))
		elif ev is InputEventJoypadButton:
			key_strs.append("Btn %d" % ev.button_index)
		elif ev is InputEventMouseButton:
			key_strs.append("M%d" % ev.button_index)
	if key_strs.is_empty():
		return "%s: %s\n" % [label, action_name]
	return "%s: %s\n" % [label, ", ".join(key_strs)]
