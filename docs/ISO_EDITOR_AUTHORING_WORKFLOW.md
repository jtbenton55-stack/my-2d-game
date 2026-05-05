# ISO Editor Authoring Workflow (Phase 2A.5)

## Core scene paths

1. How do I open the editable Taco Bell scene?  
Open `res://scenes/missions_iso/TacoBellIso_Editable.tscn` in Godot and run with `F6`.
2. Which scene should I edit?  
Edit `res://scenes/missions_iso/TacoBellIso_Editable.tscn` for normal authoring.
3. Which scene should I avoid editing?  
Do not hand-edit `res://scenes/missions_iso/TacoBellIsoBlockout.tscn` for layout placement changes.
4. What is authoring_mode?  
`authoring_mode` controls where layout/marker truth comes from (`generated`, `scene_authored`, `hybrid`).
5. Is Taco Bell currently generated, scene-authored, or hybrid?  
Taco Bell editable scene is configured as `hybrid`.

In authoring_mode = "hybrid", scene-authored marker positions are the source of truth for placement.  MissionDefinition data supplies metadata and mission rules.  If a scene marker exists for an object, runtime must use the scene marker position, not the generated definition position.

## Tile authoring

6. What layers can I hand-paint?  
`GameplayRoot/LayoutRoot/FloorLayer`, `WallLayer`, `CoverLayer`, `CollisionBarrierLayer`, `MarkerTileLayer`.
7. What layers should I not touch?  
`GameplayRoot/GameplayFloorLayer`, `GameplayCollisionLayer`, and runtime nodes under `GameplayRoot/RuntimeSystems`.
8. How do I paint floor?  
Select `FloorLayer`, choose floor tile, paint normally.
9. How do I paint wall?  
Select `WallLayer`, choose wall tile, paint blocking walls.
10. How do I paint cover?  
Select `CoverLayer`, choose cover tile, paint stealth/combat blockers.
11. How do I add/remove collision barriers?  
Edit `CollisionBarrierLayer`; run validator after any barrier changes.

## Marker authoring

12. How do I move the player spawn?  
Move marker `player_spawn_main` under `GameplayRoot/MarkerRoot/Spawns`.
13. How do I move Bentley spawn?  
Move marker `bentley_spawn_main` in `Spawns`.
14. How do I move a guard?  
Move `guard_spawn` markers in `GameplayRoot/MarkerRoot/Enemies`.
15. How do I move patrol points?  
Move `patrol_point` markers in `GameplayRoot/MarkerRoot/Patrols`; keep `order` values valid.
16. How do I move a poop bag?  
Move marker with `marker_type=poop_bag` in `Collectibles`.
17. How do I add a new poop bag?  
Duplicate a `poop_bag` marker, assign a unique `marker_id`, and validate.
18. How do I move a clue?  
Move `clue` marker in `Clues`.
19. How do I add a collectible?  
Duplicate a collectible marker in `Collectibles`, set unique `marker_id`.
20. How do I move the mission exit?  
Move marker `exit_return_to_louis` in `Exit`.
21. How do I move a route access marker?  
Move `route_access` or `bentley_vent_route` markers in `Routes`.
22. How do I move a transition marker?  
Move `transition` markers in `Transitions`.

## Validation and runtime checks

23. How do I validate the scene after editing?  
Run `validate_blockout()` on the scene root (`IsoMissionBase`), or use mission validator tooling.
24. How do I test that runtime used my edited position?  
Move a marker, save scene, run `F6`, compare marker position to spawned runtime node, and check `runtime_position_mismatches`.
25. What does the runtime still generate?  
Runtime objects (guards, cameras, interactables, triggers, debug systems) still instantiate from mission data plus marker placement.
26. What manual edits are safe?  
Marker positions and `LayoutRoot` tiles are intended-safe in hybrid mode.
27. What manual edits are not safe?  
Deleting required markers, duplicating IDs, changing runtime-only node structure, or editing generated runtime children.
28. What will be overwritten at runtime?  
`GameplayRoot/RuntimeSystems` and runtime spawned children under `EntityRoot/*` are regenerated each run.
29. How do I avoid duplicate marker ids?  
Use unique `marker_id` values per gameplay marker; validator reports duplicates.
30. How do I recover if I break the scene?  
Re-run bake tool from blockout, or restore from git; use `TacoBellIso_Editable_Test.tscn` for destructive experiments.

## Player-facing debug harness (Phase 2A.5)

31. How do I open the dev test harness?  
Run `TacoBellIso_Editable.tscn` and use the on-screen `IsoMissionDebugPanel` (debug builds only).
32. What can I test from the harness?  
Heat 0-3, mutation reroll, alarm trigger, extra guard spawn, Louis route lock/unlock, poop-bag grant/clear, and teleports (Start/Delivery Hub/Garage 1/Code Gate/Ambush/Bag Recovery/Exit).
33. How do I restart the iso test scene quickly?  
Use `Restart Taco Bell Iso` in `IsoMissionDebugPanel` (restarts `TacoBellIso_Editable.tscn`).
34. What input is used for interaction/combat?  
`E` = interact, `attack` action (default keyboard binding in this project is `J`) = attack.
35. How do I test Bentley scent trails?  
Use `Press E: Ask Bentley to sniff this trail.` on scent zones; fake trails increment `wrong_scent_trails_followed`, real trail grants `mission_access_item:real_scent_trail`.
36. How do I test poop bag use?  
Pick up any poop bag collectible (`Poop Bag collected. Count: X`), then interact with `PoopBagDecoy_loading_dock` to consume one and distract a nearby guard.
37. How do I test code gate wrong/correct paths?  
Interact with `Objective_solve_garage_office_code`; use keypad UI buttons (`Enter Wrong (Test)`, `Enter Correct (Test)`) or type code manually. Wrong attempts increment `wrong_code_attempts`; threshold escalates alert/alarm.
38. How do I test routes/transitions?  
`RouteAccess_louis_delivery_route_future_shortcut` is locked until `louis_delivery_route`; unlocked interaction teleports to disconnected route test area; use return transitions to safely re-enter main map.
39. How do I test stealth visibility?  
In debug builds, security camera cones and guard debug cones are visible; debug panel shows detection value/modifier and alert state.
40. Known placeholder limits after 2A.5?  
Bentley vent route remains a functional placeholder transition (no separate Bentley-control mode yet), and hideout shelf rendering for typed collectibles remains a separate UI pass.

## First safe edit tutorial

1. Open `TacoBellIso_Editable.tscn`.
2. Move marker `poop_bag_dog_station`.
3. Save scene.
4. Run scene with `F6`.
5. Pick up the poop bag.
6. Confirm poop bag count changed.
7. Run validator (`validate_blockout()`).
8. Undo or commit.

## Future hand-edit answer

In the future, can Jake delete/add floor and wall tiles, spawn tiles, enemy markers, poop bag markers, collision barriers, etc., and will it still run correctly?

- Yes for these layers/markers: `LayoutRoot` tile layers and `MarkerRoot` marker nodes with valid IDs/types. Moving clues, poop bags, guard spawns, patrol points, exits, route markers, and transition markers is supported.
- No or not yet: runtime-generated children under `RuntimeSystems`/`EntityRoot`, and unsupported marker type/data combinations.
- Overwritten at runtime: spawned guards/cameras/interactables/triggers/debug nodes.
- Safe to hand-edit: `FloorLayer`, `WallLayer`, `CoverLayer`, `CollisionBarrierLayer`, `MarkerTileLayer`, and marker transforms/properties.
- Requires validator after editing: all required markers, patrol orders, route/transition targets, collision-sensitive placements, and runtime position mismatch checks.
