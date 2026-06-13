@tool
extends EditorScript
class_name PVGamesObjectPaletteDockValidator

const PLUGIN_CFG := "res://addons/pvgames_object_palette/plugin.cfg"
const PLUGIN_SCRIPT := "res://addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd"
const DOCK_SCENE := "res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.tscn"
const DOCK_SCRIPT := "res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd"
const OBJECT_INDEX := "res://docs/reports/pvgames_editable_object_asset_index.json"
const EDITABLE_OBJECT_SCENE := "res://scenes/hideout/tools/PVGEditableObject.tscn"
const TEST_SCENE := "res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn"
const HOW_TO := "res://docs/reports/pvgames_object_palette_dock/pvgames_object_palette_dock_how_to_use.md"
const REPORT_JSON := "res://docs/reports/pvgames_object_palette_dock/pvgames_object_palette_dock_creation.json"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(PLUGIN_CFG), "plugin.cfg missing.", failures)
	_require(FileAccess.file_exists(PLUGIN_SCRIPT), "plugin script missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCENE), "dock scene missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCRIPT), "dock script missing.", failures)
	_require(FileAccess.file_exists(OBJECT_INDEX), "object index missing.", failures)
	_require(FileAccess.file_exists(EDITABLE_OBJECT_SCENE), "editable object scene missing.", failures)
	_require(FileAccess.file_exists(TEST_SCENE), "dock test scene missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "how-to missing.", failures)
	var plugin_text := FileAccess.get_file_as_string(PLUGIN_SCRIPT) if FileAccess.file_exists(PLUGIN_SCRIPT) else ""
	var dock_scene_text := FileAccess.get_file_as_string(DOCK_SCENE) if FileAccess.file_exists(DOCK_SCENE) else ""
	var dock_text := FileAccess.get_file_as_string(DOCK_SCRIPT) if FileAccess.file_exists(DOCK_SCRIPT) else ""
	_require(plugin_text.contains("extends EditorPlugin"), "plugin does not extend EditorPlugin.", failures)
	_require(plugin_text.contains("add_control_to_dock"), "plugin does not add dock.", failures)
	_require(plugin_text.contains("remove_control_from_docks"), "plugin does not remove dock.", failures)
	_require(not plugin_text.contains("stamp_selected"), "plugin appears to stamp on load.", failures)
	_require(dock_scene_text.contains("size_flags_vertical") or dock_text.contains("size_flags_vertical"), "dock root does not expand vertically.", failures)
	_require(dock_text.contains("ScrollContainer.new") and dock_text.contains("MainScroll"), "dock lacks script-created ScrollContainer.", failures)
	_require(dock_text.contains("ContentVBox"), "dock lacks scroll content container.", failures)
	_require(dock_text.contains("\"Actions\""), "Actions section missing.", failures)
	_require(dock_text.contains("\"Ensure Art Stamp Root\""), "Ensure Art Stamp Root button missing.", failures)
	_require(dock_text.contains("\"Dry Run Stamp\""), "Dry Run Stamp button missing.", failures)
	_require(dock_text.contains("\"Stamp Selected at Typed Position\""), "typed-position stamp button missing.", failures)
	_require(dock_text.contains("\"Stamp Selected at Scene Origin\""), "scene-origin stamp button missing.", failures)
	_require(dock_text.contains("\"Place With Mouse\"") and dock_text.contains("handle_canvas_gui_input"), "mouse placement path missing.", failures)
	_require(dock_text.contains("_stamp_selected_from_mouse_event") and dock_text.contains("_event_position_in_container"), "mouse placement coordinate helper missing.", failures)
	_require(dock_text.contains("Brush Mode") and dock_text.contains("_brush_mode"), "brush mode toggle missing.", failures)
	_require(dock_text.contains("Brush Spacing") and dock_text.contains("_brush_spacing_spin"), "brush spacing control missing.", failures)
	_require(dock_text.contains("_begin_brush_stroke") and dock_text.contains("_commit_brush_stroke") and dock_text.contains("_cancel_brush_stroke"), "brush stroke helpers missing.", failures)
	_require(dock_text.contains("_stamp_brush_points_in_container") and dock_text.contains("Brush Stamp PVGames Palette Entries"), "brush undo action missing.", failures)
	_require(dock_text.contains("_canvas_position_from_mouse_event") and dock_text.contains("get_mouse_position"), "brush canvas coordinate conversion missing.", failures)
	_require(dock_text.contains("Brush Alignment") and dock_text.contains("_brush_alignment"), "brush alignment control missing.", failures)
	_require(dock_text.contains("Auto Asset Spacing") and dock_text.contains("_brush_auto_spacing"), "brush auto asset spacing missing.", failures)
	_require(dock_text.contains("_rebuild_axis_locked_brush_points") and dock_text.contains("_effective_brush_spacing"), "axis-locked brush spacing helpers missing.", failures)
	_require(dock_text.contains("_selected_asset_scaled_visible_size") and dock_text.contains("_texture_visible_size"), "brush visible-bounds spacing helpers missing.", failures)
	_require(dock_text.contains("_compute_image_visible_size") and dock_text.contains("_brush_visible_size_cache"), "brush visible-size cache/compute helpers missing.", failures)
	_require(dock_text.contains("visible opaque bounds") or dock_text.contains("visible/content bounds"), "brush help text does not mention visible-bounds spacing.", failures)
	_require(dock_text.contains("\"Copy Object ID\""), "Copy Object ID button missing.", failures)
	_require(dock_text.contains("\"Refresh Index\""), "Refresh Index button missing.", failures)
	_require(dock_text.contains("custom_minimum_size = Vector2(360, 320)"), "result list height is not controlled.", failures)
	_require(dock_text.contains("_shorten_middle"), "source path overflow helper missing.", failures)
	_require(dock_text.contains("_load_indexes"), "dock index loader missing.", failures)
	_require(dock_text.contains("_apply_filters"), "dock filter function missing.", failures)
	_require(dock_text.contains("_dry_run_stamp_selected"), "dry-run function missing.", failures)
	_require(dock_text.contains("_stamp_selected_at_position"), "actual stamp function missing.", failures)
	_require(dock_text.contains("_ensure_art_stamp_root"), "art stamp root setup helper missing.", failures)
	_require(plugin_text.contains("_forward_canvas_gui_input") and plugin_text.contains("set_input_event_forwarding_always_enabled"), "plugin does not forward 2D canvas input.", failures)
	_require(dock_text.contains("ArtRoot/World/PVG_EditableObjects") or dock_text.contains("PVG_EditableObjects"), "container target missing.", failures)
	_require(dock_text.contains("_node_is_under_gameplayroot"), "GameplayRoot rejection helper missing.", failures)
	_require(not dock_text.contains("CollisionShape2D.new") and not dock_text.contains("StaticBody2D.new"), "dock creates collision.", failures)
	# Phase 3G v2: placement route, sortable, erase, variation, shapes
	_require(dock_text.contains("Placement Route") and dock_text.contains("_placement_route"), "placement route UI missing.", failures)
	_require(dock_text.contains("Fixed Behind Art") and dock_text.contains("Sortable 2.5D Prop") and dock_text.contains("Fixed Foreground Art"), "placement route labels missing.", failures)
	_require(dock_text.contains("_selected_placement_route") and dock_text.contains("_resolve_stamp_target"), "placement route resolution missing.", failures)
	_require(dock_text.contains("_resolve_sortable_parent") and dock_text.contains("VisualRoot/SortableWorld"), "sortable parent resolution missing.", failures)
	_require(dock_text.contains("y_sort_enabled"), "sortable y_sort_enabled validation missing.", failures)
	_require(dock_text.contains("placement_route") and dock_text.contains("sortable_2d_prop"), "sortable placement metadata missing.", failures)
	_require(dock_text.contains("Erase Palette Stamps") and dock_text.contains("_erase_selected_palette_created_node"), "palette erase UI missing.", failures)
	_require(dock_text.contains("_node_is_palette_created") and dock_text.contains("created_by"), "palette-created metadata check missing.", failures)
	_require(dock_text.contains("Erase PVGames Palette Stamp"), "palette erase undo action missing.", failures)
	_require(dock_text.contains("Variation") and dock_text.contains("Enable Position Jitter"), "variation jitter UI missing.", failures)
	_require(dock_text.contains("Enable Random Rotation") and dock_text.contains("Enable Random Scale"), "variation rotation/scale UI missing.", failures)
	_require(dock_text.contains("Deterministic Random Seed") and dock_text.contains("_random_for_stamp"), "deterministic seed support missing.", failures)
	_require(dock_text.contains("_apply_variation_to_transform"), "variation transform helper missing.", failures)
	_require(dock_text.contains("Placement Shape") and dock_text.contains("_placement_shape"), "placement shape UI missing.", failures)
	_require(dock_text.contains("Rectangle Outline") and dock_text.contains("Rectangle Fill") and dock_text.contains("Scatter Rectangle"), "placement shape options missing.", failures)
	_require(dock_text.contains("_build_rectangle_outline_points") and dock_text.contains("_build_rectangle_fill_points") and dock_text.contains("_build_scatter_points"), "rectangle/scatter point builders missing.", failures)
	_require(dock_text.contains("MAX_SCATTER_COUNT"), "scatter count clamp missing.", failures)
	_require(dock_text.contains("_handle_shape_drag_input") and dock_text.contains("_commit_shape_drag"), "shape drag placement missing.", failures)
	_require(dock_text.contains("func _preview_stamp_target"), "non-mutating stamp preview helper missing.", failures)
	_require(dock_text.contains("mutates_scene") and dock_text.contains("no scene changes"), "dry-run/mouse-arm non-mutating status text missing.", failures)
	_require(dock_text.contains("Use Z Override") and dock_text.contains("_use_z_override"), "explicit Z Override toggle missing.", failures)
	_require(dock_text.contains("_default_z_index_for_route"), "route default z_index helper missing.", failures)
	_require(dock_text.contains("should_forward_canvas_gui_input") and dock_text.contains("is_mouse_placement_pending"), "canvas input forwarding state helpers missing.", failures)
	_require(plugin_text.contains("set_input_event_forwarding_always_enabled"), "plugin must enable canvas input forwarding.", failures)
	_require(plugin_text.contains("should_forward_canvas_gui_input"), "plugin must handle armed palette input state.", failures)
	_require(plugin_text.contains("has_method(\"handle_canvas_gui_input\")"), "plugin _handles must stay armed via dock presence so forwarding survives Undo/selection changes.", failures)
	_require(plugin_text.contains("update_overlays") and not plugin_text.contains("emit_changed"), "plugin must refresh editor overlays without invalid EditorSelection APIs.", failures)
	_require(dock_text.contains("_collapsible_section"), "collapsible dock sections helper missing.", failures)
	_require(dock_text.contains("Box Erase Palette Stamps") and dock_text.contains("_begin_box_erase_palette_stamps"), "box erase UI missing.", failures)
	_require(dock_text.contains("_handle_erase_box_canvas_input") and dock_text.contains("_collect_erasable_stamps_in_global_rect"), "box erase canvas helpers missing.", failures)
	_require(dock_text.contains("Box Erase PVGames Palette Stamps"), "box erase undo action missing.", failures)
	_require(dock_text.contains("_erase_box_armed"), "box erase armed state missing.", failures)
	_require(dock_text.contains("_active_placement_route_key"), "explicit active placement route state missing.", failures)
	_require(dock_text.contains("_ui_ready"), "dock UI ready guard missing.", failures)
	_require(dock_text.contains("_on_use_z_override_toggled"), "Z override toggle handler missing.", failures)
	_require(dock_text.contains("Phase3JSortable2DPilot.tscn"), "sortable route scene guidance missing.", failures)
	_require(dock_text.contains("_clear_mouse_placement_pending"), "mouse placement pending cleanup helper missing.", failures)
	_require(dock_text.contains("_consume_next_left_release"), "paired-release consume guard missing (armed clicks must not leak to editor selection).", failures)
	_require(dock_text.contains("_undo_remove_palette_stamp") and dock_text.contains("_undo_remove_palette_stamp\", container, node, container"), "single-stamp undo must clear stale selection/placement state so Place With Mouse re-arms after Ctrl+Z.", failures)
	_require(dock_text.contains("_user_chose_route"), "explicit user route preservation flag missing.", failures)
	var dry_run_idx := dock_text.find("func _dry_run_stamp_selected")
	var mouse_arm_idx := dock_text.find("func _begin_place_with_mouse")
	var handle_input_idx := dock_text.find("func handle_canvas_gui_input")
	if dry_run_idx >= 0 and mouse_arm_idx > dry_run_idx:
		var dry_run_body := dock_text.substr(dry_run_idx, mouse_arm_idx - dry_run_idx)
		_require(dry_run_body.contains("_preview_stamp_target") and not dry_run_body.contains("_resolve_stamp_target"), "dry run must use preview helper without resolve.", failures)
	if mouse_arm_idx >= 0 and handle_input_idx > mouse_arm_idx:
		var mouse_arm_body := dock_text.substr(mouse_arm_idx, handle_input_idx - mouse_arm_idx)
		_require(mouse_arm_body.contains("_preview_stamp_target") and not mouse_arm_body.contains("_resolve_stamp_target"), "mouse arm must use preview helper without resolve.", failures)
	var test_text := FileAccess.get_file_as_string(TEST_SCENE) if FileAccess.file_exists(TEST_SCENE) else ""
	_require(test_text.contains("ArtRoot") and test_text.contains("World") and test_text.contains("PVG_EditableObjects"), "test scene missing required containers.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
