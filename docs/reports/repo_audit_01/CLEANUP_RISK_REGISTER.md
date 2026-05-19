# CLEANUP RISK REGISTER

Cleanup planning register only. No cleanup executed.

## Risk tiers

- `SAFE_DOCS_ONLY`
- `SAFE_VALIDATOR_ONLY`
- `LOW_RISK_QUARANTINE_CANDIDATE`
- `MEDIUM_RISK_SCENE_CLEANUP`
- `HIGH_RISK_DO_NOT_TOUCH_YET`
- `NEVER_REMOVE_CURRENTLY_PROTECTED`

## Register

| Item | Classification | Risk tier | Why | Recommended later handling |
|---|---|---|---|---|
| Startup chain (`project.godot`, MainMenu, SceneManager launch flow) | PROTECTED_BASELINE | NEVER_REMOVE_CURRENTLY_PROTECTED | Core boot path | No cleanup; only refactor with full regression gates |
| `IsoMissionBase.gd` core mission lifecycle | PROTECTED_BASELINE / KEEP_BUT_REFACTOR_LATER | NEVER_REMOVE_CURRENTLY_PROTECTED | Central orchestration + many dependents | Modularize later; no deletion |
| `SecurityAuthoringRoot` + mission authoring runtime builder stack | KEEP_ACTIVE | NEVER_REMOVE_CURRENTLY_PROTECTED | Current security mechanics depend on it | Preserve; adapter-based evolution |
| Collectible authoring runtime stack (author scripts + builder + persistence + sync) | KEEP_ACTIVE | NEVER_REMOVE_CURRENTLY_PROTECTED | Active D6-06/07 loop and hideout sync | Preserve; extend pattern |
| Hideout manager/controller cluster | KEEP_ACTIVE | HIGH_RISK_DO_NOT_TOUCH_YET | Tight runtime coupling and dynamic setup | Gradual decoupling only |
| `AuthoredCollectiblePickup.gd` legacy path | LEGACY_DO_NOT_USE | LOW_RISK_QUARANTINE_CANDIDATE | Superseded by authored Phase0J path | Quarantine later with manifest |
| Taco `@Label@#####` proof/auto labels under security authoring nodes | KEEP_BUT_REFACTOR_LATER | HIGH_RISK_DO_NOT_TOUCH_YET | Possible tool/plugin-generated dependencies | Isolate on branch; runtime parity test before move |
| `GeneratedRuntimeMarkerDebugInteractables` bulk | KEEP_BUT_REFACTOR_LATER | MEDIUM_RISK_SCENE_CLEANUP | Useful debug visibility but noisy and heavy | Gate/reduce in staged debug-policy pass |
| Non-resolver Taco variants (`Editable`, `Editable_Test`, `Editable2`) | UNKNOWN_NEEDS_MANUAL_REVIEW | HIGH_RISK_DO_NOT_TOUCH_YET | Could be tool/test/back-compat references | Full ref graph + runtime checks first |
| Hideout PVG layer families | KEEP_ACTIVE / FUTURE_USEFUL | HIGH_RISK_DO_NOT_TOUCH_YET | Layer name/path coupling likely in tools/scripts | Standardize names only with migration tooling |
| Documentation/report duplication and stale report folders | CANDIDATE_FOR_REMOVAL | SAFE_DOCS_ONLY | Non-gameplay clutter | Clean docs only in separate pass |
| Static validators coverage expansion | FUTURE_USEFUL | SAFE_VALIDATOR_ONLY | Safer cleanup gating without gameplay edits | Add read-only checks first |

## Mandatory reversible movement pattern (future pass)

For any future move to `_UnusedCandidates` or `_LegacyCandidates`:

1. Keep same parent domain (`src/...`, `scenes/...`, `assets/...`) and create child candidate folder there.
2. Create manifest row per moved item:
   - original path
   - candidate path
   - reason
   - evidence summary
   - confidence
   - risk tier
   - rollback path
3. Move only after manual approval and baseline runtime regression pass.
4. Keep rollback script/instructions in same cleanup PR.
