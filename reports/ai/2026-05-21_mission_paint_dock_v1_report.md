# Mission Paint Dock v1 Report

**Date:** 2026-05-21
**Branch:** `new-feature-roadmap-branch`
**Scope:** New editor dock for visual + layout blockout + collision barrier TileMapLayer painting

## 1. Goal

Implement **Mission Paint Dock** — a focused Godot 4.6.2 editor plugin for painting/erasing mission `TileMapLayer` cells with:

- Default **Visual Paint** mode (ArtRoot visual layers only)
- Locked **Layout Blockout** mode (floor/wall/cover/marker under `GameplayRoot/LayoutRoot`)
- Extra-locked **Collision Barrier** mode (`CollisionBarrierLayer`)
- One UndoRedo action per stroke
- No gameplay node spawning

## 2. Branch and baseline git status

**Before packet (unrelated dirty files present):**

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M addons/pvgames_object_palette/...
 M docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md
 M scenes/...
```

**Added by this packet:**

```
?? addons/mission_paint_dock/
?? src/tools/editor/MissionPaintDockValidator.gd
?? reports/ai/2026-05-21_mission_paint_dock_v1_report.md
```

`project.godot` **not modified** (plugin enable is manual).

## 3. Files inspected

- Phase 3 docs (`PLUG_AND_PLAY_*`, `TACO_*`, `ISO_EDITOR_TILE_PALETTE.md`)
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (layer paths)
- `assets/tilesets/iso_blockout_clean/IsoBlockoutTileset_Clean.tres`
- `assets/tilesets/marker_authoring/MarkerAuthoringTileset.tres`
- `addons/pvgames_object_palette/` (input/coordinate patterns)

## 4. Files changed

| Path | Role |
|------|------|
| `addons/mission_paint_dock/plugin.cfg` | Plugin manifest |
| `addons/mission_paint_dock/MissionPaintDockPlugin.gd` | EditorPlugin, dock + canvas forward |
| `addons/mission_paint_dock/MissionPaintDock.tscn` | Dock scene root |
| `addons/mission_paint_dock/MissionPaintDock.gd` | Dock UI + paint logic |
| `src/tools/editor/MissionPaintDockValidator.gd` | Static validator |
| `reports/ai/2026-05-21_mission_paint_dock_v1_report.md` | This report |

## 5. Existing systems reused

- PVGames palette pattern: `get_editor_viewport_2d()`, `get_mouse_position()`, canvas inverse transform, `layer.get_global_transform().affine_inverse()`
- `MissionBlockoutValidator` tile constants: wall `(1,0)`, cover `(2,0)`
- `ISO_EDITOR_TILE_PALETTE.md` layer paths and tileset paths
- Taco scene layout: `IsoBlockoutTileset_Clean.tres` on layout layers; `MarkerAuthoringTileset.tres` on `MarkerTileLayer`

## 6. New plugin/dock architecture

```
MissionPaintDockPlugin (EditorPlugin)
  └─ MissionPaintDock (VBoxContainer @tool)
       ├─ Mode + lock UI
       ├─ Target layer / tile preset / operation
       ├─ Arm Paint Tool
       └─ handle_canvas_gui_input() → paint/erase stroke
```

- Plugin calls `set_input_event_forwarding_always_enabled()` (Godot 4.6 no-arg API).
- Dock returns `false` from `handle_canvas_gui_input` when **not armed**, so disarmed mode does not consume viewport input.
- Stroke applies live; **Esc** reverts pending stroke; **UndoRedo** commits one action per completed stroke.

## 7. Mode behavior

| Mode | Targets | Locks required |
|------|---------|----------------|
| **Visual Paint** | `ArtRoot` `TileMapLayer` nodes with `collision_enabled == false` (discovered on Refresh) | None |
| **Layout Blockout** | `FloorLayer`, `WallLayer`, `CoverLayer`, `MarkerTileLayer` | `Unlock Layout Blockout Painting` |
| **Collision Barrier** | `CollisionBarrierLayer` | Layout unlock **and** `Unlock Collision Barrier Painting` |

Cross-mode guards:

- Visual mode refuses `GameplayRoot` paths.
- Layout/collision modes refuse `ArtRoot` paths.
- All modes refuse `GeneratedRuntimeCollision` and disabled gameplay tile layers.

## 8. Target layer routing

Preset paths (dropdown by mode):

- `GameplayRoot/LayoutRoot/FloorLayer`
- `GameplayRoot/LayoutRoot/WallLayer`
- `GameplayRoot/LayoutRoot/CoverLayer`
- `GameplayRoot/LayoutRoot/MarkerTileLayer`
- `GameplayRoot/LayoutRoot/CollisionBarrierLayer`

Visual mode: dynamic list from scene scan (`Refresh Scene Layers`).

## 9. Tile presets verified

| Preset | TileSet | source_id | atlas | Verified on Taco FloorLayer |
|--------|---------|-----------|-------|------------------------------|
| Floor (white) | `IsoBlockoutTileset_Clean.tres` | 0 | (0, 0) | Yes (`has_tile`) |
| Wall (black) | same | 0 | (1, 0) | Same tileset on WallLayer |
| Cover | same | 0 | (2, 0) | Same tileset on CoverLayer |
| Collision Barrier | same | 0 | (1, 0) | Same tileset on CollisionBarrierLayer (barrier uses blockout wall tile) |
| Marker OBJ | `MarkerAuthoringTileset.tres` | 0 | (0, 0) | Marker layer uses marker tileset |
| Eraser | — | — | erase_cell | N/A |

Presets validate against target layer `tile_set.resource_path` and `TileSetAtlasSource.has_tile()` before painting.

## 10. Safety gates

- No open scene → refuse
- Missing / non-`TileMapLayer` target → refuse
- Mode/lock mismatch → refuse with status text
- Forbidden paths (`GeneratedRuntimeCollision`, gameplay tile layers, etc.) → refuse
- No `StaticBody2D` / `Area2D` / `CollisionShape2D` instantiation
- Collision warning label shown in dock

## 11. UndoRedo behavior

- Action name: `Mission Paint Stroke`
- Stores per-cell previous `source_id`, `atlas_coords`, `alternative_tile`, and erase state
- Do: `set_cell` or `erase_cell`; Undo: restore previous or erase
- Cancel (Esc): reverts live stroke without creating UndoRedo entry

## 12. Validator coverage

`MissionPaintDockValidator.gd` checks plugin/dock existence, modes, locks, required paths, `TileMapLayer` APIs, UndoRedo, forbidden collision node creation, and plugin canvas forwarding.

**Note:** In-editor `validate()` may report a stale failure until Godot reloads the new `class_name` script (cached old validator message). On-disk validator matches current plugin/dock files.

## 13. Godot MCP Pro validation

| Script | Result |
|--------|--------|
| `MissionPaintDock.gd` | **PASS** (after fixing `set_input_event_forwarding_always_enabled(armed)` — Godot 4.6 takes no args) |
| `MissionPaintDockPlugin.gd` | **PASS** |
| Taco layout layers census | **PASS** — all five LayoutRoot TileMapLayers exist |
| Floor tile `has_tile(0,0)` on Taco | **PASS** |
| Live paint/erase + UndoRedo stroke | **Not automated** — requires armed manual drag in editor |

## 14. Godot LSP diagnostics

**PASS** — no issues on `MissionPaintDock.gd`.

## 15. GdUnit4

**Not run** — no headless GdUnit invocation in this session. Change is editor-plugin-only; mission authoring suite not executed.

## 16. MainMenu smoke

**Not run** — Godot CLI not on PATH in shell session.

## 17. Taco scene / runtime validation

- Scene structure verified via MCP: all required `LayoutRoot` layers present.
- **Manual validation required:** enable plugin, arm tool, paint/erase one cell on scratch area, undo stroke, playtest movement after collision edit.

## 18. `project.godot` change

**Not changed.** Enable manually:

1. Godot → **Project → Project Settings → Plugins**
2. Enable **Mission Paint Dock**
3. Dock appears in right dock slot; use **Refresh Scene Layers** on Taco test scene

Optional: add `res://addons/mission_paint_dock/plugin.cfg` to `editor_plugins/enabled` array (same pattern as PVGames Object Palette).

## 19. Kimi usage

**Not used.** Implementation followed repo docs and Godot 4.6 API behavior (canvas forwarding API fix).

## 20. Safety confirmation

- Repo-only edits
- No secrets/private files accessed
- No git commit/push/branch/history changes
- No `IsoMissionBase`, Phase0J/0K, autoloads, player, or runtime collision generator edits
- Production Taco scene not saved by this agent

## 21. Known limitations

- Canvas forwarding enabled at plugin level; disarmed gating is via `return false` (equivalent for consumption, not identical to disabling forwarding API).
- Godot 4.6 `set_input_event_forwarding_always_enabled()` has no bool parameter — cannot toggle forwarding off programmatically per arm state.
- Brush size >1 supported but default is 1 cell.
- Marker presets: only `OBJ` included; other marker abbreviations can be added after per-tile verification.
- No visual ghost preview for strokes.
- Manual paint/undo/playtest not completed in this session.

## 22. Rollback plan

```bash
# Remove plugin folder and validator
rm -rf addons/mission_paint_dock
git checkout -- src/tools/editor/MissionPaintDockValidator.gd  # if tracked later
```

Disable plugin in Project Settings. Revert any scratch scene edits if created during manual tests.

## 23. Recommended next step

1. **Enable plugin** and run manual checklist on `TacoBellIso_Editable_RedesignTest.tscn` (or scratch duplicate): layout floor/wall paint+erase+undo; collision mode only after both unlocks.
2. If brush basics validated: **Phase 3G manifest–code-gate corridor wayfinding** (scene-local visuals).
3. Expand marker tile presets in dock as needed after designer confirmation.
