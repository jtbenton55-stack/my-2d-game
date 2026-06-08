# Character Animation Mapper — Collapsible Sections, Defaults, Name Dropdown Report

**Date:** 2026-05-22

## Goal

Three focused UX improvements:
1. Searchable common animation name picker in Manual Mapping window (top 100 stems)
2. Default dock sheet/map to current Parmida manual 5-pack assets
3. Collapsible major sections in main dock and Manual Mapping window

## Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationCollapsibleSection.gd` | **New** — reusable ▼/▶ section toggle |
| `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd` | `COMMON_ANIMATION_NAME_STEMS` (100), `filter_common_animation_names()` |
| `addons/character_animation_mapper/CharacterAnimationMapperDock.gd` | Default sheet/map constants; collapsible major sections |
| `addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd` | Searchable name list; collapsible sections |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Static checks for new features |

## Files intentionally left untouched

- `CharacterAnimationGridCanvas.gd`, `CharacterAnimationLargeReviewWindow.gd`
- `project.godot`, production scenes, autoloads, reviewed/candidate maps, spritesheets
- JSON schema

## Default sheet/map changes

| Setting | New default |
|---------|-------------|
| Sheet path | `res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_01_parmida_reference_variant_sheet.png` |
| Map JSON filename | `character__working_manual_map.json` |

User can still edit both fields; no auto-load/save behavior added.

## Searchable animation name dropdown behavior

In Manual Mapping **Animation Metadata** section:
- **LineEdit** for search/type (still `_anim_name`, used by Add/Update)
- **ItemList** below shows filtered top-100 common stems
- Typing filters list (`filter_common_animation_names`)
- Clicking a list item sets Name field
- Custom full names still supported (type directly or from saved animation load)
- Structured naming (direction/action/variant) still regenerates auto-name on button clicks
- Saved animation selection still fills Name via `_set_anim_name_text()`

## Collapsible section behavior

Shared `CharacterAnimationCollapsibleSection`: flat button heading with `▼` / `▶`, content `VBoxContainer` toggles visibility.

**Main dock** (default expanded unless noted):
- Spritesheet, Frame Grid, Range Selection, Animation Metadata, Saved Ranges, Map I/O — **expanded**
- C2B Diagnostic Import, Export / Sandbox, Sheet Contact View, Frame Preview — **collapsed**

**Manual Mapping window** (all major sections **expanded** by default):
- Saved Animations, Structured Naming Panel, Animation Metadata, Frame Range, Selected Frame Strip, Animation Preview

Add/Update button remains between Saved Animations and Structured Naming (not inside a collapsible block).

## Existing systems reused

- All selection, preview, strip, zoom, jump, saved list, FPS quick, variant auto-advance, Add/Update, dock save flows
- `build_structured_name`, `parse_structured_animation_name`, dock animation snapshot API

## Systems added or modified

- New collapsible section control (minimal, shared)
- Name search list wired to existing `_anim_name` field
- Dock `_begin_collapsible_section()` helper

## Validation results

| Check | Result |
|-------|--------|
| Godot LSP diagnostics | **No errors** |
| Validator static checks updated | Yes |
| Godot editor manual test | **Not run** |
| Reviewed map JSON | **Unmodified** |

## Checks that could not be run

- Live Godot dock/window UI verification
- Collapse/expand interaction test
- Name search/select live test

## Kimi usage

None.

## Safety confirmation

- Repository-only; no git commit/history changes
- No production/runtime/map/schema changes
- Behavior preserved; UI/layout enhancements only

## Known limitations

1. Common name list sets **stem** text (e.g. `walk`), not full `walk_toward_01` — direction/variant buttons still build full names.
2. Collapse state does not persist across editor sessions.
3. Main dock `_heading()` helper remains but major sections now use collapsible toggles.
4. Editor runtime not verified this session.

## Suggested next step

Open Character Animation Mapper dock — confirm default sheet/map paths — load sheet + map — open Manual Mapping — search `attack` in Name field — collapse/expand a section — verify Add/Update still works.
