# PVGames Manual Art Placement Correction

Contact sheet images are for browsing only.

- Browse-only contact sheets live under `res://docs/reports/pvgames_palettes/`.
- Do not assign contact sheets to production `Sprite2D` nodes.
- Do not use contact sheets as TileSet sources.
- Actual PVGames source art lives under `res://assets/tilesets/cyber_city_core_tilesets/`.

Correct source path:

`res://assets/tilesets/cyber_city_core_tilesets/.../*.png`

Incorrect production texture path:

`res://docs/reports/pvgames_palettes/.../*.png`

For one-off props, use `Sprite2D` with an actual source PNG. For an atlas/sheet, either enable `Region` on `Sprite2D` and crop one part, or create/use a TileSet and paint with a `TileMapLayer`. For repeatable floors/walls, use TileSet + TileMapLayer only when the source slices cleanly. For irregular props, furniture, signs, displays, terminals, and clutter, use `Sprite2D` or `PVGamesArtStamper`.

Always place PVGames environment art under `ArtRoot/World`, never `GameplayRoot`, and never add gameplay collision to PVGames art.
