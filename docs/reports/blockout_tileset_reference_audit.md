# Blockout TileSet Reference Audit

Date: 2026-05-05  
Scope: placeholder isometric blockout assets used by current editor-authorable iso mission scenes.

## Pre-change dirty git state

```text
 M scenes/missions_iso/TacoBellIso_Editable.tscn
 M src/missions/iso/authoring/IsoMissionMarker.gd
?? docs/TACO_BELL_MARKER_LEGEND.md
?? docs/reports/
?? scenes/missions_iso/TacoBellIso_Editable2.tscn
```

## TileSets Found

- `res://assets/tilesets/iso_blockout/IsoBlockoutTileset.tres` (placeholder blockout)
- `res://assets/tilesets/iso_vertical_slice/IsoVerticalSlice.tres` (final-ish vertical slice art, out of scope)
- `res://assets/tilesets/iso_vertical_slice/IsoCyberpunkVerticalSlice.tres` (final-ish vertical slice art, out of scope)

## Blockout Atlas PNGs Found

- `res://assets/tilesets/iso_blockout/iso_blockout_atlas.png`

## Where placeholder blockout is referenced

- `src/levels/IsoMissionBase.gd`
  - `BLOCKOUT_TILESET_PATH`
  - `BLOCKOUT_ATLAS_PATH`
  - `_apply_blockout_tileset()` applies this TileSet to:
    - `GameplayRoot/GameplayFloorLayer`
    - `GameplayRoot/GameplayCollisionLayer`
    - `GameplayRoot/GameplayMarkersLayer`
    - `GameplayRoot/LayoutRoot/FloorLayer`
    - `GameplayRoot/LayoutRoot/WallLayer`
    - `GameplayRoot/LayoutRoot/CoverLayer`
    - `GameplayRoot/LayoutRoot/CollisionBarrierLayer`
    - `GameplayRoot/LayoutRoot/MarkerTileLayer`
    - `GameplayRoot/LayoutRoot/DebugLabelLayer`
    - `ArtRoot/GroundArtLayer`
    - `ArtRoot/WallArtLayer`
    - `ArtRoot/PropArtLayer`
    - `ArtRoot/DecorBelowLayer`
    - `ArtRoot/DecorAboveLayer`
    - `ArtRoot/LightingLayer`
    - `ArtRoot/LightingArtLayer`

## Scene usage audit (current editor-authorable iso missions)

- `scenes/missions_iso/TacoBellIso_Editable.tscn`
  - has embedded `TileSet` subresource (`TileSet_fdg6l`) used by:
    - `FloorLayer`
    - `WallLayer`
    - `CoverLayer`
    - `CollisionBarrierLayer`
    - `MarkerTileLayer`
    - `DebugLabelLayer`
  - also has `GameplayFloorLayer` and other runtime layers that are overridden by `IsoMissionBase`.
- `scenes/missions_iso/TacoBellIso_Editable_Test.tscn`
  - same embedded TileSet pattern and same layer usage.
- `scenes/missions_iso/TacoBellIso_Editable2.tscn`
  - same embedded TileSet pattern and same layer usage.
- `scenes/missions_iso/TacoBellIsoBlockout.tscn`
  - IsoMissionBase scene; no embedded local TileSet blockout subresource.
- `scenes/missions_iso/TacoBellIsoHandEditTest.tscn`
  - IsoMissionBase scene; no embedded local TileSet blockout subresource.
- `scenes/templates/IsoMissionTemplate.tscn`
  - IsoMissionBase template; no embedded local TileSet blockout subresource.

## Scenes with TileSet subresources inspected but not blockout target

- `scenes/hideout/hideout.tscn`
- `scenes/CityHub.tscn`
- `scenes/missions/TestMissionRoom.tscn`
- `scenes/heists/heist_tutorial.tscn`

These contain TileSet subresources but are not using the placeholder iso blockout atlas contract from `IsoMissionBase`.

## Floor/Wall identification method

- Tile coordinates from blockout contract in `IsoMissionBase.gd`:
  - floor tile: `Vector2i(0, 0)`
  - wall tile: `Vector2i(1, 0)`
  - cover tile: `Vector2i(2, 0)` (not recolored)
- Atlas region size from `IsoBlockoutTileset.tres`:
  - `texture_region_size = Vector2i(64, 64)`
- Therefore target regions are:
  - floor region: `(0..63, 0..63)`
  - wall region: `(64..127, 0..63)`

## Is FLOOR/WALL text baked into atlas?

- Yes for the placeholder blockout atlas workflow. The text is present in the tile art itself and is removed by flattening non-transparent pixels in the targeted floor/wall cells.
