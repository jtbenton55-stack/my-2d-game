# Manual Mapping Action Picker Report

**Date:** 2026-05-22

## Goal

Move the searchable top-100 list from the Name field to the Action section and make selections behave like action buttons: set action stem, auto-advance variant per direction, and generate full names like `land_left_01`.

## Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd` | Action picker UI; Name field restored to simple LineEdit |
| `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd` | `next_variant_for_action_direction()` helpers |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Updated static checks |

## Files intentionally left untouched

- Main dock, grid canvas, collapsible section, saved animations list, reviewed maps, schema, production files

## What was removed from the Name section

- Searchable ItemList under Animation Metadata
- Name field filter-on-type behavior tied to common stems
- `_name_pick_list`, `_on_common_name_selected`, `_on_anim_name_text_changed`

**Kept:** plain `Name` LineEdit for final animation name (manual edit, saved-entry load, Add/Update unchanged)

## New Action picker behavior

Under **Structured Naming Panel → Action** (after action buttons):
- Label: `Search common actions`
- Filter LineEdit (`_action_search_edit`)
- Scrollable 3-column ItemList (`_action_pick_list`) of top-100 stems

Selecting a list item calls `_apply_action_stem_from_picker(stem)`:
- Built-in action (`idle`, `walk`, …) → selects that action button
- Other stem (`land`, `attack_light`, …) → sets `custom` + custom stem field
- Does **not** change FPS, loop, review, notes, or frames
- Recomputes variant for `{stem}_{direction}_*` from in-memory animations
- Updates Variant spinbox, Auto-name, and final Name via `_refresh_structured_name()`

## 3-column list behavior

- `ItemList.max_columns = 3`
- `fixed_column_width = 98`
- Filtered via `filter_common_animation_names()` on search field text

## Variant auto-advance behavior

New helper: `next_variant_for_action_direction(animations, action_stem, direction)`

Examples:
- `land` + `left` with no existing `land_left_*` → variant `1` → `land_left_01`
- `idle` + `toward` with max `idle_toward_10` → variant `11` → `idle_toward_11`

Also runs when:
- Existing action buttons clicked (still updates FPS/loop for built-ins)
- Direction button clicked (re-advances variant for current stem + new direction)

## Existing systems reused

- `COMMON_ANIMATION_NAME_STEMS`, `filter_common_animation_names`, `build_structured_name`, `parse_structured_animation_name`
- Action buttons, custom stem, saved animation load, Add/Update, collapsible sections

## Systems added or modified

- `_apply_action_stem_from_picker()`, `_apply_next_variant_for_current_stem()`, `_current_action_stem()`
- Direction-scoped variant lookup (helpers)

## Validation results

| Check | Result |
|-------|--------|
| Godot LSP diagnostics | **No errors** |
| Validator checks updated | Yes |
| Godot editor manual test | **Not run** |

## Checks that could not be run

- Live picker select `land` / `idle` verification in editor
- Confirm 3-column layout visually

## Kimi usage

None.

## Safety confirmation

- Repository-only; no commits, maps, schema, or production changes
- Add/Update and dock save flow unchanged

## Known limitations

1. Common picker does not update FPS/loop (action buttons still do for built-ins).
2. Variant scope is per action stem **and** direction (changed from stem-only).
3. Editor runtime not verified this session.

## Suggested next step

Open Manual Mapping, search `land` under Action, select it with direction `left` — confirm Name shows `land_left_01` (or next variant), not bare `land`.
