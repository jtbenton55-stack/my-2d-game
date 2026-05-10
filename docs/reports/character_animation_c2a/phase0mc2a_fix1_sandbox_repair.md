# Phase 0M-C2A-FIX1 — Sandbox repair (final)

**Date:** 2026-05-09  
**Scope:** Sandbox + generated SpriteFrames wiring only. **No production promotion.**  

## Outcome

**PARTIAL (recommended reporting)**  
Structural root cause was fixed (invalid `SpriteFrames` serialization) and static checks pass, but this agent environment did not run Godot play mode to eyeball-confirm pixels on-screen.

## What changed

- Added **`parmida_player_spriteframes_0mc2a_fix1.tres`** in valid Godot 4 `SpriteFrames` format (atlas slices from the existing composite PNG).
- Backed up the legacy broken `.tres` to:
  - `parmida_player_spriteframes_0mc2a.broken_format_backup_0mc2a_fix1.tres`
- Rebuilt **`CharacterAnimationSandbox_0MC2A.tscn`** with explicit columns, baseline/grid, and a **non-silent `DebugPanel`** driven by:
  - `CharacterAnimationSandbox_0MC2AController.gd`
- Removed **`PlayerVisualAnimator.gd`** attachment from the sandbox animated sprite (sandbox parent is not a `CharacterBody2D`).

## Root cause (primary)

**D — `SPRITEFRAMES_EMPTY` (effective):** legacy `parmida_player_spriteframes_0mc2a.tres` was not valid Godot 4 `SpriteFrames` text, so animations did not load as usable frames.

## Manual validation (required)

Run `CharacterAnimationSandbox_0MC2A.tscn` and confirm:

- Column 3 animated sprite is visible and animates
- Debug panel reads `Sandbox status: PASS` (if everything loads)
- `Production promotion allowed: YES, after manual visual validation` only if you accept visuals

Machine-readable summary: `phase0mc2a_fix1_sandbox_repair.json`.
