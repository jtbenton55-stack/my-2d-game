# Hideout Phase 0M-D3-FIX3 Click Move / No-Place Tuning

Status: PARTIAL pending manual runtime verification.

## Backup

- Backup path: `res://scenes/hideout/HideoutHub.phase0md3fix3_backup.20260508_000529.tscn`
- Taco Bell scenes modified: no

## Files Created

- `res://scenes/hideout/HideoutHub.phase0md3fix3_backup.20260508_000529.tscn`
- `res://src/tools/editor/HideoutPhase0MD3Fix3Validator.gd`
- `res://docs/reports/hideout_phase_0md3_fix3_click_move_no_place_tuning.md`
- `res://docs/reports/hideout_phase_0md3_fix3_click_move_no_place_tuning.json`

## Files Modified

- `res://src/hideout/HideoutDecoratingModeController.gd`
- `res://src/hideout/HideoutPlacedDecorItem.gd`
- `res://src/hideout/HideoutDecorPlacementValidator.gd`
- `res://src/hideout/HideoutDecorationController.gd`

## Placed-Item Click Behavior

Before this pass, the controller hit-test path routed idle left-clicks to `start_moving_placed_item(placed_id)`, but placed item `Area2D` clicks did not consume the mouse event. Manual testing showed this could make the item disappear or fail to return to the HUD list.

After this pass, `HideoutPlacedDecorItem` consumes the left-click event before emitting `decor_clicked`, and `_on_placed_decor_clicked()` ignores clicks while already carrying an item. Idle left-click on a placed item is reserved for selecting/moving the existing placed item, not removal.

## Existing-Item Move Summary

`start_moving_placed_item(placed_id)` stores `carrying_existing_placed_id`, `selected_placed_id`, the original position, and original rotation. Confirming placement updates the existing state entry by `placed_id`; it does not call the new-item placement path while `carrying_existing_placed_id` is set. Canceling movement restores the original position and rotation.

## Canonical Remove Summary

Runtime Decorating Mode now uses `remove_placed_item_by_id(placed_id, reason)` as the canonical removal method. `remove_selected_placed_item()`, R/Delete, HUD Remove Selected, and clear-all route through that method. The Open Decor fallback controller now has the same canonical method for its panel remove and clear-all paths.

Removal deletes the state entry, rebuilds visuals/collision, clears selected/carrying IDs when needed, keeps owned inventory untouched, removes the preview when needed, and refreshes the HUD item picker.

## No-Place Validation Before / After

Before this pass, station/object zones were broad access rectangles and there were additional walking-path rectangles such as central planning, greenhouse, west collectible, east store, and southeast entry/care paths.

After this pass, broad access-path and corridor zones were removed. Station/display/table/board zones were reduced to tiny direct proxy rectangles with 6 px padding. Door, spawn, boundary, placed-item overlap, and wall snap validation remain.

## Broad Rules Removed / Disabled

- Station access corridor rectangles.
- Board/display access corridor rectangles.
- Planning/table broad access rectangles.
- Main walking/corridor rectangles.
- Greenhouse entrance path blocking.
- West collectible walking path blocking.
- East store walking path blocking.
- Southeast entry/care walking path blocking.

## Hard Safety Preserved

- Entry/exit door immediate zone.
- Player spawn immediate zone.
- Boundary margin zones.
- Direct station/proxy overlap zones.
- Existing placed-item overlap prevention.
- Wall decor snap-zone validation.
- Invalid-click nearest-open search.

## Existing Systems Preservation

- Store purchase and Case Cash paths unchanged.
- Loot Crate/Open Decor inventory paths unchanged.
- Old anchor placement fallback preserved.
- MissionBoard launch path remains `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Pause exit path remains `res://scenes/hideout/HideoutHub.tscn`.
- GameplayRoot / ArtRoot scene separation preserved.
- Taco Bell scenes were not modified.

## Validator Results

- Validator created: `res://src/tools/editor/HideoutPhase0MD3Fix3Validator.gd`
- Validator scope: static/runtime-load checks for click-to-move routing, canonical removal, narrowed no-place rules, preserved safety checks, 18+ stations, MissionBoard path, pause exit path, and reports.
- Manual runtime verification is still required for click/move feel and red-zone size.

## Known Placeholders

- Decor visuals are still placeholder polygons/labels.
- Hit testing and validation use Rect2 footprints.
- Proxy rectangles are hand-authored constants and may need spot tuning after manual testing.

## Risks / Fragile Areas

- Godot input ordering between `Area2D.input_event` and `_unhandled_input` was the likely click-remove cause; event consumption should fix it, but it needs manual confirmation.
- Direct proxy rectangles may now allow objects closer to displays than final art will want.
- Backup scene UID duplicate warnings may appear in the editor and are not addressed in this pass.

## Manual Playtest Checklist

1. Open HideoutHub.tscn.
2. Buy/use Taco Bell Stool.
3. Open Open Decor Area.
4. Select Taco Bell Stool.
5. Enter Click-to-Place Mode.
6. Place item on valid open floor.
7. Click placed item again.
8. Confirm it does NOT disappear.
9. Confirm it becomes movable / follows mouse.
10. Move it somewhere else.
11. Place it.
12. Confirm item moved, not duplicated.
13. Press R/Delete/HUD Remove.
14. Confirm item disappears.
15. Confirm item remains owned.
16. Confirm item returns to HUD available owned item list.
17. Select it from HUD item picker again.
18. Place it again.
19. Move preview near Mission Board / Big Case / Polaroid Wall / Glow Guy Shelf / Open Decor Area / Loot Crate.
20. Confirm red blocked area is much smaller.
21. Confirm red only appears on direct overlap or close/tiny proxy overlap.
22. Confirm broad walking/access paths are no longer blocked.
23. Confirm door/player spawn/boundary still block placement.
24. Try placing on top of another placed item.
25. Confirm overlap prevention still works.
26. Try placing wall item if available.
27. Confirm wall snap rules still work.
28. Exit Decorating Mode using HUD Exit.
29. Confirm E interactions still work.
30. Confirm Store, Loot Crate, Open Decor, Planning Table, Mission Board still open.
31. Confirm MissionBoard launches Taco Bell.
32. Pause Taco Bell and exit to HideoutHub.
33. Confirm no Taco Bell scenes were modified.

## Recommended Next Step

If manual 0M-D3-FIX3 test passes: `0M-B — Hideout visual dressing / Monogon-style prop pass`.

If manual test fails: `0M-D3-FIX4 — tiny targeted fix for the exact remaining issue`.
