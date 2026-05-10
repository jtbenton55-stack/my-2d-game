# Phase 0M-C2A-FIX1 — Sandbox validation

**Date:** 2026-05-09  

## Static validation (automated)

- **Script:** `res://src/tools/editor/character_animation_c2a_fix1_static_validator.py`
- **Output:** `phase0mc2a_fix1_sandbox_validation.json`

### What static validation proves

- Branch is `c2a-full-character-animation-20260509-172230`
- `git diff` shows **no edits** to:
  - `scenes/characters/player.tscn`
  - `src/player/Player.gd`
  - `scenes/missions_iso/` (Taco Bell scenes folder)
- Sandbox scene references **`parmida_player_spriteframes_0mc2a_fix1.tres`**
- Sandbox includes **`AnimatedParmidaReference`**, **`DebugPanel/DebugLabel`**, **`BaselineGuide`**, **`ReferenceGrid`**
- Fix1 SpriteFrames text contains **`"name": "idle"`** and **`"name": "walk"`** plus `SubResource("idle_0")` / `SubResource("walk_0")` markers
- Sandbox does **not** attach `PlayerVisualAnimator.gd` (sandbox-only simplification)

### What still requires Godot runtime

- Confirm `AnimatedParmidaReference` visibly animates in-editor play (F6)
- Confirm Output panel has no parse errors for `CharacterAnimationSandbox_0MC2AController.gd`

## Optional editor helper

- `res://src/tools/editor/CharacterAnimationC2AFix1Validator.gd` (`EditorScript`) — loads key paths and prints SpriteFrames animation names.
