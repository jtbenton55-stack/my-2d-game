@tool
extends EditorScript
class_name CharacterAnimationMapperValidator

const PLUGIN_CFG := "res://addons/character_animation_mapper/plugin.cfg"
const PLUGIN_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationMapperPlugin.gd"
const DOCK_SCENE := "res://addons/character_animation_mapper/CharacterAnimationMapperDock.tscn"
const DOCK_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationMapperDock.gd"
const GRID_CANVAS_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationGridCanvas.gd"
const LARGE_REVIEW_WINDOW_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd"
const MANUAL_MAPPING_WINDOW_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd"
const MAPPER_HELPERS_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd"
const CANDIDATE_DETECTOR_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationCandidateDetector.gd"
const CANDIDATE_STRIP_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationCandidateStrip.gd"
const SANDBOX_SCENE := "res://scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn"
const SANDBOX_SCRIPT := "res://src/tools/editor/CharacterAnimationMapperPreviewSandbox.gd"
const MAPS_DIR := "res://resources/character_animation_maps/"
const PREVIEW_DIR := "res://resources/character_animation_maps/generated_preview/"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(PLUGIN_CFG), "plugin.cfg missing.", failures)
	_require(FileAccess.file_exists(PLUGIN_SCRIPT), "plugin script missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCENE), "dock scene missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCRIPT), "dock script missing.", failures)
	_require(FileAccess.file_exists(SANDBOX_SCENE), "preview sandbox scene missing.", failures)
	_require(FileAccess.file_exists(SANDBOX_SCRIPT), "preview sandbox script missing.", failures)
	var plugin_text := FileAccess.get_file_as_string(PLUGIN_SCRIPT) if FileAccess.file_exists(PLUGIN_SCRIPT) else ""
	var dock_text := FileAccess.get_file_as_string(DOCK_SCRIPT) if FileAccess.file_exists(DOCK_SCRIPT) else ""
	var sandbox_text := FileAccess.get_file_as_string(SANDBOX_SCRIPT) if FileAccess.file_exists(SANDBOX_SCRIPT) else ""
	_require(plugin_text.contains("extends EditorPlugin"), "plugin does not extend EditorPlugin.", failures)
	_require(plugin_text.contains("add_control_to_dock"), "plugin does not add dock.", failures)
	_require(plugin_text.contains("remove_control_from_docks"), "plugin does not remove dock.", failures)
	_require(dock_text.contains("@tool"), "dock script is not @tool.", failures)
	_require(dock_text.contains("Character Animation Mapper"), "dock title missing.", failures)
	_require(dock_text.contains("Load Sheet"), "Load Sheet button missing.", failures)
	_require(dock_text.contains("Image.load_from_file"), "dock must load disk image dimensions via Image.load_from_file.", failures)
	_require(dock_text.contains("ImageTexture.create_from_image"), "dock must build sheet texture from full disk image.", failures)
	_require(dock_text.contains("get_map_output_path"), "dock map output path API missing.", failures)
	_require(dock_text.contains("Open Large Review Canvas"), "Open Large Review Canvas button missing.", failures)
	_require(dock_text.contains("Open Manual Mapping Window"), "Open Manual Mapping Window button missing.", failures)
	_require(FileAccess.file_exists(GRID_CANVAS_SCRIPT), "CharacterAnimationGridCanvas script missing.", failures)
	_require(FileAccess.file_exists(LARGE_REVIEW_WINDOW_SCRIPT), "CharacterAnimationLargeReviewWindow script missing.", failures)
	_require(FileAccess.file_exists(MANUAL_MAPPING_WINDOW_SCRIPT), "CharacterAnimationManualMappingWindow script missing.", failures)
	_require(FileAccess.file_exists(MAPPER_HELPERS_SCRIPT), "CharacterAnimationMapperHelpers script missing.", failures)
	var grid_text := FileAccess.get_file_as_string(GRID_CANVAS_SCRIPT) if FileAccess.file_exists(GRID_CANVAS_SCRIPT) else ""
	var window_text := FileAccess.get_file_as_string(LARGE_REVIEW_WINDOW_SCRIPT) if FileAccess.file_exists(LARGE_REVIEW_WINDOW_SCRIPT) else ""
	var manual_window_text := FileAccess.get_file_as_string(MANUAL_MAPPING_WINDOW_SCRIPT) if FileAccess.file_exists(MANUAL_MAPPING_WINDOW_SCRIPT) else ""
	var helpers_text := FileAccess.get_file_as_string(MAPPER_HELPERS_SCRIPT) if FileAccess.file_exists(MAPPER_HELPERS_SCRIPT) else ""
	var strip_text := FileAccess.get_file_as_string(CANDIDATE_STRIP_SCRIPT) if FileAccess.file_exists(CANDIDATE_STRIP_SCRIPT) else ""
	_require(grid_text.contains("size = content_size"), "grid canvas must set full content size.", failures)
	_require(grid_text.contains("MAX_FULL_DRAW_CELLS") or grid_text.contains("_draw_cell_range"), "grid canvas full draw path missing.", failures)
	_require(grid_text.contains("SelectionMode") and grid_text.contains("REPLACE") and grid_text.contains("ADD") and grid_text.contains("REMOVE"), "grid canvas selection modes missing.", failures)
	_require(grid_text.contains("_linear_frames_between"), "grid canvas linear frame drag missing.", failures)
	_require(
		grid_text.contains("CANVAS_BACKGROUND") or grid_text.contains("Color(0.96, 0.96, 0.94"),
		"grid canvas white/near-white background intent missing.",
		failures
	)
	_require(
		grid_text.contains("GRID_LINE_COLOR") or grid_text.contains("Color(1.0, 0.0, 0.0, 0.75"),
		"grid canvas red grid line intent missing.",
		failures
	)
	_require(
		window_text.contains("PANEL_BACKGROUND") or window_text.contains("Color(0.96, 0.96, 0.94"),
		"large review window light panel background intent missing.",
		failures
	)
	_require(window_text.contains("Candidate Preview"), "left-side Candidate Preview heading missing.", failures)
	_require(window_text.contains("_candidate_preview_rect"), "left-side candidate preview rect missing.", failures)
	_require(
		window_text.contains("Vector2(180, 180)") or window_text.contains("180, 180"),
		"candidate preview compact size (~25% smaller) missing.",
		failures
	)
	_require(
		window_text.contains("_build_candidate_queue_ui(left)"),
		"candidate review queue should be built on left column.",
		failures
	)
	_require(
		window_text.contains("_build_left_candidate_strip_and_hover"),
		"left-side candidate strip and hover layout missing.",
		failures
	)
	_require(
		strip_text.contains("frame_hovered") and strip_text.contains("frame_hover_cleared"),
		"candidate strip hover zoom signals missing.",
		failures
	)
	_require(window_text.contains("_strip_hover_rect"), "candidate strip hover zoom preview missing.", failures)
	_require(
		window_text.contains("Suggest 8 Direction Candidates") or window_text.contains("Optional Direction Pattern Helper"),
		"direction helper rename/section missing.",
		failures
	)
	_require(
		window_text.contains("does not mark anything reviewed") or window_text.contains("not_auto_reviewed"),
		"direction helper must clarify needs_review only.",
		failures
	)
	_require(window_text.contains("Candidate Start Frame"), "Candidate Start Frame control missing.", failures)
	_require(window_text.contains("Candidate End Frame"), "Candidate End Frame control missing.", failures)
	_require(
		window_text.contains("_apply_candidate_frame_range_edit") or window_text.contains("update_candidate_contiguous_range"),
		"candidate start/end edit sync path missing.",
		failures
	)
	_require(helpers_text.contains("update_candidate_contiguous_range"), "helpers update_candidate_contiguous_range missing.", failures)
	_require(window_text.contains("Large Review Canvas"), "large review window title missing.", failures)
	_require(window_text.contains("Apply Selection To Dock"), "Apply Selection To Dock missing.", failures)
	_require(window_text.contains("Add / Update Animation From Selection"), "canvas add/update animation missing.", failures)
	_require(window_text.contains("dock list only"), "canvas must clarify Add/Update does not save JSON.", failures)
	_require(window_text.contains("Save Reviewed Map JSON"), "canvas must mention Save Reviewed Map JSON.", failures)
	_require(helpers_text.contains("build_animation_entry"), "helpers build_animation_entry missing.", failures)
	_require(helpers_text.contains("\"frames\""), "helpers preserve frames field.", failures)
	_require(dock_text.contains("get_large_review_state"), "dock large review state API missing.", failures)
	_require(dock_text.contains("apply_canvas_selection_to_dock"), "dock apply canvas selection missing.", failures)
	_require(dock_text.contains("upsert_animation_from_canvas"), "dock upsert from canvas missing.", failures)
	_require(dock_text.contains("approve_reviewed_animation"), "dock approve reviewed API missing.", failures)
	_require(FileAccess.file_exists(CANDIDATE_DETECTOR_SCRIPT), "CharacterAnimationCandidateDetector script missing.", failures)
	_require(FileAccess.file_exists(CANDIDATE_STRIP_SCRIPT), "CharacterAnimationCandidateStrip script missing.", failures)
	var detector_text := FileAccess.get_file_as_string(CANDIDATE_DETECTOR_SCRIPT) if FileAccess.file_exists(CANDIDATE_DETECTOR_SCRIPT) else ""
	_require(detector_text.contains("detect_from_image"), "candidate detector entrypoint missing.", failures)
	_require(detector_text.contains("needs_review"), "detector must emit needs_review candidates.", failures)
	_require(detector_text.contains("detected_by=image_signature"), "detector notes must include detected_by=image_signature.", failures)
	_require(window_text.contains("Detect Candidate Ranges"), "Detect Candidate Ranges button missing.", failures)
	_require(window_text.contains("Candidate Review Queue"), "Candidate Review Queue section missing.", failures)
	_require(window_text.contains("Load Candidate Map"), "Load Candidate Map missing.", failures)
	_require(window_text.contains("Save Candidate Map"), "Save Candidate Map missing.", failures)
	_require(window_text.contains("Approve As Reviewed"), "Approve As Reviewed missing.", failures)
	_require(window_text.contains("Reject Candidate"), "Reject Candidate missing.", failures)
	_require(window_text.contains("Structured Naming Panel"), "Structured Naming Panel missing.", failures)
	_require(helpers_text.contains("toward_left") or window_text.contains("toward_left"), "direction toward_left missing.", failures)
	_require(window_text.contains("build_structured_name") or helpers_text.contains("build_structured_name"), "structured auto-name helper missing.", failures)
	_require(helpers_text.contains("validate_candidate_map_schema"), "candidate schema validation missing.", failures)
	_require(helpers_text.contains("map_kind"), "helpers candidate map_kind support missing.", failures)
	_require(window_text.contains("approve_reviewed_animation"), "window must route approval through dock reviewed API.", failures)
	_require(detector_text.contains('"review_status": "needs_review"'), "detector must emit needs_review only.", failures)
	_require(dock_text.contains("Add / Update Animation Range"), "Add / Update Animation Range missing.", failures)
	_require(dock_text.contains("Preview Selected Range"), "Preview Selected Range missing.", failures)
	_require(dock_text.contains("Save Reviewed Map JSON"), "Save Reviewed Map JSON missing.", failures)
	_require(dock_text.contains("Generate Validation SpriteFrames"), "Generate Validation SpriteFrames missing.", failures)
	_require(dock_text.contains("Import C2B Candidates as Needs Review"), "candidate import button missing.", failures)
	_require(dock_text.contains("Save Candidate Map JSON"), "save candidate map button missing.", failures)
	_require(dock_text.contains("Imported classifier/diagnostic ranges are suggestions only"), "candidate import hint missing.", failures)
	_require(dock_text.contains("needs_review_%s") or dock_text.contains("needs_review_"), "imported candidates use needs_review naming.", failures)
	_require(dock_text.contains("diagnostic_label="), "import preserves diagnostic label in notes.", failures)
	_require(dock_text.contains("\"review_status\": \"needs_review\"") or dock_text.contains('review_status": "needs_review"'), "import forces needs_review status.", failures)
	_require(not dock_text.contains("review_status\": \"reviewed\"") or dock_text.contains("!= \"reviewed\""), "import must not auto-mark reviewed.", failures)
	_require(dock_text.contains("recommended_animation_clips.json"), "dock reads recommended clips JSON.", failures)
	_require(dock_text.contains(MAPS_DIR), "maps output dir missing.", failures)
	_require(dock_text.contains("schema_version"), "schema_version missing.", failures)
	_require(dock_text.contains("source_sheet"), "source_sheet missing.", failures)
	_require(dock_text.contains("frame_width"), "frame_width missing.", failures)
	_require(dock_text.contains("frame_height"), "frame_height missing.", failures)
	_require(dock_text.contains("animations"), "animations missing.", failures)
	_require(dock_text.contains("review_status"), "review_status missing.", failures)
	_require(dock_text.contains("reviewed") and dock_text.contains("needs_review") and dock_text.contains("rejected"), "review statuses missing.", failures)
	_require(dock_text.contains(PREVIEW_DIR), "generated_preview path missing.", failures)
	_require(dock_text.contains("SpriteFrames"), "SpriteFrames generation missing.", failures)
	_require(dock_text.contains("_refresh_export_readout"), "export readout missing.", failures)
	_require(dock_text.contains("Open Preview Sandbox Scene"), "open sandbox button missing.", failures)
	_require(dock_text.contains("res://"), "dock must use res:// paths.", failures)
	_require(dock_text.contains("_is_safe_output_path"), "dock must guard output paths.", failures)
	_require(dock_text.contains("Refusing to write outside"), "dock must refuse writes outside maps dir.", failures)
	_require(dock_text.contains("Refusing unsafe output path"), "dock must refuse unsafe spriteframes path.", failures)
	_require(dock_text.contains("FileAccess.open"), "dock must save JSON via FileAccess.", failures)
	_require(dock_text.contains("ResourceSaver.save") and dock_text.contains("SpriteFrames"), "dock must save validation SpriteFrames.", failures)
	_require(sandbox_text.contains("AnimatedSprite2D"), "sandbox must use AnimatedSprite2D.", failures)
	_require(sandbox_text.contains(PREVIEW_DIR) or sandbox_text.contains("generated_preview"), "sandbox default path must use generated_preview.", failures)
	_require(sandbox_text.contains("parmida_manual_preview_spriteframes"), "sandbox default preview SpriteFrames path missing.", failures)
	_require(not sandbox_text.contains("player.tscn"), "sandbox must not reference production player scene.", failures)
	_require(not sandbox_text.contains("TacoBellIso"), "sandbox must not reference Taco scenes.", failures)
	_require(not sandbox_text.contains("Player.gd"), "sandbox must not reference Player.gd.", failures)
	_require(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(MAPS_DIR)) or FileAccess.file_exists(MAPS_DIR + ".gitkeep"), "character_animation_maps folder missing.", failures)
	_require(window_text.contains("_left_split"), "left VSplitContainer scroll layout missing.", failures)
	_require(window_text.contains("Detect Candidate Ranges"), "normal Detect Candidate Ranges must remain.", failures)
	_require(window_text.contains("Optional Direction Pattern Helper"), "direction helper needs_review section missing.", failures)
	_require(manual_window_text.contains("Manual Animation Mapping"), "manual mapping window title missing.", failures)
	_require(manual_window_text.contains("Structured Naming Panel"), "manual mapping structured naming panel missing.", failures)
	_require(manual_window_text.contains("Selected Frame Strip"), "manual mapping selected frame strip missing.", failures)
	_require(manual_window_text.contains("Add / Update Animation From Selection"), "manual mapping add/update button missing.", failures)
	_require(manual_window_text.contains("upsert_animation_from_canvas"), "manual mapping must upsert through dock API.", failures)
	_require(manual_window_text.contains("dock list only"), "manual mapping must clarify JSON save is in dock.", failures)
	_require(manual_window_text.contains("_strip_hover_rect"), "manual mapping strip hover zoom missing.", failures)
	_require(manual_window_text.contains("Play Preview"), "manual mapping play preview missing.", failures)
	_require(not manual_window_text.contains("Detect Candidate Ranges"), "manual mapping must not include candidate detection.", failures)
	_require(manual_window_text.contains("Jump Frame"), "manual mapping jump to frame control missing.", failures)
	_require(manual_window_text.contains("Focus Selection"), "manual mapping focus selection control missing.", failures)
	_require(manual_window_text.contains("Saved Animations"), "manual mapping saved animations list missing.", failures)
	_require(manual_window_text.contains("refresh_saved_animations_list"), "manual mapping saved list refresh missing.", failures)
	_require(manual_window_text.contains("FPS quick"), "manual mapping FPS quick buttons missing.", failures)
	_require(manual_window_text.contains("_apply_next_variant_for_action"), "manual mapping variant auto-advance missing.", failures)
	_require(dock_text.contains("get_animation_entries_snapshot"), "dock animation entries snapshot API missing.", failures)
	_require(helpers_text.contains("format_animation_list_label"), "helpers format_animation_list_label missing.", failures)
	_require(helpers_text.contains("parse_structured_animation_name"), "helpers parse_structured_animation_name missing.", failures)
	_require(helpers_text.contains("next_variant_for_action_stem"), "helpers next_variant_for_action_stem missing.", failures)
	_require(helpers_text.contains("COMMON_ANIMATION_NAME_STEMS"), "helpers common animation name stems missing.", failures)
	_require(helpers_text.contains("filter_common_animation_names"), "helpers filter_common_animation_names missing.", failures)
	_require(FileAccess.file_exists("res://addons/character_animation_mapper/CharacterAnimationCollapsibleSection.gd"), "collapsible section script missing.", failures)
	_require(dock_text.contains("_begin_collapsible_section"), "dock collapsible sections missing.", failures)
	_require(dock_text.contains("character__working_manual_map.json"), "dock default working manual map missing.", failures)
	_require(dock_text.contains("manual_5pack_20260521/character_01_parmida_reference_variant_sheet.png"), "dock default parmida manual sheet missing.", failures)
	_require(manual_window_text.contains("_action_pick_list"), "manual mapping searchable action list missing.", failures)
	_require(manual_window_text.contains("_action_search_edit"), "manual mapping action search field missing.", failures)
	_require(manual_window_text.contains("_apply_action_stem_from_picker"), "manual mapping action picker apply missing.", failures)
	_require(manual_window_text.contains("Delete Selected Animation"), "manual mapping delete button missing.", failures)
	_require(manual_window_text.contains("_delete_confirm_dialog"), "manual mapping delete confirmation missing.", failures)
	_require(dock_text.contains("delete_animation_by_index"), "dock delete_animation_by_index API missing.", failures)
	_require(helpers_text.contains("next_variant_for_action_direction"), "helpers next_variant_for_action_direction missing.", failures)
	_require(manual_window_text.contains("_begin_collapsible_section"), "manual mapping collapsible sections missing.", failures)
	_require(manual_window_text.contains("GRID_VIEWPORT_MIN"), "manual mapping grid viewport minimum size missing.", failures)
	_require(sandbox_text.contains("PREVIEW_OPTIONS"), "sandbox preview character dropdown missing.", failures)
	_require(sandbox_text.contains("PreviewOptionButton"), "sandbox preview option button missing.", failures)
	_require(sandbox_text.contains("LoadPreviewButton"), "sandbox load preview button missing.", failures)
	_require(sandbox_text.contains("SAFE_MAX_BYTES"), "sandbox spriteframes size guard missing.", failures)
	_require(sandbox_text.contains("_on_load_preview_pressed"), "sandbox explicit load preview handler missing.", failures)
	_require(sandbox_text.contains("_refresh_pending_state"), "sandbox pending preview state missing.", failures)
	_require(FileAccess.file_exists("res://addons/character_animation_mapper/CharacterAnimationSpriteFramesExporter.gd"), "spriteframes exporter helper missing.", failures)
	_require(FileAccess.file_exists("res://src/tools/editor/Manual5PackCharacterAnimationBatchValidator.gd"), "manual 5-pack batch validator missing.", failures)
	_require(manual_window_text.contains("Mapping QA / Review"), "manual mapping QA section missing.", failures)
	_require(manual_window_text.contains("_refresh_qa_from_current_map"), "manual mapping QA refresh missing.", failures)
	_require(manual_window_text.contains("Show Unassigned Frames"), "manual mapping unassigned frames viewer missing.", failures)
	_require(FileAccess.file_exists("res://addons/character_animation_mapper/CharacterAnimationUnassignedFramesViewer.gd"), "unassigned frames viewer script missing.", failures)
	_require(helpers_text.contains("build_mapping_qa_review_items"), "helpers mapping QA review items missing.", failures)
	_require(helpers_text.contains("build_unassigned_frame_ranges"), "helpers unassigned frame ranges missing.", failures)
	_require(grid_text.contains("scroll_to_frame"), "grid canvas scroll_to_frame missing.", failures)
	_require(grid_text.contains("focus_selection"), "grid canvas focus_selection missing.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
