# Taco Bell Phase 0K v2 Playable Mission Loop Repair

Status: **PARTIAL**

0K v2 adds the missing playable-loop pieces without touching the protected source scene or wall collision. The duplicate now has a QuestManager objective data source the pause menu can read, a safe Bentley key 3 fetch path, three code options with no in-game correct-code hint, a visible delivery bag objective, a Louis exit token, active camera nodes at CAM markers, and active guard patrol tokens at GUARD markers.

The pass is partial because full out-of-bounds tile/node cleanup was not completed with a FloorLayer flood fill, and pause-menu UI rendering still needs manual playtest verification even though the data source now populates.

## Safety Baseline

- Backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0k_backup.20260506_180122.tscn`
- Source hash before/after: `6E4E9A790D257126B6F8A17587BACAF6` / `6E4E9A790D257126B6F8A17587BACAF6`
- Duplicate hash before/after: `12EE2E9F39021A084EB0A05A6B5C0D7E` / `A96822E218C0B9A6D022649C7F299D27`
- Wall collision count before/after: `2368` / `2368`
- Runtime labels preserved: `188`
- Generated runtime debug interactables: `139`
- CAM markers found: `6`
- GUARD markers found: `7`

## Shared Script Patches

`res://src/autoload/QuestManager.gd`

- Added `add_objective()`, `set_current_objective()`, `complete_objective_id()`, `get_current_objective()`, and `get_completed_objectives()`.
- Reason: `pause_menu.gd` already called the getter names, but `QuestManager` did not implement them. Scene-local adapters could update QuestManager, but the pause menu still had no API to read.
- Risk: low. Existing `set_objective()` and `complete_objective()` behavior remains.

`res://src/player/DogCompanion.gd`

- Fixed Bentley fetch/key 3 by replacing unsafe arbitrary property reads with safe property-or-metadata lookup.
- Reason: key 3 scans `interactable` nodes, including Phase0J/0K nodes that do not all expose the same exported properties.
- Validation: direct `_try_fetch()` runtime call did not crash and Bentley remained valid.

## Objectives

Pause menu source:

- `res://src/ui/test_ui/pause_menu.gd`
- `_objectives_text()`
- Reads `QuestManager.get_current_objective(mission_id)` and `QuestManager.get_completed_objectives(mission_id)`

0K now makes those methods real. `Phase0JObjectiveAdapter` calls the new QuestManager API for current/inspected/completed objectives. Runtime validation confirmed the objective data source becomes non-empty after delivery-bag interaction.

Pause menu UI rendering is `manual_check_required`, because the data path is validated but the actual paused submenu button rendering was not automated.

## Code Gate

The code UI now shows these selectable options:

- `2174`
- `0420`
- `9021`

The in-game `DEBUG CODE: 0420` hint was removed. Runtime validation confirmed:

- At least three options present
- No correct-code hint text present
- `2174` fails
- `0420` unlocks the gate
- Gate unlock state still updates the mission state adapter and 0K completion controller

## Louis Exit

- Node: `GameplayRoot/GeneratedRuntimeInteractables/LouisExitToken`
- Position: `Vector2(800, 848)`
- Requirements: delivery bag collected and code gate unlocked

Behavior:

- Incomplete: Louis says the exit is locked and lists missing requirements.
- Complete: Louis unlocks/allows exit and completes the return-to-Louis objective.
- Louis remains on map and is not collectible.

## Delivery Bag

- Node: `GameplayRoot/GeneratedRuntimeInteractables/DeliveryBagObjective`
- Position: `Vector2(16672, 336)`
- Bag room cell: `[260, 20]`

Behavior:

- Visible token and label
- Interactable with E/Q bridge
- Updates `Phase0JMissionStateAdapter` as `objective_bag`
- Updates `Phase0JObjectiveAdapter`
- Updates `QuestManager`
- Updates `Phase0KMissionCompletionController`
- Repeated interaction does not double-count

Runtime validation: `objective_bag` count became `1` after collection.

## Cameras

`Phase0KCameraSpawner` scans `GameplayRoot/MarkerRoot/EditorOnlyPlaceholders` for CAM markers and spawns active `MissionSecurityCamera` nodes under `GameplayRoot/Phase0KRuntime/Cameras`.

- CAM markers found: `6`
- Phase0K cameras spawned: `6`
- Runtime camera nodes total: `8` including pre-existing fallback cameras
- Visible cone polygons: yes in debug runtime
- Sweep/detection: provided by `MissionSecurityCamera`

## Guards

`Phase0KGuardSpawner` scans GUARD markers and spawns simple active `Phase0KGuardPatrol` CharacterBody2D tokens under `GameplayRoot/Phase0KRuntime/Guards`.

- GUARD markers found: `7`
- Phase0K guards spawned: `7`
- Patrol assignment: 4 points per guard, using nearest PATROL markers or local fallback
- Guards are active runtime nodes and move through patrol points.

## Bounds Cleanup

Status: **PARTIAL_AUDIT_ONLY**

Louis and the delivery bag were placed at reported mission exit / bag room positions, and runtime cameras/guards spawn from CAM/GUARD marker positions. I did not perform a destructive marker-tile cleanup or full floor flood-fill relocation in this pass. Moved markers: `0`. Hidden markers: `0`.

Remaining risk: optional/debug markers outside the walkable area may still exist. A dedicated 0K-bounds-only pass should decode/flood-fill `FloorLayer`, classify every marker tile/node, and move or hide only confirmed invalid nodes without touching wall/floor tiles.

## Validation

- Duplicate scene loads: PASS
- Source scene unchanged: PASS
- Wall collision count: PASS, `2368`
- QuestManager getters exist: PASS
- Objective data source non-empty after interaction: PASS
- Bentley key 3 safe fetch call: PASS
- Code UI options/no hint/wrong/correct: PASS
- Louis token exists and exit logic works through controller: PASS
- Delivery bag exists and updates state: PASS
- Active cameras spawned: PASS
- Active guards spawned: PASS
- Counts monotonic regression: PASS
- Red HUD text preserved: PASS
- Purple runtime labels preserved: PASS, `188`

## Files Changed

- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `res://src/autoload/QuestManager.gd`
- `res://src/player/DogCompanion.gd`
- `res://src/missions/iso/runtime/Phase0JObjectiveAdapter.gd`
- `res://src/missions/iso/runtime/Phase0JCodeInputUI.gd`
- `res://src/missions/iso/runtime/Phase0JCodeGateController.gd`
- `res://src/missions/iso/runtime/Phase0KMissionCompletionController.gd`
- `res://src/missions/iso/runtime/Phase0KLouisExitInteractable.gd`
- `res://src/missions/iso/runtime/Phase0KBagObjectiveInteractable.gd`
- `res://src/missions/iso/runtime/Phase0KCameraSpawner.gd`
- `res://src/missions/iso/runtime/Phase0KGuardSpawner.gd`
- `res://src/missions/iso/runtime/Phase0KGuardPatrol.gd`
- `res://src/tools/editor/TacoBellPhase0KPlayableMissionLoopRepair.gd`
- `res://docs/reports/taco_bell_phase_0k_playable_mission_loop_repair.md`
- `res://docs/reports/taco_bell_phase_0k_playable_mission_loop_repair.json`

## Manual Playtest Checklist

1. Run `TacoBellIso_Editable_RedesignTest.tscn`.
2. Confirm walls still work.
3. Confirm no obvious required/interactable markers are outside the playable map.
4. Confirm red HUD/debug text is still readable.
5. Press key 3 / Bentley action.
6. Confirm no crash.
7. Go to code gate.
8. Confirm at least three code options appear.
9. Confirm the UI does not tell you which option is correct.
10. Choose/type wrong code and confirm wrong-code feedback.
11. Choose/type `0420` and confirm gate unlocks.
12. Go to bag room.
13. Find visible delivery bag.
14. Press E on delivery bag.
15. Confirm delivery bag objective updates.
16. Open pause menu Objectives submenu.
17. Confirm objective appears or updates.
18. Find Louis token at exit.
19. Press E on Louis before completing requirements.
20. Confirm Louis says exit is locked and lists what is missing.
21. Complete required bag/gate/objectives.
22. Press E on Louis again.
23. Confirm Louis allows exit or mission completion.
24. Walk near CAM marker areas.
25. Confirm active camera cones sweep/search.
26. Walk near GUARD marker areas.
27. Confirm guards are present and patrol.
28. Confirm counts still do not subtract incorrectly.
29. Confirm repeated interactions do not crash.
30. Confirm purple marker labels remain readable and do not block movement.
