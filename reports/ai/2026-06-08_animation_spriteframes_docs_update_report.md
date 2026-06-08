# Animation SpriteFrames Docs Update Report

Date: 2026-06-08

## Goal

Update roadmap/blueprint documentation after changing the Character Animation Mapper dock's validation `SpriteFrames` export from the legacy embedded Parmida preview to the small external-reference Parmida preview.

## Files Changed

- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-05-22_preview_sandbox_freeze_fix_report.md`
- `reports/ai/2026-06-08_animation_spriteframes_docs_update_report.md`

## Updates Made

- Roadmap now says the dock writes `character_01_parmida_reference_variant_preview_spriteframes.tres` and treats `parmida_manual_preview_spriteframes.tres` as legacy/unsafe for auto-loading.
- Blueprint now records the same current dock output and updates the next animation gate to sandbox validation of reviewed manual 5-pack previews.
- The older preview sandbox freeze report now marks its stale dock-output warning as superseded by the 2026-06-08 external-export change.

## Validation

- Searched docs for legacy/current preview references.
- Reviewed the resulting diff for the three updated Markdown files.

## Safety Confirmation

- Documentation/report-only change.
- No gameplay, runtime, scene, autoload, map, or SpriteFrames resources changed by this docs update.
- No git commit/push/pull/branch/history operations performed.
