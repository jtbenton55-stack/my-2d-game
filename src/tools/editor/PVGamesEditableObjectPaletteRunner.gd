@tool
extends EditorScript
class_name PVGamesEditableObjectPaletteRunner

const Helper = preload("res://src/tools/editor/PVGamesEditableObjectPaletteBrowserHelper.gd")
const Stamper = preload("res://src/tools/editor/PVGamesObjectStamperTool.gd")

# Default is intentionally non-destructive.
const MODE := "dry_run_list_palette"

const OBJECT_ID := "pvg_obj_core_wall_interior_wall11_2_0189"
const TARGET_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const TARGET_CONTAINER := "OccludableObjects"
const TARGET_POSITION := Vector2(0, 0)
const TARGET_SCALE := Vector2(1, 1)
const TARGET_ROTATION_DEGREES := 0.0
const TARGET_Z_INDEX := 999999
const CONTAINER_NAME := "OccludableObjects"
const CATEGORY := "wall"
const SOURCE_SET := "core"
const PALETTE_SCENE := "res://scenes/hideout/tools/PVGamesEditableObjectPalette_OccludableObjects_Page001.tscn"


func _run() -> void:
	var helper := Helper.new()
	var stamper := Stamper.new()
	match MODE:
		"dry_run_list_palette":
			helper.list_by_container(CONTAINER_NAME)
		"dry_run_find_object":
			helper.print_object_info(OBJECT_ID)
		"dry_run_stamp_object":
			print(JSON.stringify(stamper.stamp_object_dry_run(TARGET_SCENE, OBJECT_ID, TARGET_POSITION, TARGET_CONTAINER, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"stamp_object":
			print(JSON.stringify(stamper.stamp_object(TARGET_SCENE, OBJECT_ID, TARGET_POSITION, TARGET_CONTAINER, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"list_by_container":
			helper.list_by_container(CONTAINER_NAME)
		"list_by_category":
			helper.list_by_category(CATEGORY)
		"list_by_source_set":
			var out: Array[Dictionary] = []
			for entry in helper._objects():
				if String(entry.get("source_set", "")) == SOURCE_SET:
					out.append(entry)
			print(JSON.stringify(out, "\t"))
		"validate_palette":
			helper.validate_palette_scene(PALETTE_SCENE)
		_:
			push_error("Unsupported B8A palette runner mode: %s" % MODE)
