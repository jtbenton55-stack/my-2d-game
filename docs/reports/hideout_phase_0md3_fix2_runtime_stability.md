# Hideout Phase 0M-D3-FIX2 Runtime Stability

Status: PARTIAL pending manual runtime verification.

## Backup

- Backup path: `res://scenes/hideout/HideoutHub.phase0md3fix2_backup.20260507_224126.tscn`
- Taco Bell scenes modified: no

## Files Created

- `res://src/tools/editor/HideoutPhase0MD3Fix2Validator.gd`
- `res://docs/reports/hideout_phase_0md3_fix2_runtime_stability.md`
- `res://docs/reports/hideout_phase_0md3_fix2_runtime_stability.json`

## Files Modified

- `res://src/hideout/HideoutDecoratingModeController.gd`
- `res://src/hideout/HideoutDecorPlacementValidator.gd`

## Read-Only Dictionary Crash Fix

The crash was caused by `_hit_test_placed_item()` assigning `rotation_degrees` into a dictionary returned from the store catalog:

`item["rotation_degrees"] = float(placed.get("rotation", 0.0))`

That catalog dictionary can be read-only. The hit test now duplicates the catalog item dictionary before adding temporary rotation data. `_hit_test_placed_item()` does not write temporary fields into placed item dictionaries and returns only the matching `placed_id`.

Placed item updates remain isolated to `_update_placed_item()`, which finds by `placed_id`, updates the array entry, and writes the array back to state.

## Placed Item Reselect / Move

The controller-level hit test remains in place. Clicking a placed item in Decorating Mode should now select that `placed_id` without crashing, call `start_moving_placed_item(placed_id)`, hide the original visual while carried, ignore its own footprint during validation, and update the same state entry on confirm.

## Defensive Display Audit

Searched hideout/decorating code for global viewport scale, canvas transform mutation, camera zoom mutation, ProjectSettings display/window changes, stretch settings, SubViewport/render target usage, texture filtering, shader/material blur or pixelation, and persistent fullscreen overlays.

Systemwide fuzziness appears external to the Godot project. No project-side viewport/camera/stretch mutation was found.

The only matching decorating-code display reference is a read-only fallback call to `get_canvas_transform().affine_inverse()` for mouse-world conversion. It does not mutate display state.

Grid/HUD/preview cleanup is present: exit hides grid, hides HUD, removes preview, clears selection, and restores panel blocking group state.

## No-Place Zone Padding

Before:
- Normal station/object padding: 24 px
- Door/player spawn/corridor/boundary used the same default expansion

After:
- Normal station/object padding: 12 px
- Door/player spawn critical padding: 24 px
- Main corridor padding: 20 px
- Boundary padding: 16 px

No-place zones were not removed. Station/board blocked areas should now be tighter while preserving stronger protection for exit, spawn, corridors, and boundaries.

## Existing Systems Preservation

- Store purchase path unchanged.
- Case Cash path unchanged.
- Loot Crate/Open Decor paths unchanged.
- Old anchor placement fallback unchanged.
- MissionBoard launch path remains `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Pause exit path remains `res://scenes/hideout/HideoutHub.tscn`.
- Taco Bell scenes were not modified.

## Known Placeholders

- Decor visuals are still placeholder polygons and labels.
- Hit testing uses conservative Rect2 footprint checks.
- No-place zones remain authored constants and may need another small tuning pass after manual testing.

## Risks / Fragile Areas

- Manual testing is still needed to confirm placed-item click/reselect no longer crashes.
- Tighter station padding could allow some placements closer than desired and may need hand tuning around specific stations.
- Backup `.tscn` UID duplicate warnings are editor noise and not addressed in this pass.

## Manual Playtest Checklist

1. Open HideoutHub.tscn.
2. Buy/use Taco Bell Stool.
3. Open Open Decor Area.
4. Select Taco Bell Stool.
5. Enter Click-to-Place Mode.
6. Confirm HUD/grid/preview appear.
7. Place item on valid open floor.
8. Click placed item again.
9. Confirm no crash.
10. Confirm item becomes movable.
11. Move it somewhere else.
12. Confirm item moved, not duplicated.
13. Right-click/Esc while moving and confirm original position restores.
14. Place it again.
15. Press R/Delete/HUD Remove.
16. Confirm item disappears and remains owned.
17. Move preview near Mission Board / Big Case / Polaroid Wall / Glow Guy Shelf.
18. Confirm red blocked area is tighter than before.
19. Confirm station access is still protected.
20. Try placing on invalid red spot.
21. Confirm it snaps to nearest open spot or reports no open spot.
22. Exit Decorating Mode using HUD Exit.
23. Confirm grid/HUD/preview disappear.
24. Confirm E interactions still work in HideoutHub.
25. Launch Taco Bell from MissionBoard.
26. Confirm Taco Bell still launches.
27. Pause Taco Bell and exit to hideout.
28. Confirm it returns to HideoutHub.
29. Confirm no Taco Bell scenes were modified.

## Recommended Next Step

If manual 0M-D3-FIX2 test passes: `0M-B — Hideout visual dressing / Monogon-style prop pass`.

If manual test fails: `0M-D3-FIX3 — tiny targeted fix for the exact failed runtime issue`.
