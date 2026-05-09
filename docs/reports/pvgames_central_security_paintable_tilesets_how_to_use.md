# Central Security Paintable TileSets How To Use

This pass created verified, visual-only paint palettes for PVGames CyberCity Central Security assets.

## Source Assets

`res://assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles`

Raw PNGs are local-only purchased assets. The generated TileSets reference those source PNGs directly.

## TileSet Resources

- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityGroundRoadPaint.tres`
- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityWallPaint.tres`
- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityLargeStructurePaint.tres`
- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityPropSignPaint.tres`
- `res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityReviewOnlyPaint.tres`

## Verification Classes

- `READY_TO_PAINT`: coherent and useful for map dressing.
- `MODULAR_PART_OK`: useful partial like a wall segment, post, connector, barrier, floor panel, or tech module.
- `REVIEW_MANUALLY`: potentially useful but ambiguous, oversized, or context-dependent.
- `REJECT_JUNK`: excluded from production palettes.

## First Use Steps

A. Open `res://scenes/hideout/tools/PVGamesCentralSecurityPaintableTileSetTest.tscn`.

B. Select `CentralSecurityGroundRoadTileMapLayer`.

C. Paint one tile.

D. Select `CentralSecurityWallTileMapLayer`.

E. Paint one tile.

F. Open `res://scenes/hideout/HideoutHub.tscn`.

G. Select `ArtRoot/World/EditorGuideLayer` and press F.

H. Select `PVGamesCentralSecurityGroundRoadPaintLayer`.

I. Paint one floor/security panel tile.

J. Select `PVGamesCentralSecurityOccludableWallPaintLayer`.

K. Paint one wall/barrier tile.

L. Run HideoutHub.

M. Confirm player movement, station interactions, MissionBoard, and Taco Bell return still work.

## HideoutHub Layer Guide

Paint behind-player assets on:

- `ArtRoot/World/PVG_CentralSecurityPaintLayers/PVGamesCentralSecurityGroundRoadPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityPaintLayers/PVGamesCentralSecurityWallBackdropPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityPaintLayers/PVGamesCentralSecurityLargeStructureBackdropPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityPaintLayers/PVGamesCentralSecurityPropSignBackdropPaintLayer`

Paint above-player occludable assets on:

- `ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludableWallPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludablePropPaintLayer`
- `ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityOccludableLargeStructurePaintLayer`

Paint always-front overhead/foreground details on:

- `ArtRoot/World/PVG_CentralSecurityDepthPaintLayers/PVGamesCentralSecurityForegroundOverlayPaintLayer`

This follows the 0M-B5 z-index approximation. True shared Y-sort is not implemented here.

## Collision

No collision, navigation, gameplay metadata, or occlusion polygons were added. These palettes are visual-only.

## Removing Painted Tiles

Use Godot's TileMap erase tool on the selected `TileMapLayer`. Be sure you are editing the intended Central Security layer, not a gameplay node.

## Combining With Core PVGames Palettes

Use the Central Security palettes for security rooms, barriers, checkpoint tech, terminals, cameras, and hardened architectural pieces. Use the existing Core PVGames palettes for broader neon city/floor/wall dressing.

## When To Use Sprite2D/Stamper Instead

Use Sprite2D or `PVGamesArtStamper` for very large, irregular, animated-looking, or highly positional props that need individual scale, rotation, or z-index control.

## Reporting Bad Tiles

Use the verification JSON and contact sheets to identify `asset_id`, source filename, palette, and quality class, then report the exact tile for future tuning.
