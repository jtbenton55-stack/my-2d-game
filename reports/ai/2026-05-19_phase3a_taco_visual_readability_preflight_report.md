# Phase 3A — Taco Visual / Readability Preflight Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Packet type:** Audit / planning only (no repainting, no Phase 3B implementation)

## Goal

Document current Taco visual/readability state, define a repo-aligned visual layer taxonomy, rank issues, and produce a small reversible **Phase 3B** implementation plan so mechanics (including Packet 6B `PlugAndPlayPilot`) can be tested honestly before broader art painting.

## Files inspected

| Area | Paths |
|------|--------|
| Roadmap / blueprint | `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` (Phase 3), `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` (preview colors) |
| Authoring workflow | `docs/ISO_EDITOR_TILE_PALETTE.md`, `docs/ART_READY_LEVEL_WORKFLOW.md`, `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` |
| Taco audits | `docs/reports/taco_bell_marker_inventory.md`, `docs/reports/taco_bell_phase_0ja_visual_labels_baseline.json`, `docs/reports/repo_audit_01/TILEMAP_AND_ASSET_READINESS_AUDIT.md` |
| Packet 6A/6B | `reports/ai/2026-05-19_packet_6a_first_production_adoption_preflight_report.md`, `reports/ai/2026-05-19_packet_6b_taco_south_pilot_adoption_report.md` |
| Scene | `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (read-only audit) |
| Runtime (read-only) | `Phase0JRuntimeAuthoringHider.gd`, `Phase0JMarkerDebugInteractable.gd`, `MechanicAreaBase.gd` |

## Files added / modified

| File | Change |
|------|--------|
| `reports/ai/2026-05-19_phase3a_taco_visual_readability_preflight_report.md` | This report |
| `reports/ai/phase3a_taco_visual_readability_screenshots/*.png` | Seven runtime screenshots (see below) |

**Not modified:** Taco scene (audit-only; scene was not saved via MCP), `project.godot`, autoloads, `IsoMissionBase`, Phase0J/Phase0K scripts, managers, save schema.

**Note:** `git status` still shows `M` on the Taco scene from prior Packet 6B work; Phase 3A did not edit the scene file.

---

## Current Taco visual/readability summary

Taco is in **hybrid blockout** mode: large hand-painted `LayoutRoot` tile layers (white floor, black diamond wall border) plus **188 runtime Phase0J marker labels** (`GeneratedRuntimeMarkerLabels`, `z_index = 4090`) and **Polygon2D interactable icons** (`z_index = 12`). `Phase0JRuntimeAuthoringHider` hides `MarkerRoot` editor labels at runtime, but **does not** hide `GeneratedRuntimeMarkerLabels` or `SecurityAuthoringRoot` author labels.

**Playtest honesty today:**

- Canonical Phase0J interactables use colored polygon icons and floating gray `SCENE_MARKER` debug panels — readable for debugging, noisy for player-facing readability.
- Packet 6B pilot uses small `ColorRect` chips + `HintLabel` text but sits in the **same visual band** as spawn clutter; pilot chain logic works (Jake manual + Packet 6B report) but pilots are easy to miss in screenshots/play unless you know coordinates.
- **Marker vs runtime position drift** exists for key nodes (manifest clue marker vs interactable — see issues).
- Distant objectives (bag, code-gate cluster, security beam) are spatially correct in scene data but **not visually obvious** in default camera framing near spawn.

---

## Screenshot list

| File | Intended focus | Observation |
|------|----------------|-------------|
| `01_player_spawn.png` | Player spawn / start | Blockout floor, dense gray `SCENE_MARKER` labels, HUD OK |
| `02_south_pilot_corridor.png` | PlugAndPlayPilot area | Same framing as spawn in practice; pilot ColorRects not visually distinct in capture |
| `03_louis_exit_area.png` | Louis exit | Camera did not show distinct Louis area in capture (see limitation) |
| `04_manifest_code_gate_area.png` | Manifest / code-gate | Appears same as spawn framing in capture |
| `05_security_ambush_beam_area.png` | Security beam | Appears same as spawn framing in capture |
| `06_bag_recovery_area.png` | Bag recovery | Appears same as spawn framing in capture |
| `07_south_return_canonical_bag.png` | `Interactable_BAG_south_return` | Appears same as spawn framing in capture |

**Screenshot limitation:** Godot MCP `get_game_screenshot` ran after `Camera2D.global_position` assignments, but captured frames for distant targets (bag, manifest, security) still resemble the spawn view. **Node positions below are authoritative** from scene inspection; use in-editor camera pan or `IsoMissionDebugPanel` teleport for Phase 3B before/after shots.

---

## Visual layer taxonomy (Taco / repo-aligned)

Aligned with `ISO_EDITOR_TILE_PALETTE.md`, `ART_READY_LEVEL_WORKFLOW.md`, and `TILEMAP_AND_ASSET_READINESS_AUDIT.md`.

| Layer class | Scene path(s) | Purpose | Runtime visibility | Collision? |
|-------------|---------------|---------|-------------------|------------|
| **Walkable floor (gameplay)** | `GameplayRoot/LayoutRoot/FloorLayer` | Authoritative walkable paint | Visible (blockout white) | Via separate collision systems |
| **Wall / edge read** | `LayoutRoot/WallLayer` | Blocked edge readability | Visible (black diamonds) | Indirect |
| **Cover / occlusion paint** | `LayoutRoot/CoverLayer` | Visual cover hints | Hidden at runtime (`Phase0JRuntimeAuthoringHider`) | No |
| **Collision barrier paint** | `LayoutRoot/CollisionBarrierLayer` | Designer barrier authoring | Visible in editor; baked to colliders | **Yes** (authoring → generators) |
| **Marker tile paint (editor)** | `LayoutRoot/MarkerTileLayer` | Icon vocabulary (`CLUE`, `BAG`, `ROUTE_*`, etc.) | Hidden at runtime | No |
| **Decorative / art (future)** | `ArtRoot/*` (per audit) | PVGames / final art | Partial / mixed | No |
| **Foreground / depth** | `y_sort_enabled` roots, entity sprites, `z_index` on visuals | Iso depth sort | Active | N/A |
| **Runtime interactable icon** | `GeneratedRuntimeInteractables/*/RuntimeVisual` | Player-facing pickup (polygon, `z_index=12`) | Visible | `Area2D` layer 8 |
| **Runtime interactable debug label** | `GeneratedRuntimeMarkerLabels/Label_*` | Phase0J debug (`SCENE_MARKER`, `z_index=4090`) | Visible — **dominates near camera** | No |
| **Plug-and-play pilot visuals** | `PlugAndPlayPilot/*` (`ColorRect`, `HintLabel`) | Packet 6B chain | Visible but low contrast | `Area2D` layer 8 |
| **Authoring / security debug** | `SecurityAuthoringRoot`, `MarkerRoot` (editor), `EditorOnlyRoomLabels` | D6 proofs, patrol/camera authors | MarkerRoot hidden; security labels remain | Proof-only colliders |
| **Objective markers (data)** | `MarkerRoot/Objectives`, `Clues`, etc. | Hybrid placement metadata | Hidden at runtime | No |
| **Route / transition markers** | `MarkerRoot/Routes`, `Transitions`, `RuntimeSystems/RouteAccessPoints` | Route logic | Mixed; labels often hidden | Route barriers separate |

### Interactable highlight style (current vs target)

| Type | Current | Phase 3 target (incremental) |
|------|---------|------------------------------|
| Phase0J pickup | Colored polygon + gray debug panel | Category-colored ring + compact prompt (keep debug behind flag) |
| Plug-and-play pilot | 48×48 ColorRect + Label | Match blueprint colors (search=yellow, reward=gold, route=purple) + floor lane backdrop |
| Security hazard | Author labels + beam authoring nodes | Distinct hazard outline / beam tint (deferred outside spawn slice) |

### Screenshot before/after routine (Phase 3B+)

1. Load `TacoBellIso_Editable_RedesignTest.tscn` (do not save unless intentional).
2. Capture: spawn, pilot lane, Louis exit, manifest interactable, one security node, one cluttered cluster.
3. Apply visual slice; re-capture same camera bookmarks.
4. Run Taco playtest: pilot chain + bag + Louis (no mission logic changes).
5. Attach PNGs to `reports/ai/phase3b_*_screenshots/`.

---

## Collision / readability observations

- **Gameplay collision** is not the same as floor paint: barriers come from `CollisionBarrierLayer`, `Phase0JB2WallCellCollisionGenerator`, boundary shapes, and per-interactable `Area2D` (layer **8**, mask **1** per `MechanicAreaBase`).
- **Pilot `RoutePeekBlocker`** is a local `CollisionShape2D` demo only — does not gate production routes (correct for 6B).
- **Blockout** gives strong edge read (white vs black diamonds) but **no interior zone labeling** (market vs garage vs south corridor).
- **No evidence** in this audit that pilot collision overlaps canonical Phase0J pickups at current coordinates (pilot ~318–760,120–143 vs bag ~16032,368).

---

## Key node positions (GameplayRoot space, from scene)

| Node / area | Position (approx.) |
|-------------|-------------------|
| `player_spawn_main` | (-1088, 32) |
| `PlugAndPlayPilot/PpTacoSouthSearchDrop` | (318, 143) |
| `PlugAndPlayPilot/PpTacoSouthRewardScrap` | (640, 120) |
| `PlugAndPlayPilot/PpTacoSouthRoutePeek` | (760, 120) |
| `Interactable_BAG_south_return` | (see generated interactable label child positions) |
| `LouisExitToken` | (800, 848) |
| `Interactable_CLUE_route_manifest_half` | (4128, 624) |
| `clue_route_manifest_half` (MarkerRoot) | (-242, 103) — **drift** |
| `Interactable_OBJ_bag_recovery` | (16032, 368) |
| `AMBUSH_security_beam` | (9606, 167) |
| `BAG_south_return` (editor placeholder) | (5952, 864) |

---

## Prioritized issues

| ID | Severity | Area | Issue | Likely cause | Proposed fix | 3B? |
|----|----------|------|-------|--------------|--------------|-----|
| P3A-01 | **Critical** | `GeneratedRuntimeMarkerLabels` | Gray `SCENE_MARKER` panels dominate spawn view (`z_index=4090`, 188 labels) | Phase0J-C2 runtime labels not covered by `Phase0JRuntimeAuthoringHider` | Spawn-radius label cull, smaller prompts, or `debug_labels_enabled` export (default on, Taco off) | Defer script; **3B: pilot lane only** |
| P3A-02 | **High** | `PlugAndPlayPilot` | Pilot mechanics visually drowned; tiny ColorRects | No player-facing highlight standard; same z-band as debug labels | Pilot lane backdrop + enlarged rings + blueprint colors + `z_index` lift | **Yes — 3B slice** |
| P3A-03 | **High** | Manifest / code path | Marker `clue_route_manifest_half` at (-242,103) vs interactable (4128,624) | Hybrid marker fallback vs generated runtime reposition | Document + optional editor marker move packet (not 3B) | Defer |
| P3A-04 | **High** | Distant objectives | Bag/manifest/security far from spawn; not readable in default view | Map scale + no zone signage | Zone labels on floor paint later; debug teleport checklist now | Defer paint |
| P3A-05 | **Medium** | Blockout | White floor + black diamonds only; no interior art | Phase 3 not started | PVGames paint per layer rules (Phase 3C+) | Defer |
| P3A-06 | **Medium** | `SecurityAuthoringRoot` | Author labels remain at runtime | Not in hider target list | Hide author labels in play OR editor-only flag | Defer |
| P3A-07 | **Medium** | Scent / loading cluster | Multiple objectives/scents overlap (~-160..225, ±112) | Legacy marker density | Marker cleanup + floor tint zone | Defer |
| P3A-08 | **Low** | `CoverLayer` | Brown cover hidden at runtime | Intentional 0J-A cleanup | Re-enable when art pipeline needs cover read | Defer |
| P3A-09 | **Low** | Pilot `HintLabel` | Reads like debug (`Pilot Search`) | No player-facing typography rules | Short prompts + icon-first | **Yes — 3B** |

---

## Recommended Phase 3B implementation slice

**Slice name:** *South Return pilot lane readability + plug-and-play highlight standard (scene-only)*

**Why this slice**

- Directly supports honest testing of Packet 6B without full-map repaint.
- Reversible (delete/visual children only under `PlugAndPlayPilot`).
- No collision, completion, Phase0J/Phase0K, or autoload changes.
- Visible in one focused playtest from spawn.

**Scope**

1. Under `GameplayRoot/PlugAndPlayPilot` only:
   - Add `PilotLaneBackdrop` (`ColorRect`, wide semi-transparent strip, `z_index = -1`).
   - Per mechanic: add `HighlightRing` (`Polygon2D` or `Line2D` rect) using blueprint colors:
     - Search: yellow (~0.95, 0.85, 0.2)
     - Reward: gold (~0.85, 0.65, 0.2)
     - Route: purple (~0.75, 0.45, 0.95)
   - Enlarge existing `ColorRect` visuals (~64×40).
   - Set `PlugAndPlayPilot` `z_index = 30` (above interactable polygons, below HUD).
   - Restyle `HintLabel` fonts/colors for player-facing prompts (no gray debug panel style).
2. Add `reports/ai/phase3b_taco_pilot_lane_screenshots/` before/after captures.
3. **Do not** change `GeneratedRuntimeMarkerLabels` in 3B (separate packet — needs script or bulk label policy).

**Files likely to change (3B)**

- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (visual nodes only under `PlugAndPlayPilot`)
- `reports/ai/2026-05-19_phase3b_taco_pilot_lane_readability_report.md` (new)
- `reports/ai/phase3b_taco_pilot_lane_screenshots/*`

**Explicit do-not-touch (3B)**

- `IsoMissionBase`, Phase0J/Phase0K scripts, `project.godot`, autoloads
- `GeneratedRuntimeInteractables` canonical nodes (bag, manifest, Louis)
- Collision layers / barrier tiles / `CollisionBarrierLayer`
- Mission completion, flags, bridges (except existing pilot config)
- Full-map PVGames repaint, `MarkerTileLayer` mass edits, route manager

**Validation (3B)**

- GdUnit `tests/mission_authoring/` still **150/150**
- Taco play: pilot chain + bag + Louis unchanged logically
- Screenshots: spawn + pilot lane before/after
- MainMenu smoke

**Rollback**

- Remove `PilotLaneBackdrop`, `HighlightRing`, and label/visual tweaks under `PlugAndPlayPilot`; reset `z_index`.

---

## Tests / checks run (Phase 3A)

| Check | Result |
|-------|--------|
| GdUnit4 `res://tests/mission_authoring/` | **150/150 PASS** (report_30) |
| Godot LSP | Not applicable (no `.gd` edits) |
| Godot MCP — open Taco | OK |
| Godot MCP — play Taco | OK; runtime labels visible |
| Godot MCP — play MainMenu | OK (`MainMenu`) |
| Godot MCP — save Taco | **Not called** (audit safety) |
| Godot DAP | Not needed |

---

## Kimi K2.6 MCP usage

| Call | Result |
|------|--------|
| `ask_kimi_k2_6` regression review (sanitized summary) | Partial response received |

**Adopted:** Prioritize spawn-adjacent pilot lane; keep 3B scene-only/reversible; treat `GeneratedRuntimeMarkerLabels` as separate follow-up; coordinate mismatch needs dedicated fix packet.

**Rejected:** Full-map repaint as 3B; broad label deletion without a toggle policy.

**Secrets:** No credentials, `.env`, or personal files sent.

---

## Safety confirmation

- No production scene file edits in Phase 3A.
- No `project.godot`, autoload, `IsoMissionBase`, Phase0J/Phase0K, manager, or save schema changes.
- Screenshots contain only game viewport + HUD (no desktop/personal UI).
- Taco scene `M` status is from Packet 6B, not this packet.

---

## Known risks

- Fixing only pilot visuals leaves **global debug label clutter** (P3A-01) — acceptable for 3B if documented.
- Marker/runtime drift (P3A-03) can mislead designers using `MarkerRoot` alone.
- Camera-based screenshot automation may not frame distant nodes reliably; manual camera bookmarks recommended for 3B.

---

## Recommended next step

Execute **Phase 3B** using the prompt draft below, then Jake playtests spawn → pilot chain → Louis/bag in one pass with before/after screenshots.

---

## Phase 3B implementation prompt draft

```markdown
PACKET: Phase 3B — Taco South Return Pilot Lane Readability (scene-only)

GOAL:
Improve visual honesty for Packet 6B plug-and-play pilot testing in Taco without
full-map repaint, collision changes, or mission logic changes.

AUTHORIZED FILES:
- scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn (visual children under PlugAndPlayPilot only)
- reports/ai/2026-05-19_phase3b_taco_pilot_lane_readability_report.md
- reports/ai/phase3b_taco_pilot_lane_screenshots/*

DO NOT TOUCH:
- project.godot, autoloads, IsoMissionBase, Phase0J/Phase0K scripts
- GeneratedRuntimeInteractables canonical nodes (bag, manifest, Louis)
- CollisionBarrierLayer, wall/floor tile paint, RouteAccessPoints, completion controllers
- MissionInteractionBridge / pilot logic / flags / requirements

TARGET NODES (exact):
GameplayRoot/PlugAndPlayPilot
  PilotLaneBackdrop (NEW ColorRect)
  PpTacoSouthSearchDrop — add HighlightRing, enlarge visuals, restyle HintLabel
  PpTacoSouthRewardScrap — same (gold)
  PpTacoSouthRoutePeek — same (purple)
Set PlugAndPlayPilot z_index = 30

VISUAL RULES:
- Use PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT preview colors
- Player-facing labels only (no gray SCENE_MARKER style)
- No new scripts unless absolutely required; prefer scene nodes

VALIDATION:
- GdUnit mission_authoring 150/150
- Taco play: pilot chain + canonical bag/Louis non-regression
- Before/after screenshots at spawn and pilot lane
- MainMenu smoke
- Do NOT call MCP save_scene unless editor has reloaded scene from disk

ROLLBACK:
Delete PilotLaneBackdrop, HighlightRing nodes, revert label/visual/z_index under PlugAndPlayPilot.
```
