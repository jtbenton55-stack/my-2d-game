# PHASE 0M-D6-03 — Security Event Routing + Guard Spawn / Patrol Authoring

## Added

- `SecurityEventRouter.gd` — mission-local event dispatch
- `MissionAuthoringRuntimeBuilder.gd` — wires listeners and area triggers at boot
- `AreaTriggerAuthor.gd` — hand-placed area triggers emitting event IDs
- Functional `GuardSpawnAuthor` / `GuardPatrolRouteAuthor`
- `Guard.gd` — `apply_authoring_spawn_behavior`, `assign_patrol_points_world`, `apply_archetype_metadata`

## Modified

- `IsoMissionBase.gd` — router setup, beam event emission, duplicate-spawn suppression, `_spawn_guard_from_authoring_spawn`
- `SecurityBeamAuthor.gd` — `on_trip_event`, `emit_event_on_trip`
- `SecurityAuthoringRoot.gd` — collection helpers
- `IsoMissionDebugPanel.gd` — F10 Security Events section
- `TacoBellIso_Editable_RedesignTest.tscn` — proof spawn author, patrol route, area trigger
