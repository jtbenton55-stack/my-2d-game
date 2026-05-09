# PVGames Paintable Atlas Candidates

Status: PASS

Only actual source PNGs under `res://assets/tilesets/cyber_city_core_tilesets/` were used. Contact sheets under `res://docs/reports/pvgames_palettes/` were explicitly excluded.

- Floor TileSet: `res://assets/tilesets/pvgames_paintable/PVGamesFloorPaintVisualTileset.tres`
- Wall TileSet: `res://assets/tilesets/pvgames_paintable/PVGamesWallPaintVisualTileset.tres`
- Collision: disabled by using visual-only TileSets and `collision_enabled = false` on paint layers.

| Asset ID | Source | Decision | Reason |
| --- | --- | --- | --- |
| `pvg_floor_diamond_floormat1_2` | `res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_2.png` | created_visual_tileset_source | Measured diamond-ish floor mat; safe as a single visual-only paint tile. |
| `pvg_floor_diamond_floormat1_4` | `res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_4.png` | created_visual_tileset_source | Measured diamond-ish floor mat variant; visual-only floor painting candidate. |
| `pvg_floor_patch_floormat1_7` | `res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_7.png` | created_visual_tileset_source | Small floor patch useful for guide/test paint marks; not gameplay collision. |
| `pvg_wall_back_citywalls1_2` | `res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/CityWalls1_2.png` | created_visual_tileset_source | Actual PVGames wall source used as a one-piece visual paint tile. |
| `pvg_wall_back_citywalls1_4` | `res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/CityWalls1_4.png` | created_visual_tileset_source | Actual PVGames wall source used as a one-piece visual paint tile. |
| `pvg_door_window_door10_4` | `res://assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/Door10_4.png` | created_visual_tileset_source | Door/window visual tile for wall-layer painting near entry/backdrop. |
| `all_docs_reports_pvgames_palettes` | `res://docs/reports/pvgames_palettes/*.png` | excluded | Contact sheets are browse-only menu images and must never be TileSet or Sprite2D production sources. |