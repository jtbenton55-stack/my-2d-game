# PVGames Cyber City Tile Geometry Audit

Status: PASS

## Executive Conclusion

Measured samples are primarily variable-size sprites, with limited floor/atlas candidates that should be handled as a separate visual-only subset.

## Asset Roots Found

- `C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game\assets\tilesets\cyber_city_core_tilesets`

## Folders Scanned

- `C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game\assets\tilesets\cyber_city_core_tilesets`
- `C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game\assets\tilesets`
- `C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game`
- `C:\Users\jtben\Downloads`

## PNG / Import Counts

- Actual PNGs found: True
- Only `.png.import` files found: False
- CyberCity_Core_Tiles_1 actual PNGs: 1369
- CyberCity_Core_Tiles_2 actual PNGs: 5109
- CyberCity_Core_Tiles_1 `.png.import`: 1369
- CyberCity_Core_Tiles_2 `.png.import`: 5109
- Unmatched `.png.import`: 0
- Actual PNGs without `.png.import`: 0

## Representative Measurements

| Path | Category | Full | Alpha BBox | Transparent % | Classification | Confidence |
| --- | --- | --- | --- | ---: | --- | ---: |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/Floor1_1.png` | floor | 740x424 | 729x413 | 4.51 | atlas/sheet | 0.55 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/Floor1_2.png` | floor | 585x531 | 574x520 | 4.1 | atlas/sheet | 0.55 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/Floor1_3.png` | floor | 921x656 | 919x654 | 50.37 | atlas/sheet | 0.55 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/Floor1_4.png` | floor | 919x657 | 917x656 | 50.22 | atlas/sheet | 0.55 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_1.png` | floor | 49x45 | 45x45 | 19.5 | unclear | 0.45 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_2.png` | floor | 67x37 | 62x32 | 28.4 | diamond-ish | 0.85 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_3.png` | floor | 49x48 | 45x44 | 24.74 | unclear | 0.45 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_4.png` | floor | 63x36 | 62x34 | 21.25 | diamond-ish | 0.85 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_5.png` | floor | 74x53 | 69x50 | 54.44 | unclear | 0.45 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2/FloorMat1_6.png` | floor | 71x52 | 69x51 | 51.3 | unclear | 0.45 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier1_1.png` | wall | 35x114 | 31x112 | 29.5 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier1_2.png` | wall | 130x60 | 127x56 | 33.05 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier1_3.png` | wall | 36x112 | 31x111 | 30.38 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier1_4.png` | wall | 126x59 | 124x56 | 30.13 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier1_5.png` | wall | 94x97 | 92x95 | 52.2 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier1_6.png` | wall | 100x99 | 99x92 | 55.52 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier1_7.png` | wall | 97x97 | 97x95 | 53.27 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier1_8.png` | wall | 92x97 | 90x93 | 51.32 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier2_1.png` | wall | 119x63 | 117x60 | 48.1 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrier2_2.png` | wall | 35x112 | 30x110 | 56.38 | wall strip | 0.75 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel1_1.png` | prop | 63x101 | 62x97 | 44.79 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel1_2.png` | prop | 66x85 | 64x84 | 44.78 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel1_3.png` | prop | 66x75 | 63x71 | 40.79 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel1_4.png` | prop | 74x91 | 70x86 | 49.85 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel1_5.png` | prop | 60x98 | 58x94 | 43.44 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel1_6.png` | prop | 68x92 | 67x90 | 44.15 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel1_7.png` | prop | 63x80 | 61x78 | 41.19 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel1_8.png` | prop | 66x78 | 62x77 | 39.86 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel2_1.png` | prop | 59x75 | 54x73 | 32.75 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Barrel2_2.png` | prop | 60x74 | 54x72 | 33.04 | free prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard10_1.png` | tall | 39x103 | 29x98 | 53.85 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard10_2.png` | tall | 61x106 | 53x100 | 70.29 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard10_3.png` | tall | 36x87 | 29x82 | 48.34 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard10_4.png` | tall | 63x84 | 53x80 | 63.34 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard10_5.png` | tall | 52x106 | 46x105 | 58.85 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard10_6.png` | tall | 62x94 | 57x91 | 61.05 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard10_7.png` | tall | 60x95 | 57x93 | 61.65 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard10_8.png` | tall | 53x81 | 46x79 | 51.06 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard11_1.png` | tall | 55x109 | 50x100 | 46.34 | tall prop | 0.72 |
| `assets/tilesets/cyber_city_core_tilesets/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1/Billboard11_2.png` | tall | 15x132 | 7x129 | 67.02 | tall prop | 0.72 |

## Classification Summary

- True diamond floor cells: yes
- Square 48x48 cells: no
- Dimetric/parallax sprites: yes
- True tilesheets/atlases: yes
- Hybrid: yes

## Evidence Summary

- Pixel dimensions, alpha bounds, row-width profiles, and corner transparency were measured from real PNG files.
- See measurement JSON/CSV and the contact sheet for per-sample evidence.

## Contact Sheet

- Path: `res://docs/reports/pvgames_cyber_city_geometry_contact_sheet.png`

## Test Scene

- Path: `res://scenes/hideout/tests/PVGamesTileGeometryAuditTest.tscn`

## Recommended Godot Setup for 0M-B

- Best option: OPTION 4 - Hybrid: use Sprite2D broadly, with TileMapLayer only for measured floor/atlas subsets
- Runner-up: OPTION 1 - Visual-only Sprite2D/parallax dressing under ArtRoot/World
- Avoid: Avoid assuming the whole pack is one clean TileMap grid
- Tile shape: Isometric only for measured floor/atlas subset
- Tile size: measured per floor subset; sampled diamond-like FloorMat bboxes include about 62x32 and 62x34, not a global 48x24 pack
- TileMapLayer use: visual-only for measured floor/atlas subsets, collision disabled
- Sprite2D use: recommended for props, walls, signs, furniture, clutter, and any floor pieces that do not slice cleanly
- Collision: visual-only; keep GameplayRoot as gameplay truth.
- Y-sort/z-index: use ArtRoot/World visual layers, y-sort for free sprites, and small z-index bands for floor/wall/prop/foreground art.

## Risks

- Manual visual review of the contact sheet is still recommended.
- Do not infer diamond/square TileMap compatibility from .png.import sidecars.
- Do not modify HideoutHub or gameplay collision during this audit.

## Exact Next Prompt Recommendation

Proceed to 0M-B — Hideout PVGames visual dressing pass using a hybrid visual-only strategy: Sprite2D/free placement for walls, props, signs, furniture, and clutter; only use visual TileMapLayer for measured floor/atlas subsets that slice cleanly. Keep GameplayRoot, collision, interactions, decoration mode, store, MissionBoard, Taco Bell scenes, GameState, SceneManager, and Player.gd untouched.
