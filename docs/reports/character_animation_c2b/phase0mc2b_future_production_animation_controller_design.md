# Future production animation controller (design only — 0M-C2B)

This document describes how a **later** production pass could drive Parmida visuals from velocity and future input **without** changing movement, collision, or `Player.gd` unless explicitly agreed.

## Principles

1. **Read-only motion:** A `PlayerVisualAnimator`-style node reads `CharacterBody2D.velocity` (or exported signals from `Player`) and picks `idle` / `walk` / `run`. It does not write velocity or call `move_and_*`.
2. **No collision edits:** Hitboxes, layers, masks, and `CollisionShape2D` resources stay owned by gameplay.
3. **Fallbacks:** If `walk`, `run`, or `attack` resources are missing or disabled, the visual falls back to `idle` at the production scale (1.35).
4. **Attack is event-driven:** Play `attack` only when a future gameplay or UI event requests it (e.g. buffered action). No hitboxes, damage, or enemies in this design.
5. **Single facing:** C2B assets are **not** directional; production should not invent 4/8-way animation until source data supports it.

## Suggested thresholds (tunable)

| State | Condition |
|-------|-------------|
| idle | `velocity.length() < walk_threshold` |
| walk | `velocity.length() >= walk_threshold` and `< run_threshold` (and optionally no sprint flag) |
| run | `velocity.length() >= run_threshold` or sprint input true |
| attack | One-shot trigger; after animation finished or timeout, return to idle/walk/run from velocity |

## Integration shape

- Add a child under the player scene (future change — **not** done in C2B): e.g. `PlayerVisualAnimator` holding `AnimatedSprite2D` + `SpriteFrames` reference.
- Load `SpriteFrames` from `res://assets/characters/generated_player_visuals/c2b_full_animation/parmida_player_spriteframes_0mc2b.tres` only after manual promotion approval.
- Mirror sandbox scale/offset (1.35, feet baseline) to match static Parmida.

## Explicit non-goals

- Combat systems, input rebinding for strike, AI, or Taco Bell mission edits are out of scope until requested.
