# Taco Bell Iso — Generated Map Room Guide

Source manifest: `res://assets/missions/layouts/taco_bell_expanded_layout_v6.json`.
All x/y are anchor-relative (anchor = `player_spawn_main`).

Status legend:
- **REAL** — interactable runtime gameplay (real_existing or Phase 0I-promoted)
- **EDITOR-ONLY** — authoring placeholder, deferred mechanic
- **TILE-ONLY** — only the marker tile is painted, no runtime node
- **BENTLEY** — Bentley utility / vent route only (not for player walktest yet)
- **LOUIS** — Louis delivery shortcut (deferred mechanic)

## Louis Start / Player Spawn

- **Approx cell range (x):** -2 .. 9
- **What player should do:** Player + Bentley spawn. Talk to Louis (briefing objective). Mission start.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `player_spawn_main` | (2, 1) | REAL |  |
| `bentley_spawn_main` | (5, 2) | REAL |  |
| `OBJ_start_briefing` | (7, 2) | REAL |  |
| `HELP_start_controls` | (8, 6) | EDITOR-ONLY |  |

## Optional Market Nook

- **Approx cell range (x):** -8 .. 6
- **What player should do:** Quiet rain-soaked alcove south of spawn. Hidden Polaroid pickup.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `PHOTO_optional_market_nook` | (1, 24) | REAL (Phase 0I promoted) |  |

## Midnight Market Street

- **Approx cell range (x):** 10 .. 45
- **What player should do:** Walk east past closed shops. Inspect the receipt/sauce packets.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `OBJ_market_investigation` | (38, 1) | REAL |  |
| `PATROL_market_01_A` | (22, 4) | EDITOR-ONLY |  |
| `GLOW_market_shop` | (45, -16) | EDITOR-ONLY |  |

## North Shop Row + Dog Station Alley

- **Approx cell range (x):** 25 .. 75
- **What player should do:** North spur. Dog station and trash alley scent fakes (Bentley sniff training).

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `SCENT_FAKE_dog_station` | (37, -35) | EDITOR-ONLY |  |
| `BAG_dog_station` | (39, -47) | REAL |  |
| `PHOTO_dog_station` | (32, -48) | EDITOR-ONLY |  |
| `FLOOD_dog_station` | (42, -41) | EDITOR-ONLY |  |

## Trash Alley

- **Approx cell range (x):** 45 .. 65
- **What player should do:** North-side trash alley. Fake scent. Sterling clue token.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `SCENT_FAKE_trash_alley` | (72, -27) | REAL |  |
| `CLUE_sterling_delivery_token` | (77, -39) | REAL |  |

## Loading Dock Lane

- **Approx cell range (x):** 40 .. 70
- **What player should do:** South-side loading dock fake scent + bag pickup. Poop-bag decoy lane.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `SCENT_FAKE_loading_dock` | (66, 26) | REAL |  |
| `BAG_loading_dock` | (61, 43) | REAL |  |
| `FLOOD_loading_dock` | (58, 31) | EDITOR-ONLY |  |

## Delivery Alley Hub (Scent Decision)

- **Approx cell range (x):** 65 .. 95
- **What player should do:** Three scent trails converge. Bentley confirms the real one (parking garage).

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `SCENT_PATH_hub_center` | (90, 7) | EDITOR-ONLY |  |
| `OBJ_scent_decision` | (91, 7) | EDITOR-ONLY |  |
| `HELP_scent_tutorial` | (88, 4) | EDITOR-ONLY |  |

## Garage Entry Approach

- **Approx cell range (x):** 95 .. 130
- **What player should do:** Real scent leads east toward the parking garage entry.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `SCENT_REAL_garage_approach` | (104, 6) | REAL |  |
| `scent_real_parking_garage_02` | (113, 6) | REAL |  |
| `scent_real_parking_garage_03` | (121, 5) | REAL |  |

## Security Kiosk / Control Room

- **Approx cell range (x):** 110 .. 145
- **What player should do:** Camera/alarm/door control switches (deferred mechanics).

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `CONTROL_camera_terminal` | (134, -27) | EDITOR-ONLY (deferred) |  |
| `CONTROL_alarm_panel` | (129, -27) | EDITOR-ONLY (deferred) |  |
| `CONTROL_door_controls` | (141, -22) | EDITOR-ONLY (deferred) |  |

## Safe Code Input Pocket

- **Approx cell range (x):** 110 .. 130
- **What player should do:** SAFE pocket where player will eventually enter the gate code.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `SAFE_CODE_INPUT_ZONE` | (136, 3) | EDITOR-ONLY (deferred) | TIER 3 in this pass; SWITCH tile only; mechanic deferred. |
| `HELP_code_gate` | (133, 1) | EDITOR-ONLY |  |

## Garage Office / Code Clue Room

- **Approx cell range (x):** 125 .. 145
- **What player should do:** Velvet Paw stamp + delivery receipt clues for the gate code.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `CLUE_velvet_paw_stamp` | (137, 24) | REAL |  |
| `CLUE_sauce_packet` | (137, -24) | REAL |  |
| `CLUE_camera_schedule` | (132, -29) | EDITOR-ONLY |  |
| `CLUE_delivery_receipt` | (90, 16) | EDITOR-ONLY |  |

## Code Gate Chokepoint

- **Approx cell range (x):** 145 .. 155
- **What player should do:** GATE marker tile + BLOCK_code_gate runtime collider. Future code mechanic removes the blocker.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `GATE_garage_code` | (149, 3) | REAL |  |
| `BLOCK_code_gate` | (150, 3) | REAL (Phase 0I generated blocker) | physical blocker; CollisionBarrierLayer also receives a tile here. Future code-entry mechanic removes this collision tile to unlock the gate. |
| `OBJ_code_gate` | (141, 3) | REAL |  |

## Post-Gate Buffer

- **Approx cell range (x):** 150 .. 175
- **What player should do:** Service corridor after the gate. Louis route returns into this buffer.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `BAG_louis_service_corridor` | (150, 40) | REAL (Phase 0I promoted) |  |
| `ROUTE_DEST_louis_return_destination` | (168, 11) | REAL · LOUIS |  |

## Louis Service Corridor (Shortcut Return)

- **Approx cell range (x):** 60 .. 175
- **What player should do:** Louis delivery shortcut bypasses the code gate but returns BEFORE the security beam, so player still does the bag objective.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `ROUTE_IN_louis_service_door` | (99, 28) | EDITOR-ONLY (deferred) · LOUIS | DOOR tile only; mechanic deferred to a future pass. |
| `ROUTE_RET_louis_return_trigger` | (171, 22) | EDITOR-ONLY (deferred) · LOUIS | DOOR tile only; mechanic deferred. |
| `ROUTE_DEST_louis_return_destination` | (168, 11) | REAL · LOUIS |  |

## Security Beam Approach

- **Approx cell range (x):** 170 .. 195
- **What player should do:** Ambush trigger zone. Player must avoid alarm escalation.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `AMBUSH_security_beam` | (181, 14) | REAL |  |
| `OBJ_security_beam` | (181, 14) | REAL |  |
| `ALARM_beam_escalation` | (181, 9) | REAL |  |

## Garage Floor 1

- **Approx cell range (x):** 195 .. 230
- **What player should do:** Open garage floor. Patrols, cameras, interactables.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `GUARD_garage_patrol_01` | (201, 15) | REAL |  |
| `PATROL_garage_01_A` | (190, 5) | REAL |  |
| `PATROL_garage_01_B` | (228, 5) | REAL |  |
| `PATROL_garage_01_C` | (228, 31) | REAL |  |
| `CAM_garage_lower` | (232, 35) | EDITOR-ONLY |  |
| `poop_bag_garage_pet_bin` | (199, 30) | REAL (Phase 0I promoted) | MUST not be inside blocking collision; validator hard-asserts. |

## Upper Platform / Control Alcove

- **Approx cell range (x):** 225 .. 250
- **What player should do:** Upper alcove with perfect-Polaroid + ambient cameras.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `PHOTO_upper_platform` | (231, -22) | REAL |  |
| `CAM_garage_upper` | (190, 2) | EDITOR-ONLY |  |
| `CAM_upper_high_heat` | (220, -18) | EDITOR-ONLY |  |

## Bag Recovery Room

- **Approx cell range (x):** 235 .. 270
- **What player should do:** Mission objective destination: recover the delivery bag.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `OBJ_bag_recovery` | (260, 20) | REAL (Phase 0I promoted) |  |
| `CAM_bag_room` | (247, 7) | EDITOR-ONLY |  |
| `GLOW_bag_room` | (265, 30) | REAL |  |
| `TINY_loading_dock` | (84, 44) | REAL |  |

## South Return Corridor

- **Approx cell range (x):** -10 .. 130
- **What player should do:** After the bag pickup, head south then west to escape.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `BAG_south_return` | (112, 53) | EDITOR-ONLY |  |
| `OBJ_return_to_louis` | (12, 52) | REAL |  |

## Mission Exit

- **Approx cell range (x):** -15 .. 5
- **What player should do:** Return-to-Louis exit trigger. Mission ends.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `EXIT_mission_return_to_louis` | (12, 52) | REAL |  |

## Bentley Utility Routes A/B/C/D

- **Approx cell range (x):** -30 .. 270
- **What player should do:** Bentley-only vent shortcuts (deferred). Disabled for player walktest by Phase0IRouteSafeguard.

| Manifest ID | Cell | Status | Notes |
|---|---|---|---|
| `VENT_IN_bentley_A_market_grate` | (48, 18) | EDITOR-ONLY · BENTLEY |  |
| `VENT_IN_bentley_B_loading_dock_sewer` | (84, 45) | EDITOR-ONLY · BENTLEY |  |
| `VENT_IN_bentley_C_post_gate_duct` | (166, -9) | EDITOR-ONLY · BENTLEY |  |
| `VENT_IN_bentley_D_south_corridor` | (172, 62) | EDITOR-ONLY · BENTLEY |  |
| `VENT_OUT_bentley_A_utility_pocket` | (90, 21) | EDITOR-ONLY · BENTLEY |  |
| `VENT_OUT_bentley_B_alarm_utility` | (143, 45) | EDITOR-ONLY · BENTLEY |  |
| `VENT_OUT_bentley_C_upper_utility` | (216, -45) | EDITOR-ONLY · BENTLEY |  |
| `VENT_OUT_bentley_D_exit_utility` | (225, 65) | EDITOR-ONLY · BENTLEY |  |
| `BENTLEY_SWITCH_alarm_override` | (146, 45) | EDITOR-ONLY (deferred) · BENTLEY | SWITCH tile only; mechanic deferred. |
| `BENTLEY_SWITCH_camera_shutoff` | (224, -44) | EDITOR-ONLY (deferred) · BENTLEY | SWITCH tile only; mechanic deferred. |
| `BENTLEY_SWITCH_door_release` | (219, -44) | EDITOR-ONLY (deferred) · BENTLEY | SWITCH tile only; mechanic deferred. |
| `BENTLEY_SWITCH_exit_release` | (229, 64) | EDITOR-ONLY (deferred) · BENTLEY | SWITCH tile only; not a primary exit; mechanic deferred. |
| `BENTLEY_SWITCH_outdoor_floodlight_breaker` | (94, 23) | EDITOR-ONLY (deferred) · BENTLEY | SWITCH tile only; mechanic deferred. |

## Walls and collision

- `WallLayer` is the primary wall collision (`collision_enabled = true` after Phase 0I, TileSet `physics_layer_0` -> Walls = layer 3).
- `CollisionBarrierLayer` carries deliberate blocker tiles only (vents, gate-adjacent cells), `collision_enabled = false` (we use a dedicated StaticBody2D for the gate so it can be cleanly removed by future unlock mechanics).
- `GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate` is the runtime gate blocker (`collision_layer = 4` = Walls).

## Authoring vs gameplay visuals

- `MarkerTileLayer` and `EditorOnlyPlaceholders` are visible in the editor for authoring, but hidden at runtime by `Phase0IAuthoringHider`.
- `MarkerRoot/{Spawns,Routes,Transitions,Objectives,...}` are also hidden at runtime (authoring debug only).
- `FloorLayer`, `WallLayer`, `CoverLayer` remain visible at runtime as gameplay tiles.

## Bentley vs Louis vs player walktest

- Player can walk the full main path: spawn -> market -> hub -> garage approach -> safe pocket -> code gate -> post-gate buffer -> beam -> garage -> bag room -> south corridor -> exit.
- Louis delivery shortcut bypasses the code gate but rejoins BEFORE the security beam (so the player still does the bag objective and exit).
- Bentley vents are NOT player-traversable yet. `Phase0IRouteSafeguard` disables player teleport on `Transition_route_vent_return` and `Transition_route_louis_return`.