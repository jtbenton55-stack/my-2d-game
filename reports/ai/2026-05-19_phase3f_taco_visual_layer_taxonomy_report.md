# Phase 3F — Taco Visual Layer Taxonomy and Paint-Readiness Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Packet type:** Documentation / formalization only (no scene or gameplay changes in 3F)

## Goal

Convert Phase 3B–3E Taco readability work into reusable visual-layer rules and a concrete paint-readiness checklist for future packets, without repainting the map or changing gameplay.

## Files changed

| File | Change |
|------|--------|
| `docs/TACO_VISUAL_LAYER_TAXONOMY.md` | **Created** — layer taxonomy, z-index bands, style baselines, do-not-touch |
| `docs/TACO_PAINT_READINESS_CHECKLIST.md` | **Created** — pre-edit, validation, paint rules, rollback |
| `reports/ai/2026-05-19_phase3f_taco_visual_layer_taxonomy_report.md` | This report |
| `reports/ai/phase3f_taco_visual_layer_taxonomy_screenshots/*` | Current-state screenshots (see below) |

**Not modified in Phase 3F:** Taco scene, any `.gd` script, `project.godot`, autoloads, tiles, collision.

*(Scene/script `M` from Phase 3B–3E remain in worktree; 3F did not edit them.)*

## Files inspected

Phase 3A–3E reports, `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`, `docs/TACO_BELL_MARKER_LEGEND.md`, `TacoBellIso_Editable_RedesignTest.tscn`, `Phase0JRuntimeAuthoringHider.gd`, `tests/mission_authoring/`.

## Git / branch baseline

- **Branch:** `new-feature-roadmap-branch`
- **Phase 3F adds:** two docs under `docs/`, this report, screenshot folder
- **Unrelated dirty:** prior Phase 3B–3E scene/script changes; unrelated doc/report untracks

## Phase 3B–3E baseline summary

| Phase | Deliverable | Taco runtime state |
|-------|-------------|-------------------|
| 3B | `PlugAndPlayPilot` lane (`z_index=30`) | Visible; search/reward/route affordances |
| 3C | Hide `GeneratedRuntimeMarkerLabels` | Root `visible=false` |
| 3D | Hide security `AuthorLabel` + `@Label@` | 13/13 + 24/24 hidden |
| 3E | `SecurityHazardReadabilityVisuals` + hide `ProofLabel`/`DoorLabel` | Affordances visible; prototype labels hidden |

## Taco visual layer audit (summary)

Full table: `docs/TACO_VISUAL_LAYER_TAXONOMY.md`.

### Gameplay / collision-authoritative

- `LayoutRoot/CollisionBarrierLayer` (barrier authoring → generators)
- `GeneratedRuntimeCollision` (wall cells, boundaries, gate blockers)
- `GeneratedRuntimeInteractables/*` (`Area2D` pickups — bag, manifest, Louis)
- `PlugAndPlayPilot/*` (pilot `Area2D` chain)
- `SecurityAuthoringRoot` author nodes (beam, camera, triggers — logic, not labels)
- `RuntimeSystems` (spawned guards, beams, alarm zones)

### Visual-only (no gameplay from layer itself)

- `LayoutRoot/FloorLayer`, `WallLayer` (blockout paint)
- `SecurityHazardReadabilityVisuals` (Phase 3E)
- `PlugAndPlayPilot` visuals (Phase 3B)
- `GeneratedRuntimeInteractables/RuntimeVisual` polygons
- Runtime `AmbushBeamLine` (spawned visual; trip logic separate)

### Debug / editor / runtime-generated labels

- `GeneratedRuntimeMarkerLabels` — hidden at runtime (3C)
- `MarkerRoot/*` — hidden via hider `target_paths`
- `LayoutRoot/CoverLayer`, `MarkerTileLayer` — hidden at runtime
- `SecurityAuthoringRoot/AuthorLabel`, `@Label@` — hidden (3D)
- `ProofLabel`, `DoorLabel` — hidden (3E); nodes preserved
- `EditorOnlyRoomLabels` — editor-oriented high z

### Player-facing readability layers (preserve)

- `PlugAndPlayPilot` (3B)
- `SecurityHazardReadabilityVisuals` (3E)
- Interactable `RuntimeVisual` polygons + HUD
- Runtime security beam line (IsoMissionBase)

## Existing risks (open after 3F)

| ID | Risk | Severity | Next packet hint |
|----|------|----------|------------------|
| R1 | Manifest marker vs interactable position drift (3A P3A-03) | High | Document in 3G; optional marker move packet |
| R2 | Distant bag/manifest not obvious from spawn camera (3A P3A-04) | High | **3G wayfinding slice** |
| R3 | White blockout only — no interior zone art (3A P3A-05) | Medium | Deferred PVGames paint |
| R4 | `DoorStatusLabel` static — no live lock state (3E) | Low | Optional read-only visual adapter |
| R5 | Duplicate beam labels (3E + IsoMissionBase `SECURITY BEAM`) | Low | Tuning in future hazard polish |

## Implementation / documentation summary

- No new visual manager or root renames.
- Taxonomy uses **actual** `GameplayRoot` children from disk (23 direct children audited).
- Paint checklist ties each future packet to git safety, hider exports, tests, and bookmarks.

## New or updated docs

| Doc | Status |
|-----|--------|
| `docs/TACO_VISUAL_LAYER_TAXONOMY.md` | Created |
| `docs/TACO_PAINT_READINESS_CHECKLIST.md` | Created |

No duplicate pre-existing taxonomy doc found; `docs/TACO_BELL_MARKER_LEGEND.md` remains complementary (marker vocabulary, not layer policy).

## Recommended next smallest visual slice: Phase 3G

**Name:** Taco manifest–code-gate corridor wayfinding (scene-local only)

**Goal:** Add non-colliding floor/signage affordances so players can find `Interactable_CLUE_route_manifest_half` and the code-gate corridor from the south spawn area without full-map tile repaint.

**Exact scene area:** GameplayRoot space roughly from `PlugAndPlayPilot` (~300–800, 120–150) eastward toward manifest interactable (~4128, 624) and adjacent code-gate cluster.

**Likely affected roots:** New sibling under `GameplayRoot`, e.g. `ObjectiveWayfindingVisuals` (name TBD), containing `Line2D`/`Polygon2D`/`Label` only.

**Do-not-touch:**

- All Phase 3F do-not-touch list (see taxonomy doc)
- `SecurityHazardReadabilityVisuals`, `PlugAndPlayPilot` internals (unless fixing overlap only)
- `CollisionBarrierLayer`, `GeneratedRuntimeCollision`
- Hider Taco exports (3C–3E)

**Expected screenshots:** Spawn, pilot lane, manifest corridor before/after, code-gate approach.

**Expected tests:** `tests/mission_authoring/` **159/159** (no new tests if scene-only).

**Playtest:** Pilot chain; manifest interaction; no mission completion via pilot alone.

**Rollback:** Delete new visual root.

**Why lower risk than alternatives:**

| Alternative | Why deferred |
|-------------|--------------|
| Full PVGames floor/wall repaint | Too broad; collision/regen risk |
| Distant bag-only slice | Farther from spawn; harder to validate in one pass |
| Dynamic door status adapter | Requires script; 3E door read already adequate for proof area |
| Re-enable `CoverLayer` | Needs art pipeline decision |

## Screenshots / observations

`reports/ai/phase3f_taco_visual_layer_taxonomy_screenshots/`:

| File | Status |
|------|--------|
| `current_spawn_readability.png` | Reused from Phase 3E spawn capture |
| `current_pilot_lane_preserved.png` | Reused from Phase 3E |
| `current_security_hazard_affordance.png` | Reused from Phase 3E |
| `current_louis_exit_area.png` | Captured (camera at Louis exit) |
| `current_distant_bag_objective_area.png` | Captured (camera at bag interactable) |
| `current_manifest_area.png` | **Failed to save once** (MCP file error); manifest node confirmed at runtime; see MCP census below |

**Runtime census (MCP Taco play):**

```
gen=false, hazard=true, pilot=true, interact=true
h3c/h3d/h3e exports=true
bag/manifest/louis/bridge/completion present
```

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit `tests/mission_authoring/` | **159/159 PASS** |
| Godot LSP | **Not required** (no `.gd` edits in 3F) |
| Godot MCP — Taco scene inspect | Phase 3B–3E roots/exports confirmed on disk |
| Godot MCP — Taco runtime | Census above |
| MainMenu smoke | OK |
| Godot DAP | Not needed |

## Kimi K2.6 MCP usage

**Not used.** Audit and Phase 3A–3E reports provided sufficient evidence.

## Safety confirmation

- Phase 3F changed **docs and reports only**.
- Phase 3B–3E behavior validated unchanged.
- No gameplay, collision, or tile paint in this packet.

## Rollback plan

- Delete or revert `docs/TACO_VISUAL_LAYER_TAXONOMY.md`, `docs/TACO_PAINT_READINESS_CHECKLIST.md`, and this report if not useful.
- No scene/script rollback required for 3F itself.

## Known limitations

- Taxonomy reflects Taco redesign scene only; other missions may differ.
- Marker position drift (manifest) documented but not fixed in 3F.
- One manifest screenshot save failed; use in-editor camera at `(4128, 624)` for 3G before/after.

## Recommended next step

Implement **Phase 3G** manifest–code-gate corridor wayfinding using `docs/TACO_PAINT_READINESS_CHECKLIST.md` and preserve all Phase 3B–3E hider policies.
