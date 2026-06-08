# Character Animation Canvas Visibility & Candidate Range Edit Report

**Date:** 2026-05-22
**Phase:** 3I editor-tool UX repair (visibility + editable candidate ranges)
**Branch:** `new-feature-roadmap-branch`
**Packet type:** Resume/completion of interrupted Cursor run (Jake closed agent window mid-task)

## Goal

Make the Character Animation Mapper **Large Review Canvas** easier to see and correct candidate frame ranges:

1. White/near-white grid background (not dark gray).
2. Red 50×50 grid lines for zoomed-in boundary visibility.
3. Editable **Candidate Start Frame** / **Candidate End Frame** spinboxes in the Candidate Review Queue.
4. Start/end edits regenerate linear `frames`, `row_column_ranges`, mini strip, details, and large-canvas selection immediately.
5. Candidates stay `needs_review` until **Approve As Reviewed**; persistence only via **Save Candidate Map**.

No production runtime animation wiring, player/Taco scenes, or `project.godot` changes.

## Files inspected

- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-05-22_character_animation_candidate_detector_review_queue_report.md`
- `reports/ai/2026-05-22_character_animation_large_review_canvas_scroll_autodetect_fix_report.md`
- `addons/character_animation_mapper/CharacterAnimationGridCanvas.gd`
- `addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd`
- `addons/character_animation_mapper/CharacterAnimationCandidateStrip.gd`
- `addons/character_animation_mapper/CharacterAnimationCandidateDetector.gd`
- `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd`
- `addons/character_animation_mapper/CharacterAnimationMapperDock.gd`
- `src/tools/editor/CharacterAnimationMapperValidator.gd`

## Files changed

| File | Change |
|------|--------|
| `CharacterAnimationGridCanvas.gd` | Near-white background, red grid lines, stronger selection/hover/label colors for white canvas |
| `CharacterAnimationMapperHelpers.gd` | `expand_contiguous_range`, `clamp_contiguous_frame_range`, `update_candidate_contiguous_range` |
| `CharacterAnimationLargeReviewWindow.gd` | Candidate Start/End `SpinBox` controls + sync/edit pipeline |
| `CharacterAnimationMapperValidator.gd` | Static checks for white bg, red grid, spinboxes, range-edit helper |

**Resume pass (this session):** No additional code edits. Prior interrupted run had already landed the full packet; this session audited sources, re-ran automated checks, and finalized this report.

## Resume / audit findings

| Requirement | Prior-run state | This pass |
|-------------|-----------------|-----------|
| White/near-white canvas (`CANVAS_BACKGROUND`) | Implemented | Verified in source |
| Red grid lines (`GRID_LINE_COLOR`) | Implemented | Verified in source |
| Selection/hover/labels readable on white | Implemented | Verified constants |
| Candidate Start/End `SpinBox` controls | Implemented | Verified in source |
| Spin limits `0..total_frames-1` via `_configure_candidate_frame_spin_limits()` | Implemented | Verified |
| Range edit → `frames`, `row_column_ranges`, strip, grid, details | Implemented via `_apply_candidate_frame_range_edit` + `update_candidate_contiguous_range` | Helper smoke **PASS** |
| `review_status` stays `needs_review` on edit | Implemented (helper preserves status) | Smoke **PASS** |
| Approve uses edited range; reject does not touch reviewed map | Implemented | Code review **PASS** |
| Validator static checks | Implemented | `validate()` **PASS** (`failures: []`) |
| Required report | Draft existed | Updated with resume validation |

## Baseline branch and git status

**Before/after:** `new-feature-roadmap-branch` (tracking `origin/new-feature-roadmap-branch`).

Unrelated dirty files preserved (`project.godot`, PVGames palette, mission scenes, docs, etc.). New/changed mapper files remain under `?? addons/character_animation_mapper/` and `?? src/tools/editor/CharacterAnimationMapperValidator.gd`.

## Exact visibility changes

### Large Review Canvas (`CharacterAnimationGridCanvas.gd`)

| Element | Before | After |
|---------|--------|-------|
| Sheet background | `Color(0.12, 0.12, 0.14, 1.0)` | `CANVAS_BACKGROUND` = `Color(0.96, 0.96, 0.94, 1.0)` |
| Grid lines | Gray `Color(0.35, 0.4, 0.5, 0.65)` | `GRID_LINE_COLOR` = `Color(1.0, 0.0, 0.0, 0.75)` |
| Selected cells | Light blue fill | Saturated blue `SELECTION_FILL` |
| Drag preview | Yellow tint | `DRAG_PREVIEW_FILL` (amber, higher alpha) |
| Hover outline | White | Red `HOVER_OUTLINE` |
| Frame index labels | Default | Dark `FRAME_LABEL_COLOR` for readability on white |

Applies to the **large 50×50 grid** only (grid canvas `_draw`), not the entire plugin chrome.

## Exact candidate start/end edit behavior

### UI (`CharacterAnimationLargeReviewWindow.gd`)

- **Candidate Start Frame** and **Candidate End Frame** `SpinBox` controls in Candidate Review Queue (below candidate index label).
- Min `0`, max `_total_frames - 1` (normally `2499`), step `1`.
- Disabled when no candidate is selected; populated on candidate navigation/load.

### Helper (`CharacterAnimationMapperHelpers.gd`)

- `update_candidate_contiguous_range(entry, start, end, columns, total_frames, edited_start)`:
  - Clamps indices to `0..total_frames-1`.
  - If `start > end`: when editing start, sets `end = start`; when editing end, sets `start = end`.
  - Rebuilds linear `frames` via `expand_contiguous_range`.
  - Rebuilds `start_frame`, `end_frame`, `row_column_ranges` via `build_animation_entry`.
  - Preserves `review_status` (uses `needs_review` only if status was empty).
  - Appends `manual_range_edit=true` to notes (does not auto-approve).
  - Does **not** write JSON; user must **Save Candidate Map**.

### On spin change

1. Updates `_candidates[_candidate_index]` in memory.
2. Calls `_present_candidate_entry()` → grid selection, mini strip, selection summary, preview first frame, detail label, spin resync.
3. Status message reminds: **Save Candidate Map to persist**.

## Selection synchronization

```
SpinBox change
  → _apply_candidate_frame_range_edit()
  → MAPPER_HELPERS.update_candidate_contiguous_range()
  → _present_candidate_entry()
       → _grid.set_selected_frames(frames)
       → _candidate_strip.set_frames(frames)
       → _selection_summary_label updated
       → _sync_candidate_frame_spins()
       → _refresh_candidate_labels()
```

- **Preview Candidate** reads current `_candidates[_candidate_index]` (edited range).
- **Approve As Reviewed** uses `frames_from_entry` on current candidate (edited range).
- **Reject Candidate** only marks queue entry rejected; reviewed map untouched until approve + dock save.

## Candidates vs reviewed map

- Edits apply only to `_candidates` in the Large Review Window.
- Reviewed dock list / reviewed JSON unchanged until **Approve As Reviewed** + **Save Reviewed Map JSON** in main dock.
- Candidate JSON separate (`*_candidate_ranges_v1.json`); **Save Candidate Map** persists edits.

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | **PASS** — `new-feature-roadmap-branch`; unrelated dirty preserved; no new mapper edits this session |
| `validate_script` `CharacterAnimationGridCanvas.gd` | **PASS** |
| `validate_script` `CharacterAnimationLargeReviewWindow.gd` | **PASS** |
| `validate_script` `CharacterAnimationMapperHelpers.gd` | **PASS** |
| `validate_script` `CharacterAnimationMapperValidator.gd` (path-only) | **FAIL** — known `class_name` / `EditorScript` isolation quirk when compiled alone |
| `CharacterAnimationMapperValidator.validate()` via `preload(...).new().validate()` | **PASS** — `pass_fail_partial: PASS`, `failures: []` |
| Helper smoke: start 10→11, end 20→19, status `needs_review`, 9 frames | **PASS** — MCP `execute_editor_script` |
| GdUnit4 | **Not applicable** — editor-only tooling |
| Manual editor checklist (steps 1–20) | **Not run** by agent |
| Screenshot of white canvas / red grid | **Not captured** |
| Sandbox F6 after approve | **Not run** by agent |

## Godot diagnostics result

- **PASS** for mapper plugin scripts via `validate_script` (grid, window, helpers).
- Validator compiles and runs when loaded with `preload("res://src/tools/editor/CharacterAnimationMapperValidator.gd").new()`; isolated `validate_script` on the validator path still fails (global `class_name` quirk).
- Editor log contains unrelated project errors (missions, tileset, other validators); none block mapper script compile.

## GdUnit4

**Not run** — no unit tests for editor dock UX; changes are editor-plugin UI only.

## Kimi usage

**Not used** — focused UI repair; no advisory review requested.

## Known limitations

- Validator must be run in-editor (File → Run on `CharacterAnimationMapperValidator.gd`) or via inline file-content checks; headless `EditorScript.new()` fails in MCP ephemeral scripts.
- Spinbox clamp when `start > end` adjusts the opposite bound (start edit pulls end up; end edit pulls start down) — does not show a modal error.
- `manual_range_edit=true` appended to notes on first edit (traceability only).
- No autosave to candidate JSON on spin change (explicit **Save Candidate Map** required).

## Rollback plan

1. Revert `CharacterAnimationGridCanvas.gd` color constants and `_draw` colors to prior dark gray / gray grid.
2. Revert `CharacterAnimationMapperHelpers.gd` contiguous-range helpers.
3. Revert `CharacterAnimationLargeReviewWindow.gd` spinboxes and `_apply_candidate_frame_range_edit` / `_present_candidate_entry`.
4. Revert new validator `_require` lines in `CharacterAnimationMapperValidator.gd`.

## Recommended next step

Jake manual pass on `character_01_parmida_reference_variant_sheet.png`:

1. Open Large Review Canvas — confirm white background and red grid at zoom.
2. Detect/load candidates — edit Start/End — confirm immediate canvas highlight + preview.
3. Save Candidate Map → reload → approve one edited candidate → Save Reviewed Map → Generate Validation SpriteFrames → Preview Sandbox.

Optional: capture one zoomed screenshot for docs.

## How to edit a candidate start/end frame (operator)

1. Load sheet in **Character Animation Mapper** dock → **Open Large Review Canvas**.
2. **Detect Candidate Ranges** or **Load Candidate Map**.
3. Select a candidate in the queue — **Candidate Start Frame** / **Candidate End Frame** spinboxes enable and show current range.
4. Adjust start or end (clamped `0..2499`, `start <= end`); large grid highlight, mini strip, and details update immediately.
5. **Preview Candidate** to play the edited range.
6. **Save Candidate Map** to persist (no autosave on spin change).
7. **Approve As Reviewed** only when ready; then **Save Reviewed Map JSON** in the main dock.

Nothing in this packet promotes animations to production player/Taco scenes.
