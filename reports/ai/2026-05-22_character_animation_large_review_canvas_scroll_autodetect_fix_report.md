# Character Animation Mapper — Large Review Canvas scroll/autodetect fix

**Date:** 2026-05-22
**Branch:** `new-feature-roadmap-branch`
**Packet:** Phase 3I editor-tool repair (no production promotion)

## Goal

Fix blocking Large Review Canvas issues from live manual QA:

1. Manual 5-pack 10000×10000 sheets auto-detected as **50×1** instead of **50×50**.
2. After zoom, scrolling/panning showed **blank gray** outside the initial viewport.
3. Improve initial fit/UX and clarify Add/Update vs Save JSON status.

## Baseline git status

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M (unrelated files preserved)
?? addons/character_animation_mapper/
?? assets/characters/generated_player_visuals/manual_5pack_20260521/
?? resources/character_animation_maps/
?? reports/ai/...
```

## Files inspected

- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` (2026-05-22 updates)
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` (2026-05-22 updates)
- `reports/ai/2026-05-22_character_animation_large_review_canvas_report.md`
- `addons/character_animation_mapper/CharacterAnimationMapperDock.gd`
- `addons/character_animation_mapper/CharacterAnimationGridCanvas.gd`
- `addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd`
- `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd`
- `src/tools/editor/CharacterAnimationMapperValidator.gd`
- `assets/characters/generated_player_visuals/manual_5pack_20260521/manual_5pack_metadata.json`

## Files changed

| File | Change |
|------|--------|
| `CharacterAnimationMapperDock.gd` | Disk image load, grid detection, map path readout, save status |
| `CharacterAnimationGridCanvas.gd` | Full content size, full-grid draw, scroll redraw, pan redraw |
| `CharacterAnimationLargeReviewWindow.gd` | UX labels, scroll reset on fit, save-path status |
| `CharacterAnimationMapperValidator.gd` | New static checks for disk load + grid draw |

## Manual QA issues reproduced (from Jake)

- Large Review Canvas opens; zoom/selection/preview/export worked on **first visible region only**.
- Grid reported **50 columns × 1 row** for 5-pack sheets.
- Scrolling/panning after zoom showed **gray blank** for later columns/rows.
- Selection modes worked but were easy to miss in UI.
- Add/Update vs Save JSON distinction unclear.

## Root causes found

1. **50×1 autodetect:** `_on_load_sheet_pressed` used imported `Texture2D.get_width()/get_height()`. When import/clamp reports a short height (e.g. one row of pixels), `rows = height / frame_height` becomes **1** even though the PNG on disk is 10000×10000.
2. **Blank scroll regions:** Grid child did not reliably occupy full zoomed content size; draw culling used scroll offset math without guaranteed `size == content_size`, and scroll/pan did not always `queue_redraw()`. Drawing regions outside the imported/clamped texture also appeared empty.
3. **Awkward initial view:** Fit did not reset scroll offsets to (0,0).
4. **UX:** Selection summary/hover/mode controls were low-contrast; status did not state that Add/Update only updates the dock list.

## Exact fixes

### Dock (`CharacterAnimationMapperDock.gd`)

- Load sheet via `Image.load_from_file(ProjectSettings.globalize_path(path))` for true disk dimensions.
- Build runtime sheet with `ImageTexture.create_from_image(img)` so atlas regions use the full 10000×10000 image.
- Compute columns/rows from disk size ÷ frame size; apply `manual_5pack_metadata.json` fallback only when computed frame count disagrees with metadata for that sheet path.
- Status line reports disk size, column/row counts, and note if imported resource size differs.
- Added `get_map_output_path()` and visible **Map JSON output:** readout under filename field.
- Save status: `Saved Reviewed Map JSON: <path> (<n> animations).`

### Grid canvas (`CharacterAnimationGridCanvas.gd`)

- Set both `custom_minimum_size` and `size` to zoomed content size (`columns×frame_width`, `rows×frame_height`).
- `SIZE_SHRINK_BEGIN` flags so ScrollContainer scroll range matches full sheet.
- Draw **all cells** when `columns×rows ≤ 10000` (2500 for 5-pack) for correctness.
- Full grid lines across entire content; dark background under cells.
- Hook scroll bar `value_changed`, `scroll_started`, `scroll_ended` → `queue_redraw()`.
- Pan (middle/right drag) updates scroll and calls `queue_redraw()`.
- Fit/100% reset scroll to origin via `_reset_scroll_offset()`.
- Removed duplicate `class_name` to avoid global class conflict in editor.

### Large Review Window (`CharacterAnimationLargeReviewWindow.gd`)

- **Selection tools** section: prominent mode label, dedicated **Clear Selection** row, **Selection status** heading.
- Larger hover/selection labels.
- Instructions clarify Replace/Add/Remove, Clear, and Save JSON workflow.
- Fit/100% reset scroll before zoom.
- Add/Update status: `Updated animation '<name>' in dock list only. Click Save Reviewed Map JSON... <path>`.

## Systems preserved

- All existing dock buttons and workflows unchanged.
- JSON schema: `frames` authoritative; `row_column_ranges` compressed runs; reviewed-only SpriteFrames export.
- C2B import remains `needs_review` only.
- No production player/Taco/autoload/`project.godot` changes.

## Validation

| Step | Result |
|------|--------|
| `git status --short --branch` (before/after) | **PASS** — branch `new-feature-roadmap-branch`, unrelated dirty files preserved |
| `validate_script` dock / grid / window | **PASS** (after fixes) |
| `CharacterAnimationMapperValidator` (Godot MCP editor script) | **PASS** (`failures: []`) |
| Editor script: disk 10000×10000 → cols=50 rows=50 total=2500 | **PASS** (MCP `execute_editor_script`) |
| GdUnit4 | **Not run** — editor-only repair |
| Manual Godot editor steps 1–18 (scroll rows 20–40, pan, JSON round-trip, sandbox F6) | **Not run** by agent — requires Jake in editor |
| Large Review Canvas screenshot | **Not captured** |

## Godot diagnostics

- All four modified `.gd` files compile in open editor after `reload_project`.
- Removed `class_name CharacterAnimationGridCanvas` to resolve “hides a global script class” editor conflict.

## Kimi K2.6 usage

- **Pre-implementation:** Confirmed strategy — disk `Image.load`, full `ImageTexture`, fix content `size` + redraw on scroll; correctness over culling for 2500 cells.
- **Post-implementation:** Advisory on exported-build `res://` path risk, VRAM for 10000² textures, and manual regression checklist (scroll sync, JSON round-trip, plugin reload).

## Known limitations

- Full 10000×10000 `ImageTexture` in editor uses significant RAM (~400MB RGBA); acceptable for desktop tooling.
- Drawing 2500 cells per redraw is acceptable at 50×50 but may stutter if grid grows beyond 10000 cells (falls back to visible culling).
- Headless `--script` cannot run `EditorScript` validator directly (Godot requires SceneTree); validation done via MCP editor session.
- Interactive scroll/pan QA not automated in this session.

## Rollback

1. Revert the four changed `.gd` files to pre-fix versions.
2. Restore `class_name CharacterAnimationGridCanvas` if needed after clearing `.godot` global class cache.
3. Delete this report.

## Recommended next step

Jake: run manual checklist on `character_01_parmida_reference_variant_sheet.png` — confirm dock shows **50 columns, 50 rows, 2500 frames**, then scroll to row/col 20–40 in Large Review Canvas and confirm frames (not gray). Save/reload a test JSON and re-run sandbox F6.
