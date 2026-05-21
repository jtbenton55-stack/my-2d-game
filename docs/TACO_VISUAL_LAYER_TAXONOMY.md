# Taco Visual Layer Taxonomy

**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Last validated:** 2026-05-19 (Phase 3F)  
**Branch baseline:** `new-feature-roadmap-branch` with Phase 3B–3E applied

## Purpose

Formalize which Taco scene layers are gameplay-authoritative, visual-only, debug/editor-only, or runtime-generated so future visual packets can paint or add affordances without breaking collision, Phase0J/Phase0K flow, or plug-and-play pilots.

## Scope

- Production Taco redesign test scene only (`TacoBellIso_Editable_RedesignTest.tscn`).
- Documents current repo state after Phase 3B (pilot lane), 3C (generated marker hide), 3D (security author-label hide), 3E (security hazard affordances).
- Does **not** define a new visual manager or rename production roots.

## Phase 3B–3E baseline (must preserve)

| Phase | Root / policy | Runtime behavior |
|-------|----------------|------------------|
| **3B** | `GameplayRoot/PlugAndPlayPilot` (`z_index = 30`) | Pilot lane backdrop, rings, hints — **visible** |
| **3C** | `Phase0JRuntimeAuthoringHider.hide_generated_runtime_marker_labels = true` | `GeneratedRuntimeMarkerLabels` — **hidden** |
| **3D** | `hide_security_author_labels` + `hide_security_label_residue` | Security `AuthorLabel` / `@Label@` — **hidden** |
| **3E** | `GameplayRoot/SecurityHazardReadabilityVisuals` (`z_index = 18`) | Player hazard affordances — **visible** |
| **3E** | `hide_security_proof_and_door_labels = true` | `ProofLabel` / `DoorLabel` — **hidden** (nodes remain in scene) |

Taco hider path: `GameplayRoot/RuntimeHelpers/Phase0JRuntimeAuthoringHider`.

## Layer taxonomy table

| ID | Layer class | Scene path | Purpose | Baked / runtime | Editor visibility | Runtime visibility | Gameplay / collision | Player-facing | Safe to paint/edit | Phase 3 notes |
|----|-------------|------------|---------|-----------------|-------------------|--------------------|----------------------|---------------|-------------------|---------------|
| L1 | Walkable floor (layout) | `GameplayRoot/LayoutRoot/FloorLayer` | Authoritative walkable tile paint | Scene-baked | Visible | Visible (white blockout) | Indirect (walkability via collision systems) | Yes | **Paint OK** — do not move nodes | No tile edits in 3B–3E packets |
| L2 | Wall / edge read | `LayoutRoot/WallLayer` | Blocked edge readability | Scene-baked | Visible | Visible | Indirect | Yes | **Paint OK** | Black diamond blockout |
| L3 | Cover paint | `LayoutRoot/CoverLayer` | Cover/occlusion hints | Scene-baked | Visible | **Hidden** (hider `target_paths`) | No | No | Paint OK; re-enable read later | Intentionally hidden at runtime |
| L4 | Collision barrier paint | `LayoutRoot/CollisionBarrierLayer` | Designer barrier authoring | Scene-baked | Visible | Visible in editor; drives generators | **Authoritative** | No | **Edit with extreme care** — affects `GeneratedRuntimeCollision` | Never disable without audit |
| L5 | Marker tile paint | `LayoutRoot/MarkerTileLayer` | Editor icon vocabulary (`CLUE`, `BAG`, etc.) | Scene-baked | Visible | **Hidden** (hider) | No | No | Editor-only paint | Hidden at runtime |
| L6 | Debug label tiles | `LayoutRoot/DebugLabelLayer` | Tile-based debug labels | Scene-baked | Visible | Typically editor | No | No | Defer | |
| L7 | Legacy gameplay tile layers | `GameplayFloorLayer`, `GameplayCollisionLayer`, `GameplayMarkersLayer` | Disabled legacy layers | Scene-baked | **enabled = false** | Off | No | No | Do not enable without audit | |
| L8 | Layout container | `GameplayRoot/LayoutRoot` (`z_index = 20`) | Groups L1–L6 | Scene-baked | Visible | Mixed | No | Partial | Move/paint children only | |
| L9 | Runtime wall collision | `GeneratedRuntimeCollision/WallCollision` | Wall cell `StaticBody2D` from `WallLayer` | **Runtime-generated** | N/A | Active | **Authoritative** | No | **Do not hand-edit** bodies | Regenerated from tiles |
| L10 | Runtime boundaries / gates | `GeneratedRuntimeCollision/BoundaryCollision`, `GateBlockers` | Map bounds, code gate | Mixed | N/A | Active | **Authoritative** | No | **Do not move** without route audit | Includes `BLOCK_code_gate` |
| L11 | Legacy boundary colliders | `BoundaryColliders/*` | Old invisible walls | Scene-baked | Hidden / disabled | Low use | Legacy | No | Do not re-enable blindly | `collision_layer = 0` |
| L12 | Runtime interactables | `GeneratedRuntimeInteractables/*` | Phase0J pickups (`Area2D`, polygon icons) | Scene-baked nodes | Visible | **Visible** | **Yes** (`Area2D` layer 8) | Yes | Visual-only tweaks to `RuntimeVisual` — **not** logic | Canonical: bag, manifest, Louis |
| L13 | Runtime marker labels | `GeneratedRuntimeMarkerLabels` (~188 children) | Phase0J `SCENE_MARKER` debug panels | Scene-baked | Visible | **Hidden** (3C) | No | Was debug | Do not re-enable on Taco without decision | `z_index` 4090 in scene file |
| L14 | Marker debug interactables | `GeneratedRuntimeMarkerDebugInteractables` | Debug `Area2D` for markers | Scene-baked | Visible | Editor/debug | Optional | No | Defer | |
| L15 | Marker metadata roots | `MarkerRoot/{Spawns,Objectives,Clues,...}` | Hybrid placement data | Scene-baked | Visible | **Hidden** (hider `target_paths`) | No | No | **Do not delete** — data for generators | Manifest marker drift documented (3A) |
| L16 | Security authoring | `SecurityAuthoringRoot` | D6 security proofs, authors | Scene-baked | Visible | Authors active; labels hidden | **Yes** (authors → runtime) | Partial | **Do not delete** authors | Proof door collision disabled for test |
| L17 | Security hazard readability | `SecurityHazardReadabilityVisuals` (`z_index = 18`) | Phase 3E player affordances | Scene-baked | Visible | **Visible** | No | **Yes** | Edit visuals only under this root | Pink/purple/green styled labels |
| L18 | Plug-and-play pilot | `PlugAndPlayPilot` (`z_index = 30`) | Packet 6B search/reward/route | Scene-baked | Visible | **Visible** | **Yes** (pilot `Area2D`) | **Yes** | Edit only under this root | South spawn corridor |
| L19 | Runtime systems | `RuntimeSystems/*` | Guards, cameras, beams, routes, alarms | **Runtime-spawned** | N/A | Active | **Yes** | Partial | Do not duplicate managers | Beam host `SecurityBeam_Ambush_RightHallway` ~z 2600 |
| L20 | Runtime helpers | `RuntimeHelpers/*` | Hider, bridges, completion, HUD | Scene-baked | Visible | Active | **Yes** (logic) | HUD yes | **Do not change** bridge/completion scripts | `include_legacy_candidates = false` on bridge config in scene |
| L21 | Zone / objective areas | `ZoneLabels`, `ObjectiveAreas`, `ExitAreas` | Legacy zone labeling | Scene-baked | Mixed | Mixed | Partial | Partial | Defer | |
| L22 | Editor-only room labels | `EditorOnlyRoomLabels` (`z_index = 4096`) | Room names for editor | Scene-baked | Visible | High z | No | No | Editor-only | |
| L23 | Security authoring (proof labels) | `ProofLabel`, `DoorLabel` under `SecurityAuthoringRoot` | Prototype strings | Scene-baked | Visible | **Hidden** (3E hider) | No | Replaced by 3E affordances | Keep nodes; hide only | |

## Z-index / layering ranges (current evidence)

| Band | z_index (approx.) | Examples |
|------|-------------------|----------|
| Floor / layout base | 0–20 | `LayoutRoot` 20, tile layers default |
| Security hazard affordances | 18 | `SecurityHazardReadabilityVisuals` |
| Interactable polygons | 12 | `GeneratedRuntimeInteractables/RuntimeVisual` |
| Plug-and-play pilot | 30 | `PlugAndPlayPilot` (above interactable icons) |
| Runtime security beam (spawned) | ~2600 | `AmbushBeamLine` via `IsoMissionBase` |
| Editor/debug residue | 4090–4096 | `GeneratedRuntimeMarkerLabels`, `EditorOnlyRoomLabels` |
| Hidden debug (hider) | -4096 | Applied when hidden |

**Rule:** New player-facing affordances should sit **above floor (≤20)** and **below HUD**, typically **12–35**, unless matching a specific runtime system band.

## Style baselines

### Interactable highlight (Phase 3B + blueprint)

- Search: yellow `Color(0.95, 0.85, 0.2)` + `Line2D` ring  
- Reward: gold `Color(0.85, 0.65, 0.2)`  
- Route: purple `Color(0.75, 0.45, 0.95)`  
- Phase0J pickups: colored `Polygon2D` under `RuntimeVisual` (per-type colors in scene)

### Security hazard (Phase 3E)

- Alert: pink/red `Color(1, 0.16–0.38, α 0.2–0.95)`  
- Labels: outlined sans — **ALARM BEAM**, **Security Test Zone**, **TEST DOOR**  
- Do not reuse gray `SCENE_MARKER` panel style

### Debug / authoring marker policy (Phase 3C–3D)

- `GeneratedRuntimeMarkerLabels`: hidden on Taco at runtime  
- `SecurityAuthoringRoot/AuthorLabel` and `@Label@` residue: hidden  
- `MarkerRoot` subtree labels: hidden via `target_paths`  
- Recovery: set hider exports to `false` on Taco (nodes not deleted)

## Do-not-touch list (future visual packets)

- `project.godot`, autoloads, `IsoMissionBase.gd`
- `Phase0JInteractionBridge.gd`, `Phase0KMissionCompletionController.gd`, `MissionInteractionBridge.gd` (logic)
- `GeneratedRuntimeInteractables/Interactable_OBJ_bag_recovery`
- `GeneratedRuntimeInteractables/Interactable_CLUE_route_manifest_half`
- `GeneratedRuntimeInteractables/LouisExitToken`
- `GeneratedRuntimeCollision` (regenerated bodies)
- `CollisionBarrierLayer` tile data (unless dedicated collision packet)
- `PlugAndPlayPilot` requirement/effect/flag exports
- `Phase0JRuntimeAuthoringHider` Taco export values for 3C/3D/3E (unless intentional policy change)
- `SecurityAuthoringRoot` author node scripts/properties (gameplay)
- Full-map PVGames repaint in a single packet

## Screenshot validation routine

1. Load Taco from disk; do not save unless the packet changes the scene intentionally.
2. Play scene; wait for player spawn.
3. Capture bookmarks (see `TACO_PAINT_READINESS_CHECKLIST.md`):
   - Spawn / south corridor
   - Pilot lane
   - Security hazard / ambush beam
   - Manifest + code-gate corridor
   - Louis exit
   - Distant bag objective (teleport camera if needed)
4. Record runtime visibility census (hider exports, key roots).
5. Run pilot-only chain; confirm `delivery_bag_collected == false`.
6. Run `tests/mission_authoring/` full suite.
7. MainMenu smoke.

## Rollback expectations

| Change type | Rollback |
|-------------|----------|
| New visual root (e.g. 3E) | Delete/hide root; restore hider exports |
| Tile paint | Revert scene diff for `FloorLayer`/`WallLayer` only |
| Hider export | Set export `false` on Taco hider |
| Docs only (3F) | Delete or revert markdown files |

## Recommended next small visual slice

See `docs/TACO_PAINT_READINESS_CHECKLIST.md` and `reports/ai/2026-05-19_phase3f_taco_visual_layer_taxonomy_report.md` — **Phase 3G: Taco manifest–code-gate corridor wayfinding slice** (scene-local signage only).

## Related docs

- `docs/TACO_PAINT_READINESS_CHECKLIST.md`
- `docs/ISO_EDITOR_TILE_PALETTE.md`, `docs/ART_READY_LEVEL_WORKFLOW.md`
- `docs/TACO_BELL_MARKER_LEGEND.md`
- `reports/ai/2026-05-19_phase3a_*` through `phase3e_*`
