# PVGames Art Library Quickstart

## Where Things Are

- Full catalog JSON: `res://docs/reports/pvgames_full_asset_catalog.json`
- Full catalog CSV: `res://docs/reports/pvgames_full_asset_catalog.csv`
- Category contact sheets: `res://docs/reports/pvgames_palettes/`
- Birthday-build curated palette: `res://docs/reports/pvgames_birthday_build_curated_palette.md`
- Curated palette JSON: `res://docs/reports/pvgames_birthday_build_curated_palette.json`
- Curated contact sheet: `res://docs/reports/pvgames_palettes/pvgames_birthday_build_curated_palette.png`
- Manifest stamper: `res://src/tools/editor/PVGamesArtStamper.gd`
- Sample manifest: `res://docs/reports/pvgames_sample_art_placement_manifest.json`

## Manual Workflow

1. Open the curated palette first.
2. Pick assets by section, category, and recommended scene.
3. Add them as visual-only `Sprite2D` nodes under `ArtRoot/World`.
4. Use the recommended layer: `FloorLayer`, `WallLayer`, `PropLayer`, `DecorationLayer`, `CollectibleLayer`, `ForegroundLayer`, or `LightingLayer`.
5. Keep collision disabled. Do not add `StaticBody2D`, `Area2D`, or `CollisionShape2D` to PVGames art.
6. Preserve GameplayRoot as gameplay truth.

## Suggested Z-Index Ranges

- FloorLayer: about `-300`
- WallLayer: about `-220`
- PropLayer: `-120` to `-60`
- DecorationLayer: `-90` to `-40`
- CollectibleLayer: `-70` to `-30`
- ForegroundLayer: `120+`
- LightingLayer: `180+`

## Cursor-Assisted Workflow

Ask Cursor to use the curated palette or full catalog, then place visual-only art under the correct ArtRoot layer. Explicitly say not to touch GameplayRoot, collision, station proxies, objectives, guards, cameras, store systems, MissionBoard, SceneManager, or Player.gd.

## Example Prompts

Hideout greenhouse:

> Use the PVGames birthday-build curated palette to improve the HideoutHub greenhouse. Use GREENHOUSE_PLANT, DOOR_WINDOW, LIGHTING, FLOOR_PATCH, and WALL_BACK assets. Place art only under ArtRoot/World. Do not modify GameplayRoot, station proxies, collision, MissionBoard, store, or Decorating Mode.

Hideout store terminal:

> Use the PVGames catalog to improve the HideoutHub StoreTerminal area. Use STORE_TECH, NEON_SIGN, COMPUTER_ARCADE, LIGHTING, and CRATE_STORAGE. Keep art visual-only. Do not move the StoreTerminal proxy.

Taco Bell bag room:

> Use the PVGames curated palette to dress the Taco Bell bag room. Use CRATE_STORAGE, STORE_TECH, WALL_BACK, FLOOR_PATCH, and CLUTTER_SMALL. Preserve delivery bag, Louis exit, collision, objectives, guards, cameras, and all gameplay markers.

Taco Bell dining area:

> Use PVGames FURNITURE, STORE_TECH, NEON_SIGN, FLOOR_PATCH, WALL_BACK, and CLUTTER_SMALL assets to dress the Taco Bell dining area. Place visuals under ArtRoot only. Do not alter GameplayRoot or mission logic.

Future alley mission:

> Use ROAD_STREET, WALL_SIDE, NEON_SIGN, CRATE_STORAGE, FOREGROUND_TALL, and LIGHTING from the PVGames catalog to create a neon-noir alley dressing pass. Use visual-only Sprite2D placement and preserve all gameplay collision.

## What Not To Do

- Do not add PVGames collision.
- Do not move GameplayRoot proxies.
- Do not place art under GameplayRoot.
- Do not use the full pack as one TileMap.
- Do not put thousands of sprites into a production scene.
- Do not modify Taco Bell gameplay while dressing art.
- Do not modify Hideout gameplay while dressing art.
