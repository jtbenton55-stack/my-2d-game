# Taco Bell Phase 0J-C2 Interaction Repair

Status: PASS

0J-C2 repairs the manual playtest failures from 0J-C without touching the source scene, global systems, map tiles, or 0J-B2 wall collision.

## Protection
- Source scene unchanged: yes (`6E4E9A790D257126B6F8A17587BACAF6` before/after).
- Duplicate backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0jc2_backup.20260506_084905.tscn`.
- Duplicate hash before/after: `407C60AB26E56B9031C29C3BEE331232` -> `5A836AE95A9E28A2CF2FA4C36F6619EE`.
- Wall helper unchanged: `Phase0JB2WallCellCollisionGenerator.gd` stayed `3AC4BE6FB31F7234407EAA4CA5712866`.
- Wall collision shape count before/after: `2368` / `2368`.
- Map regenerated/repainted: no.

## Runtime Helpers
- `GameplayRoot/RuntimeHelpers/Phase0JInteractionBridge`
- `GameplayRoot/RuntimeHelpers/Phase0JDebugHUD`
- `GameplayRoot/RuntimeHelpers/Phase0JCodeGateController`
- `GameplayRoot/RuntimeHelpers/Phase0JCodeInputUI`

The bridge handles `E/interact` and `Q/case_the_joint`, uses distance search with a `144 px` radius, searches `phase0j_interactable`, `phase0j_marker_debug`, and Phase0J-generated `interactable` nodes, and has a `0.20 s` cooldown.

## Marker Coverage
- Collectible interactables: `49`
- Non-collectible/debug inspectables: `139`
- Runtime labels: `188`
- Runtime icons: `188`
- Uncovered markers: none

Every collectible keeps its runtime interactable and now reports visible HUD feedback. Every non-collectible/debug marker gets a temporary inspectable node and a runtime label/icon. Final guard, camera, route, switch, door, and exit mechanics remain deferred.

## Code Input UI
- Temporary code: `0420`
- `SAFE_CODE_INPUT_ZONE` has a runtime label showing the temporary code.
- Interacting opens `Phase0JCodeInputUI`.
- Wrong code returns visible `"Wrong code"` feedback and keeps the UI open.
- Correct code calls `Phase0JCodeGateController.unlock_gate()`, disables `BLOCK_code_gate` collision, closes the UI, and updates HUD gate state.
- Fresh scene reload starts locked again.

## Validation
- Godot `read_scene` loaded the duplicate after fixing the 0J-C2 label script parser issue.
- Godot `run_project` launched the duplicate scene.
- Runtime eval confirmed helpers, labels, and 49 collectible interactables exist.
- Bridge proximity simulation confirmed representative collectible and debug markers are found by distance.
- Code UI validation confirmed wrong-code and correct-code behavior through the runtime UI/controller path.
- Fresh run confirmed the gate starts locked again.

Representative bridge samples: `SAFE_CODE_INPUT_ZONE`, `OBJ_bag_recovery`, `BAG_dog_station`, `poop_bag_garage_pet_bin`, `CLUE_security_memo`, `PHOTO_dog_station`, `GLOW_market_shop`, `TINY_market_corner`, `ROUTE_IN_louis_service_door`, `VENT_IN_bentley_A_market_grate`, `GUARD_market_patrol_01`, `PATROL_market_01_A`, `CAM_market_01`, `BENTLEY_SWITCH_outdoor_floodlight_breaker`, and `GATE_garage_code`.

## Explicitly Not Changed
- `res://scenes/missions_iso/TacoBellIso_Editable.tscn`
- 0J-B2 wall collision
- map tile layers
- `Player.gd`
- guards/combat
- camera detection mechanics
- Bentley/Louis routes
- global systems

## Manual Playtest Checklist
1. Run `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
2. Confirm walls still work.
3. Confirm runtime marker labels/icons are visible immediately during play.
4. Walk to several marker categories and confirm each is readable: collectible, clue, route, vent, guard, camera/flood/alarm, switch, door, exit, code gate.
5. Press E near a collectible.
6. Confirm visible HUD/toast feedback and visual state change.
7. Press Q near a collectible.
8. Confirm visible HUD/toast feedback or debug interaction.
9. Press E/Q near a non-collectible marker: route, vent, guard, camera, switch, door.
10. Confirm the marker shows ID/category/deferred mechanic message.
11. Go to `SAFE_CODE_INPUT_ZONE`.
12. Confirm label shows temporary code.
13. Press E or Q.
14. Confirm code input UI opens.
15. Enter wrong code.
16. Confirm wrong-code feedback.
17. Enter correct code.
18. Confirm gate unlock message.
19. Walk through the gate.
20. Reload scene.
21. Confirm gate starts locked again.
22. Confirm runtime labels/icons do not block movement.
23. Confirm repeated interaction does not crash.
24. Confirm no marker is unidentifiable.

## Warnings
- MCP runtime logs contain pre-existing project warnings unrelated to 0J-C2.
- `EXIT_mission_return_to_louis` proximity exact-node simulation was overlapped by nearby priority; the bridge still found a Phase0J marker and the exit marker has its own debug inspectable and label.
- An untracked `mcp_interaction_server.gd` appeared after MCP `run_project`; it was not part of the intended 0J-C2 source edits.
