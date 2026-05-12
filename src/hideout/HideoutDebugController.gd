extends Node
class_name HideoutDebugController

signal debug_state_requested(state_id: String)

const STATES := [
	"fresh",
	"taco_bell_completed",
	"taco_bell_missing_items",
	"high_heat",
	"louis_unlocked",
]

func connect_buttons(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
	var labels := {
		"fresh": "Fresh Hideout",
		"taco_bell_completed": "Taco Bell Completed",
		"taco_bell_missing_items": "Taco Bell Completed Missing Items",
		"high_heat": "High Heat",
		"louis_unlocked": "Louis Unlocked",
	}
	for state_id in STATES:
		var button := Button.new()
		button.text = labels[state_id]
		button.custom_minimum_size = Vector2(260, 34)
		button.add_theme_color_override("font_color", Color(1, 0.1, 0.1, 1))
		button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		button.add_theme_constant_override("outline_size", 4)
		button.pressed.connect(func() -> void:
			debug_state_requested.emit(state_id)
		)
		container.add_child(button)
	_hide_debug_hideout_panel_root(container)


func _hide_debug_hideout_panel_root(container: Node) -> void:
	var walk: Node = container
	for _i in range(6):
		if walk == null:
			return
		if String(walk.name).begins_with("DebugHideout"):
			(walk as CanvasItem).visible = false
			return
		walk = walk.get_parent()
