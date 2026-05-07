# Taco Bell Phase 0K-B Remaining Playability Repair

Status: **PARTIAL**

0K-B fixes the specific manual-playtest blockers: the delivery bag is now on a real bag-room floor cell, CAM marker cameras now align with their markers and have cones, wrong code dispatches a hostile chase guard on the second failed attempt, and runtime debug-only markers outside floor cells are hidden. It is partial because a complete MarkerTileLayer/MarkerRoot flood-fill classification was not finished.

## Safety

- Backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0kb_backup.20260506_182357.tscn`
- Source hash before/after: `6E4E9A790D257126B6F8A17587BACAF6` / `6E4E9A790D257126B6F8A17587BACAF6`
- Duplicate hash before/after: `F23919BF00B39C2590C7C32CF44A2606` / `DC9753054F6B6F166C0E2571F500005D`
- Wall collision count before/after: `2368` / `2368`
- Map regenerated/repainted: no
- Shared scripts changed in 0K-B: none

## Delivery Bag Repair

Old placement:

- Node: `GameplayRoot/GeneratedRuntimeInteractables/DeliveryBagObjective`
- Old position: `Vector2(16672, 336)`
- Old cell: `(260, 20)`
- Floor check: no `FloorLayer` tile at that cell

New placement:

- New position: `Vector2(16032, 368)`
- New cell: `(250, 22)`
- Floor check: valid `FloorLayer` tile
- Bag room: `zone_bag_recovery_room`

Moved together:

- `GameplayRoot/GeneratedRuntimeInteractables/DeliveryBagObjective`
- `GameplayRoot/GeneratedRuntimeInteractables/Interactable_OBJ_bag_recovery`
- `GameplayRoot/GeneratedRuntimeMarkerLabels/Label_OBJ_bag_recovery`
- Legacy `EntityRoot/Interactables/Phase0IGeneratedCollectibles/OBJ_bag_recovery`

Runtime validation confirmed the bag is on floor, interaction succeeds, `objective_bag` becomes `1`, and QuestManager/objective/completion state updates.

## Camera Coverage

CAM markers found: `6`

- `CAM_bag_room`
- `CAM_garage_lower`
- `CAM_garage_upper`
- `CAM_market_01`
- `CAM_trash_alley`
- `CAM_upper_high_heat`

Fix: `Phase0KCameraSpawner` now parents each `MissionSecurityCamera` before assigning `global_position`. This keeps the camera cone at the CAM marker instead of shifting due to parent transforms.

Runtime validation:

- Active runtime cameras after: `8` total, including 2 pre-existing fallback cameras
- Phase0K-B CAM marker cameras: `6`
- Every Phase0K-B camera has a `Polygon2D` cone
- Cameras use `MissionSecurityCamera.gd` sweep/search behavior

## Wrong-Code Attack Guard

Wrong-code behavior now uses `Phase0KBWrongCodeAttackGuardSpawner`.

- Threshold: `2`
- First wrong code: increments attempt count and warns
- Second wrong code: spawns `WrongCodeAttackGuard_2`
- Guard metadata: `spawn_reason = wrong_code`, `hostile = true`
- Behavior: `Phase0KGuardPatrol` has `chase_player = true` for attack guards
- Infinite spawn prevention: max one dispatched wrong-code guard; later wrong codes report guard already dispatched

Runtime validation confirmed wrong attempts reached `2`, the second wrong code increased guard count from `7` to `8`, the spawned guard was hostile/chasing, and `0420` still unlocked the gate.

## Guards And Patrols

GUARD markers found: `7`

Fix: `Phase0KGuardSpawner` now parents guards before assigning `global_position`, matching the camera parenting fix.

Runtime validation:

- Patrol guards after: `7`
- Wrong-code guard after threshold: `1`
- Total after second wrong code: `8`
- All patrol guards had patrol points

## Bounds Cleanup

`Phase0KBBoundsCleanup` performs focused runtime cleanup:

- Moves required delivery-bag nodes to `(250, 22)` if they are not on floor
- Keeps Louis on floor at `(12, 52)`
- Hides debug-only labels/interactables that are off `FloorLayer`

Runtime result:

- Required moved by static scene patch: delivery bag nodes and label
- Runtime hidden debug-only nodes/labels: `65`
- Deferred full flood-fill cleanup: yes

Remaining risk: this did not decode every MarkerTileLayer cell or classify every MarkerRoot node with a full reachable-floor flood fill. Required interactables validated in this pass are on floor.

## Regression Checks

- Source scene unchanged: PASS
- Wall collision preserved: PASS
- Bag interaction/objective update: PASS
- CAM coverage/cones: PASS
- Wrong-code guard: PASS
- Correct `0420` unlock: PASS
- Bentley key 3 safety: preserved
- Objectives pause data source: still populates
- Counts monotonic: PASS
- Red HUD: PASS
- Purple labels: PASS, `188`

## Files Changed

- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `res://src/missions/iso/runtime/Phase0KCameraSpawner.gd`
- `res://src/missions/iso/runtime/Phase0KGuardSpawner.gd`
- `res://src/missions/iso/runtime/Phase0KGuardPatrol.gd`
- `res://src/missions/iso/runtime/Phase0KBWrongCodeAttackGuardSpawner.gd`
- `res://src/missions/iso/runtime/Phase0KBBoundsCleanup.gd`
- `res://src/missions/iso/runtime/Phase0JCodeInputUI.gd`
- `res://src/missions/iso/runtime/Phase0JCodeGateController.gd`
- `res://src/tools/editor/TacoBellPhase0KBRemainingPlayabilityRepair.gd`
- `res://docs/reports/taco_bell_phase_0kb_remaining_playability_repair.md`
- `res://docs/reports/taco_bell_phase_0kb_remaining_playability_repair.json`

## Manual Playtest Checklist

1. Run `TacoBellIso_Editable_RedesignTest.tscn`.
2. Confirm walls still work.
3. Confirm red HUD/debug text is still readable.
4. Confirm purple labels/icons still exist.
5. Press key 3 and confirm no crash.
6. Go to code gate.
7. Confirm three options appear and no hint reveals the correct answer.
8. Choose a wrong code once and confirm wrong-code feedback.
9. Choose a wrong code a second time and confirm attack guard spawns.
10. Confirm attack guard chases/attacks or visibly engages.
11. Enter/select `0420` and confirm gate unlocks.
12. Go to the bag room.
13. Confirm the delivery bag is inside the room, not outside the wall.
14. Press E on the delivery bag.
15. Confirm delivery bag objective/completion state updates.
16. Open pause menu Objectives submenu and confirm objective data still appears/updates.
17. Walk through camera areas.
18. Confirm every CAM marker area has a visible sweeping cone or has been removed/hidden/deferred.
19. Walk near guard/patrol areas.
20. Confirm guards are present and patrol.
21. Look around map edges.
22. Confirm no required/interactable markers are sitting outside the playable area.
23. Confirm counts do not subtract incorrectly.
24. Confirm repeated interactions do not crash.
