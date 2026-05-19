# LEGACY AND UNUSED CANDIDATES

Audit-only candidate list. No cleanup performed.

## Classification key used

- `LEGACY_DO_NOT_USE`
- `CANDIDATE_FOR_REMOVAL`
- `UNKNOWN_NEEDS_MANUAL_REVIEW`
- `KEEP_BUT_REFACTOR_LATER`

## Top candidates

### 1) `src/missions/iso/runtime/AuthoredCollectiblePickup.gd`

- Classification: `LEGACY_DO_NOT_USE`
- Confidence: high
- Evidence:
  - Current builder targets `AuthoredPhase0JInteractablePickup.gd`.
  - Static validator text explicitly treats this file as deprecated and checks for non-usage by builder path.
- Cleanup risk: `LOW_RISK_QUARANTINE_CANDIDATE` (later pass only).
- Recommended later action: move to `_LegacyCandidates` inside same parent, with manifest and fallback restore path.

### 2) Auto-generated label residue under Taco `SecurityAuthoringRoot` (`@Label@#####`)

- Classification: `KEEP_BUT_REFACTOR_LATER` (not safe removal yet)
- Confidence: medium
- Evidence:
  - Present in scene tree and static scene text.
  - Associated with authoring nodes and proof clusters.
  - Could be plugin/tool-generated metadata markers.
- Cleanup risk: `HIGH_RISK_DO_NOT_TOUCH_YET`
- Recommended later action: runtime-isolated experiment branch only, compare builder output and F10/runtime behavior before any node movement.

### 3) Massive runtime debug surfaces: `GeneratedRuntimeMarkerDebugInteractables`

- Classification: `KEEP_BUT_REFACTOR_LATER`
- Confidence: high
- Evidence:
  - Runtime tree shows extensive debug marker interactables.
  - `IsoMissionBase` contains explicit debug marker generation paths.
- Cleanup risk: `MEDIUM_RISK_SCENE_CLEANUP` (behavior/debug regression risk).
- Recommended later action: preserve by default; if reducing, gate by explicit debug flag and verify interaction path parity.

### 4) Multiple Taco scene variants

- Paths:
  - `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (playable target)
  - `scenes/missions_iso/TacoBellIso_Editable.tscn`
  - `scenes/missions_iso/TacoBellIso_Editable_Test.tscn`
  - `scenes/missions_iso/TacoBellIso_Editable2.tscn`
- Classification:
  - RedesignTest: `PROTECTED_BASELINE`
  - Other variants: `UNKNOWN_NEEDS_MANUAL_REVIEW`
- Confidence: medium
- Evidence:
  - `MissionSceneResolver` hard-resolves `taco_bell_drop` to `RedesignTest`.
  - Other files may still be tooling references.
- Cleanup risk: `HIGH_RISK_DO_NOT_TOUCH_YET`
- Recommended later action: run full reference and dynamic-load checks before any quarantine.

### 5) Old phase scripts and cleanup tools in `src/tools/editor/` and runtime `Phase0*` families

- Classification: `UNKNOWN_NEEDS_MANUAL_REVIEW`
- Confidence: low-medium
- Evidence:
  - Many phase-tagged scripts appear historical but some are still referenced by current scenes/runtime classes.
  - Mixed naming and coexistence of active + historical utilities.
- Cleanup risk: `HIGH_RISK_DO_NOT_TOUCH_YET`
- Recommended later action: only classify as removable after usage graph + runtime checks in separate branch.

## Additional notes

- High count alone (`Label`, `CollisionShape2D`, `Area2D`) is not sufficient proof of unused status in this project due to runtime builders and debug overlays.
- Group-based and signal/event wiring (`EventBus`, runtime routers) can hide real dependencies from naive scene-file scans.
