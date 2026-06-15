@tool
extends EditorPlugin

var _dock: Control


func _enter_tree() -> void:
	var dock_script := preload("res://addons/mission_dock/MissionDock.gd")
	_dock = dock_script.new()
	_dock.name = "Mission Dock"
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
	if _dock != null and _dock.has_method("should_forward_canvas_gui_input") and _dock.has_method("handle_canvas_gui_input"):
		return true
	return object == null or object is CanvasItem


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if _dock != null and _dock.has_method("handle_canvas_gui_input"):
		return bool(_dock.call("handle_canvas_gui_input", event))
	return false
