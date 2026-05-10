# Phase 0M-C2A-FIX2 — SpriteFrames report

## Fix2 resource

- **SpriteFrames:** `res://assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt/parmida_player_spriteframes_0mc2a_fix2.tres`
- **Atlas:** `res://assets/characters/generated_player_visuals/c2a_animation/fix2_rebuilt/parmida_player_composite_sheet_0mc2a_fix2.png`

## Godot 4 text format

Matches working project pattern (top-level `[resource]` → `animations = [ { ... } ]`, `SubResource` `AtlasTexture` entries, **no** broken nested `"animations/idle"` dictionary layout).

## Animations

| Name | Frames | FPS | Loop | Regions |
|------|--------|-----|------|---------|
| idle | 10 | 5.0 | yes | `Rect2(n*100, 0, 100, 200)` for n = 0..9 |

## Walk

- **Not included** in this export (idle-only).

## Quality status

**PARTIAL — pending manual Godot sandbox validation** (static structure is valid; visual acceptance is human-gated).

JSON: `phase0mc2a_fix2_spriteframes_report.json`.
