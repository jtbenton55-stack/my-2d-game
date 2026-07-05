# Corner Store Cashout — Fable 5 Independent Audit Report

**Date:** 2026-07-05  
**Auditor:** Fable 5 (Cursor), independent verification of Composer 2.5's "COMPLETED" claim  
**Mission:** `corner_store_cashout` / Corner Store Cashout  
**Scene:** `res://scenes/missions_iso/CornerStoreCashout_Editable.tscn`  
**Branch:** `new-feature-roadmap-branch` (no commit/stage/push/branch change made)

## Final status

**Repaired and ready for playtest.**

Composer's "COMPLETED" claim was **not valid as shipped**. The architecture, wiring, tests, and validator were real and largely correct, but three defects made the mission uncompletable in real play and one change regressed the Taco/all-mission debug panel. All were repaired minimally; every validation suite now passes.

## Baseline git status (Phase 1)

Branch `new-feature-roadmap-branch`, tracking origin. Classification of the dirty worktree:

| Classification | Files |
|---|---|
| Corner Store implementation (tracked, modified) | `src/autoload/GameState.gd`, `src/missions/MissionSceneResolver.gd`, `src/missions/iso/authoring/core/MissionCompletionBridge.gd`, `src/hideout/HideoutStationCatalog.gd`, `src/hideout/HideoutMissionBoardController.gd`, `src/hideout/HideoutManager.gd` |
| Corner Store implementation (untracked, new) | `scenes/missions_iso/CornerStoreCashout_Editable.tscn`, `assets/missions/corner_store_cashout_definition.tres`, `src/missions/iso/runtime/CornerStoreCashout{Mission,Encounter}Controller.gd`, `src/missions/iso/dev/CornerStoreCashout{LayoutBootstrap,IntegratedProofHarness}.gd`, `src/tools/editor/corner_store_cashout_production_skeleton/*`, `tests/mission_authoring/CornerStoreCashoutProductionSkeletonTest.gd`, `docs/reports/corner_store_cashout_production_skeleton/` |
| Prior Phase 17/18 work (pre-existing, not touched) | `addons/mission_dock/MissionDock.gd`, `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`, `src/missions/iso/runtime/Phase0JInteractionBridge.gd`, `Phase16GarageManagerDeniabilityController.gd`, `authoring/MissionInteractionBridge.gd`, `src/ui/MissionResult.gd`, `src/missions/iso/authoring/mechanics/EncounterRouteActionNode.gd`, `src/tools/editor/phase18_taco_player_routes/`, Phase 18 tests/reports |
| Generated validation/report artifacts | `docs/reports/phase*/…validator_run.json`, `reports/report_43..60/` (new), `reports/report_23..42/` (deleted HTML report churn — left alone) |
| Unrelated dirty / do not touch | `.cursor/mcp.json`, `docs/CHANGELOG.md` (updated additively only), roadmap/blueprint docs (updated additively only), `docs/things to complete.md`, `resources/character_animation_maps/*.json` |

No untracked files were deleted. No unrelated dirty files reverted.

## Composer claims verified (Phase 2)

| Claim | Verdict |
|---|---|
| Scene exists, `IsoMissionBase` root, full `GameplayRoot` tree | **True** |
| Exactly one `EntityRoot` under `GameplayRoot`, no root duplicate | **True statically**, but see architecture note: `IsoMissionBase` creates its own root-level `EntityRoot` at runtime; the scene's `GameplayRoot/EntityRoot` is inert authoring structure |
| 30+ authored mechanics | **True** (31 mechanic nodes counted, all `mission_id_override` + `csc_*` ids) |
| `MissionInteractionBridge.include_legacy_candidates = false` | **True** |
| `RuntimeHelpers`, `MissionMechanics` exist | **True** |
| `DebugProof` hidden/dev-safe proof harness in scene | **False as shipped.** Node was declared `name="GameplayRoot/DebugProof"` (slash in node name); headless load proved all panel children "vanished when instantiating". The harness was not actually in the runtime scene. **Fixed.** |
| Four cleanup routes selectable in play | **False as shipped.** All four `EncounterRouteActionNode`s used `../RuntimeHelpers/...` NodePaths from `GameplayRoot/MissionMechanics/*`, which resolve to a nonexistent `MissionMechanics/RuntimeHelpers`. `controller_path` survived via group fallback, but `required_controller_bool_path` has no fallback and returns `false`, so the progress gate never passed and **all routes were permanently locked**, making `choose_cleanup_route` and therefore extraction impossible. **Fixed** (`../../RuntimeHelpers/...`). |
| Extraction reaches mission completion path | **True after route fix.** `ExtractionZone` → `MissionCompletionBridge.request_complete` → RuntimeHelpers discovery → `CornerStoreCashoutMissionController.complete_mission_and_exit` → `IsoMissionBase.request_exit_completion`. Single completion path (no duplicate `iso_mission_exit` wiring). |
| Catalog / resolver / Mission Board wiring | **True** (catalog entry, resolver constant, slot 2, launch/replay/confirm/info actions, DEV bypass in debug builds) |
| Taco completion unlocks `corner_store_cashout` | **True** (`_unlock_next_missions("taco_bell_drop")` adds it alongside existing branch unlocks; follows the existing progression pattern; no fragile Taco-only hardcoding beyond that pattern) |
| Failure subtitle safe | **True** (isolated `match` arm; no effect on other missions) |
| Validator performs meaningful checks | **True** (file existence, wiring tokens, scene structure, mechanic/flag/route presence, bridge scope, Phase0J/0K absence, duplicate mechanic ids). It did **not** catch the NodePath or node-name defects; **two new checks added** so it does now. |
| GdUnit covers meaningful behavior | **Mostly true** — objective chain, door requirement, extraction gating, route locking, bridge discovery, unlock progression. Route tests used an isolated mini-tree with *different NodePaths than the scene*, which is exactly why the scene defect slipped through. Scene-text NodePath checks now live in the validator. |
| Validator PASS 77, GdUnit 12/12, bridge 4/4, headless PASS | **Reproduced pre-fix**, but "headless PASS" was exit-code-only and concealed script compile errors (below). Post-fix: validator **79/79**, corner store **12/12**, bridge **4/4**, full suite **318/318**, headless clean. |
| Report/roadmap/blueprint/changelog accurate | **Partially.** Wiring/test claims accurate; "COMPLETED"/playable overstated given the locked routes and broken proof harness. Corrected via this audit report and a changelog entry. |

## Regression found beyond the mission (critical)

`src/hideout/HideoutStationCatalog.gd:116` — Composer's new `var mission_id := ids[i]` fails GDScript type inference. This cascaded: `HideoutStationCatalog` → `MissionSchemeCardFormatter` → `IsoMissionDebugPanel` all failed to compile, so the **F10 debug panel failed to load in every iso mission, including Taco** (`_ensure_dev_harness` backtrace in headless log). A second instance in `HideoutMissionBoardController.gd:103` (`.get("completed", false)` inferred as Variant, warning-treated-as-error) broke compilation of the hideout test chain and crashed the full GdUnit run. **Both fixed** with explicit types.

## Risky changes reviewed (Phase 3)

| Change | Verdict |
|---|---|
| `MissionCompletionBridge` RuntimeHelpers discovery | **Safe as-is.** Phase0K / named-controller lookups take precedence, so Taco is unaffected; new path only fires when older lookups miss; only duck-types `complete_mission_and_exit()`. Regression suite 4/4. |
| `GameState._unlock_next_missions` | **Safe as-is.** Additive, follows existing pattern, `unlock_mission` validates against catalog. |
| Mission Board slot/bypass wiring | **Safe after type fix.** DEV corner-store launch only in debug builds; post-Taco board states verified by reading; full logic behind `_status_for` fallback is conservative. |
| Runtime blockout bootstrap generating geometry at runtime | **Acceptable for skeleton, flagged.** Layout is not stored in-scene; real production polish requires baking/hand-painting. Not a safety issue. |
| `_process` fact sync in mission controller | **Safe but inelegant.** Per-frame flag polling on one node; matches the reported known-risk. Recommend event-driven sync in the polish packet. |
| Mission-specific controllers duplicating plug-and-play behavior | **Acceptable.** Controllers are mission-local (no global managers, no Phase0J/0K), compose existing adapters (`PaperTrail`, `SocialStealth`, `ReactiveNpcBrain`) and `EncounterController`; facts/objectives flow through `MissionFactBridge` / `ObjectiveStepController` / `MissionObjectiveBridge`. |
| `csc_route_selected` flag overwrite | **Small fix applied.** Controller previously overwrote the route-id string with `true`, degrading the stored route choice. Write removed (route actions own that flag). |

## Architecture audit (Phase 4)

Follows the plug-and-play chain: placed mechanic → `RequirementSet` (badge-gated office door via sub-resources) → effects/flags → `MissionFactBridge`/`MissionCompletionBridge` → `GameState`/`IsoMissionBase`. Stable `csc_*` flags and mechanic ids. No Phase0J/Phase0K dependency (validator-enforced). Routes use `EncounterRouteActionNode` with allowlisted methods. Encounter/paper/social/reactive summaries flow into `MissionResult` via `get_summary()` and the `mission_encounter_controller` group. Mission Dock recognizes and audits `EncounterRouteActionNode` (added to `MECHANIC_TYPES` + audit rules in the Phase 18 packet).

## Visual/layout honesty (Phase 5)

- The level is **runtime-generated blockout**, not hand-painted: `CornerStoreCashoutLayoutBootstrap` paints floor/wall/cover/barrier/marker cells and a small programmatic PVGames art pass on `ArtRoot` at `_ready`.
- PVGames layers have tilesets assigned and a few programmatic cells — **"wired with a starter art pass", not painted**. Do not consider visual polish complete.
- Camera bounds present (`Camera2D` limits ±900/±500). Spawn marker present.
- Mechanics are positioned in coherent clusters (storefront → office → stockroom → alley) but several are schematic and tightly packed — notably the four route actions are 40 px apart with 96 px interaction shapes, so prompt overlap needs manual QA.
- Prompts/labels are readable plain English.
- Pre-existing PVGames tileset load errors ("Cannot create tile", "no tile at (0,0)") also occur loading `HideoutHub.tscn` — **not a corner-store regression**.
- **Jake manual visual/pacing QA is still required**; this audit does not mark visual polish complete.

## Fixes made by Fable 5 (Phase 7)

1. `src/hideout/HideoutStationCatalog.gd` — `var mission_id: String = ids[i]` (fixes compile cascade breaking F10 panel in all missions).
2. `src/hideout/HideoutMissionBoardController.gd` — `bool(...)` around inferred Variant (fixes warning-as-error compile failure crashing the full GdUnit suite).
3. `build_corner_store_scene.py` + regenerated scene — route action `controller_path` / `required_controller_bool_path` corrected to `../../RuntimeHelpers/...` (fixes permanently locked routes).
4. `build_corner_store_scene.py` + regenerated scene — `DebugProof` node name fixed (was `"GameplayRoot/DebugProof"` with a slash; children were dropped at instantiation).
5. Builder/scene + `CornerStoreCashoutIntegratedProofHarness.gd` — correct controller/status-label NodePaths for the harness's real position; button lookup now searches the panel (button is a sibling, not a child).
6. `CornerStoreCashoutMissionController.gd` — removed the `csc_route_selected` bool overwrite that clobbered the stored route-id string.
7. `corner_store_cashout_production_skeleton_validator.py` — added `route_action_node_paths_resolve` and `debug_proof_node_name_valid` checks so these defects cannot silently return.

## Validation commands and results (Phase 6)

| Check | Command | Result |
|---|---|---|
| Corner store static validator | `python .../corner_store_cashout_production_skeleton_validator.py` | **PASS (79 checks)** |
| Corner store + bridge GdUnit | `runtest.cmd -a CornerStoreCashoutProductionSkeletonTest.gd -a MissionCompletionBridgeTest.gd` | **16/16 PASS** |
| Full `tests/mission_authoring` suite | `runtest.cmd -a res://tests/mission_authoring` | **318/318 PASS** (crashed pre-fix on hideout compile error) |
| Phase 17 validator | `phase17_level_builder_readiness_validator.py` | **PASS (53 checks)** |
| Phase 18 validator | `phase18_taco_player_routes_validator.py` | **PASS (44 checks)** |
| Mission Dock validator | `phase2k_mission_dock_static_validator.py` | **PASS** |
| Corner store headless load | `--headless --quit-after 2 CornerStoreCashout_Editable.tscn` | exit 0, **no script errors / no vanished nodes** (pre-existing tileset + quit-leak noise only) |
| Taco headless smoke | `--headless --quit-after 2 TacoBellIso_Editable_RedesignTest.tscn` | exit 0, clean after catalog fix (was: IsoMissionDebugPanel compile failure) |
| MainMenu smoke | `--headless --quit-after 2 res://scenes/MainMenu.tscn` | exit 0, clean |

## Blocked checks

- **Godot MCP Pro runtime QA** — editor not open / MCP not attached this session (connection timeout). Static + headless + GdUnit evidence provided instead, per fallback policy.

## Taco regression assessment

- Pre-audit: **regressed** — the corner-store hideout wiring broke `IsoMissionDebugPanel` (F10) compilation for all iso missions including Taco.
- Post-fix: Taco headless smoke clean; Phase 17/18 validators pass; full `mission_authoring` suite (which includes Taco Phase 16/17/18 contracts) 318/318. `MissionCompletionBridge` precedence preserves Phase0K authority. Canonical Taco flow logic untouched.

## Manual QA checklist for Jake

1. Hideout → Mission Board → DEV: Start Corner Store Cashout (or complete Taco first).
2. Clipboard search → name-tag pickup → badge-gated office door (verify locked message first).
3. Grab cash envelope + scam folder; confirm `recover_cashout_evidence` completes.
4. Approach the four route actions **before** office unlock — all should show the progress-locked prompt; after unlock, pick one and confirm the other three lock.
5. Extraction blocked before evidence+route; succeeds after; MissionResult shows Route + Style labels.
6. Replay from board; confirm attempt flags reset.
7. Check route-action prompt overlap (they're 40 px apart) and general movement/collision/camera readability.
8. Optional: toggle `GameplayRoot/DebugProof/ProofPanel` visible in editor and press Run Integrated Proof.

## Commit safety

Safe to commit after Jake's manual playable QA passes. All changes are repo-local, additive or corrective to the corner-store packet, with Taco-preserving evidence above. Nothing was staged or committed per instructions.
