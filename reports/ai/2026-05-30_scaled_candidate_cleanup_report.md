# Scaled Candidate Workflow Cleanup Report

**Date:** 2026-05-30
**Branch:** `new-feature-roadmap-branch`

## Goal

Safely remove the failed **scaled candidate ranges** implementation added in the prior task, while preserving the working Character Animation Mapper, normal candidate workflow, Large Review Canvas (including left-side scroll fix), loop-corrected reviewed map, and backup.

## Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd` | Removed scaled queue UI, state, handlers, preload; kept `_left_split` VSplitContainer scroll layout |
| `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd` | Removed scaled-only helpers (`scaled_candidate_map_path_for_sheet`, `load_json_map`, `GUIDE_REVIEWED_MAP_PATH`, `build_scaled_candidate_map_dict`, `validate_scaled_candidate_map`) |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Removed scaled detector/UI validator checks; kept `_left_split` scroll layout check |

## Files deleted

| File | Reason |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationScaledCandidateDetector.gd` | Failed scaled workflow detector |
| `addons/character_animation_mapper/CharacterAnimationScaledCandidateDetector.gd.uid` | Godot UID for deleted script |
| `src/tools/editor/character_animation_apply_loop_policy.py` | One-shot loop script no longer needed (corrections already applied) |

## Files intentionally preserved

- `resources/character_animation_maps/character__working_manual_map.json` — **unchanged in this cleanup**
- `resources/character_animation_maps/character__working_manual_map_before_loop_policy_20260530_225247.json` — loop backup
- `reports/ai/2026-05-30_scaled_candidate_ranges_large_canvas_loop_policy_report.md` — audit history
- All other Character Animation Mapper addon files (normal detector, grid canvas, strip, dock, etc.)
- No scaled candidate JSON existed in repo (nothing to delete)

## Confirmation: reviewed map preserved

- **221 animations** — verified via Python parse
- **Not modified** during this cleanup pass

## Confirmation: loop corrections preserved

Spot-check after cleanup:

| Stem | Expected | Actual |
|------|----------|--------|
| jump | false | `{False}` |
| eating | false | `{False}` |
| death | false | `{False}` |
| roll | false | `{False}` |
| walk | true | `{True}` |
| idle | true | `{True}` |

## Confirmation: backup map preserved

`character__working_manual_map_before_loop_policy_20260530_225247.json` — **exists**

## Confirmation: normal candidate workflow remains

Static grep confirms these controls/handlers still present in `CharacterAnimationLargeReviewWindow.gd`:

- Detect Candidate Ranges / Load Candidate Map / Save Candidate Map
- Previous Candidate / Next Candidate / Preview Candidate
- Approve As Reviewed / Reject Candidate
- Update Candidate Label / Apply Candidate To Canvas Selection
- Candidate Start Frame / Candidate End Frame spinboxes (via `_build_candidate_queue_ui`)

## Confirmation: scaled candidate workflow removed

Post-cleanup repo search for `ScaledCandidate`, `scaled_candidate`, `Detect Scaled`, `CharacterAnimationScaledCandidate`, `_scaled_` under `addons/character_animation_mapper` and validator: **no matches**.

## Left-side scroll fix preserved

`VSplitContainer` (`_left_split`) with top controls `ScrollContainer` and bottom grid `ScrollContainer` — **unchanged**.

## Kimi K2.6 MCP usage

**Not used** — local inspection was sufficient to separate scaled-only code from preserved mapper behavior.

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | **PASS** — no commits; unrelated dirty preserved |
| Scaled term search (post-cleanup) | **PASS** — no active references |
| Normal candidate terms present | **PASS** |
| Reviewed map parses, 221 anims | **PASS** |
| Loop corrections intact | **PASS** (spot-check) |
| Backup map exists | **PASS** |
| Godot MCP `validate_script` | **NOT RUN** — editor not connected |
| Manual Large Review Canvas open test | **NOT RUN** — editor offline |

## Known limitations

- GDScript compile not verified via Godot this session (MCP offline).
- Jake should open Large Review Canvas once to confirm no missing-preload errors and that scaled buttons are gone.

## Suggested next step

1. Open Godot → Character Animation Mapper → load Parmida sheet → **Open Large Review Canvas**.
2. Confirm no parse errors; scaled candidate buttons absent; normal candidate buttons work.
3. Confirm left controls scroll (top split pane) and grid scroll/zoom (bottom split pane).
4. Optionally run `CharacterAnimationMapperValidator.gd` from the editor.
