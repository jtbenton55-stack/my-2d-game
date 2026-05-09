# 0M-B5 Runtime Graybox Cleanup / Depth Sorting

Status: PARTIAL

Partial because the cleanup and static validation were implemented, but an in-editor runtime playtest still needs to be performed. Godot CLI was not available on `PATH` in this shell.

## Backup

`res://scenes/hideout/HideoutHub.phase0mb5_backup.20260508_193821.tscn`

## Baseline Paths

- Hideout root: `HideoutHubRoot`
- Gameplay root: `HideoutHubRoot/GameplayRoot`
- Art root: `HideoutHubRoot/ArtRoot`
- Art world: `HideoutHubRoot/ArtRoot/World`
- Editor guide: `HideoutHubRoot/ArtRoot/World/EditorGuideLayer`
- 0M-B4 paint layers: `HideoutHubRoot/ArtRoot/World/PVG_CatalogPaintLayers`
- Player: `HideoutHubRoot/GameplayRoot/Characters/Player`
- Player visual child: `HideoutHubRoot/GameplayRoot/Characters/Player/AnimatedSprite2D`
- Station proxies/interactables: runtime children of `HideoutHubRoot/GameplayRoot/Stations`
- MissionBoard: runtime station node `GameplayRoot/Stations/MissionBoard`
- StoreTerminal: runtime station node `GameplayRoot/Stations/StoreTerminal`
- BentleyCareStation: runtime station node `GameplayRoot/Stations/BentleyCareStation`
- OpenDecorZone: runtime station node `GameplayRoot/Stations/OpenDecorZone`
- Runtime visual containers: old station grayboxes were generated under `ArtRoot/World/PropLayer` as `Visual_*`

## Runtime Graybox Source

The visible gray/green rectangles and labels came from `HideoutManager.gd`.

- `_build_world_layers()` created the floor polygon, circulation line, `GREENHOUSE ALCOVE`, `THE BIG CASE`, and other placeholder labels/rectangles.
- `_make_station_visual()` created `Visual_*` station placeholder boxes and labels under `ArtRoot/World/PropLayer`.
- Station `InteractionProxy` labels were added as children of runtime station nodes.

## What Changed

- Added `show_runtime_graybox_debug := false` and `show_station_proxy_debug_labels := false` to `HideoutManager.gd`.
- Gated runtime graybox creation behind `show_runtime_graybox_debug`.
- Gated station proxy debug label visibility behind `show_station_proxy_debug_labels`.
- Preserved station nodes, interaction logic, collision, and UI prompts.
- Kept `EditorGuideLayer` in the scene; its existing script hides it during play.
- Disabled the old `HideoutPVGamesVisualHelper` by default and moved the scene instance into `ArtRoot/World/QuarantinedOldPVGamesVisuals_0MB5`.

## Old PVGames Visuals

Found and quarantined:

- `ArtRoot/World/HideoutPVGamesVisualHelper` -> `ArtRoot/World/QuarantinedOldPVGamesVisuals_0MB5/HideoutPVGamesVisualHelper`

The helper remains in the project but defaults to disabled, so it no longer generates old Cursor-placed PVGames dressing in normal play.

## Depth Sorting Choice

Chosen solution: occludable foreground approximation.

True shared Y-sort was not implemented because the player is a `CharacterBody2D` under `GameplayRoot/Characters`, and moving it would risk camera, combat, collision, station interaction, and manager paths such as `../../Characters/Player`.

The previous issue happened because `ArtRoot` had `z_index = -250`, while the player was under `GameplayRoot/Characters/Player` at z-index `30`. That made the player draw over most world art.

## New Layer Model

- Behind floor/ground: `z_index = -300`
- Behind wall backdrop: `z_index = -240`
- Existing 0M-B4 catalog paint layers: preserved and still behind the player
- Player: unchanged at `GameplayRoot/Characters/Player`, `z_index = 30`, `y_sort_enabled = false`
- Occludable wall paint: `z_index = 80`
- Occludable prop paint: `z_index = 90`
- Foreground overlay paint: `z_index = 160`
- UI: `CanvasLayer`

## New Paint Layers

Added under `ArtRoot/World/PVG_DepthPaintLayers`:

- `PVGamesBehindGroundPaintLayer`
- `PVGamesBehindWallBackdropPaintLayer`
- `PVGamesOccludableWallPaintLayer`
- `PVGamesOccludablePropPaintLayer`
- `PVGamesForegroundOverlayPaintLayer`

All are visual-only `TileMapLayer` nodes with `collision_enabled = false`.

## Y Sort Origin Audit

See `res://docs/reports/hideout_phase_0mb5_y_sort_origin_audit.md`.

Player base/feet sorting was considered. Since true Y-sort was skipped, per-tile Y Sort Origin tuning is documented for a later pass.

## Safety

- Taco Bell scenes modified: no
- GameplayRoot moved: no
- Player moved: no
- Station proxies moved: no
- Collision added to PVGames art: no
- 0M-B4 paint layers preserved: yes
- Gameplay scripts modified: yes, limited to `HideoutManager.gd` and the visual helper default flag to hide runtime debug visuals and disable old visual generation.

## Validation

- Static validation passed for required layer names, runtime debug flags, helper quarantine, explicit no-collision depth layers, and visual-only depth test scene.
- Godot CLI validator run was not possible because `godot`, `godot4`, and `godot.console` were not found on `PATH`.

## Manual Test Checklist

1. Open `HideoutHub.tscn`.
2. Confirm old unwanted Cursor PVGames visuals are gone/hidden/quarantined.
3. Confirm `EditorGuideLayer` still exists in editor.
4. Run HideoutHub.
5. Confirm the large gray/green translucent boxes are not visible during play.
6. Confirm labels like GREENHOUSE ALCOVE, MISSION BOARD, THE BIG CASE, HEAT SCANNER are not visible during play unless intentionally in debug mode.
7. Confirm E prompts still appear.
8. Confirm all station interactions still work.
9. Confirm 0M-B4 catalog paint layers still exist.
10. Confirm no PVGames art is under `GameplayRoot`.
11. Paint one floor tile on the ground/floor paint layer.
12. Confirm player walks over floor tile.
13. Paint one wall/prop tile on the occludable wall/prop layer.
14. Walk below/in front of it and confirm player appears in front if appropriate.
15. Walk above/behind it and confirm player appears behind or covered if appropriate.
16. Confirm no collision was added.
17. Confirm MissionBoard launches Taco Bell.
18. Confirm pause exit returns to HideoutHub.
19. Confirm Taco Bell scenes were not modified.

## Recommended Next Step

Perform the manual runtime checklist in Godot. If the occludable approximation feels too coarse, the next pass should prototype a player visual proxy or a shared Y-sort world without moving the gameplay body.
