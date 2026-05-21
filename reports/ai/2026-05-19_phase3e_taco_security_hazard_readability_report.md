# Phase 3E — Taco Security Hazard Player-Facing Readability Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Packet type:** Scene-local security hazard readability (follows Phase 3C/3D; no security gameplay changes)

## Goal

Replace Taco’s reliance on proof/prototype debug text (`ProofLabel`, `DoorLabel`) for security hazard readability with intentional player-facing affordances, while preserving Phase 3C/3D label hiding, security runtime, pilot gameplay, and canonical Phase0J/Phase0K flow.

## Files changed

| File | Change |
|------|--------|
| `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` | Added `GameplayRoot/SecurityHazardReadabilityVisuals` subtree; Taco hider `hide_security_proof_and_door_labels = true` |
| `src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd` | Added `hide_security_proof_and_door_labels` export (default `false`) |
| `tests/mission_authoring/Phase0JRuntimeAuthoringHiderTest.gd` | +2 tests (9 total in suite file) |
| `reports/ai/2026-05-19_phase3e_taco_security_hazard_readability_report.md` | This report |
| `reports/ai/phase3e_taco_security_hazard_readability_screenshots/*` | Before/after runtime screenshots |

**Not modified:** `project.godot`, autoloads, `IsoMissionBase`, security runtime/author scripts, Phase0J/Phase0K bridge/completion scripts, pilot logic, tile paint, collision layers.

## Files inspected

| Area | Paths |
|------|--------|
| Prior phases | `reports/ai/2026-05-19_phase3a_*.md` through `phase3d_*.md` |
| Roadmap | `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` (security hazard visibility style) |
| Scene | `TacoBellIso_Editable_RedesignTest.tscn` |
| Hider | `Phase0JRuntimeAuthoringHider.gd` |
| Security | `SecurityAuthoringRoot.gd`, `MissionAuthoringRuntimeBuilder.gd`, `SecurityBeamAuthor.gd`, author scripts (read-only) |
| Runtime beam | `IsoMissionBase.gd` `_attach_fix7_ambush_beam_visual()` (read-only) |

## Git / branch baseline

- **Branch:** `new-feature-roadmap-branch`
- **Phase 3E modifies:** Taco scene (visual root + hider export), hider script, hider tests, report/screenshots
- **Pre-existing dirty worktree:** unrelated docs/reports/deleted report artifacts (untouched)

## Security hazard readability audit

### Hazard / proof area (Taco)

| Node | Path | Role |
|------|------|------|
| Beam author | `GameplayRoot/SecurityAuthoringRoot/AMBUSH_security_beam` | Author at `(9606, 167)`, `visual_height = 475` |
| Runtime beam | `GameplayRoot/RuntimeSystems/SecurityBeam_Ambush_RightHallway/AmbushBeamLine` | Spawned by `IsoMissionBase` (red `Line2D`, z_index ~2600) |
| Proof marker | `.../D6_05_ProofMarker` | Effect-proof anchor at `(8990, 191)` |
| Proof text | `.../D6_05_ProofMarker/ProofLabel` | **Prototype** text `"D6-05 effect proof"` |
| Door proof | `.../TestDoorLockProof` | Door-lock test at `(9278, 383)` |
| Door target | `.../D6_05A_TestDoorLock_Target` | `StaticBody2D`, collision disabled for test |
| Door text | `.../DoorLabel` | **Prototype** text `"D6-05A TEST LOCK DOOR [UNLOCKED]"` |
| Door visual | `.../DoorVisual` | Green `ColorRect` (already player-visible geometry) |

### After Phase 3D (before 3E affordances)

- `AuthorLabel` / `@Label@` residue: hidden.
- `ProofLabel` / `DoorLabel`: still visible (prototype strings).
- Beam line + runtime `"SECURITY BEAM"` label from `IsoMissionBase`: visible.
- Hazard readable but relied on debug/proof strings for zone/door context.

### Classification

| Label | Type | Phase 3E action |
|-------|------|-----------------|
| `ProofLabel` | Proof/debug prototype | Hidden at runtime after replacement |
| `DoorLabel` | Prototype status string | Hidden at runtime after replacement |
| New `AmbushBeamWarningLabel` | Intentional player-facing | Visible |
| New `ProofZoneLabel` | Intentional player-facing | Visible |
| New `DoorStatusLabel` | Intentional player-facing | Visible |

## Implementation path chosen

**Outcome C (smallest safe):** Add scene-local player-facing affordances, then hide `ProofLabel` and `DoorLabel` via new hider export `hide_security_proof_and_door_labels = true` on Taco only.

Rationale: Runtime beam geometry is strong; supplemental band/ticks/labels at z_index 18 improve scanability without duplicating the high-z runtime beam. Proof/door prototype strings are replaced by styled labels and shapes, then hidden at runtime (nodes not deleted).

## Visual affordances added

Root: `GameplayRoot/SecurityHazardReadabilityVisuals` (`z_index = 18`, below pilot `30`, above floor; non-colliding).

| Child | Type | Position / notes |
|-------|------|------------------|
| `AmbushBeamReadability` | Node2D | `(9606, 167)` aligned to beam author |
| `AmbushBeamHazardBand` | ColorRect | Translucent pink vertical band, h≈475 |
| `AmbushBeamTickTop` / `AmbushBeamTickBottom` | Line2D | Endpoint warning ticks |
| `AmbushBeamWarningIcon` | Polygon2D | Red warning triangle |
| `AmbushBeamWarningLabel` | Label | `"ALARM BEAM"` — outlined pink player text |
| `ProofZoneReadability` | Node2D | `(8990, 191)` |
| `ProofZoneBackdrop` | Polygon2D | Purple translucent zone tint |
| `ProofZoneLabel` | Label | `"Security Test Zone"` |
| `DoorReadability` | Node2D | `(9284, 102)`, rotation matches door |
| `DoorStatusRing` | Line2D | Green door highlight ring |
| `DoorStatusLabel` | Label | `"TEST DOOR"` |

## Exact z-index / layering

| Layer | z_index |
|-------|---------|
| `SecurityHazardReadabilityVisuals` | 18 |
| `PlugAndPlayPilot` | 30 (unchanged) |
| `RuntimeSystems/.../AmbushBeamLine` | ~2600 (runtime, unchanged) |
| Hidden debug labels | -4096 via hider |

## ProofLabel / DoorLabel decision

| Label | Runtime visibility | Notes |
|-------|-------------------|--------|
| `ProofLabel` | **Hidden** | Replaced by `ProofZoneLabel` + backdrop |
| `DoorLabel` | **Hidden** | Replaced by `DoorStatusLabel` + ring + existing `DoorVisual` |

Nodes remain in scene for editor/recovery; hider sets `visible = false` only.

## Phase 3C / 3D preservation

| Policy | Taco runtime |
|--------|--------------|
| `hide_generated_runtime_marker_labels` | true — `GeneratedRuntimeMarkerLabels` hidden |
| `hide_security_author_labels` | true — 13/13 `AuthorLabel` hidden |
| `hide_security_label_residue` | true — 24/24 `@Label@` hidden |
| `hide_security_proof_and_door_labels` | true — `ProofLabel` / `DoorLabel` hidden |

## Security hazard readability result

| Check | Result |
|-------|--------|
| `SecurityHazardReadabilityVisuals.visible` | **true** |
| `AmbushBeamWarningLabel.visible` | **true** |
| `AmbushBeamLine.visible` | **true** |
| No prototype proof/door strings at runtime | **confirmed** |
| Affordances distinct from gray debug panels | **yes** (pink/purple/green styled) |

## Pilot gameplay preservation

| Check | Result |
|-------|--------|
| `PlugAndPlayPilot.visible` | **true** |
| `GeneratedRuntimeInteractables.visible` | **true** |
| Pilot lane not obscured by hazard visuals | **confirmed** (separate map region; z_index below pilot) |

## Canonical Taco non-regression

| Node | Present |
|------|---------|
| `Interactable_OBJ_bag_recovery` | Yes |
| `Interactable_CLUE_route_manifest_half` | Yes |
| `LouisExitToken` | Yes |
| `Phase0JInteractionBridge` | Yes (`RuntimeHelpers`) |
| `Phase0KMissionCompletionController` | Yes |
| `include_legacy_candidates` | **false** |

## Tests / checks run

| Check | Result |
|-------|--------|
| `Phase0JRuntimeAuthoringHiderTest.gd` | **9/9 PASS** |
| `tests/mission_authoring/` (full) | **159/159 PASS** (157 + 2 Phase 3E tests) |
| Godot LSP (changed `.gd`) | **Clean** |
| MainMenu `res://scenes/MainMenu.tscn` | Loads OK |
| Godot MCP Pro Taco runtime | Label census + visibility per above |
| Godot DAP | **Not needed** |

## Screenshots

`reports/ai/phase3e_taco_security_hazard_readability_screenshots/`:

- `before_security_hazard_placeholder_text.png` (from Phase 3D era)
- `before_security_hazard_area_runtime.png`
- `after_security_hazard_affordance.png`
- `after_security_hazard_without_debug_label_reliance.png`
- `after_spawn_phase3c3d3e_readability.png`
- `after_pilot_lane_still_readable.png`

## Kimi K2.6 MCP usage

**Not used.** Local audit and runtime validation were sufficient.

## Safety confirmation

- Scene-local visuals only; no collision/Area2D added.
- No security gameplay, router, or author logic changes.
- Labels hidden, not deleted; defaults outside Taco unchanged.
- Rollback: remove visual root and set `hide_security_proof_and_door_labels = false`.

## Rollback plan

1. Delete or hide `GameplayRoot/SecurityHazardReadabilityVisuals`.
2. Set `hide_security_proof_and_door_labels = false` on Taco hider (keep 3C/3D exports unless rolling those back).
3. Revert hider script export + tests if unused elsewhere.
4. Re-run `tests/mission_authoring/` and Taco/MainMenu smoke.

## Known limitations

- `DoorStatusLabel` is static `"TEST DOOR"` (does not reflect live lock state; runtime door state still driven by security authors).
- Runtime `IsoMissionBase` still adds `"SECURITY BEAM"` label on beam host (high z); may overlap `AmbushBeamWarningLabel` in some camera frames — acceptable for current test slice.
- Affordances are coordinate-baked to current Taco proof layout; moving authors requires moving the visual root children.

## Recommended next step

**Phase 3F / broader visual layer pass:** Apply roadmap layer taxonomy to decorative props and foreground depth; optionally sync door status label with lock state via a tiny read-only visual adapter (still no gameplay changes).
