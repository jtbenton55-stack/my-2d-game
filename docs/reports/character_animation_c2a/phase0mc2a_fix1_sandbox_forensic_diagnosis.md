# Phase 0M-C2A-FIX1 — Sandbox forensic diagnosis

**Date:** 2026-05-09  
**Scene:** `res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn`

## What was wrong (pre-FIX1)

1. **SpriteFrames resource format (primary)**  
   `parmida_player_spriteframes_0mc2a.tres` was generated with an invalid `animations` structure for Godot 4 (nested `"animations/idle"` / `"animations/walk"` objects inside an array).  
   Valid Godot 4 `SpriteFrames` text resources look like `res://assets/sprites/player_sprite_frames.tres`: an array of dictionaries with `"name"`, `"frames"`, `"loop"`, `"speed"`.

2. **Symptom**  
   `AnimatedSprite2D` referenced the broken `.tres`, so Godot could not materialize usable animations. The sprite appeared invisible (no drawable frames), which reads as “animated Parmida not visible”.

3. **Secondary (non-primary)**  
   The sandbox attached `PlayerVisualAnimator.gd` while the parent was not a `CharacterBody2D`. This is not the main invisibility mechanism, but it was removed from the sandbox to reduce confusion.

## Scene structure (post-FIX1)

- Root: `CharacterAnimationSandbox_0MC2A` (`Node2D`) + `CharacterAnimationSandbox_0MC2AController.gd`
- Background/grid/baseline: `ReferenceBackground` (`Polygon2D`), `ReferenceGrid` (`Line2D`), `BaselineGuide` (`Line2D`)
- Columns: `OldPlaceholderColumn`, `StaticParmidaColumn`, `AnimatedParmidaColumn`
- Animated column nodes:
  - `AnimatedParmidaReference` (`AnimatedSprite2D`) uses `parmida_player_spriteframes_0mc2a_fix1.tres`
  - `AnimatedParmidaFallbackFrame` (`Sprite2D`) + `FallbackWarningPanel` / `FallbackWarningLabel` for explicit failure UI

Machine-readable: `phase0mc2a_fix1_sandbox_forensic_diagnosis.json`.
