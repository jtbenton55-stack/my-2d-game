# iso_vertical_slice tilesets

Internal-only assets for the **`iso_vertical_slice`** dev mission (`res://scenes/dev/IsoVerticalSlice.tscn`). Not part of default story progression.

## Active cyberpunk slice (Monogon subset)

- **`processed/cyberpunk_iso_atlas.png`** — curated **6×2** grid of **64×64** cells (downscaled/cropped from vendor PNGs). Built by **`processed/build_cyberpunk_atlas.ps1`** (PowerShell + `System.Drawing`).
- **`processed/cyberpunk_iso_atlas_source_map.md`** — maps each atlas cell to the original Monogon file path.
- **`IsoCyberpunkVerticalSlice.tres`** — isometric **`TileSet`** (`tile_size` **64×32**, **`physics_layer_0/collision_layer = 4`** → project **Walls** layer 3). Used by **`IsoVerticalSlice.gd`** at runtime.

## Legacy prototype (retained — do not delete)

- **`prototype_iso_atlas.png`** — placeholder grass/wall blocks for early wiring tests.
- **`IsoVerticalSlice.tres`** — minimal two-tile prototype **`TileSet`** pointing at that atlas.

Use the prototype pair for A/B comparison or tooling smoke tests; gameplay for the dev mission targets **`IsoCyberpunkVerticalSlice.tres`**.

## Raw vendor dumps

- **`source/monogon/`** — unmodified Cyberpunk (+ other) packs. Contains **`.gdignore`** so Godot does **not** bulk-import thousands of source PNGs. Do **not** point runtime **`TileSet`** textures directly here for shipping builds.

## Attribution / license

See **`ASSET_MANIFEST.md`** at the repo root. **TODO:** paste official Monogon license text from your purchase into that manifest before release builds.
