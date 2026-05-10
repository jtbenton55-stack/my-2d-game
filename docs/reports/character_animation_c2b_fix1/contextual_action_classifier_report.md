# 0M-C2B-FIX1 — Contextual action classifier (final)

## A–AI summary

| Field | Value |
|-------|--------|
| A. PASS/FAIL/PARTIAL | **PARTIAL_PENDING_MANUAL** |
| B. Branch | `c2a-full-character-animation-20260509-172230` |
| C. `player.tscn` modified | **No** |
| D. `Player.gd` modified | **No** |
| E. Taco Bell scenes modified | **No** |
| F. Raw kit modified | **No** (read-only) |
| G. Frame size | **200×200** |
| H. Context window | **21** (10 + current + 10), edge-truncated at sequence ends |
| I. Layers | See `selected_layers.json` (Female Base 3, Bottoms 13, Tops 24, Head 4, Hair 7) |
| J. Full frame catalog | `full_composite_frame_catalog.{json,csv,md}` |
| K. Contextual 21-frame features | `contextual_21_frame_features.{json,csv,md}` |
| L. Manual seed labels | `manual_seed_labels.{md,json}` |
| M. 21-frame context sheets | `context_windows_21/context_21_page_*.png` + `context_window_21_index.json` |
| N. Row browser | `row_browser/row_*_contact_sheet.png`, `all_rows_contact_sheet.png` |
| O. Action segments | `action_segments.{md,json,csv}` |
| P. Segment previews | `segment_contact_sheets/`, `segment_gifs/` (GIF count capped; see `segment_preview_index.json`) |
| Q. Recommended clips | `recommended_animation_clips.{md,json}` + `assets/.../c2b_context_classifier/clips/` |
| R. Diagnostic SpriteFrames | `parmida_context_classifier_spriteframes.tres` + `parmida_context_classifier_atlas.png` |
| S–Z. Clips | See `recommended_animation_clips.json` (some may be `"missing": true`) |
| AA. Rows 35/37 | **No** `walk` in `per_frame_predictions.json` for those rows |
| AB. Sandbox | `res://scenes/hideout/tools/CharacterAnimationContextClassifierSandbox_0MC2B_FIX1.tscn` |
| AC. Validator | `structural_pass: true` (see `validation.json`) |
| AD. Godot runtime | **Manual** (MCP bridge not used here) |
| AE–AG | Reports under `docs/reports/character_animation_c2b_fix1/`; pipeline + sandbox + validators |
| AH. Manual checklist | Open context pages → segments → GIFs → sandbox OptionButton clips → confirm 200×200, no 100×200, promotion NO |

## Notes

- **numpy** is required to run `character_animation_c2b_fix1_context_classifier_pipeline.py`.
- **Segment GIFs** are written for the largest segments first, capped (see `segment_preview_index.json`); **all** qualifying segments get **PNG** contact sheets.
- **attack_candidate_best** may be missing if no segment used that label — see clips JSON.
