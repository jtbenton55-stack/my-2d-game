# Hideout Phase 0M-D3-FIX Decorating Runtime Repair

Status: PARTIAL pending manual runtime playtest.

## Backup

- Backup path: `res://scenes/hideout/HideoutHub.phase0md3fix_backup.20260507_211036.tscn`
- Taco Bell scenes modified: no

## Files Created

- `res://src/tools/editor/HideoutPhase0MD3FixValidator.gd`
- `res://docs/reports/hideout_phase_0md3_fix_decorating_runtime.md`
- `res://docs/reports/hideout_phase_0md3_fix_decorating_runtime.json`

## Files Modified

- `res://src/hideout/HideoutDecoratingModeController.gd`

## HUD Fix Summary

The Decorating Mode HUD now builds a readable UI with title, status label, controls label, buttons, and an owned-item picker. Buttons include Exit Decorating Mode, Cancel Placement, Remove Selected, and Clear Selection. The item picker lists owned decor items that are not currently placed.

## Preview Hover Movement Fix

Hover movement now reads mouse world position, snaps it to the 16 px world grid, assigns the preview to that snapped position, and only validates for color/status feedback.

Nearest-open search is no longer used during hover.

## Confirm / Nearest-Open Summary

Nearest-open search now runs only from `confirm_current_placement()` when the player left-clicks on an invalid placement. If a nearby valid grid point is found, the item places there and the HUD reports “Snapped to nearest open spot.” If none is found, the item remains carried and HUD reports “No open spot nearby.”

## Placed Item Reselect / Move Summary

Placed item selection now has controller-level hit testing using placed item footprints. Left-click while idle in Decorating Mode checks placed item rectangles directly and starts moving the clicked item. Moving an existing item preserves `placed_id`, hides the original visual while carried, ignores its own old footprint during validation, and updates the existing state record on confirm.

## Remove / Delete Summary

R/Delete and HUD Remove Selected call the same removal path. Removing clears selected/carrying IDs, deletes state entry, rebuilds visuals/collision, keeps owned inventory, and refreshes the HUD item picker so the removed item can be placed again.

## Cancel / Exit Summary

Right-click/Esc while carrying cancels placement and restores an existing moved item to its original position/rotation. Esc while idle exits Decorating Mode. HUD Exit Decorating Mode exits safely and hides HUD/grid/preview.

## Existing Systems Preservation

- Store purchase and Case Cash paths unchanged.
- Loot Crate/Open Decor Area paths unchanged.
- Old anchor placement buttons remain in Open Decor Area.
- MissionBoard launch path remains `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Pause exit path remains `res://scenes/hideout/HideoutHub.tscn`.
- GameplayRoot / ArtRoot separation preserved.

## Known Placeholders

- Decor visuals remain placeholder polygons/labels.
- Runtime item picker and HUD layout are functional but plain.
- Placement validation still uses conservative Rect2 footprints.
- Manual tuning may still be needed for no-place zone sizes.

## Risks / Fragile Areas

- Manual testing is needed to confirm mouse-world conversion under the active camera matches the player’s perceived cursor position.
- Wall decor still uses validation/status for wall rows but hover is intentionally direct to snapped mouse position to avoid rerouting.
- UID duplicate warnings from backup scenes are editor noise and not addressed in this pass.

## Manual Playtest Checklist

1. Open HideoutHub.tscn.
2. Buy or use already-owned Taco Bell Stool.
3. Open Open Decor Area.
4. Select item.
5. Click Enter Click-to-Place Mode.
6. Confirm panel closes.
7. Confirm HUD has readable text.
8. Confirm HUD has Exit Decorating Mode button.
9. Confirm HUD has Cancel Placement button when carrying.
10. Confirm HUD has Remove Selected button when item selected.
11. Confirm HUD lists available owned unplaced item(s).
12. Confirm grid appears.
13. Move mouse around open floor.
14. Confirm preview follows mouse smoothly and only snaps to grid.
15. Move mouse over/near Mission Board, The Big Case, Polaroid Wall, Glow Guy Shelf, and other no-place zones.
16. Confirm preview does NOT fly around in weird rows/columns.
17. Confirm preview simply stays under snapped mouse position and turns red/blocked over invalid areas.
18. Left-click on valid open floor.
19. Confirm item places.
20. Confirm still in Decorating Mode.
21. Click placed item.
22. Confirm item becomes selected/movable.
23. Move mouse.
24. Confirm selected item follows mouse as preview.
25. Left-click to place it somewhere else.
26. Confirm item moved, not duplicated.
27. Try placing on invalid red spot.
28. Confirm nearest-open search only happens when clicking, not while hovering.
29. Confirm invalid click either snaps to nearby valid spot or says no open spot nearby.
30. Press R or Delete with item selected.
31. Confirm item disappears and remains owned.
32. Use HUD item picker to select it again.
33. Place it again.
34. Right-click while carrying and confirm cancel.
35. Press Esc while carrying and confirm cancel.
36. Press Esc while idle and confirm Decorating Mode exits.
37. Enter Decorating Mode again and press HUD Exit Decorating Mode.
38. Confirm Decorating Mode exits.
39. Confirm E interactions work afterward.
40. Confirm Store, Loot Crate, Open Decor, Planning Table, and Mission Board still open.
41. Confirm MissionBoard still launches Taco Bell.
42. Confirm pause exit still returns to HideoutHub.
43. Confirm no Taco Bell scenes were modified.

## Recommended Next Step

If manual 0M-D3-FIX test passes: `0M-B — Hideout visual dressing / Monogon-style prop pass`.

If manual test fails: `0M-D3-FIX2 — targeted fix for remaining runtime issue`.
