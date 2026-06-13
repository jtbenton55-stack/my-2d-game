# Phase 3G — PVGames Object Palette Blank Dock Fix (Init + Parse)

**Date:** 2026-06-10
**Agent:** Cursor Ultra Auto

## Regression

Jake opened `PVGamesObjectPaletteDockTest.tscn` with the `PVGames Object Palette` dock tab visible but **completely blank body**.

## Root cause (confirmed)

Godot Output parse error — script never loaded, so `_ready()` never ran:

```text
res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd:1254 - Parse Error:
Cannot infer the type of "route" variable because the value doesn't have a set type.
var route := PLACEMENT_ROUTE_KEYS[idx] if idx >= 0 and idx < PLACEMENT_ROUTE_KEYS.size() else _active_placement_route_key
```

Godot 4.6.2 cannot infer a concrete type for this ternary (`Array` element access vs `String` fallback).

An earlier init-guard pass ( `_ui_ready`, Z Override reorder ) was correct hygiene but **did not fix** the blank dock because the script failed to parse first.

## Code fix

**Primary (line ~1254):**

```gdscript
var route: String = _active_placement_route_key
if idx >= 0 and idx < PLACEMENT_ROUTE_KEYS.size():
    route = String(PLACEMENT_ROUTE_KEYS[idx])
```

**Additional explicit typing / if-else** in the same file to avoid similar Godot 4.6 inference failures:

- `_preview_stamp_target`: `reported_path: String` with if/else
- `_on_placement_route_changed`: `entry: Dictionary` explicit type
- `_random_for_stamp`: `seed_base: int` with if/else
- `_normalized_scale_range`: `lo: float` / `hi: float` explicit types

Behavior unchanged; Phase 3G features preserved.

## Files changed

| File | Change |
|---|---|
| `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` | Parse-safe route + similar ternary fixes |
| `reports/ai/2026-06-10_phase3g_pvgames_palette_blank_dock_init_fix_report.md` | This report (updated) |

Prior init guards (`_ui_ready`, `_on_use_z_override_toggled`, deferred route sync) remain in place.

## Validation

| Check | Result |
|---|---|
| `git diff --check` | Run in session |
| Unsafe route ternary removed (static grep) | **PASS** |
| Godot LSP `get_diagnostics` (dock) | **PASS** |
| Live editor: full dock UI visible | **PENDING Jake** |
| Post-fix smoke QA (Dry Run + Place With Mouse) | **PENDING Jake** |

## Post-fix smoke QA (Jake)

Scratch scene `PVGamesObjectPaletteDockTest.tscn`:

1. Confirm full dock UI (title, Search, Results, Placement Route, Actions, etc.).
2. No red Output error for `PVGamesObjectPaletteDock.gd`.
3. Fixed Occludable Art → Dry Run Stamp → no scene mutation.
4. Place With Mouse → LMB → one object under `ArtRoot/World/PVG_EditableObjects/OccludableObjects`.

Full Phase 3G checklist still pending after smoke pass.

## Phase 3G status

**Manual QA pending** — not signed off until Jake confirms dock UI + full checklist.

## Recommended next step

Reload/re-enable plugin, confirm parse error gone and UI visible, then rerun Phase 3G checklist from `2026-06-10_phase3g_pvgames_palette_v2_rearm_sortable_route_fix_report.md`.
