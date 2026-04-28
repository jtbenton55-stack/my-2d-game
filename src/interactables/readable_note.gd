extends Area2D

@export var note_title: String = "Note"
@export_multiline var note_text: String = "This is a note."
@export var note_image: Texture2D
@export var polaroid_id: String = ""

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	_show_note()

func _show_note() -> void:
	var packed := load("res://src/interactables/note_panel.tscn") as PackedScene
	if packed == null:
		EventBus.warn("Note panel scene missing.")
		return
	var panel := packed.instantiate()
	if panel.has_method("set_note"):
		panel.set_note(note_title, note_text, note_image)
	get_tree().current_scene.add_child(panel)
	if polaroid_id != "":
		CollectibleManager.collect_polaroid(polaroid_id)
