# PVGames Object Palette Visible-Bounds Brush Spacing Report

**Date:** 2026-05-21
**Branch:** `new-feature-roadmap-branch`
**Scope:** Auto Asset Spacing uses visible opaque/content bounds instead of full PNG dimensions

## 1. Goal

Harden PVGames Object Palette v2 brush placement so **Auto Asset Spacing** spaces repeated stamps by the **visible opaque region** of the selected texture (alpha > 0.01), eliminating gaps caused by transparent PNG padding, while preserving axis lock, UndoRedo, typed stamping, and safety boundaries.

## 2. Branch and baseline git status

**Before this packet:**

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd
 M docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md
 M scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn
 M scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn
 M src/tools/editor/PVGamesObjectPaletteDockValidator.gd
?? reports/ai/...
```

**Changed by this packet:**

- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- `src/tools/editor/PVGamesObjectPaletteDockValidator.gd`
- `reports/ai/2026-05-21_pvgames_object_palette_visible_bounds_spacing_report.md`

Unrelated dirty files were not reverted or overwritten.

## 3. Files inspected

- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` (Phase 3 palette-before-paint-dock ordering)
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` (PVGames Palette V2)
- `docs/TACO_PAINT_READINESS_CHECKLIST.md`
- `docs/TACO_VISUAL_LAYER_TAXONOMY.md`
- `reports/ai/2026-05-20_pvgames_object_palette_artroot_mouse_placement_report.md`
- `reports/ai/2026-05-20_pvgames_object_palette_brush_placement_report.md`
- `reports/ai/2026-05-21_pvgames_object_palette_brush_alignment_repair_report.md`
- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- `src/tools/editor/PVGamesObjectPaletteDockValidator.gd`
- `scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`

## 4. Files changed

| File | Change |
|------|--------|
| `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` | Visible-bounds scan, cache, auto-spacing integration, help text |
| `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` | Static checks for new helpers and help text |

## 5. Existing systems reused

- `_effective_brush_spacing(axis)` — now reads visible scaled size when auto spacing on
- `_rebuild_axis_locked_brush_points()` — unchanged deterministic axis placement
- `_selected_asset_scaled_size()` — retained as full-texture fallback inside visible-size pipeline
- `_load_texture()`, brush cache cleared on **Refresh Index**
- Typed stamp, mouse placement, UndoRedo brush commit, GameplayRoot refusal, visual-only `_create_node()`

## 6. Root cause

Auto spacing used `texture.get_size() * abs(scale)`, which includes **transparent margins** in PVGames PNGs. Centered `Sprite2D` nodes are spaced by origin distance, so full-texture width/height leaves visible gaps between opaque content.

## 7. Implementation details

### Visible bounds helper

- **`_brush_visible_size_cache`** — `Dictionary` keyed by `res://` source path → unscaled `Vector2` visible size (session-local, no file writes).
- **`_texture_visible_size(texture, source_path)`** — cache lookup; else `texture.get_image()` + compute; store result.
- **`_compute_image_visible_size(image, fallback_size)`** — scans pixels; alpha **> 0.01** (`BRUSH_VISIBLE_ALPHA_THRESHOLD`) counts as visible; returns `Vector2(max_x - min_x + 1, max_y - min_y + 1)`; falls back to full size if image null/empty/no visible pixels.
- **`_selected_asset_scaled_visible_size()`** — visible unscaled size × `abs(scale)` from `_typed_scale()`.

### `_effective_brush_spacing(axis)` when Auto Asset Spacing on

| Axis | Spacing |
|------|---------|
| Horizontal | visible scaled width |
| Vertical | visible scaled height |
| Freeform | `max(visible width, visible height)` |

If visible scaled size is zero/invalid → manual **Brush Spacing** spin (unchanged fallback).

### Other behavior

- Does **not** crop textures or change sprite pivot/position.
- Manual spacing when auto off — unchanged.
- Help text updated to mention **visible opaque bounds**.

## 8. Systems preserved

- Typed stamping (`_stamp_selected_at_position`)
- Place With Mouse / coordinate helpers
- Brush alignment (Auto Axis / Horizontal / Vertical / Freeform)
- One UndoRedo action per brush stroke
- ArtRoot target routing; `_node_is_under_gameplayroot` refusal
- No collision, physics, gameplay, mission mechanics, or tile data

## 9. Tests / checks run

| Check | Result |
|-------|--------|
| `git diff --check` | PASS (CRLF→LF warnings only) |
| Intended file scope | PASS — only dock + validator (+ this report) |
| `project.godot` | Not modified |
| Godot MCP `validate_script` — dock | **PASS** |
| Godot LSP — dock | **PASS** (no diagnostics) |
| `PVGamesObjectPaletteDockValidator.validate()` in-editor | **PASS** (`failures: []`) |
| Godot MCP visible-size comparison snippet | **Not run** — editor script compile failed in one MCP attempt (validator/script compile still PASS) |
| GdUnit4 `tests/mission_authoring/` | **Not run** — no headless GdUnit invocation in this session; palette change is editor-plugin-only |
| MainMenu smoke | **Not run** — no headless project launch in this session |
| Manual scratch drag on padded asset | **Pending Jake** — see checklist below |

## 10. Godot MCP Pro validation

- `validate_script` on `PVGamesObjectPaletteDock.gd`: **PASS**
- In-editor `PVGamesObjectPaletteDockValidator.validate()`: **PASS**
- Live brush drag / visible gap comparison: **not automated**

## 11. Godot LSP diagnostics

**PASS** — no issues on modified dock script.

## 12. GdUnit4

**Not run** (environment/session limitation). Risk assessed **low** — changes are isolated to `@tool` editor dock; no runtime autoload or mission script edits.

## 13. Manual / scratch editor validation

**Recommended on** `res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`:

1. Select a rectangular PVGames asset with transparent padding (e.g. floor/wall tile from prior gap repro).
2. Brush Mode on, **Horizontal**, **Auto Asset Spacing** on — drag strip; opaque edges should touch or be much closer vs prior full-texture spacing.
3. Undo once removes whole stroke.
4. **Vertical** alignment — same X, improved vertical edge spacing.
5. **Freeform** + auto on — uses max visible dimension.
6. Auto off — manual Brush Spacing applies.
7. Typed stamp + undo still work.

## 14. Kimi usage

**Not used.** Change is a straightforward alpha-bounds scan with documented Godot `Texture2D.get_image()` API; no external advisory required. No secrets or private files sent.

## 15. Safety confirmation

- Stayed inside repo workspace
- Did not access secrets, `.env`, credentials, or unrelated personal files
- Did not commit, push, rebase, reset, stash, or change branches
- Did not modify `project.godot`, autoloads, IsoMissionBase, Phase0J/0K, collision, or production Taco gameplay scripts
- Did not save production Taco scenes in this packet

## 16. Known limitations

- First visible-size compute per texture path scans all pixels (cached afterward); very large PNGs may hitch once on first brush use.
- Scan uses full texture image, not atlas sub-rect metadata (icons still use full loaded PNG bounds).
- Does not adjust sprite offset for visible-bounds centering — spacing only.
- Manual editor confirmation still needed for perceptual gap improvement on specific padded assets.

## 17. Rollback plan

```bash
git checkout -- addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd
git checkout -- src/tools/editor/PVGamesObjectPaletteDockValidator.gd
```

Reload Godot editor / PVGames Object Palette plugin.

## 18. Recommended next step

1. Jake: manual confirm on scratch test scene with a previously gappy repeatable asset.
2. If gaps remain on specific assets: follow-up **minimal spacing multiplier/trim** control (not in this packet).
3. If brush basics validated: proceed to **Phase 3G manifest–code-gate corridor wayfinding** or **Mission Paint Dock** per roadmap priority.
