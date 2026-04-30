extends Control

@onready var list_label: Label = $Panel/ListLabel
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_render_smiski_list()

func _render_smiski_list() -> void:
	var smiski_ids: Array[String] = []
	for item in GameState.collected_polaroids:
		var id := String(item)
		if id.findn("smiski") != -1:
			smiski_ids.append(id)
	if smiski_ids.is_empty():
		list_label.text = "No Smiskis collected yet.\n\nTry searching mission corners and optional routes."
		return
	var lines: Array[String] = ["Collected Smiskis:"]
	for smiski_id in smiski_ids:
		var info := CollectibleManager.get_polaroid_info(smiski_id)
		lines.append("- " + String(info.get("title", smiski_id)))
	list_label.text = "\n".join(lines)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	SceneManager.return_to_hideout()
