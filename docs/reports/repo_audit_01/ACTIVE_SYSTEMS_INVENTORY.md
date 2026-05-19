# ACTIVE SYSTEMS INVENTORY

Systems with clear evidence of current use in the working game spine.

## PROTECTED_BASELINE

- `project.godot` startup/autoload chain.
- `res://scenes/MainMenu.tscn` + `src/ui/MainMenu.gd`.
- `src/autoload/SceneManager.gd` + `src/missions/MissionSceneResolver.gd`.
- `res://scenes/hideout/HideoutHub.tscn` + `src/hideout/HideoutManager.gd` and hideout controllers.
- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- `src/levels/IsoMissionBase.gd` runtime structure and mission lifecycle.
- `src/missions/iso/runtime/Phase0JInteractionBridge.gd` interaction routing.
- `src/missions/iso/runtime/Phase0KMissionCompletionController.gd` + `Phase0KLouisExitInteractable.gd`.
- `src/missions/iso/runtime/MissionAuthoredCollectiblePersistence.gd` + `MissionCollectibleHideoutSync.gd`.

## KEEP_ACTIVE (mission security)

- `src/missions/iso/authoring/SecurityAuthoringRoot.gd`
- `src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd`
- Author scripts:
  - `SecurityBeamAuthor.gd`
  - `SecurityCameraAuthor.gd`
  - `GuardSpawnAuthor.gd`
  - `GuardPatrolRouteAuthor.gd`
  - `AreaTriggerAuthor.gd`
  - effect authors (`DoorLockEffectAuthor`, `SecurityLockdownEffectAuthor`, `ObjectiveEffectAuthor`, `NodeToggleEffectAuthor`)
- Runtime support:
  - `SecurityEventRouter.gd`
  - `MissionSecurityCamera.gd`
  - `MissionAlertController.gd`
  - guard/patrol runtime scripts under `src/missions/iso/runtime/`

## KEEP_ACTIVE (collectible authorables)

- `src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd`
- `src/missions/iso/runtime/AuthoredPhase0JInteractablePickup.gd`
- Author scripts:
  - `PoopBagAuthor.gd`
  - `CaseCashAuthor.gd`
  - `PolaroidAuthor.gd`
  - `TinyIconAuthor.gd`
  - `GlowGuyAuthor.gd`
  - `ClueAuthor.gd`
- Scene evidence in Taco:
  - `CollectibleAuthoringProof` cluster under `GameplayRoot/SecurityAuthoringRoot/...`

## KEEP_ACTIVE (hideout sync + meta loop)

- `src/hideout/HideoutStateController.gd` case cash and display state.
- `src/hideout/HideoutMissionBoardController.gd` launch flow.
- `src/hideout/HideoutCollectibleController.gd`, `HideoutEvidenceBoardController.gd`, `HideoutStoreController.gd`.
- `HideoutManager` deferred sync call path:
  - `apply_banked_case_cash_to_hideout`
  - `apply_persisted_flags_to_hideout_state`

## KEEP_ACTIVE (debug and test scaffolding in active loop)

- `src/missions/iso/runtime/IsoMissionDebugPanel.gd` is integrated by `IsoMissionBase` and tied to F10/F9 behavior.
- `tests/d6_06/MissionAuthoredCollectiblePersistenceTest.gd` exists and targets current persistence helpers.
- Validators for d6_06b/d6_07/d6_07b/d6_08a exist and reflect current authored-system contracts.

## KEEP_BUT_REFACTOR_LATER (still active)

- `src/levels/IsoMissionBase.gd` (centralized large surface area; heavy coupling).
- `src/hideout/HideoutManager.gd` (multi-responsibility orchestration and runtime child creation).
- Runtime debug marker generation under `GeneratedRuntimeMarkerDebugInteractables` (useful but noisy/high-coupling).

## Confidence

- High confidence for startup/mission/hideout system activity due to:
  - direct path wiring in code,
  - scene references,
  - Godot runtime scene-tree observations.
- Medium confidence on some legacy/duplicate runtime pathways where dynamic behavior or tooling conventions may still consume nodes/scripts indirectly.
