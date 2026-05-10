# Phase 0M-C2A-FIX1 — SpriteFrames regeneration

**Date:** 2026-05-09  

## Why regeneration was needed

The legacy generator wrote `parmida_player_spriteframes_0mc2a.tres` using a **non-Godot-4** `SpriteFrames` text layout. Godot did not deserialize usable `idle` / `walk` animations, so the sandbox `AnimatedSprite2D` rendered nothing.

## What was regenerated

- **New resource:** `res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a_fix1.tres`
- **Source atlas:** `res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_composite_sheet_0mc2a.png` (already generated in C2A; not raw PVGames)
- **Frame size:** `100x200`
- **Animations:** `idle` (10 frames, 6 FPS), `walk` (10 frames, 10 FPS)
- **Atlas regions:** same as the prior compositor intent (`y=0` idle strip, `y=200` walk strip)

## Safety / constraints

- **No raw PVGames kit edits**
- **No direction guesswork** (Option C generic `idle` + `walk` only)
- **Original legacy `.tres` not overwritten**; copied to:
  - `parmida_player_spriteframes_0mc2a.broken_format_backup_0mc2a_fix1.tres`

## Generator

- `res://src/tools/editor/character_animation_c2a_fix1_write_spriteframes.py`

Machine-readable: `phase0mc2a_fix1_spriteframes_regeneration.json`.
