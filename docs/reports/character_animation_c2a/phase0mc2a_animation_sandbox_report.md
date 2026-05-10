# Phase 0M-C2A — Animation sandbox report (updated after **0M-C2A-FIX3**)

**Phase:** 0M-C2A + FIX1 + FIX2 + **FIX3**  
**Scene:** `res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2A.tscn`  
**Date note:** 2026-05-09  

## Timeline

1. **Pre-FIX1:** Legacy `parmida_player_spriteframes_0mc2a.tres` used a broken Godot 4 text schema → animated column invisible.
2. **FIX1:** Valid Godot 4 `SpriteFrames` (`parmida_player_spriteframes_0mc2a_fix1.tres`) → **visible but glitchy** (wrong strip semantics + wrong cell size risk).
3. **FIX2:** Rebuilt **100×200** fixed-canvas frames + valid `SpriteFrames`; also adjusted scene wiring so missing generated assets do not hard-fail scene load. Animation could still look **wrong** vs C2 evidence.
4. **FIX3:** **Frame-size forensics** (100×200 vs **200×200**) + decision driven by C2’s documented **200×200** `source_frame_rect`; rebuilt **`fix3_stable`** assets; sandbox primary is **`parmida_player_spriteframes_0mc2a_fix3.tres`**; added **frame-by-frame viewer**; **walk** only if stable (current export: **idle-only**).

## Current sandbox columns / tools

| # | Item | Notes |
|---|------|-------|
| 1 | Old placeholder | `old_player_token_reference_0mc2.png` |
| 2 | Static Parmida | `parmida_player_visual_0mc2.png` @ **(1.35, 1.35)** |
| 3 | Animated Parmida | `AnimatedSprite2D` → **FIX3** `SpriteFrames` @ **(1.35, 1.35)** (FIX2/FIX1 only as runtime fallback if FIX3 missing) |
| 4 | Frame-by-frame viewer | Steps through **FIX3** `idle_*.png` paths from metadata |

## Forensic / QA artifacts (FIX3)

- **100×200 forensic strip:** `res://docs/reports/character_animation_c2a/phase0mc2a_fix3_frame_size_forensic_100x200.png`
- **200×200 forensic strip:** `res://docs/reports/character_animation_c2a/phase0mc2a_fix3_frame_size_forensic_200x200.png`
- **Side-by-side comparison:** `res://docs/reports/character_animation_c2a/phase0mc2a_fix3_frame_size_forensic_comparison.png`
- **Bad idle (prior FIX2 frames):** `phase0mc2a_fix3_current_bad_idle_frames.png`
- **Bad walk sheet / placeholder:** `phase0mc2a_fix3_current_bad_walk_frames.png`
- **Stable FIX3 sheet:** `phase0mc2a_fix3_stable_frames_contact_sheet.png`

## Pass status

**PARTIAL — manual runtime validation still required**

- FIX3 static validator: `phase0mc2a_fix3_validation.json` (`structural_pass`); automated “FULL_BODY” tags may still be **conservative** — **eyeball** the forensic + stable contact sheets in Godot.

## Production promotion

**Not allowed** from this pass. `player.tscn` / `Player.gd` unchanged.

## Primary resource if promoted later (explicit separate task)

`res://assets/characters/generated_player_visuals/c2a_animation/fix3_stable/parmida_player_spriteframes_0mc2a_fix3.tres`

## Related FIX3 reports

- `phase0mc2a_fix3_stable_animation.md`
- `phase0mc2a_fix3_validation.md`
