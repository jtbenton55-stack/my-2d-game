# Hideout Existing PVGames Visual Nodes Inventory

Status: PASS

No saved visible `Sprite2D` texture reference to `res://docs/reports/pvgames_palettes/` was found in `HideoutHub.tscn`.

Loose contact-sheet PNG copies found in `scenes/hideout/`:
- `scenes/hideout/pvgames_palette_wall_back.png`
- `scenes/hideout/pvgames_palette_wall_corner.png`
- `scenes/hideout/pvgames_palette_wall_side_001.png`
- `scenes/hideout/pvgames_palette_wall_side_002.png`

These loose files are not production source art. Actual source art remains under `res://assets/tilesets/cyber_city_core_tilesets/`.

## Visual Nodes

### `ArtRoot/World/HideoutPVGamesVisualHelper`
- Parent layer: `ArtRoot/World`
- Texture/source: `runtime helper loads actual source PNGs from res://assets/tilesets/cyber_city_core_tilesets/`
- Uses contact sheet: False
- Z-index: runtime per helper spec
- Visible: True
- Safe to delete: yes, if you want to remove the whole 0M-B visual dressing helper; do not delete gameplay nodes
- Notes: Runtime visual-only helper. It does not create collision.

### `ArtRoot/World/EditorGuideLayer`
- Parent layer: `ArtRoot/World`
- Texture/source: ``
- Uses contact sheet: False
- Z-index: 260
- Visible: editor only; hidden on play
- Safe to delete: yes, editor guide only, but it is useful for art placement
- Notes: Visual-only guide nodes; no collision nodes.

### `ArtRoot/World/FloorLayer/PVGamesFloorPaintLayer`
- Parent layer: `ArtRoot/World/FloorLayer`
- Texture/source: `res://assets/tilesets/pvgames_paintable/PVGamesFloorPaintVisualTileset.tres`
- Uses contact sheet: False
- Z-index: 20
- Visible: True
- Safe to delete: yes, visual-only empty paint layer
- Notes: TileMapLayer collision disabled.

### `ArtRoot/World/WallLayer/PVGamesWallPaintLayer`
- Parent layer: `ArtRoot/World/WallLayer`
- Texture/source: `res://assets/tilesets/pvgames_paintable/PVGamesWallPaintVisualTileset.tres`
- Uses contact sheet: False
- Z-index: 20
- Visible: True
- Safe to delete: yes, visual-only empty paint layer
- Notes: TileMapLayer collision disabled.
