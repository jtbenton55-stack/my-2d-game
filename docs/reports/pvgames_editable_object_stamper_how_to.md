# PVGames Editable Object Stamper How-To

## Why Not TileMapLayer For Everything?

Moving a `TileMapLayer` moves every tile on that layer. That is useful for floors, roads, repeated panels, broad flat coverage, and repeated decals, but it is awkward for walls, signs, terminals, furniture, barriers, counters, shelves, and large structures that need individual editing.

The editable object workflow creates one `Node2D` per asset:

`PVG_Object Node2D with PVGEditableObject.gd -> Sprite2D`

Each object has its own position, scale, rotation, z-index, metadata, and centered Sprite2D pivot.

## Containers

- `PVG_EditableObjects`: root under `ArtRoot/World`.
- `BehindPlayerObjects`: background objects that stay behind the player.
- `OccludableObjects`: wall fronts, barriers, terminals, counters, and props that draw above the player using the 0M-B5 z-index approximation.
- `ForegroundObjects`: overhead pipes, beams, hanging signs, and always-front overlays.
- `ReviewObjects`: experimental assets that need inspection.

## Beginner Workflow

A. Open `res://scenes/hideout/tools/PVGamesObjectStamperTest.tscn`.

B. Select one sample object.

C. Move it.

D. Scale it.

E. Rotate it.

F. Confirm only that object changes.

G. Open `res://scenes/hideout/HideoutHub.tscn`.

H. Confirm `ArtRoot/World/PVG_EditableObjects` exists.

I. Use `res://src/tools/editor/PVGamesObjectStamperRunner.gd` in `dry_run_list` mode.

J. Use `dry_run_stamp` for one object.

K. If correct, stamp one object into `ArtRoot/World/PVG_EditableObjects/OccludableObjects`.

L. Select the stamped object and edit it normally.

## Transforming One Object

Select the stamped parent `Node2D`, not the container. Use the normal Godot move tool, scale fields, and `rotation_degrees`. Since the child `Sprite2D.centered` is true and the parent origin is centered, scaling and rotation happen around the object center by default.

## Visible Alpha Center Pivot

If the source PNG has significant transparent padding, `PVGEditableObject.gd` can offset the Sprite2D using the indexed alpha bounding box so the visible art center sits on the Node2D origin. Some dimetric assets still rotate oddly because their perspective is baked; for those, choose another directional source asset instead of rotating.

## Z-Index

Change the parent object's `z_index` to tune depth. Use behind containers for background dressing, occludable containers for objects that should cover the player, and foreground containers for always-front art.

## Duplicate And Delete

Use the Godot editor duplicate/delete commands for selected sample objects, or use the stamper tool's `duplicate_stamped_object()` and `delete_stamped_object()` helpers for scene-safe scripted edits.

## Safety

Do not place editable objects under `GameplayRoot`. Do not delete TileSet `.tres` resources or source PNGs. These objects are visual-only and should never have collision, physics, navigation, or station behavior.

## Restore From Backup

Before destructive stamper operations, the tool creates a timestamped `HideoutHub.phase0mb8_stamper_backup...tscn`. Replace `HideoutHub.tscn` with that backup if needed.

## Reporting Bad Pivots

Report the `object_id`, filename, source path, and whether the issue is texture padding, baked perspective, or an incorrect alpha bbox.
