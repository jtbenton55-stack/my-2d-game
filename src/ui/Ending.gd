extends Control

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var story_label: Label = $Panel/VBox/StoryLabel
@onready var continue_button: Button = $Panel/VBox/ButtonRow/ContinueButton
@onready var title_button: Button = $Panel/VBox/ButtonRow/TitleButton

func _ready() -> void:
	AudioManager.play_music("ending")
	_render_ending()
	continue_button.pressed.connect(_on_continue_pressed)
	title_button.pressed.connect(_on_title_pressed)
	continue_button.grab_focus()

func _render_ending() -> void:
	title_label.text = "Friends Helping Friends"
	var lines: Array[String] = [
		"Victor Sterling thought she came alone.",
		"",
		"Louis opened the delivery elevator.",
		"Mere found the trap hidden in the contract.",
		"Yordano dropped the bass and the lights went dark.",
		"Dom had the getaway idling before anyone asked.",
		"Jake patched the bruises and pretended not to be proud.",
		"Bentley retrieved the master key, then judged the carpet.",
		"",
		"Some empires are built on fear.",
		"Hers was built on favors.",
		"",
		"Final Polaroid unlocked: the crew, the city, and one very important Shiba."
	]
	story_label.text = "\n".join(lines)
	GameState.dialogue_flags["ending_seen"] = true
	GameState.collect_polaroid("final_crew_polaroid")
	SaveManager.auto_save()

func _on_continue_pressed() -> void:
	SceneManager.return_to_hideout()

func _on_title_pressed() -> void:
	SceneManager.return_to_title()
