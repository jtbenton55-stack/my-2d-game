# PVGames Object Palette Dock How-To

## Enable The Plugin

Open Godot, then go to Project -> Project Settings -> Plugins and enable `PVGames Object Palette`.

The dock appears as `PVGames Object Palette`.

## Basic Workflow

1. Open `res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`.
2. Search for `wall`, `barrier`, `terminal`, `sign`, or `shelf`.
3. Filter by `OccludableObjects` for most walls/props/barriers.
4. Select one result.
5. Confirm the preview and details panel update.
6. Click `Dry Run Stamp`.
7. Click `Stamp Selected at Typed Position` or `Stamp Selected at 2D View Center`.
8. Select the new object in the scene and move, scale, rotate, duplicate, or delete it normally.

## Placement Modes

- `Dry Run Stamp` prints the target scene, source texture, target container, position, scale, rotation, z-index, and safety flags without modifying the scene.
- `Stamp Selected at Typed Position` creates one editable object at the X/Y fields.
- `Stamp Selected at 2D View Center` currently uses `Vector2.ZERO` as a documented fallback because reliable 2D viewport center access is deferred.
- `Place With Mouse` is deferred and reports that status in the dock.

## What Gets Created

The dock creates one `Node2D` using `PVGEditableObject.gd` with a centered `Sprite2D` child:

`ArtRoot/World/PVG_EditableObjects/<container>/PVG_Object_<category>_<shortid>`

The stamped object stores metadata including `object_id`, `source_png_path`, `source_set`, category, recommended container, and `created_by = PVGamesObjectPaletteDock`.

## TileMap Versus Object Dock

Floors, roads, broad panels, and repeated flat coverage still belong on TileMap layers. Walls, props, signs, barriers, terminals, shelves, counters, furniture, large structures, and foreground pieces belong in this dock when you want individual move/scale/rotation.

## Troubleshooting

- If `ArtRoot/World` is missing, the dock refuses to stamp.
- If the texture is missing, the dock refuses to stamp.
- If scale looks wrong, adjust Scale X/Y before stamping or after selecting the object.
- If rotation looks odd, the dimetric perspective may be baked into the sprite. Pick a better directional source asset when possible.
- Do not place anything under `GameplayRoot`.

## Buttons Are Cut Off / I Cannot See Dry Run Stamp

The dock content is scrollable. Use the scrollbar or mouse wheel inside the `PVGames Object Palette` dock to reach the `Actions` section.

The `Actions` section contains:

- `Dry Run Stamp`
- `Stamp Selected at Typed Position`
- `Stamp Selected at 2D View Center`
- `Place With Mouse (Deferred)`
- `Copy Object ID`
- `Refresh Index`

If the dock layout still looks wrong, resize the dock, disable/re-enable the plugin, or reset the Godot editor layout.
