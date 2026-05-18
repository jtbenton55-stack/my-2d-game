# PHASE 0M-D6-02 — Security Authoring Editor Foundation

## Goal

Hand-placeable security authoring nodes in the Godot editor; runtime consumes author placement instead of FIX7F collision geometry when enabled.

## Added

- `src/missions/iso/authoring/SecurityAuthoringRoot.gd` — container, collection helpers, `find_enabled_beam_author`
- `src/missions/iso/authoring/SecurityBeamAuthor.gd` — beam exports, editor preview, `build_runtime_config()`
- `src/missions/iso/authoring/SecurityCameraAuthor.gd` — editor cone preview (runtime hookup deferred)
- `src/missions/iso/authoring/GuardSpawnAuthor.gd` — editor marker (runtime hookup deferred)
- `src/missions/iso/authoring/GuardPatrolRouteAuthor.gd` — waypoint polyline preview (runtime hookup deferred)

## Modified

- `src/levels/IsoMissionBase.gd` — authoring lookup, `_setup_ambush_beam_from_security_beam_author`, FIX7F fallback
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd` — F10 `--- Security Authoring ---` block
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` — `GameplayRoot/SecurityAuthoringRoot` + `AMBUSH_security_beam` author at (8050, 700)

## Protected (untouched)

- `project.godot`, `Player.gd`, `PlayerStaminaController.gd`, `player.tscn`, save/load, heat, hub, launcher

## Runtime flow

1. Deferred `_setup_fix7_ambush_beam_runtime` on `physics_frame`
2. If `SecurityBeamAuthor` enabled for `AMBUSH_security_beam` → authoring path
3. Else existing FIX7F doorway solver fallback
4. F10 reports `d6_02_ambush_beam_source` (`authoring_node` | `fix7f_fallback` | `missing`)
