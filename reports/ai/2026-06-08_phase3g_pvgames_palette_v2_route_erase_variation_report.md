# Phase 3G — PVGames Object Palette v2 Route / Erase / Variation Report

**Date:** 2026-06-08
**Stage:** Phase 3G
**Agent:** Cursor Ultra Auto (implementation/debugging)

## Goal

Upgrade `PVGamesObjectPaletteDock` from brush/stamp v1 into a safer, more complete visual-object placement tool with explicit placement routes, sortable 2.5D prop routing, palette-only erase, variation controls, and rectangle/scatter placement shapes — without becoming Mission Paint Dock or gameplay authoring tooling.

## Files changed

| File | Change |
|---|---|
| `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` | v2 UI + route/sortable/erase/variation/shape helpers; stamping paths refactored |
| `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` | Added static checks for all v2 surfaces |
| `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` | Phase 3G status, feature list, deferred polish |
| `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` | Tooling table + dependency-order gate updated |
| `reports/ai/2026-06-08_phase3g_pvgames_palette_v2_route_erase_variation_report.md` | This report |

**Not changed:** `project.godot`, Taco production scenes, Phase0J/Phase0K scripts, Mission Paint Dock, Character Animation Mapper, autoloads.

## New UI summary

1. **Placement Route** — Fixed Behind Art, Fixed Occludable Art, Sortable 2.5D Prop, Fixed Foreground Art, Review. Syncs with Target Container for fixed routes.
2. **Placement Shape** — Stroke, Rectangle Outline, Rectangle Fill, Scatter Rectangle (+ Scatter Count, clamp 500).
3. **Variation** — Position jitter X/Y, random rotation min/max, random scale min/max, deterministic random seed + seed value.
4. **Erase Palette Stamps** — Erase Selected Palette-Created Node button.

Existing sections preserved: search/filters, preview, brush controls, actions (dry run, typed/origin stamp, mouse place, ensure art root, copy ID, refresh).

## New behavior summary

### Placement routes
- Fixed routes continue to use `ArtRoot/World/PVG_EditableObjects` (or `ArtRoot/PVG_EditableObjects`) object/icon containers.
- **Sortable 2.5D Prop** resolves `VisualRoot/SortableWorld` (preferred) or `EntityRoot` when `y_sort_enabled = true`.
- Sortable stamps are **direct children** of the resolved Y-sort parent.
- Sortable metadata: `created_by`, `placement_route = sortable_2d_prop`, `y_sort_parent_path`.
- Icons refuse sortable route with clear status text.
- Default sortable `z_index = 0` unless Z Override is explicitly set (non-999999).

### Erase
- Only nodes with `created_by == "PVGamesObjectPaletteDock"`.
- Refuses GameplayRoot descendants and non-palette selection.
- UndoRedo restores erased node.

### Variation
- Applies to typed stamp, mouse place, brush, rectangle, scatter.
- Defaults: jitter/rotation/scale off; deterministic seed on.
- Positive-only random scale; invalid min/max normalized safely.

### Shapes
- **Stroke** — existing brush drag (one undo per stroke).
- **Rectangle Outline / Fill** — click-drag in viewport with Brush Mode on; one undo per operation.
- **Scatter Rectangle** — random points inside drag rect; count clamped to 500; deterministic when seed enabled.
- Esc / RMB cancels pending rectangle/scatter drag.

## Safety boundaries honored

- No collision / `StaticBody2D` / `Area2D` creation.
- No placement under `GameplayRoot`.
- No auto-create of `EntityRoot` or `VisualRoot/SortableWorld`.
- No mission mechanic or gameplay node authoring.
- No Taco / production scene saves.

## Validation run

| Check | Result | Notes |
|---|---|---|
| `git diff --check` | **PASS** | CRLF warnings only |
| Python simulated validator strings | **PASS** | All v2 markers present |
| Godot LSP `get_diagnostics` (dock) | **PASS** (after fix) | Fixed ternary type inference on typed-position stamp |
| Godot LSP `get_diagnostics` (validator) | **PASS** | No issues |
| `PVGamesObjectPaletteDockValidator` in editor | **NOT RUN** | Godot editor/MCP Pro offline in this session |
| Full manual scratch checklist | **NOT RUN** | Requires live Godot editor + viewport interaction |
| Sortable pilot scene manual QA | **NOT RUN** | Requires live editor on `Phase3JSortable2DPilot.tscn` |
| Taco dry-run | **NOT RUN** | Avoided unsaved production scene edits |

## Manual checks completed

- Static code audit of route resolution, erase guards, variation helpers, and shape point builders.
- Confirmed no collision node creation strings in dock script.
- Confirmed validator checks align with implemented symbols.

## Checks not run and why

- **Interactive editor QA** — Godot editor was not available for dock enable, viewport drag, undo redo, and sortable pilot stamping in this pass.
- **GdUnit4** — No dedicated palette v2 runtime tests exist; tool is `@tool` editor-only.
- **Kimi K2.6 review** — MCP tool descriptors present but advisory review not invoked this pass (implementation followed repo evidence directly).

## Kimi usage

Not used this session. Advisory second-brain review deferred; no secrets or repo dumps sent.

## Nowledge Mem handoff attempt

**Result:** Not available — no Nowledge Mem MCP server in enabled MCP set for this workspace session.

Handoff payload intended:
- Stage: Phase 3G complete (implementation + static validation)
- Files: dock + validator + docs + report
- Features: routes, sortable, erase, variation, rectangle/scatter
- Evidence: `git diff --check`, LSP clean, simulated validator pass
- Risks: manual editor QA still required
- Next: Mission Authoring Palette (Phase 2K) per dependency order

## Known risks / limitations

1. **Manual editor QA gap** — Full acceptance requires Jake to run scratch + sortable pilot checklist in Godot.
2. **No radius erase mode** — Only selected-node erase implemented (acceptable per task).
3. **No Y-sort contact preview overlay** — Deferred polish.
4. **Sortable in scenes without Y-sort parent** — Correctly refuses; user must author parent in scene first.
5. **Target Container dropdown** — Still visible for fixed routes; sortable route bypasses container folders by design.

## Rollback plan

1. Revert `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` to pre-Phase-3G commit/state.
2. Revert `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` v2 checks.
3. Revert doc status lines if needed.
4. No `project.godot` or scene changes to undo.

## Recommended next step

1. **Jake manual QA** — Run checklist in `PVGamesObjectPaletteDockTest.tscn` and `Phase3JSortable2DPilot.tscn` (fixed route stamp/undo, brush, jitter, shapes, erase, sortable direct-child placement).
2. **Proceed dependency gate Seventh** — Mission Authoring Palette (Phase 2K) once Phase 3G manual QA is signed off.
