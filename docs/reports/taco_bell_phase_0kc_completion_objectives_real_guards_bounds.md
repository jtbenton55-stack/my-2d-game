# Taco Bell Phase 0K-C Completion, Objectives, Real Guards, Bounds

Status: **PARTIAL**

0K-C wires Louis into real mission completion, changes pause objectives into active/completed lists, replaces triangle/debug guard visuals with the requested real guard-style token, makes wrong-code guards hostile/chasing, and expands runtime cleanup of off-floor marker-like objects. It remains partial because bounds cleanup is runtime/FloorLayer based, not a persisted MarkerTileLayer rewrite or physics wall flood-fill.

## Safety

- Backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0kc_backup.20260506_195828.tscn`
- Source hash before/after: `6E4E9A790D257126B6F8A17587BACAF6` / `6E4E9A790D257126B6F8A17587BACAF6`
- Duplicate hash before/after: `80A8783662280451BACBFE857548197F` / `80A8783662280451BACBFE857548197F`
- Wall collision count before/after: `2368` / `2368`
- Map regenerated/repainted: no

## Mission Completion

Louis now calls `Phase0KMissionCompletionController.complete_mission_and_exit()` once requirements are met. That method:

- marks `exit_unlocked = true`
- marks `mission_completed = true`
- completes `return_to_louis`
- calls `GameState.complete_mission("taco_bell_drop")`
- calls `SceneManager.show_mission_result(result)`

Runtime validation confirmed incomplete Louis interaction blocks exit, while completed requirements set mission completion state and create a mission result for `taco_bell_drop`.

## Running Objectives

`QuestManager` now stores active objectives and completed objectives separately. The pause menu now renders:

- `Active Objectives`
- `Completed Objectives`

Validation sequence:

- Add A and B: both remain active.
- Complete A: A moves to completed, B remains active.
- Add C: B and C remain active, A remains completed.

## Real Guard Visuals And Behavior

`Phase0KGuardPatrol` now uses the requested guard visual style:

- `BlackBodyOutline`
- `RedBody`
- `WhiteCircleHead`
- `RedScanningCone`

Patrol guards still patrol. Wrong-code attack guards use the same script/visual style, set `hostile = true`, and set `chase_player = true`.

Runtime validation:

- Patrol guards: `7`
- All patrol guards had outline/head/cone visuals.
- Second wrong code spawned `WrongCodeAttackGuard_2`.
- Wrong-code guard used `Phase0KGuardPatrol.gd`, had real guard visuals, was hostile, and chased the player.
- `0420` still unlocked the gate.

## Bounds Cleanup

`Phase0KBBoundsCleanup` now audits generated interactables, labels, and debug interactables against `FloorLayer`.

Runtime validation:

- Floor cells counted: `18269`
- Runtime nodes audited: `378`
- Runtime nodes moved: `18`
- Runtime nodes hidden: `106`
- Required checked on floor: `DeliveryBagObjective`, `Interactable_OBJ_bag_recovery`, `LouisExitToken`

Remaining warning: MarkerTileLayer authoring cells and every MarkerRoot node still need a dedicated persisted bounds-only cleanup if you want the editor file itself to stop showing every outside marker tile. This pass hides/moves runtime-visible generated objects without touching floor/wall geometry.

## Regressions

- Delivery bag still on floor and interactable: PASS
- Camera cones preserved: PASS
- Bentley key 3 safe behavior preserved: PASS
- Red HUD/debug text preserved: PASS
- Counts still monotonic: PASS
- Purple labels preserved: PASS, `188`
- Source scene untouched: PASS
- Wall collision preserved: PASS

## Files Changed

- `res://src/autoload/QuestManager.gd`
- `res://src/ui/test_ui/pause_menu.gd`
- `res://src/missions/iso/runtime/Phase0KMissionCompletionController.gd`
- `res://src/missions/iso/runtime/Phase0KLouisExitInteractable.gd`
- `res://src/missions/iso/runtime/Phase0KGuardPatrol.gd`
- `res://src/missions/iso/runtime/Phase0KBBoundsCleanup.gd`
- `res://src/tools/editor/TacoBellPhase0KCCompletionObjectivesRealGuardsBounds.gd`
- `res://docs/reports/taco_bell_phase_0kc_completion_objectives_real_guards_bounds.md`
- `res://docs/reports/taco_bell_phase_0kc_completion_objectives_real_guards_bounds.json`
- `res://docs/reports/taco_bell_phase_0kc_marker_authoring_contract.md`

## Manual Playtest Checklist

1. Run `TacoBellIso_Editable_RedesignTest.tscn`.
2. Confirm walls still work.
3. Confirm red HUD/debug text still readable.
4. Confirm delivery bag is still in the bag room and interactable.
5. Pick up delivery bag.
6. Confirm delivery bag objective completes.
7. Open pause menu Objectives submenu.
8. Confirm “Recover the delivery bag” appears in completed objectives.
9. Interact with another objective.
10. Confirm previous objectives remain listed instead of disappearing.
11. Go to code gate.
12. Enter wrong code once.
13. Confirm warning/feedback but no fake label blocking movement.
14. Enter wrong code second time.
15. Confirm a real guard spawns, not a triangle or label.
16. Confirm the guard looks like the real guard style: black square/outline, white circle head, red body, red scanning triangle/cone.
17. Confirm the wrong-code guard attacks/chases or clearly engages.
18. Enter `0420` and confirm gate unlocks.
19. Complete delivery bag + code gate requirements.
20. Talk to Louis.
21. Confirm Louis triggers mission completion or enables an exit marker.
22. Interact with exit marker if present.
23. Confirm mission completion/exit behavior occurs or placeholder completion state is clear.
24. Walk near all guard/patrol areas.
25. Confirm guards look real and patrol/attack, not triangle placeholders.
26. Walk map edges.
27. Confirm no visible required/interactable labels/tokens are outside walkable floor/walls.
28. Confirm camera cones are preserved.
29. Press Bentley key 3 and confirm no crash.
30. Confirm counts do not subtract incorrectly.
