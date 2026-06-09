@tool
extends EditorPlugin

const DOCK_SCRIPT := preload("res://addons/scene_asset_browser/SceneAssetBrowserDock.gd")

var _dock: Control


func _enter_tree() -> void:
	_dock = DOCK_SCRIPT.new()
	_dock.name = "Scene/Asset Browser"
	if _dock.has_method("setup"):
		_dock.setup(self)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
