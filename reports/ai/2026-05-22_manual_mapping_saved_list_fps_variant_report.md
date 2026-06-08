# Manual Mapping Saved List, FPS Quick-Set, Variant Auto-Advance Report

**Date:** 2026-05-22
**Project:** Character Animation Mapper (Godot 4.6.2)

## Goal

Add three workflow helpers to the Manual Animation Mapping pop-out:
1. Saved animation selector/list (upper-right sidebar)
2. Common FPS quick-set buttons
3. Variant auto-advance when clicking action buttons

No JSON schema, production runtime, or main dock save flow changes.

## Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd` | Saved animations `ItemList`, load entry workflow, FPS quick buttons, variant auto-advance |
| `addons/character_animation_mapper/CharacterAnimationMapperDock.gd` | `get_animation_entries_snapshot()`, `get_animation_entry_at()`, list refresh notify; dock list label uses shared helper |
| `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd` | `format_animation_list_label`, `parse_structured_animation_name`, variant helpers |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Static checks for new APIs and UI |

## Files intentionally left untouched

- `CharacterAnimationGridCanvas.gd`
- `CharacterAnimationLargeReviewWindow.gd`
- `CharacterAnimationCandidateStrip.gd`
- `project.godot`, production scenes, autoloads
- `character__working_manual_map.json` and all reviewed maps
- Raw spritesheet assets

## Saved animation selector/list behavior

- **Section:** `Saved Animations` at top of right sidebar (upper-right area)
- **Control:** Compact `ItemList` (140px min height)
- **Labels:** Same format as main dock via `MAPPER_HELPERS.format_animation_list_label()`
  e.g. `walk_toward_01 [0..7] reviewed fps=10.1 loop=true`
- **Populate:** On window open (`setup_from_dock`) and after Add/Update; also when dock `_refresh_range_list()` runs while manual window is visible
- **Select entry:** Loads frames onto grid, focuses selection, updates start/end, strip, preview, name, FPS, loop, review, notes
- **Naming parse:** If name matches `{action}_{direction}_{variant}` pattern (directions with underscores supported), direction/action/variant/custom stem controls update; ambiguous names leave unparseable controls unchanged
- **No JSON write** on selection; no duplicate entries created

## FPS quick button behavior

Buttons below FPS spinbox: **6, 8, 10, 10.1, 12, 15, 24**

- Sets FPS spinbox value on click
- If preview is playing, timer interval updates immediately
- Does not change frames or save until Add/Update or dock Save JSON

## Variant auto-advance behavior

- On **action button click**, variant sets to `next_variant_for_action_stem()` from in-memory dock list
- Compares parsed `action_stem` from existing animation names (e.g. all `idle_*` → max variant + 1)
- **Custom action:** uses custom stem text when action = `custom`
- **No existing animations for stem:** variant = `1`
- **Selecting saved animation:** variant loaded from parsed name (does not auto-advance)
- **Manual variant edits:** preserved until next action button click
- Auto-name label updates; name field updates on action/direction/variant changes except while loading a saved entry

## Existing systems reused

- Dock in-memory `_animations` via snapshot API (defensive duplicates)
- `MAPPER_HELPERS.frames_from_entry`, `build_structured_name`, `build_animation_entry`
- Grid focus/selection/strip/preview/Add-Update flow unchanged
- Dock `_refresh_range_list()` + manual window refresh hook

## Systems added or modified

### Helpers
- `format_animation_list_label(entry)`
- `parse_structured_animation_name(name)` — longest-direction match, numeric suffix variant
- `highest_variant_for_action_stem(animations, stem)`
- `next_variant_for_action_stem(animations, stem)`

### Dock
- `get_animation_entries_snapshot()` / `get_animation_entry_at(index)`
- `_notify_manual_mapping_list_changed()` from `_refresh_range_list()`

### Manual window
- `refresh_saved_animations_list()`, `_load_animation_entry()`, `_apply_next_variant_for_action()`
- `_loading_saved_entry` guard prevents clobbering loaded name during saved-entry load

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | Run; 4 files modified |
| Name parse logic (Python mirror) | **PASS** — `walk_toward_01`, `idle_away_right_10`, `death_left_02` |
| Static validator mirror | **PASS** |
| Godot LSP diagnostics | **No errors** |
| Godot MCP Pro | **Not run** — editor not connected |
| In-editor manual test | **Not run** |
| Reviewed map JSON | **Unmodified** |

## Checks that could not be run

- Load Parmida sheet + working map in Godot
- Saved animations list population with 221 animations
- Select `walk_toward_01` and verify full field/grid load
- FPS quick buttons live test
- Action button variant auto-advance with real map data
- Large Review Canvas smoke test

## Kimi usage

None.

## Safety confirmation

- Repository-only; no git commit/history changes
- No production/runtime/map/schema changes
- Add/Update and dock Save JSON flow preserved
- Large Review Canvas and existing manual mapping navigation preserved

## Known limitations

1. Name parsing requires standard `{stem}_{direction}_{NN}` pattern; non-conforming names load fields but may not update direction/action/variant controls.
2. Custom multi-underscore stems rely on longest direction suffix match; extremely ambiguous names may not parse.
3. Saved list does not highlight the entry matching current form fields until user selects it.
4. Editor runtime not verified this session.

## Suggested next step

Open Manual Mapping Window after loading `character__working_manual_map.json`, select `walk_toward_01` from **Saved Animations**, confirm grid focus and fields, then click **idle** and verify variant jumps to next idle number (e.g. 11 if `idle_*_10` exists).
