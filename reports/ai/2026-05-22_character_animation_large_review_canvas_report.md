# Character Animation Mapper — Large Review Canvas

**Date:** 2026-05-22
**Branch:** `new-feature-roadmap-branch`
**Agent:** Cursor Ultra Auto

## Goal

Add a **Large Review Canvas** popup to the Character Animation Mapper editor dock for accurate manual frame picking on 10000×10000 (50×50 × 200×200) PVGames spritesheets, with zoom/pan, linear global drag selection, Replace/Add/Remove modes, in-popup labeling/preview, and backward-compatible JSON/`frames` authority — without trusting the old Parmida reviewed map.

## Baseline git status (start of task)

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M addons/pvgames_object_palette/...
 M project.godot
 M scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn
 ... (unrelated dirty files preserved)
?? addons/character_animation_mapper/
?? resources/character_animation_maps/
?? src/tools/editor/CharacterAnimationMapperValidator.gd
```

No commits made. Unrelated worktree changes preserved.

## Files inspected

- `addons/character_animation_mapper/CharacterAnimationMapperDock.gd`
- `addons/character_animation_mapper/CharacterAnimationMapperDock.tscn`
- `addons/character_animation_mapper/CharacterAnimationMapperPlugin.gd`
- `addons/character_animation_mapper/plugin.cfg`
- `src/tools/editor/CharacterAnimationMapperValidator.gd`
- `scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn`
- `src/tools/editor/CharacterAnimationMapperPreviewSandbox.gd`
- `resources/character_animation_maps/` (schema samples only; **not** `parmida_manual_animation_map_v1.json` as truth)
- `assets/characters/generated_player_visuals/manual_5pack_20260521/manual_5pack_metadata.json`
- Prior reports under `reports/ai/` (3I v1 / v1.1)

## Files changed / added

| File | Role |
|------|------|
| `addons/character_animation_mapper/CharacterAnimationGridCanvas.gd` | Efficient grid draw, zoom/pan, linear selection, modes |
| `addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd` | Large popup UI, preview, labeling, dock bridge |
| `addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd` | `build_animation_entry`, `row_column_ranges`, summaries |
| `addons/character_animation_mapper/CharacterAnimationMapperDock.gd` | Button + dock APIs + `_current_selection_frames` |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Static checks for new feature |

## Implementation path

- **Split responsibilities:** dock keeps sheet I/O, `_animations`, JSON, SpriteFrames export; grid canvas owns rendering/selection; window owns popup UX.
- **No 2500 TextureRects:** `CharacterAnimationGridCanvas` uses `_draw` + `draw_texture_rect_region` with scroll-based visible culling.
- **Linear drag:** `_linear_frames_between(a,b)` selects global indices along row-major order (not a rectangle).
- **Signals/callbacks:** dock exposes `get_large_review_state`, `apply_canvas_selection_to_dock`, `upsert_animation_from_canvas`, `get_dock_selection_frames`.
- **Avoided bloating dock** (~150 lines of integration vs monolithic canvas in dock).

## How Large Review Canvas works

1. Load sheet in dock → set 50 cols / 50 rows / 200×200 frames (auto from image size on load).
2. Click **Open Large Review Canvas** → resizable `Window` (~90% editor viewport, min 1200×800).
3. Left: instructions, zoom controls, selection mode (Replace / Add / Remove), selection actions, scrollable grid.
4. Right: animation name/FPS/loop/review/notes, FPS presets, Add/Update Animation, preview area + Play/Stop.
5. Drag first→last frame in **global order**; cross-row drags select linear sequence.
6. **Apply Selection To Dock** updates dock spins + `_current_selection_frames`.
7. **Add / Update Animation From Selection** writes to dock `_animations` via `CharacterAnimationMapperHelpers.build_animation_entry`.
8. Save JSON / Generate SpriteFrames from **main dock** (unchanged workflow).

## JSON / schema behavior

- **`frames`:** authoritative ordered list (sorted on save from selection).
- **`start_frame` / `end_frame`:** min/max of sorted `frames`.
- **`row_column_ranges`:** compressed contiguous global runs (multiple runs for gaps).
- Non-contiguous Add/Remove selections preserve exact `frames`; dock **Add / Update Animation Range** uses `_current_selection_frames` when set.
- SpriteFrames export unchanged: uses `_frames_from_entry()` → explicit `frames` when present; **reviewed** only.

## Systems preserved

- Small Sheet Contact View
- C2B candidate import (`needs_review` only)
- Safe output path guards
- Preview sandbox (hideout only)
- No changes to player/Taco scenes, autoloads, `project.godot`, or raw PVGames kit PNGs

## Tests / checks

| Check | Result |
|-------|--------|
| `CharacterAnimationMapperValidator` (Godot MCP `execute_editor_script`) | **PASS** (`failures: []`) |
| `validate_script` — `CharacterAnimationMapperDock.gd` | **PASS** |
| `validate_script` — `CharacterAnimationGridCanvas.gd` | **PASS** |
| `validate_script` — `CharacterAnimationLargeReviewWindow.gd` | **PASS** (after removing duplicate `class_name`) |
| GdUnit4 | **Not run** — no unit tests added; editor-only UI |
| Manual in-editor: load 5pack sheet, open canvas, zoom/pan, drag cross-row | **Not run** — requires Jake with plugin enabled |
| Manual: JSON round-trip `test_canvas_selection_needs_review` | **Not run** |
| Manual: SpriteFrames + sandbox play | **Not run** |
| Godot MCP screenshot of Large Review Canvas | **Not captured** — canvas not opened in live editor session |
| MainMenu / global smoke | **Skipped** — editor-tool-only; no autoload/scene graph changes |

## Godot diagnostics

- LSP workspace scan: **no new errors** in mapper scripts after reload.
- Fixed compile issues: duplicate global `class_name` on Window; `get_visible_rect()` replaced with scroll-based `_visible_canvas_rect()`; `MAPPER_HELPERS` preload naming to avoid hiding `CharacterAnimationMapperHelpers` class.

## Kimi K2.6 (advisory)

**Architecture review (pre-fix):** risks noted — orphaned Window on plugin reload, grid-dimension mismatch invalidating global indices, dock/window desync, scroll+zoom coordinate mismatch, no EditorUndoRedo.

**Regression review (post-impl):** recommended manual tests — scroll/zoom alignment, dock↔canvas selection sync, Replace/Add/Remove drag behavior, window open/close lifecycle, preview timer cleanup, JSON export integrity, stress on full 50×50 sheet.

Kimi was **advisory only**; Cursor implemented and validated compile/static checks.

## Screenshots / observations

- No screenshot captured (editor canvas not opened in automated session).
- Validator and script compile checks confirm files and string contracts are present.

## Known limitations

- No EditorUndoRedo integration for canvas edits.
- Window parented to editor base control; plugin disable while window open may leave stale window (close window first).
- Very large textures may log Godot large-image warnings (non-fatal).
- `class_name` removed from `CharacterAnimationLargeReviewWindow` to avoid global class conflict; dock uses `preload` + `Window` typed ref.
- Full interactive QA (zoom accuracy, cross-row drag, JSON round-trip) requires manual Godot editor session with plugin enabled.

## Rollback

1. Remove `CharacterAnimationGridCanvas.gd`, `CharacterAnimationLargeReviewWindow.gd`, `CharacterAnimationMapperHelpers.gd`.
2. Revert `CharacterAnimationMapperDock.gd` integration block and button.
3. Revert `CharacterAnimationMapperValidator.gd` Large Review checks.
4. Delete this report if desired.

## Recommended next step

1. Enable **Character Animation Mapper** in Project Settings → Plugins.
2. Load `character_01_parmida_reference_variant_sheet.png` from `manual_5pack_20260521`.
3. Run the manual checklist in Kimi regression review (especially cross-row linear drag and JSON reload of exact `frames`).
4. Save a test map as `test_canvas_selection_needs_review.json`, mark one range **reviewed**, generate validation SpriteFrames, open preview sandbox.
