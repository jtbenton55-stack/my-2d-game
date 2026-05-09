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

## PVGames CyberCity Central Security

Install the PVGames CyberCity Central Security tiles locally at:

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/`

Expected subfolders:

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/CyberCity_CentralSecurity_Tiles_1/`

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/CyberCity_CentralSecurity_Tiles_2/`

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/CyberCity_CentralSecurity_Tiles_3/`

`assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles/CyberCity_CentralSecurity_Tiles_4/`

Raw Central Security PNGs are local-only purchased/source assets. Do not redistribute them unless the license permits it. Generated Central Security TileSets under `assets/tilesets/pvgames_central_security_paintable/` reference these local PNG files; missing source files will produce missing textures in Godot.

## PVGames Cyber City Icons and Doomsday Icons

Install these local-only purchased icon packs at:

- `res://assets/tilesets/cyber_city_core_tilesets/Store_Items/CyberCity_Icons`
- `res://assets/tilesets/cyber_city_core_tilesets/Store_Items/Doomsday Icons`

Raw icon PNGs and `.png.import` files are purchased/local-only source assets. Generated catalogs and dock entries reference local source images. Contact sheets are generated browsing aids, not source art. Missing source icons will produce missing previews/textures.
