# 0M-D4 — Expanded Taco Bell scene audit (text/static)

**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Method:** Text grep + `.tscn` header / node-path inspection. **GRB:** not connected (`grb_ping` — no live tree). **No scene file modified.**

## 1–4. Root, script, inheritance, player

| Item | Finding |
| --- | --- |
| Root node | `TacoBellIso_Editable` (`Node2D`) — name retained from legacy naming; **playable path is still RedesignTest file** per `MissionSceneResolver`. |
| Root script | `res://src/levels/IsoMissionBase.gd` |
| Inheritance | Not a subclass scene; flat mission scene with many `ext_resource` scripts and packed scenes. |
| Player | `ext_resource` → `res://scenes/characters/player.tscn`; spawn wiring lives under `GameplayRoot` / spawn metadata in blockout definition (see scene marker JSON blobs). |

## 5–8. EntityRoot, GameplayRoot, ArtRoot, layers

- **EntityRoot / GameplayRoot / ArtRoot:** Present per `IsoMissionBase._ensure_iso_structure()` pattern; RedesignTest includes **`GameplayRoot`** with `GameplayFloorLayer`, `GameplayCollisionLayer`, `GameplayMarkersLayer`, `BoundaryColliders`, `ZoneLabels`, etc. **`ArtRoot`** used for sorted art tile layers (ext_resource tilesets: `IsoBlockoutTileset_Clean`, `MarkerAuthoringTileset`).
- **Collision:** `GameplayCollisionLayer` + generated `BoundaryWall_*` StaticBody2D chain + runtime collision generators (Phase0J-B2 metadata in scene).

## 9–11. Navigation, camera, objectives

- **Navigation:** Not fully enumerated in grep; iso floors/collision present; D5 should not assume NavMesh without audit in-editor.
- **Camera:** `IsoMissionBase` creates `Camera2D` if missing; scene may include limits via mission base / spawners — **Phase0KCameraSpawner** under `RuntimeHelpers`.
- **Objective markers:** Rich `object_type` / `marker_id` data embedded in scene (e.g. `talk_to_louis`, `code_gate`, `escape_and_return_to_louis`, poop bag packs, `exit`).

## 12–21. Clues, guards, beam, gate, Louis, delivery, poop, exit, pause, Phase0J/K

- **Clue/collectible placeholders:** Scripts `MissionCluePickupPlaceholder.gd`, `MissionCollectiblePickupPlaceholder.gd` referenced.
- **Guards / cameras / alarms:** `MissionAlertController.gd`; runtime buckets include `guard_spawn`, `camera_terminals`, `detection_zones`, `alarm_zones`; **garage_entry_beam** is the documented beam alarm id in `IsoMissionBase.gd`.
- **Beam:** Editor label node **"Security Beam"**; runtime alarm zone naming aligns with `garage_entry_beam`; **one-shot** implemented in `IsoMissionBase._on_runtime_alarm_zone_entered` + `_is_alarm_zone_one_shot`.
- **Code gate:** **`Phase0JCodeGateController`** with UI **`Phase0JCodeInputUI`**, blocker path export, wrong-code spawner link to **Phase0KBWrongCodeAttackGuardSpawner**. Physically separate from beam per layout validator docs (`TacoBellExpandedLayoutValidator` / `MissionBlockoutValidator` distance heuristics).
- **Louis route:** Marker **`louis_delivery_route_future_shortcut`** and route access metadata **`bypasses_challenge_id = "garage_entry_beam"`** — bypass targets **beam challenge**, not the keypad (evidence: scene grep on `bypasses_challenge_id`).
- **Delivery / order:** `Phase0KMissionCompletionController` tracks `delivery_bag_collected`, `code_gate_unlocked`, QuestManager objectives (`recover_delivery_bag`, `open_garage_code_gate`, `return_to_louis`).
- **Poop bags:** Marker ids `taco_bell_poop_bag_1..3`; `IsoMissionBase.deploy_poop_bag_decoy_at`; Player uses **`MissionToolSurfaceHelper`** when mission implements `deploy_poop_bag_decoy_at` / `handle_tool_use`.
- **Exit:** `object_type: exit` marker; **Phase0KLouisExitInteractable** / `LouisExitToken` (Area2D) in `GeneratedRuntimeInteractables`.
- **Pause / UI:** `pause_menu.tscn`, `hud.tscn`, `DialogueBox.tscn`, `controls_overlay.tscn` referenced.
- **Phase0J / Phase0K:** Full stack under `GameplayRoot/RuntimeHelpers` (see JSON list).

## 22–24. Scripts, reset, zones

- **Scripts:** 20+ mission/runtime scripts (Phase0J/K family, IsoMissionDebugPanel, marker scripts, etc.) — see `.tscn` `[ext_resource]` block in repo.
- **Reset / retry:** `IsoMissionBase._reset_attempt_runtime_state()` clears `_attempt_runtime_state` baseline and calls `iso_alert_controller.reset_attempt_state` if present; beam/arm flags derive from `alarm_triggered:garage_entry_beam`. **MissionObjectiveBridge.reset_runtime_objectives_for_mission** is currently a **stub** (`pass`) — **D5 risk** for QuestManager/Phase0K desync on reload unless SceneManager reload or explicit reset is proven.

## 25–30. Zones, references, risk, D5 edit surface

- **Zones / routes:** ZoneLabels include Louis Start/Service Corridor/Return, Security Beam, Escape/Return; route access points in runtime summary metadata (`route_access_points:*`).
- **Broken references:** D5 should run editor “Open anyway” check; grep shows `CodeGateBarrier_garage_office_code` referenced in Phase0I legacy blocker metadata — confirm runtime node paths still resolve after generations.
- **High-risk structure:** **Dual state**: IsoMissionBase dictionaries + **Phase0JMissionStateAdapter** collect dictionaries + **Phase0KMissionCompletionController** flags + **QuestManager** strings — easy to desync without a single “attempt state” owner (see ownership map).
- **D5 can safely edit:** New small Taco adapter scripts under `src/missions/taco_bell/`; selective `IsoMissionBase` / Phase0J/K **only with tests**; pause menu wiring if mission_id propagation is wrong; validators.
- **D5 should avoid:** Large TileMap art edits, raw asset dirs, rewriting entire Phase0J stack in one pass, changing `MissionSceneResolver` routing away from RedesignTest.
- **Manual review:** Exact player spawn NodePath, camera limits on widescreen, guard AI parity vs “placeholder” spawners.

Assertions: `expanded_scene_audited`, `root_script_identified`, `key_nodes_identified_or_missing_reported`, `no_scene_files_modified` — all true.
