# ISO Editor Tile Palette Guide

This guide explains the editor-facing tile palettes used for isometric mission authoring.

## Resource Paths

- Clean blockout atlas: `res://assets/tilesets/iso_blockout_clean/iso_blockout_atlas_clean.png`
- Clean blockout TileSet: `res://assets/tilesets/iso_blockout_clean/IsoBlockoutTileset_Clean.tres`
- Marker authoring atlas (source image): `res://assets/tilesets/marker_authoring/marker_authoring_atlas.png`
- Marker authoring TileSet: `res://assets/tilesets/marker_authoring/MarkerAuthoringTileset.tres`

## Which Layer To Paint

- Floor painting: `GameplayRoot/LayoutRoot/FloorLayer`
- Wall painting: `GameplayRoot/LayoutRoot/WallLayer`
- Cover painting: `GameplayRoot/LayoutRoot/CoverLayer`
- Collision/barrier painting: `GameplayRoot/LayoutRoot/CollisionBarrierLayer`
- Marker icon painting: `GameplayRoot/LayoutRoot/MarkerTileLayer`

## Confirm Clean Blockout Palette Is Active

1. Open an editable mission scene (for example `res://scenes/missions_iso/TacoBellIso_Editable.tscn`).
2. Select `FloorLayer` and verify the palette shows white/off-white floor tiles (no FLOOR text).
3. Select `WallLayer` and verify the palette shows black/dark wall tiles (no WALL text).
4. In the Scene dock, confirm those layers reference `IsoBlockoutTileset_Clean.tres`.

## Confirm Marker Palette Is Active

1. Select `MarkerTileLayer`.
2. Confirm it references `MarkerAuthoringTileset.tres`.
3. Confirm marker tiles are visible/selectable for:
   `OBJ`, `HELP`, `SCENT_REAL`, `SCENT_FAKE`, `SCENT_PATH`, `GUARD`, `PATROL`, `CAM`, `FLOOD`, `LIGHT`, `ALARM`, `AMBUSH`, `GATE`, `BLOCK`, `ROUTE_IN`, `ROUTE_SPAWN`, `ROUTE_RET`, `ROUTE_DEST`, `VENT_IN`, `VENT_OUT`, `STAIRS_UP`, `STAIRS_DN`, `CLUE`, `BAG`, `PHOTO`, `GLOW`, `TINY`, `EXIT`, `DOOR`, `SWITCH`.

## Marker Atlas Coordinates

The marker authoring tileset registers 30 tiles across rows `y=0`, `y=2`, `y=4` of the `640x320` atlas (`64x64` per cell, source id `0`):

| Row | Atlas coords (x,y) | Abbreviations |
| --- | --- | --- |
| 0 | (0..9, 0) | `OBJ`, `HELP`, `SCENT_REAL`, `SCENT_FAKE`, `SCENT_PATH`, `GUARD`, `PATROL`, `CAM`, `FLOOD`, `LIGHT` |
| 2 | (0..9, 2) | `ALARM`, `AMBUSH`, `GATE`, `BLOCK`, `ROUTE_IN`, `ROUTE_SPAWN`, `ROUTE_RET`, `ROUTE_DEST`, `VENT_IN`, `VENT_OUT` |
| 4 | (0..9, 4) | `STAIRS_UP`, `STAIRS_DN`, `CLUE`, `BAG`, `PHOTO`, `GLOW`, `TINY`, `EXIT`, **`DOOR`**, **`SWITCH`** |

`DOOR` and `SWITCH` are new in Phase 0G v6 to support route-doors and control/utility switches without overloading category tiles like `GATE`, `CAM`, `LIGHT`, or `EXIT`. Neither tile carries a physics polygon — both are visual authoring aids only.

## If You Still See Old Blue/Gray Tiles

1. In Godot, right-click `iso_blockout_atlas_clean.png` and choose **Reimport**.
2. Reopen the scene and reselect `FloorLayer` / `WallLayer`.
3. If needed, reimport `marker_authoring_atlas.png` as well.

## Marker Layer Behavior

- `MarkerTileLayer` is an editor-authoring visual aid.
- It is configured with `collision_enabled = false`.
- Painting marker tiles does not add runtime interaction logic by itself.
- Runtime mission logic still comes from `MarkerRoot` (`IsoMissionMarker` nodes) unless a system explicitly reads marker tilemap data.

## Visual Marker Tiles vs Runtime Markers

- `MarkerTileLayer`: quick visual planning and paintable icon vocabulary.
- `MarkerRoot`: authoritative gameplay markers (IDs, positions, links, and mission behavior).
- Do not assume a painted marker tile replaces a required runtime marker node.

## Scenes Updated In This Pass

- `res://scenes/missions_iso/TacoBellIso_Editable.tscn`
- `res://scenes/missions_iso/TacoBellIso_Editable_Test.tscn`
- `res://scenes/missions_iso/TacoBellIso_Editable2.tscn`

## Scenes Inspected But Not Updated

- `res://scenes/missions_iso/TacoBellIsoBlockout.tscn` (does not expose the same editable `LayoutRoot` tile authoring stack)
- `res://scenes/templates/IsoMissionTemplate.tscn` (no equivalent mission-editable layout tile stack to switch in this pass)

## Known Limitations

- Existing mission validation warnings/errors unrelated to this palette pass can still appear (for example `poop_bag_garage_pet_bin` in blocking collision).
- Marker tile icons are authoring aids and should be kept synchronized with `MarkerRoot` marker placement by the designer.

## Next Step

After visually confirming the floor/wall/marker palettes in editor, proceed to Phase `0G` coordinate-driven map construction.
