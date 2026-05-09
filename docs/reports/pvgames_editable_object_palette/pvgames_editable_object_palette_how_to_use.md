# PVGames Editable Object Palette How-To

This baked palette is a visual shelf for the B8 editable object stamper. It is not a production gameplay scene and it is not a TileMap palette.

TileMap palettes are still best for floors, roads, repeated panels, repeated decals, and broad flat coverage. This palette is for individual Sprite2D/Node2D objects: walls, barriers, signs, terminals, counters, shelves, large structures, foreground pieces, and anything you want to move, scale, rotate, duplicate, delete, or z-order by itself.

## Preview Scenes Are Not Production

Do not drag every preview into `HideoutHub`. The preview cards are browsing aids. Production `HideoutHub` should stay clean with empty containers under `ArtRoot/World/PVG_EditableObjects` until you intentionally stamp one chosen object with the B8 stamper.

## Depth Containers

- `BehindPlayerObjects`: background panels, back-wall details, and non-occluding dressing.
- `OccludableObjects`: walls, wall fronts, barriers, counters, shelves, terminals, tall props, and large physical objects.
- `ForegroundObjects`: overhead pipes, ceiling pieces, hanging signs, and always-front overlays.
- `ReviewObjects`: uncertain, oversized, awkwardly cropped, missing, or visually risky assets.

## First-Use Workflow

A. Open `res://scenes/hideout/tools/PVGamesEditableObjectMasterPalette.tscn`.

B. Open `res://scenes/hideout/tools/PVGamesEditableObjectPalette_OccludableObjects.tscn`.

C. Pick a wall/barrier `object_id`.

D. Use `PVGamesEditableObjectPaletteRunner.gd` with `MODE := "dry_run_find_object"`.

E. Use `MODE := "dry_run_stamp_object"`.

F. If correct, use B8 stamper or change the runner to `stamp_object` to stamp exactly one object into `ArtRoot/World/PVG_EditableObjects/OccludableObjects`.

G. Select the stamped object in `HideoutHub`.

H. Move, scale, and rotate it normally.

## Scene Paths

- Master: `res://scenes/hideout/tools/PVGamesEditableObjectMasterPalette.tscn`
- Behind: `res://scenes/hideout/tools/PVGamesEditableObjectPalette_BehindPlayerObjects.tscn`
- Occludable: `res://scenes/hideout/tools/PVGamesEditableObjectPalette_OccludableObjects.tscn`
- Foreground: `res://scenes/hideout/tools/PVGamesEditableObjectPalette_ForegroundObjects.tscn`
- Review: `res://scenes/hideout/tools/PVGamesEditableObjectPalette_ReviewObjects.tscn`

## Contact Sheets

Contact sheets live in `res://docs/reports/pvgames_editable_object_palette/contact_sheets/`. They are browsing-only and are labeled that way. Do not use contact sheets as source art.

## If A Preview Is Missing

The object is assigned to `ReviewObjects` and the card shows a warning. Use another asset or report the `object_id` and source path.

## If A Palette Scene Is Slow

Open the specific page scene instead of the container index scene. Large containers are paginated at 125 preview cards per page.

## If Labels Overlap

Use the normalized index or contact sheet for the same object_id. The stamped production object uses the B8 object metadata, not the label layout.

## Rotation Warning

Some dimetric assets have baked perspective and may look wrong when rotated. Prefer a source asset facing the right direction over rotating a perspective-heavy sprite.

## What Not To Touch

Do not manually edit `GameplayRoot`, Taco Bell scenes, gameplay scripts, source PNGs, TileSets, or collision. Do not mass-place previews into production `HideoutHub`.
