# Dock Validation SpriteFrames External Export Report

Date: 2026-06-08

## Goal

Change the Character Animation Mapper dock's `Generate Validation SpriteFrames` path so it writes the small external-reference Parmida preview instead of the legacy embedded `parmida_manual_preview_spriteframes.tres` file.

## Files Changed

- `addons/character_animation_mapper/CharacterAnimationMapperDock.gd`
- `reports/ai/2026-06-08_dock_validation_spriteframes_external_export_report.md`

## Behavior Changed

- The dock now targets `res://resources/character_animation_maps/generated_preview/character_01_parmida_reference_variant_preview_spriteframes.tres`.
- The dock now uses `CharacterAnimationSpriteFramesExporter.build_spriteframes_from_map_data()` to build `SpriteFrames` with external sheet references.
- The export readout now names the small external-reference output path.

## Files Intentionally Left Untouched

- `res://resources/character_animation_maps/generated_preview/parmida_manual_preview_spriteframes.tres` remains untouched as a legacy artifact.
- Reviewed animation maps were not modified.
- Production player scenes, Taco scenes, autoloads, `project.godot`, and raw spritesheets were not modified.

## Validation

- Parsed `character__working_manual_map.json`: 591 animations, all `reviewed`.
- Confirmed small Parmida preview exists: `character_01_parmida_reference_variant_preview_spriteframes.tres` at about 0.54 MB.
- Confirmed legacy preview still exists and remains large: `parmida_manual_preview_spriteframes.tres` at about 1166.46 MB.
- Searched the dock script: no remaining reference to `parmida_manual_preview_spriteframes.tres`; the dock references the small preview path and exporter helper.

## Checks Not Run

- Godot CLI/script validation was not run because `godot` is not available on PATH in this environment.
- In-editor click-through was not run from this environment.

## Safety Confirmation

- Stayed inside the repository.
- No secrets or private files accessed.
- No git commit, push, branch, reset, stash, or history operations performed.
- No production/runtime wiring changed.

## Known Limitations

- The dock export needs a live Godot editor test: click `Generate Validation SpriteFrames` and confirm the output remains small and loads in the preview sandbox.
- The legacy 1.16 GB preview file still exists; after live validation, it should be archived or deleted in a separate cleanup step if Jake no longer needs it.

## Suggested Next Step

In Godot, load the Parmida sheet and `character__working_manual_map.json`, click `Generate Validation SpriteFrames`, then verify `character_01_parmida_reference_variant_preview_spriteframes.tres` remains small and loads in `CharacterAnimationMapperPreviewSandbox.tscn`.
