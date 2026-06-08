# Character Animation Large Review Canvas UX Polish Report

**Date:** 2026-05-22
**Phase:** 3I editor-tool UX polish (post visual QA)
**Branch:** `new-feature-roadmap-branch`

## Goal

Improve Large Review Canvas usability after Jake’s visual QA:

1. Whole window/panel background white or near-white (not only the 50×50 grid).
2. Candidate mini strip hover zoom preview with frame/row/column readout.
3. Clarify the 8-direction suggestion helper (rename + explanatory text + optional section).
4. Move moving-character preview to the left side above/beside the grid.
5. Move **Add / Update Animation From Selection** higher in the right panel.
6. Preserve candidate detector, review queue, start/end spinboxes, structured naming, reviewed-map flow, and sandbox preview.

No production runtime animation wiring, player/Taco scenes, or `project.godot` changes.

## Files inspected

- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-05-22_character_animation_candidate_detector_review_queue_report.md`
- `reports/ai/2026-05-22_character_animation_canvas_visibility_candidate_range_edit_report.md`
- `addons/character_animation_mapper/CharacterAnimationGridCanvas.gd`
- `addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd`
- `addons/character_animation_mapper/CharacterAnimationCandidateStrip.gd`
- `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd`
- `addons/character_animation_mapper/CharacterAnimationMapperDock.gd`
- `src/tools/editor/CharacterAnimationMapperValidator.gd`

## Files changed

| File | Change |
|------|--------|
| `CharacterAnimationLargeReviewWindow.gd` | Light panel shell, left **Candidate Preview**, strip hover preview UI, right-panel reorder, direction helper section, dark label styling |
| `CharacterAnimationCandidateStrip.gd` | `frame_hovered` / `frame_hover_cleared` signals, mouse-motion hover, thumb highlight |
| `CharacterAnimationMapperValidator.gd` | Static checks for panel bg, left preview, strip hover, direction helper clarity |

## Baseline branch and git status

**Branch:** `new-feature-roadmap-branch` (tracking `origin/new-feature-roadmap-branch`).

**Before/after:** Unrelated dirty files preserved (`project.godot`, PVGames palette, mission scenes, docs). Mapper addon remains under `?? addons/character_animation_mapper/`.

## Exact background/panel color changes

- Added `PANEL_BACKGROUND = Color(0.96, 0.96, 0.94, 1.0)` and `PANEL_TEXT_COLOR = Color(0.12, 0.12, 0.15, 1.0)`.
- Root content wrapped in `PanelContainer` with `StyleBoxFlat` using `PANEL_BACKGROUND`.
- Left/right `ScrollContainer` panels also use the same light stylebox.
- Labels/headings inside the Large Review Canvas use dark text overrides for readability on light panels.
- **50×50 grid** still uses `CANVAS_BACKGROUND` / red `GRID_LINE_COLOR` in `CharacterAnimationGridCanvas.gd` (unchanged).

## Exact candidate strip hover zoom behavior

**Strip (`CharacterAnimationCandidateStrip.gd`):**

- Emits `frame_hovered(global_index, row, column)` on mouse motion over a thumbnail.
- Emits `frame_hover_cleared()` when the pointer leaves the strip or gaps between thumbs.
- Highlights hovered thumb with a red border.

**Window (`CharacterAnimationLargeReviewWindow.gd`):**

- `_strip_hover_rect` — 168×168 `TextureRect` below the candidate strip.
- `_strip_hover_label` — shows `Hover: Frame N | row R | col C` while hovering.
- On clear, shows `Last hovered: Frame N | row R | col C` if any frame was hovered; otherwise placeholder text.
- Does not change candidate selection or `Preview Candidate` playback.

## Explanation of the renamed direction helper

- **Section:** `Optional Direction Pattern Helper`
- **Button:** `Suggest 8 Direction Candidates` (was `Suggest 8-dir needs_review clips`)
- **Helper text:** States it creates eight directional `needs_review` placeholder candidates with **empty frames**, does **not** mark anything reviewed, and frames must be mapped manually.
- **Behavior unchanged:** Still appends eight `needs_review` entries via `build_animation_entry` with `detected_by=direction_pattern_assist` notes; status message explicitly says nothing was auto-reviewed.

## Preview relocation details

- New left-side block at top of left column: heading **Candidate Preview**.
- `_candidate_preview_rect` — 240×240 primary animated preview.
- `_candidate_preview_info` — frame / row / column readout.
- **Play Preview** / **Stop Preview** moved to left under the preview (removed from bottom of right scroll).
- `_show_preview_frame` and `_on_preview_tick` now drive `_candidate_preview_rect` only.
- **Preview Candidate** still uses the same timer/frames pipeline; animation appears in the left preview area.

## Add/Update button relocation details

Right panel build order changed to:

1. **Structured Naming Panel** (auto-name, direction, action, variant)
2. **Animation Fields** (name, FPS, loop, review, notes)
3. **Add / Update Animation From Selection** + dock-save hint
4. **Candidate Review Queue** (detect/load/save, strip, hover zoom, approve/reject, start/end spins)
5. **Optional Direction Pattern Helper** (lower priority)

This places **Add / Update** directly under naming/field controls so it is visible without scrolling on a ~1280×860 window. Button text and `upsert_animation_from_canvas` behavior unchanged.

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | **PASS** — branch unchanged; unrelated dirty preserved |
| `validate_script` `CharacterAnimationLargeReviewWindow.gd` | **PASS** |
| `validate_script` `CharacterAnimationCandidateStrip.gd` | **PASS** |
| `CharacterAnimationMapperValidator.validate()` (preload in editor) | **PASS** — `failures: []` |
| GdUnit4 | **Not applicable** — editor-only UI |
| Manual editor checklist (steps 1–19) | **Not run** by agent |
| Screenshot of full light panel / hover zoom / left preview | **Not captured** |
| Sandbox F6 after approve | **Not run** by agent |

## Godot diagnostics result

- **PASS** for modified mapper scripts via `validate_script`.
- Full validator run via `preload(...).new().validate()` in editor: **PASS**.

## GdUnit4

**Not run** — no unit tests for editor dock layout UX.

## Kimi usage

**Not used** — focused UI packet; no advisory review requested.

## Known limitations

- Right panel still scrolls for long candidate queues; **Add / Update** is high but candidate controls remain below it.
- Strip hover preview draws up to 24 visible thumbs; hover only applies to drawn thumbs.
- Window chrome (title bar) may still follow editor theme; inner content panel is light.
- Manual visual QA (white panel vs grid, zoomed red lines, scroll-free Add button on Jake’s monitor) not verified by agent.

## Rollback plan

1. Revert `CharacterAnimationLargeReviewWindow.gd` UI build order and panel shell/preview relocation.
2. Revert `CharacterAnimationCandidateStrip.gd` hover signals.
3. Revert new validator `_require` lines in `CharacterAnimationMapperValidator.gd`.

## Recommended next step

Jake manual pass on `character_01_parmida_reference_variant_sheet.png`:

1. Open Large Review Canvas — confirm entire panel is light, grid still has red lines.
2. Load/detect candidates — hover strip thumbnails — confirm enlarged hover preview.
3. **Preview Candidate** — confirm animation in left **Candidate Preview**.
4. Confirm **Add / Update Animation From Selection** visible without scrolling.
5. Try **Suggest 8 Direction Candidates** — confirm helper text and `needs_review` only.
6. Edit start/end spins — confirm grid sync still immediate.
7. Optional full flow: save candidate map → approve → save reviewed map → validation SpriteFrames → sandbox.
