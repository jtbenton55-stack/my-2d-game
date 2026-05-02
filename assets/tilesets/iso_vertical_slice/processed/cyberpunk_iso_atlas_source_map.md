# Cyberpunk iso vertical-slice atlas — source map

Processed atlas: `cyberpunk_iso_atlas.png`  
Grid: **6×2** cells of **64×64** px (see `build_cyberpunk_atlas.ps1` for crop rectangles).

All sources live under `assets/tilesets/iso_vertical_slice/source/monogon/`.

| Atlas `(col,row)` | Use | Monogon source file |
|-------------------|-----|---------------------|
| `(0, 0)` | Floor A — pavement | `Isometric Cyberpunk Streets/Architecture/Cyberpunk Streets-140-Pavement-3.png` |
| `(1, 0)` | Floor B — ground tile strip | `Isometric Cyberpunk Streets/Architecture/Cyberpunk Streets-6-GroundTile-2.png` |
| `(2, 0)` | Floor C — road chunk | `Isometric Cyberpunk City/StreetModules/Road_Chunk6.png` |
| `(3, 0)` | Wall / barrier A | `Isometric Cyberpunk Streets/Architecture/Cyberpunk Streets-14-BuildingModule-17.png` |
| `(4, 0)` | Wall / barrier B | `Isometric Cyberpunk Buildings/Building/SciFi_Buildings-46-Base_A.png` |
| `(5, 0)` | Door / entrance (visual, DetailLayer) | `Isomectric Cyberpunk Interior/Props&Characters/Megabuilding-94-Door-1.png` |
| `(0, 1)` | Prop — vent | `Isometric Cyberpunk Streets/Props/Cyberpunk Streets-156-Vent-4.png` |
| `(1, 1)` | Prop — crate / box | `Isometric Cyberpunk Streets/Props/Cyberpunk Streets-15-Box_Pharmacy-1.png` |
| `(2, 1)` | Prop — metal corner | `Isometric Cyberpunk Streets/Props/Cyberpunk Streets-146-MetalCorner.png` |
| `(3, 1)` | Prop — pills scatter (no collision) | `Isometric Cyberpunk Streets/Props/Cyberpunk Streets-138-Pills-1.png` |
| `(4, 1)` | Prop — cable strip (no collision) | `Isometric Cyberpunk Streets/Props/Cyberpunk Streets-12-Cable-24.png` |

Cell `(5, 1)` is unused (transparent fill in atlas builder).
