# PVGames Icon Library How-To

Cyber City Icons and Doomsday Icons are iconography assets for UI badges, store thumbnails, mission symbols, evidence icons, objectives, warnings, map pins, screen graphics, decals, signage, stickers, and hologram markers.

They are not map TileSets and should not be added to floor/wall TileSet palettes.

Use contact sheets under `res://docs/reports/pvgames_icon_library/contact_sheets/` to visually browse icons and find `icon_id` values. Use `PVGamesIconLibrary.gd` to load icon textures by id in future UI work.

The existing `PVGames Object Palette` dock now includes an `Asset Type` filter. Choose `Icons` to search/filter icons, then use `Dry Run Stamp` before stamping world-decal icons into `ArtRoot/World/PVG_EditableObjects/IconObjects/<container>`.

Flat icons usually work best as signage, screen art, stickers, holograms, UI, or markers. They should remain visual-only and collision-free.

Future passes can use this registry for Store Terminal, MissionBoard, Scheme Cards, Evidence Board, Big Case, Pause Menu, and Objectives without rescanning source folders.
