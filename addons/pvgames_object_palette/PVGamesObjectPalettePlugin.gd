@tool
extends EditorPlugin

var _dock: Control


func _enter_tree() -> void:
	var dock_scene := preload("res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.tscn")
	_dock = dock_scene.instantiate()
	_dock.name = "PVGames Object Palette"
	if _dock.has_method("setup"):
		_dock.setup(self)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	set_input_event_forwarding_always_enabled()


func notify_input_forwarding_changed() -> void:
	update_overlays()
	call_deferred("update_overlays")


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


func _handles(object: Object) -> bool:
	# Keep 2D canvas input forwarding alive independent of editor selection and
	# undo state. As long as the palette dock is present, act as an active
	# handler so re-arming after Ctrl+Z (which can leave the edited object stale,
	# freed, or empty) still receives the next viewport click. The dock's
	# should_forward_canvas_gui_input() reports when a palette mode is armed, and
	# handle_canvas_gui_input() returns false when no palette mode is active, so
	# normal editor selection/editing is preserved when not placing.
	if _dock != null and _dock.has_method("should_forward_canvas_gui_input") and _dock.has_method("handle_canvas_gui_input"):
		return true
	return object == null or object is CanvasItem


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if _dock != null and _dock.has_method("handle_canvas_gui_input"):
		return bool(_dock.call("handle_canvas_gui_input", event))
	return false
