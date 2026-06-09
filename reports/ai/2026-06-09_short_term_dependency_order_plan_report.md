# Short-Term Dependency-Order Plan Roadmap Update Report

Date: 2026-06-09

## Goal

Record Jake's current short-term dependency-order plan directly in the mission-system roadmap so it can be referenced and revised as work proceeds.

## Files Changed

- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `reports/ai/2026-06-09_short_term_dependency_order_plan_report.md`

## Summary

Added `Current Short-Term Dependency-Order Plan` before `Highest-Value Near-Term Build Order` in the roadmap.

The new section preserves the long-term roadmap while documenting the current operating sequence:

1. Quick validation reviews for Mission Paint Dock and animation previews.
2. Production foundation confidence through Taco Packet 6C and core reusable mechanic status.
3. PVGames Palette v2 safety features.
4. Mission Authoring Palette and small Mission Assist Browser.
5. Gameplay expansion through card modifiers, stealth, inventory, Bentley, and noise/distraction.
6. Larger identity systems such as side jobs, hideout rewards, paper trail, social stealth, encounters, advanced NPC, and narrative/presentation.

## Scope Notes

- This update is documentation-only.
- No production scenes, scripts, resources, autoloads, plugin files, or `project.godot` were changed by this pass.
- The plan is dependency-driven rather than strict numeric phase order.
- The roadmap now includes an explicit update rule: revise the section after each completed gate or when validation changes the dependency order.

## Pre-existing Worktree Note

Before this pass, `git status --short --branch` showed existing modified files from the Phase 3K completion update plus a modified generated preview SpriteFrames file:

```text
M resources/character_animation_maps/generated_preview/character_02_neon_runner_preview_spriteframes_before_manual_5pack_apply_20260607_201600.tres
```

This pass did not modify that generated preview SpriteFrames file.

## Validation

- `git diff --check` — PASS.
- Roadmap insertion read back from `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` and confirmed under `Current Short-Term Dependency-Order Plan`.
- GdUnit4 not run because this was a documentation-only roadmap update.
- Godot editor/runtime checks not run because no scenes, scripts, resources, or plugins were changed.
