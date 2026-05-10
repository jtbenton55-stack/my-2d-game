# Phase 0M-C2A — Visual Animator Report

**Phase:** 0M-C2A  
**Phase Name:** Visual-Only Player Animation Controller  
**Date:** 2026-05-09  

## Generated Script

**Path:** `src/characters/PlayerVisualAnimator.gd`

## Design Principles

This script follows the C2A safety requirements:

1. **Visual-Only** — Does not modify gameplay, physics, or collision
2. **Parent Velocity Reader** — Only reads `parent.velocity`, never writes
3. **Fallback Safe** — Gracefully disables if resources missing
4. **No Movement Changes** — Does not modify position, velocity, or input
5. **No Camera Changes** — Does not touch camera
6. **No Collision Changes** — Purely visual

## Script Features

| Feature | Implementation |
|---------|----------------|
| Animation detection | Auto-detects parent CharacterBody2D |
| Velocity threshold | Configurable `walk_velocity_threshold` (default: 10.0) |
| Idle animation | Plays when velocity < threshold |
| Walk animation | Plays when velocity >= threshold |
| Missing animation fallback | Falls back to idle if walk missing |
| No SpriteFrames fallback | Disables gracefully, logs warning |
| FPS configuration | `idle_fps` (6), `walk_fps` (10) |
| Facing tracking | Tracks `_last_facing` for future expansion |

## Exported Variables

```gdscript
@export var idle_animation_name: String = "idle"
@export var walk_animation_name: String = "walk"
@export var walk_velocity_threshold: float = 10.0
@export var idle_fps: float = 6.0
@export var walk_fps: float = 10.0
```

## Public API

- `force_idle()` — Force switch to idle animation
- `force_walk()` — Force switch to walk animation
- `is_animation_working() -> bool` — Returns true if animations functioning

## Attachment Instructions

1. Add an `AnimatedSprite2D` node to the Player scene
2. Name it: `PlayerVisual_ParmidaAnimated`
3. Assign the SpriteFrames resource: `parmida_player_spriteframes_0mc2a.tres`
4. Attach this script to the AnimatedSprite2D
5. Configure position/scale to match the working C2 static visual (1.35, 1.35)

## Safety Guarantees

| System | Modified? | Notes |
|--------|-----------|-------|
| Player.gd | NO | Script is attached to visual node only |
| Movement | NO | Reads velocity only, never writes |
| Collision | NO | No collision changes |
| Input | NO | No input handling |
| Camera | NO | No camera references |
| Velocity | NO | Never modifies parent velocity |
| Position | NO | Never modifies parent position |

## Hard Assertions

| Assertion | Status |
|-----------|--------|
| visual_animator_created_if_needed | [PASS] |
| visual_animator_does_not_modify_gameplay | [PASS] |
| missing_animation_falls_back_to_idle | [PASS] |
| player_movement_script_not_rewritten | [PASS] |
| no_unsafe_sprite_flipping | [PASS] |

