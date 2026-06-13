# Phase 3G — PVGames Object Palette v2 Manual QA Blockers Fix

**Date:** 2026-06-10
**Follow-up to:** `reports/ai/2026-06-09_phase3g_pvgames_palette_v2_review_fix_report.md`
**Agent:** Cursor Ultra Auto

## Goal

Fix Jake's remaining Phase 3G manual QA blockers:
1. Unreliable `Place With Mouse` before a prior stamp/CanvasItem selection.
2. `Z Override` effectively always on (no disable path).
3. Confusing sortable route messaging in scratch test scene (no `VisualRoot/SortableWorld`).

## Jake QA evidence (pre-fix)

**PASS:**
- Rectangle outline / fill / scatter
- Shape cancel
- Position jitter, random rotation, random scale, combined scatter + variation
- Sortable placement + erase in sortable pilot scene
- Non-palette erase refusal

**BLOCKERS found:**
- Place With Mouse often does nothing until after `Stamp Selected at Scene Origin` (selects a CanvasItem)
- Z Override always active — no way to use route defaults
- Sortable route confusing in `PVGamesObjectPaletteDockTest.tscn` (no sortable parent)

## Files changed

| File | Change |
|---|---|
| `addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd` | `_handles()` returns true while palette input armed; `notify_input_forwarding_changed()` |
| `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` | Canvas forwarding helpers; `Use Z Override` checkbox; route default z_index; sortable scene guidance |
| `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` | Checks for new helpers and Z override toggle |
| `reports/ai/2026-06-10_phase3g_pvgames_palette_v2_manual_qa_blockers_fix_report.md` | This report |

## Fix summary

### 1. Place With Mouse reliability
**Root cause:** `_handles()` only returned true for `CanvasItem` selections. Godot forwards canvas GUI input to plugins based on `_handles()` even with forwarding enabled in 4.6.

**Fix:**
- `should_forward_canvas_gui_input()` on dock — true when mouse placement armed, brush active, shape drag active, or brush mode on.
- Plugin `_handles()` returns true when `should_forward_canvas_gui_input()` is true.
- `_notify_input_forwarding_changed()` calls `update_overlays()` on arm/cancel/brush toggle.
- Arming still uses `_preview_stamp_target()` only (non-mutating).

### 2. Z Override disable
- Added **`Use Z Override`** checkbox (default **OFF**).
- When OFF: `_default_z_index_for_route()` applies route/container defaults (`-120` / `90` / `160` / `-40`; sortable `0`).
- When ON: uses spinbox value exactly.
- Removed user-facing `999999` sentinel.
- Dry run reports `use_z_override` and resolved `z_index`.

### 3. Sortable route clarity
- Sortable refusal message now includes: `Use Phase3JSortable2DPilot.tscn for sortable QA.`
- Placement Route help text distinguishes scratch fixed-route scene vs sortable pilot scene.
- Dry Run / Place With Mouse refuse sortable in scratch scene without arming or mutating.

## Scene usage (manual QA guide)

| Scene | Purpose |
|---|---|
| `res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn` | Fixed routes, dry run, mouse placement, shapes, variation, erase |
| `res://scenes/dev/phase3j_sortable_2d_pilot/Phase3JSortable2DPilot.tscn` | Sortable 2.5D Prop route + Y-sort depth QA |

## Validation run

| Check | Result |
|---|---|
| `git diff --check` | **PASS** (CRLF warnings) |
| Python static wiring simulation | **PASS** |
| Godot LSP (dock) | **PASS** |
| Godot LSP (plugin) | **PASS** (after reverting invalid `true` arg — Godot 4.6 API is no-arg) |
| Jake re-run manual checklist | **PENDING** |

## Manual QA checklist (Jake — pending re-run)

### Scratch scene — mouse placement
- [ ] Fresh state, no palette object selected → Place With Mouse → LMB places one object
- [ ] Esc cancel — no mutation
- [ ] RMB cancel — no mutation
- [ ] Non-palette node selected → Place With Mouse → LMB still places

### Scratch scene — Z defaults
- [ ] `Use Z Override` OFF → Behind `-120`, Occludable `90`, Foreground `160`, Review `-40`
- [ ] `Use Z Override` ON @ `123` → stamped `z_index = 123`
- [ ] OFF again → defaults return

### Scratch scene — sortable refusal
- [ ] Sortable route → Dry Run refuses with pilot scene message
- [ ] Sortable route → Place With Mouse refuses to arm

### Sortable pilot — regression
- [ ] Sortable stamp direct child of `VisualRoot/SortableWorld`, `z_index = 0` when override OFF
- [ ] Icons refused; erase guards unchanged

### Regression
- [ ] Dry run non-mutating; shapes/variation/erase unchanged

## Phase 3G status

**Implementation + static validation:** complete through this fix pass.
**Manual QA:** pending Jake re-run of checklist above.
**Not auto-signed-off** — ready for Jake sign-off only after checklist passes.

## Remaining risks

1. Canvas forwarding behavior may vary by Godot editor focus; Jake should confirm from fresh editor restart.
2. `_selected_z_index()` retained for compatibility but stamping uses `_selected_z_index_for_route()`.

## Recommended next step

Jake re-runs the checklist in this report. If PASS, sign off Phase 3G gate #6 and proceed to Phase 2K Mission Authoring Palette.
