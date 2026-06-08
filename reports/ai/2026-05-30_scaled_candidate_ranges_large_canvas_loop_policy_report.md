# Scaled Candidate Ranges, Large Canvas Scroll Fix & Loop Policy Report

**Date:** 2026-05-30
**Branch:** `new-feature-roadmap-branch`
**Phase:** 3I editor-tool (scaled automation + layout + loop policy)

## Goal

1. Add a non-destructive **scaled candidate** workflow (max 10 frames, guide-informed) beside the existing normal candidate workflow.
2. Fix **left-side scrolling** on the Large Review Canvas so all controls remain reachable.
3. Correct **loop flags only** in the 221-animation Parmida reviewed map, with timestamped backup first.

No production runtime wiring, player/Taco scenes, or reviewed-map field changes beyond `loop`.

## Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationScaledCandidateDetector.gd` | **New** — guide-informed scaled detection, max 10 frames |
| `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd` | Scaled map path, JSON load, scaled map build/validate |
| `addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd` | Scaled queue UI/handlers; left `VSplitContainer` + controls scroll |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Static checks for scaled workflow and left split layout |
| `src/tools/editor/character_animation_apply_loop_policy.py` | **New** — loop-only mutation with backup |
| `resources/character_animation_maps/character__working_manual_map.json` | **Loop fields only** (26 changes) |
| `resources/character_animation_maps/character__working_manual_map_before_loop_policy_20260530_225247.json` | **New** — timestamped backup |

## Files intentionally left untouched

- Production player/Taco scenes, autoloads, `project.godot`
- `CharacterAnimationCandidateDetector.gd` (normal `MAX_CLIP_FRAMES = 40` unchanged)
- Raw spritesheets under `assets/characters/...`
- PVGames kit files

## Backup path (loop policy)

`res://resources/character_animation_maps/character__working_manual_map_before_loop_policy_20260530_225247.json`

## New scaled candidate output path

`res://resources/character_animation_maps/character_01_parmida_reference_variant_sheet_scaled_candidate_ranges_v1.json`

(Resolved via `MAPPER_HELPERS.scaled_candidate_map_path_for_sheet()` when the Parmida sheet is loaded.)

## Scaled candidate count

**Not generated in this session** — Godot editor/MCP was offline, so `Detect Scaled Candidate Ranges` was not executed against the live sheet image. Detector implementation is in place; Jake should run detect once in-editor and save.

## Maximum scaled candidate frame length

**Hard cap: 10** (`SCALED_MAX_FRAMES := 10` in `CharacterAnimationScaledCandidateDetector.gd`). Save refuses any scaled entry with `frames.size() > 10`.

## Scaled candidates are all `needs_review`

Yes — every entry built with `review_status = "needs_review"`; load/save paths force non-reviewed; save refuses `reviewed`.

## Reviewed map still has 221 animations

**Confirmed** — Python parse before/after: `221` animations.

## Only loop fields changed in reviewed map

**Confirmed** — diff vs backup: `non_loop_field_diffs = 0`, `loop_diffs = 26`.

## Loop policy summary

| Policy | Stems |
|--------|-------|
| `loop = true` | `idle_*`, `walk_*`, `run_*`, `sneak_*`, `crouch_*`, `climb_*`, `sit_*` |
| `loop = false` | `death_*`, `dodge_*`, `jump_*`, `punch_*`, `roll_*`, `face_*`, `eating_*`, `slumped_*`, `hurt_*`, `attack_*`, `interact_*`, `use_*`, `pickup_*` |

**Ambiguous stems:** none in this map (all 221 names matched a known stem). **No silent guesses.**

### Loop counts before / after by action stem

| Stem | Before (true/false) | After (true/false) | Changed |
|------|---------------------|--------------------|---------|
| climb | 8/0 | 8/0 | 0 |
| crouch | 16/0 | 16/0 | 0 |
| death | 2/12 | 0/14 | **2** → false |
| dodge | 0/8 | 0/8 | 0 |
| eating | 7/0 | 0/7 | **7** → false |
| face | 0/24 | 0/24 | 0 |
| idle | 81/0 | 81/0 | 0 |
| jump | 8/0 | 0/8 | **8** → false |
| punch | 1/7 | 0/8 | **1** → false |
| roll | 8/0 | 0/8 | **8** → false |
| run | 8/0 | 8/0 | 0 |
| sit | 7/0 | 7/0 | 0 |
| slumped | 0/8 | 0/8 | 0 |
| sneak | 8/0 | 8/0 | 0 |
| walk | 8/0 | 8/0 | 0 |

**Total loop flags changed:** 26

## Existing systems reused

- `CharacterAnimationCandidateDetector.detect_from_image` — unchanged normal path; scaled detector calls it then re-chunks
- `CharacterAnimationMapperHelpers.build_animation_entry`, `finalize_candidate_entries`, `build_candidate_map_dict`
- Large Review Canvas preview, strip, grid selection, dock apply APIs
- Existing normal candidate buttons and handlers (untouched text/behavior)

## Systems added or modified

- **`CharacterAnimationScaledCandidateDetector`** — splits normal detection output into ≤10-frame chunks using guide map exact ranges for naming/size hints
- **Scaled Candidate Queue** UI — separate `_scaled_candidates` / `_scaled_candidate_index` / save path
- **Left layout** — `VSplitContainer`: top `ScrollContainer` (controls), bottom grid `ScrollContainer`
- **`character_animation_apply_loop_policy.py`** — backup + loop-only edits

## Architecture notes (anti-spaghetti)

- **Separation of concerns:** Normal detector file untouched; scaled logic in its own script with explicit constants (`SCALED_MAX_FRAMES`, `GUIDE_MAP_FILE`).
- **Separate state:** `_candidates` vs `_scaled_candidates`, separate save/load handlers, separate preview queue mode (`_preview_queue_mode`).
- **Shared presentation only:** `_present_scaled_candidate_entry` mirrors normal present but writes to scaled labels; no shared mutable candidate array.
- **Guide map read-only:** Loaded via `load_json_map`; never written by scaled workflow.
- **Loop mutation isolated:** One-off Python script; reviewed map edited only for `loop` booleans with verified diff.

## Kimi K2.6 MCP usage

**Used** (`ask_kimi_k2_6`, mode `regression_risk_review`). Sanitized context only (file names, constraints, architecture summary — no secrets or repo dumps).

**Adopted:**
- Keep normal/scaled arrays and save paths strictly separate (already implemented).
- Deep-copy via `finalize_candidate_entries` / `duplicate(true)` on load (already implemented).
- Defensive guide-map handling (empty guide aborts detect with status message).

**Not adopted in this pass:**
- `ReviewQueue` class refactor (would broaden scope).
- Virtualized grid pooling (existing grid unchanged).
- Kimi’s note about guide map keyed by animation name — our guide lookup uses exact frame range keys from reviewed entries, matching this project’s map shape.

## Safety confirmation

- No commits, pushes, or branch changes.
- No production scene/autoload/`project.godot` edits.
- Reviewed map backup created before loop edits.
- Only `loop` changed in reviewed map (verified).
- Scaled output is separate JSON; reviewed map not overwritten by scaled detect/save.
- All existing normal candidate button labels preserved.

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | **PASS** — branch unchanged; unrelated dirty preserved |
| Reviewed map parses, 221 animations | **PASS** (Python) |
| Backup exists and parses | **PASS** |
| Only `loop` fields changed | **PASS** (26 diffs, 0 non-loop diffs) |
| Scaled detector max 10 in source | **PASS** (static) |
| Normal candidate buttons present in source | **PASS** (validator strings + grep) |
| Godot MCP `validate_script` | **NOT RUN** — editor not connected |
| `CharacterAnimationMapperValidator.validate()` in editor | **NOT RUN** — editor offline |
| Manual Large Review Canvas UI test | **NOT RUN** — editor offline |
| Scaled detect count / saved JSON file | **NOT RUN** — requires in-editor detect |
| GdUnit4 | **Not applicable** — editor tooling |

## Known limitations

- Scaled candidate JSON not yet generated until Jake runs **Detect Scaled Candidate Ranges** in Godot.
- Left `VSplitContainer` split offset defaults to 400px; Jake may drag the splitter for preference.
- Scaled queue does not duplicate normal Start/End spinboxes (uses same canvas/strip presentation on select).
- Godot script compile not verified this session (MCP/CLI unavailable).

## Suggested next step

1. Open Godot → Character Animation Mapper → load Parmida sheet → **Open Large Review Canvas**.
2. Confirm left controls scroll (top pane) and grid scrolls independently (bottom pane).
3. **Detect Scaled Candidate Ranges** → verify all chunks ≤10 frames → **Save Scaled Candidate Map**.
4. Spot-check loop flags on a few `jump_*`, `eating_*`, `death_*` clips in the reviewed map or validation SpriteFrames preview.
5. Run `CharacterAnimationMapperValidator.gd` from the editor (File → Run) to confirm static checks.
