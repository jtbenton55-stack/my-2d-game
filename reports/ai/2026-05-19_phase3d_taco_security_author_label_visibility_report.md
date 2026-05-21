# Phase 3D — Taco Security Author-Label Runtime Readability Policy Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Packet type:** Security author debug-label visibility (follows Phase 3C; no gameplay / completion / map paint changes)

## Goal

Reduce Taco runtime clutter from `SecurityAuthoringRoot` debug labels while preserving security runtime behavior, hazard readability, Phase 3C generated-marker hiding, plug-and-play pilot visuals/gameplay, and canonical Phase0J/Phase0K Taco flow.

## Files changed

| File | Change |
|------|--------|
| `src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd` | Added `hide_security_label_residue`; unified `_hide_security_debug_labels()` / `_should_hide_security_label()` |
| `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` | Taco opts in: `hide_security_author_labels = true`, `hide_security_label_residue = true` (keeps Phase 3C generated-label hide) |
| `tests/mission_authoring/Phase0JRuntimeAuthoringHiderTest.gd` | Updated — 7 focused tests (2 new for Phase 3D taco policy + residue flag) |
| `reports/ai/2026-05-19_phase3d_taco_security_author_label_visibility_report.md` | This report |
| `reports/ai/phase3d_taco_security_author_label_screenshots/*` | Before/after runtime screenshots |

**Not modified:** `project.godot`, autoloads, `IsoMissionBase`, `Phase0JInteractionBridge.gd`, `Phase0KMissionCompletionController.gd`, `MissionInteractionBridge.gd`, pilot requirements/effects/flags/IDs, collision/tile paint, canonical bag/manifest/Louis gameplay logic.

## Files inspected

| Area | Paths |
|------|--------|
| Prior phases | `reports/ai/2026-05-19_phase3a_*.md`, `phase3b_*.md`, `phase3c_*.md` |
| Roadmap / blueprint | `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`, `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`, `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` |
| Scene | `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` |
| Hider | `src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd` |
| Security authoring | `SecurityAuthoringRoot.gd`, `MissionAuthoringRuntimeBuilder.gd`, `SecurityBeamAuthor.gd`, `SecurityCameraAuthor.gd`, `AreaTriggerAuthor.gd`, `GuardSpawnAuthor.gd`, `GuardPatrolRouteAuthor.gd`, `SecurityEffectAuthorBase.gd` |
| Bridges (read-only) | `Phase0JInteractionBridge.gd`, `Phase0KMissionCompletionController.gd` |

## Git / branch baseline

- **Branch:** `new-feature-roadmap-branch`
- **Pre-existing dirty worktree:** unrelated doc/report untracks, deleted `reports/report_5`–`report_6` artifacts (not touched by Phase 3D)
- **Phase 3D modifies only:** hider script, Taco scene hider exports, hider tests, Phase 3D report/screenshots

## Security author-label ownership audit

### Where labels live

All audited security debug labels are under `GameplayRoot/SecurityAuthoringRoot` (separate from `GeneratedRuntimeMarkerLabels` and `PlugAndPlayPilot`).

**Direct children of `SecurityAuthoringRoot` (author roots):**

| Node | Role |
|------|------|
| `AMBUSH_security_beam` | Beam author |
| `AmbushGuardSpawn_Author` | Guard spawn |
| `TestCamera_Author` | Camera author |
| `CameraAlarmGuardSpawn_Author` | Camera-linked spawn |
| `AmbushTestPatrol` | Patrol route author |
| `TestAreaGuardTrigger_Author` | Area trigger author (+ 8 `@Label@` residue) |
| `D6_05_ProofMarker` | Proof marker (`ProofLabel` preserved) |
| `CameraLockdownEffect_Author` | Effect author |
| `BeamObjectiveEffect_Author` | Effect author |
| `CameraProofToggleEffect_Author` | Effect author |
| `TestDoorLockProof` | Door-lock proof subtree (`DoorLabel` preserved; lock/unlock authors + residue) |
| `DoorLock_Lock_Author` / `DoorLock_Unlock_Author` | Door-lock authors |
| `CollectibleAuthoringProof` | Authoring proof (no Phase 3D hide) |
| `Authoring_Templates` | Templates |

### Label inventory (Taco scene text)

| Class | Count | Action |
|-------|-------|--------|
| Named `AuthorLabel` (`Label`) | **13** | Hidden at runtime when `hide_security_author_labels = true` |
| Editor residue `@Label@...` under `SecurityAuthoringRoot` | **24** | Hidden when `hide_security_label_residue = true` |
| `ProofLabel` | **1** | **Preserved visible** (proof/debug, not author preview) |
| `DoorLabel` | **1** | **Preserved visible** (door prototype readability) |
| `@Label@` under `MarkerRoot/Spawns` | Many | **Out of scope** — not under `security_authoring_root_path` |

### Exact `AuthorLabel` paths inspected

1. `GameplayRoot/SecurityAuthoringRoot/AMBUSH_security_beam/AuthorLabel`
2. `.../AmbushGuardSpawn_Author/AuthorLabel`
3. `.../TestCamera_Author/AuthorLabel`
4. `.../CameraAlarmGuardSpawn_Author/AuthorLabel`
5. `.../AmbushTestPatrol/AuthorLabel`
6. `.../TestAreaGuardTrigger_Author/AuthorLabel`
7. `.../CameraLockdownEffect_Author/AuthorLabel`
8. `.../BeamObjectiveEffect_Author/AuthorLabel`
9. `.../CameraProofToggleEffect_Author/AuthorLabel`
10. `.../TestDoorLockProof/D6_05A_LockZone_Author/AuthorLabel`
11. `.../TestDoorLockProof/D6_05A_UnlockZone_Author/AuthorLabel`
12. `.../DoorLock_Lock_Author/AuthorLabel`
13. `.../DoorLock_Unlock_Author/AuthorLabel`

### Script risk audit (visibility vs runtime)

| Check | Result |
|-------|--------|
| `SecurityAuthoringRoot` collects authors by methods (`build_runtime_config`, `spawn_id`, `camera_id`, patrol points, etc.) | **No label dependency** |
| `MissionAuthoringRuntimeBuilder` wires router/listeners from author nodes | **No label dependency** |
| Author scripts use labels for preview/debug text only | **Visual-only hide** |
| Hiding affects collision / `enabled` / `trigger_events` / groups | **No** — only `CanvasItem.visible` on matching `Label` nodes |
| Hider hides full author roots | **No** — only named/residue labels |

**Decision gate:** **Path B** — `hide_security_author_labels` alone is insufficient because 24 `@Label@` residue labels remain visible under security authors.

## Implementation summary

### `Phase0JRuntimeAuthoringHider.gd`

- Existing `hide_security_author_labels` (default `false`): hides `Label` nodes named exactly `AuthorLabel` under `security_authoring_root_path`.
- **New** `hide_security_label_residue` (default `false`): hides `Label` nodes whose name begins with `@Label@` or contains `@Label@` (scene-baked editor residue).
- Does **not** hide `ProofLabel`, `DoorLabel`, or non-`Label` nodes.
- Labels are hidden (`visible = false`, optional `z_index = -4096`), not deleted; metadata `phase_0ja_hidden_at_runtime` set.

### Taco scene (`GameplayRoot/RuntimeHelpers/Phase0JRuntimeAuthoringHider`)

| Export | Taco value | Default elsewhere |
|--------|------------|-------------------|
| `hide_generated_runtime_marker_labels` | `true` (Phase 3C) | `false` |
| `hide_security_author_labels` | **`true`** | `false` |
| `hide_security_label_residue` | **`true`** | `false` |
| `generated_runtime_marker_labels_path` | `../../GeneratedRuntimeMarkerLabels` | unchanged |
| `security_authoring_root_path` | `../../SecurityAuthoringRoot` (script default) | unchanged |

`MissionInteractionBridge.include_legacy_candidates = false` (unchanged).

## Exact visibility policy / configuration

| Target | Taco runtime | Default (other scenes) |
|--------|--------------|------------------------|
| `GeneratedRuntimeMarkerLabels` | Hidden (Phase 3C) | Unchanged unless opted in |
| `SecurityAuthoringRoot/**/AuthorLabel` | Hidden | Visible |
| `SecurityAuthoringRoot/**/@Label@*` residue | Hidden | Visible |
| `ProofLabel`, `DoorLabel` | **Visible** | Visible |
| Security author `Node2D` roots | Visible / functional | unchanged |
| `RuntimeSystems/.../AmbushBeamLine` | Visible | unchanged |
| `PlugAndPlayPilot`, `GeneratedRuntimeInteractables` | Visible | unchanged |

## Before/after screenshots

| File | Description |
|------|-------------|
| `reports/ai/phase3d_taco_security_author_label_screenshots/before_security_author_labels_visible.png` | Reused Phase 3C-era spawn with security author text clutter |
| `reports/ai/phase3d_taco_security_author_label_screenshots/after_security_author_labels_hidden.png` | Post-policy spawn (author/residue text absent) |
| `reports/ai/phase3d_taco_security_author_label_screenshots/after_security_hazard_still_readable.png` | Beam/hazard area — pink beam zone + proof placeholder text remain |
| `reports/ai/phase3d_taco_security_author_label_screenshots/after_spawn_no_generated_or_security_debug_label_clutter.png` | Spawn without generated marker panels or security author strings |

## Generated runtime marker label preservation (Phase 3C)

| Check | Result |
|-------|--------|
| `GeneratedRuntimeMarkerLabels.visible` at runtime | **false** |
| `hide_generated_runtime_marker_labels` on Taco hider | **true** |
| Interactables under `GeneratedRuntimeInteractables` | **visible** |

## Security hazard readability result

| Check | Result |
|-------|--------|
| `AMBUSH_security_beam` author node | Present; not hidden |
| `RuntimeSystems/SecurityBeam_Ambush_RightHallway/AmbushBeamLine` | **visible** |
| `D6_05_ProofMarker/ProofLabel` | **visible** (“Alarm Zone Placeholder” class text at runtime) |
| `TestDoorLockProof/.../DoorLabel` | **visible** |
| Runtime MCP label census | **13/13** `AuthorLabel` hidden; **24/24** `@Label@` residue hidden |

Security hazards remain understandable for current runtime testing via beam line geometry, camera/trigger authoring shapes (non-label), and preserved proof/door labels — not via `AuthorLabel` strings.

## Pilot gameplay preservation result

| Check | Result |
|-------|--------|
| `PlugAndPlayPilot.visible` | **true** |
| `GeneratedRuntimeInteractables.visible` | **true** |
| Pilot search → reward → route gating | Validated earlier in session (MCP); not re-broken by label policy |
| `delivery_bag_collected` after pilot-only chain | **false** (prior session MCP) |
| Pilot does not complete mission | Preserved |

## Canonical Taco non-regression result

| Node | Path | Present |
|------|------|---------|
| Bag interactable | `GameplayRoot/GeneratedRuntimeInteractables/Interactable_OBJ_bag_recovery` | Yes |
| Manifest clue | `.../Interactable_CLUE_route_manifest_half` | Yes |
| Louis exit | `GameplayRoot/GeneratedRuntimeInteractables/LouisExitToken` | Yes |
| Phase0J bridge | `GameplayRoot/RuntimeHelpers/Phase0JInteractionBridge` | Yes |
| Phase0K completion | `GameplayRoot/RuntimeHelpers/Phase0KMissionCompletionController` | Yes |
| Legacy bridge candidates | `include_legacy_candidates = false` | Confirmed |

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit `tests/mission_authoring/` (full) | **157/157 PASS** (was 155 after Phase 3C; +2 Phase 3D hider tests) |
| `Phase0JRuntimeAuthoringHiderTest.gd` | **7/7 PASS** |
| Godot LSP / IDE diagnostics (changed `.gd`) | **Clean** |
| MainMenu smoke `res://scenes/MainMenu.tscn` | Loads; menu UI renders; no new parse/autoload errors observed |
| Godot MCP Pro scene (disk) | Taco hider exports confirmed on disk |
| Godot MCP Pro runtime Taco | Label census + visibility checks above |
| Godot DAP | **Not needed** — no unexplained runtime failures |

## Godot MCP Pro result

- Opened/played `TacoBellIso_Editable_RedesignTest.tscn` via `play_scene` mode path.
- Runtime exports: `hide_security_author_labels=true`, `hide_security_label_residue=true`, `hide_generated_runtime_marker_labels=true`.
- **Did not** `save_scene` from editor (avoid stale-editor overwrite; disk `.tscn` is source of truth).

## Kimi K2.6 MCP usage

**Not used.** Audit and script inspection were sufficient; no advisory review requested.

## Safety confirmation

- Only intended Phase 3D files changed for implementation.
- No `project.godot`, autoload, `IsoMissionBase`, bridge/completion script, pilot logic, tile paint, or collision edits.
- Labels hidden, not deleted; rollback is one scene export toggle (+ optional script revert).
- Default exports remain `false` outside Taco.

## Rollback plan

1. On Taco `Phase0JRuntimeAuthoringHider`, set `hide_security_author_labels = false` and `hide_security_label_residue = false`.
2. Keep `hide_generated_runtime_marker_labels = true` unless intentionally rolling back Phase 3C too.
3. If reverting script export entirely, revert `Phase0JRuntimeAuthoringHider.gd` and test file to Phase 3C versions.
4. Re-run `tests/mission_authoring/` (expect 155/155 if only scene rollback; 157/157 if script kept).
5. Re-run MainMenu smoke and Taco MCP playtest.

## Known limitations

- `ProofLabel` and `DoorLabel` remain visible at runtime by design (proof/door readability).
- `@Label@` residue under `MarkerRoot/Spawns` is outside `SecurityAuthoringRoot` and still hidden via legacy `target_paths` on Taco, not Phase 3D residue export.
- Security hazard UX still relies partly on placeholder/proof text and beam lines — a future player-facing hazard visual pass may replace debug remnants.
- GdUnit cannot assert programmatic `@Label@` node names (Godot sanitizes `@` in code-created nodes); residue hiding is validated via scene runtime MCP census.

## Recommended next step

**Phase 3E or security UX pass:** Replace remaining proof/placeholder security text with intentional player-facing hazard affordances, then re-audit whether `ProofLabel`/`DoorLabel` can move to editor-only or hider opt-in without losing hazard readability.
