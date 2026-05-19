# D6-08A Security Authorables Foundation Report

**Phase:** 0M-D6-08A  
**Mission scope:** Taco Bell iso proof (`taco_bell_drop`) — audit + templates + validator  
**Result:** **PASS** (foundation; runtime already existed for READY types)

## Executive summary

Security authoring was already implemented across D6-02–D6-05. This pass **audited** Taco security, **classified** the taxonomy, added **drag/drop templates** for READY author types, added a **static validator**, and documented rollout. No broad rewrite of guard/camera/beam/alarm frameworks. Taco security smoke behavior preserved.

## Audit summary

### Scene structure (`TacoBellIso_Editable_RedesignTest.tscn`)

| Location | Contents |
|----------|----------|
| `GameplayRoot/SecurityAuthoringRoot` | Hand-placed security authors (source of truth for D6-03+) |
| `GameplayRoot/MarkerRoot` | Legacy JSON markers (guard spawn placeholders, ambush markers) |
| `GameplayRoot/RuntimeHelpers/Phase0K*` | Phase0K spawners (guards, cameras, completion) |
| `EntityRoot/Cameras` | Runtime cameras (authored + spawned) |

Authored vs generated:

- **Authored in scene:** beam, spawn, camera, patrol, area, effect authors under `SecurityAuthoringRoot`
- **Generated at runtime:** `AuthoredCamera_*`, `AreaTrigger_*`, ambush beam collision from beam author config, guards from spawn authors

### Scripts and runtime flow

```
SecurityAuthoringRoot (scene)
  → IsoMissionBase._setup_d6_03_authoring_security_runtime (taco_bell_drop)
  → MissionAuthoringRuntimeBuilder.setup
       → SecurityEventRouter
       → GuardSpawnAuthor.bind_mission + register_listener
       → AreaTriggerAuthor.setup_runtime_trigger
       → SecurityCameraAuthor.setup_runtime_camera
  → _setup_ambush_beam_from_security_beam_author (beam geometry)
```

### Collision / detection (unchanged)

- Beams: trigger size from author `build_runtime_config`
- Cameras: `MissionSecurityCamera.gd` on `Area2D`
- Area triggers: `Area2D`, `collision_mask = 1` (player)
- No layer changes in D6-08A

### F10 visibility (pre-existing)

`IsoMissionDebugPanel` authoring mode shows security root, beam/camera/spawn/patrol/area counts, router, ambush trips, camera alarm, guard spawn results, effect counts. **No F10 redesign in D6-08A.**

## Taxonomy table

| Type | Status | Notes |
|------|--------|-------|
| Security beam | READY | Template + runtime |
| Ambush beam | READY | Same script as beam |
| Security camera | READY | Template + `setup_runtime_camera` |
| Guard spawn (event) | READY | Not idle guard |
| Patrol route | READY | Waypoint children |
| Patrol waypoint | READY | Structural `Node2D` |
| Area trigger | READY | Template + runtime area |
| Security effects | NEEDS BRIDGE | Door/lockdown/objective/toggle |
| Alarm group | NEEDS BRIDGE | Event strings only |
| Idle guard | NEEDS BRIDGE | Phase0K / markers |
| Door / keypad | AUDIT ONLY | Proof `DoorLockEffectAuthor` only |
| Marker-only security | OBSOLETE | Do not extend |

## Files changed / added

### Added

- `docs/SECURITY_AUTHORABLES_GUIDE.md`
- `docs/reports/d6_08a_security_authorables/D6_08A_SECURITY_AUTHORABLES_REPORT.md`
- `docs/reports/d6_08a_security_authorables/phase0md6_08a_static_validator_run.json` (after validator run)
- `reports/ai/D6_08A_SECURITY_AUTHORABLES_REPORT.md`
- `scenes/missions_iso/security_authoring_templates/*.tscn` (7 templates)
- `src/tools/editor/d6_08a_security_authorables/phase0md6_08a_security_authorable_validator.py`

### Modified

- `docs/AUTHORABLE_NODES_GUIDE.md` — cross-link only

### Protected (untouched)

- `project.godot`
- `src/player/Player.gd`, `PlayerStaminaController.gd`
- `scenes/characters/player.tscn`
- No changes to `IsoMissionBase`, security runtime scripts, or Taco scene

## Templates

| Template | Runtime-ready? |
|----------|----------------|
| SecurityBeamAuthorTemplate | Yes — uses existing beam pipeline |
| AmbushBeamAuthorTemplate | Yes — preset ambush event |
| SecurityCameraAuthorTemplate | Yes — Taco mission setup |
| GuardSpawnAuthorTemplate | Yes — event-driven spawn |
| GuardPatrolRouteAuthorTemplate | Yes — data for patrol behavior |
| PatrolWaypointTemplate | Structural only |
| AreaTriggerAuthorTemplate | Yes — area + router |

Deferred: Guard (idle), AlarmGroup, DoorKeypad templates.

## Validator

**Path:** `src/tools/editor/d6_08a_security_authorables/phase0md6_08a_security_authorable_validator.py`

**Checks:** guide/report/templates exist; required scripts; Taco `SecurityAuthoringRoot` placeholder/duplicate IDs; patrol route waypoint count; spawn `patrol_route_id` references; protected paths noted.

**Limitations:** No Godot runtime; partial `trigger_events` array parsing; does not validate MarkerRoot Phase0K JSON.

## Kimi K2.6 advisory

- **Used:** yes (`architecture_review`)
- **Adopted:** templates+validator-first; classify idle guard/alarm as NEEDS BRIDGE; defer door/keypad; warn on false runtime affordance
- **Rejected:** broad new frameworks; implying alarm group node without bridge
- **No secrets sent**

## Validation

| Check | Result |
|-------|--------|
| Static validator | **PASS** (`phase0md6_08a_static_validator_run.json`) |
| Godot MCP Pro | **PASS** — opened Taco scene, played current scene, `SecurityAuthoringRoot` live: cameras=1, spawns=2, patrols=1, areas=3, runtime cameras=1; no new blocking errors |
| Godot LSP | **PASS** — workspace scan: no new errors in D6-08A files; pre-existing warnings elsewhere |
| GdUnit4 | **Not run** — no D6-08A security tests; existing `tests/d6_06/` unchanged |
| DAP | **Not used** — MCP runtime tree probe sufficient |

**Note:** `SecurityAuthoringRoot.collect_beam_authors()` counts any child with `build_runtime_config`, including `SecurityCameraAuthor` (pre-existing). Use `collect_camera_authors()` for camera counts; F10 uses separate fields.

## Known limitations

- Security authoring runtime setup is **Taco-gated** (`taco_bell_drop`).
- Templates in other missions need matching `IsoMissionBase` setup in a later pass.
- Idle guards still come from MarkerRoot / Phase0K.

## Recommended next phases

1. **D6-08B** — Guard spawn + patrol hardening; idle guard bridge from markers
2. **D6-08C** — Camera/beam multi-mission setup + validator depth
3. **D6-08D** — Ambush/alarm event graph authoring
4. **D6-08E** — Door/keypad if audit clears production APIs
