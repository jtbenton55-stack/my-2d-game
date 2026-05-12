# 0M-D5-02A — Phase 2: Taco runtime clutter (GRB)

## Method

- **GRB** tier 2: `NewGameButton` → `HideoutMissionBoardController.launch_taco_bell()`.
- `grb_find_nodes` substring `Debug` (limit 40).

## Observations (pre-relaunch; some nodes reflect prior build)

- **Phase0JDebugHUD** at `.../RuntimeHelpers/Phase0JDebugHUD` — `CanvasLayer`; after code fix expected **`visible = false`** when `visible_by_default` is false and startup message no longer forces visibility.
- **IsoMissionDebugPanel** at `/root/TacoBellIso_Editable/IsoMissionDebugPanel` — **`visible: false`** after hygiene (F10 to show).
- Many **world** debug interactables (`Debug_*` Area2D) — clutter in-world, not corner text; **deferred** for a later “marker visibility” pass.
- **Screenshot:** not captured (GRB screenshot tool not invoked this pass).

## Limitations

- GRB **pause** path still poor for scroll testing (per D5-00).
- One `grb_get_property` used wrong path (`RuntimeSystems` vs `RuntimeHelpers`) — corrected in follow-up read.
