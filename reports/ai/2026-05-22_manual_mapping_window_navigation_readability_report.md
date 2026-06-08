# Manual Mapping Window Navigation & Readability Report

**Date:** 2026-05-22
**Project:** Character Animation Mapper (Godot 4.6.2)

## Goal

Improve the Manual Animation Mapping pop-out so the red-outlined frame grid is the primary working surface — larger viewport, better navigation (jump/focus/zoom), clearer selected/hovered frames, and preview/strip/hover moved off the grid column into the right sidebar.

## Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd` | Layout rework, navigation controls, grid-first sizing, sidebar for strip/preview |
| `addons/character_animation_mapper/CharacterAnimationGridCanvas.gd` | Scroll APIs, readability visuals, ctrl+wheel option, double-click focus, max zoom 12x |
| `addons/character_animation_mapper/CharacterAnimationMapperDock.gd` | Manual window opens at ~92% viewport (min 1200×820) |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Static checks for new nav/grid APIs |

## Layout changes

**Before:** Left column held grid + start/end + strip + preview; right column held naming only.

**After:**
- **Left/center (~80% width):** status, zoom/navigation rows, large scrollable grid only (`GRID_VIEWPORT_MIN` 720×540)
- **Right sidebar (~20%, scrollable):** structured naming → name/fps/loop/review/notes → start/end frames → selected frame strip → strip hover zoom → animation preview + Play/Stop → Add/Update

Default window: 1440×920 (min 1120×720). Dock opens manual window at 92% viewport.

Initial zoom after Fit enforces a minimum readable zoom (~22%) when fit-to-viewport would be too small.

## Navigation controls added

Near the grid:
- **Zoom Out / In / Fit / 100%** (existing, retained)
- **Preset zoom:** `2x`, `4x`, `8x`, `12x` (sets canvas zoom 2.0–12.0)
- **Jump Frame** spinbox + **Go**
- **Jump Row** spinbox + **Go**
- **Focus Selection** — centers viewport on current selection
- Hover/selection sync jump spinboxes automatically

Grid canvas APIs:
- `scroll_to_frame(global_index, center)`
- `scroll_to_row(row, center)`
- `scroll_to_cell(row, column, center)`
- `focus_selection()`

## Visual readability changes

In `CharacterAnimationGridCanvas.gd` (shared; benefits Large Review Canvas too):
- Selected frames: light red tint + thick red outline (`SELECTED_OUTLINE`)
- Hover: stronger red outline (thicker than before)
- Grid lines: scale slightly with zoom
- Axis labels every 10 rows/columns (`r0`, `c0`, …) when zoom ≥ ~14%
- `MAX_ZOOM` raised from 4.0 to 12.0 for close inspection

## Mouse interaction changes

Manual window enables on grid:
- **Ctrl + wheel** = zoom (wheel alone pans scroll viewport)
- **Shift + wheel** = horizontal pan when ctrl zoom mode active
- **Middle / right drag** = pan (already existed; unchanged)
- **Double-click frame** = select single frame + scroll to center

Large Review Canvas unchanged (ctrl wheel flag defaults off; wheel still zooms as before).

## Existing functionality preserved

- Click/drag selection (replace/add/remove)
- Start/end spinboxes ↔ selection sync
- Selected frame strip + hover zoom
- Play/Stop preview with FPS/loop
- Structured naming + Add/Update → `upsert_animation_from_canvas`
- JSON save via main dock only
- Large Review Canvas and normal candidate workflow untouched
- No reviewed map or schema changes

## Validation results

| Check | Result |
|-------|--------|
| `git status` before/after | Run; 4 files touched |
| Static Python validator mirror | **PASS** |
| Godot LSP diagnostics | **No errors** |
| Godot MCP Pro `validate_script` | **Not run** — editor not connected |
| In-editor manual test | **Not run** |

## Checks that could not be run

- Godot editor open / Manual Mapping Window visual verification
- Jump to frame/row, focus selection, preset zoom in live grid
- Strip hover, preview, Add/Update temporary animation test
- Large Review Canvas regression smoke test in editor

## Kimi usage

None.

## Safety confirmation

- Repository-only edits; no git commit/history changes
- No `project.godot`, production scenes, autoloads, spritesheets, or reviewed maps modified
- JSON schema unchanged
- Targeted UI/grid changes only; no mapper rewrite

## Known limitations

1. **Show Current Row Only** not implemented — deferred as future work.
2. Start/end spinboxes still edit contiguous ranges only.
3. Preset `12x` hits max zoom; very large sheets may still need Jump/Focus for distant rows.
4. Runtime/editor UX not verified this session (Godot MCP offline).

## Suggested next step

Open Godot, load Parmida sheet + working map, open **Manual Mapping Window**, and confirm:
1. Grid dominates left side at usable size
2. Jump Frame / Jump Row / Focus Selection replace scrollbar hunting
3. Ctrl+wheel zoom and wheel pan feel natural
4. Selected frames show clear red tint/outline at 4x–8x presets
