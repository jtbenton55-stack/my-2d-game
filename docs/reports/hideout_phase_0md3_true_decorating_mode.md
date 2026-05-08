# Hideout Phase 0M-D3 True Decorating Mode

Status: PARTIAL pending manual playtest. Static implementation is complete and designed to be runtime-load verified.

## Backup

- Backup path: `res://scenes/hideout/HideoutHub.phase0md3_backup.20260507_192506.tscn`
- Taco Bell scenes modified: no

## Files Created

- `res://src/hideout/HideoutDecoratingModeController.gd`
- `res://src/hideout/HideoutPlacedDecorItem.gd`
- `res://src/hideout/HideoutDecorGridOverlay.gd`
- `res://src/hideout/HideoutDecorPlacementValidator.gd`
- `res://src/tools/editor/HideoutPhase0MD3Validator.gd`
- `res://docs/reports/hideout_phase_0md3_true_decorating_mode.md`
- `res://docs/reports/hideout_phase_0md3_true_decorating_mode.json`

## Files Modified

- `res://scenes/hideout/HideoutHub.tscn`
- `res://src/hideout/HideoutManager.gd`
- `res://src/hideout/HideoutDecorationController.gd`
- `res://src/hideout/HideoutStoreController.gd`

## Decorating Mode Summary

`HideoutDecoratingModeController` provides an explicit state machine with inactive, active idle, carrying new item, carrying existing item, selected placed item, and placement invalid states. Entering decorating mode closes the station panel, removes the panel from `blocking_ui` while active, shows a HUD, shows a faint grid, and starts a ghost preview if an owned item is selected.

The explicit action is `decor_enter_click_to_place_mode`. Old aliases are routed through `HideoutManager` so `decor_enter_placement_mode`, `enter_click_to_place_mode`, `decor_enter_click_to_place`, and `decor_place_mode` do not fail silently.

## Snap, Preview, Rotation

World-space snapping uses a 16 px grid. The grid is a low-alpha world-space line overlay, not an iso-cell grid. The ghost preview follows the mouse using world coordinates, snaps to the grid, rotates in 45-degree increments with arrow keys, and tints valid/blocked.

Rotation uses a conservative axis-aligned footprint for validation when rotated; exact rotated rectangle collision is deferred.

## Metadata

All Taco Bell decor items now include `footprint_width_px`, `footprint_height_px`, `blocks_player`, `can_rotate`, `snap_mode`, `wall_only`, and `placement_category`. `iso_cell` is reserved conceptually through `snap_mode` but not implemented in this pass.

## No-Place Zones

No-place zones are implemented as Rect2 world-space zones in code. Zone count: 29. Protected station/proxy count: at least 16. Door protected: yes. Player spawn protected: yes. Boundary/corridor protected: yes.

Overlap prevention compares candidate footprints against no-place zones and existing placed item footprints. Nearest-open search scans outward in 16 px rings up to 256 px and reports either nearest-open snap or no nearby open spot.

## Collision

Floor-standing decor with `blocks_player = true` creates a `StaticBody2D` using the Walls layer bitmask (`4`) so the existing player wall mask collides with it. Rugs and wall items reserve placement space but do not block the player.

## Select / Move / Remove

Placed decor is rebuilt as `HideoutPlacedDecorItem` nodes with clickable `Area2D` selection. In Decorating Mode, clicking an item starts moving that placed record instead of duplicating it. R/Delete removes selected placed decor while preserving owned inventory. The Open Decor Area remove and clear buttons remain.

## Wall Snap Rows

Wall decor/light items snap to named wall rows/zones: `wall_snap_west`, `wall_snap_east_store`, `wall_snap_north_big_case`, `wall_snap_greenhouse`, and `wall_snap_cozy_lounge`. Wall items do not block player movement and cannot be freely placed in the middle of the room.

## Preservation

- Existing 18 station interactions: statically preserved through station catalog.
- MissionBoard launch path: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Pause exit hideout path: `res://scenes/hideout/HideoutHub.tscn`.
- Store purchase: preserved.
- Case Cash: preserved.
- Loot Crate inventory: preserved.
- Back/Close: preserved.
- GameplayRoot / ArtRoot separation: preserved.

## Known Placeholders

- Decor visuals are placeholder polygons and labels.
- Validation uses rectangular no-place zones, not authored Area2D zones.
- Rotated footprint checks use conservative axis-aligned boxes.
- Persistence is scene-local/debug state only.

## Risks / Fragile Areas

- Runtime mouse/world coordinate conversion must be checked in the camera/CanvasLayer setup.
- Wall snap rows are hand-authored world-space rectangles and may need tuning after manual playtest.
- No-place zones intentionally overprotect station paths; some desired cozy placement spots may be blocked until tuned.

## Manual Playtest Checklist

1. Open `res://scenes/hideout/HideoutHub.tscn`.
2. Confirm movement and collision still work.
3. Open Store Terminal.
4. Toggle Taco Bell Completed if needed.
5. Buy one decor item.
6. Confirm Case Cash decreases.
7. Open Loot Crate.
8. Confirm purchased item appears.
9. Open Open Decor Area.
10. Select purchased item.
11. Click Enter Click-to-Place Mode.
12. Confirm Open Decor panel closes.
13. Confirm Decorating Mode HUD appears.
14. Confirm faint grid appears.
15. Confirm item ghost/preview follows mouse.
16. Confirm preview snaps to grid.
17. Press Left/Right Arrow.
18. Confirm preview rotates in 45-degree increments.
19. Move preview near station/door/player spawn.
20. Confirm placement is blocked or snapped away from protected area.
21. Move preview to open floor.
22. Left-click to place item.
23. Confirm item appears.
24. Confirm still in Decorating Mode.
25. Try walking into placed item.
26. Confirm collision blocks the player for floor-standing decor.
27. Click placed item again in Decorating Mode.
28. Confirm it becomes selected/carryable.
29. Move it elsewhere.
30. Left-click to place it again.
31. Try placing it on top of another item or blocked zone.
32. Confirm overlap is prevented or nearest open spot is used.
33. Rotate placed/moving item again.
34. Remove/delete selected item using R/Delete or HUD/button.
35. Confirm item disappears from map.
36. Confirm item remains owned in inventory.
37. Try right-click cancel.
38. Try Esc cancel.
39. Confirm Esc exits Decorating Mode when not carrying item.
40. Reopen Open Decor Area.
41. Confirm old anchor-placement buttons still work as fallback.
42. Confirm Store, Loot Crate, Planning Table, Mission Board, Bentley Care still open.
43. Confirm MissionBoard still launches Taco Bell.
44. Pause Taco Bell and exit to hideout.
45. Confirm it returns to new HideoutHub.
46. Confirm no Taco Bell scenes were modified.

## Recommended Next Step

If manual 0M-D3 test passes: `0M-B — Hideout visual dressing / Monogon-style prop pass`.

If manual 0M-D3 test fails: `0M-D3-FIX — focused fix for failed decorating-mode issue`.
