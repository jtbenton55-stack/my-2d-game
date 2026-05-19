# TILEMAP AND ASSET READINESS AUDIT

Readiness assessment for future visual mission-map painting and reusable authoring.

## Current state summary

## 1) Mission tile/layer model (Taco)

- Active mission uses explicit gameplay + layout + art layer split in `IsoMissionBase`:
  - Gameplay tile layers (`GameplayFloorLayer`, `GameplayCollisionLayer`, `GameplayMarkersLayer`)
  - Layout layers (`FloorLayer`, `WallLayer`, `CoverLayer`, `CollisionBarrierLayer`, `MarkerTileLayer`, `DebugLabelLayer`)
  - Art layers (`GroundArtLayer`, `WallArtLayer`, `PropArtLayer`, `DecorBelowLayer`, `DecorAboveLayer`, `LightingLayer`, `LightingArtLayer`)

Classification:

- `KEEP_ACTIVE` and `FUTURE_USEFUL` (strong baseline for map-painting pipeline).

## 2) Hideout paint/depth model

- Hideout includes multiple paint/depth layer families:
  - `PVG_CatalogPaintLayers`
  - `PVG_DepthPaintLayers`
  - `PVG_CentralSecurityPaintLayers`
  - `PVG_CentralSecurityDepthPaintLayers`

Classification:

- `KEEP_ACTIVE` (live visual stack) with partial `KEEP_BUT_REFACTOR_LATER` for standardization.

## 3) Collision and navigation separation

- Taco: explicit boundary collider root + gameplay collision layers.
- Hideout: navigation/collision roots plus art world separation.

Classification:

- `KEEP_ACTIVE` and `PROTECTED_BASELINE`.

## 4) Y-sort/layering conventions

- Mission/hideout code contains explicit z-index and y-sort controls.
- Layer naming conventions are partially standardized but still mixed across phases and tool-era assets/scripts.

Classification:

- `KEEP_BUT_REFACTOR_LATER`.

## 5) Tileset/asset inventory signals

- Assets contain large tileset corpus (many source packs and paintable tilesets).
- Dedicated tilesets exist for marker authoring and paint workflows.

Classification:

- Active production subset: `KEEP_ACTIVE`.
- Broad corpus not clearly mapped to current playable path: `UNKNOWN_NEEDS_MANUAL_REVIEW`.

## Readiness for future mission painting

Overall readiness: **medium-high** for structural foundation, **medium** for standardization maturity.

Strengths:

- Layer separation already modeled for gameplay/collision/visual concerns.
- Existing paint-layer families can be adapted for reusable map-authoring conventions.
- TileMapLayer usage is pervasive and explicit in mission/hideout runtime.

Gaps:

- Layer taxonomy and naming need normalization across active scenes.
- Legacy/proof/debug layer noise increases accidental break risk during painter pipeline changes.
- Diagnostics include tile/texture warnings in editor/runtime traces that should be resolved before broad migration.

## Recommended later standardization themes (no changes made)

- Define canonical layer contract for all mission maps (required/optional layers, naming, collision flags, z/y-sort rules).
- Separate "shipping gameplay layers" from "editor proof/debug layers" via clear conventions.
- Build a layer-validation gate (read-only validator) before scene acceptance.
- Introduce tile/asset provenance tags (active mission, hideout-only, test-only, legacy).

## Cleanup risk posture for tile/assets

- TileMap/layer cleanup is generally `MEDIUM_RISK_SCENE_CLEANUP`.
- Any rename/move of active layer nodes is `HIGH_RISK_DO_NOT_TOUCH_YET` unless all code string-path references are updated and runtime-tested.
- Core gameplay collision and marker layers are `NEVER_REMOVE_CURRENTLY_PROTECTED`.
