@tool
extends EditorScript
class_name PVGamesPaintLayerCleanupRunner

const CleanupTool = preload("res://src/tools/editor/PVGamesPaintLayerCleanupTool.gd")

# Default is intentionally non-destructive.
const MODE := "dry_run_inventory"

# Allowed modes:
# - dry_run_inventory
# - dry_run_layer
# - dry_run_group
# - clear_layer
# - clear_group
#
# Before using clear_layer or clear_group, run the corresponding dry-run mode
# and review the printed layer/cell counts. Clear modes create backups by default.

const TARGET_LAYER_PATH := "ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludableWallPaintLayer"
const TARGET_GROUP := "central_security"
const MAKE_BACKUP := true


func _run() -> void:
	var tool := CleanupTool.new()
	match MODE:
		"dry_run_inventory":
			tool.print_inventory()
		"dry_run_layer":
			print(JSON.stringify(tool.dry_run_clear_layer(TARGET_LAYER_PATH), "\t"))
		"dry_run_group":
			print(JSON.stringify(tool.dry_run_clear_group(TARGET_GROUP), "\t"))
		"clear_layer":
			print(JSON.stringify(tool.clear_layer(TARGET_LAYER_PATH, MAKE_BACKUP), "\t"))
		"clear_group":
			print(JSON.stringify(tool.clear_group(TARGET_GROUP, MAKE_BACKUP), "\t"))
		_:
			push_error("[PVGamesPaintLayerCleanupRunner] Unsupported MODE: %s" % MODE)
