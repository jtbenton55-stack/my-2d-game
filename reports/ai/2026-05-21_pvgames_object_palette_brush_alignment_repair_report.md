# PVGames Object Palette Brush Alignment and Auto-Spacing Repair Report

**Date:** 2026-05-21
**Branch:** `new-feature-roadmap-branch`
**Scope:** Focused repair pass for PVGames Object Palette v2 brush placement (coordinates, axis lock, asset spacing)

## 1. Goal

Fix three user-observed brush issues:

1. Stamps appearing ~1–2 inches above the editor cursor (coordinate misalignment).
2. Vertical drift when painting repeatable floor/wall/road strips (freehand sampling).
3. Fixed 96px spacing causing gaps/overlap instead of edge-to-edge repetition for scaled assets.

Preserve typed stamping, single UndoRedo per brush stroke, and all safety boundaries.

## 2. Branch and baseline git status

**Before this packet (repo already had unrelated edits):**

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd
 M docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md
 M scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn
 M scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn
 M src/tools/editor/PVGamesObjectPaletteDockValidator.gd
?? reports/ai/...
```

**Changed by this packet only:**

- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- `src/tools/editor/PVGamesObjectPaletteDockValidator.gd`
- `reports/ai/2026-05-21_pvgames_object_palette_brush_alignment_repair_report.md`

`project.godot` not modified. No gameplay/mission script changes.

## 3. Files inspected

- `reports/ai/2026-05-20_pvgames_object_palette_brush_placement_report.md`
- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- `addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd`
- `src/tools/editor/PVGamesObjectPaletteDockValidator.gd`
- `scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`
- `src/hideout/PVGEditableObject.gd`
- Godot `scene_paint_2d_editor_plugin.cpp` coordinate pattern (via reference)

## 4. Files changed

| File | Change |
|------|--------|
| `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` | Coordinate fix, brush alignment UI, auto asset spacing, deterministic axis-locked point rebuild |
| `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` | Static checks for new brush alignment/spacing helpers |

## 5. Root cause analysis

### Cursor offset (stamps above click)

Previous helper used `get_canvas_transform().affine_inverse() * event.position` then `container.to_local()`.

Issues:

- `event.position` in forwarded editor input may not match the 2D editor viewport’s local mouse position (toolbar/subviewport offsets).
- `to_local()` on a nested container without matching global transform chain can drift when canvas/world space is wrong.

Godot’s own 2D paint editor uses **`viewport.get_local_mouse_position()`** (GDScript: `SubViewport.get_mouse_position()`) with **`canvas_transform.affine_inverse()`**, then **`node.get_global_transform().affine_inverse()`** for parent-local placement.

### Vertical drift between tiles

Brush collected raw motion samples at a fixed distance threshold. Slight vertical mouse movement during horizontal drags produced different Y per stamp.

### Gaps / overlap on repeatable assets

Fixed **96px** spacing ignored per-asset texture size and scale. Centered `Sprite2D` nodes need spacing equal to **scaled width** (horizontal strips) or **scaled height** (vertical strips) for edge-to-edge placement.

## 6. Implementation details

### Coordinate conversion (fix #1)

```gdscript
func _canvas_position_from_mouse_event(_event: InputEventMouse) -> Vector2:
    var viewport := _editor_viewport_2d()
    var viewport_mouse := viewport.get_mouse_position()
    return viewport.get_canvas_transform().affine_inverse() * viewport_mouse

func _event_position_in_container(event: InputEventMouse, container: Node2D) -> Vector2:
    var canvas_pos := _canvas_position_from_mouse_event(event)
    return container.get_global_transform().affine_inverse() * canvas_pos
```

Shared by brush and one-shot Place With Mouse. Typed stamping unchanged (no mouse path).

### Brush alignment (fix #2)

New **Brush Alignment** option: `Auto Axis` (default), `Horizontal`, `Vertical`, `Freeform`.

- **Auto Axis:** after 12px motion from anchor, lock to dominant axis (|dx| vs |dy|).
- **Horizontal / Vertical:** lock axis at stroke start.
- **Freeform:** legacy distance-based sampling (for non-strip use).

Axis-locked modes project motion onto one axis (`_project_point_to_brush_axis`).

### Auto asset spacing (fix #3)

New **Auto Asset Spacing** checkbox (default **on**).

- `_selected_asset_scaled_size()` → `texture.get_size() * abs(scale)`
- Horizontal spacing → scaled width
- Vertical spacing → scaled height
- Freeform → max(width, height) when auto on; else manual **Brush Spacing** spin

### Deterministic stamp points (fix #4)

`_rebuild_axis_locked_brush_points()` replaces raw motion samples for axis modes:

- Project cursor to locked axis.
- `step_count = floor(|signed_distance| / spacing)`
- Stamps at `anchor + direction * spacing * n` for `n = 0..step_count`
- Supports negative direction when dragging left/up from anchor
- Rebuilds full point list each motion frame (no gap skipping on fast drags)

### UndoRedo / typed stamp

- Whole stroke still one action: `Brush Stamp PVGames Palette Entries`
- `_stamp_selected_at_position` / typed buttons untouched
- Selection after brush: last stamp only (unchanged)

## 7. Exact UI changes

Under **Brush Placement**:

| Control | Default |
|---------|---------|
| Brush Mode | off |
| Brush Spacing | 96 (manual fallback) |
| Brush Alignment | Auto Axis |
| Auto Asset Spacing | on |

Help text updated to describe axis lock and edge-to-edge spacing.

## 8. Kimi usage

**Advisory** `ask_kimi_k2_6` (debugging): confirmed risk of wrong viewport vs canvas transform and recommended verifying `get_mouse_position()` vs `event.position`. Local fix aligned with Godot paint editor source pattern.

## 9. Validation results

| Check | Result |
|-------|--------|
| `git diff --check` | PASS (CRLF warnings only) |
| `PVGamesObjectPaletteDockValidator.validate()` (in-editor) | **PASS** |
| Godot MCP `validate_script` — dock | **PASS** |
| Godot LSP — dock | **PASS** (no diagnostics) |
| `project.godot` | Not changed |
| Full viewport drag alignment | **Manual editor pass recommended** (MCP cannot reliably simulate LMB drag alignment) |

## 10. What passed

- Script compile and static validator
- New helpers present (`_rebuild_axis_locked_brush_points`, `_effective_brush_spacing`, `_selected_asset_scaled_size`, alignment UI)
- Typed stamp code path not modified
- Safety helpers (`_node_is_under_gameplayroot`, visual-only `_create_node`) unchanged

## 11. What failed / limitations

| Item | Notes |
|------|--------|
| MCP programmatic axis-spacing test | Editor script snippet failed to compile in one MCP run after plugin reload; validator + `validate_script` passed after reload |
| Live cursor alignment | Requires Jake to confirm on `PVGamesObjectPaletteDockTest.tscn` with a rectangular repeatable asset |
| Place With Mouse | Uses same coordinate helper; may work now but not acceptance-tested |
| Iso/isometric scenes | Axis lock is screen-axis in container local space; extreme parent rotation may need Freeform |

## 12. Manual test checklist (editor)

1. Open `scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`
2. Select a rectangular floor/wall-like object
3. **Stamp Selected at Typed Position** → works; undo works
4. Brush Mode on, **Auto Axis**, **Auto Asset Spacing** on
5. Drag horizontally → stamps on cursor line, same Y, edge-to-edge
6. Undo once → whole stroke removed
7. **Vertical** alignment + vertical drag → same X, edge-to-edge vertically
8. **Freeform** → non-axis behavior returns
9. Brush off → normal viewport pan/select

## 13. Rollback plan

```bash
git checkout -- addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd
git checkout -- src/tools/editor/PVGamesObjectPaletteDockValidator.gd
```

Reload PVGames Object Palette plugin in Godot.

## 14. Recommended next step

1. Jake manual confirm on scratch test scene (horizontal strip + undo).
2. If cursor offset persists at certain zoom levels, capture zoom % and scene root path for a follow-up (possible `CanvasItemEditor` transform access).
3. Next roadmap slice remains **manifest–code-gate corridor wayfinding** or Mission Paint Dock when prioritized — not in this packet.
