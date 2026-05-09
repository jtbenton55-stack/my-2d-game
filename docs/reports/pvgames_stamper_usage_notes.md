# PVGames Stamper Usage Notes

Use `PVGamesArtStamper.gd` for irregular props: furniture, signs, shelves, displays, terminals, plants, clutter, and oversized one-off art.

- Tool path: `res://src/tools/editor/PVGamesArtStamper.gd`
- Sample manifest: `res://docs/reports/pvgames_sample_art_placement_manifest.json`
- Type: `@tool` `EditorScript`
- Default safety: refuses to overwrite the target scene unless an output scene path is supplied.
- Collision: does not create `StaticBody2D`, `Area2D`, or `CollisionShape2D`.
- Metadata: writes `pvgames_asset_id`, `category`, `subcategory`, `placement_method`, `visual_only`, and `collision_disabled`.

Use a real source PNG from `res://assets/tilesets/cyber_city_core_tilesets/`, target an `ArtRoot/World` layer such as `PropLayer` or `DecorationLayer`, and stamp into a duplicate/test scene first. Remove stamped art by deleting the `PVGamesStampedArt` container or the individual `PVG_*` Sprite2D nodes. Do not use TileMapLayer for irregular props.
