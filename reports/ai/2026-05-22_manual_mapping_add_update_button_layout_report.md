# Manual Mapping Add/Update Button Layout Report

**Date:** 2026-05-22

## Goal

Move the **Add / Update Animation From Selection** button directly below **Saved Animations** and above **Structured Naming Panel** in the Manual Animation Mapping window. Layout only — no behavior changes.

## Files changed

- `addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd`

## What moved

In `_build_ui()`, the call order for the right sidebar was changed from:

1. Saved Animations
2. Structured Naming Panel
3. … (fields, frame range, strip, preview)
4. Add / Update

To:

1. Saved Animations
2. **Add / Update Animation From Selection**
3. Structured Naming Panel
4. … (fields, frame range, strip, preview)

`_build_add_update_button()` is unchanged; only its placement in the build sequence moved.

## Confirmation behavior was not changed

- Single button instance (`add_btn.text = "Add / Update Animation From Selection"`)
- Same `pressed.connect(_on_add_update_animation)` callback
- No edits to `_on_add_update_animation`, saved list, naming, FPS, variant, grid, or preview logic

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | One file modified |
| Diff review | Layout-only (reordered two `_build_*` calls) |
| Godot LSP diagnostics | No errors |
| Grep for button label | Exactly one occurrence |
| Godot editor visual test | **Not run** — editor/MCP unavailable |

## Checks that could not be run

- In-editor confirmation of visual order and button click

## Safety confirmation

- Repository-only; no git commit/history changes
- No production files, maps, schema, or unrelated systems touched
- Behavior preserved; layout reorder only
