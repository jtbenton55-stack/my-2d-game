# FIX3 — Prior C2 / C2A data inventory

## C2 (static Parmida)

- **Key JSON:** `docs/reports/character_sprite_replacement/phase0mc2_player_visual_resource_preparation.json`
- **Documented source cell:** **200×200** (`source_frame_rect`)
- **Slicing report:** `phase0mc2_spritesheet_slicing_report.json` (also 200×200)
- **Generated static PNG:** 46×96 (cropped from frame for display)

## C2A (prior animation pass)

- Prior reports under `docs/reports/character_animation_c2a/` (`phase0mc2a_*`)
- Earlier compositor / FIX1 / FIX2 assumed **100×200** kit cells for animation strips.

## Discrepancy

| Source | Frame size |
|--------|------------|
| C2 static prep | **200×200** |
| C2A / FIX2 animation | **100×200** |

Using **100×200** slices on art laid out for **200×200** can yield **half-width** crops (classic “cut in half” symptom). FIX3 forensics compare **100×200** vs **200×200** and select using evidence + C2 metadata.

## FIX1 / FIX2 artifacts

- FIX1: valid Godot 4 `SpriteFrames`, glitchy motion (wrong strip semantics + wrong cell width risk).
- FIX2: improved strip pick under **100×200**; still mismatched vs C2 **200×200** evidence.

JSON: `phase0mc2a_fix3_prior_data_inventory.json`.
