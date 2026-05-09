@tool
extends EditorScript
class_name PVGamesObjectStamperRunner

const StamperTool = preload("res://src/tools/editor/PVGamesObjectStamperTool.gd")

# Default is intentionally non-destructive.
const MODE := "dry_run_list"

# Allowed modes:
# - dry_run_list
# - dry_run_stamp
# - stamp_object
# - set_object_transform
# - duplicate_object
# - delete_object
# - convert_tile_cell_to_object_dry_run
# - convert_tile_cell_to_object

const FILTER := "wall"
const TARGET_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const OBJECT_ID := "REPLACE_WITH_OBJECT_ID_FROM_DRY_RUN_LIST"
const TARGET_CONTAINER := "OccludableObjects"
const TARGET_POSITION := Vector2(0, 0)
const TARGET_SCALE := Vector2(1, 1)
const TARGET_ROTATION_DEGREES := 0.0
const TARGET_Z_INDEX := 999999
const OBJECT_NODE_PATH := "ArtRoot/World/PVG_EditableObjects/OccludableObjects/REPLACE_WITH_OBJECT_NAME"
const TILE_LAYER_PATH := "ArtRoot/World/PVG_CatalogPaintLayers/PVGamesCatalogWallPaintLayer"
const TILE_CELL := Vector2i(0, 0)


func _run() -> void:
	var tool := StamperTool.new()
	match MODE:
		"dry_run_list":
			print(JSON.stringify(tool.list_object_assets(FILTER), "\t"))
		"dry_run_stamp":
			print(JSON.stringify(tool.stamp_object_dry_run(TARGET_SCENE, OBJECT_ID, TARGET_POSITION, TARGET_CONTAINER, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"stamp_object":
			print(JSON.stringify(tool.stamp_object(TARGET_SCENE, OBJECT_ID, TARGET_POSITION, TARGET_CONTAINER, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"set_object_transform":
			print(JSON.stringify(tool.set_object_transform(TARGET_SCENE, OBJECT_NODE_PATH, TARGET_POSITION, TARGET_SCALE, TARGET_ROTATION_DEGREES, TARGET_Z_INDEX), "\t"))
		"duplicate_object":
			print(JSON.stringify(tool.duplicate_stamped_object(TARGET_SCENE, OBJECT_NODE_PATH, TARGET_POSITION), "\t"))
		"delete_object":
			print(JSON.stringify(tool.delete_stamped_object(TARGET_SCENE, OBJECT_NODE_PATH), "\t"))
		"convert_tile_cell_to_object_dry_run":
			print(JSON.stringify(tool.convert_tile_cell_to_object_dry_run(TARGET_SCENE, TILE_LAYER_PATH, TILE_CELL), "\t"))
		"convert_tile_cell_to_object":
			print(JSON.stringify(tool.convert_tile_cell_to_object(TARGET_SCENE, TILE_LAYER_PATH, TILE_CELL, false), "\t"))
		_:
			push_error("[PVGamesObjectStamperRunner] Unsupported mode: %s" % MODE)

# Examples:
# 1. Dry-run list all wall objects: MODE = "dry_run_list", FILTER = "wall"
# 2. Dry-run stamp one Central Security barrier: MODE = "dry_run_stamp", OBJECT_ID = an indexed barrier id.
# 3. Stamp into OccludableObjects: MODE = "stamp_object", TARGET_CONTAINER = "OccludableObjects".
# 4. Scale one object: MODE = "set_object_transform", TARGET_SCALE = Vector2(0.75, 0.75).
# 5. Rotate one object: MODE = "set_object_transform", TARGET_ROTATION_DEGREES = 15.0.
# 6. Duplicate one object: MODE = "duplicate_object".
# 7. Delete one object: MODE = "delete_object".
# 8. Convert a TileMap cell: run "convert_tile_cell_to_object_dry_run" first.
