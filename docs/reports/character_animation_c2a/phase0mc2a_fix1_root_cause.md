# Phase 0M-C2A-FIX1 — Root cause classification

**Date:** 2026-05-09  

## Primary category

**D — `SPRITEFRAMES_EMPTY` (effective)**  

The on-disk `parmida_player_spriteframes_0mc2a.tres` was not a valid Godot 4 `SpriteFrames` text serialization. In practice, the `AnimatedSprite2D` ended up with **no usable animation frames**, so nothing rendered.

## Secondary category (symptom overlap)

**E — `ANIMATION_NAME_MISMATCH` (symptom-level)**  

The sandbox attempted `animation = idle` / autoplay, but the broken resource did not expose a working `idle` animation in the engine’s expected schema.

## Evidence

- Known-good reference: `res://assets/sprites/player_sprite_frames.tres`
- Broken pattern: nested `"animations/idle"` / `"animations/walk"` inside `animations = [{ ... }]` in `parmida_player_spriteframes_0mc2a.tres`
- Repair: new `parmida_player_spriteframes_0mc2a_fix1.tres` using the standard `animations = [ { "frames": [...], "loop": ..., "name": "...", "speed": ... }, ... ]` format with `AtlasTexture` `SubResource`s.

Machine-readable: `phase0mc2a_fix1_root_cause.json`.
