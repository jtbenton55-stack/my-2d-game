# Phase 0M-C2A-FIX1 — Generated resource inventory

**Date:** 2026-05-09  

## Summary

- **C2A folder:** `res://assets/characters/generated_player_visuals/c2a_animation/`
- **Machine inventory (paths, sizes, PNG dimensions, .tres text signals):** `phase0mc2a_fix1_generated_resource_inventory.json`
- **Inventory generator:** `res://src/tools/editor/character_animation_c2a_fix1_inventory.py`

## Key files (purpose)

| Path | Purpose |
|------|---------|
| `parmida_player_composite_sheet_0mc2a.png` | Composited idle+walk sheet (1000x400, 100x200 frames) |
| `frames/idle_frame_*.png`, `frames/walk_frame_*.png` | Exported per-frame PNGs for diagnostics / fallback |
| `parmida_player_spriteframes_0mc2a.tres` | **Legacy generator output — invalid Godot 4 SpriteFrames text format** (kept; backup added) |
| `parmida_player_spriteframes_0mc2a.broken_format_backup_0mc2a_fix1.tres` | Backup copy of legacy `.tres` before fix1 work |
| `parmida_player_spriteframes_0mc2a_fix1.tres` | **FIX1: valid Godot 4 SpriteFrames** (`idle`, `walk`, AtlasTexture frames) |
| `parmida_player_animation_metadata.json` | Composition metadata from C2A pipeline |
| `CharacterAnimationSandbox_0MC2A.tscn` | Sandbox scene (rebuilt in FIX1) |
| `CharacterAnimationSandbox_0MC2AController.gd` | Sandbox-only diagnostics + fallback wiring |

## SpriteFrames notes

- **Legacy** `parmida_player_spriteframes_0mc2a.tres` used a non-Godot `animations = [...]` structure (nested `"animations/idle"` keys). Godot 4 expects an array of dictionaries with `"name"`, `"frames"`, `"loop"`, `"speed"` (see `res://assets/sprites/player_sprite_frames.tres`).
- **Fix1** `parmida_player_spriteframes_0mc2a_fix1.tres` matches that format and references the same composite PNG atlas regions.
