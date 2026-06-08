# Apply Reviewed Animation Map to Manual 5-Pack Characters Report

**Date:** 2026-05-22

## Goal

Clone the fully reviewed Parmida manual animation map (591 animations) to the other four manual 5-pack character sheets, generating per-character validation map JSONs and SpriteFrames resources without touching production runtime wiring.

## Files changed

**New per-character artifacts**
- `resources/character_animation_maps/character_02_neon_runner_manual_animation_map.json`
- `resources/character_animation_maps/character_03_cyber_tech_manual_animation_map.json`
- `resources/character_animation_maps/character_04_street_bruiser_manual_animation_map.json`
- `resources/character_animation_maps/character_05_nocturne_guard_manual_animation_map.json`
- `resources/character_animation_maps/generated_preview/character_02_neon_runner_preview_spriteframes.tres` (~563 KB)
- `resources/character_animation_maps/generated_preview/character_03_cyber_tech_preview_spriteframes.tres` (~563 KB)
- `resources/character_animation_maps/generated_preview/character_04_street_bruiser_preview_spriteframes.tres` (~563 KB)
- `resources/character_animation_maps/generated_preview/character_05_nocturne_guard_preview_spriteframes.tres` (~563 KB)

**New/updated tooling**
- `src/tools/editor/character_animation_apply_manual_5pack_batch.py` — batch clone + SpriteFrames text export
- `addons/character_animation_mapper/CharacterAnimationSpriteFramesExporter.gd` — editor-safe SpriteFrames export helper (uses external sheet texture via `ResourceLoader.load`)
- `src/tools/editor/Manual5PackCharacterAnimationBatchValidator.gd` — Godot EditorScript batch validator
- `src/tools/editor/RunManual5PackCharacterAnimationBatch.gd` — optional Godot-side SpriteFrames regeneration
- `src/tools/editor/CharacterAnimationMapperPreviewSandbox.gd` — preview character dropdown
- `scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn` — PreviewOptionButton UI
- `src/tools/editor/CharacterAnimationMapperValidator.gd` — static checks for new tooling

## Files intentionally left untouched

- `resources/character_animation_maps/character__working_manual_map.json` (read-only; hash verified unchanged)
- `project.godot`, production player/Taco scenes, autoloads, runtime controllers
- Raw character sheet PNGs
- Existing dock default preview output path/behavior (`parmida_manual_preview_spriteframes.tres`)

## Source map status

| Check | Result |
|---|---|
| Animation count | 591 |
| All `reviewed` | Yes |
| No `spear_stab_*` | Yes |
| Grid | 200×200, 50×50 |
| Source sheet | Parmida manual 5-pack sheet |

## Target sheets processed

All four targets processed successfully (10000×10000 PNG, compatible 50×50×200 layout per `manual_5pack_metadata.json`):

| Character | Sheet | Map | SpriteFrames |
|---|---|---|---|
| Neon runner | `character_02_neon_runner_sheet.png` | `character_02_neon_runner_manual_animation_map.json` | `character_02_neon_runner_preview_spriteframes.tres` |
| Cyber tech | `character_03_cyber_tech_sheet.png` | `character_03_cyber_tech_manual_animation_map.json` | `character_03_cyber_tech_preview_spriteframes.tres` |
| Street bruiser | `character_04_street_bruiser_sheet.png` | `character_04_street_bruiser_manual_animation_map.json` | `character_04_street_bruiser_preview_spriteframes.tres` |
| Nocturne guard | `character_05_nocturne_guard_sheet.png` | `character_05_nocturne_guard_manual_animation_map.json` | `character_05_nocturne_guard_preview_spriteframes.tres` |

**Skipped:** none

## Cloned map metadata

Each cloned map preserves all 591 animation definitions and adds:
- `source_map_template`: `res://resources/character_animation_maps/character__working_manual_map.json`
- `applied_from_character`: `character_01_parmida_reference_variant`
- `requires_visual_sandbox_validation`: `true`
- Updated `source_sheet` per character

`review_status` preserved as `reviewed` for all entries.

## Validation results

| Check | Result |
|---|---|
| Source map unmodified | PASS (byte hash unchanged) |
| 4 target maps parse | PASS |
| Animation count = 591 each | PASS |
| Correct `source_sheet` each | PASS |
| All entries `reviewed` | PASS |
| No `spear_stab_*` | PASS |
| No duplicate animation names | PASS |
| Frame indices 0..2499 | PASS |
| SpriteFrames files exist | PASS |
| 591 animations per SpriteFrames (text scan) | PASS |
| Representative anims present (`idle_toward_01`, `stab_toward_01`, etc.) | PASS |
| Godot LSP diagnostics (edited GDScript) | PASS (0 issues) |
| Godot editor load/play test per character | **Not run** (editor offline) |
| `Manual5PackCharacterAnimationBatchValidator` in Godot | **Not run** (requires EditorScript execution) |

## Sandbox testing instructions

1. Open `res://scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn`
2. Run scene (F6)
3. Use **Preview character** dropdown to switch between:
   - Parmida (existing dock-generated preview)
   - Neon runner / Cyber tech / Street bruiser / Nocturne guard
4. Pick representative animations (`idle_toward_01`, `walk_toward_01`, `run_toward_01`, `stab_toward_01`, etc.) and click **Play**
5. Confirm frames animate from the correct character sheet silhouette

**Alternative:** Set exported `spriteframes_path` on the sandbox root node in the inspector.

**If Godot rejects text-exported SpriteFrames:** Run EditorScript `RunManual5PackCharacterAnimationBatch.gd` (File → Run) to regenerate via `ResourceSaver` using `CharacterAnimationSpriteFramesExporter.gd`.

**Batch re-run (maps + text SpriteFrames):**
```bash
python src/tools/editor/character_animation_apply_manual_5pack_batch.py
```

**Godot batch validation (when editor open):**
Run `Manual5PackCharacterAnimationBatchValidator.gd` as EditorScript.

## Kimi K2.6 MCP usage

Not used.

## Safety confirmation

- Validation-only artifacts under `resources/character_animation_maps/` and `generated_preview/`
- No production runtime wiring
- No git commit/push
- Source Parmida reviewed map read-only

## Known limitations

- Generated SpriteFrames use text export with external `Texture2D` references (~563 KB each) vs the existing Parmida dock export (~1.2 GB embedded image). Godot load compatibility should be confirmed in-editor.
- Cloned maps inherit Parmida frame assignments; visual sandbox validation is still required before production promotion (`requires_visual_sandbox_validation: true`).
- Parmida preview SpriteFrames was not regenerated by this task (dock default unchanged).

## Suggested next step

1. Open Godot and run the preview sandbox for each character via the new dropdown
2. Spot-check 2–3 animations per character (idle/walk/stab/death)
3. Run `Manual5PackCharacterAnimationBatchValidator.gd` in the editor for full SpriteFrames resource validation
4. After visual sign-off, consider regenerating Parmida preview via `CharacterAnimationSpriteFramesExporter` for consistent external-texture file sizes
