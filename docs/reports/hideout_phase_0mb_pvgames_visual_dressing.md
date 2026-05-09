# Hideout Phase 0M-B PVGames Visual Dressing

Status: PASS pending final manual playtest.

## Backup

- Backup path: `res://scenes/hideout/HideoutHub.phase0mb_backup.20260508_032325.tscn`

## PVGames Audit Files Read

- `res://docs/reports/pvgames_cyber_city_tile_geometry_audit.md`
- `res://docs/reports/pvgames_cyber_city_tile_geometry_audit.json`
- `res://docs/reports/pvgames_cyber_city_geometry_measurements.json`
- `res://docs/reports/pvgames_cyber_city_geometry_contact_sheet.png`

## Asset Folders Used

- `res://assets/tilesets/cyber_city_core_tilesets`

## Integration Method

This pass uses a hybrid visual-only approach. PVGames assets are placed as Sprite2D nodes at runtime by `HideoutPVGamesVisualHelper.gd`; no PVGames collision, physics bodies, station proxies, gameplay scripts, or TileMap collision were added.

TileMapLayer was not used in production for this pass. The measured floor subset is represented with hand-placed visual Sprite2D floor patches because the pack is not one clean global grid.

## Layering Summary

- `FloorLayer`: floor tint and PVGames floor/mat patches.
- `WallLayer`: greenhouse, north wall, MissionBoard, Big Case, west display backers, and entry door art.
- `PropLayer`: planning table, store terminal, care station, loot crates, lounge furniture, plants, and scanner props.
- `CollectibleLayer`: west collectible shelves/displays.
- `ForegroundLayer`: sparse rooftop machinery for depth.
- `LightingLayer`: small translucent neon/zone glows and labels.

All PVGames visuals are tagged with `hideout_pvgames_visual_only` and `pvgames_visual_only` metadata.

## Area Summaries

- Floor: darkened the runtime graybox floor, added floor tint zones, and placed measured PVGames floor mats to define planning, greenhouse, cozy lounge, loot, entry, and open decor areas.
- Wall/structure: added PVGames wall pieces behind major north/west focal points and a cyber door at the entry.
- Greenhouse: added north wall/glass-like panels, green floor wash, plants, and soft green glow.
- Entry/care: added a door, utility cabinet, crate, delivery/care boxes, and a Bentley Care neon label.
- Cozy lounge: added Bentley bed, couch, chairs, warm mat, barrel side table, and warm glow.
- MissionBoard: added screen bank, neon sign, cyan glow, and label.
- Big Case: added mystery/evidence screen, wall backer, warm clue-board light, and label.
- PlanningTable: added PVGames table, chairs, monitor, floor patching, and central composition.
- Collectible displays: added shelves/cabinets/billboard accents to Polaroid, Glow Guy, Tiny Icon, and Poop Bag displays.
- Store: added terminal, counter/cabinet, magenta sign/glow, and shady store identity.
- Open Decor Area: kept open; only subtle floor markers and label were added.

## Visual Design / Feng Shui

The pass clusters props by station purpose, leaves open walking/decor space, and gives the north/west/east/southwest zones different color identities. It avoids mass asset dumping and uses roughly 50 curated PVGames assets.

## Preservation Summary

- GameplayRoot remains gameplay truth.
- ArtRoot/World contains the visual dressing helper.
- Station proxies were not moved or renamed.
- Existing collision was not rebuilt.
- PVGames collision was not added.
- MissionBoard launch path remains `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Pause return path remains `res://scenes/hideout/HideoutHub.tscn`.
- Taco Bell scenes were not modified.

## Decorating Mode Preservation

No decorating mode logic was changed. The helper only lowers graybox visual noise and adds visual-only art. Placed decor remains under `ArtRoot/World/DecorationLayer/PlacedDecor`; floor art stays beneath that layer.

## Regression Check Summary

Runtime load of HideoutHub through `SceneManager.change_scene("res://scenes/hideout/HideoutHub.tscn")` completed with zero captured engine errors after the helper was added. Manual playtest is still required for full interaction/decorating coverage.

## Troubleshooting Performed

- Fixed an initial helper typing issue caught by runtime load.
- Lowered/dimmed runtime graybox placeholder polygons so PVGames art reads as the primary dressing.
- Kept the debug/status UI and gameplay proxies untouched.

## Validator Results

- Validator created: `res://src/tools/editor/HideoutPhase0MBValidator.gd`
- Validator result: PASS

## Known Placeholders

- PVGames art is a first curated pass, not final per-pixel art direction.
- No production TileSet/TileMapLayer was built yet.
- Existing debug state panel remains available in the scene.
- Existing runtime station labels are dimmed, not fully replaced by custom art labels.

## Risks / Fragile Areas

- Manual visual review is needed to tune exact sprite scale/offsets.
- Some PVGames assets may need per-zone replacement after seeing them at full gameplay scale.
- The helper runs deferred after the runtime graybox build; if HideoutManager layer names change, the helper must be updated.

## Manual Playtest Checklist

1. Open HideoutHub.tscn.
2. Confirm the room is visibly dressed with PVGames art.
3. Confirm it still uses the same non-square hideout layout.
4. Confirm it looks like a neon-noir cyber crime hideout, not a graybox.
5. Confirm player appears above floor visuals.
6. Walk around the whole hideout.
7. Confirm collision still works.
8. Confirm player does not look like walking on walls/counters.
9. Press E at EntryExitDoor.
10. Press E at BentleyCareStation.
11. Press E at LootCrateDropZone.
12. Press E at Bentley/Jake/Mere.
13. Press E at MissionBoard.
14. Press E at The Big Case.
15. Press E at PlanningTable.
16. Press E at PolaroidWall.
17. Press E at GlowGuyShelf.
18. Press E at TinyIconShelf.
19. Press E at PoopBagCareDisplay.
20. Press E at StoreTerminal.
21. Press E at OpenDecorZone.
22. Confirm panels still open/close.
23. Buy an item from Store.
24. Confirm Case Cash decreases.
25. Open Loot Crate.
26. Confirm item appears.
27. Open Open Decor Area.
28. Enter Decorating Mode.
29. Confirm HUD/grid/preview visible above art.
30. Place an item.
31. Confirm placed item visible above floor art.
32. Confirm placed item blocks player.
33. Click/move/remove placed item.
34. Confirm it returns to HUD available list.
35. Open MissionBoard.
36. Launch Taco Bell.
37. Pause Taco Bell and exit to hideout.
38. Confirm it returns to HideoutHub.
39. Confirm no Taco Bell scenes were modified.

## Recommended Next Step

Manual 0M-B playtest. If it passes, continue to a small visual polish pass for sprite scale/offset tuning only. If it fails, do `0M-B-FIX1` for the exact visual or interaction regression.
