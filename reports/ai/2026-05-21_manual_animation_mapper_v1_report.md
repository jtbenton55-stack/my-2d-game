# Phase 3I — Manual Animation Mapper / Reviewer v1 Report

**Date:** 2026-05-21
**Branch:** `new-feature-roadmap-branch`
**Packet type:** Editor-only art tool (no runtime/player/Taco changes)

## 1. Goal

Deliver the first safe Manual Animation Mapper / Reviewer dock for PVGames character creator sheets: load a composite sheet, configure grid, select frame ranges manually, preview, label with review status, save reviewed JSON maps, and generate validation-only `SpriteFrames` under `resources/character_animation_maps/` — without promoting outputs to production player/Taco.

## 2. Branch and baseline git status

**Before (recorded):** `new-feature-roadmap-branch` with prior Phase 3 tooling dirty state (`mission_paint_dock`, `pvgames_object_palette`, Taco scene, `project.godot`, etc.).

**After this packet (new/untracked only from 3I):**

| Path | Status |
|------|--------|
| `addons/character_animation_mapper/` | **New** |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | **New** |
| `resources/character_animation_maps/` | **New** (+ sample outputs) |
| `reports/ai/2026-05-21_manual_animation_mapper_v1_report.md` | **New** |

**Not modified by 3I:** `project.godot` (plugin not auto-enabled), `player.tscn`, `Player.gd`, Taco scenes, autoloads, raw PVGames kit PNGs, existing `parmida_player_spriteframes_0mc2b.tres`.

## 3. Files inspected

- `docs/Prompt_Improvement.md`, `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`, `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` (Manual Animation Mapper section)
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`, `docs/DECISIONS.md` (C2B diagnostic-only)
- `docs/reports/character_animation_c2b_fix1/*` (classifier reports — reference only)
- `assets/characters/generated_player_visuals/c2b_full_animation/` (composite sheet + diagnostic SpriteFrames)
- `src/tools/editor/character_animation_c2a_*` / `character_animation_c2b_*` Python pipelines (reference only)
- `addons/mission_paint_dock/` (editor plugin pattern)

## 4. Files changed

| File | Change |
|------|--------|
| `addons/character_animation_mapper/plugin.cfg` | Created |
| `addons/character_animation_mapper/CharacterAnimationMapperPlugin.gd` | Created |
| `addons/character_animation_mapper/CharacterAnimationMapperDock.tscn` | Created |
| `addons/character_animation_mapper/CharacterAnimationMapperDock.gd` | Created |
| `src/tools/editor/CharacterAnimationMapperValidator.gd` | Created |
| `resources/character_animation_maps/.gitkeep` | Created |
| `resources/character_animation_maps/generated_preview/.gitkeep` | Created |
| `resources/character_animation_maps/parmida_manual_animation_map_v1.json` | Created (validation sample) |
| `resources/character_animation_maps/generated_preview/parmida_manual_preview_spriteframes.tres` | Created (validation sample) |
| `reports/ai/2026-05-21_manual_animation_mapper_v1_report.md` | This report |

## 5. Existing animation assets/reports reused

| Asset / report | Use |
|----------------|-----|
| `parmida_player_composite_sheet_0mc2b.png` | Default sheet path in dock |
| `parmida_player_animation_metadata_0mc2b.json` | Row hints (idle row 35, walk row 37) for validation samples |
| C2B FIX1 classifier reports | **Not** imported as reviewed truth |
| `parmida_player_spriteframes_0mc2b.tres` | Read-only; never overwritten |

**No partial GDScript mapper existed** under `src/tools/editor/character_animation_mapper/`; prior work is Python diagnostic pipelines only. A new focused addon plugin was chosen over extending Python classifiers.

## 6. Implementation path

**Chosen:** Godot 4.6 editor plugin + right-dock UI (`addons/character_animation_mapper/`), mirroring Mission Paint Dock safety style.

**Why not extend C2B Python classifier:** Blueprint and `DECISIONS.md` require **manual** reviewed row/column ranges; classifier labels (`walk_best`, etc.) remain diagnostic-only.

## 7. UI / features implemented

- Title: **Character Animation Mapper**
- Status label
- Sheet path + **Load Sheet** (default C2B composite sheet)
- Frame width/height (default 200×200), columns/rows (auto from texture size), total frames readout
- Global frame range + row/column range + **Row/Column -> Global Range** + **Use Current Global Range**
- Animation name, FPS, loop, review status (`reviewed` / `needs_review` / `rejected`), notes
- **Add / Update Animation Range**, **Remove Selected Range**, range list
- **Preview Selected Range** / **Stop Preview** (editor `Timer` + `AtlasTexture` regions)
- **Save Reviewed Map JSON** / **Load Existing Map JSON**
- **Generate Validation SpriteFrames** (reviewed animations only)
- **Copy Output Path**
- Contact-sheet `TextureRect` with click-to-set start/end frame
- Frame preview panel with row/column/index readout

**Deferred v1:** drag-marquee frame selection on sheet (click sets start/end only).

## 8. Reviewed map JSON schema

Saved under `res://resources/character_animation_maps/`:

```json
{
  "schema_version": 1,
  "tool": "CharacterAnimationMapperDock",
  "source_sheet": "res://...",
  "frame_width": 200,
  "frame_height": 200,
  "columns": 12,
  "rows": 50,
  "animations": [
    {
      "animation_name": "walk",
      "start_frame": 444,
      "end_frame": 455,
      "frames": [444, 445, "..."],
      "fps": 10.0,
      "loop": true,
      "review_status": "reviewed",
      "notes": "",
      "row_column_ranges": [
        { "start_row": 37, "start_column": 0, "end_row": 37, "end_column": 11 }
      ]
    }
  ]
}
```

**Note:** Auto-detected grid for the bundled composite sheet is **12×N** (texture width 2400px), not the full 50×50 kit grid. Jake can override columns/rows after load for other sheets.

## 9. SpriteFrames generation status

**Implemented.** Generates only animations with `review_status == "reviewed"`.

- Output: `res://resources/character_animation_maps/generated_preview/parmida_manual_preview_spriteframes.tres`
- Uses `AtlasTexture` regions from the loaded sheet
- Godot may include a built-in `default` animation on new `SpriteFrames` resources (observed in validation load)

## 10. Exact output paths

| Output | Path |
|--------|------|
| Reviewed maps | `res://resources/character_animation_maps/*.json` |
| Validation SpriteFrames | `res://resources/character_animation_maps/generated_preview/*.tres` |
| Sample map (MCP validation) | `res://resources/character_animation_maps/parmida_manual_animation_map_v1.json` |
| Sample SpriteFrames | `res://resources/character_animation_maps/generated_preview/parmida_manual_preview_spriteframes.tres` |

## 11. Safety boundaries preserved

- Writes only under `resources/character_animation_maps/` (+ `generated_preview/`)
- `_is_safe_output_path()` blocks unsafe destinations
- No edits to raw kit PNGs, player, Taco, mission logic, autoloads, diagnostic C2B `.tres` in `c2b_full_animation/`
- Classifier metadata never auto-marked `reviewed`

## 12. Tests / checks

| Check | Result |
|-------|--------|
| `git status` before/after | Recorded; 3I files untracked new only |
| `project.godot` | **Not modified** by 3I |
| Script diffs for player/Taco | **None** |
| Godot MCP `validate_script` (3 scripts) | **PASS** (all compile) |
| `CharacterAnimationMapperValidator` via `class_name` in editor | **FAIL** (stale global class cache — old failure strings) |
| Inline validator (reads files from disk) | **PASS** |
| Sample map save + reload | **PASS** (2 animations) |
| Sample SpriteFrames generate + load | **PASS** (`walk` = 12 frames) |
| MainMenu `play_scene` | **PASS** (scene path confirmed before stop) |
| GdUnit4 | **Not run** — no editor-tool tests; Godot CLI not on PATH |
| Godot DAP | **Not used** |

## 13. Godot MCP Pro validation

- `validate_script`: Plugin, Dock, Validator — **valid**
- Editor workflow script: saved JSON + generated preview SpriteFrames — **OK** (`save_err: 0`, `walk_frames: 12`)

## 14. Godot LSP diagnostics

**No linter errors** on new `.gd` files (Cursor LSP).

## 15. Manual editor validation

**Requires Jake:**

1. **Project → Project Settings → Plugins** → enable **Character Animation Mapper** (not added to `project.godot` by this packet).
2. Open dock **Character Animation Mapper** (right panel).
3. **Load Sheet** → default composite path.
4. Add `needs_review_idle` + `walk` (or similar), preview, save JSON, reload JSON.
5. **Generate Validation SpriteFrames** after marking at least one range `reviewed`.
6. Confirm preview `.tres` is not assigned to `player.tscn`.

Automated MCP steps covered load/save/SpriteFrames logic; full dock UI click-through not automated.

## 16. GdUnit4

**Not run.** No `tests/` coverage for editor-only mapper; appropriate for v1.

## 17. MainMenu smoke

**Pass (limited):** `play_scene` → `res://scenes/MainMenu.tscn` (no new autoload/parse errors observed).

## 18. Kimi K2.6 MCP

**Not used.**

## 19. Safety confirmation

- Stayed inside repo; no secrets/private files accessed
- Raw PVGames kit files unchanged
- Production player/Taco unchanged
- No git history changes (commit/push not performed)

## 20. Known limitations

- Plugin **not enabled** in `project.godot` — manual enable required
- `class_name CharacterAnimationMapperValidator` may need editor restart to clear stale cache before `EditorScript` run passes
- Composite sheet auto-grid is **12 columns** for bundled asset (not full 50×50 kit page)
- Click-drag multi-frame selection not in v1
- Preview timer runs in dock only (not AnimatedSprite2D in scene)
- SpriteFrames export skips `needs_review` / `rejected` entries

## 21. Rollback plan

1. Disable/remove `addons/character_animation_mapper/`
2. Delete `src/tools/editor/CharacterAnimationMapperValidator.gd`
3. Delete test artifacts under `resources/character_animation_maps/` if desired
4. Delete this report

No player/Taco/runtime rollback needed.

## 22. Recommended next step

1. Jake enables plugin and playtests dock on full 50×50 kit sheet(s) under `assets/characters/pvgames_cyber_city_character_creator_kit/`.
2. Manually review `idle` / `walk` / `run` rows; save `parmida_manual_animation_map_v1.json`.
3. Separate **promotion pass** (future packet) to wire reviewed SpriteFrames into player — not part of 3I.

Optional v1.1: drag selection on contact sheet, grid overlay lines, import diagnostic classifier ranges as `needs_review` stubs only.
