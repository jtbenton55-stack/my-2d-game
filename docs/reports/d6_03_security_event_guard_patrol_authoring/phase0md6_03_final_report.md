# PHASE 0M-D6-03 — Final Report

## Goal

**Status: PASSED (with documented MCP limitations)**

Mission-local security event routing, beam/area event emission, functional `GuardSpawnAuthor` / `GuardPatrolRouteAuthor`, and duplicate direct-beam spawn suppression are implemented and runtime-verified on Taco Bell editable mission.

## Files changed

### Added
- `src/missions/iso/runtime/SecurityEventRouter.gd`
- `src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd`
- `src/missions/iso/authoring/AreaTriggerAuthor.gd`
- `src/tools/editor/d6_03_security_event_guard_patrol_authoring/phase0md6_03_static_validator.py`
- `docs/reports/d6_03_security_event_guard_patrol_authoring/*`

### Modified
- `src/missions/iso/authoring/SecurityAuthoringRoot.gd`
- `src/missions/iso/authoring/SecurityBeamAuthor.gd`
- `src/missions/iso/authoring/GuardSpawnAuthor.gd`
- `src/missions/iso/authoring/GuardPatrolRouteAuthor.gd`
- `src/levels/IsoMissionBase.gd` (router wiring, spawn API, beam emit, F10 state, compile fixes)
- `src/enemies/Guard.gd` (authoring behavior + archetype metadata)
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd` (F10 section)
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (proof nodes)

### Protected (untouched)
- `project.godot`, `Player.gd`, `PlayerStaminaController.gd`, `player.tscn`, save/load, heat persistence, HUD, pause, F1/F10/F11 input routing

## Systems reused
- `SecurityAuthoringRoot` collection/validation
- `SecurityBeamAuthor` runtime beam build (D6-02/D6-02A)
- Existing alarm zone `body_entered` → `_on_runtime_alarm_zone_entered`
- `MissionSecurityGuardResolver` guard scene path
- Security spawn cap / functional guard counting
- Search-net builders for `join_security_net`
- F10 runtime summary pipeline

## Systems added / modified

### SecurityEventRouter (mission-local `Node`)
- `register_listener`, `emit_event`, `has_listeners`, `get_debug_summary`
- Dispatches `on_security_event(event_id, payload)` on listeners
- Tracks listener counts, recent events, warnings

### MissionAuthoringRuntimeBuilder
- Creates router under `GameplayRoot/RuntimeSystems`
- Registers `GuardSpawnAuthor` listeners by `trigger_events`
- Calls `AreaTriggerAuthor.setup_runtime_trigger`

### SecurityBeamAuthor
- `on_trip_event` (default `ambush_beam_tripped`), `emit_event_on_trip`
- Beam trip emits through router from `IsoMissionBase._on_runtime_alarm_zone_entered`

### AreaTriggerAuthor
- Editor preview + runtime `Area2D` under `AuthoringAreaTriggers`
- Emits `on_enter_event` on player entry (one-shot supported)

### GuardSpawnAuthor
- Listens via router; spawns through `_spawn_guard_from_authoring_spawn`
- Cooldown, heat min/max, max alive, behaviors (`attack_player`, `patrol`, etc.)

### GuardPatrolRouteAuthor
- Child `Node2D` waypoints → `get_patrol_points_global()`

### Duplicate prevention
- `can_spawn_alarm_guard_for_source` returns `false` for ambush beam when `has_listeners(trip_event)`
- Event route spawns guard; legacy direct beam spawn suppressed

## Architecture notes
Event IDs decouple triggers (beam, area, future camera/gate) from responses (guard spawn, locks, objectives). No hardcoded `camera_id` → spawn branches.

## Kimi K2.6
- **Used:** yes (`regression_risk_review`)
- **Adopted:** per-beam one-shot/debounce on emit; verify listener spawn success before suppressing fallback (future hardening); manual overlap check after teleport for tests
- **Rejected:** global autoload router (kept mission-local per spec)
- **No secrets/private files sent**

## Safety
- Work confined to repo; no git history operations; no credential access

## Godot validation

| Tool | Result |
|------|--------|
| Static validator | PASS |
| LSP (`IsoMissionBase`, `GuardSpawnAuthor`) | clean |
| Godot MCP `validate_script` | false negative (DialogueManager / stale log); **runtime OK** |
| GdUnit4 | no mission security tests |
| DAP | not required |

### Runtime values (MCP playtest)
| Field | Value |
|-------|-------|
| router active | true |
| registered events | 1 |
| listeners `ambush_beam_tripped` | 1 |
| last event (manual) | `ambush_beam_tripped` |
| spawn author | `ambush_guard_spawn` |
| spawn result | `spawned` |
| spawned count | 1 |
| duplicate avoided | yes |
| direct beam spawn allowed | false |
| screenshot | `user://d6_03_runtime_validation.png` |

## Known limitations
- MCP teleport did not confirm `body_entered` beam trip; manual `emit_event` confirmed routing.
- `test_area_entered` area exists; no second spawn author wired (minimal clutter).
- Patrol spawn proof not run (`attack_player` used on proof spawn).
- Full archetype stat variation deferred (metadata only for fast/tough).

## Suggested next step
**D6-04:** functional `SecurityCameraAuthor` runtime + camera alarm event → downstream effects.
