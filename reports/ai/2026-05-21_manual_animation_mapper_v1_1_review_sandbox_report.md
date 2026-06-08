# Phase 3I v1.1 — Manual Animation Mapper Review Candidates + Sandbox Report

**Date:** 2026-05-21
**Branch:** `new-feature-roadmap-branch`
**Packet type:** Editor/art-tool validation (no production promotion)

## 1. Goal

Improve Manual Animation Mapper workflow so Jake can:

1. Import C2B/FIX1 diagnostic clips as **`needs_review` candidates** (never auto-reviewed).
2. Preview **validation-only SpriteFrames** in a dedicated sandbox scene without touching player/Taco/runtime.

## 2. Branch and baseline git status

**Before:** `new-feature-roadmap-branch` with Phase 3I v1 mapper (untracked), prior tooling dirty state.

**After (this packet):**

| Path | Status |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationMapperDock.gd` | Modified |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Modified |
| `src/tools/editor/CharacterAnimationMapperPreviewSandbox.gd` | **New** |
| `scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn` | **New** |
| `resources/character_animation_maps/parmida_review_candidates_v1.json` | **New** (validation artifact) |
| `reports/ai/2026-05-21_manual_animation_mapper_v1_1_review_sandbox_report.md` | **New** |

**Not modified:** `project.godot`, `player.tscn`, `Player.gd`, Taco scenes, autoloads, raw kit PNGs, diagnostic `parmida_player_spriteframes_0mc2b.tres`, existing C2B classifier sandbox scenes.

## 3. Files inspected

- Phase 3I v1 report and mapper addon files
- `docs/reports/character_animation_c2b_fix1/recommended_animation_clips.json`
- `docs/reports/character_animation_c2b_fix1/action_segments.json`
- `docs/DECISIONS.md`, roadmap/blueprint tooling sections
- Existing `CharacterAnimationContextClassifierSandbox_0MC2B_FIX1` (reference only; not modified)

## 4. Files changed

See section 2.

## 5. Existing systems/assets reused

| Asset | Use |
|-------|-----|
| `recommended_animation_clips.json` | Primary candidate import source (10 clips) |
| `action_segments.json` | Fallback if clips file missing |
| `parmida_manual_preview_spriteframes.tres` | Sandbox default preview resource |
| Character Animation Mapper v1 dock/plugin | Extended in place |

## 6. Candidate import behavior

**UI added:**

- `Import C2B Candidates as Needs Review`
- `Save Candidate Map JSON`
- Hint: classifier ranges are suggestions only; always `needs_review`

**Logic:**

- Reads `res://docs/reports/character_animation_c2b_fix1/recommended_animation_clips.json` first; falls back to `action_segments.json`.
- Maps each clip to `needs_review_{action_label}` (e.g. `needs_review_walk`, **not** `walk_best` as reviewed truth).
- Sets `review_status = "needs_review"` always.
- Notes include `source=character_animation_c2b_fix1; diagnostic_label=...; requires_manual_review`.
- Uses diagnostic grid columns **50** when sheet not loaded; uses loaded sheet columns when sheet is loaded.
- Skips candidates only when a sheet is loaded and `end_frame` exceeds sheet bounds.
- `Save Candidate Map JSON` writes `parmida_review_candidates_v1.json` and refuses if any entry is `reviewed`.

**Validation artifact generated (MCP editor script):**

- `resources/character_animation_maps/parmida_review_candidates_v1.json` — **10** candidates, **0** reviewed.

## 7. Sandbox scene behavior

**Scene:** `res://scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn`
**Script:** `res://src/tools/editor/CharacterAnimationMapperPreviewSandbox.gd`

- Tool/test scene only (hideout/tools); not referenced by MainMenu/player/Taco/autoloads.
- `AnimatedSprite2D` loads validation SpriteFrames from exported path (default `generated_preview/parmida_manual_preview_spriteframes.tres`).
- UI: path label, status/warning, animation `OptionButton`, Play/Stop, frame/fps/loop readout.
- Missing resource: shows warning, does not crash.
- Skips empty `default` animation when other anims exist.

**Runtime playtest (MCP):**

- Scene played successfully.
- Loaded `walk` animation, **12 frames**, `playing: true`.
- Status: "Validation sandbox — not for production."

## 8. Safety boundaries preserved

- Output maps/SpriteFrames remain under `resources/character_animation_maps/`
- `_is_safe_output_path()` unchanged
- No production scene/script edits
- Diagnostic classifier outputs are never auto-marked `reviewed`
- SpriteFrames export still requires explicit `reviewed` status

## 9. Exact output paths

| Output | Path |
|--------|------|
| Candidate map | `res://resources/character_animation_maps/parmida_review_candidates_v1.json` |
| Validation SpriteFrames | `res://resources/character_animation_maps/generated_preview/parmida_manual_preview_spriteframes.tres` |
| Sandbox scene | `res://scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn` |

## 10. Validator updates

`CharacterAnimationMapperValidator.gd` now checks:

- Import buttons/strings and needs_review hint
- `needs_review_` naming + `diagnostic_label=` notes
- `recommended_animation_clips.json` reference
- Sandbox scene/script + `AnimatedSprite2D` + `generated_preview` default path
- No production player/Taco references in sandbox script
- Export readout + open sandbox button

**Note:** `validate_script` may report parse error for `class_name CharacterAnimationMapperValidator` if a stale global class is cached in the editor. On-disk validator runs **PASS** via `validate()` (0 failures).

## 11. Tests/checks

| Check | Result |
|-------|--------|
| Git status/diff | Recorded |
| `validate_script` Dock | **PASS** |
| `validate_script` Sandbox | **PASS** |
| `validate_script` Validator | **FAIL** (class_name hides global script class — editor cache) |
| `CharacterAnimationMapperValidator.validate()` | **PASS** |
| Candidate JSON generation | **PASS** — 10 candidates, 0 reviewed |
| Sandbox `play_scene` | **PASS** — `walk` 12 frames playing |
| MainMenu smoke | **Started** via MCP (not fully exercised after sandbox stop) |
| GdUnit4 | **Not run** — no editor-tool unit tests |
| Godot DAP | **Not used** |

## 12. Godot MCP Pro validation

- Scripts compile (dock + sandbox)
- Sandbox runtime: SpriteFrames load + animation play confirmed
- Candidate map saved via editor script with correct review statuses

## 13. Godot LSP diagnostics

**No linter errors** on modified `.gd` files (Cursor).

## 14. Manual/editor validation (Jake)

1. Enable **Character Animation Mapper** plugin (if not already).
2. Open dock → **Load Sheet** (composite PNG).
3. **Import C2B Candidates as Needs Review** → confirm list entries are `needs_review_*`.
4. **Save Candidate Map JSON** → `parmida_review_candidates_v1.json`.
5. Mark one range `reviewed` manually → **Generate Validation SpriteFrames**.
6. **Open Preview Sandbox Scene** → Run (F6) → switch animations / Play.

## 15. GdUnit4

**Not run** — editor-only tooling; no dedicated test suite.

## 16. MainMenu smoke

**Limited:** `play_scene` MainMenu invoked; no new parse errors observed during session. Full navigation not exercised.

## 17. Kimi K2.6 MCP

**Not used.**

## 18. Safety confirmation

- Stayed inside repo; no secrets accessed
- Raw PVGames kit unchanged
- Production player/Taco unchanged
- No git history changes

## 19. Known limitations

- C2B classifier grid uses **50 columns** on full diagnostic grid; bundled composite sheet may be **12 columns** — import may skip out-of-bounds clips when sheet loaded; load full sheet or import before sheet load for all 10 clips.
- `action_segments.json` fallback imports many segments (not exercised in validation artifact; clips file present).
- Missing SpriteFrames graceful path not playtested via MCP instantiate (runtime default path works).
- Validator `class_name` may need editor restart after first add.

## 20. Rollback plan

1. Revert `addons/character_animation_mapper/CharacterAnimationMapperDock.gd`
2. Delete sandbox `.tscn` / `.gd`
3. Revert validator
4. Delete `parmida_review_candidates_v1.json` if test-only
5. Delete this report

## 21. Recommended next step

Jake playtest: import candidates → manually review idle/walk rows on correct sheet grid → save reviewed map → generate preview SpriteFrames → sandbox play all reviewed anims. **Separate future packet** for production player promotion only after review sign-off.
