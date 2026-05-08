# Asset Installation

Raw purchased art assets are intentionally local-only and are not committed to this repository.

## PVGames Cyber City Core

Install the PVGames Cyber City Core tiles locally at:

`assets/tilesets/cyber_city_core_tilesets/`

Expected subfolders:

`assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/`

`assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/`

The generated paint palettes under `assets/tilesets/pvgames_catalog_paintable/` reference PNG files from those local folders. If the raw PVGames files are missing, Godot may show missing textures in the paint palettes.

Do not redistribute purchased asset packs unless the license explicitly permits it. Keep local copies backed up outside Git.

## Monogon Isometric Assets

Monogon source PNGs are also treated as local-only purchased/source assets and should be installed locally under:

`assets/tilesets/monogon_isometric_tilesets/`

## Notes

- Generated `.tres` TileSet resources are allowed in Git.
- Godot `.tscn` scenes, scripts, reports, and project tooling remain trackable unless separately reviewed.
- Raw source PNGs and generated `.png.import` sidecars for purchased packs are ignored to prevent accidental staging.
