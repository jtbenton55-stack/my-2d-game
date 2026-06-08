# Character Animation Mapper — Candidate Detector & Review Queue

**Date:** 2026-05-22
**Branch:** `new-feature-roadmap-branch`
**Packet:** Phase 3I editor-tool accelerator (no production promotion)

## Goal

Add semi-automated animation mapping acceleration: **Candidate Range Detector**, **Candidate Review Queue**, **Structured Naming Panel**, **mini contact strip**, **8-dir pattern assist**, and **keyboard shortcuts**. Automation produces `needs_review` candidates only; **Approve As Reviewed** is manual.

## Baseline git status

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M (unrelated files preserved)
?? addons/character_animation_mapper/
?? resources/character_animation_maps/
?? src/tools/editor/CharacterAnimationMapperValidator.gd
```

## Files inspected

- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`, `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-05-22_character_animation_large_review_canvas_report.md`
- `reports/ai/2026-05-22_character_animation_large_review_canvas_scroll_autodetect_fix_report.md`
- Existing mapper addon scripts and validator

## Files changed / added

| File | Role |
|------|------|
| `CharacterAnimationCandidateDetector.gd` | **NEW** — image-signature detection |
| `CharacterAnimationCandidateStrip.gd` | **NEW** — horizontal thumbnail strip |
| `CharacterAnimationMapperHelpers.gd` | Candidate map schema, naming, validation |
| `CharacterAnimationMapperDock.gd` | Sheet image cache, `approve_reviewed_animation`, APIs |
| `CharacterAnimationLargeReviewWindow.gd` | Review queue UI, naming panel, shortcuts |
| `CharacterAnimationMapperValidator.gd` | Static checks for new features |

## Architecture chosen

- **Detector** (`RefCounted`, preload only): scans `Image` from dock disk load; no network/external tools.
- **Candidates live in Large Review Window** (`_candidates` array), separate from dock `_animations` (reviewed working map).
- **Approve** calls `dock.approve_reviewed_animation()` → adds/replaces entry with `review_status: "reviewed"` only.
- **Save Candidate Map** writes separate JSON (`map_kind: "review_candidates"`); **Save Reviewed Map JSON** unchanged.
- **No auto-reviewed**: detector and `build_candidate_map_dict` force `needs_review`; approve is explicit.

## Detection heuristics implemented

Per frame 0..2499 on loaded sheet:

1. Downscale cell to 24×24 thumb; **alpha coverage**, color average, 16-bin histogram.
2. **Neighbor diff** = color + histogram distance (empty↔content = high diff).
3. **Active runs** = contiguous frames with coverage > threshold.
4. Long runs split at **MAX_CLIP_FRAMES (40)** at highest internal diff (prefer over-split).
5. **Still subclips** split where consecutive diff < STILL_DIFF.
6. Minimum clip length **3** frames; notes include `detected_by=image_signature; reason=…; start/end/count`.

Headless smoke on `character_01_parmida_reference_variant_sheet.png`: **114 candidates**, **0 reviewed**, ~**137 ms**.

## Candidate JSON schema

```json
{
  "schema_version": 1,
  "tool": "CharacterAnimationMapperDock",
  "map_kind": "review_candidates",
  "source_sheet": "res://.../character_01_parmida_reference_variant_sheet.png",
  "frame_width": 200,
  "frame_height": 200,
  "columns": 50,
  "rows": 50,
  "animations": [ { "animation_name": "candidate_001", "start_frame", "end_frame", "frames", "fps", "loop", "review_status": "needs_review", "notes", "row_column_ranges" } ]
}
```

Default path: `res://resources/character_animation_maps/character_01_parmida_reference_variant_sheet_candidate_ranges_v1.json` (derived from sheet basename).

## Review queue UX (Large Review Canvas)

Buttons: Detect Candidate Ranges, Load/Save Candidate Map, Previous/Next, Preview Candidate, Approve As Reviewed, Reject Candidate, Update Candidate Label, Apply Candidate To Canvas Selection.

Labels: `Candidate N / total`, detailed frame/row/col/status/notes.

## Structured naming

- **Directions** (exclusive toggles): toward, away, left, right, toward_left, toward_right, away_left, away_right.
- **Actions** (exclusive): idle, walk, run, sneak, attack, interact, use, pickup, hurt, death, sleep, sit, custom.
- **Variant** spinbox → `01`, `02`, …
- Auto-name: `<action>_<direction>_<variant>` (e.g. `walk_toward_01`).
- Action selects FPS/loop defaults (idle 6 loop, walk 10 loop, attack 12 no loop, etc.); manual override kept.
- Duplicate warning when approving if name exists in reviewed list.

## Approval / rejection

- **Approve**: builds reviewed entry with structured name + candidate `frames`; dock list updated; candidate marked `rejected` with `approved_elsewhere` note (stays in candidate file for traceability).
- **Reject**: `review_status: "rejected"`, notes append `rejected_by=user`.
- **Update Candidate Label**: metadata only in queue (not reviewed).
- Approved entries require **Save Reviewed Map JSON** in dock (e.g. `character_01_working_manual_map.json`).

## Preventing auto-reviewed

- Detector emits only `"review_status": "needs_review"`.
- `build_candidate_map_dict` downgrades any `reviewed` to `needs_review`.
- `validate_candidate_map_schema` fails if any candidate is `reviewed`.
- No code path marks detected candidates reviewed without **Approve As Reviewed**.

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | **PASS** — branch `new-feature-roadmap-branch`, unrelated dirty preserved |
| `validate_script` dock / large window / detector / strip | **PASS** |
| `CharacterAnimationMapperValidator` (Godot MCP) | **PASS** (`failures: []`) |
| Headless detection smoke (character_01 sheet) | **PASS** — 114 candidates, 0 reviewed, schema fields OK |
| GdUnit4 | **Not run** — editor tooling |
| Manual editor steps 1–17 | **Not run** by agent |
| Sandbox F6 playback after approve | **Not run** by agent |
| Screenshot | **Not captured** |

## Godot diagnostics

- All new/modified mapper scripts compile after `reload_project`.
- Removed `class_name` from `CharacterAnimationMapperHelpers` to avoid global class conflict in editor.

## Kimi K2.6

- **Pre:** Confirmed split candidate vs reviewed data, disk `Image` detection, no auto-approve.
- **Post:** Advisory on VRAM, editor-only paths, manual regression checklist (not re-run here).

## Known limitations

- Detection is heuristic — expects over-split candidates Jake merges/skips; not semantic action/direction classification.
- 8-dir **Suggest** button adds empty-frame placeholder candidates for manual mapping (conservative).
- Detection ~100–200 ms for 2500 frames in headless test; UI may show brief pause.
- Candidate file and reviewed map are separate — Jake must save both explicitly.
- C2B dock import still merges into dock list (legacy); new detector uses window queue only.

## Rollback

1. Remove `CharacterAnimationCandidateDetector.gd`, `CharacterAnimationCandidateStrip.gd`.
2. Revert `CharacterAnimationMapperHelpers.gd`, `CharacterAnimationLargeReviewWindow.gd`, `CharacterAnimationMapperDock.gd`, validator.
3. Delete candidate JSON files if undesired.

## Recommended next step

1. Load `character_01_parmida_reference_variant_sheet.png` → confirm 50×50.
2. Open Large Review Canvas → **Detect Candidate Ranges** → **Save Candidate Map**.
3. Navigate candidates, preview, approve one as `walk_toward_01`, **Save Reviewed Map JSON** to `character_01_working_manual_map.json`.
4. Generate Validation SpriteFrames → preview sandbox F6.
