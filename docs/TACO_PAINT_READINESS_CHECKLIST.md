# Taco Paint-Readiness Checklist

**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Companion:** `docs/TACO_VISUAL_LAYER_TAXONOMY.md`  
**Last updated:** 2026-05-19 (Phase 3F)

Use this checklist before any Taco visual-only or paint-adjacent packet.

---

## 1. Pre-edit git safety

- [ ] `git status --short --branch` — record branch and unrelated dirty files
- [ ] Confirm only intended files will change
- [ ] Do not commit/push unless Jake explicitly requests
- [ ] Do not save Taco from editor unless disk version matches intentional edits

---

## 2. Required reading

- [ ] `docs/TACO_VISUAL_LAYER_TAXONOMY.md`
- [ ] Latest Phase 3 report for the area you touch (`reports/ai/2026-05-19_phase3b` … `phase3e`)
- [ ] `reports/ai/2026-05-19_phase3a_taco_visual_readability_preflight_report.md` (open issues P3A-03, P3A-04)
- [ ] `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` (Phase 3 goals)
- [ ] `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` (PVGames Object Palette v2, Mission Paint Dock, Y-sort, gizmo, and optional plugin bridge contracts)
- [ ] `docs/ISO_EDITOR_TILE_PALETTE.md` / `docs/ART_READY_LEVEL_WORKFLOW.md` (if painting tiles)

---

## 3. Scene roots to inspect (disk)

- [ ] `GameplayRoot/LayoutRoot/FloorLayer`
- [ ] `GameplayRoot/LayoutRoot/WallLayer`
- [ ] `GameplayRoot/LayoutRoot/CoverLayer`
- [ ] `GameplayRoot/LayoutRoot/CollisionBarrierLayer`
- [ ] `GameplayRoot/LayoutRoot/MarkerTileLayer`
- [ ] `GameplayRoot/GeneratedRuntimeInteractables`
- [ ] `GameplayRoot/GeneratedRuntimeMarkerLabels`
- [ ] `GameplayRoot/PlugAndPlayPilot`
- [ ] `GameplayRoot/SecurityAuthoringRoot`
- [ ] `GameplayRoot/SecurityHazardReadabilityVisuals`
- [ ] `GameplayRoot/RuntimeHelpers/Phase0JRuntimeAuthoringHider`
- [ ] `GameplayRoot/GeneratedRuntimeCollision`

---

## 4. Screenshot bookmarks (GameplayRoot space)

| Bookmark | Approx. focus | Node hint |
|----------|---------------|-----------|
| Spawn | Player start | `MarkerRoot/Spawns/default` (~-1088, 32) |
| Pilot lane | Plug-and-play | `PlugAndPlayPilot` (~318–760, 120–143) |
| Security hazard | Ambush beam + 3E visuals | `(9606, 167)` |
| Manifest / code | Canonical clue | `Interactable_CLUE_route_manifest_half` (~4128, 624) |
| Louis exit | Completion token | `LouisExitToken` (~800, 848) |
| Bag objective | Canonical bag | `Interactable_OBJ_bag_recovery` (~16032, 368) |

**Tip:** Use camera teleport or debug panel for distant bookmarks; document if screenshot framing fails.

Save under `reports/ai/phase3*_taco_*_screenshots/`.

---

## 5. Phase 3B–3E non-regression (runtime)

On `GameplayRoot/RuntimeHelpers/Phase0JRuntimeAuthoringHider` confirm Taco exports:

- [ ] `hide_generated_runtime_marker_labels = true`
- [ ] `hide_security_author_labels = true`
- [ ] `hide_security_label_residue = true`
- [ ] `hide_security_proof_and_door_labels = true`

Runtime visibility:

- [ ] `GeneratedRuntimeMarkerLabels.visible == false`
- [ ] Security `AuthorLabel` hidden (13/13)
- [ ] `SecurityHazardReadabilityVisuals.visible == true`
- [ ] `PlugAndPlayPilot.visible == true`
- [ ] `GeneratedRuntimeInteractables.visible == true`
- [ ] `ProofLabel` / `DoorLabel` hidden when 3E policy enabled

---

## 6. Canonical mission non-regression

- [ ] `Interactable_OBJ_bag_recovery` exists and works
- [ ] `Interactable_CLUE_route_manifest_half` exists and works
- [ ] `LouisExitToken` exists
- [ ] `Phase0JInteractionBridge` present under `RuntimeHelpers`
- [ ] `Phase0KMissionCompletionController` present
- [ ] `MissionInteractionBridge.include_legacy_candidates = false`
- [ ] Pilot chain: search → reward → route; mission **not** completed by pilot alone
- [ ] `delivery_bag_collected == false` after pilot-only chain (if safely checked)

---

## 7. Do-not-touch systems

- `project.godot`, autoloads
- `IsoMissionBase.gd`
- Phase0J/Phase0K **scripts** (unless packet explicitly authorizes a tiny hider fix)
- Security gameplay / `SecurityEventRouter` / author scripts
- Pilot requirements, effects, flags, IDs
- `GeneratedRuntimeCollision` bodies (unless collision packet)
- Canonical interactable logic nodes
- Full-map repaint in one packet

---

## 8. Layer-by-layer paint rules

| Layer | Paint? | Rules |
|-------|--------|-------|
| `FloorLayer` | Yes, dedicated packet | Walkable only; no shifting `GameplayRoot` |
| `WallLayer` | Yes, dedicated packet | Visual edge; verify wall collision regen |
| `CoverLayer` | Yes | Currently hidden at runtime — coordinate with hider |
| `CollisionBarrierLayer` | **Rare** | Treat as gameplay authoring — audit generators after |
| `MarkerTileLayer` | Editor | Hidden at runtime; legend-driven |
| New visual roots | Yes | Scene-local `Node2D` children, no collision, z 12–35 |
| `SecurityHazardReadabilityVisuals` | Supplement only | Preserve 3E affordances |
| `PlugAndPlayPilot` | Pilot packets only | Preserve 3B lane |

---

## 9. Avoid collision changes while painting visuals

- Do not add `Area2D` / `StaticBody2D` to visual-only roots unless packet explicitly requires it (default: **forbidden**).
- Do not move `GeneratedRuntimeInteractables` pickup positions without a dedicated gameplay packet.
- Do not enable disabled `CollisionShape2D` on proof doors unless security packet says so.
- After any `WallLayer` / `CollisionBarrierLayer` edit: playtest movement + run `tests/mission_authoring/`.

---

## 10. Packet type decision

| Situation | Packet type |
|-----------|-------------|
| New `Polygon2D` / `Line2D` / `Label` under new or existing visual root | Scene-only |
| New hider export (default `false`, Taco opt-in) | Script + tests |
| Tile paint on `FloorLayer`/`WallLayer` | Scene-only paint packet + movement playtest |
| PVGames Object Palette v2 brush/repeat placement | Editor-tool packet + scratch-scene validation before production save |
| Mission Paint Dock use on Taco | Scene-only paint packet; visual layers only; no collision or mechanics |
| Manual animation mapper/reviewer | Art-tool packet; writes reviewed animation map / generated `SpriteFrames`, not Taco scene |
| Unclear ownership | **Audit-only** — no scene edit |

---

## 11. Tests and smoke

- [ ] Full `tests/mission_authoring/` — baseline **159/159** after Phase 3E
- [ ] MainMenu `res://scenes/MainMenu.tscn` loads
- [ ] Godot LSP clean if any `.gd` changed; otherwise note N/A
- [ ] Write `reports/ai/YYYY-MM-DD_phase3*_report.md`

---

## 12. Next suggested slice (post–Phase 3F)

**Phase 3G — Taco manifest–code-gate corridor wayfinding** (see Phase 3F report for full scope).

Goal: scene-local floor/signage affordances from spawn south corridor toward `Interactable_CLUE_route_manifest_half` without tile repaint of full map or collision edits.

---

## Rollback

1. Revert scene diff for the packet’s visual root or tile layers only.
2. Restore Taco hider exports if changed.
3. Re-run tests + MainMenu + Taco playtest bookmarks above.
