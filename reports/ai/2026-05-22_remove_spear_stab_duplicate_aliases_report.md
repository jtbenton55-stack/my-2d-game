# Remove spear_stab Duplicate Aliases Report

**Date:** 2026-05-22

## Goal

Remove duplicate `spear_stab_*_01` alias entries from the reviewed Parmida animation map and keep `stab_*_01` / `stab_*_02` as the canonical naming family.

## Files changed

- `resources/character_animation_maps/character__working_manual_map.json`

## Backup map path

`res://resources/character_animation_maps/character__working_manual_map_before_remove_spear_stab_aliases_20260607_200832.json`

## Removed animation names (8)

- `spear_stab_toward_01` (frames 2120..2122)
- `spear_stab_left_01` (2123..2125)
- `spear_stab_right_01` (2126..2128)
- `spear_stab_away_01` (2129..2131)
- `spear_stab_toward_left_01` (2132..2134)
- `spear_stab_away_left_01` (2135..2137)
- `spear_stab_toward_right_01` (2138..2140)
- `spear_stab_away_right_01` (2141..2143)

Each removed entry matched its corresponding `stab_*_01` entry frame-for-frame.

## Kept stab names

**stab_*_01 (8):** `stab_toward_01`, `stab_left_01`, `stab_right_01`, `stab_away_01`, `stab_toward_left_01`, `stab_away_left_01`, `stab_toward_right_01`, `stab_away_right_01`

**stab_*_02 (8):** `stab_toward_02`, `stab_left_02`, `stab_right_02`, `stab_away_02`, `stab_toward_left_02`, `stab_away_left_02`, `stab_toward_right_02`, `stab_away_right_02`

## Animation count before/after

| Metric | Before | After |
|---|---:|---:|
| Animation count | 599 | 591 |
| Covered frames | 2493 | 2493 |

## Duplicate frame validation result

Before: all frames **2120..2143** were duplicated (`spear_stab_*_01` + matching `stab_*_01`).

After: **0** duplicate frames in range 2120..2143. Covered frame count unchanged because `stab_*_01` entries remain.

## Safety confirmation

- JSON-only edit; no scripts, scenes, autoloads, or `project.godot` touched
- Timestamped backup created before edit
- Only the 8 listed `spear_stab_*_01` entries removed
- No `stab_*` entries modified
- Top-level schema/grid/source sheet unchanged

## Validation results

| Check | Result |
|---|---|
| Git status before/after | Recorded |
| Backup exists and parses | PASS |
| Updated map parses | PASS |
| Exactly 8 entries removed | PASS |
| No `spear_stab_*` remain | PASS |
| All `stab_*_01` and `stab_*_02` remain | PASS |
| No duplicate animation names | PASS |
| Frames 2120..2143 no longer duplicated | PASS |
| All remaining entries `reviewed` | PASS |
| Schema/source sheet/grid unchanged | PASS |
| Covered frame count unchanged | PASS |

## Known limitations

- `character__working_manual_map_review_todo.json` was not regenerated; refresh QA in Manual Mapping window if duplicate warnings are still listed from stale todo data
- No in-editor reload test performed this session

## Suggested next step

Reload `character__working_manual_map.json` in the Character Animation Mapper dock and confirm Saved Animations no longer lists `spear_stab_*`. Use **Mapping QA / Review → Refresh QA From Current Map** to clear stale duplicate warnings if needed.
