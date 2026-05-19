# FUTURE FEATURE FIT ANALYSIS

Mapping current systems to future plug-and-play roadmap targets.

## Fit legend

- `directly reusable`
- `reusable with adapter`
- `should be replaced later`
- `unknown`
- `not useful`

## High-fit foundations

### 1) Authoring-root + runtime-builder pattern

- Current: `SecurityAuthoringRoot` + `MissionAuthoringRuntimeBuilder`, collectible author base + collectible runtime builder.
- Future fit: `directly reusable`.
- Why: already supports "place editor node -> runtime behavior" workflow.

### 2) Mission runtime root topology

- Current: `IsoMissionBase` + structured roots (`GameplayRoot`, `ArtRoot`, `EntityRoot`, `RuntimeSystems`, `GeneratedRuntimeInteractables`).
- Future fit: `reusable with adapter`.
- Why: strong structure, but currently centralized and heavily coupled.

### 3) Completion + mission loop handoff

- Current: Phase0K completion controller and Louis exit path, SceneManager return flow, hideout sync.
- Future fit: `reusable with adapter`.
- Why: loop exists, but objective semantics are mission-specific and partly fallback-driven.

### 4) Hideout state + sync surfaces

- Current: `HideoutStateController`, `MissionCollectibleHideoutSync`, display-key persistence path.
- Future fit: `directly reusable` for meta-loop rewards/progression.

### 5) Tile/layer split for 2.5D missions

- Current: gameplay/collision/marker/art layer partition in mission + paint layer conventions in hideout.
- Future fit: `directly reusable` for map-painting pipeline baseline.

## Medium-fit foundations

### 6) Security authorables

- Current: beams/cameras/spawns/patrols/triggers/effects.
- Future fit: `reusable with adapter`.
- Why: core pieces exist, but broader suspicion/alarm/noise/distraction framework still needs generalized contracts.

### 7) Collectible authorables

- Current: poop/case-cash/polaroid/tiny/glow/clue authorables with commit/persist path.
- Future fit: `reusable with adapter`.
- Why: strong pattern for objective/inspectable/interactable authorables with extended schemas.

### 8) F10 debug visibility

- Current: `IsoMissionDebugPanel` exposes many runtime/security/collectible signals.
- Future fit: `reusable with adapter`.
- Why: valuable operator tooling, but noisy and mission-specific sections need modularization.

## Low-fit or replace-later candidates

### 9) Monolithic mission base and phase-tag pathways

- Current: `IsoMissionBase` contains many phase-specific paths, fallback logic, and mixed concerns.
- Future fit: `should be replaced later` (or heavily modularized).
- Why: high coupling will slow extensibility for new mechanic families.

### 10) Legacy marker/debug interactable bulk

- Current: large generated debug marker populations and legacy proof residue.
- Future fit: `unknown` to `not useful` for shipping mechanics, but may remain useful for dev verification.

## Priority scoring snapshot (E/U/I/C model)

Approximate foundational priorities from observed architecture:

1. Authoring-root + runtime-builder contract: high C/I, medium-high E/U.
2. Requirement/effect-style reusable mechanic node pattern: high C/I, medium E.
3. Objective step orchestration abstraction over current mission-specific completion.
4. Trigger/event volume standardization over current area-trigger/event-router pattern.
5. Security state orchestration (suspicion/alarm) generalized from current alert/controller path.
6. Inventory/heist kit + scheme integration anchored to current GameState/meta loop.
7. Map-painting canonical layer contract from existing TileMapLayer split.

## Kimi advisory reconciliation (applied)

Adopted from advisory review:

- Treat dynamic Godot dependencies (groups/signals/class_name/runtime builders) as first-class coupling risk.
- Avoid deleting scene residue solely from static counts.
- Use phased cleanup with mandatory runtime parity checks.

Modified:

- Keep some debug surfaces as `KEEP_BUT_REFACTOR_LATER` instead of classifying immediately as removal candidates.

Rejected:

- Any broad rewrite-first recommendation without staged verification.
