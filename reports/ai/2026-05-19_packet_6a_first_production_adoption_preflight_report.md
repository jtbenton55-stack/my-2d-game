# Packet 6A — First Production Adoption Preflight Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Goal:** Audit Taco production mission structure, document candidate adoption slices, select one safe Packet 6B slice, and draft an explicit implementation prompt. **No production wiring in this packet.**

## Files inspected

| Area | Paths |
|------|--------|
| Blueprint / roadmap | `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` (Packet 6), `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` |
| Construction kit | `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`, `reports/ai/2026-05-19_packet_2b10_construction_kit_validation_report.md` |
| Scene routing | `src/missions/MissionSceneResolver.gd`, `src/hideout/HideoutMissionBoardController.gd`, `src/autoload/SceneManager.gd`, `project.godot` (read-only) |
| Canonical Taco scene | `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` |
| Mission base | `src/levels/IsoMissionBase.gd` (read-only) |
| Phase0J stack | `Phase0JInteractionBridge.gd`, `Phase0JInteractablePickup.gd`, `Phase0JMechanicRouter.gd`, `Phase0JMissionStateAdapter.gd` |
| Phase0K stack | `Phase0KMissionCompletionController.gd`, `Phase0KLouisExitInteractable.gd`, `Phase0KBagObjectiveInteractable.gd` |
| Legacy route | `MissionRouteAccessPoint.gd` |
| New bridge | `src/missions/iso/runtime/authoring/MissionInteractionBridge.gd` |
| Mechanics | `SearchZone.gd`, `RewardNode.gd`, `RouteUnlockNode.gd`, `ExtractionZone.gd`, `SideObjectiveNode.gd` |

## Files added / modified

| File | Change |
|------|--------|
| `reports/ai/2026-05-19_packet_6a_first_production_adoption_preflight_report.md` | Added (this report) |

**No production scenes, scripts, `project.godot`, autoloads, or Taco wiring were modified.**

---

## Canonical Taco scene and flow

| Item | Value |
|------|--------|
| **Playable scene** | `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` |
| **Root node** | `TacoBellIso_Editable` → `IsoMissionBase.gd` |
| **Mission id** | `taco_bell_drop` |
| **Launch** | Hideout mission board → `HideoutMissionBoardController.launch_taco_bell()` → `GameState.start_mission("taco_bell_drop")` → `MissionSceneResolver.resolve_playable_scene_path()` → `SceneManager.change_scene(...)` |
| **Main menu entry** | `project.godot` `run/main_scene` = `res://scenes/MainMenu.tscn` |
| **Legacy catalog path** | `GameState` still lists classic `TacoBellMission.tscn`; resolver overrides to RedesignTest iso |

### Scene hierarchy (authoring-relevant)

```
TacoBellIso_Editable (IsoMissionBase)
└── GameplayRoot
    ├── SecurityAuthoringRoot (D6 security proofs — separate stack)
    ├── ZoneLabels, tile layers, boundaries
    ├── MarkerRoot (objectives, spawns, routes — inspect/deferred)
    ├── RuntimeSystems (RouteAccessPoints, spawns, etc.)
    ├── ExitAreas
    ├── GeneratedRuntimeInteractables  ← Phase0J-C2 runtime pickups
    ├── GeneratedRuntimeMarkerLabels
    └── RuntimeHelpers
        ├── Phase0JInteractionBridge      ← production E-interact (Phase0J/K only)
        ├── Phase0KMissionCompletionController
        ├── Phase0J* adapters / code gate / router
        └── (no MissionInteractionBridge today)
```

### Player / interact flow today

- **E / Q** handled by `Phase0JInteractionBridge` for nodes under `GeneratedRuntimeInteractables` with `phase0j_interactable` / Phase0J meta, plus `phase0k_louis_exit`.
- **MissionInteractionBridge is absent** from the Taco scene. New `MechanicAreaBase` nodes (`mission_mechanic` + `interactable`, **not** `phase0j_interactable`) are **ignored** by Phase0J bridge (`_is_phase0j_candidate` filters them out).
- **Packet 6B must add** `MissionInteractionBridge` beside Phase0J (do not remove Phase0J bridge).

---

## Current Taco objective / completion spine

### Phase0K-owned completion (canonical exit)

`Phase0KMissionCompletionController` (`mission_id = taco_bell_drop`) seeds QuestManager objectives:

| Objective id | Role |
|--------------|------|
| `open_garage_code_gate` | Code gate solved |
| `recover_delivery_bag` | Bag recovered → sets `required_objectives_complete` |
| `return_to_louis` | Unlocked after requirements; completed on exit |

**Exit requirements:** `delivery_bag_collected` + `code_gate_unlocked`  
**Exit interactable:** `GameplayRoot/GeneratedRuntimeInteractables/LouisExitToken` (`Phase0KLouisExitInteractable`) → `complete_mission_and_exit()` → `IsoMissionBase.request_exit_completion()` or `apply_phase0k_louis_exit_completion()`.

### Critical Phase0J interactables (do not replace in 6B)

| Node | Location | Purpose |
|------|----------|---------|
| `Interactable_OBJ_bag_recovery` | GeneratedRuntimeInteractables | Bag → Phase0K completion |
| `Interactable_CLUE_route_manifest_half` | ~(4128, 624) | Clue for garage code gate (`required_clue_id` in IsoMissionBase) |
| Other `Interactable_CLUE_*` | Various | Evidence / objectives via adapters |
| `LouisExitToken` | Near escape zone | Mission completion |

### Route / search spine (deferred / legacy)

- Marker manifest includes `ROUTE_IN_louis_service_door`, `ROUTE_RET_*`, `ROUTE_DEST_*` — `Phase0JMechanicRouter` marks **ROUTE_* as `INSPECT_ONLY_DEFERRED`**.
- `MissionRouteAccessPoint` in `RuntimeSystems/RouteAccessPoints` uses `GameState.has_evidence_clue("route_manifest_half")` — **separate** from plug-and-play flags.
- **Do not** wire Packet 6B to Louis route markers or `handle_route_access` until a dedicated route migration packet.

### Double-completion risks (must avoid in 6B)

| Risk | Mitigation |
|------|------------|
| Second exit completing mission | **No** `ExtractionZone` with `complete_mission_on_success = true` |
| Duplicate `return_to_louis` / bag objectives | **No** `SideObjectiveNode` / `ObjectiveStepController` on canonical ids |
| Replacing `route_manifest_half` pickup | **Do not** overlap or disable `Interactable_CLUE_route_manifest_half` |
| Calling `MissionCompletionBridge` from pilot | **No** completion effects; flags + optional dialogue only |
| Phase0K controller hooks | **No** edits to `set_delivery_bag_collected` / `set_code_gate_unlocked` from pilot |

---

## Production authoring-root recommendation

Add a **new sibling root** under `GameplayRoot` (not under `GeneratedRuntimeInteractables`):

```
GameplayRoot/PlugAndPlayPilot
```

Rationale:

- Keeps Phase0J runtime pickups untouched.
- Clear rollback: delete one folder + one bridge node.
- Matches dev-room `MultiInstance/` pattern.
- Avoids `SecurityAuthoringRoot` (different D6 stack).

Also add under `GameplayRoot/RuntimeHelpers`:

```
MissionInteractionBridge  (player_path → scene Player node)
```

Configure `interaction_radius` ≥ 144 (match Phase0J). Both bridges may receive `interact`; Phase0J will not target pilot nodes.

---

## Candidate slices (2–4)

### Candidate A — South Return Corridor optional search → reward → local route peek (RECOMMENDED)

| Field | Detail |
|-------|--------|
| **Area** | Near `ZoneLabel_South_Return_Corridor` (~472, 84); pilot nodes at **~(520, 120)**, **(640, 120)**, **(760, 120)** |
| **Mechanics** | `SearchZone` → `RewardNode` → `RouteUnlockNode` (local visuals only) |
| **Touches** | New `PlugAndPlayPilot` nodes, `MissionInteractionBridge`, namespaced `mission_flag:taco_bell_drop:pp_*` |
| **Does not touch** | Louis exit, bag recovery, code gate, `route_manifest_half`, Phase0K controller, `IsoMissionBase` |
| **Risks** | Low — optional, off critical path |
| **Validation** | Play Taco → visit south corridor → E chain → flags set → Louis exit still requires bag+gate |
| **Rollback** | Remove `PlugAndPlayPilot` + bridge node |

### Candidate B — Parallel “manifest scrap” beside `CLUE_route_manifest_half`

| Field | Detail |
|-------|--------|
| **Area** | Adjacent to (4128, 624) |
| **Mechanics** | `SearchZone` + `RewardNode` |
| **Risks** | **High** — confuses canonical clue / code gate; players may think scrap replaces manifest |
| **Verdict** | **Reject for 6B** |

### Candidate C — Louis service corridor `RouteUnlockNode` on `spawn_route_louis_entry`

| Field | Detail |
|-------|--------|
| **Area** | ~(5664, 656) Louis route markers |
| **Mechanics** | `RouteUnlockNode` toggling real route blockers |
| **Risks** | **High** — overlaps deferred `ROUTE_IN` / `MissionRouteAccessPoint` / future shortcut design |
| **Verdict** | **Defer** to post-pilot route packet |

### Candidate D — Optional `ExtractionZone` in `ExitAreas`

| Field | Detail |
|-------|--------|
| **Mechanics** | `ExtractionZone` with `complete_mission_on_success = false` |
| **Risks** | **Medium** — proximity to Louis exit; player confusion; still must not call completion |
| **Verdict** | **Defer** — use only if 6B needs extraction demo after A succeeds |

### Candidate E — Optional `SideObjectiveNode` (“bonus objective”)

| Field | Detail |
|-------|--------|
| **Risks** | **Medium** — QuestManager pollution; must use **new** objective id (not `open_garage_code_gate` / `recover_delivery_bag` / `return_to_louis`) |
| **Verdict** | **Defer** to 6C — A proves flags + interact without QuestManager coupling |

---

## Selected Packet 6B slice

**Candidate A: South Return Corridor Plug-and-Play Pilot**

Smallest reversible production edit that demonstrates real construction-kit value (search → reward → route) without touching canonical completion or Phase0J pickups.

---

## Exact proposed ids / flags / effects (Packet 6B)

**Mission:** `taco_bell_drop` (`mission_id_override` on all pilot nodes)

| Node | Type | mechanic_id | Other ids | Requirements | Success effects / flags |
|------|------|-------------|-----------|--------------|-------------------------|
| `PpTacoSouthSearchDrop` | SearchZone | `pp_taco_south_search` | `searched_flag`: `pp_taco_south_searched` | none | `SET_MISSION_FLAG` → `pp_taco_south_found_scrap` (+ optional `pp_taco_south_searched`) |
| `PpTacoSouthRewardScrap` | RewardNode | `pp_taco_south_reward` | `reward_id`: `pp_taco_south_scrap` | `RequirementSet`: mission_flag `pp_taco_south_found_scrap` | `collected_flag`: `pp_taco_south_reward_collected`; effect `pp_taco_south_reward_effect` |
| `PpTacoSouthRoutePeek` | RouteUnlockNode | `pp_taco_south_route` | `route_id`: `pp_taco_south_peek` | mission_flag `pp_taco_south_reward_collected` | `route_flag`: `pp_taco_south_route_open`; effect `pp_taco_south_route_effect`; toggles **pilot-local** `RouteBlockedVisual` / `RouteOpenVisual` / `RoutePeekBlocker` only |

**Explicitly excluded from 6B:**

- `complete_mission_on_success`
- `ObjectiveStepController` / `SideObjectiveNode`
- `MissionCompletionBridge` / `COMPLETE_OBJECTIVE` effects on canonical ids
- Editing or disabling Phase0J nodes
- `IsoMissionBase.gd` changes

**Optional feedback:** `TRIGGER_SIMPLE_DIALOGUE` on reward collect (“Bonus scrap logged.”) — safe, no completion.

---

## Validation plan (Packet 6B)

1. GdUnit: full `tests/mission_authoring/` still **149/149**.
2. Open Taco scene → confirm `PlugAndPlayPilot` + `MissionInteractionBridge` present; **save scene**.
3. Play Taco from hideout (or debug launch):
   - Phase0J bag / manifest / Louis exit unchanged.
   - South pilot: search → reward blocked until scrap flag → route blocked until reward → route unlock toggles pilot visuals only.
   - Louis exit still blocked without bag + code gate.
   - Mission does **not** complete from pilot nodes.
4. Repeat interact → `already_searched` / `already_collected` / `already_unlocked`.
5. `GameState.dialogue_flags` contains `mission_flag:taco_bell_drop:pp_taco_south_*` only for pilot actions.

---

## Rollback plan (Packet 6B)

1. Remove `GameplayRoot/PlugAndPlayPilot` subtree from Taco scene.
2. Remove `MissionInteractionBridge` node from `RuntimeHelpers` (if added only for pilot).
3. Optional: clear `mission_flag:taco_bell_drop:pp_taco_south_*` keys from saves (not required for code rollback).
4. Re-run mission_authoring tests.

---

## Tests / checks run (Packet 6A)

| Check | Result |
|-------|--------|
| GdUnit4 `tests/mission_authoring/` | **149/149** pass |
| Godot LSP | N/A (no `.gd` files modified) |
| Godot MCP — open Taco scene | OK; tree shows `RuntimeHelpers/Phase0JInteractionBridge`, no `MissionInteractionBridge`, `LouisExitToken`, `GeneratedRuntimeInteractables` |
| Godot MCP — MainMenu smoke | Loads `MainMenu`; no new parse/autoload errors |
| Godot MCP — Taco play smoke | **Not run** (avoid long runtime / accidental save); editor inspection only |
| Godot DAP | Not needed |

## Kimi K2.6 MCP

Not used.

## Safety confirmation

- No production scene saves, Taco wiring, `project.godot`, autoload, `IsoMissionBase`, Phase0J, or Phase0K code changes in 6A.
- No new managers, save schema, or mission rating UI.
- Packet 6B scope bounded to one pilot folder + one bridge node.

## Known risks (for 6B)

| Risk | Note |
|------|------|
| Dual bridges on `interact` | Phase0J ignores pilot nodes; pilot bridge must be present. Watch priority if pilot overlaps Phase0J interactable at same position — **keep pilot away from manifest/bag/Louis**. |
| Player discovery | South corridor is optional; add `HintLabel` on pilot nodes. |
| Resource wiring | RequirementSet/EffectSet as sub-resources in scene or small `PlugAndPlayPilotBootstrap.gd` — prefer **inline scene exports** to avoid new autoloads. |
| Future cleanup | Old Phase0J path remains until post-playtest removal packet (per blueprint Packet 6 rule 4). |

---

## Packet 6B implementation prompt draft

Use this prompt for the next packet:

---

**TASK: Packet 6B — First Taco production adoption (South Return Plug-and-Play Pilot)**

Implement **only** Candidate A from `reports/ai/2026-05-19_packet_6a_first_production_adoption_preflight_report.md`.

**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

**Add:**

1. `GameplayRoot/PlugAndPlayPilot` (Node2D) with three Area2D children:
   - `PpTacoSouthSearchDrop` — `SearchZone.gd`, position ~(520, 120)
   - `PpTacoSouthRewardScrap` — `RewardNode.gd`, position ~(640, 120)
   - `PpTacoSouthRoutePeek` — `RouteUnlockNode.gd`, position ~(760, 120), local `RouteBlockedVisual` / `RouteOpenVisual` / `RoutePeekBlocker` children

2. `GameplayRoot/RuntimeHelpers/MissionInteractionBridge` — script `MissionInteractionBridge.gd`, `player_path` → existing Player node, `interaction_radius` 144+.

**Configure exports (all `mission_id_override = "taco_bell_drop"`):**

- Search: `mechanic_id` `pp_taco_south_search`, `searched_flag` `pp_taco_south_searched`, success sets `pp_taco_south_found_scrap`.
- Reward: `reward_id` `pp_taco_south_scrap`, requires flag `pp_taco_south_found_scrap`, `collected_flag` `pp_taco_south_reward_collected`, effect `pp_taco_south_reward_effect`.
- Route: `route_id` `pp_taco_south_peek`, requires `pp_taco_south_reward_collected`, `route_flag` `pp_taco_south_route_open`, toggles pilot-local nodes only.

**DO NOT:** modify `IsoMissionBase`, Phase0J/Phase0K scripts, Louis exit, bag/manifest interactables, `complete_mission_on_success`, QuestManager canonical objectives, `project.godot`, autoloads, or delete Phase0J nodes.

**Validate:** 149/149 mission_authoring tests; play Taco; pilot chain; Louis exit still gates on bag+gate; no mission complete from pilot; MCP/LSP clean.

**Report:** `reports/ai/2026-05-19_packet_6b_taco_south_pilot_adoption_report.md`

---

## Recommended next step

Run **Packet 6B** using the draft above. After one successful Taco playtest, plan a **cleanup packet** (remove duplicate paths) only if Jake approves — not in 6B.
