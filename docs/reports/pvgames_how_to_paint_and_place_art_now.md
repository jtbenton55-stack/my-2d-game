# How To Paint And Place PVGames Art Now

## A. What Files Are What

- Contact sheets are visual menus only: `res://docs/reports/pvgames_palettes/*.png`.
- Actual production PNGs live under `res://assets/tilesets/cyber_city_core_tilesets/`.
- TileSet/TileMapLayer is for repeatable floor/wall painting.
- Sprite2D/stamper is for irregular props, furniture, signs, shelves, displays, terminals, plants, and clutter.

## B. Viewing Categorized Assets

Open `pvgames_birthday_build_curated_palette.png` for the short best-of board. Use category contact sheets for broader browsing, the CSV for search/filtering, and `res://scenes/hideout/tools/PVGamesAssetPaletteBrowser.tscn` for a lightweight Godot scene preview.

## C. Finding Real Source PNGs

Open the curated palette markdown or JSON, find the `asset_id`, then copy the `path` that starts with `res://assets/tilesets/cyber_city_core_tilesets/`. Do not use any `res://docs/reports/pvgames_palettes/` path as a Sprite2D or TileSet texture.

## D. Seeing The Hideout Layout

Open `HideoutHub.tscn`, select `ArtRoot/World/EditorGuideLayer`, and press `F`. Use the cyan floor footprint, orange wall edge hints, magenta station boxes, and labels to orient yourself. Hide/show the whole guide with the eye icon on `EditorGuideLayer`; it hides automatically when the game runs.

## E. Painting Floors/Walls

Select `ArtRoot/World/FloorLayer/PVGamesFloorPaintLayer` or `ArtRoot/World/WallLayer/PVGamesWallPaintLayer`. Open the TileMap panel, choose a tile from the assigned TileSet, and paint. Collision is disabled. Use the guide for alignment and save the scene when you like the result.

## F. Placing Individual Props

Add a `Sprite2D` under the correct `ArtRoot/World` layer, assign an actual source PNG, position it visually, set scale/z-index, and do not add collision. Use `PVGamesArtStamper.gd` for manifest-based bulk placement into a duplicate/test scene.

## G. Recommended Parent Layers

- Floors/rugs/ground: `FloorLayer`
- Walls/windows: `WallLayer`
- Furniture/station props: `PropLayer`
- Clutter/decor: `DecorationLayer`
- Display shelves/frames: `CollectibleLayer`
- Tall foreground objects: `ForegroundLayer`
- Glow/sign/light art: `LightingLayer`

## H. Recommended Z-Index Ranges

- FloorLayer: `-300`
- WallLayer: `-220`
- PropLayer: `-120` to `-60`
- DecorationLayer: `-90` to `-40`
- CollectibleLayer: `-70` to `-30`
- ForegroundLayer: `120+`
- LightingLayer: `180+`
- UI: CanvasLayer above all

## I. Y-Sort Guidance

Do not use Y-sort for floors. Usually do not use Y-sort for background walls. Maybe use Y-sort for props/characters only when needed. Set z-index first, then use y-sort within a matching z-index group.

## J. Removing Unwanted Art

Search the scene tree for `PVG`, `PVGames`, or the layer you edited. Hide first with the eye icon, then delete unwanted Sprite2D nodes or art-only containers. Do not delete `GameplayRoot`, station proxies, collision nodes, MissionBoard, StoreTerminal, or Decorating Mode nodes.

## K. Common Mistakes

- Using a contact sheet as a texture.
- Placing walls in `FloorLayer`.
- Placing environment art under `GameplayRoot`.
- Adding collision to PVGames art.
- Using an atlas as Sprite2D without Region.
- Using TileMap for irregular props.
- Setting z-index so high that art covers player/UI.
- Deleting gameplay nodes while cleaning up visuals.
