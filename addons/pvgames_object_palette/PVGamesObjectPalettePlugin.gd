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


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
