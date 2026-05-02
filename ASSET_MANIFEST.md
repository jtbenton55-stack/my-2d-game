# Asset manifest (third-party / licensed sources)

This file tracks **external art and audio** used in the project: **what it is**, **where it lives**, and **how we may use it**.

---

## Monogon / Max Parata — 2D Isometric GIGA ENORMOUS Bundle

- **Publisher / creator:** Monogon (Max Parata isometric asset packs).
- **Use in this repo:** A **small curated subset** was cropped into a processed atlas for the **internal dev mission** `iso_vertical_slice` only (cyberpunk-flavored isometric vertical slice). Packs involved for this pass: **Isometric Cyberpunk Streets**, **Isometric Cyberpunk City**, **Isometric Cyberpunk Buildings**, and **Isomectric Cyberpunk Interior** (folder name as shipped).
- **Raw source folder (editor-import suppressed):** `assets/tilesets/iso_vertical_slice/source/monogon/` (see `.gdignore` in that tree — thousands of PNGs are **not** meant to be bulk-imported by Godot).
- **Processed atlas:** `assets/tilesets/iso_vertical_slice/processed/cyberpunk_iso_atlas.png`
- **Per-tile provenance:** `assets/tilesets/iso_vertical_slice/processed/cyberpunk_iso_atlas_source_map.md`
- **Godot TileSet:** `assets/tilesets/iso_vertical_slice/IsoCyberpunkVerticalSlice.tres`
- **Mission:** `iso_vertical_slice` → `res://scenes/dev/IsoVerticalSlice.tscn`

### License / terms — TODO

**TODO:** Paste the **official license text** from your **purchased download** (itch.io / publisher page / included `LICENSE` / EULA) here. **Do not ship** a build that relies on this pack until this section is completed and verified against the vendor terms.

---

## Legacy prototype iso placeholder (retained)

- **`assets/tilesets/iso_vertical_slice/prototype_iso_atlas.png`** and **`IsoVerticalSlice.tres`** remain for regression / comparison; the running cyberpunk slice uses **`IsoCyberpunkVerticalSlice.tres`** instead.
