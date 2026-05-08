# PVGames Catalog Paintable TileSets - How To Use

## What Was Created

This pass used `pvgames_full_asset_catalog.json` and `pvgames_full_asset_catalog.csv` to derive paint candidates automatically. You did not need to paste 6,478 assets or a 1,000+ candidate list.

Created TileSets:

- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogGroundRoadPaint.tres`
- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogWallPaint.tres`
- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogLargeStructurePaint.tres`
- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogPropSignPaint.tres`
- `res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogReviewOnlyPaint.tres`, if review tiles exist

Open `res://scenes/hideout/tools/PVGamesCatalogPaintableTileSetTest.tscn` to inspect and test the palettes safely.

## Tile Quality Classes

- `READY_TO_PAINT`: visually coherent and useful now.
- `MODULAR_PART_OK`: partial but useful as a wall, corner, post, edge, road, floor, rail, decal, door, or connector.
- `REVIEW_MANUALLY`: could be useful but needs human inspection; checked with extra review passes and moved to review-only when present.
- `REJECT_JUNK`: blank, broken, too transparent, too huge, bad source, or unusable. Excluded from production palettes.

Some partial tiles are legitimate because walls, roads, rails, platforms, and corners are modular. Partial crops are junk only when they do not make sense as a reusable map component.

## Verification

Open the verification sheets in `res://docs/reports/pvgames_catalog_paintable_verification/`. They show the actual tile preview, tile ID, source filename, quality class, palette, and warnings.

## Painting

1. Open `PVGamesCatalogPaintableTileSetTest.tscn`.
2. Select `GroundRoadTileMapLayer`.
3. Use the TileMap panel to choose a tile and paint a test tile.
4. Select `WallTileMapLayer` and paint a wall tile.
5. Check verification sheets if a tile is unclear.
6. If HideoutHub layers are present, open `HideoutHub.tscn`, select `ArtRoot/World/EditorGuideLayer`, press `F`, then select a `PVGamesCatalog*PaintLayer`.
7. Paint small tests only; erase with the TileMap eraser if wrong.

Collision is disabled. Do not add collision, navigation, or gameplay metadata to PVGames TileSets.

Use `Sprite2D` or `PVGamesArtStamper.gd` for assets listed in `pvgames_catalog_assets_better_as_sprites_or_stamps.md`, especially irregular props needing precise placement, scaling, rotation, z-index, or individual editing.

Contact sheets under `res://docs/reports/pvgames_palettes/` are browsing references only and must not be used as textures.
