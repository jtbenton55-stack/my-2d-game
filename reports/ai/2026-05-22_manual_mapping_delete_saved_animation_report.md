# Manual Mapping Delete Saved Animation Report

**Date:** 2026-05-22

## Goal

Add a safe in-memory delete workflow for saved animations in the Manual Animation Mapping window. Deletion updates the dock list immediately; JSON persists only via main dock **Save Reviewed Map JSON**.

## Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationMapperDock.gd` | `delete_animation_by_index()` API |
| `addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd` | Delete button, confirmation dialog, selection tracking, field reset |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Static checks for delete API and UI |

## Files intentionally left untouched

- Helpers, grid canvas, reviewed map JSON files, schema, production scenes, `project.godot`

## Delete button placement

Inside **Saved Animations** collapsible section, directly below the saved animations `ItemList`.

- Label: **Delete Selected Animation**
- Hidden and disabled when no saved animation is selected
- Visible and enabled when a saved animation is selected

## Delete behavior

1. User selects entry in Saved Animations list → fields load (unchanged) + delete button enables
2. User clicks **Delete Selected Animation** → confirmation dialog
3. On confirm → `dock.delete_animation_by_index(_selected_saved_anim_index)`
4. Dock removes entry from `_animations`, adjusts `_selected_anim_index`, refreshes range list/export readout (no JSON write)
5. Manual window clears grid/fields, refreshes saved list, disables delete button
6. Status explains deletion is in-memory until **Save Reviewed Map JSON**

Index-based deletion matches snapshot order from `get_animation_entries_snapshot()`.

## Confirmation behavior

Godot `ConfirmationDialog`:
- Title: Delete Animation
- Message includes animation name and note that JSON writes only happen on main dock save
- Cancel leaves list unchanged

## Dock API added/reused

**Added:** `delete_animation_by_index(index: int) -> Dictionary`

- Returns `{ok, message, animation_name}` on success/failure
- Reuses same in-memory removal pattern as `_on_remove_range()` but index-explicit for manual window mapping
- Calls `_refresh_range_list()` → also notifies manual window list refresh when open

## Save semantics

- JSON file **not** touched on delete
- Main dock saved ranges list updates immediately
- Manual Mapping saved list updates immediately
- **Save Reviewed Map JSON** writes the updated in-memory list (deleted animation absent)

## Validation results

| Check | Result |
|-------|--------|
| Godot LSP diagnostics | **No errors** |
| Validator checks updated | Yes |
| Godot editor manual test | **Not run** |
| Reviewed map JSON | **Not modified** |

## Checks that could not be run

- Live delete/cancel/save flow in Godot editor

## Kimi usage

None.

## Safety confirmation

- Repository-only; no commits or map file writes during implementation
- No schema, production, or sprite/map file deletion
- Add/Update and existing workflows preserved

## Known limitations

1. Delete uses list index; if dock list order changes between select and delete without refresh, user should re-select (refresh on list rebuild clears selection).
2. Editor runtime not verified this session.

## Suggested next step

Load working map, add a temporary test animation via Add/Update, select it in Saved Animations, delete with confirmation, verify both lists update, then save JSON only if intentionally persisting the test deletion.
