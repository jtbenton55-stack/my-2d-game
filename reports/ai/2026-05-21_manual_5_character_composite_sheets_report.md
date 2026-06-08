# Manual 5 Character Composite Sheets Report

**Date:** 2026-05-21
**Scope:** Generated five PVGames composite character sheets plus contact-sheet preview for Character Animation Mapper review

## Goal

Create five varied character composite sheets from repo-local PVGames Character Creator Kit layers. Each output sheet uses the 200x200, 50-column, 50-row grid expected by the Character Animation Mapper for full-kit sheets.

## Files generated

| Character | Gender | Sheet | Layer count |
|---|---|---|---:|
| character_01_parmida_reference_variant | Female | `assets/characters/generated_player_visuals/manual_5pack_20260521/character_01_parmida_reference_variant_sheet.png` | 6 |
| character_02_neon_runner | Female | `assets/characters/generated_player_visuals/manual_5pack_20260521/character_02_neon_runner_sheet.png` | 6 |
| character_03_cyber_tech | Female | `assets/characters/generated_player_visuals/manual_5pack_20260521/character_03_cyber_tech_sheet.png` | 7 |
| character_04_street_bruiser | Male | `assets/characters/generated_player_visuals/manual_5pack_20260521/character_04_street_bruiser_sheet.png` | 8 |
| character_05_nocturne_guard | Male | `assets/characters/generated_player_visuals/manual_5pack_20260521/character_05_nocturne_guard_sheet.png` | 8 |

Additional outputs:

- Metadata: `assets/characters/generated_player_visuals/manual_5pack_20260521/manual_5pack_metadata.json`
- Contact sheet preview: `assets/characters/generated_player_visuals/manual_5pack_20260521/manual_5pack_contact_sheet_preview.png`

## Safety

- Raw PVGames kit spritesheets were read only.
- No production player, Taco scene, autoload, mission logic, or project settings were modified.
- Outputs are isolated under `assets/characters/generated_player_visuals/manual_5pack_20260521/`.

## Mapper usage

Load any generated `*_sheet.png` into Character Animation Mapper with:

- Frame width: `200`
- Frame height: `200`
- Columns: `50`
- Rows: `50`

Use the contact sheet preview for quick visual comparison before detailed row/range review.

## Validation

- Source sheets were required to exist and match 10000x10000 pixels.
- Each generated character sheet is 10000x10000 pixels.
- Each generated character sheet has 2500 frames at 200x200.
