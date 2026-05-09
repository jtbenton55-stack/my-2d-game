# PVGames Paint Layer Cleanup How-To

## Why Normal Erasing May Fail

Many PVGames paint assets are large rendered sprites stored as one TileMap tile. The occupied TileMap cell is at the tile anchor/grid coordinate, but the visible artwork may extend upward, sideways, or far away from that anchor. Clicking the visible art may not click the actual occupied cell, so Godot's normal eraser, right-click erase, or undo can feel unreliable.

The reliable delete path is to operate on the `TileMapLayer` data directly with methods such as `get_used_cells()`, `erase_cell(coords)`, and `clear()`.

## Identify Which Layer Contains A Tile

1. Hide/show likely paint layers with the editor eye icon.
2. Read `res://docs/reports/hideout_phase_0mb7_pvgames_paint_layer_inventory.md`.
3. Check the layer's used cell count.
4. Select suspected `TileMapLayer` nodes under `ArtRoot/World`, never under `GameplayRoot`.

## Safe Cleanup Examples

Example A, clear one exact layer after dry-run:

`layer_path = "ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludableWallPaintLayer"`

Example B, dry-run all Central Security:

`group_name = "central_security"`

Example C, clear all PVGames paint layers:

`group_name = "all_pvgames"`

Actual clearing should only happen after reviewing dry-run results.

## Using The Runner

Open `res://src/tools/editor/PVGamesPaintLayerCleanupRunner.gd`. The checked-in default is:

`const MODE := "dry_run_inventory"`

Allowed modes are documented at the top of that file. Change to `dry_run_layer` or `dry_run_group` first. Only use `clear_layer` or `clear_group` after reviewing the dry-run.

## Backup Behavior

Future destructive clear calls create backups like:

`res://scenes/hideout/HideoutHub.phase0mb7_cleanup_backup.REASON.TIMESTAMP.tscn`

To restore, close Godot or make sure the scene is not open, then replace `HideoutHub.tscn` with the backup scene.

## What Not To Delete

Do not delete `GameplayRoot`, `ArtRoot`, station proxies, collision, player, UI, E prompts, `.tres` TileSet resources, or source PNG files. The cleanup tool is designed to clear only painted cell data on safe PVGames `TileMapLayer` nodes.

## Repaint After Clearing

Select the appropriate Core or Central Security paint layer under `ArtRoot/World`, then repaint from the TileMap palette. Use behind-player layers for floor/backdrop art and occludable layers for walls/props that should draw above the player.

## If The Tool Finds Zero Layers

Confirm you are using `HideoutHub.tscn`, the PVGames paint layers still live under `ArtRoot/World`, and the TileSet resource paths point to `pvgames_catalog_paintable` or `pvgames_central_security_paintable`.

## If A Layer Is Unsafe

Do not force-clear it. It may not use a known PVGames paint TileSet or may be outside `ArtRoot/World`. Inspect the node path and TileSet path first.
