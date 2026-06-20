# Security Authorables Guide

This guide documents the **D6-08A foundation** for drag-and-drop security authoring in isometric missions. It complements the collectible guide: [AUTHORABLE_NODES_GUIDE.md](AUTHORABLE_NODES_GUIDE.md).

## Current status (D6-08A)

| Layer | Status |
|-------|--------|
| Audit + taxonomy | Done |
| Drag/drop templates (READY types) | Done |
| Static validator | Done |
| Full mission-agnostic runtime bridge | Partial — Taco `taco_bell_drop` only today |
| Idle guard placement author | Not implemented |
| Alarm group author node | Not implemented |
| Production door/keypad author | Audit only |

**Templates are foundation-only.** They use existing author scripts that already wire into `MissionAuthoringRuntimeBuilder` on Taco. Placing a template in another mission does **not** auto-enable runtime until that mission calls the same setup path.

## Taco security scene structure

Path: `GameplayRoot/SecurityAuthoringRoot` (`SecurityAuthoringRoot.gd`)

| Child (examples) | Script | Runtime role |
|------------------|--------|----------------|
| `AMBUSH_security_beam` | `SecurityBeamAuthor` | Ambush beam geometry + `ambush_beam_tripped` event |
| `AmbushGuardSpawn_Author` | `GuardSpawnAuthor` | Spawns guards on beam trip |
| `TestCamera_Author` | `SecurityCameraAuthor` | Authored camera → `EntityRoot/Cameras` |
| `CameraAlarmGuardSpawn_Author` | `GuardSpawnAuthor` | Spawns on `test_camera_alarm` |
| `AmbushTestPatrol` | `GuardPatrolRouteAuthor` | Waypoints for patrol behavior |
| `TestAreaGuardTrigger_Author` | `AreaTriggerAuthor` | Area → security event |
| `*Effect*_Author` | Effect authors | Downstream lockdown/objective/door |
| `CollectibleAuthoringProof` | Collectible authors | D6-06/07 (separate pipeline) |

Legacy parallel systems (do not duplicate in new work):

- `GameplayRoot/MarkerRoot` — JSON/marker-driven spawns (e.g. `garage_floor_1_guard_placeholder` via Phase0K)
- `RuntimeHelpers/Phase0KGuardSpawner` — mission-specific guard spawn helpers

## Taxonomy

| Authorable type | Status | Required IDs | Runtime source |
|-----------------|--------|--------------|------------------|
| Security beam | **READY** | `beam_id`, `on_trip_event` | `SecurityBeamAuthor.build_runtime_config` + ambush setup |
| Ambush beam | **READY** (same script) | Same; default event `ambush_beam_tripped` | Same |
| Security camera | **READY** | `camera_id`, `on_alarm_event` | `SecurityCameraAuthor.setup_runtime_camera` |
| Guard spawn (event) | **READY** | `spawn_id`, `trigger_events[]` | `GuardSpawnAuthor` + `SecurityEventRouter` |
| Patrol route | **READY** | `route_id` + ≥2 `Waypoint*` children | `GuardPatrolRouteAuthor.get_patrol_points_global` |
| Patrol waypoint | **READY** (structural) | None — child `Node2D` under route | Included in route points |
| Area trigger | **READY** | `trigger_id`, `on_enter_event` | `AreaTriggerAuthor.setup_runtime_trigger` |
| Security effects | **READY** | `effect_id`, `trigger_events[]`, `EffectSet` | `SecurityEffectAuthorBase` subclasses, including `SecurityEffectSetAuthor` |
| Alarm group | **NEEDS BRIDGE** | Event string names today (`alarm_id`, `on_alarm_event`) | No dedicated author node |
| Idle / placed guard | **NEEDS BRIDGE** | N/A | `Phase0KGuardSpawner` / markers |
| Door / keypad | **AUDIT ONLY** | `DoorLockEffectAuthor` for proof effects | Mission gate APIs, not full keypad UI |
| Old marker-only security | **OBSOLETE** for new authoring | marker JSON IDs | Do not revive for new features |

## Templates

Folder:

```text
scenes/missions_iso/security_authoring_templates/
```

| Template | Script | Placeholder IDs |
|----------|--------|-----------------|
| `SecurityBeamAuthorTemplate.tscn` | `SecurityBeamAuthor` | `CHANGE_ME_BEAM_ID`, event |
| `AmbushBeamAuthorTemplate.tscn` | `SecurityBeamAuthor` | beam id; preset `ambush_beam_tripped` |
| `SecurityCameraAuthorTemplate.tscn` | `SecurityCameraAuthor` | `CHANGE_ME_CAMERA_ID`, alarm event |
| `GuardSpawnAuthorTemplate.tscn` | `GuardSpawnAuthor` | `CHANGE_ME_SPAWN_ID`, trigger event |
| `GuardPatrolRouteAuthorTemplate.tscn` | `GuardPatrolRouteAuthor` | `CHANGE_ME_ROUTE_ID` + 2 waypoints |
| `PatrolWaypointTemplate.tscn` | plain `Node2D` | Rename `WaypointN` under a route |
| `AreaTriggerAuthorTemplate.tscn` | `AreaTriggerAuthor` | trigger + enter event |
| `SecurityEffectSetAuthorTemplate.tscn` | `SecurityEffectSetAuthor` | trigger event + placeholder `EffectSet` |

**Deferred (no template — by design):**

- `GuardAuthorTemplate` (idle guard) — no author script yet
- `AlarmGroupAuthorTemplate` — use matching event strings on beams/cameras/spawns
- `DoorKeypadAuthorTemplate` — door/keypad flow still audit-only

## How to place security authorables

1. Open the mission scene (Taco proof: `TacoBellIso_Editable_RedesignTest.tscn`).
2. Drag a template under `GameplayRoot/SecurityAuthoringRoot` (not under `MarkerRoot`).
3. Set unique IDs and event names; wire `GuardSpawnAuthor.trigger_events` or `SecurityEffectSetAuthor.trigger_events` to beam/camera/area events.
4. For patrol spawns: set `patrol_route_id` on spawn author to match a route’s `route_id`.
5. Add `Waypoint0`, `Waypoint1`, … as children of patrol routes (or duplicate `PatrolWaypointTemplate`).
6. Run the static validator (below).
7. Play Taco, press **F10** — security authoring section shows beam/camera/spawn/patrol counts.
8. Press **F12** for the task-focused QA Review panel when manually testing Phase 4 security slices. Do not use F8; Godot Editor uses F8 to stop the running project.

### Phase 4E-4G-lite additions

- Authored cameras can set `sweep_readability_label`; runtime cameras expose sweep debug dictionaries and plain-English sweep lines for debug UI/tests.
- `HideSpotNodeTemplate.tscn` lives under `scenes/missions/iso/authoring/` because hide spots are regular plug-and-play mechanics, not children of `SecurityAuthoringRoot`.
- Taco has a minimal `SecurityEffectSetAuthor` proof node named `Phase4G_CameraAlarmEffectSet_Author`. It listens to `test_camera_alarm` and sets the mission flag `phase4g_camera_alarm_seen` through `EffectSet`.
- The Taco debug HUD now has an **F12 Mission QA Review** panel for manual testing. Select `Phase 4G - Camera Alarm EffectSet` to see exact paths, next action, live PASS/WAIT checks, and buttons for teleporting to the camera test position and resetting the Phase 4G flag.

## ID and linking rules

- **beam_id** — unique per beam author; often matches `alarm_id`.
- **on_trip_event** — must match a `GuardSpawnAuthor.trigger_events` entry or effect `trigger_events`.
- **camera_id** — unique; **on_alarm_event** links to spawns/effects.
- **spawn_id** — unique per spawn author (not per guard instance).
- **route_id** — unique; referenced by `GuardSpawnAuthor.patrol_route_id` when `initial_behavior` is `patrol`.
- **trigger_id** — unique per area trigger.
- Do not leave `CHANGE_ME_*` values in mission scenes.

## Multi-instance rules

- Multiple beams, cameras, spawns, routes, and area triggers are supported.
- Duplicate IDs in the same mission break routing and F10 diagnostics.
- One-shot beams/spawns use `one_shot` on the author.

## Testing

### Static validator

```powershell
python src/tools/editor/d6_08a_security_authorables/phase0md6_08a_security_authorable_validator.py
```

### Runtime (Taco smoke)

1. Run `TacoBellIso_Editable_RedesignTest.tscn`.
2. F10: `security` section — root found, beam/camera/spawn/patrol counts.
3. F12: select `Phase 4G - Camera Alarm EffectSet` for the task-focused manual checklist.
4. Trip ambush beam → guard spawn + event router activity.
5. Enter camera cone or use the F12 teleport button -> `test_camera_alarm` -> camera alarm spawn and `phase4g_camera_alarm_seen` flag.
6. No new red errors in Godot output.

## What is not implemented yet

- Mission-agnostic security authoring setup (today gated on `taco_bell_drop` in `IsoMissionBase`).
- Drag/drop **idle** guards (replacing Phase0K marker spawns).
- Dedicated **alarm group** author node.
- Full **door/keypad** authoring across missions.
- Production scene placement for `SecurityEffectSetAuthor` beyond the dev-room proof.
- Full hide-spot art pass, animation, and player-facing tutorialization.

## Planned phases

| Phase | Focus |
|-------|--------|
| **D6-08B** | Guard spawn + patrol route authoring hardening, idle guard bridge |
| **D6-08C** | Camera + beam authoring expansion, validator depth |
| **D6-08D** | Ambush + alarm/event graph authoring |
| **D6-08E** | Door/keypad authoring (if audit approves) |

## Related files

- `src/missions/iso/authoring/SecurityAuthoringRoot.gd`
- `src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd`
- `src/missions/iso/runtime/SecurityEventRouter.gd`
- `src/levels/IsoMissionBase.gd` — `_setup_d6_03_authoring_security_runtime`
- `docs/reports/d6_08a_security_authorables/D6_08A_SECURITY_AUTHORABLES_REPORT.md`
