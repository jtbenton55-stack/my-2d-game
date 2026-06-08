@tool
extends EditorPlugin

var _dock: Control


func _enter_tree() -> void:
	var dock_scene := preload("res://addons/mission_paint_dock/MissionPaintDock.tscn")
	_dock = dock_scene.instantiate()
	_dock.name = "Mission Paint Dock"
	if _dock.has_method("setup"):
		_dock.setup(self)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	set_input_event_forwarding_always_enabled()


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


func _handles(object: Object) -> bool:
	return object is CanvasItem


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if _dock == null or not _dock.has_method("handle_canvas_gui_input"):
		return false
	return bool(_dock.call("handle_canvas_gui_input", event))
