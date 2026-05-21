# PVGames Object Palette ArtRoot / Mouse Placement Fix Report

**Date:** 2026-05-20  
**Branch:** `new-feature-roadmap-branch`  
**Scope:** Editor plugin fix for PVGames object/icon stamping

## Goal

Restore PVGames Object Palette stamping in Taco scenes that have `ArtRoot` paint layers directly under `ArtRoot` rather than an `ArtRoot/World` wrapper, and replace the deferred mouse placement button with a working 2D viewport click placement mode.

## Files changed

| File | Change |
|------|--------|
| `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` | Uses `ArtRoot/World` when present, otherwise falls back to direct `ArtRoot`; adds explicit stamp-root setup; adds mouse placement mode; renames origin button for accuracy |
| `addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd` | Enables 2D canvas input forwarding and routes canvas input to the dock |
| `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` | Updates palette dock validation expectations for the new setup and mouse-placement path |

## Files inspected

- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- `addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `docs/ART_READY_LEVEL_WORKFLOW.md`
- `docs/ISO_EDITOR_TILE_PALETTE.md`
- `docs/ISO_EDITOR_AUTHORING_WORKFLOW.md`

## Root cause

`TacoBellIso_Editable_RedesignTest.tscn` has:

```text
ArtRoot
  GroundArtLayer
  WallArtLayer
  PropArtLayer
  DecorBelowLayer
  DecorAboveLayer
  LightingLayer
```

It does **not** have `ArtRoot/World`.

The PVGames Object Palette dock was hardcoded to require `ArtRoot/World` before stamping. That made Taco redesign report `Error: ArtRoot/World not found` even though the scene still has the correct `ArtRoot` paint stack.

## Implementation summary

- Added `_art_object_root(scene_root)` to resolve the stamp parent:
  - Prefer `ArtRoot/World` when present for old scenes.
  - Fall back to direct `ArtRoot` for Taco editable/redesign scenes.
- `PVG_EditableObjects` is now created under the resolved art root.
- Added `Ensure Art Stamp Root` to explicitly create `PVG_EditableObjects`, object target containers, `IconObjects`, and icon target containers before stamping.
- Dry-run target paths now reflect the actual root that will be used.
- Replaced `Place With Mouse (Deferred)` with `Place With Mouse`.
- Added editor canvas input forwarding in the plugin.
- Left-click in the 2D viewport now converts the click through `container.make_input_local(mouse_event)` after resolving the target container, so mouse placement uses the same local coordinate space as the stamped child node.
- Right-click or Escape cancels pending mouse placement.
- Updated the validator so it checks `Ensure Art Stamp Root`, `Place With Mouse`, `_load_indexes`, and plugin canvas forwarding instead of stale labels/function names.

## Usage after fix

1. Open a Taco scene or scratch duplicate.
2. Open `PVGames Object Palette`.
3. Select an object or icon in `Results`.
4. Pick a target container.
5. Optional: set scale, rotation, and z override.
6. Optional: click `Ensure Art Stamp Root` to create the visual target folders before stamping.
7. Click `Dry Run Stamp` to confirm target path.
8. Use either:
   - `Stamp Selected at Typed Position`
   - `Place With Mouse`, then left-click the 2D viewport

For Taco redesign, stamps should appear under:

```text
ArtRoot/PVG_EditableObjects/...
```

For scenes that already have `ArtRoot/World`, stamps should continue to appear under:

```text
ArtRoot/World/PVG_EditableObjects/...
```

## Safety notes

- No production Taco scene changes were made by this fix.
- No `project.godot` changes were made by this fix.
- No gameplay, collision, Phase0J/Phase0K, mission completion, hider, or pilot logic changes were made.
- Stamping still refuses targets under `GameplayRoot`.
- Stamped nodes are visual object/icon nodes only.

## Validation

| Check | Result |
|-------|--------|
| Taco scene text inspection | Confirmed `ArtRoot` exists with direct paint layers and no `ArtRoot/World` |
| Plugin and validator diff review | Completed |
| `git diff --check` on changed plugin/validator files | Passed; only existing CRLF normalization warnings shown |
| Stale label/function grep | Passed; old `Stamp Selected at 2D View Center`, `Place With Mouse (Deferred)`, and `_load_object_index` checks are gone from the touched palette files |
| New hook grep | Passed; found `Ensure Art Stamp Root`, `handle_canvas_gui_input`, `_forward_canvas_gui_input`, `make_input_local`, and canvas forwarding enablement |
| Stale mouse transform grep | Passed; removed the prior `get_editor_viewport_2d().get_canvas_transform()` mouse-placement path from the palette files |
| Godot CLI parse/test | Not run; `godot` is not available on PATH and no Godot executable was found in the approved tools folder from this shell |
| Manual Godot editor validation | Still required by Jake in the editor |

## Manual validation checklist

- Open a scratch copy of Taco or another safe scene.
- Select an object/icon in the PVGames Object Palette.
- Click `Ensure Art Stamp Root` and confirm `PVG_EditableObjects` appears under `ArtRoot` or `ArtRoot/World` depending on scene structure.
- Run `Dry Run Stamp`; confirm target path is `ArtRoot/PVG_EditableObjects/...` for Taco redesign.
- Use `Stamp Selected at Typed Position` and confirm the node appears under `ArtRoot/PVG_EditableObjects/...`.
- Undo the stamp and confirm UndoRedo works.
- Use `Place With Mouse`, left-click in the 2D viewport, and confirm the node is stamped near the clicked position.
- Right-click or press Escape while armed and confirm placement cancels.
- Save/reopen only a scratch scene if persistence needs testing.
- Do not save production Taco unless intentionally keeping the visual stamp.

## Known limitations

- Full Godot parse/runtime validation still needs to be performed in an editor environment with the project Godot binary available.
- The PVGames Object Palette is a stamper for object/icon nodes, not a TileMap brush. TileMap painting still uses Godot's built-in TileMap/TileMapLayer painting tools.

## Rollback plan

Revert these files:

- `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- `addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd`
- `src/tools/editor/PVGamesObjectPaletteDockValidator.gd`

No scene rollback should be required unless manual testing stamps into and saves a scene.
