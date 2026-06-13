# Phase 3G PVGames Object Palette — Mouse Fix, Dock Usability, Box Erase

**Date:** 2026-05-22
**Status:** Manual QA passed on 2026-06-13; ready for Phase 3G sign-off
**Scope:** Editor tool only — no mission authoring, Taco/production scenes, or `project.godot` changes

## Summary

This pass fixes the `Place With Mouse` regression caused by an invalid `EditorSelection.emit_changed()` call, improves dock usability with collapsible sections and a taller Results list, and adds safe multi-stamp box erase for palette-created nodes. Follow-up fixes through 2026-06-13 resolved repeatable placement, sortable route desync, BackgroundArt click capture, blank-dock parse/init regressions, and `Ctrl+Z` undo/re-arm behavior; Jake confirmed final manual QA passed on 2026-06-13.

> **Follow-up 2026-06-13** — Jake re-QA'd this build. See the [2026-06-13 follow-up section](#2026-06-13-follow-up--repeatable-mouse-placement--click-capture--sortable-route-desync) at the end for the next round of fixes (repeatable placement, click capture over `BackgroundArt`, and sortable route desync).

## 1. Place With Mouse fix (`emit_changed()`)

### Root cause
`PVGamesObjectPalettePlugin.gd` called `selection.emit_changed()` inside `notify_input_forwarding_changed()`. Godot 4.6.2 `EditorSelection` does not expose `emit_changed()`, so arming mouse placement threw an error and blocked viewport input forwarding.

### Fix
Removed the invalid API call. Input forwarding refresh now uses only:
- `update_overlays()`
- `call_deferred("update_overlays")`

Canvas forwarding remains driven by `_handles()` + `should_forward_canvas_gui_input()` on the dock (mouse pending, brush stroke, shape drag, box erase armed/drag, brush mode ON).

## 2. Collapsible dock sections

Added `_collapsible_section(title, default_open)` helper. Wrapped major UI blocks:

| Section | Default |
|---|---|
| Help / Status | Collapsed |
| Search / Filters | Open |
| Results | Open |
| Selected Asset | Collapsed |
| Placement Route | Open |
| Placement | Open |
| Brush Placement | Collapsed |
| Placement Shape | Collapsed |
| Variation | Collapsed |
| Erase Palette Stamps | Open |
| Actions | Open |

Long help text moved into collapsible bodies under Help / Status, Placement Route, Brush Placement, Placement Shape, and Erase Palette Stamps.

## 3. Taller Results list

Results `ItemList` minimum size changed from `Vector2(360, 150)` to `Vector2(360, 320)` with `SIZE_EXPAND_FILL` vertical flag for easier scrolling. Result count label preserved.

## 4. Safe box-erase mode

New controls under **Erase Palette Stamps**:
- **Box Erase Palette Stamps**
- **Cancel Box Erase**

Behavior:
- Arm box erase → drag rectangle in 2D viewport → release LMB
- Deletes only nodes where `created_by == "PVGamesObjectPaletteDock"` and node is not under `GameplayRoot`
- Uses `global_position` inside normalized drag rect
- Single UndoRedo action: `Box Erase PVGames Palette Stamps`
- Esc / RMB cancel without mutation
- Mutually exclusive with mouse placement, brush stroke, and shape drag (other modes cancel box erase on start)

## Files touched

- `addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd`
- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- `src/tools/editor/PVGamesObjectPaletteDockValidator.gd`
- `reports/ai/2026-05-22_phase3g_pvgames_palette_mouse_usability_box_erase_report.md`

## Static validation

| Check | Result |
|---|---|
| `git diff --check` | PASS (no conflict markers / trailing whitespace issues) |
| Godot LSP on dock + plugin + validator | PASS (no diagnostics reported) |
| `PVGamesObjectPaletteDockValidator` | Run in editor after reload — see below |

## Manual QA checklist (Jake)

**Scene:** `res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`

### Dock / UI
- [ ] Dock loads and is not blank
- [ ] Collapsible sections toggle open/closed
- [ ] Long help text collapses under Help / Status and route/brush/shape/erase sections
- [ ] Results list is taller and scrolls comfortably

### Place With Mouse
- [ ] Select asset, Fixed Occludable Art route, Brush Mode OFF
- [ ] Place With Mouse → LMB viewport → stamp under `ArtRoot/World/PVG_EditableObjects/OccludableObjects`
- [ ] Repeat Place With Mouse → second stamp appears
- [ ] Place With Mouse → Esc → no mutation; re-arm works
- [ ] Place With Mouse → RMB → no mutation; re-arm works

### Dry run
- [ ] Dry Run Stamp → no scene tree changes

### Box erase
- [ ] Create several palette stamps (rectangle fill/scatter or repeated mouse placement)
- [ ] Box Erase Palette Stamps → drag around some stamps → only palette stamps deleted
- [ ] Undo restores all deleted stamps
- [ ] Box around non-palette nodes → nothing deleted
- [ ] Esc / RMB cancel → no scene changes

### Sortable regression
**Scene:** `res://scenes/dev/phase3j_sortable_2d_pilot/Phase3JSortable2DPilot.tscn`
- [ ] Sortable 2.5D Prop route, Use Z Override OFF, Place With Mouse → no ArtRoot error
- [ ] LMB → object under `VisualRoot/SortableWorld`, `z_index = 0`

## Remaining risks

1. **Box erase coordinate alignment** — uses canvas-space drag rect vs stamp `global_position`; verify on zoomed/panned 2D viewport in scratch scene.
2. **Collapsible section UX** — simple ▼/▶ header buttons; no persisted open/closed state across editor restarts.
3. **Large stamp counts in box** — batch undo restores nodes but may be slow with hundreds of stamps in one rectangle.
4. **Manual QA not rerun in this session** — static checks only; Jake must confirm full checklist before Phase 3G sign-off.

## Rollback

Revert the three code files listed above. No scene or `project.godot` changes required for rollback.

---

## 2026-06-13 Follow-up — repeatable mouse placement, click capture, sortable route desync

**Status:** Manual QA pending (Jake rerun required)

### Jake's re-QA findings on the prior build
- Collapsible dock UI: **PASS**
- Box erase: **PASS**
- `Stamp Selected at Scene Origin`: **PASS**
- `Place With Mouse`: **only works once** — re-arming after one placement was unreliable; Esc did not restore reliable re-arming.
- In `Phase3JSortable2DPilot.tscn`, clicking on/inside the large `BackgroundArt` area **selected `BackgroundArt`** instead of placing the stamp; placement only worked outside that art.
- Sortable scene still sometimes reported `Error: ArtRoot not found`, indicating the active route was desyncing back to a fixed route.

### Root cause (Issues 1 & 2 share one cause)
When an armed left-click placed a stamp, the dock handled the **press** (placed + disarmed) but let the paired **button release** fall through to the editor. The canvas editor then ran its own click-selection on that release and selected the underlying art (e.g. `BackgroundArt`, a `Polygon2D`). That had two effects:
1. The wrong node got selected instead of the placement being clean.
2. Selecting polygon-type art could flip the 2D editor into polygon-edit interaction, which then intercepted subsequent clicks — so `Place With Mouse` appeared to "only work once" and re-arm/Esc felt unreliable.

### Issue 3 root cause
`_select_entry()` unconditionally called `_set_placement_route_from_container_name(entry.recommended_container)` every time an asset was selected, silently resetting an explicitly-chosen `Sortable 2.5D Prop` route back to a fixed route. The fixed route then required `ArtRoot`, producing `Error: ArtRoot not found` in the sortable scene.

### Fixes (minimal, reversible)
**`PVGamesObjectPaletteDock.gd`**
- Added `_consume_next_left_release` state. On an armed left-click placement, the dock now sets this flag; `handle_canvas_gui_input()` consumes the matching left-button **release** (returns `true`) so the editor's selection tool never sees it. This stops `BackgroundArt` from being selected and stops the polygon-edit mode flip, which restores repeatable placement and reliable re-arm/Esc.
- Rewrote `_handle_place_with_mouse_canvas_input()` to consume the full click cycle while armed (LMB press places + disarms + arms release-suppression; RMB press/release and motion are consumed; Esc cancels). It no longer leaks the release.
- Added `_user_chose_route` flag. Once the user picks any route from the dropdown (`_on_placement_route_changed`), `_select_entry()` preserves it across asset selections instead of resetting to the recommended fixed route. Target Container is only re-synced for non-sortable routes.

**`PVGamesObjectPalettePlugin.gd`**
- `_handles()` now also returns `true` for an empty (`null`) selection, so canvas input forwarding stays armed for repeated placement even when no scene node is selected. (`set_input_event_forwarding_always_enabled()` and `update_overlays()` retained; no invalid `EditorSelection` APIs.)

**`PVGamesObjectPaletteDockValidator.gd`**
- Added static assertions for `_consume_next_left_release` and `_user_chose_route`.

### Sortable route guarantees (unchanged, re-verified in code)
- `sortable_2d_prop` resolves `VisualRoot/SortableWorld` first, then `EntityRoot`, only when `y_sort_enabled = true`, and never touches `ArtRoot` (`_resolve_sortable_parent` / `_preview_stamp_target` / `_resolve_stamp_target`).
- Sortable stamps are direct children of the resolved Y-sort parent.
- `Use Z Override` OFF → `z_index = 0`; ON → exact override.
- Icons on the sortable route are refused with a clear message (`_route_allows_entry`).

### Validation (this session)
| Check | Result |
|---|---|
| `git diff --check` | PASS (only pre-existing CRLF→LF warnings) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPaletteDock.gd` | PASS (no diagnostics) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPalettePlugin.gd` | PASS (no diagnostics) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPaletteDockValidator.gd` | PASS (no diagnostics) |
| In-editor `PVGamesObjectPaletteDockValidator.validate()` | **Not run** — Godot editor/MCP Pro not connected this session |
| Runtime manual QA | **Not run** — requires Jake in editor |

### Manual QA still required (Jake)
Run the full scratch + sortable checklists from the task. Key new assertions:
- Place With Mouse works repeatedly (3+ times), and after Esc/RMB/Undo.
- Clicking directly on `BackgroundArt` in `Phase3JSortable2DPilot.tscn` **places the stamp** and does not select `BackgroundArt`.
- Sortable route stays `Sortable 2.5D Prop` after selecting an asset; no `ArtRoot not found`; stamps land under `VisualRoot/SortableWorld` with correct `z_index`.

### Remaining risks
1. **Editor input-forwarding precedence** — the release-consume approach prevents the editor selecting underlying art during armed placement. If a future Godot build changes when polygon-edit sub-tools claim input, this may need revisiting. Documented as the safest non-mutating workaround (no helper nodes, no forced tool switch).
2. **`_user_chose_route` is sticky** — once the user picks a route it persists across asset selections until they pick another route (intentional, per task's recommended behavior). Switching to a brand-new scene keeps the last chosen route.
3. **In-editor validator + runtime QA not executed this session** — Godot editor was not running; only LSP static diagnostics ran. Phase 3G remains manual-QA pending.

---

## 2026-06-13 Follow-up #2 — Place With Mouse stops working after Ctrl+Z Undo

**Status:** Manual QA pending (Jake rerun required)

### Jake's re-QA findings on the prior build
PASS: dock loads, collapsible UI, box erase, rectangle outline, repeated Place With Mouse before Undo, Esc re-arm, RMB re-arm, sortable scene, clicking `BackgroundArt` places the stamp instead of selecting it.

FAIL: after placing with the mouse and pressing `Ctrl+Z` to undo, clicking `Place With Mouse` again and left-clicking the viewport placed nothing.

### Root cause
Per the Godot 4 docs, `_forward_canvas_gui_input()` is only delivered to the plugin when `_handles()` returns `true` for the **currently edited object**. Repeated placement worked because each stamp selected the new `Node2D` (a `CanvasItem`), so `_handles(stamp) → true` kept the plugin in the editor's active-handler list. After `Ctrl+Z`, the undo removes the stamped node and leaves the editor's edited object stale, freed, or empty. The previous `_handles()` implementation (`return object == null or object is CanvasItem`) dropped the plugin from the active-handler list in that stale state, so the next viewport click was never forwarded — even though the dock was armed (`_place_with_mouse_pending = true`).

### Fix (minimal, reversible)
**`PVGamesObjectPalettePlugin.gd`** — `_handles()` now returns `true` whenever the palette dock is present and exposes both `should_forward_canvas_gui_input()` and `handle_canvas_gui_input()`. This makes canvas input forwarding independent of editor selection/undo state. The dock's `handle_canvas_gui_input()` already returns `false` when no palette mode is armed, so normal editor selection/editing is preserved when not placing, and the existing click-release consumption (BackgroundArt fix) is untouched. No new editor APIs, no helper nodes, no scene mutation while arming.

**`PVGamesObjectPaletteDockValidator.gd`** — added an assertion that the plugin keeps `_handles` armed via dock presence (`has_method("handle_canvas_gui_input")`) so forwarding survives Undo/selection changes.

### Why this is safe
The plugin does not implement `_edit()`, `_make_visible()`, or a main-screen control, so returning `true` from `_handles()` for any object has no object-editing side effects (the docs' "one type at a time" warning applies to plugins that edit objects via `_edit()`). `set_input_event_forwarding_always_enabled()` is retained to also cover the empty-selection case.

### Validation (this session)
| Check | Result |
|---|---|
| `git diff --check` | PASS (only pre-existing CRLF→LF warnings) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPaletteDock.gd` | PASS (no diagnostics) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPalettePlugin.gd` | PASS (no diagnostics) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPaletteDockValidator.gd` | PASS (no diagnostics) |
| In-editor `PVGamesObjectPaletteDockValidator.validate()` | **Not run** — Godot editor/MCP Pro not connected this session |
| Runtime manual QA | **Not run** — requires Jake in editor |

### Nowledge Mem handoff
**Attempted: unavailable this session.** No Nowledge Mem MCP server is mounted in the current Cursor session (available servers: godot-dap-debugger, siliconflow-kimi-k2-6, godot-mcp-pro, godot-lsp-diagnostics, context7, vercel). Handoff recorded here in the AI report instead, per `AGENTS.md`. When a Nowledge Mem channel is available, log: Phase 3G PVGames Object Palette v2 — Undo/re-arm fix via selection-independent `_handles`; branch `new-feature-roadmap-branch`; files `PVGamesObjectPalettePlugin.gd`, `PVGamesObjectPaletteDockValidator.gd`; static checks pass; manual QA pending.

### Manual QA still required (Jake)
Scratch scene `res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`: place → `Ctrl+Z` → re-arm → place, repeated 3× (each cycle should place). Plus regressions: repeated placement without undo, Esc/RMB re-arm, Dry Run non-mutating, box erase + undo restore, rectangle outline/fill/scatter, non-palette erase refusal. Sortable scene `res://scenes/dev/phase3j_sortable_2d_pilot/Phase3JSortable2DPilot.tscn`: place on `BackgroundArt` → `Ctrl+Z` → re-arm → place again as direct child of `VisualRoot/SortableWorld`.

### Remaining risks
1. **Always-on `_handles`** — the plugin now reports it handles canvas input whenever the dock is loaded. This is the standard pattern for placement-tool plugins and is gated on the dock returning `false` when idle, but it means `_forward_canvas_gui_input` is consulted for every 2D viewport event while the dock exists (negligible overhead; returns `false` fast when idle).
2. **In-editor validator + runtime QA not executed this session** — Godot editor not running; only LSP static diagnostics ran. Phase 3G remains manual-QA pending until Jake confirms the full checklist.

---

## 2026-06-13 Follow-up #3 — Place With Mouse still failed after Ctrl+Z Undo (selection-cleanup fix)

**Status:** Manual QA pending (Jake rerun required)

### Jake's re-QA finding
The Follow-up #2 `_handles()` change (always-on while dock present) did **not** fix the Undo path. Repeating: place with mouse → `Ctrl+Z` (object disappears) → click `Place With Mouse` → left-click viewport → **nothing places**. All other QA still PASS (repeated placement before undo, Esc/RMB re-arm, sortable scene, BackgroundArt placement, box erase, rectangle outline, `Stamp Selected at Scene Origin`).

### Root cause (the real one)
After a successful stamp, `_select_created_object(node)` selects the new stamp. The single-stamp UndoRedo action only did `add_undo_method(container, "remove_child", node)`. On `Ctrl+Z`, the node is removed from the tree **but the editor selection still points at that now-orphaned node**. With the editor's edited object out-of-tree, the 2D canvas editor does not forward viewport input to the plugin — so even though `_handles()` returns `true` and the dock re-arms (`_place_with_mouse_pending = true`), the next click is never delivered to `handle_canvas_gui_input()`. The Follow-up #2 change could not help because the problem was the stale/orphaned *edited object*, not whether `_handles` returned true.

### Fix (minimal, reversible) — `PVGamesObjectPaletteDock.gd`
- Added `_undo_remove_palette_stamp(parent, node, safe_selection)`. As the undo handler it: clears stale placement state (`_consume_next_left_release = false`, `_place_with_mouse_pending = false`), clears the editor selection (dropping the orphaned-node reference), removes the stamp from its parent, then re-selects a stable in-tree `CanvasItem` (the target container) so the editor's edited object is valid and canvas forwarding stays healthy. Finally it notifies input forwarding (immediate + deferred). This is selection-only cleanup; it mutates no scene content beyond the stamp removal the undo already performs, creates no helper nodes, and uses no invalid editor APIs.
- `_stamp_selected_in_container()` single-stamp undo now calls `add_undo_method(self, "_undo_remove_palette_stamp", container, node, container)` instead of the plain `remove_child`. This covers both mouse placement (`_stamp_selected_from_mouse_event`) and typed-position stamping (`_stamp_selected_at_position`), which share this helper.
- `_begin_place_with_mouse()` now resets `_consume_next_left_release = false` before arming, so a release event missed around an Undo/editor focus change can never wrongly swallow the next placement click.

### `PVGamesObjectPaletteDockValidator.gd`
- Added an assertion that the single-stamp undo routes through `_undo_remove_palette_stamp(container, node, container)`.

### Batch undo (brush / rectangle / scatter)
Left unchanged this pass (Jake reports rectangle/box-erase undo work). Those batch actions could in principle leave a stale selection too, but they are not the reported blocker and changing them now risks regressing passing QA. Flagged as a watch-item below rather than modified, to keep this pass minimal.

### Validation (this session)
| Check | Result |
|---|---|
| `git diff --check` | PASS (only pre-existing CRLF→LF warnings) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPaletteDock.gd` | PASS (no diagnostics) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPalettePlugin.gd` | PASS (no diagnostics) |
| Godot LSP `get_diagnostics` — `PVGamesObjectPaletteDockValidator.gd` | PASS (no diagnostics) |
| In-editor `PVGamesObjectPaletteDockValidator.validate()` | **Not run** — Godot editor/MCP Pro not connected this session |
| Runtime manual QA | **Not run** — requires Jake in editor |

### Nowledge Mem handoff
**Attempted: unavailable this session.** No Nowledge Mem MCP server is mounted (available servers: godot-dap-debugger, siliconflow-kimi-k2-6, godot-mcp-pro, godot-lsp-diagnostics, context7, vercel). Recorded here per `AGENTS.md`. When available, log: Phase 3G PVGames Object Palette v2 — Undo/re-arm fix via `_undo_remove_palette_stamp` (clears orphaned editor selection + stale placement state, re-selects container); branch `new-feature-roadmap-branch`; files `PVGamesObjectPaletteDock.gd`, `PVGamesObjectPaletteDockValidator.gd`; static checks pass; manual QA pending.

### Manual QA still required (Jake)
Scratch scene: place → `Ctrl+Z` → re-arm → place, 3× cycles (each should place). Regressions: repeated placement without undo, Esc/RMB re-arm, Dry Run non-mutating, box erase + undo restore, rectangle outline/fill/scatter, non-palette erase refusal. Sortable scene: place on `BackgroundArt` → `Ctrl+Z` → re-arm → place again as direct child of `VisualRoot/SortableWorld`.

### Remaining risks
1. **Re-selecting the container on undo** — after `Ctrl+Z` the target container (e.g. `OccludableObjects`) becomes the selected node. This is an intentional, non-mutating side effect that keeps forwarding healthy; if Jake finds it distracting it can be revisited (e.g. select the scene root instead).
2. **Batch undo selection state** — brush/rectangle/scatter undo was not modified; if a future report shows the same Undo/re-arm stall after batch placement, apply the same selection-cleanup pattern to those actions.
3. **In-editor validator + runtime QA not executed this session** — Godot editor not running; only LSP static diagnostics ran. Phase 3G remains manual-QA pending until Jake confirms the full checklist.
