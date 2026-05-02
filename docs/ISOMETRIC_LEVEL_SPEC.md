# Isometric level spec (vertical slice)

## Scope

Isolated dev mission **`iso_vertical_slice`** (`res://scenes/dev/IsoVerticalSlice.tscn`). Not in default `available_missions`. Does not modify CityHub, Hideout, MainMenu, or story missions.

## Scene hierarchy

- **`WorldRoot`** (`Node2D`, `y_sort_enabled`) — owns all map layers and **`EntityRoot`**.
- **Standalone `TileMapLayer` siblings** (Godot 4.6 — no deprecated `TileMap` parent):
  - **`GroundLayer`** — floor tiles.
  - **`DetailLayer`** — decals (e.g. door sprite near exit); tiles typically **without** collision polygons.
  - **`WallLayer`** — perimeter walls; tile collision uses **physics layer 0** with **`collision_layer = 4`** (project **Walls** layer 3).
  - **`PropLayer`** — scatter props; **solid** tiles use **footprint-only** collision (bottom band of the 64×64 cell), not full art height.
- **`EntityRoot`** (`Node2D`, `y_sort_enabled`) — player/dog parented here for depth sorting with tiles.

Boot flow still uses **`LevelBase`** (spawn, exit, HUD, mission completion).

## `IsoVerticalSlice` boot flow (dev slice)

- **Spawn / exit:** Player spawn uses map cell **`(-ROOM_HALF + 2, 0)`** (west); **`ExitZone`** uses **`(ROOM_HALF - 1, 0)`** (east). This keeps the player away from the exit diamond on load.
- **Exit `Area2D`:** **`ExitZone.monitoring`** is disabled for the first part of boot, then re-enabled after a short delay so tile layers and deferred paints cannot cause a spurious **`body_entered`** during setup.
- **Paint timing:** Floors and walls paint after **`await get_tree().process_frame`**. The door uses **`call_deferred("_paint_iso_room_details")`**. Each **`PropLayer`** cell is separated by **`await get_tree().process_frame`** inside **`_paint_iso_room_details`** — without this, only the first prop cell persisted on some runs (Godot 4.6 / shared `TileSet`).

## Runtime painting

`IsoVerticalSlice.gd` assigns **`IsoCyberpunkVerticalSlice.tres`** to every `TileMapLayer` (or builds an equivalent runtime **`TileSet`** from **`processed/cyberpunk_iso_atlas.png`** if the `.tres` atlas texture is not importable yet) and paints a rectangular room (mixed floor variants, alternating wall art, door decal on **`DetailLayer`**, a few **`PropLayer`** props). The `.tscn` stays free of binary `tile_map_data`.

## Tile metrics (cyberpunk slice)

- **Atlas:** `processed/cyberpunk_iso_atlas.png` — **384×128** px, cells **64×64**.
- **`TileSet`:** `IsoCyberpunkVerticalSlice.tres` — **`tile_shape`** isometric, **`tile_size = Vector2i(64, 32)`**, **`texture_region_size = Vector2i(64, 64)`** (matches legacy prototype footprint so movement/camera tuning stays comparable).
- **Raw Monogon PNGs** live under `source/monogon/` with **`.gdignore`** to avoid editor import churn; **processed** art lives outside that ignored tree.

## Follow-ups (human)

- Paste vendor license into **`ASSET_MANIFEST.md`** before shipping any build using Monogon art.
- Tune **`y_sort_origin` / texture origins** per tile if tall façades still sort oddly against the player.
- Consider an **`IsoLevelBase`** once multiple iso missions exist.
- Revisit **`player.tscn` `collision_mask`** if wall interaction should differ per game mode.
