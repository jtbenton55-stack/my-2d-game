# 0M-C2B — Full animation discovery (Parmida)

## Summary

**Result: PARTIAL_PENDING_MANUAL** — Idle and walk were generated at **200×200** from composited kit layers; **run** and **attack** are **RUN_NOT_FOUND_SAFE** / **ATTACK_NOT_FOUND_SAFE**. Production player and Taco Bell were not touched. **Promotion: NO** until you validate in the sandbox.

| Key | Value |
|-----|-------|
| A. Pass/Fail | PARTIAL_PENDING_MANUAL |
| B. Branch | `c2a-full-character-animation-20260509-172230` |
| C. `player.tscn` modified | **No** |
| D. `Player.gd` modified | **No** |
| E. Taco Bell scenes modified | **No** |
| F. Raw PVGames kit modified | **No** (read-only) |
| G. Frame size | **200×200** (100×200 not used) |
| H. Layers | Female Base 3, Bottoms 13, Tops 24, Head 4, Hair 7 — see `phase0mc2b_selected_layers.json` |
| I. Grid verification | `phase0mc2b_200x200_grid_verification.json` |
| J. Row browser | `res://docs/reports/character_animation_c2b/row_browser/` |
| K. Master row sheet | `phase0mc2b_all_rows_contact_sheet.png` |
| L. Classification | `phase0mc2b_row_classification.json` |
| M. Idle row | **35** |
| N. Walk row | **37** |
| O. Run row | **—** |
| P. Attack row | **—** |
| Q. Walk status | **WALK_SELECTED** |
| R. Run status | **RUN_NOT_FOUND_SAFE** |
| S. Attack status | **ATTACK_NOT_FOUND_SAFE** |
| T. C2B folder | `res://assets/characters/generated_player_visuals/c2b_full_animation/` |
| U. SpriteFrames | `parmida_player_spriteframes_0mc2b.tres` |
| V. Animations | `idle`, `walk` |
| W–Z. Frame counts | Idle **12**, Walk **12**, Run **0**, Attack **0** |
| AA. Contact sheets | idle, walk, combined (under `docs/reports/character_animation_c2b/`) |
| AB–AC. Sandbox | `CharacterAnimationSandbox_0MC2B.tscn` + `CharacterAnimationSandbox_0MC2BController.gd` |
| AD. Frame-by-frame | Yes (C2B current animation) |
| AE. Production promotion | **NO** |
| AF. Future controller design | `phase0mc2b_future_production_animation_controller_design.md` |
| AG. Validator | `character_animation_c2b_static_validator.py` + `CharacterAnimationC2BValidator.gd` |
| AH. Godot runtime | Run sandbox manually in editor |
| AI. Reports | `docs/reports/character_animation_c2b/` |

## Manual checklist

1. Open row browser contact sheets (`row_browser/row_XX_contact_sheet.png`).
2. Confirm rows **35** (idle) and **37** (walk) match intent.
3. Open `phase0mc2b_combined_animation_contact_sheet.png`.
4. Confirm accepted frames are full-body **200×200**.
5. No half-width / cropped bodies.
6. No violent anchor jumps (eyeball).
7. Open `res://scenes/hideout/tools/CharacterAnimationSandbox_0MC2B.tscn` and run.
8. Confirm idle plays; walk plays; run/attack buttons disabled with **NOT FOUND SAFE** labels.
9. Step frames with Prev/Next.
10. Scale matches static **1.35** reference.
11. Confirm no unexpected Output errors.
12. Confirm `player.tscn`, `Player.gd`, Taco Bell scenes unchanged.
