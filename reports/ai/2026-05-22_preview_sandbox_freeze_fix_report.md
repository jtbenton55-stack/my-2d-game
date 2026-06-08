# Preview Sandbox Freeze Fix Report

**Date:** 2026-05-22

## Goal

Stop `CharacterAnimationMapperPreviewSandbox.tscn` from freezing on F6 by preventing auto-load of the ~1.16 GB embedded Parmida SpriteFrames.

## Root cause

On `_ready()`, the sandbox called `_bootstrap()` → `_load_spriteframes()` with default path `parmida_manual_preview_spriteframes.tres` (~1166 MB, embedded textures). Godot blocked while parsing/loading that resource.

## File sizes observed

| File | Size |
|---|---:|
| `parmida_manual_preview_spriteframes.tres` (legacy) | ~1166 MB |
| `character_01_parmida_reference_variant_preview_spriteframes.tres` (new) | ~0.54 MB |
| `character_02_neon_runner_preview_spriteframes.tres` | ~0.54 MB |
| Other character previews (03–05) | ~0.54 MB each |

## Files changed

- `src/tools/editor/CharacterAnimationMapperPreviewSandbox.gd` — lazy load, size guard, new defaults
- `scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn` — Load Preview button, `auto_play = false`
- `src/tools/editor/RunManual5PackCharacterAnimationBatch.gd` — added Parmida small preview target
- `src/tools/editor/character_animation_apply_manual_5pack_batch.py` — generates small Parmida preview
- `src/tools/editor/CharacterAnimationMapperValidator.gd` — static checks for new sandbox behavior

## New artifact

- `resources/character_animation_maps/generated_preview/character_01_parmida_reference_variant_preview_spriteframes.tres` (~563 KB, external texture refs)

Legacy `parmida_manual_preview_spriteframes.tres` was **not** deleted or overwritten.

## Sandbox startup behavior change

**Before:** Auto-loaded default SpriteFrames on startup; `auto_play = true`; default path = huge Parmida file.

**After:**
- Opens in safe empty state (no `load()` on startup)
- Default dropdown selection: **Neon runner** (small preview)
- `auto_play = false`
- Selecting a character updates path label + file size only
- **Load Preview** button explicitly loads the selected `.tres`
- **Play** / **Stop** work after load
- 100 MB size guard blocks unsafe loads with warning message
- Legacy huge Parmida listed separately as `Parmida LEGACY (embedded, unsafe)` — blocked by size guard unless regenerated

## Whether new small Parmida preview was generated

**Yes** — `character_01_parmida_reference_variant_preview_spriteframes.tres` generated from `character__working_manual_map.json` with external sheet reference (591 animations).

## Validation results

| Check | Result |
|---|---|
| Git status before/after | Recorded |
| Sandbox no `_load_spriteframes()` in `_bootstrap()` | PASS |
| Default path = neon runner small preview | PASS |
| `auto_play` false in scene | PASS |
| Size guard `SAFE_MAX_BYTES` (100 MB) | PASS |
| Small Parmida preview generated (~0.54 MB) | PASS |
| Legacy huge Parmida untouched | PASS |
| Godot LSP diagnostics | PASS (0 issues) |
| F6 run / in-editor play test | **Not run** (editor offline) |

## How Jake should test now

1. Open `res://scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn`
2. Press **F6** — scene should open immediately without freezing
3. Confirm status: “select a character, then click Load Preview”
4. Default selection: **Neon runner**
5. Click **Load Preview** → animation dropdown populates
6. Select `idle_toward_01`, click **Play**
7. Switch to **Cyber tech** → click **Load Preview** again → play `walk_toward_01`, `stab_toward_01`
8. Select **Parmida (character 01)** → Load Preview → should load small ~0.54 MB file
9. Select **Parmida LEGACY** → Load Preview → should show size warning, not freeze

## Safety confirmation

- No production scenes/autoloads/`project.godot`/reviewed maps changed
- Legacy huge Parmida preview preserved
- Validation-only sandbox tooling

## Known limitations

- Godot in-editor F6/play test not performed this session
- Text-exported SpriteFrames load compatibility should still be confirmed in Godot
- Superseded 2026-06-08: the dock now writes `character_01_parmida_reference_variant_preview_spriteframes.tres` through the external-reference exporter. The legacy `parmida_manual_preview_spriteframes.tres` remains preserved but should not be auto-loaded.

## Suggested next step

After confirming sandbox works, use the dock's updated `Generate Validation SpriteFrames` path for the small Parmida preview and archive/remove the 1.16 GB legacy file once Jake no longer needs it.
