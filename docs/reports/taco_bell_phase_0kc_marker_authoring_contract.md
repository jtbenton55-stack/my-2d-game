# Phase 0K-C Marker Authoring Contract

This contract documents the runtime behavior used by the Taco Bell redesign duplicate.

## Categories

- `GUARD`: spawns one real guard-style runtime guard.
- `PATROL`: supplies patrol route points for nearby guards.
- `CAM`: spawns one active `MissionSecurityCamera` with a visible cone and sweep behavior.

## Required Metadata

- `manifest_id` or node name: stable marker id.
- `category`: `GUARD`, `PATROL`, or `CAM`.
- Optional `patrol_group` / `linked_patrol_ids`: future explicit route grouping.

## Runtime Behavior

- `Phase0KGuardSpawner` enumerates `GUARD` markers under `GameplayRoot/MarkerRoot/EditorOnlyPlaceholders` and spawns `Phase0KGuardPatrol` nodes under `GameplayRoot/Phase0KRuntime/Guards`.
- Guards use the real guard-style token: black body outline, red body, white head, and red scanning cone.
- Patrol guards use nearest `PATROL` markers; if no route is nearby, they get a local fallback route.
- `Phase0KCameraSpawner` enumerates `CAM` markers and spawns `MissionSecurityCamera` nodes under `GameplayRoot/Phase0KRuntime/Cameras`.
- Cameras must have visible cones and sweep/search behavior.

## Placement Rules

- `GUARD` and `PATROL` markers must be on reachable floor.
- `CAM` markers may be floor, ceiling, or wall-adjacent, but their cone must cover reachable floor.
- Invalid visible/debug-only markers are hidden at runtime or moved to nearby floor by bounds cleanup.

## Future Generalization

A later generalized pass should turn this scene-local contract into a reusable mission runtime: explicit patrol groups, editor validation warnings, and non-destructive preview of invalid marker placements.
