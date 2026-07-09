# Level Blueprints (Dev-Only Design Overlay)

A blueprint is a deterministic JSON layout file that renders as a labeled, color-coded
overlay behind a mission scene in the Godot editor. You trace it with Mission Paint Dock
(floors/walls/collision) and Mission Dock (mechanics), then turn it off. It is authoring-only
and can never appear in a running game.

## The Three Artifacts

| Artifact | Where | What it is |
| --- | --- | --- |
| Blueprint spec | `docs/blueprints/<name>.blueprint.json` | The layout: regions + mechanic slots. AI agents generate this as plain text, so the same spec always renders identically. |
| In-editor overlay | `AuthoringBlueprintLayer` node in your scene | Draws the spec in the viewport: regions, labeled mechanic slots, dependency arrows, grid, and legend. |
| Build guide | `docs/blueprints/<name>.build_guide.md` | Generated Markdown checklist with per-slot instructions, in dependency order. Keep it open while building. |

Reference examples: `starter_room.blueprint.json` (minimal core chain) and
`laundromat_heist.blueprint.json` (full-feature demo with security, social stealth, Bentley).

## Workflow

1. **Get a blueprint.** Ask Cursor or OpenCode to write one (see "AI Generation Contract"
   below), or copy `starter_room.blueprint.json` and edit it by hand.
2. **Validate + generate the guide:**

```powershell
python src/tools/editor/level_blueprint/level_blueprint_validator.py
python src/tools/editor/level_blueprint/generate_blueprint_guide.py docs/blueprints/<name>.blueprint.json
```

3. **Add the overlay to your scene.** Add a `Node2D` named `AuthoringBlueprintLayer`
   (a good parent is `GameplayRoot/LayoutRoot`), attach
   `res://src/tools/authoring/AuthoringBlueprintLayer.gd`, keep it at position `(0, 0)`,
   and set `blueprint_path` to your spec. The blueprint appears immediately.
4. **Trace the layout.** Paint each region onto the LayoutRoot tile layer listed in the
   build guide (floor -> FloorLayer, wall -> WallLayer, collision_barrier -> CollisionBarrierLayer, ...).
5. **Place mechanics.** In Mission Dock's palette, use the **Place From Blueprint** section:
   Refresh Blueprint Slots, pick a `[MISSING]` slot, Prefill From Selected Slot, then place
   at the typed position (or with the mouse). The prefill copies the slot's mechanic type,
   suggested id, position, and zone size.
6. **Audit coverage.** In the Assist Browser, Refresh Scene Audit. The blueprint coverage
   entry reports `N/M slots placed` plus a Warning per missing or type-mismatched slot.
7. **Finish.** Untick `overlay_visible` (or delete the node). Done.

## Inspector Controls on AuthoringBlueprintLayer

- `blueprint_path` - the spec file to render.
- `overlay_visible` - master toggle.
- `opacity` (0.05-1.0) - dim the blueprint while tracing.
- `show_grid`, `show_regions`, `show_mechanic_slots`, `show_labels`,
  `show_dependency_arrows`, `show_legend` - per-element toggles.
- `draw_on_top` - draw above the map at low opacity instead of behind it (useful when
  checking placement against finished tiles).
- `reload_blueprint` - tick to re-read the file after editing it externally.

## Player-Safety Guarantees

1. The node calls `queue_free()` in `_ready()` whenever the game is actually running
   (`Engine.is_editor_hint()` is false), in editor play mode, debug builds, and exports alike.
2. `Phase0JRuntimeAuthoringHider` additionally strips any node named
   `AuthoringBlueprintLayer` at runtime as a redundant guard.
3. `tests/mission_authoring/LevelBlueprintLayerTest.gd` asserts the self-destruct so a
   regression cannot ship silently.

## Spec Format Reference

```json
{
  "blueprint_id": "my_mission_v1",
  "mission_id": "my_mission",
  "description": "One-line summary.",
  "grid_size": 64,
  "canvas": {"width": 2560, "height": 1600},
  "regions": [
    {"kind": "floor", "shape": "rect", "rect": [64, 64, 1408, 1472], "label": "Front Room"},
    {"kind": "wall", "shape": "polyline", "points": [[64, 64], [2496, 64]], "label": "North Wall"},
    {"kind": "marker", "shape": "circle", "center": [192, 1408], "radius": 48, "label": "Spawn Area"}
  ],
  "mechanic_slots": [
    {
      "slot_id": "entry_search",
      "mechanic_type": "SearchZone",
      "position": [704, 192],
      "size": [128, 96],
      "suggested_id": "my_mission.search_zone.01",
      "note": "What this slot does and how to wire it.",
      "depends_on": []
    }
  ]
}
```

Rules:

- Coordinates are scene-root-local pixels (the overlay node must sit at `(0, 0)`).
- `regions[].kind`: `floor`, `wall`, `cover`, `collision_barrier`, or `marker` - these map
  1:1 to Mission Paint Dock's LayoutRoot layers.
- `regions[].shape`: `rect` (`rect: [x, y, w, h]`), `polyline` (`points: [[x, y], ...]`),
  or `circle` (`center: [x, y]`, `radius`).
- `mechanic_slots[].mechanic_type`: any of Mission Dock's supported types (all 55). The
  validator rejects unknown types.
- `slot_id` and `suggested_id` must be unique within the file. Use Mission Dock's id
  convention for `suggested_id`: `<mission_id>.<snake_case_type>.<nn>` (exception:
  the first PlayerStartMarker should use `start_main`).
- `size` is optional (draws the zone footprint); `depends_on` is optional (draws
  dashed arrows and orders the build guide).
- Slot markers are color-coded by category (security red, puzzle purple, core orange, ...);
  the on-canvas legend is generated automatically.

## AI Generation Contract (for Cursor / OpenCode)

When asked to generate a blueprint, an agent must:

1. Write only `docs/blueprints/<mission_id>.blueprint.json` following the format above.
   Use plain integers on a `grid_size` multiple for all coordinates. No image generation.
2. Choose `suggested_id` values with the Mission Dock convention
   (`<mission_id>.<snake_case_type>.<nn>`, `start_main` for the first spawn).
3. Express lock-and-key or ordering logic through `depends_on` and explain the wiring in
   each slot's `note`.
4. Run `python src/tools/editor/level_blueprint/level_blueprint_validator.py` and fix
   failures.
5. Run `python src/tools/editor/level_blueprint/generate_blueprint_guide.py <spec>` to
   produce the build guide.

Because the spec is text and the renderer is deterministic, any agent regenerating the
same spec produces a pixel-identical overlay.

## Troubleshooting

- **Nothing draws:** check `blueprint_path` is set, `overlay_visible` is on, and the spec
  has no errors (errors are drawn in red at the node origin, and the validator lists them).
- **Blueprint misaligned with tiles:** the overlay node must be at position `(0, 0)`
  under a parent that is also at origin. Coordinates are plain world-space (not
  iso-projected); trace by matching world positions.
- **Coverage says MISMATCH:** a node carries the slot's `suggested_id` but has a
  different script than the slot's `mechanic_type` - fix whichever side is wrong.
- **Edited the JSON but the overlay didn't change:** tick `reload_blueprint`.
