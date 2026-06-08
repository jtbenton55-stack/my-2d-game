# Phase 3G — Taco Manifest–Code-Gate Corridor Wayfinding Report

**Date:** 2026-05-21
**Branch:** `new-feature-roadmap-branch`
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
**Packet type:** Scene-local visual-only wayfinding slice (no gameplay logic)

## 1. Goal

Add a small, reversible, player-facing wayfinding layer from the south `PlugAndPlayPilot` area toward the canonical manifest interactable (`Interactable_CLUE_route_manifest_half`) and the adjacent code-gate corridor, without changing mission logic, collision, interactables, pilot exports, hider exports, or project settings.

## 2. Branch and baseline git status

**Before edits (recorded):**

```
## new-feature-roadmap-branch...origin/new-feature-roadmap-branch
 M addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd
 M docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md
 M project.godot
 M scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn
 M scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn
 M src/tools/editor/PVGamesObjectPaletteDockValidator.gd
?? addons/mission_paint_dock/
?? (several reports)
```

**After Phase 3G (this packet):**

- **Changed by this packet:** `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (adds `ObjectiveWayfindingVisuals` block only among intentional 3G edits), this report, screenshot folder.
- **Not modified by this packet:** `project.godot`, any `.gd` script, autoloads, TileSets, mission definitions, canonical interactables, collision layers, pilot/hider/bridge exports.
- **Pre-existing dirty state:** Taco `.tscn` already contained unrelated edits (security label duplicates, PVGames ext_resource churn, etc.). Phase 3G did **not** revert those; only appended the visual root via editor script + save.

## 3. Files inspected

| File | Purpose |
|------|---------|
| `docs/Prompt_Improvement.md` | Packet workflow reference |
| `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` | Phase 3 visual pipeline |
| `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` | Phase 3 authoring pipeline |
| `docs/TACO_VISUAL_LAYER_TAXONOMY.md` | z-index bands, do-not-touch |
| `docs/TACO_PAINT_READINESS_CHECKLIST.md` | Paint safety checklist |
| `reports/ai/2026-05-19_phase3f_taco_visual_layer_taxonomy_report.md` | R1/R2 risks, 3G recommendation |
| `reports/ai/2026-05-21_mission_paint_dock_v1_report.md` | Dock context |
| `reports/ai/2026-05-21_mission_paint_dock_collision_erase_fix_report.md` | Dock erase fix |
| `reports/ai/2026-05-21_pvgames_object_palette_visible_bounds_spacing_report.md` | Palette context |
| `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` | Target scene |

## 4. Files changed

| File | Change |
|------|--------|
| `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` | Added `GameplayRoot/ObjectiveWayfindingVisuals` (~143 lines of visual nodes) |
| `reports/ai/2026-05-21_phase3g_taco_manifest_code_gate_wayfinding_report.md` | This report |
| `reports/ai/phase3g_taco_manifest_code_gate_wayfinding_screenshots/*.png` | Runtime captures (7 files) |

## 5. Scene roots audited (pre/post)

| Root | Finding |
|------|---------|
| `LayoutRoot/FloorLayer` | Present; not edited |
| `LayoutRoot/WallLayer` | Present; not edited |
| `LayoutRoot/CoverLayer` | Present; not edited |
| `LayoutRoot/CollisionBarrierLayer` | Present; not edited |
| `LayoutRoot/MarkerTileLayer` | Present; not edited |
| `GeneratedRuntimeInteractables` | Present; canonical interactables unchanged |
| `Interactable_CLUE_route_manifest_half` | `(4128, 624)` — wayfinding terminus |
| `Interactable_OBJ_bag_recovery` | `(16032, 368)` — unchanged |
| `LouisExitToken` | `(800, 848)` — unchanged |
| `PlugAndPlayPilot` | `z_index=30`; south search `(318, 143)` — unchanged |
| `SecurityHazardReadabilityVisuals` | `z_index=18`; ambush/proof/door affordances — unchanged |
| `Phase0JRuntimeAuthoringHider` | All four hide exports still `true` |
| `Phase0JInteractionBridge` | Present |
| `Phase0KMissionCompletionController` | Present |
| `MissionInteractionBridge` | `include_legacy_candidates = false` |
| `GeneratedRuntimeCollision` | Present; `BLOCK_code_gate` at `(8384, 64)` |

## 6. Ownership / classification of changed nodes

| Path | Type | Classification |
|------|------|----------------|
| `GameplayRoot/ObjectiveWayfindingVisuals` | `Node2D` | Visual-only root (`z_index=24`) |
| `.../ManifestCorridorRoute` | `Node2D` | Gold manifest trail group |
| `.../ManifestTrail`, `ManifestTrailAccent` | `Line2D` | Segmented path |
| `.../Chevron_0`–`Chevron_5` | `Polygon2D` | Floor arrows |
| `.../ManifestApproachRing` | `Polygon2D` | Approach ring at interactable |
| `.../ManifestApproachLabel` | `Label` | `MANIFEST` |
| `.../CorridorForkMarker`, `ForkHintLabel` | `Polygon2D`, `Label` | Fork at `(3600, 520)` |
| `.../CodeGateCorridorRoute` | `Node2D` | Purple/cyan code-gate branch |
| `.../CodeGateTrail`, `CodeGateTrailAccent` | `Line2D` | Code-gate path |
| `.../GateChevron_0`–`GateChevron_4` | `Polygon2D` | Directional chevrons |
| `.../CodeGateApproachRing` | `Polygon2D` | Ring at `(8384, 64)` |
| `.../CodeGateApproachLabel` | `Label` | `CODE GATE` |

No scripts, `Area2D`, `StaticBody2D`, or `CollisionShape2D` under this root.

## 7. Implementation path and rationale

**Chosen:** Godot MCP Pro `execute_editor_script` to build a dedicated `ObjectiveWayfindingVisuals` root, then `save_scene`.

**Why:** Matches Phase 3F taxonomy (new visual-only sibling under `GameplayRoot`), keeps rollback to a single subtree delete, avoids Mission Paint Dock / tile edits, and uses inspected world positions for the canonical interactable and code-gate cluster.

**Not used:** TileMapLayer paint, marker moves, interactable repositioning, script-driven runtime spawns.

## 8. Exact visual root / node paths added

See section 6. Inserted in scene tree after `SecurityHazardReadabilityVisuals`, before disabled gameplay tile layers.

## 9. z-index and visibility

| Node | z_index | visible (runtime) |
|------|---------|-------------------|
| `ObjectiveWayfindingVisuals` | 24 | `true` |
| `SecurityHazardReadabilityVisuals` | 18 | `true` |
| `PlugAndPlayPilot` | 30 | `true` (above wayfinding) |

Wayfinding sits above floor/security hazard bands (18) and below pilot lane (30), per taxonomy band 22–28 guidance.

## 10. Systems preserved

- Phase0J/0K runtime bridges and completion controller
- Generated runtime interactables and collision
- PlugAndPlayPilot requirement/effect chain (not exercised end-to-end in automation)
- `Phase0JRuntimeAuthoringHider` label-hiding policy
- `SecurityHazardReadabilityVisuals` Phase 3E affordances
- Mission Paint Dock / collision barrier data (no dock edits)
- Autoloads and `project.godot` (not touched by this packet)

## 11. Do-not-touch confirmations

| Item | Status |
|------|--------|
| `project.godot` | Not modified by Phase 3G |
| Scripts (`.gd`) | None changed by Phase 3G |
| `Interactable_OBJ_bag_recovery` | Unchanged |
| `Interactable_CLUE_route_manifest_half` | Unchanged (position `4128, 624`) |
| `LouisExitToken` | Unchanged |
| `GeneratedRuntimeCollision` / `CollisionBarrierLayer` | Unchanged |
| `PlugAndPlayPilot` exports/children | Unchanged |
| `Phase0JRuntimeAuthoringHider` exports | All four still `true` |
| `MissionInteractionBridge.include_legacy_candidates` | Still `false` |

## 12. Marker / interactable drift (documented, not fixed)

| Source | Position (GameplayRoot local) | Notes |
|--------|-------------------------------|-------|
| **Canonical interactable** `Interactable_CLUE_route_manifest_half` | `(4128, 624)` | Wayfinding terminus — **authoritative for players** |
| Authoring marker `MarkerRoot/Clues/clue_route_manifest_half` | `(-242, 103)` | Large drift — hidden at runtime via hider |
| Manifest metadata `runtime_spawn_position` | `(1344, -64)` | Stale vs final interactable |
| Code-gate marker `code_gate_garage_office` | `(8320, 64)` | Near `BLOCK_code_gate` / approach ring |
| Code-gate clue `Interactable_CLUE_code_gate_nearby` | `(8800, 400)` | Branch endpoint on purple/cyan trail |

**R1 confirmed:** Do not guide to the clue marker tile; gold trail ends at the real interactable.

## 13. Tests / checks run

| Check | Result |
|-------|--------|
| Git status before/after | Recorded; 3G adds scene block + report + screenshots |
| Scene diff scope | Phase 3G block is visual-only; file has additional pre-existing dirty hunks |
| `project.godot` | Not modified by 3G (still dirty from prior plugin enablement) |
| Scripts | No `.gd` changes from 3G |
| Godot MCP editor validation | `bad_nodes=[]`, all protected paths exist, hider/bridge exports OK |
| Taco runtime play (`play_scene`) | Scene loads; wayfinding `visible=true`, `z_index=24` |
| Runtime visibility policy | `GeneratedRuntimeMarkerLabels.visible=false`; security/pilot/interactables `true` |
| MainMenu smoke | `play_scene` → `res://scenes/MainMenu.tscn` loads (path confirmed via `execute_game_script`) |
| GdUnit4 `tests/mission_authoring/` | **Not run** — Godot CLI not on PATH in agent shell |
| Godot LSP | **N/A** — no script edits |
| Godot DAP | **Not used** — no new runtime faults attributable to 3G |
| Pilot chain / `delivery_bag_collected` | **Not automated** — would need scripted input + mission state read |

## 14. Godot MCP Pro scene / runtime validation

**Editor (post-save):**

- `ObjectiveWayfindingVisuals` exists under `GameplayRoot`
- No `Area2D` / `StaticBody2D` / `CollisionShape2D` / scripts under wayfinding root
- Protected nodes census: all `true`

**Runtime (Taco play):**

```json
{
  "ow_exists": true,
  "ow_visible": true,
  "ow_z": 24,
  "marker_labels_visible": false,
  "security_visible": true,
  "pilot_visible": true,
  "interactables_visible": true,
  "manifest_pos": "(2818.0, 793.0)",
  "hider_exports": { "hide_generated_runtime_marker_labels": true, ... }
}
```

No new Phase 3G-specific errors in editor log; pre-existing GDScript warnings only.

## 15. GdUnit4

**Not run.** Godot executable was not available on PATH for headless `gdunit` invocation. Risk: low for a scene-only visual subtree with no script changes.

## 16. Godot LSP

**N/A** — no `.gd` files modified in this packet.

## 17. MainMenu smoke

**Pass (limited):** `play_scene` with `res://scenes/MainMenu.tscn`; live scene path reported as `res://scenes/MainMenu.tscn`. No parse/autoload failure observed. Full menu navigation not exercised.

## 18. Godot DAP

**Not used.** No stack traces, null refs, or signal bugs observed during Taco/MainMenu MCP play.

## 19. Screenshots

Folder: `reports/ai/phase3g_taco_manifest_code_gate_wayfinding_screenshots/`

| File | Camera focus (GameplayRoot-local) |
|------|-----------------------------------|
| `phase3g_00_default_spawn.png` | Default spawn view |
| `phase3g_01_pilot_lane.png` | `(550, 125)` pilot lane |
| `phase3g_02_mid_trail.png` | `(2200, 300)` mid corridor |
| `phase3g_03_manifest_approach.png` | `(4128, 624)` manifest |
| `phase3g_04_code_gate_corridor.png` | `(8800, 350)` code gate |
| `phase3g_05_security_ambush_beam.png` | `(9606, 167)` ambush beam |
| `phase3g_06_louis_exit.png` | `(800, 848)` Louis exit |

**Note:** White blockout floor limits contrast; trails are subtle by design (moderate alpha). Jake playtest should confirm in-game readability at player zoom.

## 20. Kimi K2.6 MCP

**Not used.** Visual-risk plan was straightforward from Phase 3F docs; no advisory review requested.

## 21. Safety confirmation

- Visual-only subtree; easy delete rollback
- No gameplay, collision, mission, autoload, or `project.godot` changes from this packet
- Guides to canonical interactable position, not stale marker
- z-index respects pilot (30) > wayfinding (24) > security hazard (18)

## 22. Rollback plan

1. Delete node `GameplayRoot/ObjectiveWayfindingVisuals` in `TacoBellIso_Editable_RedesignTest.tscn` (or revert only that hunks).
2. Optionally delete this report and `reports/ai/phase3g_taco_manifest_code_gate_wayfinding_screenshots/`.
3. No script, TileSet, hider, or collision rollback required.

## 23. Known limitations

- Trails are geometric overlays on white blockout; may be faint until zone art (R3) lands.
- Fork hint label is text-only; not localized.
- Code-gate branch includes clue at `(8800, 400)` as secondary endpoint; primary gate affordance is `(8384, 64)` ring/label.
- Full pilot-chain and mission-completion regression not automated here.
- Taco `.tscn` worktree still carries unrelated dirty hunks outside 3G.

## 24. Recommended next step

**Phase 3H (suggested):** Jake playtest walk south pilot → manifest → code gate; tune trail alpha/width from screenshots. Then either:

- Small **bag-recovery / Louis-exit** wayfinding slice (same pattern), or
- Deferred **PVGames floor art** on safe `LayoutRoot` layers per paint checklist (not full-map repaint).

Optional follow-up packet: marker–interactable realignment for `clue_route_manifest_half` (separate from wayfinding; fixes R1 at source).
