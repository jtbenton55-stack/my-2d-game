# Mission Paint Dock Collision Barrier Erase Fix Report

**Date:** 2026-05-21
**Branch:** `new-feature-roadmap-branch`
**Scope:** Fix left-drag erase strokes on `CollisionBarrierLayer` (and all layers using Operation = Erase)

## 1. Goal

Make **Operation = Erase** with left-click/drag reliably erase tiles on `GameplayRoot/LayoutRoot/CollisionBarrierLayer` (and other layout layers), matching floor/wall erase behavior. Preserve right-click erase shortcut and all safety locks.

## 2. Branch and baseline git status

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M project.godot  (plugin enablement — pre-existing, not modified by this repair)
 ?? addons/mission_paint_dock/
 ?? src/tools/editor/MissionPaintDockValidator.gd
```

This repair only touched Mission Paint Dock scripts and this report.

## 3. Files inspected

- `addons/mission_paint_dock/MissionPaintDock.gd` (`_handle_stroke_input`, `_commit_stroke`, `_cancel_stroke`)
- `addons/mission_paint_dock/MissionPaintDockPlugin.gd`
- `src/tools/editor/MissionPaintDockValidator.gd`
- `reports/ai/2026-05-21_mission_paint_dock_v1_report.md`

## 4. Files changed

| File | Change |
|------|--------|
| `addons/mission_paint_dock/MissionPaintDock.gd` | Stroke button tracking, motion mask fix, commit/cancel state cleanup |
| `src/tools/editor/MissionPaintDockValidator.gd` | Static checks for button-mask repair |
| `reports/ai/2026-05-21_mission_paint_dock_collision_erase_fix_report.md` | This report |

## 5. Root cause

In `_handle_stroke_input()`, mouse motion continued a stroke only when:

```gdscript
(_stroke_erase and MOUSE_BUTTON_MASK_RIGHT) or ((not _stroke_erase) and MOUSE_BUTTON_MASK_LEFT)
```

Left-drag strokes with **Operation = Erase** set `_stroke_erase = true` but still used **left** button. Motion required **right** button held, so only the first cell (on press) erased; drag did nothing.

Floor/wall erase may have appeared to work if tested primarily via right-click erase shortcut, or single-click erase on press only.

## 6. Implementation details

- Added `_stroke_mouse_button` to record which button started the stroke.
- `_begin_stroke(erase, mouse_button)` stores `MOUSE_BUTTON_LEFT` or `MOUSE_BUTTON_RIGHT`.
- `_stroke_button_mask_held(motion)` continues stroke only while that button’s mask is held.
- Commit on release only when the releasing button matches `_stroke_mouse_button`.
- Split `_clear_stroke_state(revert_live_changes)`:
  - **Cancel (Esc):** reverts live tile changes.
  - **Commit:** clears stroke state without revert (live edits remain; UndoRedo records the stroke).
- `_update_stroke_status()` shows operation, layer path, cell, and stroke cell count during drag.

## 7. Behavior before vs after

| Action | Before | After |
|--------|--------|-------|
| Operation = Erase, LMB drag | First cell only (motion ignored) | Full drag erases all cells under brush |
| Operation = Paint, LMB drag | Worked | Unchanged |
| RMB erase shortcut drag | Worked | Unchanged |
| LMB release | Committed any active stroke | Commits only LMB-started strokes |
| RMB release | Committed if `_stroke_erase` | Commits only RMB-started strokes |
| Esc | Revert + cancel | Unchanged intent |

## 8. Safety gates preserved

- Visual / Layout Blockout / Collision Barrier modes unchanged.
- Layout and collision unlock checkboxes unchanged.
- Forbidden paths (`GeneratedRuntimeCollision`, gameplay layers) unchanged.
- No `Area2D` / `StaticBody2D` / `CollisionShape2D` creation.
- No TileSet, scene, gameplay script, or autoload edits.

## 9. Validator updates

Added checks for `_stroke_mouse_button`, `_stroke_button_mask_held`, `MOUSE_BUTTON_MASK_LEFT` / `MOUSE_BUTTON_MASK_RIGHT`, and erase operation / right-button shortcut presence.

## 10. Tests / checks run

| Check | Result |
|-------|--------|
| `git diff --check` (dock) | **PASS** |
| Godot MCP `validate_script` — `MissionPaintDock.gd` | **PASS** |
| Godot LSP — `MissionPaintDock.gd` | **PASS** |
| `MissionPaintDockValidator.validate()` in-editor | **PASS** |
| Manual CollisionBarrier LMB erase drag (20-step checklist) | **Not run by agent** — Jake should re-verify |
| GdUnit4 `tests/mission_authoring/` | **Not run** |
| MainMenu smoke | **Not run** |
| Taco runtime playtest | **Not run** |

## 11. Godot MCP Pro validation

**PASS** — dock script compiles; in-editor validator returns no failures.

## 12. Godot LSP diagnostics

**PASS** — no issues on modified dock script.

## 13. Manual editor validation

**Pending Jake confirmation** using the task’s 20-step checklist on `TacoBellIso_Editable_RedesignTest.tscn` (paint 3 collision cells → LMB erase drag → RMB erase → undo). Regression: FloorLayer/WallLayer LMB erase drag.

## 14. GdUnit4

**Not run** — editor-plugin-only change.

## 15. MainMenu smoke

**Not run**.

## 16. Taco runtime validation

**Not run** — no scene saves intended from this repair.

## 17. Kimi usage

**Not used.**

## 18. Safety confirmation

- Repo-only edits; no secrets accessed.
- No git commit/push/history changes.
- `project.godot` not modified by this repair packet.
- No gameplay/mission/collision-generator script changes.

## 19. Known limitations

- Manual erase/playtest not re-run in this session.
- Commit no longer reverts live tiles before UndoRedo apply (intentional fix; should match expected visible result after commit).

## 20. Rollback plan

```bash
git checkout -- addons/mission_paint_dock/MissionPaintDock.gd
git checkout -- src/tools/editor/MissionPaintDockValidator.gd
```

Reload Godot editor or disable/re-enable Mission Paint Dock plugin.

## 21. Recommended next step

1. Jake: re-run CollisionBarrier **Operation = Erase** left-drag test (steps 10–12 in task).
2. If pass: use Mission Paint Dock for Taco blockout work; then Phase 3G corridor wayfinding when ready.
