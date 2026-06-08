# Character Animation Large Review Canvas Layout Compaction Report

**Date:** 2026-05-22
**Phase:** 3I editor-tool layout compaction (no-scroll core workflow)
**Branch:** `new-feature-roadmap-branch`

## Goal

Reorganize the Large Review Canvas so core review tools are visible together without scrolling (~1280×860):

- Smaller left **Candidate Preview** (~25%).
- **Candidate Review Queue**, strip thumbnails, and strip hover zoom on the **left**, above the 50×50 grid.
- **Structured Naming Panel** and **Add / Update Animation From Selection** on the **right**, high and without a scroll wrapper.

No production runtime wiring, player/Taco scenes, or `project.godot` changes.

## Files inspected

- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-05-22_character_animation_large_review_canvas_ux_polish_report.md`
- `reports/ai/2026-05-22_character_animation_canvas_visibility_candidate_range_edit_report.md`
- `reports/ai/2026-05-22_character_animation_candidate_detector_review_queue_report.md`
- `addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd`
- `addons/character_animation_mapper/CharacterAnimationGridCanvas.gd`
- `addons/character_animation_mapper/CharacterAnimationCandidateStrip.gd`
- `src/tools/editor/CharacterAnimationMapperValidator.gd`

## Files changed

| File | Change |
|------|--------|
| `CharacterAnimationLargeReviewWindow.gd` | Left-column layout compaction, smaller preview, queue/strip/hover on left, right panel without scroll |
| `CharacterAnimationMapperValidator.gd` | Static checks for left placement, 180×180 preview, strip/hover helper |

## Baseline branch and git status

**Branch:** `new-feature-roadmap-branch`.

**Before/after:** Unrelated dirty files preserved. Mapper addon under `?? addons/character_animation_mapper/`.

## Exact layout changes

### Left column (top → bottom, above grid)

1. **Candidate Preview** — 180×180 (was 240×240), Play/Stop adjacent.
2. **Candidate Review Queue** — compact button rows, shortened map label with tooltip.
3. **Candidate strip + hover zoom** — side-by-side row (`_build_left_candidate_strip_and_hover`): strip scroll (64px tall) + 126×126 hover preview.
4. Status line + zoom/selection tools (single-row selection summary + hover).
5. **50×50 grid** scroll area (expand fill).

### Right column (no `ScrollContainer` wrapper)

1. **Structured Naming Panel** (auto-name, direction, action, variant, custom stem).
2. FPS / Loop / Review / Notes grid + **Add / Update Animation From Selection** + short hint.
3. **Optional Direction Pattern Helper** (lower priority; may extend below fold on small monitors).

### Removed / relocated

- Long shortcut instructions block removed from left (saves vertical space).
- Candidate queue, strip, and hover removed from right panel.
- Right `ScrollContainer` removed so naming + Add/Update are direct children of the split.

## Candidate Preview size change

| Before | After |
|--------|-------|
| `Vector2(240, 240)` | `Vector2(180, 180)` (~25% smaller) |

Playback still uses `_candidate_preview_rect` via `_show_preview_frame` / `_on_preview_tick`.

## Which controls moved left

- Entire **Candidate Review Queue** section (detect/load/save, nav, preview, approve/reject, label update, apply to canvas, index, start/end spins, details).
- **Candidate strip** thumbnails.
- **Strip hover zoom** preview + label.

## Which controls stayed right

- **Structured Naming Panel** (direction/action/variant/custom).
- **Animation fields** (name, FPS, loop, review, notes).
- **Add / Update Animation From Selection**.
- **Optional Direction Pattern Helper**.

## How no-scroll core workflow was addressed

- Vertical budget saved by: smaller preview, compact queue rows (`_add_compact_button`), side-by-side strip/hover, removed instruction block, smaller fonts (11–13px) on dense labels, shortened map path display, combined selection summary + hover on one row.
- Right panel no longer scrolls independently — core naming + Add/Update appear at top of right column.
- Grid retains `SIZE_EXPAND_FILL` so it uses remaining left height; top rows of red grid remain visible when window is ~1280×860.

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | **PASS** — branch unchanged; unrelated dirty preserved |
| `validate_script` `CharacterAnimationLargeReviewWindow.gd` | **PASS** |
| `CharacterAnimationMapperValidator.validate()` | **PASS** — `failures: []` |
| GdUnit4 | **Not applicable** — editor UI layout only |
| Manual editor checklist (steps 1–18) | **Not run** by agent |
| Screenshot at 1280×860 showing all core controls | **Not captured** |

## Godot diagnostics result

- **PASS** — `validate_script` on modified window; full validator via editor preload.

## GdUnit4

**Not run** — no unit tests for dock layout.

## Kimi usage

**Not used**.

## Known limitations

- On monitors shorter than ~860px or with large editor UI scale, optional direction helper or bottom grid area may still require scrolling/window resize.
- Compact queue uses smaller buttons/fonts; full button text unchanged but rows may wrap on very narrow left column.
- Selection tool rows remain above grid (required for zoom/pan workflow) and consume some vertical space.
- Agent did not visually confirm all seven core regions visible simultaneously on Jake’s display.

## Rollback plan

1. Revert `CharacterAnimationLargeReviewWindow.gd` `_build_ui` order and right `ScrollContainer`.
2. Restore 240×240 preview and 168×168 hover sizes.
3. Revert validator layout checks.

## Recommended next step

Jake manual pass on `character_01_parmida_reference_variant_sheet.png` at ~1280×860:

1. Confirm left stack: preview → queue → strip/hover → grid top visible together with right naming + Add/Update.
2. Detect/load candidates, hover strip, preview candidate on left, edit start/end, approve one if desired.
3. Capture one screenshot for docs if layout looks correct.
