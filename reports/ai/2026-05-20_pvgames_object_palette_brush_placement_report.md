# PVGames Object Palette Brush Placement Report

**Date:** 2026-05-20
**Branch:** `new-feature-roadmap-branch`
**Scope:** Phase 3 editor-tooling — PVGames Object Palette v2 brush/repeat placement

## 1. Goal

Add an opt-in **Brush Mode** to the PVGames Object Palette so artists can left-drag in the 2D editor viewport to stamp repeated visual PVGames object/icon nodes at a configurable spacing, with one UndoRedo action per stroke, while preserving typed stamping and all existing safety boundaries.

## 2. Branch and baseline git status

**Before edits:**

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
(clean working tree)
```

**After edits:**

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd
 M src/tools/editor/PVGamesObjectPaletteDockValidator.gd
```

No unrelated dirty files. `project.godot` unchanged.

## 3. Files inspected

- `AGENTS.md`
- `docs/Prompt_Improvement.md` (referenced in task)
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` (brush slice scope)
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/TACO_PAINT_READINESS_CHECKLIST.md`
- `docs/TACO_VISUAL_LAYER_TAXONOMY.md`
- `reports/ai/2026-05-20_pvgames_object_palette_artroot_mouse_placement_report.md`
- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- `addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd`
- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.tscn`
- `src/tools/editor/PVGamesObjectPaletteDockValidator.gd`
- `scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`
- `src/hideout/HideoutDecoratingModeController.gd` (canvas transform pattern)

## 4. Files changed

| File | Change |
|------|--------|
| `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` | Brush UI, stroke state, canvas input routing, coordinate helper, batch stamp + UndoRedo |
| `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` | Static checks for brush mode, helpers, and canvas conversion |

**Not changed:** `PVGamesObjectPalettePlugin.gd`, `project.godot`, production Taco scenes, gameplay/mission scripts.

## 5. Existing systems reused

- `_create_node`, `_unique_child_name`, `_set_owner_recursive`, `_select_created_object`
- `_ensure_container`, `_ensure_art_stamp_root`, `_art_object_root`, `_node_is_under_gameplayroot`
- `_stamp_selected_in_container` / `_stamp_selected_at_position` (typed path unchanged)
- Plugin `_forward_canvas_gui_input` → `handle_canvas_gui_input` (no plugin edits required)

## 6. Implementation path and rationale

**Coordinate conversion:** One-shot `Place With Mouse` used `container.make_input_local(mouse_event)`, which does not reliably map editor canvas events. Brush and mouse placement now share:

1. `get_editor_viewport_2d().get_canvas_transform().affine_inverse() * event.position` → scene canvas/world position
2. `container.to_local(...)` → target container local space

This matches the working pattern in `HideoutDecoratingModeController.gd` and avoids a broad mouse-placement rewrite.

**Brush stroke lifecycle:** Points are collected in memory during drag; nodes are created only on **left mouse release** (`_commit_brush_stroke`). Cancel (RMB / Esc) drops pending points without adding nodes — no orphan cleanup or partial undo.

**Input consumption:** Canvas forwarding returns `true` only when a brush stroke is active or when brush mode handles LMB down / motion / release. With brush mode off, the dock returns `false` so normal editor viewport tools are not blocked.

**Selection after stroke:** If “Select new object after stamping” is enabled, only the **last** node in the stroke is selected (avoids noisy multi-selection).

## 7. UI and behavior added

**UI (Placement section):**

- **Brush Mode** checkbox (opt-in)
- **Brush Spacing** spin box (8–4096, default **96** px, local/world units after conversion)
- Help text: select asset → enable brush → left-drag → release to commit; RMB/Esc cancels

**Existing buttons preserved:** Ensure Art Stamp Root, Dry Run Stamp, Stamp Selected at Typed Position, Stamp Selected at Scene Origin, Place With Mouse, Copy Object ID, Refresh Index.

**Brush behavior:**

1. Brush mode off → no canvas input consumption.
2. Brush on + valid selection → LMB down starts stroke; motion with LMB held appends points when distance ≥ spacing.
3. LMB release commits all points in one UndoRedo action (`Brush Stamp PVGames Palette Entries`).
4. RMB or Esc cancels pending stroke without stamping.
5. Disabling Brush Mode while stroking cancels the stroke.
6. Single-point stroke (click without much motion) still commits one stamp.
7. Spacing prevents duplicate stamps at the same coordinate during slow movement.

## 8. Safety boundaries preserved

- Stamps only into resolved art containers under `ArtRoot` / `ArtRoot/World` → `PVG_EditableObjects/...`
- `_node_is_under_gameplayroot` guard unchanged; unsafe targets abort with status message
- Visual `PVGEditableObject` nodes only — no collision, gameplay, Area2D, StaticBody2D, mission mechanics, or tile data
- No edits to `GameplayRoot`, `IsoMissionBase`, Phase0J/0K, autoloads, or production Taco gameplay logic
- `project.godot` not modified

## 9. Kimi usage

**Used (advisory):** `ask_kimi_k2_6` — `godot_playtest_plan` on editor input forwarding, UndoRedo multi-node strokes, and coordinate conversion.

**Key advisory points (verified locally):**

- Only consume input when brush mode is on or a stroke is active; avoid blocking pan/zoom/select.
- Prefer deferring node creation until commit (implemented).
- Undo child order: undo `remove_child` in reverse order (implemented).
- Fast drags may skip intermediate spacing samples — acceptable for v1; interpolate later if needed.

## 10. Validation performed

| Check | Result |
|-------|--------|
| `git diff --check` | PASS (CRLF→LF warnings only) |
| `PVGamesObjectPaletteDockValidator.validate()` via Godot MCP `execute_editor_script` | **PASS** (`failures: []`) |
| Godot MCP `validate_script` — dock | **PASS** |
| Godot MCP `validate_script` — validator | FAIL in isolation (`class_name` hides global script — pre-existing EditorScript quirk; in-editor `validate()` PASS) |
| Godot LSP `get_diagnostics` — dock | **PASS** (no issues) |
| `project.godot` diff | **unchanged** |
| Programmatic `_stamp_brush_points_in_container` on `PVGamesObjectPaletteDockTest.tscn` | **PASS** (+3 visual nodes under `ArtRoot/World/PVG_EditableObjects/OccludableObjects`, no GameplayRoot hits) |
| Editor output log | Shows `Stamp PVGames Palette Entry` / `Remove Node(s)` during manual editor session (typed undo exercised) |

### Godot MCP / editor validation limits

- **Full viewport drag + UndoRedo for brush stroke** was not fully automated via MCP (requires real LMB drag in 2D canvas). Programmatic stamp path and static validator confirm wiring; **manual confirmation in editor is still recommended** using `PVGamesObjectPaletteDockTest.tscn`.
- **Typed stamp** path code unchanged; manual confirmation previously reported working — re-verify after pull if desired.

## 11. What passed

- Static validator (in-editor)
- Dock script compile + LSP clean
- Brush batch stamp creates multiple visual-only nodes under safe art container
- GameplayRoot safety helper reports no hits on stamped children
- Git scope limited to palette dock + validator
- `project.godot` and plugin script untouched

## 12. What failed and fixes

| Issue | Fix |
|-------|-----|
| `make_input_local` unreliable for editor canvas events | Shared `_canvas_position_from_mouse_event` + `_event_position_in_container` |
| Batch unique names when creating multiple nodes before `add_child` | `_unique_child_name_for_batch` with reserved-name list |
| MCP `validate_script` on EditorScript validator | Known `class_name` conflict outside editor; use in-editor `validate()` |

## 13. Known limitations

- **Place With Mouse (one-shot):** Updated to use the same coordinate helper as brush; may work now but was **not** acceptance-tested in this packet. Prior manual reports noted it broken — treat as non-blocking unless regression is observed.
- **Fast brush drags:** No interpolation between motion samples; very fast movement may leave gaps larger than spacing (Kimi noted; acceptable for thin slice).
- **Brush spacing** is in **container local / world units**, not screen pixels — zoom changes visual density on screen.
- **RMB during brush mode** cancels an active stroke only; does not arm a global “cancel mode” when idle.
- **MCP automated drag/undo** for brush stroke not completed; manual editor test checklist below.

## 14. Rollback plan

```bash
git checkout -- addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd
git checkout -- src/tools/editor/PVGamesObjectPaletteDockValidator.gd
```

Reload Godot editor or disable/re-enable the PVGames Object Palette plugin. Remove any test stamps from scratch scenes if undesired.

## 15. Recommended next step

1. **Manual editor pass** on `scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`: typed stamp → undo; brush drag → single undo removes whole stroke; RMB/Esc cancel; brush off → normal select/pan works.
2. If one-shot Place With Mouse still fails after coordinate fix, log repro (zoom level, container path) in a follow-up thin slice — do not block brush acceptance.
3. Next roadmap slice per Phase 3 docs: **manifest–code-gate corridor wayfinding** (scene-local visuals) or Mission Paint Dock when prioritized.

## Manual test checklist (editor)

- [ ] Open `PVGamesObjectPaletteDockTest.tscn`
- [ ] Select entry → **Stamp Selected at Typed Position** → node under `ArtRoot/World/PVG_EditableObjects/...`
- [ ] Undo removes typed stamp
- [ ] Enable **Brush Mode**, drag LMB → multiple stamps at ~96px spacing
- [ ] Undo once removes entire stroke
- [ ] Mid-stroke RMB or Esc → no new nodes on release
- [ ] Brush Mode off → viewport select/pan normal
- [ ] Optional: **Place With Mouse** single click (document result)
