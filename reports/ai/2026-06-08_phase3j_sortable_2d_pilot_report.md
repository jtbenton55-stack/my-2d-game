# Phase 3J Sortable 2.5D Pilot Report

**Date:** 2026-06-08

## Goal

Implement an isolated Phase 3J validation pilot proving the blueprint 2.5D visual-depth contract: player/NPC proxies and a sortable prop draw behind/in front correctly via Y-sort, with fixed background/foreground bands.

## Branch and baseline git status summary

- **Branch:** `new-feature-roadmap-branch` (tracking `origin/new-feature-roadmap-branch`)
- **Baseline dirty (pre-existing, untouched by this pass):** `scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn`
- **Post-edit:** only new untracked Phase 3J pilot files added; no staged changes; `git diff --check` passes

## Files inspected

- `AGENTS.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` (Phase 3 Visual Pipeline, 2.5D contract, Y-sort, pivot rules, Phase 3J table)
- `scenes/dev/IsoVerticalSlice.tscn` (existing dev Y-sort pattern)
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (`OccludableObjects` staging, `EntityRoot` Y-sort)
- `src/levels/IsoVerticalSlice.gd`

## Files changed

- `scenes/dev/phase3j_sortable_2d_pilot/Phase3JSortable2DPilot.tscn` (new)
- `src/dev/phase3j_sortable_2d_pilot/Phase3JSortable2DPilot.gd` (new)

## Scene structure

```text
Phase3JSortable2DPilot
  VisualRoot
    BackgroundArt          (z_index -200, fixed)
      FloorLane / grid hint / label
    SortableWorld          (y_sort_enabled = true)
      PlayerProxy          (origin = floor pivot, WASD movement)
      NPCProxy             (static, same pivot rule)
      SortableProp         (counter-like prop, direct sibling — active Y-sort participant)
    ForegroundArt          (z_index 160, fixed)
      ForegroundStrip / label
    DebugVisuals           (z_index 2400)
      Title / instructions / live sort-hint labels
      PVGSortableObjectsRouteNote (palette routing note only — not in sort layer)
  Camera2D
```

Floor-contact pivots are marked with small yellow squares at each sortable node's origin (`FloorPivot`). Visual bodies extend upward from that origin (no child `z_index` sorting hacks).

## Implementation path chosen and why

- **Isolated dev scene + local script** — smallest reversible path; no production scene edits, no autoloads, no global depth manager.
- **Colored Polygon2D proxies** — fast to read, no PVGames asset routing risk, no raw asset moves.
- **`SortableWorld.y_sort_enabled`** — matches blueprint contract and existing `EntityRoot` / `WorldRoot` patterns in repo.
- **Fixed z_index bands for BackgroundArt / ForegroundArt** — matches blueprint Z-band guidance (-200 background, 160 foreground, 2400 debug).

## Existing systems reused

- Project input actions: `move_left`, `move_right`, `move_up`, `move_down`
- Godot 4.6 `Node2D.y_sort_enabled` sorting
- Dev scene placement pattern (`scenes/dev/…`)

## Systems intentionally left untouched

- `project.godot`
- `Player.gd`, `PlayerStaminaController.gd`
- Production Taco scenes, `HideoutHub.tscn`
- `CharacterAnimationMapperPreviewSandbox.tscn` (pre-existing dirty; not modified)
- PVGames Object Palette routing (Phase 3K not started)
- Autoloads, mission runtime, Phase 0J/0K, animation SpriteFrames promotion

## What was validated

| Check | Result |
|---|---|
| `git status --short --branch` before/after | PASS |
| `git diff --check` | PASS |
| Only intended new files added | PASS |
| Forbidden files unchanged in diff | PASS |
| Godot LSP diagnostics (`Phase3JSortable2DPilot.gd`) | PASS (0 issues) |
| Manual F6 runtime / draw-order playtest | PASS (Jake confirmed) |
| Godot MCP Pro runtime/play | **Not run** (editor offline; manual F6 validation used instead) |
| GdUnit4 | **Not run** (no relevant tests; pilot is visual/manual) |
| Godot DAP | **Not needed** (no runtime errors observed statically) |

## Godot MCP Pro/runtime validation

Godot MCP Pro was unavailable because the editor was not connected. Jake ran the manual F6 validation and confirmed the Phase 3J draw-order behavior looks good.

## Kimi usage

**Not used.** Local blueprint + existing repo Y-sort patterns were sufficient for this isolated pilot; no architecture ambiguity requiring advisory review.

## Safety confirmation

- Work confined to repo
- No commits/pushes/staging
- No production or animation sandbox edits
- Rollback: delete `scenes/dev/phase3j_sortable_2d_pilot/` and `src/dev/phase3j_sortable_2d_pilot/`

## Phase 3K / sandbox confirmations

- **Phase 3K Scene/Asset Browser:** not started
- **`CharacterAnimationMapperPreviewSandbox.tscn`:** not touched

## Known limitations

- Visual placeholders only (not PVGames props)
- NPC is static (sorting validated by position relative to prop; player movement covers dynamic case)
- No collision / gameplay separation demo (visual-only pilot)
- Godot MCP Pro runtime inspection was not performed; manual F6 validation passed instead
- PVGames Object Palette sortable route not wired — debug label documents future target: props stamped as direct `SortableWorld` children (organizational `PVGSortableObjects` folder optional in production, but active Y-sort participants must be direct siblings under `y_sort_enabled` parent)

## FIX1 — Active Y-sort parent correction

### Problem found

Initial pilot nested `SortableProp` under `PVGSortableObjects` inside `SortableWorld`. In Godot, only **direct children** of a `y_sort_enabled` node participate in Y-sort. The nested structure would sort `PVGSortableObjects` (at its container origin, default Y=0) against `PlayerProxy` and `NPCProxy`, not the prop's floor-contact Y at (480, 400). That could invalidate the depth-contract test.

### Fix applied

- Moved `SortableProp` to be a **direct child** of `SortableWorld` (sibling of `PlayerProxy` and `NPCProxy`).
- Removed `PVGSortableObjects` from the active sort layer.
- Added `PVGSortableObjectsRouteNote` under `DebugVisuals` (fixed Z, non-sorting) documenting future palette routing intent.
- Updated `_sortable_prop` NodePath to `$VisualRoot/SortableWorld/SortableProp`.

### Final active scene structure

```text
SortableWorld (y_sort_enabled = true)
  PlayerProxy
  NPCProxy
  SortableProp
```

### Validation run

| Check | Result |
|---|---|
| `git diff --check` | PASS |
| Godot LSP (`Phase3JSortable2DPilot.gd`) | PASS (0 issues) |
| F6 runtime / draw-order playtest | PASS (Jake confirmed) |

### Manual validation result

Jake ran F6 and confirmed the draw order above/below the prop matches the sort-hint labels. Phase 3J is considered validated.

## Rollback plan

Delete:
- `scenes/dev/phase3j_sortable_2d_pilot/Phase3JSortable2DPilot.tscn`
- `src/dev/phase3j_sortable_2d_pilot/Phase3JSortable2DPilot.gd`
- this report (optional)

## Manual test checklist

1. Open `res://scenes/dev/phase3j_sortable_2d_pilot/Phase3JSortable2DPilot.tscn`
2. Run the scene (F6)
3. Move player proxy **above** the sortable prop (lower Y, toward top of lane)
4. Confirm prop draws **in front of** player
5. Move player proxy **below** the prop (higher Y)
6. Confirm player draws **in front of** prop
7. Observe NPC proxy (below prop Y) draws in front of prop; move player above NPC to confirm NPC can occlude player when player Y is lower
8. Confirm background lane stays behind all sortable content
9. Confirm foreground strip stays in front
10. Confirm no production Taco/player/autoload changes

## Recommended next step

1. Add/keep a Phase 3J completion note in the blueprint.
2. Start Phase 3K Scene/Asset Browser planning as a read/search/select planning pass only.
3. Future: PVGames Object Palette v2 route **Sortable 2.5D prop** → stamp as direct `SortableWorld` child (optional `PVGSortableObjects` folder for organization only if children remain Y-sort siblings)
