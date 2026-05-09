# PVGames Asset Library And Painting Tool

Status: PASS

- Asset root scanned: `res://assets/tilesets/cyber_city_core_tilesets`
- Total PNGs indexed: 6478
- Catalog JSON: `res://docs/reports/pvgames_full_asset_catalog.json`
- Catalog CSV: `res://docs/reports/pvgames_full_asset_catalog.csv`
- Contact sheets folder: `res://docs/reports/pvgames_palettes/`
- Contact sheets created: 65
- Birthday-build curated palette: `res://docs/reports/pvgames_birthday_build_curated_palette.md`
- Birthday-build curated asset count: 145
- Curated contact sheet: `res://docs/reports/pvgames_palettes/pvgames_birthday_build_curated_palette.png`
- Palette browser scene: `res://scenes/hideout/tools/PVGamesAssetPaletteBrowser.tscn`
- Stamping tool: `res://src/tools/editor/PVGamesArtStamper.gd`
- Sample manifest: `res://docs/reports/pvgames_sample_art_placement_manifest.json`
- Character support plan: `res://docs/reports/character_asset_support_plan.md`
- Quickstart: `res://docs/reports/pvgames_art_library_quickstart.md`

## Existing Character-Adjacent Assets Found

- `res://scenes/characters/guard.tscn`
- `res://assets/sprites/guard_sprite_frames.tres`
- `res://src/enemies/Guard.gd`
- Monogon character import sidecars under `res://assets/tilesets/monogon_isometric_tilesets/`

## Category Counts

- FLOOR_DIAMOND: 2
- FLOOR_PATCH: 106
- ROAD_STREET: 298
- WALL_BACK: 57
- WALL_SIDE: 132
- WALL_CORNER: 56
- DOOR_WINDOW: 145
- BUILDING_LARGE: 297
- FURNITURE: 315
- STORE_TECH: 40
- COMPUTER_ARCADE: 434
- NEON_SIGN: 485
- LIGHTING: 64
- GREENHOUSE_PLANT: 40
- CRATE_STORAGE: 363
- CLUTTER_SMALL: 47
- DISPLAY_SHELF: 40
- CHARACTER_ADJACENT: 64
- FOREGROUND_TALL: 34
- FX_DECAL: 325
- TILESET_ATLAS: 728
- UNKNOWN_REVIEW: 2339
- AVOID_FOR_NOW: 67

## Recommended Manual Workflow

Use curated palette first; place PVGames art as visual-only Sprite2D under ArtRoot/World. Use full catalog/contact sheets for deeper searches.

## Recommended Cursor Workflow

Ask Cursor to use curated IDs from the birthday-build palette or category IDs from the full catalog. Always require visual-only placement under ArtRoot/World and forbid GameplayRoot/collision/proxy changes.

## HideoutHub Painting

Use `HIDEOUTHUB_ESSENTIALS`, `GREENHOUSE_Cozy_BENTLEY`, `DISPLAYS_SHELVES_COLLECTIONS`, and `SIGNS_LIGHTS_NEON_MONITORS` first. Place props under ArtRoot/World layers only.

## Taco Bell Painting

Use `TACO_BELL_FAST_FOOD_STORE`, `FLOORS_WALLS_STRUCTURE`, `CRATE_STORAGE`, `STORE_TECH`, `FURNITURE`, and `CLUTTER_SMALL` entries. Preserve all mission gameplay markers, guards, cameras, objectives, and collision.

## Future Character Assets

Buy/use transparent PNG sprite sheets or frame sequences with 4-direction minimum and 8-direction preferred. Avoid side-view platformer sprites and one-direction packs.

## Known Limitations

- Full category contact sheets are broad browsing aids, not art-direction approval for every asset.
- TileMap floor subset is intentionally skipped until manual slicing is requested.
- Palette browser scene is representative and not linked to game runtime.

## Next Recommended Prompt

Use the birthday-build curated palette for small, targeted visual-only polish passes in HideoutHub or Taco Bell after 0M-B manual testing.
