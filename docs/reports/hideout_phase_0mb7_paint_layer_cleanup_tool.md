# 0M-B7 PVGames Paint Layer Cleanup Tool

Status: PASS

- HideoutHub modified: no
- Taco Bell scenes modified: no
- Gameplay scripts modified: no
- Cells actually cleared in this pass: 0
- PVGames paint layers found: 19
- Total used PVGames cells found: 4
- Cleanup tool: `res://src/tools/editor/PVGamesPaintLayerCleanupTool.gd`
- Runner: `res://src/tools/editor/PVGamesPaintLayerCleanupRunner.gd`
- How-to guide: `res://docs/reports/pvgames_paint_layer_cleanup_how_to.md`

## Dry-Run Results

- `core`: 9 layers, 4 cells would be cleared, changed=false
- `central_security`: 8 layers, 0 cells would be cleared, changed=false
- `ground`: 6 layers, 1 cells would be cleared, changed=false
- `wall`: 8 layers, 3 cells would be cleared, changed=false
- `occludable`: 5 layers, 0 cells would be cleared, changed=false
- `foreground`: 2 layers, 0 cells would be cleared, changed=false
- `review_only`: 0 layers, 0 cells would be cleared, changed=false
- `all_pvgames`: 19 layers, 4 cells would be cleared, changed=false

Backup-before-clear behavior is implemented in the cleanup tool. No clear operation was run in this pass.
