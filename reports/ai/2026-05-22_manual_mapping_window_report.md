# Manual Mapping Window Report

**Date:** 2026-05-22
**Project:** Character Animation Mapper (Godot 4.6.2 editor plugin)

## Goal

Add a focused pop-out **Manual Mapping Window** for manual animation mapping: structured naming, zoomable red-outlined frame grid with click/drag selection, start/end frame controls, selected-frame strip with hover zoom, animation preview, and **Add / Update Animation From Selection** wired back to the main dock — without replacing or destabilizing the existing Large Review Canvas or normal candidate workflow.

## Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd` | **New** — focused manual mapping pop-out |
| `addons/character_animation_mapper/CharacterAnimationMapperDock.gd` | Preload, window instance, **Open Manual Mapping Window** button, open handler, dock sync on range-list selection |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Static checks for new window, dock button, and absence of candidate detection in manual window |

## Files intentionally left untouched

- `CharacterAnimationLargeReviewWindow.gd` — no behavioral changes
- `CharacterAnimationGridCanvas.gd` — reused as-is
- `CharacterAnimationCandidateStrip.gd` — reused as-is
- `CharacterAnimationMapperHelpers.gd` — reused as-is
- `CharacterAnimationCandidateDetector.gd`
- `project.godot`, production player/Taco scenes, autoloads
- `resources/character_animation_maps/character__working_manual_map.json` — not modified during validation
- Raw spritesheet PNG assets

## Existing systems reused

| System | Role in manual window |
|--------|----------------------|
| `CharacterAnimationGridCanvas.gd` | Full-sheet frame grid: zoom, red grid lines, hover outline, REPLACE/ADD/REMOVE drag selection |
| `CharacterAnimationCandidateStrip.gd` | Selected-frame thumbnails, hover zoom signals, click-to-preview |
| `CharacterAnimationMapperHelpers.gd` | `DIRECTIONS`, `ACTIONS`, `build_structured_name`, `action_defaults`, `build_animation_entry`, `selection_summary`, `clamp_contiguous_frame_range`, `expand_contiguous_range`, `sorted_frames_array` |
| `CharacterAnimationMapperDock.gd` | `get_large_review_state()`, `upsert_animation_from_canvas()`, `get_map_output_path()`, `_on_large_review_animation_updated()` refresh path |

## Systems added or modified

### Added: `CharacterAnimationManualMappingWindow.gd`

Editor `Window` with:

- **Left column:** status, zoom/mode/clear, scrollable grid, start/end frame spinboxes, selected frame strip + hover zoom, animation preview + Play/Stop
- **Right column (scroll):** structured naming panel, animation fields, Add/Update button

### Modified: dock integration

- Button: **Open Manual Mapping Window** (alongside existing **Open Large Review Canvas**)
- Handler: `_on_open_manual_mapping_window()` — same lifecycle pattern as large review (editor base control parent, `setup_from_dock`, `popup_centered_ratio`)
- Selection sync when picking animations in dock range list while manual window is visible
- Generic upsert status message (no longer Large-Review-only wording)

## New button / window path

- **Button:** Character Animation Mapper dock → **Open Manual Mapping Window**
- **Window script:** `res://addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd`
- **Window title:** Manual Animation Mapping

## How selection works

1. **Grid click/drag** — `CharacterAnimationGridCanvas` emits `selection_changed` with selected global frame indices (sorted).
2. **Selection modes** — Replace (default), Add, Remove via option button (maps to grid `selection_mode` enum).
3. **Start/End spinboxes** — Show min/max of current selection; editing either spinbox expands a **contiguous** range via `clamp_contiguous_frame_range` + `expand_contiguous_range` and pushes back to the grid.
4. **Strip** — `set_frames(selected)` on every selection change; order follows grid sorted output.
5. **Non-contiguous ADD selections** — Supported on grid; start/end show min/max; editing start/end collapses to contiguous range (same pattern as large review candidate range edits).

## How preview works

- **Strip hover** — `frame_hovered` → 126×126 `AtlasTexture` preview + row/col/frame readout
- **Animation preview** — Play Preview uses selected frames, current FPS spinbox interval, loop checkbox; Stop Preview halts timer
- **Atlas regions** — Built from loaded sheet + frame width/height + columns (consistent with existing mapper)

## How add/update writes back to the dock

1. Manual window gathers selected frames + form fields.
2. `MAPPER_HELPERS.build_animation_entry(...)` builds schema-compatible entry.
3. `dock.upsert_animation_from_canvas(entry)` — add or replace by `animation_name` in in-memory `_animations`.
4. Dock refreshes range list and export readout; does **not** write JSON.
5. User persists via existing dock **Save Reviewed Map JSON** flow.
6. `animation_updated` signal triggers same refresh handler as Large Review Canvas.

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | Run; new/edited files under `addons/character_animation_mapper/` and validator |
| Static Python validator mirror | **PASS** — dock button, preload, handler, manual window required strings, no candidate detection |
| Godot LSP diagnostics | **No linter errors** on edited scripts |
| Godot MCP Pro `validate_script` | **Not run** — editor not connected |
| In-editor manual test (Parmida sheet + working map) | **Not run** — Godot editor unavailable in session |
| GdUnit4 tests | **Not run** — no mapper-specific unit tests identified |
| Reviewed 221-animation map | **Unmodified** |

## Godot editor/runtime checks performed

- None (MCP Pro connection error: editor not connected).

## Checks that could not be run

1. Godot script compile via MCP Pro
2. Load Parmida sheet + `character__working_manual_map.json` in dock
3. Open manual window and verify grid render, zoom, click/drag selection
4. Start/end spinbox bidirectional sync
5. Strip hover zoom and Play/Stop preview
6. Temporary add/update animation test
7. Confirm Large Review Canvas still opens
8. GdUnit4 regression suite

**Recommended manual verification in editor:**

1. Enable Character Animation Mapper plugin
2. Load sheet: `res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_01_parmida_reference_variant_sheet.png`
3. Load map: `character__working_manual_map.json`
4. Click **Open Manual Mapping Window**
5. Exercise selection, preview, add/update with a clearly temporary animation name; save JSON only if intentionally testing persistence

## Kimi K2.6 MCP usage

**None.** Architecture reuses established dock/grid/strip/helpers patterns with no significant coupling risk.

## Safety confirmation

- Stayed inside repository workspace
- No git commit/push/stage/branch changes
- No `project.godot`, production scenes, autoloads, or runtime player changes
- No reviewed map JSON overwrite
- No JSON schema changes
- Existing Large Review Canvas code untouched
- Normal candidate detection workflow untouched
- No scaled candidate code reintroduced

## Known limitations

1. Start/end spinboxes edit **contiguous** ranges only; non-contiguous multi-select from ADD mode is visible on grid/strip but collapsed if start/end are edited.
2. Godot MCP/editor offline — runtime UX not verified this session.
3. Manual window does not include **Apply Selection To Dock** as a separate action; Add/Update upsert already syncs dock fields (same as large review add/update path).
4. Direction/action structured naming on open does not reverse-parse existing animation name from dock (name field copied from dock; direction/action buttons stay at defaults until user clicks them).

## Suggested next step

1. Open Godot editor and run the manual verification checklist above.
2. If Jake wants direction/action buttons to auto-match a loaded animation name, add a small name-parse helper in `CharacterAnimationMapperHelpers` (low-risk follow-up).
3. Optional: add `RunCharacterAnimationMapperValidator.gd` runner script if headless CI validation is desired (only `.uid` exists today).
