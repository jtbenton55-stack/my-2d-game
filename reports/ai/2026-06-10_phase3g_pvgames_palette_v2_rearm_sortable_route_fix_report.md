# Phase 3G — PVGames Object Palette v2 Re-Arm + Sortable Route Fix

**Date:** 2026-06-10 (follow-up pass)
**Agent:** Cursor Ultra Auto

## Jake QA context

**Already PASS:** rectangle outline/fill/scatter, shape cancel, jitter/rotation/scale, combined scatter+variation, sortable placement/erase (prior pass), non-palette erase refusal, first Place With Mouse placement.

**Blockers before this fix:**
1. Place With Mouse did not reliably re-arm after placement, Esc, RMB, or Undo.
2. Sortable route in `Phase3JSortable2DPilot.tscn` reported `Error: ArtRoot not found` when UI showed Sortable 2.5D Prop.

## Root causes

### Re-arm failure
`update_overlays()` alone did not refresh Godot editor plugin `_handles()` state when `_place_with_mouse_pending` toggled without a selection change (common after Undo clears selection). Canvas forwarding stopped until a CanvasItem was selected again.

### Sortable / ArtRoot error
Route UI desync: `_on_target_container_changed()` could overwrite `_active_placement_route_key` back to a fixed ArtRoot route after the user chose Sortable 2.5D Prop. In scenes without ArtRoot (Phase3J pilot), fixed-route preview/arm then failed with `ArtRoot not found`.

## Files changed

| File | Change |
|---|---|
| `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` | `_active_placement_route_key`, route sync guards, `_clear_mouse_placement_pending()`, deferred notify |
| `addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd` | `selection.emit_changed()` on input forwarding refresh |
| `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` | Checks for active route key + pending clear + emit_changed |
| `reports/ai/2026-06-10_phase3g_pvgames_palette_v2_rearm_sortable_route_fix_report.md` | This report |

## Fix summary

1. **`_active_placement_route_key`** — source of truth for route; set from route dropdown index directly (not stale OptionButton reads).
2. **Route sync guards** — `_on_target_container_changed()` ignored when route is sortable; signal blocking during programmatic UI sync.
3. **Re-arm refresh** — `_clear_mouse_placement_pending()` + deferred `_notify_input_forwarding_changed()`; plugin calls `selection.emit_changed()` to refresh `_handles()`.
4. **Sortable in Phase3J** — preview/resolve use active route key; sortable path never requires ArtRoot.

## Validation

| Check | Result |
|---|---|
| `git diff --check` | Run in session |
| Static validator simulation | Run in session |
| Godot LSP | Run in session |
| Jake full manual checklist | **PENDING** |

## Manual QA checklist (Jake — pending)

### Scratch scene — repeated mouse placement
- [ ] Place With Mouse → LMB → object appears
- [ ] Place With Mouse again → LMB → second object
- [ ] Undo → Place With Mouse → LMB still works
- [ ] Place With Mouse → Esc → no mutation → re-arm works
- [ ] Place With Mouse → RMB → no mutation → re-arm works
- [ ] Dry Run Stamp → no tree changes

### Phase3J sortable pilot
- [ ] Select object, set Sortable route **after** asset selection
- [ ] Place With Mouse → no ArtRoot error
- [ ] LMB → direct child of `VisualRoot/SortableWorld`, `z_index = 0` (override OFF)
- [ ] Repeat Place With Mouse twice
- [ ] Z Override ON @ 123 → sortable stamp uses 123
- [ ] Icon + Sortable → clear refusal

### Regression
- [ ] Shapes, variation, erase unchanged

## Phase 3G status

Implementation + static validation updated; **manual QA pending Jake re-run**. Not auto-signed-off.

## Recommended next step

Jake re-runs checklist above; if PASS, sign off Phase 3G gate #6.
