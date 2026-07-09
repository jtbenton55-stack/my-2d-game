# Build Guide: starter_room_v1

Generated from `starter_room.blueprint.json`. Do not edit by hand; re-run `python src/tools/editor/level_blueprint/generate_blueprint_guide.py docs/blueprints/starter_room.blueprint.json` after changing the spec.

- Mission ID: `starter_room`
- Canvas: 1280 x 960 px
- Grid size: 64 px
- Description: Minimal canonical blueprint example: one room with the core search -> reward -> route unlock -> extraction chain. Copy this file as the starting point for new blueprints.

## Setup

1. Open your mission scene (start from `scenes/templates/IsoMissionTemplate.tscn` for a new mission).
2. Add a `Node2D` named `AuthoringBlueprintLayer` with the script `res://src/tools/authoring/AuthoringBlueprintLayer.gd` (a good parent is `GameplayRoot/LayoutRoot`). Keep the node at position (0, 0).
3. Set its `blueprint_path` to `res://docs/blueprints/starter_room.blueprint.json`. The blueprint appears in the editor viewport.
4. Tune `opacity`, `draw_on_top`, and the `show_*` toggles while you work. The layer frees itself at runtime and is never visible to players.

## Trace Layout (Mission Paint Dock)

Paint each region onto its LayoutRoot tile layer:

| Region | Kind | Paint layer |
| --- | --- | --- |
| Main Room | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Outer Walls | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Divider Wall | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Center Counter | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Crate Cover | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Spawn Area | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |

## Place Mechanics (Mission Dock)

Slots are listed in dependency order; place them top to bottom. Use the Mission Dock palette's "Place From Blueprint" section to prefill each slot, then place at the typed position or with the mouse.

### 1. `player_start` - PlayerStartMarker

- Suggested ID: `start_main`
- Position: (192, 768)
- Parent: `GameplayRoot/MarkerRoot/Spawns`
- Instructions: Main player spawn. Mission Dock parents this under GameplayRoot/MarkerRoot/Spawns automatically.

### 2. `entry_search` - SearchZone

- Suggested ID: `starter_room.search_zone.01`
- Position: (384, 256)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Instructions: First interaction: searching here sets the search_done flag the reward requires.

### 3. `reward_pickup` - RewardNode

- Suggested ID: `starter_room.reward_node.01`
- Position: (960, 256)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `entry_search`
- Instructions: Requires entry_search's flag. Grants the reward that opens the exit route.

### 4. `exit_route_unlock` - RouteUnlockNode

- Suggested ID: `starter_room.route_unlock_node.01`
- Position: (960, 512)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `reward_pickup`
- Instructions: Requires reward_pickup's flag. Sets route_open for the extraction zone.

### 5. `extraction` - ExtractionZone

- Suggested ID: `starter_room.extraction_zone.01`
- Position: (1120, 768)
- Zone size: 128 x 128
- Parent: `MissionMechanics`
- Depends on: `exit_route_unlock`
- Instructions: Mission exit. Requires route_open from exit_route_unlock.

## Completion Checklist

- [ ] `player_start` (PlayerStartMarker) placed with id `start_main`
- [ ] `entry_search` (SearchZone) placed with id `starter_room.search_zone.01`
- [ ] `reward_pickup` (RewardNode) placed with id `starter_room.reward_node.01`
- [ ] `exit_route_unlock` (RouteUnlockNode) placed with id `starter_room.route_unlock_node.01`
- [ ] `extraction` (ExtractionZone) placed with id `starter_room.extraction_zone.01`

When everything is placed, run Mission Dock's Assist Browser "Refresh Scene Audit" - the blueprint coverage entry should report all slots placed. Then hide or delete the `AuthoringBlueprintLayer` node.
