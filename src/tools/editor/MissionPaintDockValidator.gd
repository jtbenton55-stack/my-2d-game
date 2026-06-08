@tool
extends EditorScript
class_name MissionPaintDockValidator

const PLUGIN_CFG := "res://addons/mission_paint_dock/plugin.cfg"
const PLUGIN_SCRIPT := "res://addons/mission_paint_dock/MissionPaintDockPlugin.gd"
const DOCK_SCENE := "res://addons/mission_paint_dock/MissionPaintDock.tscn"
const DOCK_SCRIPT := "res://addons/mission_paint_dock/MissionPaintDock.gd"
const TEST_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(PLUGIN_CFG), "plugin.cfg missing.", failures)
	_require(FileAccess.file_exists(PLUGIN_SCRIPT), "plugin script missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCENE), "dock scene missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCRIPT), "dock script missing.", failures)
	var plugin_text := FileAccess.get_file_as_string(PLUGIN_SCRIPT) if FileAccess.file_exists(PLUGIN_SCRIPT) else ""
	var dock_text := FileAccess.get_file_as_string(DOCK_SCRIPT) if FileAccess.file_exists(DOCK_SCRIPT) else ""
	_require(plugin_text.contains("extends EditorPlugin"), "plugin does not extend EditorPlugin.", failures)
	_require(plugin_text.contains("add_control_to_dock"), "plugin does not add dock.", failures)
	_require(plugin_text.contains("remove_control_from_docks"), "plugin does not remove dock.", failures)
	_require(plugin_text.contains("_forward_canvas_gui_input"), "plugin does not forward canvas input.", failures)
	_require(plugin_text.contains("handle_canvas_gui_input"), "plugin does not delegate canvas input to dock.", failures)
	_require(dock_text.contains("@tool"), "dock script is not @tool.", failures)
	_require(dock_text.contains("Mission Paint Dock"), "dock title missing.", failures)
	_require(dock_text.contains("Visual Paint") and dock_text.contains("Layout Blockout") and dock_text.contains("Collision Barrier"), "dock modes missing.", failures)
	_require(dock_text.contains("Unlock Layout Blockout Painting") and dock_text.contains("Unlock Collision Barrier Painting"), "dock lock checkboxes missing.", failures)
	_require(dock_text.contains("Arm Paint Tool"), "arm paint toggle missing.", failures)
	_require(dock_text.contains("GameplayRoot/LayoutRoot/FloorLayer"), "FloorLayer path missing.", failures)
	_require(dock_text.contains("GameplayRoot/LayoutRoot/WallLayer"), "WallLayer path missing.", failures)
	_require(dock_text.contains("GameplayRoot/LayoutRoot/CoverLayer"), "CoverLayer path missing.", failures)
	_require(dock_text.contains("GameplayRoot/LayoutRoot/CollisionBarrierLayer"), "CollisionBarrierLayer path missing.", failures)
	_require(dock_text.contains("GameplayRoot/LayoutRoot/MarkerTileLayer"), "MarkerTileLayer path missing.", failures)
	_require(dock_text.contains("TileMapLayer"), "dock must use TileMapLayer.", failures)
	_require(dock_text.contains("local_to_map"), "dock must use local_to_map.", failures)
	_require(dock_text.contains("set_cell") and dock_text.contains("erase_cell"), "dock must paint and erase cells.", failures)
	_require(dock_text.contains("get_undo_redo") and dock_text.contains("Mission Paint Stroke"), "dock must use UndoRedo per stroke.", failures)
	_require(dock_text.contains("GeneratedRuntimeCollision"), "dock must refuse GeneratedRuntimeCollision.", failures)
	_require(not dock_text.contains("StaticBody2D.new") and not dock_text.contains("Area2D.new") and not dock_text.contains("CollisionShape2D.new"), "dock must not spawn collision bodies.", failures)
	_require(plugin_text.contains("set_input_event_forwarding_always_enabled"), "plugin must enable canvas forwarding.", failures)
	_require(dock_text.contains("_arm_paint") and dock_text.contains("handle_canvas_gui_input"), "dock must gate paint input when disarmed.", failures)
	_require(dock_text.contains("_stroke_mouse_button") and dock_text.contains("_stroke_button_mask_held"), "stroke mouse button tracking missing.", failures)
	_require(dock_text.contains("MOUSE_BUTTON_MASK_LEFT") and dock_text.contains("MOUSE_BUTTON_MASK_RIGHT"), "stroke button mask logic missing.", failures)
	_require(dock_text.contains("MOUSE_BUTTON_RIGHT") and dock_text.contains("\"Erase\""), "right-click erase and explicit erase operation missing.", failures)
	var test_text := FileAccess.get_file_as_string(TEST_SCENE) if FileAccess.file_exists(TEST_SCENE) else ""
	_require(test_text.contains("GameplayRoot/LayoutRoot/FloorLayer") or test_text.contains("FloorLayer"), "test scene missing FloorLayer.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
