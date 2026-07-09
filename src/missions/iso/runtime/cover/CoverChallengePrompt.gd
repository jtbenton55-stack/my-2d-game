class_name CoverChallengePrompt
extends CanvasLayer

## Replan Packet 3: when an inspector challenges the player, offer a 3-choice
## bark -- Bluff (needs an active cover story), Excuse (needs a credential),
## or Deflect to Bentley (always available but burns professionalism).

signal challenge_resolved(choice: String, ok: bool)

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export var bluff_success_exposure_decay: float = 0.4
@export var bluff_fail_exposure: float = 0.3
@export var excuse_success_exposure_decay: float = 0.3
@export var deflect_professionalism_cost: int = 1

var challenge_open: bool = false
var last_challenge_result: Dictionary = {}

var _panel: PanelContainer = null
var _buttons: Dictionary = {}


func _ready() -> void:
	layer = 30
	add_to_group("cover_challenge_prompt")
	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not challenge_open or not (event is InputEventKey) or not event.pressed:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1:
			resolve_choice("bluff")
		KEY_2:
			resolve_choice("excuse")
		KEY_3:
			resolve_choice("deflect")


func open_challenge(challenge_text: String = "Hey! What are you doing back here?") -> void:
	challenge_open = true
	_panel.visible = true
	var title := _panel.get_node_or_null("Column/Title") as Label
	if title != null:
		title.text = challenge_text
	_refresh_option_availability()
	EventBus.objective_updated.emit("Challenged! Pick your story (1/2/3).")


func resolve_choice(choice: String) -> Dictionary:
	if not challenge_open:
		return {"ok": false, "code": "no_open_challenge", "message": "No challenge is open."}
	var ok := false
	var message := ""
	match choice:
		"bluff":
			ok = _has_cover_story()
			if ok:
				_decay_exposure(bluff_success_exposure_decay)
				message = "They bought the story."
			else:
				_add_exposure(bluff_fail_exposure)
				message = "No story to sell. That looked bad."
		"excuse":
			ok = _has_credential()
			if ok:
				_decay_exposure(excuse_success_exposure_decay)
				message = "Badge checks out."
			else:
				_add_exposure(bluff_fail_exposure)
				message = "No credentials. Awkward."
		"deflect":
			ok = true
			SocialStealthAdapterScript.adjust_professionalism(-deflect_professionalism_cost, {})
			message = "Bentley takes the blame. Again."
		_:
			return {"ok": false, "code": "unknown_choice", "message": "Unknown challenge choice."}
	challenge_open = false
	_panel.visible = false
	last_challenge_result = {"ok": ok, "code": "challenge_%s" % choice, "message": message, "choice": choice}
	challenge_resolved.emit(choice, ok)
	EventBus.objective_updated.emit(message)
	return last_challenge_result


func _refresh_option_availability() -> void:
	if _buttons.has("bluff"):
		(_buttons["bluff"] as Button).disabled = not _has_cover_story()
	if _buttons.has("excuse"):
		(_buttons["excuse"] as Button).disabled = not _has_credential()


func _has_cover_story() -> bool:
	return String(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, "", {})) != ""


func _has_credential() -> bool:
	return bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, "", {}))


func _decay_exposure(amount: float) -> void:
	var controller := _alert_controller()
	if controller != null and controller.has_method("decay_exposure"):
		controller.call("decay_exposure", amount)


func _add_exposure(amount: float) -> void:
	var controller := _alert_controller()
	if controller != null and controller.has_method("accumulate_exposure"):
		controller.call("accumulate_exposure", "cover_challenge", amount, "failed_challenge")


func _alert_controller() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("iso_alert_controller")


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "ChallengePanel"
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -180.0
	_panel.offset_right = 180.0
	_panel.offset_top = -90.0
	_panel.offset_bottom = 90.0
	add_child(_panel)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)
	var title := Label.new()
	title.name = "Title"
	title.text = "Hey! What are you doing back here?"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var options := [
		["bluff", "1. Bluff (needs cover story)"],
		["excuse", "2. Excuse (needs credential)"],
		["deflect", "3. Blame Bentley (-1 professionalism)"],
	]
	for option: Array in options:
		var button := Button.new()
		button.text = String(option[1])
		var choice := String(option[0])
		button.pressed.connect(func() -> void: resolve_choice(choice))
		column.add_child(button)
		_buttons[choice] = button
