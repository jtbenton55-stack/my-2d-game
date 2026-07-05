# Corner Store Cashout — Production Mission Report

**Date:** 2026-07-04 (completion pass 2026-07-05)  
**Mission ID:** `corner_store_cashout`  
**Phase label:** Second production-intent mission (post–Taco Bell, plug-and-play)  
**Status:** **COMPLETED** (production skeleton + completion wiring)  
**Grouped-milestone mode:** Yes — shell, mechanics, launcher, completion bridge, proof harness, validator, tests, and docs in one packet.

## Summary

Built and completed the first full production-intent second mission using the plug-and-play authoring stack: **Corner Store Cashout**, a compact neon convenience-store micro-heist. The mission is playable via hideout launch (unlocks after Taco Bell complete, or DEV bypass), resolver-backed, validator-checked, extraction-wired through `MissionCompletionBridge`, and covered by focused GdUnit tests.

## What was built

### Scene and layout
- `scenes/missions_iso/CornerStoreCashout_Editable.tscn` — `IsoMissionBase` root, `GameplayRoot` tree, tile layers, runtime helpers, 30+ authored mechanics, art layer hooks, camera bounds, alley extraction, debug proof harness (hidden panel).
- `src/missions/iso/dev/CornerStoreCashoutLayoutBootstrap.gd` — runtime blockout paint + tileset assignment + PVGames/catalog/security art pass on `ArtRoot` layers.
- `assets/missions/corner_store_cashout_definition.tres` — mission definition resource.

### Mission-local controllers (non-Taco, no Phase0J/0K)
- `CornerStoreCashoutMissionController.gd` — objective seeding, fact sync, exit requirements, `complete_mission_and_exit` → `request_exit_completion`.
- `CornerStoreCashoutEncounterController.gd` — clean social, Bentley distraction, evidence/paper-trail, messy authority, cleanup redirect routes with MissionResult summaries.

### Completion / progression wiring
- `MissionCompletionBridge._find_controller_under()` — discovers any `RuntimeHelpers` child with `complete_mission_and_exit()` so extraction reaches `CornerStoreCashoutMissionController`.
- `GameState._unlock_next_missions("taco_bell_drop")` — now unlocks `corner_store_cashout` alongside parallel branch missions.
- `GameState._failure_subtitle("corner_store_cashout")` — mission-specific failure copy.

### Integrated proof harness (debug)
- `CornerStoreCashoutIntegratedProofHarness.gd` — dev-only integrated proof for paper-trail, social-stealth, reactive-NPC, and encounter route composition (Phase 17 pattern). Wired under `GameplayRoot/DebugProof` (panel hidden by default).

### Launcher / catalog
- `GameState.mission_catalog` entry for `corner_store_cashout`.
- `MissionSceneResolver` playable path constant.
- `HideoutStationCatalog.missions()` slot 2 + launch actions.
- `HideoutMissionBoardController` + `HideoutManager` launch/replay/confirmation flow.

### Tooling
- Scene generator: `src/tools/editor/corner_store_cashout_production_skeleton/build_corner_store_scene.py` (no duplicate root `EntityRoot`/`MissionController`; includes debug proof harness)
- Static validator: `corner_store_cashout_production_skeleton_validator.py` (**77 checks PASS**)
- GdUnit: `tests/mission_authoring/CornerStoreCashoutProductionSkeletonTest.gd` (**12/12 PASS**, `reports/report_59/`)

## Mechanics / systems exercised

| Family | Nodes / behavior |
|--------|------------------|
| Core loop | SearchZone, InventoryPickupNode, LockedInteractionNode (badge req), RewardNode, ExtractionZone |
| Routes | 4× EncounterRouteActionNode (clean social, Bentley, evidence, messy authority) |
| Puzzle/security | TerminalHackNode, TimedSwitchNode, PressurePlateNode, PowerCircuitNode, RouteUnlockNode |
| Bentley/noise | CompanionCommandPoint, BentleyWaitMarker, BentleyCrawlspaceConnector, NoiseEmitterNode, DistractionObject |
| Social/paper/reactive | BelievableTaskZone, ProtocolZone, AuditTrailCleanupNode, HeatSinkObject, InvestigationPointNode, RoutineOverrideNode |
| Side job | DeadDropNode, ObjectSwapNode, BugPlantNode, EavesdropZone, SideObjectiveNode, CustomSequenceRunner |
| Bridges | MissionInteractionBridge (`include_legacy_candidates = false`), MissionAlertController, MissionCompletionBridge, MissionObjectiveBridge seeding |
| Scheme hook | SchemeCardTriggerNode (disabled on ready) |

## Validation

| Check | Result |
|-------|--------|
| `corner_store_cashout_production_skeleton_validator.py` | **PASS** (77 checks) |
| GdUnit `CornerStoreCashoutProductionSkeletonTest.gd` | **PASS** 12/12 |
| GdUnit `MissionCompletionBridgeTest.gd` regression | **PASS** 4/4 |
| Headless scene load `CornerStoreCashout_Editable.tscn` | **PASS** (exit 0; known quit-after tile leak noise from layout bootstrap) |
| Godot MCP Pro runtime QA | **Not run** (editor/MCP not attached this session) |

## Known risks / Jake review items

### Visual / layout (manual QA required)
- Blockout and programmatic PVGames art pass run at runtime; **hand-painted layout polish** still needs Jake's tile/prop placement judgment.
- Collision/camera/readability tuning not playtested in-editor.
- Route pacing and aisle/back-office distances are schematic, not balanced.

### Technical
- Full scene instantiate in tests hits a **pre-existing `IsoMissionBase.gd` strict-type compile warning** in GdUnit harness; tests use isolated mechanics + file-text checks instead. Headless load still succeeds.
- Mission controller uses `_process` fact sync — acceptable for skeleton; may move to event-driven sync later.
- Headless `--quit-after 1` reports TileMapLayer leak noise from bootstrap paint teardown (known pattern).

## Manual QA checklist

1. Launch hideout → Mission Board → start **Corner Store Cashout** (after Taco complete, or DEV button).
2. Confirm spawn at storefront, camera limits, and collision/barriers feel readable.
3. Search scheduling clipboard → collect/fake badge → unlock employee door → enter back office.
4. Collect cash envelope + scam folder.
5. Run **each route** on separate attempts: clean social, Bentley distraction, evidence/paper-trail, messy authority.
6. Complete optional side job chain (dead drop / coupon scam / sequence nodes).
7. Exercise puzzle/security path (terminal, timer, plate, power circuit).
8. Exercise Bentley/noise path (bark, chip aisle noise, distraction).
9. Confirm extraction **blocked** before evidence + route; **succeeds** after both and returns via mission controller.
10. Inspect **MissionResult** for route label/style and consequence fields.
11. Return to hideout; replay and confirm attempt-local flags reset.
12. (Debug) Enable `GameplayRoot/DebugProof/ProofPanel` and run integrated proof button.

## Recommended next polish packet

1. Hand-paint PVGames floor/wall/prop layers + security nook readability pass.
2. Tune mechanic positions to painted layout; add guard/clerk NPC placeholders if desired.
3. Wire success_effects on key mechanics for tighter objective progression without `_process` sync.
4. Jake manual movement/collision/prompt/pacing QA in Godot editor.

## Files changed (this packet)

- `scenes/missions_iso/CornerStoreCashout_Editable.tscn`
- `assets/missions/corner_store_cashout_definition.tres`
- `src/missions/iso/runtime/CornerStoreCashoutMissionController.gd`
- `src/missions/iso/runtime/CornerStoreCashoutEncounterController.gd`
- `src/missions/iso/dev/CornerStoreCashoutLayoutBootstrap.gd`
- `src/missions/iso/dev/CornerStoreCashoutIntegratedProofHarness.gd` (new)
- `src/missions/iso/authoring/core/MissionCompletionBridge.gd`
- `src/tools/editor/corner_store_cashout_production_skeleton/*`
- `tests/mission_authoring/CornerStoreCashoutProductionSkeletonTest.gd`
- `src/autoload/GameState.gd`, `src/missions/MissionSceneResolver.gd`
- `src/hideout/HideoutStationCatalog.gd`, `HideoutMissionBoardController.gd`, `HideoutManager.gd`
- `docs/CHANGELOG.md`, roadmap/blueprint notes
- `docs/reports/corner_store_cashout_production_skeleton/corner_store_cashout_production_skeleton_validation.json`

**Taco Bell systems preserved.** No commits made (per instructions).
