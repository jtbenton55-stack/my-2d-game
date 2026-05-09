# Hideout Phase 0M-B PVGames Asset Selection

Status: PASS - curated visual-only set selected from actual PVGames PNGs.

## Source

- Asset root: `res://assets/tilesets/cyber_city_core_tilesets`
- Geometry audit read: `res://docs/reports/pvgames_cyber_city_tile_geometry_audit.md`
- Strategy: hybrid visual-only dressing, with Sprite2D placement for props/walls and measured floor/atlas subsets used only as visual art.

## Selection Principles

- Every selected asset is an actual `.png`, not a `.png.import` sidecar.
- PVGames art is visual-only and has no collision.
- Assets are clustered by station purpose instead of scattered randomly.
- Open Decor Area remains intentionally open.
- GameplayRoot remains gameplay truth.

## Curated Asset List

| Asset | Area | Layer | Z | Method | Purpose / caution |
| --- | --- | --- | ---: | --- | --- |
| `FloorMat1_2.png` | greenhouse/open decor | FloorLayer | -6 | Sprite2D | Diamond-like floor accent; not a global 48x24 tile. |
| `FloorMat1_4.png` | greenhouse/open decor | FloorLayer | -6 | Sprite2D | Companion diamond-like floor accent. |
| `FloorMat1_5.png` | planning | FloorLayer | -5 | Sprite2D | Planning-table rug patch. |
| `FloorMat1_6.png` | planning | FloorLayer | -5 | Sprite2D | Planning-table rug patch. |
| `FloorMat1_1.png` | cozy lounge | FloorLayer | -5 | Sprite2D | Warm lounge mat. |
| `FloorMat1_3.png` | cozy lounge | FloorLayer | -5 | Sprite2D | Warm lounge mat. |
| `FloorMat1_7.png` | entry | FloorLayer | -4 | Sprite2D | Entry warning/floor marker. |
| `FloorMat1_8.png` | loot crate | FloorLayer | -4 | Sprite2D | Delivery drop pad. |
| `CityWalls1_1.png` | west displays | WallLayer | -7 | Sprite2D | Display-wall backer. |
| `CityWalls1_2.png` | greenhouse | WallLayer | -8 | Sprite2D | North glass/garage wall impression. |
| `CityWalls1_3.png` | west displays | WallLayer | -7 | Sprite2D | Display-wall backer. |
| `CityWalls1_4.png` | greenhouse | WallLayer | -8 | Sprite2D | North glass/garage wall impression. |
| `CityWalls1_6.png` | greenhouse | WallLayer | -8 | Sprite2D | North glass/garage wall impression. |
| `CityWalls1_7.png` | MissionBoard | WallLayer | -7 | Sprite2D | Mission board backer. |
| `CityWalls1_8.png` | Big Case | WallLayer | -7 | Sprite2D | Evidence board backer. |
| `Door10_4.png` | entry | WallLayer | -4 | Sprite2D | Cyber door/exit silhouette. |
| `Table2_2.png` | PlanningTable | PropLayer | 2 | Sprite2D | Central planning table. |
| `Chair10_1.png` | PlanningTable | PropLayer | 3 | Sprite2D | Planning chair. |
| `Chair10_5.png` | PlanningTable | PropLayer | 3 | Sprite2D | Planning chair. |
| `ComputerMonitor1_1.png` | PlanningTable | PropLayer | 4 | Sprite2D | Scheme/planning monitor. |
| `ComputerScreen1_4.png` | MissionBoard | PropLayer | 4 | Sprite2D | Mission board screen bank. |
| `BuildingLargeSign10_2.png` | MissionBoard | PropLayer | 5 | Sprite2D | Neon mission header. |
| `ComputerScreen1_7.png` | Big Case | PropLayer | 4 | Sprite2D | Mystery/evidence display. |
| `BuildingLights1_3.png` | Big Case | PropLayer | 5 | Sprite2D | Clue-board light. |
| `KitchenCabinet1_2.png` | BentleyCare | PropLayer | 2 | Sprite2D | Care cabinet. |
| `CardboardBox1_3.png` | BentleyCare | PropLayer | 3 | Sprite2D | Treat/poop-bag box. |
| `Crate1_2.png` | BentleyCare | PropLayer | 3 | Sprite2D | Cleaning/care crate. |
| `Crate1_4.png` | LootCrate | PropLayer | 3 | Sprite2D | Main delivery crate. |
| `CardboardBox1_1.png` | LootCrate | PropLayer | 3 | Sprite2D | Delivery box. |
| `CardboardBox1_5.png` | LootCrate | PropLayer | 3 | Sprite2D | Delivery box. |
| `Terminal1_2.png` | StoreTerminal | PropLayer | 4 | Sprite2D | Store terminal focal prop. |
| `KitchenCabinet1_5.png` | StoreTerminal | PropLayer | 3 | Sprite2D | Store counter/cabinet. |
| `BuildingLargeSign12_2.png` | StoreTerminal | PropLayer | 5 | Sprite2D | Shady store sign. |
| `Bed1_4.png` | Bentley/cozy lounge | PropLayer | 2 | Sprite2D | Bentley bed stand-in. |
| `Couch1_2.png` | cozy lounge | PropLayer | 2 | Sprite2D | Lounge couch. |
| `Chair10_3.png` | Jake | PropLayer | 3 | Sprite2D | Jake hangout chair. |
| `Chair10_7.png` | Mere | PropLayer | 3 | Sprite2D | Mere hangout chair. |
| `Barrel1_2.png` | cozy lounge | PropLayer | 3 | Sprite2D | Small improvised side table. |
| `ConvenienceStoreShelf1_2.png` | PolaroidWall | CollectibleLayer | 3 | Sprite2D | Photo display shelf. |
| `ConvenienceStoreShelf1_4.png` | GlowGuyShelf | CollectibleLayer | 3 | Sprite2D | Lit collectible shelf. |
| `ConvenienceStoreShelf1_6.png` | TinyIconShelf | CollectibleLayer | 3 | Sprite2D | Small-item display shelf. |
| `KitchenCabinet1_7.png` | PoopBagCareDisplay | CollectibleLayer | 3 | Sprite2D | Utility display/care cabinet. |
| `Billboard10_5.png` | west displays | CollectibleLayer | 4 | Sprite2D | Noir/cyber display accent. |
| `Plant1_1.png` | greenhouse | PropLayer | 3 | Sprite2D | Greenhouse plant. |
| `Plant1_5.png` | greenhouse | PropLayer | 3 | Sprite2D | Greenhouse plant. |
| `Plant2_3.png` | greenhouse | PropLayer | 3 | Sprite2D | Greenhouse plant. |
| `Computer1_6.png` | HeatScanner | PropLayer | 3 | Sprite2D | Scanner/status machine. |
| `ComputerScreen1_2.png` | HeatScanner | PropLayer | 4 | Sprite2D | Warning screen. |
| `ACUnit1_2.png` | foreground edge | ForegroundLayer | 1 | Sprite2D | Rooftop machinery depth. |
| `ACUnit2_6.png` | foreground edge | ForegroundLayer | 1 | Sprite2D | Rooftop machinery depth. |

## Areas Intentionally Kept Open

- `OpenDecorZone` remains mostly open with only light floor markers.
- Central movement lane remains readable.
- Entry/care corner has clustered props but no gameplay collision.

## No External Assets

No external assets were added. The pass uses PVGames Cyber City Core PNGs already in the project plus simple Godot visual primitives for tint/glow labels.
