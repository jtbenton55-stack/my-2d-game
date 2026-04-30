extends Area2D

signal note_read(note: Node)

@export var note_title: String = "Note"
@export_multiline var note_text: String = "This is a note."
@export var note_image: Texture2D
@export var polaroid_id: String = ""

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	_show_note()
	note_read.emit(self)

func _show_note() -> void:
	var packed := load("res://src/interactables/note_panel.tscn") as PackedScene
	if packed == null:
		EventBus.warn("Note panel scene missing.")
		return
	var panel := packed.instantiate()
	if panel.has_method("set_note"):
		panel.set_note(note_title, note_text, note_image)
	# Full-screen Control must not be parented directly under mission Node2D—layout breaks (e.g. clipped corner UI).
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "NotePanelCanvas"
	ui_layer.layer = 92
	ui_layer.add_to_group("blocking_ui")
	get_tree().current_scene.add_child(ui_layer)
	ui_layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.tree_exiting.connect(_free_note_canvas.bind(ui_layer))
	if polaroid_id != "":
		CollectibleManager.collect_polaroid(polaroid_id)


func _free_note_canvas(host: CanvasLayer) -> void:
	if is_instance_valid(host):
		host.remove_from_group("blocking_ui")
		host.call_deferred("queue_free")
