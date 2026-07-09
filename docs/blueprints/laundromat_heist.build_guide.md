# Build Guide: laundromat_heist_v1

Generated from `laundromat_heist.blueprint.json`. Do not edit by hand; re-run `python src/tools/editor/level_blueprint/generate_blueprint_guide.py docs/blueprints/laundromat_heist.blueprint.json` after changing the spec.

- Mission ID: `laundromat_heist`
- Canvas: 2560 x 1600 px
- Grid size: 64 px
- Description: Fuller reference blueprint: three-room laundromat heist with security, social stealth, Bentley support, and a lock-and-key chain. Demonstrates every major slot feature (size, depends_on, notes, security parents).

## Setup

1. Open your mission scene (start from `scenes/templates/IsoMissionTemplate.tscn` for a new mission).
2. Add a `Node2D` named `AuthoringBlueprintLayer` with the script `res://src/tools/authoring/AuthoringBlueprintLayer.gd` (a good parent is `GameplayRoot/LayoutRoot`). Keep the node at position (0, 0).
3. Set its `blueprint_path` to `res://docs/blueprints/laundromat_heist.blueprint.json`. The blueprint appears in the editor viewport.
4. Tune `opacity`, `draw_on_top`, and the `show_*` toggles while you work. The layer frees itself at runtime and is never visible to players.

## Trace Layout (Mission Paint Dock)

Paint each region onto its LayoutRoot tile layer:

| Region | Kind | Paint layer |
| --- | --- | --- |
| Front Room (Washers) | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Back Office | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Alley / Loading | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Outer Walls | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Office Wall (door gap at south) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Alley Wall (door gap at east) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Washer Row A | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Washer Row B | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Office Desk | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Laundry Cart Cover | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Alley Dumpster | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Spawn Area | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |
| Extraction Area | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |

## Place Mechanics (Mission Dock)

Slots are listed in dependency order; place them top to bottom. Use the Mission Dock palette's "Place From Blueprint" section to prefill each slot, then place at the typed position or with the mouse.

### 1. `player_start` - PlayerStartMarker

- Suggested ID: `start_main`
- Position: (192, 1408)
- Parent: `GameplayRoot/MarkerRoot/Spawns`
- Instructions: Player enters through the front door, bottom-left.

### 2. `front_counter_search` - SearchZone

- Suggested ID: `laundromat_heist.search_zone.01`
- Position: (704, 192)
- Zone size: 128 x 96
- Parent: `MissionMechanics`
- Instructions: Front counter: searching reveals the office keycard location and sets the flag the keycard pickup requires.

### 3. `keycard_pickup` - InventoryPickupNode

- Suggested ID: `laundromat_heist.inventory_pickup_node.01`
- Position: (1216, 576)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `front_counter_search`
- Instructions: Office keycard hidden between washer rows. Requires front_counter_search.

### 4. `office_door` - LockedInteractionNode

- Suggested ID: `laundromat_heist.locked_interaction_node.01`
- Position: (1472, 704)
- Zone size: 96 x 128
- Parent: `MissionMechanics`
- Depends on: `keycard_pickup`
- Instructions: Office door in the wall gap. Unlocks with the keycard item from keycard_pickup.

### 5. `office_safe_search` - SearchZone

- Suggested ID: `laundromat_heist.search_zone.02`
- Position: (2112, 512)
- Zone size: 128 x 96
- Parent: `MissionMechanics`
- Depends on: `office_door`
- Instructions: Safe behind the office desk. Only reachable after office_door opens.

### 6. `cash_reward` - RewardNode

- Suggested ID: `laundromat_heist.reward_node.01`
- Position: (2240, 512)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `office_safe_search`
- Instructions: The heist target. Requires office_safe_search's flag.

### 7. `manager_inspection` - InspectionZone

- Suggested ID: `laundromat_heist.inspection_zone.01`
- Position: (1280, 960)
- Zone size: 256 x 256
- Parent: `MissionMechanics`
- Instructions: Manager patrols the front room south aisle; player needs a believable cover story to pass.

### 8. `folding_task` - BelievableTaskZone

- Suggested ID: `laundromat_heist.believable_task_zone.01`
- Position: (704, 1216)
- Zone size: 128 x 128
- Parent: `MissionMechanics`
- Instructions: Folding laundry sells the cover story used by manager_inspection.

### 9. `bentley_vent` - BentleyCrawlspaceConnector

- Suggested ID: `laundromat_heist.bentley_crawlspace_connector.01`
- Position: (1408, 128)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Instructions: Optional route: Bentley can crawl into the office through the vent to open the door from inside.

### 10. `dryer_distraction` - DistractionObject

- Suggested ID: `laundromat_heist.distraction_object.01`
- Position: (960, 832)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Instructions: Overloading the dryer pulls the manager away from the inspection aisle.

### 11. `office_camera` - SecurityCameraAuthor

- Suggested ID: `laundromat_heist.security_camera_author.01`
- Position: (1536, 128)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Camera watching the office door. Parent under GameplayRoot/SecurityAuthoringRoot.

### 12. `alley_guard_route` - GuardPatrolRouteAuthor

- Suggested ID: `laundromat_heist.guard_patrol_route_author.01`
- Position: (1984, 1184)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Alley patrol loop between the dumpster and the loading door. Parent under GameplayRoot/SecurityAuthoringRoot.

### 13. `alley_guard_spawn` - GuardSpawnAuthor

- Suggested ID: `laundromat_heist.guard_spawn_author.01`
- Position: (2240, 1056)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Depends on: `alley_guard_route`
- Instructions: Guard spawn tied to alley_guard_route. Parent under GameplayRoot/SecurityAuthoringRoot.

### 14. `poop_bag_bonus` - PoopBagAuthor

- Suggested ID: `laundromat_heist.poop_bag_author.01`
- Position: (1728, 1408)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Bonus collectible behind the dumpster. Parent under GameplayRoot/SecurityAuthoringRoot.

### 15. `alley_route_unlock` - RouteUnlockNode

- Suggested ID: `laundromat_heist.route_unlock_node.01`
- Position: (2368, 832)
- Zone size: 96 x 128
- Parent: `MissionMechanics`
- Depends on: `cash_reward`
- Instructions: Loading door to the alley opens once the cash is taken.

### 16. `extraction` - ExtractionZone

- Suggested ID: `laundromat_heist.extraction_zone.01`
- Position: (2368, 1408)
- Zone size: 128 x 128
- Parent: `MissionMechanics`
- Depends on: `alley_route_unlock`
- Instructions: Escape through the alley. Requires alley_route_unlock's route_open flag.

### 17. `getaway_music` - MusicTriggerZone

- Suggested ID: `laundromat_heist.music_trigger_zone.01`
- Position: (1984, 1472)
- Zone size: 512 x 128
- Parent: `MissionMechanics`
- Instructions: Music swap to the getaway theme when entering the alley end.

## Completion Checklist

- [ ] `player_start` (PlayerStartMarker) placed with id `start_main`
- [ ] `front_counter_search` (SearchZone) placed with id `laundromat_heist.search_zone.01`
- [ ] `keycard_pickup` (InventoryPickupNode) placed with id `laundromat_heist.inventory_pickup_node.01`
- [ ] `office_door` (LockedInteractionNode) placed with id `laundromat_heist.locked_interaction_node.01`
- [ ] `office_safe_search` (SearchZone) placed with id `laundromat_heist.search_zone.02`
- [ ] `cash_reward` (RewardNode) placed with id `laundromat_heist.reward_node.01`
- [ ] `manager_inspection` (InspectionZone) placed with id `laundromat_heist.inspection_zone.01`
- [ ] `folding_task` (BelievableTaskZone) placed with id `laundromat_heist.believable_task_zone.01`
- [ ] `bentley_vent` (BentleyCrawlspaceConnector) placed with id `laundromat_heist.bentley_crawlspace_connector.01`
- [ ] `dryer_distraction` (DistractionObject) placed with id `laundromat_heist.distraction_object.01`
- [ ] `office_camera` (SecurityCameraAuthor) placed with id `laundromat_heist.security_camera_author.01`
- [ ] `alley_guard_route` (GuardPatrolRouteAuthor) placed with id `laundromat_heist.guard_patrol_route_author.01`
- [ ] `alley_guard_spawn` (GuardSpawnAuthor) placed with id `laundromat_heist.guard_spawn_author.01`
- [ ] `poop_bag_bonus` (PoopBagAuthor) placed with id `laundromat_heist.poop_bag_author.01`
- [ ] `alley_route_unlock` (RouteUnlockNode) placed with id `laundromat_heist.route_unlock_node.01`
- [ ] `extraction` (ExtractionZone) placed with id `laundromat_heist.extraction_zone.01`
- [ ] `getaway_music` (MusicTriggerZone) placed with id `laundromat_heist.music_trigger_zone.01`

When everything is placed, run Mission Dock's Assist Browser "Refresh Scene Audit" - the blueprint coverage entry should report all slots placed. Then hide or delete the `AuthoringBlueprintLayer` node.
