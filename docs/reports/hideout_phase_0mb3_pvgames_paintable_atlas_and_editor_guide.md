# Hideout Phase 0M-B3 PVGames Paintable Atlas And Editor Guide

Status: PASS

- Backup path: `res://scenes/hideout/HideoutHub.phase0mb3_backup.20260508_093641.tscn`
- HideoutHub modified: yes, visual-only editor guide and empty paint layers only.
- Taco Bell scenes modified: no.
- Gameplay scripts modified: no.
- Contact-sheet Sprite2D nodes found: 0
- Contact-sheet handling: none needed; no saved visible contact-sheet Sprite2D reference found
- Contact sheets are browse-only: `res://docs/reports/pvgames_palettes/*.png`.
- Real source art: `res://assets/tilesets/cyber_city_core_tilesets/**/*.png`.

## Why The Graybox Was Not Visible In Editor

`HideoutHub.tscn` saved the empty containers (`FloorLayer`, `WallLayer`, `PropLayer`, etc.), but `HideoutManager.gd` builds the irregular floor polygon, boundary collision, walkable area, station interactables, and graybox station visuals at runtime in `_build_world_layers()`, `_build_navigation_collision()`, and `_build_stations()`. The 0M-B PVGames visual helper is also runtime/deferred visual dressing. So the editor had no saved floor footprint/station guide to frame, leaving mostly colored markers and the player token visible.

Select `ArtRoot/World/EditorGuideLayer` and press `F` to focus the actual playable hideout area now.

## Editor Guide

- Path: `ArtRoot/World/EditorGuideLayer`
- Visual-only: yes.
- Collision: none.
- Hide behavior: visible in editor, hidden on play by `HideoutEditorGuideLayer.gd`.
- Components: floor footprint, boundary outline, wall paint hints, station guide boxes, station labels, zone hints.

## Paintable TileMap Workflow

- Floor TileSet: `res://assets/tilesets/pvgames_paintable/PVGamesFloorPaintVisualTileset.tres`
- Wall TileSet: `res://assets/tilesets/pvgames_paintable/PVGamesWallPaintVisualTileset.tres`
- Floor paint layer: `ArtRoot/World/FloorLayer/PVGamesFloorPaintLayer`
- Wall paint layer: `ArtRoot/World/WallLayer/PVGamesWallPaintLayer`
- Collision disabled: yes.
- Sources are actual PVGames PNGs, not contact sheets.

## Sprite2D/Stamper Workflow

Use Sprite2D or `PVGamesArtStamper.gd` for irregular props, furniture, signs, shelves, displays, terminals, clutter, and plants. Do not force those into TileMapLayer.

## Direct Answers

1. You do not need to manually add every individual sprite/tile; use curated palette, TileMap paint layers for safe repeatables, and stamper/Sprite2D for props.
2. Yes, this can be automated with `PVGamesArtStamper.gd`, but it should write duplicate/test scenes first.
3. Yes, Cursor can find all real source art from the catalog automatically.
4. One Sprite2D uses one texture at a time; for atlases use Region or TileSet.
5. Each separate placed prop normally needs its own Sprite2D node unless stamped/generated into a container.
6. Use TileMapLayer for repeatable floor/wall tiles that slice cleanly.
7. Use atlases when you want repeated tile painting or Region-cropped sheet pieces.
8. The contact sheet appeared huge because it is one giant browse image assigned as one Sprite2D texture.
9. Atlases were not recommended for everything because most PVGames files are irregular props/sheets, not one consistent global grid.
10. Contact sheets are `res://docs/reports/pvgames_palettes/*.png`.
11. Actual source art is `res://assets/tilesets/cyber_city_core_tilesets/**/*.png`.
12. Paint walls/floors with `PVGamesFloorPaintLayer` and `PVGamesWallPaintLayer`.
13. Place individual props as Sprite2D under the correct `ArtRoot/World` layer or use the stamper.
14. See the hideout layout with `ArtRoot/World/EditorGuideLayer`.
15. Remove unwanted assets by hiding/deleting art-only `PVG*`/`PVGames*` nodes; do not delete GameplayRoot nodes.
16. Prevent collision by never adding CollisionShape2D/Area2D/StaticBody2D to PVGames art and keeping TileMap collision disabled.
17. Use Y-sort only for props/characters when z-index alone is not enough.
18. Avoid false walk-on-wall/counter visuals by keeping big props near existing edges and out of walkable center.
19. Use z-index ranges from the how-to guide: floor around -300, wall around -220, props -120 to -60, foreground 120+, lighting 180+.
20. Focus the map by selecting `ArtRoot/World/EditorGuideLayer` and pressing `F`.

## Risks / Limitations
- TileSets are intentionally small safe starter palettes, not a conversion of the whole PVGames pack.
- The guide is approximate but based on existing HideoutManager floor/station coordinates.
- Loose contact-sheet image copies in scenes/hideout are reported but not deleted automatically.

## Validator Result

PASS - static validation completed. Godot CLI was not on PATH, so the EditorScript validator was created but not executed in-engine from the shell.

## Manual Test Checklist

Open HideoutHub, confirm the guide and labels are visible, select paint layers to see tiles, paint one test tile, verify no collision is added, hide the guide, run the scene, and verify player movement/stations/MissionBoard/pause return still work.