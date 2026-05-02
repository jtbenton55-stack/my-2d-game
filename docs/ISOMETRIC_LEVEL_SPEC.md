# Isometric level spec (vertical slice)

## Scope

Isolated dev mission **`iso_vertical_slice`** (`res://scenes/dev/IsoVerticalSlice.tscn`). Not in default `available_missions`. Does not modify CityHub, Hideout, MainMenu, or story missions.

## Scene hierarchy

- **`WorldRoot`** (`Node2D`, `y_sort_enabled`) — owns all map layers and **`EntityRoot`**.
- **Standalone `TileMapLayer` siblings** (Godot 4.6 — no deprecated `TileMap` parent):
  - **`GroundLayer`** — floor tiles.
  - **`DetailLayer`** — optional decals (empty in first pass).
  - **`WallLayer`** — perimeter walls; tile collision uses **physics layer 0** with **`collision_layer = 4`** (project **Walls** layer 3).
  - **`PropLayer`** — optional props (empty in first pass).
- **`EntityRoot`** (`Node2D`, `y_sort_enabled`) — player/dog parented here for depth sorting with tiles.

Boot flow still uses **`LevelBase`** (spawn, exit, HUD, mission completion).

## Runtime painting

`IsoVerticalSlice.gd` assigns the shared **`IsoVerticalSlice.tres`** to every `TileMapLayer` and paints a small rectangular room so the `.tscn` stays free of binary `tile_map_data`.

## Follow-ups (human)

- Replace placeholder atlas with an approved pack; tune **`tile_size`**, **`y_sort_origin`**, and collision polygons.
- Consider an **`IsoLevelBase`** once multiple iso missions exist.
- Revisit **`player.tscn` `collision_mask`** if wall interaction should differ per game mode.
