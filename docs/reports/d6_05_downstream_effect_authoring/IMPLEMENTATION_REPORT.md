# D6-05 Downstream Effect Authoring — Implementation Report

## Summary

Added event-linked downstream effect authors that register as `SecurityEventRouter` listeners and reuse existing mission systems.

## New scripts

| Script | Role |
|--------|------|
| `SecurityEffectAuthorBase.gd` | Shared cooldown, one-shot, event match, structured results |
| `DoorLockEffectAuthor.gd` | `set_code_gate_open` / gate flags / node `locked` adapter |
| `SecurityLockdownEffectAuthor.gd` | `MissionAlertController.set_alert_state` |
| `ObjectiveEffectAuthor.gd` | `QuestManager` + debug flags |
| `NodeToggleEffectAuthor.gd` | Safe show/hide/process toggle for proof nodes |

## Integration

- `SecurityAuthoringRoot` — collect/count effect authors by type
- `MissionAuthoringRuntimeBuilder` — register listeners, bind mission, store counts
- `IsoMissionBase` — `_record_authoring_effect_result`, `_store_d6_05_effect_author_counts`
- `IsoMissionDebugPanel` — Downstream Effects F10 section

## Taco proof nodes

- `CameraLockdownEffect_Author` → `test_camera_alarm`
- `CameraProofToggleEffect_Author` → shows `D6_05_ProofMarker`
- `BeamObjectiveEffect_Author` → `ambush_beam_tripped` debug objective flag
- `DoorLockEffect_Author` — present but **disabled** (API-ready, no risky garage gate target)

## Kimi

Not used.
