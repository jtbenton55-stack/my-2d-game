# Plug-And-Play Mission System Implementation Blueprint

Date: 2026-05-19

Status: Planning document. This file describes how to implement the roadmap. It does not implement code.

Implementation update 2026-07-03: the D6 Taco player-facing polish packet now uses existing adapters/providers instead of a new manager: `GameState` annotates mission results and posts the first Taco Sterling clue, `MissionPauseDataProvider` owns next-objective text, `MissionHudDataProvider` feeds HUD objective/poop-bag status, and `MissionResult` renders the richer payload. Validator: `src/tools/editor/taco_bell_redesign_d6_player_facing_polish/phase0md6_player_facing_polish_static_validator.py`.

Implementation update 2026-07-04 Phase 16: Taco production adoption now uses `src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd`, a dormant mission-local controller placed under `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn::GameplayRoot/PlugAndPlayPilot`, plus `src/missions/iso/dev/Phase16GarageDeniabilityDevTrigger.gd` as a dev-only callable route trigger. It extends `EncounterController` and composes `PaperTrailAdapter`, `SocialStealthAdapter`, and `ReactiveNpcBrainAdapter` for clean social, Bentley, evidence, messy authority-report, and cleanup/redirect routes while preserving Phase0J/Phase0K authority and `MissionInteractionBridge.include_legacy_candidates = false`.

Implementation update 2026-07-04 Phase 17 + Level-Builder Readiness: route activation now happens through F12 QA-only controls in `MissionQAChecklistPanel`; `IsoMissionDebugPanel` and `MissionResult` show the selected route label; Mission Dock Assist Browser audits Phase 16/17 readiness and bridge scope; `NewMissionStarterTemplate.tscn` and `Phase17LevelBuilderReadinessProofRoom.tscn` provide the reusable level-building proof path. Jake manually QA-confirmed canonical bag/code/Louis flow and route-label mapping after Phase 16/17; player-facing Taco route activation is now cleared for the next packet.

Implementation update 2026-07-04 Phase 18: player-facing Taco route activation now follows the authored-mechanic chain: `EncounterRouteActionNode -> Phase16GarageManagerDeniabilityController -> paper/social/encounter/reactive adapters -> MissionResult`. Four authored Taco route Area2Ds are placed under `GameplayRoot/PlugAndPlayPilot/Phase18GarageRouteActions`, gated by the existing Phase0K `code_gate_unlocked` state, and mutually locked by mission flag `phase18_garage_route_selected`. The route action remains reusable through completed-objective, mission-flag, and optional controller-bool gates; it allowlists controller methods, records route/style flags, and is visible to Mission Dock audit. Post-QA fixes add prompt feedback and make Phase0J defer input near Phase 18 route actions. No Phase0J/Phase0K rewrite, new global manager, or legacy-candidate bridge expansion was added.

Implementation update 2026-07-04 Corner Store Cashout production mission (COMPLETED): Full production-intent second mission `corner_store_cashout` — playable scene, mission-local controllers, Taco Bell unlock wiring, MissionCompletionBridge extraction path, integrated proof harness, validator 77/77, GdUnit 12/12, headless scene load PASS. JSON summary: `docs/reports/corner_store_cashout_production_skeleton/corner_store_cashout_production_skeleton_validation.json`. Report: `reports/ai/2026-07-04_corner_store_cashout_production_skeleton_report.md`.

Audit update 2026-07-05 Corner Store Cashout (Fable 5): the 2026-07-04 "COMPLETED" state was not playable end-to-end — route action NodePaths and the DebugProof node name were broken, and new hideout type-inference errors regressed the F10 debug panel in all iso missions. All repaired minimally, scene regenerated, validator hardened to 79 checks, GdUnit `mission_authoring` 318/318, Taco/MainMenu/CornerStore headless smokes clean. Status: repaired and ready for Jake's manual playtest. Report: `reports/ai/2026-07-05_corner_store_cashout_fable5_audit_report.md`.

Implementation update 2026-07-04 second-level readiness self-test: repo-local tooling and plug-and-play contracts are ready for a second production mission skeleton. Validated bridges (`MissionInteractionBridge`, `MissionFactBridge`, `MissionObjectiveBridge`, `MissionCompletionBridge`, `MissionDialogueBridge`, `MissionEffectApplier`, `RequirementSet`, `EffectSet`, `MissionAlertController`), Mission Dock palette/audit (including `EncounterRouteActionNode`), tile palettes, headless scene loads, Phase 2K–18 validators, and GdUnit `306/306`. Godot MCP Pro editor connection is an external prerequisite for MCP runtime inspection. JSON summary: `docs/reports/second_level_readiness_selftest/second_level_readiness_selftest.json`. Report: `reports/ai/2026-07-04_second_level_readiness_selftest_report.md`.

Implementation update 2026-07-04 Corner Store Cashout production skeleton: second playable iso mission uses the Phase 17/18 non-Taco pattern — mission-local controllers, authored `EncounterRouteActionNode` cleanup routes, `ExtractionZone` objective gating, `RequirementSet` on locked doors, and hideout resolver launch. Scene generator + static validator under `src/tools/editor/corner_store_cashout_production_skeleton/`. Validation JSON: `docs/reports/corner_store_cashout_production_skeleton/corner_store_cashout_production_skeleton_validation.json`. Report: `reports/ai/2026-07-04_corner_store_cashout_production_skeleton_report.md`.

Implementation update 2026-07-09 Level Blueprint System (dev-only design overlay): the visual/authoring pipeline gains a blueprint tracing layer that fits the Phase 3 debug/authoring-overlay vocabulary without touching production art roots. Deterministic spec files under `docs/blueprints/` are rendered by `AuthoringBlueprintLayer` (draw-only `@tool` Node2D, self-frees at runtime, stripped again by `Phase0JRuntimeAuthoringHider`); `LevelBlueprintSpec.gd` owns schema/coverage logic and keeps CATEGORY_BY_TYPE in enforced parity with Mission Dock `MECHANIC_TYPES` (validator + GdUnit). Mission Dock adds read-only "Place From Blueprint" prefill and blueprint-coverage audit issues (`blueprint_coverage`, `blueprint_slot_missing`, `blueprint_slot_type_mismatch`). No new runtime manager, no parallel mission format, no scene mutation from the overlay. Guide: `docs/How to Use/Level Blueprints.md`. Report: `reports/ai/2026-07-09_level_blueprint_system_report.md`.

Implementation update 2026-07-09 Velvet Paw Jazz Club production skeleton (COMPLETED): the first full 68-slot blueprint-authored mission validates the intended layering at production scale: placed mechanics -> typed `RequirementSet`/`EffectSet` Resources -> existing fact/dialogue/objective/security bridges -> mission-local `VelvetPawJazzClubMissionController` -> existing authoritative managers. `MissionInteractionBridge.include_legacy_candidates` remains false; the controller adds no global manager and owns only Velvet Paw objective synchronization, authored clue-to-flag adaptation, wrong-note security-event routing, and the three existing Velvet Paw `GameState` side effects. Coverage is 68/68 with no missing/mismatched slots; both static validators pass; focused GdUnit passes 16/16 and full `mission_authoring` passes 410/410. Report: `reports/ai/2026-07-09_velvet_paw_full_mission_build_report.md`.

Implementation update 2026-07-11 Velvet Paw collision milestone (AUTOMATED CLOSEOUT PASS): collision remains separated from visuals and authoritative mission flow. Blueprint contract regions feed `LevelBlueprintLayoutPainter`; `TileDataPromotionHelper` permits only four exact layout-layer payload insertions; `IsoMissionBase` forward-syncs the persisted 9,996 floor cells and 1,996 unique blocking cells; mission-local `LayoutWallCellCollisionGenerator` derives 1,420 transform-aware expanded wall polygons; and five existing Velvet mechanics control six mission-local dynamic shapes through their established collision-disable arrays. The only shared runtime change is ownership-safe disposal of unused detached `IsoMissionBase` fallbacks. The only controller repair is the Velvet return-teleport relative path. No new autoload, global collision manager, shared TileSet collision, reverse-sync change, or Taco production change was introduced. Validation passes both static validators, focused 51/51, full `mission_authoring` 449/449 with zero orphans, clean-exit harness, Velvet/Taco/MainMenu smokes, and exact structural/signature checks. Manual visual/playable QA and lower-spec profiling remain open. Consolidated report: `reports/ai/2026-07-11_velvet_paw_collision_phases3_to7_final_report.md`.

Implementation follow-up 2026-07-11 Velvet Paw blockout visibility: preserve the validated 9,996-cell floor baseline plus current intentional non-colliding additions, and require runtime floor to exactly match the authoritative source rather than hard-coding a mutable post-closeout count. Render suppression is separate from gameplay data: set `visible = false` on `GameplayFloorLayer`, `GameplayCollisionLayer`, and all populated `LayoutRoot` floor/wall/cover/collision-barrier layers; keep `enabled = true`, retain all `tile_map_data`, and keep runtime `GameplayCollisionLayer.collision_enabled = true`. Because Godot can omit visibility properties from initially empty destination layers during an editor save, the mission-local controller also reapplies suppression in `_ready()`. This serialized-plus-runtime configuration is now a required final gate when applying the seven-phase collision protocol to future missions.

Implementation update 2026-07-11 Velvet Paw Route Component 1: grouped implementation extended existing bridge-first contracts rather than adding managers. `DialogueManager`/`DialogueBox` now support opt-in timed non-manual lines; `DialogueTriggerZone` preserves explicit line payloads and reliable no-key fallbacks. `SocialStealthAdapter` exposes targeted cover/credential removal and the existing F12 QA panel provides a Velvet-only Normal/VIP selector. `MissionInteractionBridge` is E-only and refreshes the existing control hint; Player Q delegates to one mission-local `MissionCaseHintProvider`, which selects `CaseHintDefinition` Resources by RequirementSet, distance, priority, and cooldown and emits a dedicated HUD toast. Velvet retains its 68-slot blueprint while adding mission-local front presentation/entry helpers, a dynamic rope, VIP inspection rules, eavesdrop/phone/dead-drop effects, and stable future Taco entitlement ID `velvet_paw_vip_access`. The generic `IsoMissionBase.layout_collision_excluded_cells` contract and wall-proxy filtering let authored dynamic openings retain source paint without duplicate runtime collision. Report: `reports/ai/2026-07-11_velvet_paw_route_component_1_report.md`.

Implementation follow-up 2026-07-11 Velvet Paw Route Component 1 polish: timed rejection lines are 2.5 seconds each and dialogue UI owns a dedicated Enter-to-close path that remains available even when line metadata disables E advance and Skip. The approved alley fallback is `There are too many colognes. And none of them smell as good as my expression.` For spatial concealment, keep the full mission on one authored canvas and add no global manager: `VelvetPawJazzClubMissionController` creates seven high-Z, non-colliding `Polygon2D` curtains from the blueprint floor-region rectangles, keeps only the player's current region uncovered, retains the prior region through doorway bands, and refreshes after all Velvet teleports. This preserves all node paths, collision, mechanics, entities, and future art while preventing disconnected or adjacent regions from leaking into the active view. Report: `reports/ai/2026-07-11_velvet_paw_route_component_1_polish_report.md`.

Implementation update 2026-07-11 Velvet Paw Route Component 2 feedback pass: preserve the existing manager hierarchy and make the smallest reusable contract repairs. `AudioManager` owns cue identity and same-cue no-op behavior; `MusicTriggerZone` supplies stable authored cue keys; `MissionInteractionBridge` performs collision-layer LOS before selecting any global E candidate; `MissionSecurityCamera` owns its generic visible body; and `GuardSpawnAuthor.spawn_on_ready` remains opt-in while the Velvet controller performs one post-startup retry because `IsoMissionBase` attempt cleanup can remove authored guards created during initial setup. Initial patrol guards are tagged ambient rather than security-response guards, preserving alarm cleanup semantics. Mission-local controller responsibilities add scene-wide overlay construction, music interruption on alert/hostile state, and hidden generic blueprint-marker suppression. The existing F12 `MissionQAChecklistPanel` owns the Velvet-only `Red Map Overlay` checkbox; the overlay discovers and labels relevant runtime collision objects, gameplay groups, and authoring zones without adding another manager or keyboard shortcut. Scene-authored Component 2 effects provide bar-cover, automatic inspection, protocol, and Bentley dialogue feedback. Tests cover the authored contract, F12 toggle, runtime cameras/guards/overlay, and wall-blocked interaction. Report: `reports/ai/2026-07-11_velvet_paw_route_component_2_feedback_report.md`.

Implementation update 2026-07-12 Velvet Paw Route Component 2 security/playability closeout: no new authoritative manager was added. `MissionAlertController` owns an opt-in camera policy and suspicious-action registry; `MechanicAreaBase` opens that registry only during authored hold interactions; `Player` owns reference-counted forced-stealth sources used by `HideSpotNode`; and `MissionSecurityCamera` applies one detection contract to gameplay and its ray-fan visual, including physics and `CoverLayer` occlusion. `EnemyBase` now supplies reusable facing-cone LOS awareness with buildup/decay, while `Guard` adds optional social-cover suppression and noise investigation; `GuardSpawnAuthor` binds those policies and routes spotting to the existing alert controller. Velvet's scene configures twelve authored cameras, six patrol routes/guards, four suspicious objective pickups, two explicit rear-room social-cover bypasses, and a mission-local post-startup camera reconciliation parallel to the existing guard retry. `DogCompanion` records marker-specific wait state; `ProtocolZone` can require that marker and distance. VIP phone/dead-drop/polaroid rewards remain Resource/fact/autoload driven through existing systems. Validation: focused 64/64, full 495/495, zero orphans, 120-frame production smoke. Report: `reports/ai/2026-07-12_velvet_paw_route_component_2_security_playability_report.md`.

Implementation follow-up 2026-07-12 Velvet Paw VIP/security repair: preserve the same manager hierarchy. `VelvetPawJazzClubMissionController` coordinates only the mission-local VIP gate, Bentley threshold dialogue/action registration, alarm fan-out, protocol-plus-voicemail-gated polaroid, and club-entry music. The gate reads Bentley's existing marker-specific wait state and opens at the exact authored marker; `ProtocolZone` separately retains cover plus wait-state requirements, and the phone retains its protocol requirement. `MissionSecurityCamera` and `SecurityCameraAuthor` add opt-in movement-sensitive exposure with defaults disabled; only the Velvet VIP camera enables it, now with a manual-QA-shortened 520 px range. `AudioManager` remains the sole music player, guarantees its expected named buses, and receives direct success callbacks from both club entry zones. The champagne polaroid sits beside the VIP phone and remains invisible and non-collidable until protocol and voicemail facts are both true. `GuardSpawnAuthor` gains opt-in world-space restricted-room hostility, spread response placement, and initial-awareness accounting control; default behavior remains unchanged elsewhere. `DisruptionActionNode` gains opt-in noise emission only for authored `noise`/`blackout` actions. The blueprint collision contract describes seven blockers and classifies the sole VIP opening as a Bentley-parking gate. Shared HUD renders the existing social/alert/player state rather than owning it. Focused tests cover gate collision, camera movement pause/resume, camera geometry, floor-music entry routing and bus availability, polaroid gating/placement, three-guard response, all-guard hostility, room-entry hostility, and scene wiring.

Implementation follow-up 2026-07-12 Velvet Paw Component 2 progression/QA repair: preserve one authoritative alert controller, mission-local progression coordination, and existing inventory/fact bridges. `GameState.increase_venue_heat()` and `MissionAlertController.resolve_alert()` are narrow reusable APIs consumed by a new Velvet security mode in `MissionQAChecklistPanel`; the mission controller exposes only a narrow QA-callable hostile transition. West-bar cover and three-table service completion are deliberately separate: the former continues to satisfy social inspection and floor guards, while the latter is an aggregate of three authored `BelievableTaskZone` flags that opens `StageServiceDoorBlocker`, participates in the Bentley-gated VIP opening, and gates `ProtocolZone` through its existing `RequirementSet`. `VipNorthRailBlocker` closes the geometric bypass without changing source TileMap paint. The VIP phone uses the existing in-booth search position but becomes visible/collidable only after protocol. `InventoryPickupNode` now supplies display names, polaroid pickup mirrors the persistent collectible into attempt inventory, and the briefcase Resource grants a mission inventory entry. The blueprint expands from 68 to 71 slots and seven to eight dynamic blocker contracts. No new manager, compatibility layer, or controller-input scope was added.

Implementation follow-up 2026-07-12 Velvet Paw VIP gate/music correction: continue using the same mission-local controller and shared alert/audio seams. `_vip_gate_prerequisites_met()` is now the single predicate for gate collision and protocol availability: active barback cover, three tables, and exact Bentley parking. Fixed rail and dynamic opening geometry are exact at the authored `x=2624` boundary; protocol is disabled/non-monitoring while closed and its smaller footprint is entirely inside VIP. Protocol success synchronously enables both phone and polaroid, while `polaroid_pickup.is_interaction_available()` prevents hidden pickup selection. VIP camera trespass keys explicitly from unparked Bentley rather than proximity to the player, emits two case-hint warnings, permits stationary exposure, and retains alarm reinforcement routing. The side-door music repair expands the trigger across the full physical doorway and adds club-interior position reconciliation; `AudioManager` initializes its owned Music bus and exposes debug state rendered by F12. No duplicate music player, gate manager, or suspicion manager was introduced. Controller completion remains separate scope: core analog movement/interact/combat mappings exist, but Start pause and Bentley park/stay are not wired for this scene.

Implementation follow-up 2026-07-13 guard collision checkpoint: retain one shared `guard.tscn` contract for definition-driven, authored startup, and authored reinforcement spawns. Its `CharacterBody2D` uses enemy layer 2 and mask 7; `EnemyBase` perception uses LOS mask 5 so player and layer-4 wall bodies participate without treating enemy bodies as occluders. Damage knockback is deferred because melee damage originates from an `Area2D.body_entered` physics callback, then uses `move_and_collide` rather than direct position mutation. Real-physics tests cover layer-4 movement blocking, layer-4 LOS blocking, wall-stopped knockback, and live Velvet startup/reinforcement instances. No navigation system or new manager was added; guards stop or slide at walls rather than pathfind around them.

Implementation follow-up 2026-07-13 Velvet Paw VIP countdown checkpoint 2: keep countdown ownership in the existing camera seam. `SecurityCameraAuthor` passes opt-in `minimum_exposure_seconds` and ring-readability configuration to `MissionSecurityCamera`; the runtime camera accumulates only while observed/exposure-eligible, resets on lost exposure, exposes debug progress, and renders a player-relative remaining-time ring without adding a HUD or alert manager. Defaults preserve immediate threshold behavior for every camera not opting in. Velvet configures only its VIP camera for six seconds, and `VelvetPawJazzClubMissionController` requires that camera's completed exposure before committing `vpj_vip_trespass_alarm` or spawning the existing response guards. The production scene reconciliation restores protocol/phone/gate/rail contracts and exactly nine route-blocker bodies, so the existing exact-count runtime assertion catches duplicate blocker serialization. Validation passes 41/41 focused cases, the level-blueprint validator, production scene startup, and `git diff --check`; manual ring/readability/controller QA remains separate.

Implementation follow-up 2026-07-13 Velvet Paw controller checkpoint 3: use the project-wide action map and existing authored mechanic chain rather than adding mission-local input. `src/ui/test_ui/pause_menu.gd`, which `LevelBase` instantiates in iso missions, now treats `pause` as the open/close toggle and permits `ui_cancel` only to close an already-visible menu; this preserves Escape, enables the existing joypad Start/Menu binding, and prevents controller B/cancel from opening pause during gameplay. Bentley parking uses the final Xbox layout's A/interact action: `MissionInteractionBridge` selects the production `BentleyWaitMarker`, and `DogCompanion.command_wait()` records its exact ID/position. Do not map the D-pad Down stay/heel shortcut directly to the authored marker; that polling path clears marker identity and would race the interaction. `VelvetPawControllerCheckpointTest` proves action-map wiring, pause semantics/focus, and the live production A-to-marker path. The focused gate preserves E/Q, bridge priority/LOS/cooldown, companion commands, Component 2, and runtime contracts. Physical controller feedback led to the final semantic prompts and contextual feedback documented in the GameSir controller report.

Pre-commit checkpoint 2026-07-13: the combined Component 2/controller gate executed 81 test cases; 79 passed. Controller suites passed 9/9. Four assertion failures across two Component 2 test cases all identify the same saved-scene drift: `VipNorthRailBlocker/RightRailShape` is `(2992,1600)`, size `(32,384)`, while the blueprint contract remains `(3008,1600)`, size `(64,384)`. Physics, camera, guard, and production runtime suites otherwise pass. Treat this commit as a test-needed checkpoint, not Component 2 sign-off.

Companion roadmap: `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`

## Intent

This blueprint explains how to implement the plug-and-play mission roadmap so future missions can be assembled from placed nodes and Resources instead of custom mission scripts.

The target authoring workflow is:

```text
1. Paint or block out the map.
2. Drop a reusable node into the scene.
3. Assign RequirementSet and EffectSet Resources.
4. Fill in prompt, objective, reward, dialogue, and debug fields.
5. Playtest the scene without writing mission-specific script.
```

The implementation should preserve current systems and add adapters around them.

## Current Systems To Preserve

The project already has the spine needed for this plan.

| System | Current File | Use In Blueprint |
|---|---|---|
| Mission state | `src/autoload/GameState.gd` | Authoritative source for mission ids, selected cards, completed missions, typed collectibles, evidence clues, alert state, mission performance, and mission completion/failure. |
| Objective display/state | `src/autoload/QuestManager.gd` | Authoritative objective UI and structured objective records. |
| Objective bridge | `src/missions/objectives/MissionObjectiveBridge.gd` | Existing bridge documenting split between `QuestManager` and mission-local gating. Extend this pattern. |
| Card registry | `src/inventory/CardManager.gd` | Source for loaded card Resources and selected card Resources. |
| Card effects | `src/autoload/CardEffects.gd` | Existing central card-effect helpers. Add mission modifier helpers here only when needed. |
| Scheme bridge | `src/missions/schemes/MissionSchemeBridge.gd` | Existing mission-facing card snapshot. Extend rather than bypass. |
| Dialogue | `src/autoload/DialogueManager.gd` | Use through a bridge/effect. Do not hardwire dialogue calls into every mechanic. |
| Signals/logging | `src/utils/EventBus.gd` | Emit existing signals first. Add new signals only when needed by UI/debug tooling. |
| Legacy interactables | `src/missions/iso/runtime/Phase0JInteractablePickup.gd` | Keep interface compatibility: `interact`, `on_interact`, `use`, `is_interaction_available`, `get_interaction_priority`, `is_completed`, `get_interaction_text`. |
| Legacy interaction bridge | `src/missions/iso/runtime/Phase0JInteractionBridge.gd` | Keep during migration. New bridge should support the same interface and also support new generic mechanics. |
| Authored collectibles | `src/missions/iso/authoring/CollectibleAuthorBase.gd`, `src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd` | Reuse the author node to runtime config pattern. |
| Area triggers | `src/missions/iso/authoring/AreaTriggerAuthor.gd` | Reuse preview/runtime setup ideas, but move future trigger behavior into Resource-driven mechanics. |
| Security authoring | `src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd`, security author scripts | Keep current security authoring and event routing. Add adapters only. |
| Alert state | `src/missions/iso/runtime/MissionAlertController.gd` | Extend for suspicion/alert effects. Do not duplicate alert state. |
| Input map | `project.godot` | Use existing actions: `interact`, `case_the_joint`, `bentley_ability`, `bentley_bark`, `bentley_sniff`, `bentley_fetch`, `bentley_toggle_stay`, `poop_bag_targeting`. |
| Visual depth | `ArtRoot`, `EntityRoot`, PVGames object palette containers, mission art layers | Keep fixed paint layers separate from a dedicated Y-sortable 2.5D visual layer for player/NPC/sortable props. |

## Core Rule

Do not make a giant new manager that owns everything.

Use this layering instead:

```text
Placed mechanic node
  -> RequirementSet checks
  -> EffectSet applies
  -> Thin bridges/adapters
  -> Existing authoritative managers
```

Examples:

```text
LockedInteractionNode
  -> RequirementSet says player has louis_delivery_route selected
  -> EffectSet sets mission flag loading_dock_open = true
  -> GameState stores the flag/fact through adapter helpers
```

```text
ExtractionZone
  -> RequirementSet says objective delivery_bag_recovered completed
  -> EffectSet requests mission completion
  -> GameState.complete_mission(current mission id)
```

```text
BentleyBarkDistractionPoint
  -> RequirementSet says Bentley command is available
  -> EffectSet emits noise/distraction event
  -> MissionAlertController or future Noise system reacts
```

## Accelerated Grouped-Milestone Operating Mode

Jake wants the remaining game-system roadmap implemented in larger, complete chunks so level building can start on top of finished systems, not minimal placeholders. The implementation strategy is high-risk with guardrails.

### Packet Shape

Prefer grouped milestones over isolated one-file slices when systems naturally connect. A good grouped packet may include several labeled phase slices, such as:

```text
Phase 4B scene proof
Phase 4C template/validator
Phase 4D debug readability
```

or:

```text
Phase 5A inventory Resources
Phase 5B mission inventory state
Phase 5C requirement/effect integration
Phase 5D pickup node + dev proof
```

If the grouped packet becomes unstable, narrow the work to 2-3 tightly related slices and continue from the last validated boundary.

### Completion Checklist

For each grouped milestone, complete as many of these as apply:

1. Runtime code.
2. Resource/data classes.
3. Requirement/effect/fact integration.
4. Focused GdUnit tests and broader affected-suite tests.
5. Dev scene or production scene proof.
6. Template scenes for authorable nodes where useful.
7. Static validators where useful.
8. Mission Dock or authoring integration when relevant.
9. Debug/readability output.
10. Roadmap/blueprint/docs/report updates.
11. Nowledge Mem handoff per phase packet.

### Manager Policy

Default to adapters and mission-local state. Add a dedicated manager only when the system needs authoritative state across multiple mechanics, missions, or result screens.

Likely manager candidates:

- Mission inventory / heist-kit state.
- Paper-trail event state.
- Mission rating/result aggregation.

Likely adapter-first systems:

- Suspicion/alert extensions through `MissionAlertController`.
- Security event consequences through `SecurityEventRouter` and `EffectSet`.
- Scheme-card mission modifiers through `MissionSchemeBridge`, `MissionModifierSet`, and placed nodes.

### Validation Policy

For bigger swings, run automated tests plus at least one Godot scene/headless smoke when feasible. For production Taco changes, provide a manual QA checklist and prefer Jake's manual confirmation before a grouped milestone commit.

## Recommended Future File Layout

Use the existing `src/missions/iso` area for the first implementation because the current real authored mission systems already live there. Avoid moving existing files during the first pass.

Add these folders during implementation:

```text
src/missions/iso/authoring/core/
src/missions/iso/authoring/mechanics/
src/missions/iso/runtime/authoring/
scenes/missions/iso/authoring/
resources/mission_authoring/
tests/mission_authoring/
```

Add these editor-tooling folders only after the underlying runtime/mechanic path is stable:

```text
addons/mission_paint_dock/
addons/mission_authoring_palette/
addons/mission_assist_browser/
addons/scene_asset_browser/
src/tools/editor/character_animation_mapper/
resources/character_animation_maps/
resources/mission_sequences/
```

Optional plugin integrations must stay behind project-owned bridge scripts. Do not call PhantomCamera, Resonant, LimboAI, or any other optional plugin directly from placed mechanics.

Recommended scripts for Phase 1:

| Future File | Class Name | Type | Purpose |
|---|---|---|---|
| `src/missions/iso/authoring/core/MissionFactBridge.gd` | `MissionFactBridge` | `RefCounted` | Static query/apply helpers over `GameState`, `QuestManager`, `CardManager`, `CardEffects`, `MissionSchemeBridge`, and `MissionAlertController`. |
| `src/missions/iso/authoring/core/MissionRequirement.gd` | `MissionRequirement` | `Resource` | One atomic requirement row. |
| `src/missions/iso/authoring/core/RequirementSet.gd` | `RequirementSet` | `Resource` | A group of requirements using all/any/none logic. |
| `src/missions/iso/authoring/core/MissionEffect.gd` | `MissionEffect` | `Resource` | One atomic effect row. |
| `src/missions/iso/authoring/core/EffectSet.gd` | `EffectSet` | `Resource` | Ordered list of effects to apply. |
| `src/missions/iso/authoring/core/MissionEffectApplier.gd` | `MissionEffectApplier` | `RefCounted` | Applies `MissionEffect` rows to existing managers. |
| `src/missions/iso/authoring/core/MissionDialogueBridge.gd` | `MissionDialogueBridge` | `RefCounted` | Thin wrapper over `DialogueManager`. |
| `src/missions/iso/authoring/core/MissionCompletionBridge.gd` | `MissionCompletionBridge` | `RefCounted` | Thin wrapper over scene completion methods and `GameState.complete_mission` / `GameState.fail_mission`. |
| `src/missions/iso/runtime/authoring/MissionInteractionBridge.gd` | `MissionInteractionBridge` | `Node` | General interaction bridge for new mechanics while preserving Phase0J interface compatibility. |
| `src/missions/iso/authoring/mechanics/MechanicAreaBase.gd` | `MechanicAreaBase` | `Area2D` | Base class for placed interactable/trigger mechanics. |
| `src/missions/iso/authoring/mechanics/TriggerZone.gd` | `TriggerZone` | `MechanicAreaBase` | First proof node. Automatic or interact-required trigger. |

Recommended scenes for Phase 1:

| Future Scene | Purpose |
|---|---|
| `scenes/missions/iso/authoring/MechanicAreaBase.tscn` | Base scene with `Area2D`, collision shape, optional preview label. |
| `scenes/missions/iso/authoring/TriggerZone.tscn` | Drop-in trigger node scene. |
| `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` | Tiny validation scene for requirements/effects/interaction behavior. |

Recommended test files for Phase 1:

| Future Test | Purpose |
|---|---|
| `tests/mission_authoring/RequirementSetTest.gd` | Verifies requirement evaluation. |
| `tests/mission_authoring/EffectSetTest.gd` | Verifies effect ordering and result reporting. |
| `tests/mission_authoring/MissionFactBridgeTest.gd` | Verifies fact reads from existing managers without mutating unrelated state. |
| `tests/mission_authoring/MechanicAreaBaseTest.gd` | Verifies one-shot, prompt text, locked text, and activation results. |

## Shared Result Dictionary Contract

Every bridge, requirement, effect, and mechanic should return dictionaries with the same shape.

Use this schema everywhere:

```gdscript
{
    "ok": true,
    "code": "success",
    "message": "Human-readable designer/debug text.",
    "source_id": "node_or_resource_id",
    "details": {},
}
```

Rules:

1. `ok` is always a bool.
2. `code` is always a stable snake_case string.
3. `message` is always safe to show in a debug panel.
4. `source_id` identifies the node, requirement, or effect that produced the result.
5. `details` contains extra data for tests/debug panels.
6. Do not return raw `null` for failure.
7. Do not throw errors for normal designer mistakes such as missing optional Resources; return a failure result and push a warning only when useful.

Failure example:

```gdscript
{
    "ok": false,
    "code": "missing_required_card",
    "message": "Requires selected card: louis_delivery_route.",
    "source_id": "req_loading_dock_card",
    "details": {"card_id": "louis_delivery_route"},
}
```

Effect result example:

```gdscript
{
    "ok": true,
    "code": "objective_completed",
    "message": "Completed objective: delivery_bag_recovered.",
    "source_id": "effect_complete_delivery_bag",
    "details": {"mission_id": "taco_bell_drop", "objective_id": "delivery_bag_recovered"},
}
```

## Mission Context Dictionary Contract

Requirement and effect code should accept a context dictionary so mechanics stay reusable.

Use this context schema:

```gdscript
{
    "mission_id": "taco_bell_drop",
    "actor": player,
    "mechanic": self,
    "source_id": "loading_dock_gate",
    "source_path": str(get_path()),
    "position": global_position,
    "debug": true,
}
```

Rules:

1. `mission_id` should be resolved from explicit export first, then current scene mission definition, then `GameState.current_mission_id`.
2. `actor` is usually the player, but the contract must allow Bentley or NPC actors later.
3. `mechanic` is the node applying the requirement/effect.
4. `source_id` should be stable and designer-authored.
5. `source_path` is for debug only; do not persist it.
6. `position` enables event payloads and guard/noise routing later.

## Phase 1A: MissionFactBridge

### Purpose

`MissionFactBridge` is the one place where requirements and effects translate high-level fact names into current project systems.

It must not be an autoload at first. Make it `RefCounted` with static methods.

### Future File

`src/missions/iso/authoring/core/MissionFactBridge.gd`

### Class Header

```gdscript
class_name MissionFactBridge
extends RefCounted
```

### Required Static Methods

```gdscript
static func resolve_mission_id(context: Dictionary = {}) -> String
static func evaluate_fact(fact_type: StringName, key: String, expected: Variant = true, context: Dictionary = {}) -> Dictionary
static func get_fact_value(fact_type: StringName, key: String, context: Dictionary = {}) -> Variant
static func set_fact_value(fact_type: StringName, key: String, value: Variant, context: Dictionary = {}) -> Dictionary
static func has_autoload(name: String) -> bool
static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary
```

### Initial Fact Types

Use string names instead of hard enum dependencies so new facts can be added without breaking saved Resources.

| Fact Type | Key Example | Expected Example | Read From | Notes |
|---|---|---|---|---|
| `always` | empty | `true` | none | Always passes. |
| `mission_id` | empty | `taco_bell_drop` | context/GameState | Useful for mission-specific authorables. |
| `mission_completed` | `taco_bell_drop` | `true` | `GameState.has_completed()` | Existing API exists. |
| `selected_card` | `louis_delivery_route` | `true` | `GameState.has_selected_card()` | Existing API exists. |
| `unlocked_card` | `mere_legal_eyes` | `true` | `GameState.has_scheme_card()` or `GameState.unlocked_cards` | Prefer `has_scheme_card` because it merges registries. |
| `scheme_effect` | `delivery_route_access` | `true` | `MissionSchemeBridge.has_scheme_effect()` | Existing bridge exists. |
| `typed_collectible` | `OBJ_bag_recovery` | `true` | `GameState.typed_collectibles` | Check key existence. |
| `typed_collectible_type_count` | `poop_bag` | `3` | `GameState.typed_collectibles` | Count records where `type` or `collection_group` matches. |
| `evidence_clue` | `sterling_invoice` | `true` | `GameState.has_evidence_clue()` | Existing API exists. |
| `crew_assist` | `louis_delivery_route_assist` | `true` | `GameState.has_crew_assist()` | Existing API exists. |
| `objective_active` | `delivery_bag_recovered` | `true` | `QuestManager.has_objective()` plus status check | Current `has_objective` checks record presence, not active status. Bridge should inspect records carefully. |
| `objective_completed` | `delivery_bag_recovered` | `true` | `QuestManager.is_objective_completed()` | Existing API exists. |
| `alert_state` | empty or mission id | `alerted` | `GameState.get_mission_alert_state()` | Existing API exists. |
| `dialogue_flag` | `met_louis` | `true` | `GameState.dialogue_flags` | Existing dictionary exists. |
| `mission_flag` | `loading_dock_open` | `true` | New namespace inside `GameState.dialogue_flags` initially | Use namespaced keys until a dedicated mission flag dictionary is justified. |
| `poop_bag_count` | empty | `1` | `GameState.get_poop_bag_count()` | Existing API exists. |

### Mission Flag Storage Rule

Do not add a new saved dictionary in the first implementation unless tests prove it is necessary.

Use namespaced `GameState.dialogue_flags` keys for early mission flags:

```text
mission_flag:<mission_id>:<flag_id>
```

Example:

```text
mission_flag:taco_bell_drop:loading_dock_open
```

Reason:

`dialogue_flags` is already serialized in `GameState.to_dict()` and restored in `from_dict()`. This avoids save migration in the first pass.

Later, if mission flags grow beyond dialogue-style booleans, add a dedicated `mission_flags` dictionary in a save-versioned migration.

### MissionFactBridge Set Operations

Initial write support should be limited and explicit.

| Settable Fact Type | Operation |
|---|---|
| `mission_flag` | Set namespaced `GameState.dialogue_flags` value. |
| `dialogue_flag` | Set `GameState.dialogue_flags[key]`. |
| `alert_state` | Call `GameState.set_mission_alert_state(mission_id, value)`. |
| `selected_card` | Do not set directly from mechanics. Return unsupported. |
| `unlocked_card` | Call `GameState.unlock_card(card_id)`. |
| `evidence_clue` | Call `GameState.record_evidence_clue()` or `ensure_and_discover_sterling_clue()` only if enough data is supplied. |
| `typed_collectible` | Call `GameState.record_typed_collectible()`. |
| `poop_bag_count` | Prefer `GameState.add_poop_bag()` or `try_consume_poop_bag()` effects, not arbitrary assignment. |

## Phase 1B: MissionRequirement Resource

### Purpose

`MissionRequirement` is one editable row in the inspector.

### Future File

`src/missions/iso/authoring/core/MissionRequirement.gd`

### Class Header

```gdscript
@tool
class_name MissionRequirement
extends Resource
```

### Exported Fields

```gdscript
enum Operator {
    EQUALS,
    NOT_EQUALS,
    EXISTS,
    NOT_EXISTS,
    GREATER_THAN,
    GREATER_OR_EQUAL,
    LESS_THAN,
    LESS_OR_EQUAL,
}

@export var requirement_id: StringName = &"requirement"
@export var enabled: bool = true
@export var fact_type: StringName = &"always"
@export var key: String = ""
@export var operator: Operator = Operator.EQUALS
@export var expected_bool: bool = true
@export var expected_int: int = 1
@export var expected_float: float = 1.0
@export var expected_string: String = ""
@export_enum("bool", "int", "float", "string", "exists") var expected_value_type: String = "bool"
@export var fail_message: String = ""
@export var debug_note: String = ""
```

### Required Methods

```gdscript
func evaluate(context: Dictionary = {}) -> Dictionary
func get_expected_value() -> Variant
func get_designer_summary() -> String
```

### Evaluation Rules

1. Disabled requirements pass with code `disabled_requirement`.
2. `fact_type == &"always"` passes.
3. Unknown fact types fail with code `unknown_fact_type`.
4. Missing autoloads fail safely with code `autoload_missing`.
5. `EXISTS` ignores expected value and only checks that fact value is not null/empty/false depending on type.
6. `NOT_EXISTS` passes when the value is null, false, empty string, or missing.
7. String comparisons should be exact after `strip_edges()`, not fuzzy.
8. Numeric comparisons should convert with `int()` or `float()` only after type checks.

### Designer Summary Examples

```text
Requires selected_card louis_delivery_route == true
Requires objective_completed delivery_bag_recovered == true
Requires typed_collectible_type_count poop_bag >= 3
Requires mission_flag loading_dock_open exists
```

## Phase 1C: RequirementSet Resource

### Purpose

`RequirementSet` groups requirements into all/any/none logic and returns a detailed evaluation report.

### Future File

`src/missions/iso/authoring/core/RequirementSet.gd`

### Class Header

```gdscript
@tool
class_name RequirementSet
extends Resource
```

### Exported Fields

```gdscript
enum MatchMode {
    ALL,
    ANY,
    NONE,
}

@export var set_id: StringName = &"requirements"
@export var enabled: bool = true
@export var match_mode: MatchMode = MatchMode.ALL
@export var requirements: Array[MissionRequirement] = []
@export var empty_set_passes: bool = true
@export var locked_message: String = ""
@export var debug_note: String = ""
```

### Required Methods

```gdscript
func evaluate(context: Dictionary = {}) -> Dictionary
func passes(context: Dictionary = {}) -> bool
func get_failure_message(context: Dictionary = {}) -> String
func get_designer_summary() -> String
```

### Evaluation Result Details

`evaluate()` should return:

```gdscript
{
    "ok": true,
    "code": "requirements_passed",
    "message": "All requirements passed.",
    "source_id": String(set_id),
    "details": {
        "match_mode": "ALL",
        "passed_count": 2,
        "failed_count": 0,
        "results": [],
    },
}
```

### Match Mode Rules

| Mode | Passes When |
|---|---|
| `ALL` | Every enabled requirement passes. |
| `ANY` | At least one enabled requirement passes. |
| `NONE` | No enabled requirement passes. |

### Empty Set Rule

Most placed mechanics should be usable by default. Therefore `empty_set_passes` should default to `true`.

Use `empty_set_passes = false` only for nodes that must be explicitly configured before use.

## Phase 1D: MissionEffect Resource

### Purpose

`MissionEffect` is one ordered action applied when a mechanic succeeds or fails.

### Future File

`src/missions/iso/authoring/core/MissionEffect.gd`

### Class Header

```gdscript
@tool
class_name MissionEffect
extends Resource
```

### Exported Fields

```gdscript
enum EffectType {
    SET_MISSION_FLAG,
    CLEAR_MISSION_FLAG,
    SET_DIALOGUE_FLAG,
    ACTIVATE_OBJECTIVE,
    COMPLETE_OBJECTIVE,
    FAIL_OBJECTIVE,
    SET_PRIMARY_OBJECTIVE_TEXT,
    GRANT_CARD,
    GRANT_TYPED_COLLECTIBLE,
    GRANT_EVIDENCE_CLUE,
    ADD_POOP_BAG,
    CONSUME_POOP_BAG,
    SET_ALERT_STATE,
    ADD_ALERT_EXPOSURE,
    TRIGGER_DIALOGUE_KEY,
    TRIGGER_SIMPLE_DIALOGUE,
    EMIT_EVENTBUS_DEBUG,
    REQUEST_MISSION_COMPLETE,
    REQUEST_MISSION_FAIL,
    TOGGLE_NODE,
    CALL_METHOD,
}

@export var effect_id: StringName = &"effect"
@export var enabled: bool = true
@export var effect_type: EffectType = EffectType.SET_MISSION_FLAG
@export var key: String = ""
@export var value_bool: bool = true
@export var value_int: int = 1
@export var value_float: float = 1.0
@export var value_string: String = ""
@export_enum("bool", "int", "float", "string", "dictionary") var value_type: String = "bool"
@export var payload: Dictionary = {}
@export var target_path: NodePath
@export var method_name: StringName = &""
@export var debug_note: String = ""
```

### Required Methods

```gdscript
func apply(context: Dictionary = {}) -> Dictionary
func get_value() -> Variant
func get_designer_summary() -> String
```

### Effect Application Rule

`MissionEffect.apply()` should delegate to `MissionEffectApplier.apply_effect(self, context)`.

Reason:

Resources should hold data and small helpers. The applier should own manager lookups and side effects.

## Phase 1E: EffectSet Resource

### Purpose

`EffectSet` applies multiple `MissionEffect` Resources in deterministic order.

### Future File

`src/missions/iso/authoring/core/EffectSet.gd`

### Class Header

```gdscript
@tool
class_name EffectSet
extends Resource
```

### Exported Fields

```gdscript
@export var set_id: StringName = &"effects"
@export var enabled: bool = true
@export var effects: Array[MissionEffect] = []
@export var stop_on_failure: bool = false
@export var debug_note: String = ""
```

### Required Methods

```gdscript
func apply_all(context: Dictionary = {}) -> Dictionary
func is_empty() -> bool
func get_designer_summary() -> String
```

### Apply Result Details

```gdscript
{
    "ok": true,
    "code": "effect_set_applied",
    "message": "Applied 3 effects.",
    "source_id": String(set_id),
    "details": {
        "applied_count": 3,
        "failed_count": 0,
        "results": [],
    },
}
```

### Ordering Rule

Effects must run in array order.

Common order examples:

```text
1. Set mission flag
2. Complete objective
3. Trigger dialogue
4. Emit debug event
```

```text
1. Grant collectible
2. Complete objective
3. Request extraction
```

## Phase 1F: MissionEffectApplier

### Purpose

`MissionEffectApplier` is the centralized side-effect dispatcher.

### Future File

`src/missions/iso/authoring/core/MissionEffectApplier.gd`

### Class Header

```gdscript
class_name MissionEffectApplier
extends RefCounted
```

### Required Static Methods

```gdscript
static func apply_effect(effect: MissionEffect, context: Dictionary = {}) -> Dictionary
static func _apply_set_mission_flag(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _apply_clear_mission_flag(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _apply_objective(effect: MissionEffect, context: Dictionary, action: String) -> Dictionary
static func _apply_card(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _apply_typed_collectible(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _apply_evidence_clue(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _apply_alert(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _apply_dialogue(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _apply_completion(effect: MissionEffect, context: Dictionary, success: bool) -> Dictionary
static func _apply_toggle_node(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _apply_call_method(effect: MissionEffect, context: Dictionary) -> Dictionary
static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary
```

### Effect Type Mapping

| Effect Type | Implementation |
|---|---|
| `SET_MISSION_FLAG` | `MissionFactBridge.set_fact_value(&"mission_flag", effect.key, effect.get_value(), context)` |
| `CLEAR_MISSION_FLAG` | Set namespaced mission flag to `false` or erase if helper supports erase. |
| `SET_DIALOGUE_FLAG` | `GameState.dialogue_flags[effect.key] = effect.get_value()` |
| `ACTIVATE_OBJECTIVE` | `QuestManager.add_objective(effect.key, text, "active", mission_id)` |
| `COMPLETE_OBJECTIVE` | `QuestManager.complete_objective_id(effect.key, text, mission_id)` |
| `FAIL_OBJECTIVE` | `QuestManager.add_objective(effect.key, text, "failed", mission_id)` |
| `SET_PRIMARY_OBJECTIVE_TEXT` | `QuestManager.set_objective(effect.value_string, mission_id)` |
| `GRANT_CARD` | `GameState.unlock_card(effect.key)` |
| `GRANT_TYPED_COLLECTIBLE` | `GameState.record_typed_collectible(effect.key, type, payload)` |
| `GRANT_EVIDENCE_CLUE` | `GameState.record_evidence_clue(effect.key, payload)` or `GameState.ensure_and_discover_sterling_clue(effect.key, payload)` |
| `ADD_POOP_BAG` | `GameState.add_poop_bag()` |
| `CONSUME_POOP_BAG` | `GameState.try_consume_poop_bag()` |
| `SET_ALERT_STATE` | Prefer local `MissionAlertController.set_alert_state()` if in scene; also syncs to `GameState`. Fallback to `GameState.set_mission_alert_state()`. |
| `ADD_ALERT_EXPOSURE` | Find `MissionAlertController` in group or scene and call `accumulate_exposure(source_id, amount, kind)`. |
| `TRIGGER_DIALOGUE_KEY` | `MissionDialogueBridge.play_dialogue_key(effect.key, context)` |
| `TRIGGER_SIMPLE_DIALOGUE` | `MissionDialogueBridge.play_simple_line(effect.payload, context)` |
| `EMIT_EVENTBUS_DEBUG` | `EventBus.debug(effect.value_string)` |
| `REQUEST_MISSION_COMPLETE` | `MissionCompletionBridge.request_complete(mission_id, context)` |
| `REQUEST_MISSION_FAIL` | `MissionCompletionBridge.request_fail(mission_id, reason, context)` |
| `TOGGLE_NODE` | Resolve `target_path`, set `visible`, `process_mode`, `monitoring`, or `disabled` according to payload. |
| `CALL_METHOD` | Resolve `target_path`, call `method_name` with optional payload arguments. Keep this as escape hatch, not default pattern. |

### Safety Rules

1. `CALL_METHOD` must be disabled in exported production Resources unless explicitly reviewed.
2. `target_path` must resolve relative to the mechanic node first, then scene root if needed.
3. Missing optional systems return `ok=false` but should not crash the mission.
4. Mission-completion effects must go through `MissionCompletionBridge` so future result screens and ranking remain consistent.
5. Alert effects must use `MissionAlertController` when present so `EventBus.detection_state_changed` stays accurate.

## Phase 1G: MissionDialogueBridge

### Purpose

Mechanics should not know whether dialogue comes from `DialogueManager`, `MissionDialogueProvider`, Dialogic, or a future bark system.

### Future File

`src/missions/iso/authoring/core/MissionDialogueBridge.gd`

### Class Header

```gdscript
class_name MissionDialogueBridge
extends RefCounted
```

### Required Static Methods

```gdscript
static func play_dialogue_key(dialogue_key: String, context: Dictionary = {}) -> Dictionary
static func play_simple_line(payload: Dictionary, context: Dictionary = {}) -> Dictionary
static func play_bark(speaker: String, text: String, context: Dictionary = {}) -> Dictionary
static func is_dialogue_busy() -> bool
```

### Initial Implementation

Use `DialogueManager.start_simple_dialogue()` first.

Support these payload shapes:

```gdscript
{"speaker": "Louis", "text": "Delivery entrance is yours."}
```

```gdscript
{"lines": [{"speaker": "Bentley", "text": "Bark."}, {"speaker": "Louis", "text": "He makes a point."}]}
```

### Dialogue Key Handling

If no mission dialogue key registry exists yet, `play_dialogue_key()` should initially do one of these:

1. Look for `payload["fallback_text"]` and play it.
2. Log a debug message and return `ok=false` with code `dialogue_key_unresolved`.

Do not invent a large dialogue database in Phase 1.

## Phase 1H: MissionCompletionBridge

### Purpose

Mission completion and failure should remain routed through existing completion paths.

### Future File

`src/missions/iso/authoring/core/MissionCompletionBridge.gd`

### Class Header

```gdscript
class_name MissionCompletionBridge
extends RefCounted
```

### Required Static Methods

```gdscript
static func request_complete(mission_id: String, context: Dictionary = {}) -> Dictionary
static func request_fail(mission_id: String, reason: String = "The job went sideways.", context: Dictionary = {}) -> Dictionary
static func find_completion_controller(context: Dictionary = {}) -> Node
```

### Completion Order

Use this order for completion:

1. If context mechanic or current scene has a mission-local completion method, call it.
2. If `Phase0KMissionCompletionController` is present and appropriate, call its public completion method if one exists.
3. Fallback to `GameState.complete_mission(mission_id)`.
4. Emit useful debug output.

Use this order for failure:

1. If current scene has a mission-local failure method, call it.
2. Fallback to `GameState.fail_mission(mission_id, reason)`.
3. Emit useful debug output.

### Guardrail

Do not directly change scenes from inside `EffectSet`. Let existing `EventBus.mission_result_ready` and current scene flow handle result screens.

## Phase 1I: MechanicAreaBase

### Purpose

`MechanicAreaBase` is the base scene script for all drag-and-drop mission mechanics.

### Future File

`src/missions/iso/authoring/mechanics/MechanicAreaBase.gd`

### Class Header

```gdscript
@tool
class_name MechanicAreaBase
extends Area2D
```

### Required Signals

```gdscript
signal availability_changed(mechanic_id: String, available: bool)
signal activation_started(mechanic_id: String, actor: Node)
signal activation_succeeded(mechanic_id: String, result: Dictionary)
signal activation_failed(mechanic_id: String, result: Dictionary)
signal effects_applied(mechanic_id: String, result: Dictionary)
```

### Exported Fields

```gdscript
enum InteractionMode {
    AUTOMATIC_ON_ENTER,
    INTERACT_REQUIRED,
    SCRIPT_ONLY,
}

@export_group("Identity")
@export var mechanic_id: StringName = &"mechanic"
@export var display_name: String = ""
@export var enabled: bool = true
@export var mission_id_override: String = ""

@export_group("Interaction")
@export var interaction_mode: InteractionMode = InteractionMode.INTERACT_REQUIRED
@export var one_shot: bool = true
@export var starts_used: bool = false
@export var interaction_priority: int = 500
@export var prompt_text: String = "Press E: Interact"
@export var locked_prompt_text: String = "Unavailable"
@export var available_actor_group: StringName = &"player"
@export var action_interact: StringName = &"interact"

@export_group("Logic")
@export var requirements: RequirementSet
@export var success_effects: EffectSet
@export var failure_effects: EffectSet

@export_group("Shape")
@export var shape_size: Vector2 = Vector2(96.0, 96.0)
@export var collision_shape_path: NodePath = NodePath("CollisionShape2D")

@export_group("Debug")
@export var debug_enabled: bool = true
@export var show_debug_label: bool = true
@export var debug_label_path: NodePath = NodePath("DebugLabel")
@export var preview_color: Color = Color(0.3, 0.7, 1.0, 0.35)
```

### Runtime Fields

```gdscript
var used: bool = false
var current_actor: Node = null
var last_requirement_result: Dictionary = {}
var last_activation_result: Dictionary = {}
var last_effect_result: Dictionary = {}
```

### Required Interface Methods

These methods preserve compatibility with existing interaction patterns.

```gdscript
func interact(actor: Node = null) -> bool
func on_interact(actor: Node = null) -> bool
func use(actor: Node = null) -> bool
func is_interaction_available(actor: Node = null) -> bool
func should_show_interaction_prompt() -> bool
func get_interaction_priority(actor: Node = null) -> int
func is_completed() -> bool
func get_interaction_text() -> String
func inspect_marker(actor: Node = null) -> bool
```

### Required Internal Methods

```gdscript
func _build_context(actor: Node = null) -> Dictionary
func _evaluate_requirements(actor: Node = null) -> Dictionary
func _activate(actor: Node = null, reason: String = "interact") -> Dictionary
func _apply_success_effects(context: Dictionary) -> Dictionary
func _apply_failure_effects(context: Dictionary) -> Dictionary
func _mark_used() -> void
func _can_actor_use(actor: Node) -> bool
func _refresh_debug_label() -> void
func _designer_name() -> String
```

### Group Membership

On `_ready()`, add:

```gdscript
add_to_group("interactable")
add_to_group("mission_mechanic")
```

Do not add new mechanics to `phase0j_interactable` by default. That group is legacy-specific. The new `MissionInteractionBridge` should find `mission_mechanic` and old groups.

### Collision Rules

Use existing physics layers from `project.godot`:

```text
Layer 1: Player
Layer 4: Interactables
```

Recommended initial defaults:

```gdscript
collision_layer = 8
collision_mask = 1
monitoring = true
monitorable = true
```

### Activation Rules

1. If `enabled == false`, activation fails with code `mechanic_disabled`.
2. If `one_shot == true` and `used == true`, activation returns success-like `already_used` and does not apply effects again.
3. If actor group does not match, ignore the actor.
4. Evaluate `requirements` before success effects.
5. If requirements fail and `failure_effects` is assigned, apply failure effects.
6. If requirements pass, apply success effects.
7. If success effects pass and `one_shot == true`, mark used.
8. Update debug label after every activation attempt.

### Prompt Rules

`get_interaction_text()` should return:

1. Empty string if disabled or used one-shot.
2. `prompt_text` if requirements pass or no requirements are assigned.
3. `RequirementSet.locked_message` if requirements fail and it is non-empty.
4. `locked_prompt_text` if requirements fail and no specific locked message exists.

### Debug Label Format

Use short labels in scene:

```text
TRIGGER loading_dock_gate
READY Press E: Open loading dock
```

```text
TRIGGER loading_dock_gate
LOCKED Requires selected card: louis_delivery_route
```

```text
TRIGGER loading_dock_gate
USED
```

## Phase 1J: MissionInteractionBridge

### Purpose

The current `Phase0JInteractionBridge` only intentionally targets Phase0J/Phase0K candidates. New reusable mechanics need a general bridge that supports both old and new interfaces.

### Future File

`src/missions/iso/runtime/authoring/MissionInteractionBridge.gd`

### Class Header

```gdscript
class_name MissionInteractionBridge
extends Node
```

### Exported Fields

```gdscript
@export var player_path: NodePath
@export var action_interact: StringName = &"interact"
@export var action_scan_or_debug: StringName = &"case_the_joint"
@export var interaction_radius: float = 144.0
@export var cooldown_seconds: float = 0.20
@export var prefer_available: bool = true
@export var prefer_uncompleted: bool = true
@export var debug_enabled: bool = true
@export var prompt_target_path: NodePath
```

### Candidate Groups

Collect candidates from these groups:

```gdscript
["mission_mechanic", "interactable", "phase0j_interactable", "phase0j_marker_debug", "phase0k_louis_exit"]
```

Unlike `Phase0JInteractionBridge`, do not reject generic `interactable` nodes solely because they lack `generated_by` metadata.

### Candidate Interface

Candidate methods should be checked in this order:

```gdscript
["interact", "on_interact", "use", "inspect_marker"]
```

Priority should come from:

```gdscript
node.get_interaction_priority(player)
```

Availability should come from:

```gdscript
node.is_interaction_available(player)
```

Prompt should come from:

```gdscript
node.get_interaction_text()
```

Completion should come from:

```gdscript
node.is_completed()
```

### Sorting Order

Sort candidates by:

1. Available before unavailable if `prefer_available` is true.
2. Not completed before completed if `prefer_uncompleted` is true.
3. Higher `interaction_priority` first.
4. Shorter distance first.

### Migration Rule

Do not remove `Phase0JInteractionBridge` immediately.

First use `MissionInteractionBridge` only in the validation scene. Then add it to a controlled dev mission. Only after parity testing should production missions switch.

## Phase 1K: TriggerZone Proof Node

### Purpose

`TriggerZone` proves the foundation with the smallest useful mechanic.

### Future File

`src/missions/iso/authoring/mechanics/TriggerZone.gd`

### Class Header

```gdscript
@tool
class_name TriggerZone
extends MechanicAreaBase
```

### Extra Exported Fields

```gdscript
@export_group("Trigger")
@export var trigger_on_enter: bool = true
@export var trigger_on_exit: bool = false
@export var trigger_event_id: StringName = &""
@export var emit_security_event: bool = false
```

### Behavior

1. If `trigger_on_enter == true` and the actor enters, call `_activate(actor, "body_entered")` when `interaction_mode == AUTOMATIC_ON_ENTER`.
2. If `interaction_mode == INTERACT_REQUIRED`, do not auto-activate. Let the bridge call `interact()`.
3. If `trigger_event_id` is non-empty, include it in the context details and debug result.
4. Do not directly call `SecurityEventRouter` in the first version unless `emit_security_event` is true and a router is present.

### First Validation Nodes

Create these in `MechanicAuthoringTestRoom.tscn`:

| Node | Requirement | Effect | Expected Result |
|---|---|---|---|
| `Trigger_AlwaysObjective` | none | complete objective `test_trigger_complete` | Objective appears completed in `QuestManager`. |
| `Trigger_CardLocked` | selected card `louis_delivery_route` | set mission flag `loading_dock_open` | Locked message shows until card is selected. |
| `Trigger_Reward` | none | grant typed collectible `test_token` | `GameState.typed_collectibles` contains `test_token`. |
| `Trigger_Extraction` | objective completed `test_trigger_complete` | request mission complete | Calls completion bridge. |

## Phase 2: Core Mission Construction Nodes

After `TriggerZone` works, implement nodes in this order.

### 1. ObjectiveStepController

Future file:

`src/missions/iso/authoring/core/ObjectiveStepController.gd`

Purpose:

Provide clearer methods over `QuestManager` for authored mechanics.

Required methods:

```gdscript
static func activate_objective(objective_id: String, text: String, mission_id: String) -> Dictionary
static func complete_objective(objective_id: String, text: String, mission_id: String) -> Dictionary
static func fail_objective(objective_id: String, text: String, mission_id: String) -> Dictionary
static func is_objective_active(objective_id: String, mission_id: String) -> bool
static func is_objective_completed(objective_id: String, mission_id: String) -> bool
```

Implementation detail:

Use `QuestManager.add_objective()`, `QuestManager.complete_objective_id()`, and `QuestManager.is_objective_completed()`.

Do not replace `MissionObjectiveBridge`. Either extend it or keep this as a thin helper in the same spirit.

### 2. ExtractionZone

Future file:

`src/missions/iso/authoring/mechanics/ExtractionZone.gd`

Extends:

`MechanicAreaBase`

Extra exports:

```gdscript
@export var clean_exit_effects: EffectSet
@export var messy_exit_effects: EffectSet
@export var required_objective_ids: Array[StringName] = []
@export var optional_objective_ids: Array[StringName] = []
@export var fail_if_alerted: bool = false
@export var messy_if_alerted: bool = true
@export var extraction_tag: StringName = &"default_exit"
```

Rules:

1. Base `requirements` still run first.
2. `required_objective_ids` are converted into objective-completed checks.
3. If alert state is `alerted` and `fail_if_alerted`, apply failure effects or mission fail.
4. If alert state is `alerted` and `messy_if_alerted`, apply messy effects then complete mission.
5. Otherwise apply clean effects then complete mission.

### 3. LockedInteractionNode

Future file:

`src/missions/iso/authoring/mechanics/LockedInteractionNode.gd`

Extends:

`MechanicAreaBase`

Extra exports:

```gdscript
@export_enum("door", "gate", "safe", "terminal", "scanner", "container") var lock_kind: String = "door"
@export var unlocked_flag: StringName = &""
@export var open_on_success: bool = true
@export var locked_sound_key: StringName = &""
@export var unlocked_sound_key: StringName = &""
@export var target_visual_path: NodePath
@export var target_collision_path: NodePath
```

Rules:

1. Requirements represent the key/code/card/credential requirement.
2. Success effects should usually set `unlocked_flag` and complete or activate an objective.
3. If `open_on_success`, toggle visual/collision paths after success effects.
4. Do not create separate keypad, safe, badge, and credential classes until this generic node proves insufficient.

### 4. SearchZone

Future file:

`src/missions/iso/authoring/mechanics/SearchZone.gd`

Extends:

`MechanicAreaBase`

Extra exports:

```gdscript
@export var search_duration_seconds: float = 0.0
@export var search_flag: StringName = &""
@export var reveal_effects: EffectSet
@export var empty_effects: EffectSet
@export var suspicious_if_alerted: bool = false
```

Rules:

1. First version can be instant; timed search can be added later.
2. Success effects grant clues/items/objectives.
3. If already searched, return `already_used` and show searched prompt.
4. If `search_flag` is set, use `mission_flag:<mission_id>:<search_flag>` to persist searched state.

### 5. InteractiveContainer

Future file:

`src/missions/iso/authoring/mechanics/InteractiveContainer.gd`

Extends:

`SearchZone`

Extra exports:

```gdscript
@export_enum("drawer", "locker", "fridge", "filing_cabinet", "crate", "trash", "safe") var container_kind: String = "drawer"
@export var starts_open: bool = false
@export var close_after_search: bool = false
```

Rule:

Do not implement a separate inventory UI for containers in this phase. Containers apply effects directly.

### 6. RewardNode

Future file:

`src/missions/iso/authoring/mechanics/RewardNode.gd`

Extends:

`MechanicAreaBase`

Purpose:

A visible pickup/reward object that uses `EffectSet` rather than collectible-specific code.

Rule:

If the reward is a current typed collectible, use `GRANT_TYPED_COLLECTIBLE` so it routes through `GameState.record_typed_collectible()`.

### 7. RouteUnlockNode

Future file:

`src/missions/iso/authoring/mechanics/RouteUnlockNode.gd`

Extends:

`MechanicAreaBase`

Extra exports:

```gdscript
@export var route_id: StringName = &"route"
@export var route_flag: StringName = &""
@export var nodes_to_show: Array[NodePath] = []
@export var nodes_to_hide: Array[NodePath] = []
@export var collision_to_enable: Array[NodePath] = []
@export var collision_to_disable: Array[NodePath] = []
```

Rules:

1. Requirements define whether route is available.
2. Success effects set route flag.
3. Route node toggles visuals/collision in a deterministic local way.
4. Card-driven routes should be requirements on this node, not separate hardcoded route scripts.

## Phase 3: Visual And Authoring Pipeline

The plug-and-play system only works if designers can see what they placed.

### 2.5D Visual Depth Contract

Mission scenes should use two complementary depth systems:

1. Fixed-Z paint/overlay bands for broad layer separation.
2. A dedicated Y-sortable visual container for player/NPC/sortable props that need dynamic front/behind behavior.

Do not try to make all PVGames objects work by stacking arbitrary parent and child `z_index` values. A child sprite offset such as `-90` can appear to work in one container while breaking the mental model elsewhere because child and parent Z values compound.

### Recommended Visual Containers

For new validation scenes and future production mission scenes, use this conceptual structure:

```text
VisualRoot
  BackgroundArt
    TilePaint
    BehindPlayerObjects
  SortableWorld
    PlayerVisual or PlayerProxy
    NPCVisuals
    PVGSortableObjects
    DynamicProps
  ForegroundArt
    ForegroundObjects
    ForegroundOverlays
  DebugVisuals
```

For the current Taco scenes, do not rename existing roots immediately. Introduce the sortable layer incrementally, preferably as a small pilot under the current scene tree, then migrate only the visuals that need dynamic 2.5D sorting.

### Y-Sort Rules

Y-sort is for objects whose draw order should change when the player moves above or below them.

Use Y-sort for:

- player visual/token
- guard/NPC visuals
- tables, counters, terminals, pillars, crates, waist-height props
- PVGames object-palette stamps that should sometimes cover the player and sometimes sit behind the player

Do not use Y-sort for:

- floor paint
- ground decals
- wall/floor readability paint
- lighting overlays
- debug labels
- authoring marker overlays
- always-front foreground art

### Pivot And Origin Rules For Sortable Objects

Sortable objects must have meaningful origins. The origin used for Y-sort should represent the object's floor contact point, not the visual center of a large sprite.

Initial rules:

1. Character/player origins should be at their feet.
2. Table/counter/crate origins should be near the bottom edge or intended floor contact line.
3. Large PVGames sprites with transparent padding may need a wrapper or pivot adjustment before they are reliable sortable props.
4. Do not use Sprite2D child Z offsets as the normal way to fix a sortable object's order.

### PVGames Palette Routing Rules

The PVGames object palette should eventually expose explicit placement routes:

| Palette Route | Target Container | Use |
|---|---|---|
| Behind/fixed art | `BackgroundArt/BehindPlayerObjects` or current `ArtRoot/PVG_EditableObjects/BehindPlayerObjects` | Floor-adjacent props and details that should always stay behind characters. |
| Sortable 2.5D prop | `SortableWorld/PVGSortableObjects` | Props that should draw behind the player when the player is below/behind them and in front when the player is above/in front of them. |
| Foreground/fixed art | `ForegroundArt/ForegroundObjects` or current `ArtRoot/PVG_EditableObjects/ForegroundObjects` | Always-front trim, top overlays, and visual blockers. |
| Review | `ReviewObjects` | Assets whose correct depth/pivot/category is unknown. |

Until the sortable container exists, `OccludableObjects` is only a temporary staging container. Use it for visual experiments, but do not treat fixed `z_index = 90` as the final 2.5D solution.

### PVGames Object Palette V2

The existing PVGames Object Palette should evolve from a one-shot stamper into a focused brush/repeat placement tool before large art passes.

Required v2 features:

1. Single-click stamp remains supported.
2. Click-drag brush mode for repeatable visual assets.
3. Brush spacing in pixels and optional snap-to-grid.
4. Optional random rotation, scale jitter, and position jitter.
5. Line, rectangle, scatter, and erase-created-by-palette modes.
6. Explicit target routes: fixed behind art, sortable 2.5D prop, fixed foreground art, and review.
7. Y-sort contact-point/pivot preview for sortable props.
8. UndoRedo for every brush stroke.
9. Refuse targets under `GameplayRoot` unless a dedicated authoring packet explicitly changes that policy.

Current implementation status as of 2026-06-13:

1. `addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd` now exposes explicit **Placement Route** UI: Fixed Behind Art, Fixed Occludable Art, Sortable 2.5D Prop, Fixed Foreground Art, and Review.
2. **Sortable 2.5D Prop** resolves `VisualRoot/SortableWorld` first, then `EntityRoot`, only when `y_sort_enabled = true`. Stamps are direct children of the resolved Y-sort parent with `placement_route = sortable_2d_prop`, `created_by = PVGamesObjectPaletteDock`, and optional `y_sort_parent_path` metadata. Icons refuse the sortable route. The dock does not auto-create sort parents or place under `GameplayRoot`.
3. **Erase Palette Stamps** removes only nodes with `created_by = PVGamesObjectPaletteDock` via UndoRedo; non-palette nodes and GameplayRoot descendants are refused.
4. **Variation** controls cover position jitter, random rotation, random scale, and deterministic random seed (defaults off except deterministic seed on).
5. **Placement Shape** adds Stroke (existing brush), Rectangle Outline, Rectangle Fill, and Scatter Rectangle (count clamped to 500). Rectangle/scatter operations commit as one UndoRedo action.
6. Existing search/filter, preview, dry-run, typed/origin stamp, mouse placement, brush axis lock, visible-bounds auto spacing, ArtRoot routing, and no-collision policy remain intact.
7. Static validator `src/tools/editor/PVGamesObjectPaletteDockValidator.gd` checks the v2 surface plus non-mutating dry-run/mouse-arm wiring, active route preservation, input-forwarding guards, and box-erase surfaces. Manual editor QA in scratch and sortable pilot scenes passed on 2026-06-13.
8. **2026-06-09 to 2026-06-13 review fixes:** `Dry Run Stamp` and arming `Place With Mouse` use `_preview_stamp_target()` and do not call `_ensure_container()`. Fixed-route container creation happens only on actual stamp/brush/shape commit via `_resolve_stamp_target()`. Follow-up fixes restored repeatable mouse placement after `Ctrl+Z`, prevented BackgroundArt selection during armed placement, preserved explicit sortable route choice, added safe box erase, and made dock sections collapsible with a taller Results list.
9. Deferred polish: Y-sort contact-point preview overlay, snap-to-grid, and optional route-specific z-index presets beyond sortable default `z_index = 0`.

Do not turn this dock into the mission mechanic authoring tool. It is for visual objects/icons and repeatable PVGames art placement.

### Mission Paint Dock

Add this after palette brush basics are validated.

Purpose:

1. Visual-only floor, wall, decal, foreground, and review painting.
2. Layer-aware target selection using `docs/TACO_VISUAL_LAYER_TAXONOMY.md`.
3. No collision changes by default.
4. No mechanic `Area2D` or mission-state authoring.
5. Snapshot/report hooks for before/after validation.

The Mission Paint Dock should make visual passes faster without blurring the boundary between art, collision, and mission logic.

Current implementation status as of 2026-05-21:

1. `addons/mission_paint_dock/` implements Mission Paint Dock v1.
2. The dock has a safe visual paint mode plus locked layout/collision modes for Taco-style `GameplayRoot/LayoutRoot` layers.
3. Collision barrier painting and erasing are intentionally gated behind explicit unlocks because they can affect runtime movement/blockers.
4. This tool must still be treated as an editor aid; it does not create mission mechanics, `Area2D`, `StaticBody2D`, `CollisionShape2D`, or mission state.
5. After any `WallLayer` or `CollisionBarrierLayer` edit, run movement/collision validation and the relevant mission-authoring tests when available.

### Manual Animation Mapper And Reviewer

Use this instead of relying on generated classifier names such as `walk_best` or `run_best`.

Source-of-truth Resource or JSON shape:

```text
character_animation_map
  frame_width
  frame_height
  columns
  animations[]
    animation_name
    row/column ranges
    fps
    loop
    review_status
```

Required reviewer features:

1. Show 50x50 PVGames character creator sheets as browsable/contact-sheet pages.
2. Click or drag row/column frame ranges.
3. Preview selected ranges as looping/non-looping animations.
4. Label ranges manually as `idle`, `walk`, `run`, `crouch`, `jump`, `fall`, and custom names.
5. Save the reviewed map separately from generated frame exports.
6. Generate `SpriteFrames` from the reviewed map and selected character layers.
7. Preserve rejected/questionable ranges for future review without promoting them.

This tool should be part of the Phase 3 art-tool lane, not the runtime mission-authoring lane.

Current implementation status as of 2026-05-22:

1. `addons/character_animation_mapper/` implements Manual Animation Mapper / Reviewer v1.
2. The dock loads PVGames/composite sheets, supports numeric/click-based range selection, previews ranges, saves reviewed JSON maps under `res://resources/character_animation_maps/`, and can generate validation-only `SpriteFrames` under `res://resources/character_animation_maps/generated_preview/`. The current dock output for Parmida is the small external-reference `character_01_parmida_reference_variant_preview_spriteframes.tres`; the older embedded `parmida_manual_preview_spriteframes.tres` is a legacy artifact and should not be auto-loaded.
3. Large Review Canvas support now exists in `addons/character_animation_mapper/` through a grid canvas/window/helper split. It supports zooming, hover readout, linear global drag selection across row boundaries, Replace/Add/Remove selection modes, in-window labeling, preview, and dock integration.
4. Five manual composite character sheets were generated under `res://assets/characters/generated_player_visuals/manual_5pack_20260521/` with metadata/contact preview for mapper review. They are intended as 200x200 frames on a 50x50 grid.
5. Manual QA confirmed one reviewed `walk_toward_01` selection could be added, marked reviewed, exported to validation `SpriteFrames`, opened in the preview sandbox, and played correctly.
6. The Large Review Canvas repair fixed the generated-sheet auto-detection and zoomed full-sheet scroll/pan defects. Manual QA confirmed 50x50 auto-detection, usable full-grid navigation, visible selection controls, save/reload behavior, reviewed `SpriteFrames` generation, and sandbox playback.
7. The output is review data, not production promotion. Do not assign generated preview `SpriteFrames` to `player.tscn`, Taco, or shared runtime scenes without a separate promotion packet.
8. Existing classifier outputs such as `walk_best` / `run_best` remain diagnostic-only. They may be imported later as `needs_review` suggestions, but never as automatically reviewed production truth.
9. Next packet should sandbox-validate the reviewed manual 5-pack maps and small external-reference preview `SpriteFrames` before any production promotion packet.

### Larger Scene/Asset Browser Dock

Build this only after the object palette, mission paint dock, mission authoring palette, mission assist browser, and animation mapper prove their narrower workflows.

Initial scope should be read/search/select/open only:

1. PVGames objects/icons.
2. Mission authoring templates.
3. Security templates.
4. Animation maps.
5. Sequence templates.
6. Validation reports.

Do not let the larger browser become the first place where asset categories, target routes, or mechanic defaults are invented.

### Initial Z Band Guidance

Use these bands as broad defaults, not as per-object micro-tuning:

| Band | Suggested Z | Notes |
|---|---:|---|
| Background/floor art | `-300` to `-120` | Always behind player and sortable world. |
| Sortable world parent | `0` | Player, NPCs, and sortable props should sort by Y inside this band. |
| Foreground overlays | `160` and above | Always in front. |
| Debug/authoring overlays | `2400+` or existing debug conventions | Must not be confused with production art. |

Once an object is in the correct broad band, leave the stamped parent and child `Sprite2D` Z near `0` unless a reviewed exception exists.

### Editor Preview Requirements

Every mechanic node must support:

1. `@tool` preview.
2. Visible debug label.
3. Color-coded shape.
4. Clear missing-id warning in preview.
5. Preview that works without running the game.

### Recommended Gizmos

| Gizmo | Purpose | First Owner |
|---|---|---|
| Interaction radius | Shows where the player can press interact for a mechanic. | Mission Authoring Palette |
| Trigger shape | Shows trigger `Area2D` bounds and activation mode. | Mission Authoring Palette |
| Requirement status badge | Shows empty, valid, missing, or failing requirement configuration. | Mission Assist Browser |
| Effect chain badge | Shows success/failure effect counts and broken effect warnings. | Mission Assist Browser |
| Unique ID warning | Highlights missing IDs, placeholder IDs, and duplicates. | Mission Assist Browser |
| Extraction boundary | Shows extraction area and clean/messy completion policy. | Core mission nodes |
| Search/container target links | Shows visual nodes hidden/shown by search or container state. | Core mission nodes |
| Route unlock links | Draws lines to nodes shown/hidden/enabled/disabled by a route. | Core mission nodes |
| Objective step number | Displays objective or sequence order near the node. | Sequence tooling |
| Chronographic step | Shows step index, prerequisite step, and before/after relation. | Sequence tooling |
| Drop-box order | Labels ordered drop points such as `Drop 1`, `Drop 2`, and dependency arrows. | Sequence tooling |
| Patrol route | Shows waypoint path, direction arrows, and route id. | Security authoring |
| Camera cone | Shows FOV, sweep arc, and linked alarm event. | Security authoring |
| Laser/beam | Shows beam line, trip area, one-shot state, and event id. | Security authoring |
| Noise radius | Shows bark/distraction/noise emission range. | Bentley/noise phase |
| Y-sort contact point | Shows sortable prop floor-contact origin/pivot. | PVGames palette v2 |
| Depth band | Shows fixed background, sortable world, foreground, or review classification. | PVGames palette v2 |
| Camera bounds | Shows sequence/camera clamp region. | CameraBridge phase |
| Player-control lock zone | Shows areas or sequence steps that restrict player control. | PlayerControlBridge phase |
| Dialogue trigger | Shows dialogue key, fallback text, one-shot, and cooldown state. | Narrative phase |

### Recommended Preview Colors

| Mechanic | Color |
|---|---|
| Trigger | Blue |
| Locked interaction | Orange |
| Search/container | Yellow |
| Reward | Gold |
| Extraction | Green |
| Route | Purple |
| Bentley command | Cyan |
| Suspicion/social zone | Red/pink |
| Paper trail/cleanup | White/gray |

### Scene Organization Rule

For production missions, add this structure under `GameplayRoot` when practical:

```text
GameplayRoot
  RuntimeSystems
    MissionInteractionBridge
    MissionAlertController
  Authoring
    MissionMechanics
      Triggers
      Locks
      Searches
      Rewards
      Exits
      Routes
      Bentley
      Social
      PaperTrail
    SecurityAuthoringRoot
    CollectibleAuthoringRoot
```

Do not rename existing production roots during early implementation. Use this structure for new validation scenes and future missions first.

## Phase 4: Inventory / Heist Kit Implementation

### Timing

Do not implement inventory before `RequirementSet`, `EffectSet`, and the first four mechanics are working.

### Future Files

| Future File | Class Name | Type |
|---|---|---|
| `src/inventory/items/ItemData.gd` | `ItemData` | `Resource` |
| `src/inventory/items/InventoryEntry.gd` | `InventoryEntry` | `Resource` or simple dictionary helper |
| `src/inventory/MissionInventory.gd` | `MissionInventory` | `Node` or `RefCounted` adapter |
| `src/missions/iso/authoring/mechanics/InventoryPickupNode.gd` | `InventoryPickupNode` | `RewardNode` or `MechanicAreaBase` |

### ItemData Fields

```gdscript
@export var item_id: StringName = &"item"
@export var display_name: String = ""
@export_enum("key_item", "tool", "evidence", "consumable", "credential", "contraband", "flavor") var category: String = "key_item"
@export var stackable: bool = false
@export var max_stack: int = 1
@export var mission_only: bool = true
@export var suspicious: bool = false
@export var heat_value: int = 0
@export var icon: Texture2D
@export_multiline var description: String = ""
```

### Initial Inventory Rule

Use mission-only inventory first. Do not add permanent save data until at least one mission proves it needs persistent items.

2026-06-20 Phase 5A-5C-lite status: implemented the first mission-only inventory contract with `ItemData`, `InventoryEntry`, and `MissionInventory`. Runtime state is held outside `GameState.to_dict()` / `from_dict()`, clears through mission lifecycle hooks, and can be queried by authored requirements.

2026-06-20 Phase 5D-5F-lite status: implemented `InventoryPickupNode` as a `RewardNode`-based item pickup, added an authoring template, Mission Dock placement/audit support, a dev-room pickup-to-route proof using `inventory_has_item`, and a compact F10 `mission_inv` debug line. Persistent inventory save schema and production item placement remain deferred.

### Requirement Integration

Add fact types:

```text
inventory_has_item
inventory_item_count
inventory_has_category
```

### Effect Integration

Add effect types:

```text
GRANT_ITEM
REMOVE_ITEM
CLEAR_MISSION_ITEMS
```

## Phase 5: Scheme Card Mission Modifiers

### Timing

Implement after route, locked, search, and extraction nodes work.

### Extension Points

Use existing systems:

- `GameState.selected_cards`
- `GameState.current_scheme_loadout`
- `GameState.has_selected_card()`
- `GameState.has_scheme_card()`
- `CardManager.get_selected_cards()`
- `CardEffects` helper methods
- `MissionSchemeBridge.get_scheme_snapshot()`
- `MissionSchemeBridge.has_scheme_effect()`

### New Resource

Future file:

`src/missions/iso/authoring/core/MissionModifierSet.gd`

Fields:

```gdscript
@export var modifier_id: StringName = &"modifier"
@export var source_card_id: StringName = &""
@export var requirements: RequirementSet
@export var setup_effects: EffectSet
@export var debug_note: String = ""
```

### Card-Driven Authoring Pattern

Do this:

```text
RouteUnlockNode.requirements = RequirementSet(selected_card louis_delivery_route)
RouteUnlockNode.success_effects = EffectSet(set mission_flag loading_dock_route_open)
```

Avoid this:

```text
if CardManager.is_selected("louis_delivery_route") hardcoded inside the Taco scene script
```

### First Card Integrations

| Card | Plug-And-Play Use |
|---|---|
| `louis_delivery_route` | Unlocks loading dock route nodes. |
| `mere_legal_eyes` | Reveals clue/SearchZone helper markers. |
| `clorox_wipe_protocol` | Improves cleanup or paper-trail effects later. |
| `fish_treat_focus` | Enables or improves Bentley sniff command points. |
| `bryce_swiss_timing` | Improves timed/safe/card rhythm windows later. |

## Phase 6: Suspicion And Alert Effects

### Timing

Implement after base nodes and card modifiers.

### Rule

Do not create a separate suspicion autoload first. Extend or wrap `MissionAlertController`.

### New Effect Types

```text
ADD_SUSPICION
REDUCE_SUSPICION
SET_ALERT_STATE
TRIGGER_LOCKDOWN
MARK_MESSY
```

### Alert State Vocabulary

Current `MissionAlertController.VALID_STATES` supports:

```text
normal
suspicious
alerted
resolved
```

Do not introduce `lockdown` or `escape` into Resources until `MissionAlertController.VALID_STATES` is intentionally expanded.

### Mechanic Integration Examples

| Mechanic | Failure Effect |
|---|---|
| Wrong keypad | Add alert exposure, trigger dialogue bark. |
| Search suspicious drawer while watched | Add suspicion. |
| Enter restricted zone without credential | Set alert state suspicious. |
| Trip camera beam | Use existing security event routing. |

### Roadmap Phase 4A Security Event Bridge

Current additive file:

`src/missions/iso/authoring/SecurityEffectSetAuthor.gd`

Use it when an existing `SecurityEventRouter` event should apply reusable mission-authoring effects:

```text
Security beam / camera / area trigger
  -> SecurityEventRouter emits event_id
  -> SecurityEffectSetAuthor listens for event_id
  -> EffectSet applies mission flags, objectives, alert state, route toggles, dialogue, or completion effects
```

Do not add one-off security consequences directly into Taco scripts when an `EffectSet` can express the same behavior.

Phase 4B-4D grouped proof files:

| File | Purpose |
|---|---|
| `scenes/dev/mission_authoring/SecurityEffectSetAuthorProofRoom.tscn` | Dev proof that an authored area security event applies a normal `EffectSet`. |
| `scenes/missions_iso/security_authoring_templates/SecurityEffectSetAuthorTemplate.tscn` | Drag/drop template for event-to-EffectSet authoring. |
| `src/tools/editor/phase4b_4d_security_effect_sets/phase4b_4d_security_effect_set_validator.py` | Static guard for the proof scene, template, and debug contract. |

## Phase 7: Bentley Command Points

### Timing

Implement after `MissionInteractionBridge`, base mechanics, inventory, and alert effects are stable.

### Future Base File

`src/missions/iso/authoring/mechanics/CompanionCommandPoint.gd`

Extends:

`MechanicAreaBase`

Extra exports:

```gdscript
@export_enum("sniff", "fetch", "bark", "crawlspace", "wait", "danger_sense") var command_kind: String = "sniff"
@export var bentley_required: bool = true
@export var command_cooldown_seconds: float = 2.0
@export var bentley_target_path: NodePath
@export var command_effects: EffectSet
```

### Command Point Files

| Future File | Purpose |
|---|---|
| `BentleySniffTrail.gd` | Reveals route/clue or completes sniff objective. |
| `BentleyFetchTarget.gd` | Grants an item/collectible after Bentley reaches target. |
| `BentleyBarkDistractionPoint.gd` | Emits noise/distraction effect. |
| `BentleyCrawlspaceConnector.gd` | Unlocks/toggles route for Bentley or player. |
| `BentleyWaitMarker.gd` | Tells Bentley to hold position or support puzzle timing. |

### Integration With Existing Files

Use:

- `src/player/DogCompanion.gd`
- `CardEffects.get_bentley_recharge_multiplier()`
- `CardEffects.get_bentley_bark_radius_multiplier()`
- existing input actions `bentley_ability`, `bentley_bark`, `bentley_sniff`, `bentley_fetch`, `bentley_toggle_stay`

### Rule

Bentley command points should be placed in scenes. Do not make every command globally available everywhere.

2026-06-20 Phase 7A-7D-lite status: implemented `CompanionCommandPoint` for `bark`, `sniff`, and `fetch` as placed `MechanicAreaBase` mechanics. `DogCompanion.gd` exposes public `command_bark`, `command_sniff`, and `command_fetch` methods so command points reuse existing Bentley behavior and card-influenced bark/recharge paths. Mission Dock can place/audit the command point, the dev room proves bark/sniff/fetch with normal `EffectSet` success flags, and `CompanionCommandPointTest.gd` covers requirements, effects, missing companions, command calls, DogCompanion command APIs, and the dev-scene nodes. Phase 7E-7G crawlspace, wait marker, and card-specific command tuning remain deferred.

2026-06-20 Phase 7E-7G-lite status: implemented `BentleyCrawlspaceConnector` and `BentleyWaitMarker` as thin `CompanionCommandPoint` subclasses, added `DogCompanion.command_crawlspace()` and `command_wait()`, added templates and Mission Dock placement defaults, and expanded the dev room with crawlspace/wait proof nodes that apply normal `EffectSet` flags. `CardEffects.gd` now centralizes Bentley sniff cooldown, fetch cooldown, and fetch range modifiers; `DogCompanion.gd` consumes those helpers, with focused tests proving `fish_treat_focus` changes fetch/sniff behavior. Production mission placement and full noise/listener AI remain deferred.

## Phase 8: Noise And Distraction

### Timing

Implement after guards/alert effects and Bentley bark command point.

### Future Files

| Future File | Purpose |
|---|---|
| `src/missions/iso/runtime/noise/NoiseEvent.gd` | Data helper or dictionary schema for noise. |
| `src/missions/iso/runtime/noise/NoiseEmitterNode.gd` | Emits noise event from placed object. |
| `src/missions/iso/runtime/noise/NoiseListenerComponent.gd` | Added to guards/NPCs later. |
| `src/missions/iso/authoring/mechanics/DistractionObject.gd` | Plug-and-play throwable/clickable distraction. |

### Noise Event Schema

```gdscript
{
    "noise_id": "bentley_bark_loading_dock",
    "source_id": "bentley_bark_point_01",
    "position": global_position,
    "radius": 192.0,
    "strength": 1.0,
    "kind": "bark",
    "team": "player",
    "timestamp": Time.get_ticks_msec(),
}
```

### First Integration

Bentley bark should create a noise event. Guards can initially react through existing security event routing or a simple debug response before full listener AI is implemented.

2026-06-20 Phase 8A-8D-lite status: implemented `NoiseEvent`, `NoiseEmitterNode`, and `DistractionObject` as the first adapter-first noise/distraction packet. Noise events are dictionaries with `noise_id`, `source_id`, `position`, `radius`, `strength`, `kind`, `team`, and `timestamp`; placed emitters extend the same requirement/effect pipeline as other authoring mechanics. `DogCompanion.command_bark()` now emits a bark noise event, `EventBus` exposes `mission_noise_emitted`, and `MissionAlertController.register_noise_event()` records recent noise and can move normal missions to suspicious for player-team noise. `IsoMissionDebugPanel` exposes compact noise debug output. `NoiseListenerComponent` and production guard pathing remain future work.

2026-06-20 Phase 8E-8G-lite status: implemented `NoiseListenerComponent` as a mission-local listener that subscribes to `EventBus.mission_noise_emitted`, filters by radius/kind/team, records heard noise, sets debug metadata on its parent receiver, and optionally calls parent `on_noise_heard(noise_event, listener)`. Existing `MissionPoopBagDecoyPoint` now emits a `poop_decoy` `NoiseEvent` after successful poop-bag consumption, so the older poop-bag distraction path can feed `MissionAlertController` and any active listeners without a new global noise manager. The dev room includes a listener guard proof. Full guard pathing/investigation movement and production mission placement remain deferred.

2026-06-20 Phase 8H-lite status: implemented `NoiseReactiveGuard`, a lightweight parent receiver for `NoiseListenerComponent`. It handles `on_noise_heard(noise_event, listener)`, records `investigating_noise` state and an investigate target, writes readable debug metadata, optionally faces the source, and exposes `get_noise_reaction_summary()`. This proves the listener callback path without adding pathfinding, patrol interruption, or a global noise manager.

## Phase 9: Puzzle And Side Job Kit

### Timing

Implement after base nodes, inventory, card modifiers, Bentley command points, and alert/noise basics.

### Rule

All puzzle nodes should extend `MechanicAreaBase` unless they are pure data controllers.

### First Puzzle Nodes

| Node | Extends | Core Behavior |
|---|---|---|
| `TerminalHackNode` | `LockedInteractionNode` | Requires code/card/tool, applies objective/evidence effects. |
| `PowerCircuitNode` | `MechanicAreaBase` | Tracks linked switches and toggles route/lock state. |
| `TimedSwitchNode` | `MechanicAreaBase` | Sets temporary mission flag. |
| `PressurePlateNode` | `MechanicAreaBase` | Automatic flag while occupied. |
| `DeadDropNode` | `InteractiveContainer` | Deposit or retrieve item. |
| `ObjectSwapNode` | `MechanicAreaBase` | Requires carried item, grants replacement/evidence. |
| `BugPlantNode` | `MechanicAreaBase` | Requires bug item, starts eavesdrop objective. |
| `EavesdropZone` | `TriggerZone` | Requires remaining hidden, completes when duration passes. |

2026-06-20 Phase 9A status: implemented `TerminalHackNode` as a thin `LockedInteractionNode` subclass. It keeps hacking requirement/effect-driven, exposes `terminal_id` and `hack_completed_flag`, routes completion through mission facts, and adds Mission Dock placement/audit support, a template scene, dev-room proof, focused tests, static validation, and report. No production Taco placement, side jobs, puzzle manager, or save-schema changes were added.

2026-06-20 Phase 9B status: implemented `PowerCircuitNode`, `TimedSwitchNode`, and `PressurePlateNode` as mission-local linked-power puzzle mechanics. `TimedSwitchNode` sets and expires a temporary mission flag, `PressurePlateNode` sets and clears a flag while pressed, and `PowerCircuitNode` checks configured mission flags before setting a circuit flag and applying normal effect sets. Mission Dock can place/audit all three, the authoring templates and dev-room proof demonstrate switch plus plate powering a circuit, and focused tests/static validation cover the contracts. No global puzzle manager, production Taco placement, side jobs, custom sequence resources, or save-schema changes were added.

2026-06-21 Phase 9C-9F status: implemented the next puzzle/side-job slice with `DeadDropNode`, `ObjectSwapNode`, `BugPlantNode`, `EavesdropZone`, `CustomSequenceStep`, `CustomSequenceResource`, and `CustomSequenceRunner`. Dead drops can deposit or retrieve mission inventory items, object swaps consume one item and optionally grant a replacement, bug plants consume a bug item and set planted facts, eavesdrop zones complete after a short listen window, and sequence resources enforce ordered step dependencies through explicit `depends_on_step_ids`. Mission Dock supports placement/audit for the four placed node types, templates and a dev-room proof chain were added, and focused tests/static validation cover the contracts. No production Taco placement, global puzzle manager, save-schema changes, full side-job scenario, tail target, carry-object controller, or presentation/cutscene ownership was added.

2026-06-21 Phase 9G-9I status: completed the remaining side-job proof and adoption gate. `Phase9SideJobProofRoom` now proves two authored side jobs mostly assembled from reusable nodes: Poop Bag Calibration Course combines `TimedSwitchNode`, `PressurePlateNode`, `PowerCircuitNode`, and `CustomSequenceRunner`; Bentley's Snack Trail combines `DeadDropNode`, `ObjectSwapNode`, `BugPlantNode`, `EavesdropZone`, and `CustomSequenceRunner`. Taco production adoption is limited to `PpTacoSouthSideJobSignoff`, a route-gated `SideObjectiveNode` under `GameplayRoot/PlugAndPlayPilot` that requires `pp_taco_south_route_open` and preserves `MissionInteractionBridge.include_legacy_candidates = false`. No global puzzle manager, save-schema change, tail target, carry-object controller, or Phase 12 presentation ownership was added.

## Phase 10: Hideout Rewards / Cozy Meta Hooks

### Timing

Implement after mission systems produce clear rewards.

### Use Existing Controllers

Extend:

- `HideoutManager.gd`
- `HideoutStoreController.gd`
- `HideoutCareController.gd`
- `HideoutCollectibleController.gd`
- `HideoutDecorationController.gd`
- `HideoutMissionBoardController.gd`

### Rule

Mission effects should not directly manipulate hideout UI nodes. They should grant data or flags. Hideout controllers should read and present that state.

### Current Implementation

Phase 10A-10F-lite is implemented through `src/hideout/HideoutRewardAdapter.gd` and `HideoutStateController.apply_mission_reward_contract()`. The adapter reads existing `GameState` completion/reward data and produces a hideout contract; `HideoutManager` syncs completed mission rewards into hideout state on load. This keeps UI ownership inside hideout controllers and avoids a duplicate hideout reward manager.

The first production contract covers `taco_bell_drop`: reward scheme-card visibility, Taco decor/store unlocks, collectible display flags, Louis visibility, Bentley sauce-paw care unlock, and a save-safe case-cash floor. Additional missions can extend the adapter contract when their reward data and hideout displays are authored.

## Phase 11: Paper Trail And Plausible Deniability

### Timing

Implement after puzzle/side-job and hideout reward contracts are stable enough to produce mission result context.

### Future Event Schema

```gdscript
{
    "trace_id": "camera_saw_player_loading_dock",
    "mission_id": "taco_bell_drop",
    "source_id": "camera_loading_dock_01",
    "trace_type": "camera_seen",
    "severity": 2,
    "can_cleanup": true,
    "cleanup_requirement": "clorox_wipe_protocol",
    "created_at": Time.get_unix_time_from_system(),
}
```

### Future Mechanics

| Mechanic | Purpose |
|---|---|
| `AuditTrailCleanupNode` | Removes or weakens trace events. |
| `HeatSinkObject` | Redirects suspicion to another explanation. |
| `DoorStateMemoryNode` | Records suspicious door/open state. |
| `CounterSurveillanceSweepNode` | Reveals cameras/traces. |

### Rule

Trace should affect mission result summaries before it affects complex NPC behavior.

## Phase 12: Narrative And Presentation / Cutscene Bridges

### Timing

Implement after puzzle/side-job ordering, rewards, and paper-trail result context are stable enough to benefit from presentation polish.

### Bridge Files

| Future File | Purpose |
|---|---|
| `src/missions/iso/presentation/DialogueTriggerZone.gd` | Placed dialogue trigger with cooldown/one-shot rules. |
| `src/missions/iso/presentation/BarkTrigger.gd` | Placed bark/flavor trigger with spam prevention. |
| `src/missions/iso/presentation/PresentationSequencePlayer.gd` | Coordinates short flavor beats through bridges. |
| `src/missions/iso/presentation/CameraBridge.gd` | Camera focus/blend/shake/restore wrapper, optional PhantomCamera adapter. |
| `src/missions/iso/presentation/PlayerControlBridge.gd` | Temporary input lock/guided movement with guaranteed restore. |
| `src/missions/iso/presentation/AudioVisualBridge.gd` | Audio/visual cues with optional Resonant adapter. |

### Rule

Presentation bridges may call camera/player/audio systems, but mission mechanics should not call those systems directly. The Phase 9 `CustomSequenceRunner` remains gameplay-ordering infrastructure and should not become the cutscene owner.

## Phase 13: Social Stealth

### Timing

Implement after basic stealth/alert, inventory, route/card systems, puzzle/side jobs, and paper-trail facts are stable.

### Resource Files

| Future File | Purpose |
|---|---|
| `src/missions/iso/social/CoverStoryData.gd` | What the player claims to be doing. |
| `src/missions/iso/social/CredentialData.gd` | Badge, outfit, document, or social permission. |
| `src/missions/iso/social/InspectionRuleSet.gd` | NPC/security acceptance rules. |

### Mechanic Files

| Future File | Extends | Purpose |
|---|---|---|
| `InspectionZone.gd` | `MechanicAreaBase` | Checks credential/cover story requirements. |
| `BelievableTaskZone.gd` | `MechanicAreaBase` | Lets player perform a plausible task to reduce suspicion. |
| `ProtocolZone.gd` | `MechanicAreaBase` | Requires procedure item/card/state. |
| `ProfessionalismMeterNode.gd` | `Node` | Mission-local meter, not global at first. |
| `CleanlinessGate.gd` | `LockedInteractionNode` | Requires cleanup/protocol state. |

### Rule

Social stealth state should start as mission facts and effects. Only add a dedicated manager after at least two missions need shared social state.

## Complete Phase Scope Index

This section is the blueprint-level source of truth for phase and subphase scope. The detailed Phase 1A-1K sections above remain the implementation-level source for the already-scoped foundation. Later phase sections may be expanded packet-by-packet, but the boundaries below should be preserved unless the roadmap is intentionally revised.

### Phase 0: Protect And Extend Existing Spine

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 0A | Ownership audit | Document which existing systems own mission state, objectives, cards, dialogue, completion, save/load, security, collectibles, hideout rewards, and player/Bentley behavior. | No implementation starts until authoritative owners are known. |
| Phase 0B | Adapter-point audit | Identify the narrowest safe adapter points around `GameState`, `QuestManager`, `CardManager`, `CardEffects`, `DialogueManager`, `MissionAlertController`, Phase0J, Phase0K, and security authoring. | No duplicate manager is proposed when an existing owner can be wrapped. |
| Phase 0C | Baseline tests and reports | Capture current branch, dirty state, key passing test counts, canonical Taco scene, and known limitations. | Future packets can compare against a documented baseline. |
| Phase 0D | Production safety rules | Lock down do-not-touch systems for early packets: `project.godot`, autoloads, `IsoMissionBase`, canonical Taco bag/manifest/Louis flow, Phase0J/Phase0K scripts, generated runtime collision, and unrelated scenes. | Every later packet names what it preserves. |
| Phase 0E | Rollback strategy | Define small reversible packet boundaries and report requirements. | Each packet can be reverted without broad scene/project damage. |

### Phase 1: Shared Authoring Foundation

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 1A | Mission facts | `MissionFactBridge` over current authoritative managers. | Fact reads/writes are tested without duplicate state owners. |
| Phase 1B | Atomic requirements | `MissionRequirement` Resource. | Requirement evaluation returns consistent result dictionaries. |
| Phase 1C | Requirement sets | `RequirementSet` Resource with all/any/none behavior. | Failure reasons are designer-readable and test-covered. |
| Phase 1D | Atomic effects | `MissionEffect` Resource. | Effect rows are serializable, explicit, and narrow. |
| Phase 1E | Effect sets | `EffectSet` ordered effect collection. | Ordered application and failure handling are test-covered. |
| Phase 1F | Effect applier | `MissionEffectApplier` routing to existing systems. | Effects do not bypass existing authoritative managers. |
| Phase 1G | Dialogue bridge | `MissionDialogueBridge`. | Mechanics can trigger dialogue without depending on implementation details. |
| Phase 1H | Completion bridge | `MissionCompletionBridge`. | Completion/failure routes through existing completion flow. |
| Phase 1I | Mechanic base | `MechanicAreaBase`. | One-shot, prompts, requirements, effects, debug labels, and groups work. |
| Phase 1J | Interaction bridge | `MissionInteractionBridge`. | Candidate selection and Phase0J compatibility boundaries are validated. |
| Phase 1K | Proof trigger | `TriggerZone` and validation room. | A placed proof node evaluates requirements and applies effects safely. |

### Phase 2: Mission Construction Kit

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 2A | Objective adapter | `ObjectiveStepController` over `QuestManager`. | Objectives can activate/complete/fail without direct scattered `QuestManager` calls. |
| Phase 2B | Extraction | `ExtractionZone` with clean/messy/failure exit effects. | Extraction can require objectives and route completion through `MissionCompletionBridge`. |
| Phase 2C | Locks and gates | `LockedInteractionNode`. | Doors/gates/safes/terminals can be requirement-gated without one-off scripts. |
| Phase 2D | Search | `SearchZone`. | Searchable spots can grant effects and persist searched state. |
| Phase 2E | Containers | `InteractiveContainer`. | Open/search container patterns work without inventory UI. |
| Phase 2F | Rewards | `RewardNode`. | Visible rewards route through `EffectSet` and existing collectible/fact systems. |
| Phase 2G | Routes | `RouteUnlockNode`. | Routes can show/hide visuals and enable/disable local blockers deterministically. |
| Phase 2H | Side objectives | `SideObjectiveNode`. | Optional/side objective steps use `ObjectiveStepController`. |
| Phase 2I | Multi-instance isolation | Duplicate mechanics of the same class in one mission. | Core reusable mechanic kit status confirmed on 2026-06-09: GdUnit `mission_authoring` PASS, dev-room live chain PASS, Taco Packet 6C already confirmed, and no new core-kit fixes required. |
| Phase 2J | First production adoption | One non-critical Taco route/search/reward/extraction slice beside Phase0J. | Packet 6C live Taco pilot validation passed on 2026-06-09; no immediate pilot fix pass is required unless later validation finds issues. |
| Phase 2K | Authoring UX entry point | Combined **Mission Dock** plugin with Mission Authoring Palette + Mission Assist Browser tabs. | Implementation landed 2026-06-13: plugin files under `addons/mission_dock/`, all approved mechanic classes supported with safe defaults, read-only audit browser, static validator, plugin enabled in `project.godot`. Post-manual-QA fix pass addressed parent fallback, BBCode details, starter requirements, and placement/resource summaries; Jake retest passed. Tooling uses existing mechanic classes, not a parallel format. |

### Phase 3: Visual Tile / Asset Painting Pipeline

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 3A | Visual safety baseline | Taco visual layer taxonomy, paint-readiness checklist, screenshot bookmarks. | Visual packets know what is gameplay, visual-only, debug-only, generated, or protected. |
| Phase 3B | South pilot readability | Scene-local visual affordances around the first plug-and-play pilot lane. | Pilot interactions are readable without changing gameplay. |
| Phase 3C | Runtime debug residue policy | Hide generated marker labels in player-facing runtime while preserving recoverability. | Runtime labels are hidden; authoring data remains intact. |
| Phase 3D | Security author label policy | Hide security author labels/residue at runtime while preserving author nodes. | Security authoring still works and proof labels are recoverable. |
| Phase 3E | Security hazard readability | Player-facing hazard affordances for beams/cameras/security tests. | Hazards are readable without changing detection behavior. |
| Phase 3F | Visual layer taxonomy | Formal fixed-Z, foreground, debug, and sortable-world layer vocabulary. | Future paint packets have shared layer rules. |
| Phase 3G | PVGames Object Palette v2 | Explicit placement routes, sortable 2.5D prop route, erase-created-by-palette, variation (jitter/rotation/scale), rectangle/scatter shapes, brush/repeat placement, safe art-root routing, UndoRedo batch strokes. | Repeated visual assets can be placed safely without one-by-one dragging; sortable stamps land as direct Y-sort siblings. |
| Phase 3H | Mission Paint Dock | Visual-only floor/wall/decal/foreground painting. | Paint dock cannot touch collision, mechanics, Phase0J/Phase0K, or mission state. |
| Phase 3I | Manual animation mapper | Reviewed PVGames row/column animation maps, Large Review Canvas frame selection, and generated validation `SpriteFrames`. | Animation preview validation passed on 2026-06-09; production runtime promotion still requires a separate reviewed promotion packet. |
| Phase 3J | Sortable 2.5D pilot | Small test lane with player/NPC/sortable PVGames prop depth validation. | Player can walk in front/behind prop correctly. |
| Phase 3K | Scene/Asset Browser planning | Read/search/select browser that unifies proven categories only after smaller tools work. | Browser manually validated as read-only search/select/open tooling; it does not invent categories, target routes, placement behavior, or write actions. |

Status note as of 2026-05-22, updated 2026-06-13: Phase 3G PVGames Object Palette v2 expansion includes explicit placement routes, sortable 2.5D prop routing, erase-created-by-palette, safe box erase, collapsible dock sections, a taller Results list, variation, rectangle/scatter shapes, and static validator coverage. Jake confirmed manual editor QA passed in the scratch and sortable pilot scenes on 2026-06-13, including repeatable Place With Mouse after `Ctrl+Z`, non-mutating dry run/arming, sortable placement over existing BackgroundArt, and non-palette erase refusal. Phase 3H and Phase 3I each have v1 tooling in the repo. Phase 3I now has a manually validated Large Review Canvas repair: 50x50 sheet auto-detection, full-sheet zoom/scroll/pan, frame selection, JSON save/reload, reviewed preview `SpriteFrames`, sandbox playback, and animation preview validation have been confirmed in editor QA. The dock's validation export now targets the small external-reference Parmida preview rather than the legacy embedded file. Phase 3J has a validated isolated sortable 2.5D pilot under `res://scenes/dev/phase3j_sortable_2d_pilot/`; the key rule confirmed is that active sortable player/NPC/prop nodes must be direct siblings under the same `y_sort_enabled` parent, with floor-contact origins. Phase 3K now has a planning report and manually validated read-only Scene/Asset Browser skeleton under `res://addons/scene_asset_browser/`; it is intentionally limited to search/select/open of proven categories and must not place, generate, promote, or invent routes/defaults. Treat these as usable editor-tool foundations, not final production pipelines. Production animation wiring still requires a separate promotion packet. The next gameplay-authoring decision should return to the production pilot / mission-authoring sequence rather than expanding Phase 3K beyond its read-only boundary.

### Phase 4: Stealth Readability And Escalation

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 4A | Alert bridge hardening | Extend `MissionAlertController` and `MissionEffectApplier` alert effects. | Alert changes remain data-driven through effects. |
| Phase 4B | Suspicion vocabulary | Lite proof implemented 2026-06-17: `SecurityEffectSetAuthor` event chains now expose source/event/effect-set result dictionaries and a dev scene proves event consequences stay data-driven. | Suspicion/security event consequences can be debugged without a new global manager. |
| Phase 4C | Visual feedback | Lite proof implemented 2026-06-17: `IsoMissionDebugPanel` downstream effects block includes `effect_set` counts and last chain summary. | Designers can see event-to-effect consequences in existing debug output. |
| Phase 4D | Security authoring polish | Lite proof implemented 2026-06-17: `SecurityEffectSetAuthorTemplate.tscn`, collector/count plumbing, and static validator cover the reusable security effect bridge. | Existing D6 security authorables do not regress. |
| Phase 4E | Camera sweep loops | Lite proof implemented 2026-06-17: camera runtime and author nodes expose sweep debug/readability summaries; F12 QA Review exposes camera-readability paths/checks. | Camera loops are predictable and testable. |
| Phase 4F | Hide spots | Lite proof implemented 2026-06-17: `HideSpotNode` reduces detection through `MissionAlertController` and remains a normal `MechanicAreaBase` node. | Hide spots interact with alert/suspicion without AI rewrite. |
| Phase 4G | Production security slice | Lite proof implemented 2026-06-17: Taco `test_camera_alarm` drives `phase4g_camera_alarm_seen` through `SecurityEffectSetAuthor` and `EffectSet`, not Taco script hardcoding; F12 QA Review adds a dropdown checklist, live PASS/WAIT states, and teleport/reset helpers for manual validation. F12 intentionally avoids Godot Editor's F8 stop-running shortcut. | Security events activate facts/objectives/routes without hardcoded mission scripts and can be manually verified without parsing raw F10 output. |

### Phase 5: Inventory / Heist Kit

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 5A | Item data | `ItemData` Resource and category vocabulary. | Items are data, not hardcoded mechanic branches. |
| Phase 5B | Mission inventory adapter | Implemented 2026-06-20: lightweight `MissionInventory` static adapter stores `InventoryEntry` records in mission runtime memory only and clears mission-only entries on new game, mission start, completion, and failure. | Mission-only items do not pollute permanent save data. |
| Phase 5C | Requirement/effect integration | Implemented 2026-06-20: `MissionFactBridge` supports `inventory_has_item`, `inventory_item_count`, and `inventory_has_category`; `MissionEffectApplier` supports `GRANT_ITEM`, `REMOVE_ITEM`, and `CLEAR_MISSION_ITEMS`; Mission Dock vocabulary includes the new fact/effect types. | Locks/search/extraction can require or grant items. |
| Phase 5D | Pickup mechanics | Implemented 2026-06-20: `InventoryPickupNode` extends `RewardNode`, grants through `MissionEffect.GRANT_ITEM` / `MissionEffectApplier`, has a template scene, and is placeable/auditable in Mission Dock. | Item pickups are reusable and instance-safe. |
| Phase 5E | Debug UI | Lite proof implemented 2026-06-20: F10 debug HUD shows compact `mission_inv` snapshot lines. | Designers can inspect mission item state without a full grid UI. |
| Phase 5F | Persistence policy | Lite policy implemented 2026-06-20: mission-only items remain outside save data and clear through new-game/start/complete/fail lifecycle hooks; persistent item schema is still deferred. | Restart/failure/success paths do not duplicate or leak mission-only items. |

### Phase 6: Scheme Card Mission Modifiers

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 6A | Card fact bridge | Selected/unlocked/effect card facts through existing `GameState`, `CardManager`, and `MissionSchemeBridge`. | Implemented 2026-06-15: `selected_card`, `unlocked_card`, and `scheme_effect` are queryable through `RequirementSet` / `MissionRequirement`; `scheme_effect` now uses `MissionSchemeBridge.get_active_scheme_cards()` so selected cards and current planning loadout effects are visible to authored requirements without changing `CardEffects.gd` or adding a new manager. |
| Phase 6B | Mission modifier data | `MissionModifierSet` and setup effect bundles. | Implemented 2026-06-16: `MissionModifierSet` is an inspectable data Resource for `source_card_id`, optional `RequirementSet`, optional setup `EffectSet`, and `debug_note`; no global modifier manager or production card behavior was added. |
| Phase 6C | Card-triggered nodes | `SchemeCardTriggerNode` or equivalent placed trigger. | Implemented 2026-06-17: `SchemeCardTriggerNode` consumes `MissionModifierSet` Resources, reads active cards through `MissionSchemeBridge`, and applies setup `EffectSet` data without production scene scripts or a global modifier manager. |
| Phase 6D | Route modifiers | Card-driven route unlocks. | Lite proof implemented 2026-06-17: focused tests and the dev-room sample show Louis-style card setup writing a route-gating mission flag that a reusable `RouteUnlockNode` can require. |
| Phase 6E | Starting item/modifier hooks | Cards grant starting tools, hints, or route facts. | Lite proof implemented 2026-06-17: `SchemeCardTriggerNode.apply_on_ready` can run setup effects at scene start for route facts/hints; inventory/item grants remain deferred to Phase 5. |
| Phase 6F | Production card slice | One real card changes a placed node in a production mission. | Implemented 2026-06-17: `louis_delivery_route` now drives a production Taco `SchemeCardTriggerNode` setup flag that lets the existing south pilot route unlock via either the original reward chain or the Louis route card, with no Taco script hardcoding. The Planning Table includes a dev-only Louis override for pre-progression QA without permanently unlocking the card. Post-fix manual QA passed for the positive Louis-equipped route open and the negative no-Louis blocked-route path; `GameState.start_mission()` now clears namespaced mission flags for the launching mission so attempt-local route flags cannot leak between Taco runs. |

### Phase 7: Bentley Core Verbs

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 7A | Command point base | `CompanionCommandPoint` extending `MechanicAreaBase`. | Bentley actions use requirements/effects like other mechanics. |
| Phase 7B | Sniff | Lite proof implemented 2026-06-20 through `CompanionCommandPoint.command_type = "sniff"` and `DogCompanion.command_sniff()`. | Sniff can apply normal `EffectSet` outputs from a placed command point. |
| Phase 7C | Fetch | Lite proof implemented 2026-06-20 through `CompanionCommandPoint.command_type = "fetch"`, `DogCompanion.command_fetch()`, and a dev-room fetchable inventory token. | Fetch can trigger an authored pickup/reward target and apply command-point effects. |
| Phase 7D | Bark distraction | Lite proof implemented 2026-06-20 through `CompanionCommandPoint.command_type = "bark"` and existing bark radius/card modifier behavior. | Bark command points produce effect output without a noise/listener AI rewrite. |
| Phase 7E | Crawlspace | Lite proof implemented 2026-06-20 with `BentleyCrawlspaceConnector`, template, dev-room node, and `DogCompanion.command_crawlspace()`. | Bentley can move to a placed crawlspace marker and apply normal effects in a controlled slice. |
| Phase 7F | Wait marker | Lite proof implemented 2026-06-20 with `BentleyWaitMarker`, template, dev-room node, and `DogCompanion.command_wait()`. | Bentley position/timing can support puzzles through placed command markers. |
| Phase 7G | Card modifiers | Lite proof implemented 2026-06-20 with CardEffects sniff/fetch cooldown/range helpers consumed by `DogCompanion.gd`. | Bentley card behavior is centralized and testable. |

### Phase 8: Noise And Distraction

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 8A | Noise event schema | `NoiseEvent` dictionary/resource contract. | Noise is structured and inspectable. |
| Phase 8B | Noise emitters | `NoiseEmitterNode` for placed authored noise. | Noise uses normal requirements/effects. |
| Phase 8C | Distraction objects | `DistractionObject` and decoy defaults. | Distractions emit noise without a global manager. |
| Phase 8D | Existing verb bridges | Bentley bark and poop-decoy noise output. | Existing mechanics feed the same noise path. |
| Phase 8E | Listener component | `NoiseListenerComponent` for guard/NPC/debug receivers. | Listeners hear filtered noise events. |
| Phase 8F | Alert/debug readability | Alert controller/debug panel noise summaries. | Designers can inspect noise consequences. |
| Phase 8G | Scene/template proof | Dev-room/template validation. | Noise works in a reusable proof scene. |
| Phase 8H | Guard response lite | `NoiseReactiveGuard` callback receiver. | Guard response is debuggable without pathfinding AI. |

### Phase 9: Puzzle And Side Job Kit

Canonical numbering note as of 2026-06-21: Puzzle And Side Job Kit is Phase 9. Earlier index rows that labeled this family as Phase 8 were superseded by Jake's approved grouped roadmap execution and Phase 9A-9F implementation.

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 9A | Terminal/hack | Implemented: `TerminalHackNode` built from locked interaction patterns. | Hacking is requirement/effect-driven. |
| Phase 9B | Power/switches | Implemented: `PowerCircuitNode`, `TimedSwitchNode`, `PressurePlateNode`. | Local puzzles toggle facts/routes without custom scripts. |
| Phase 9C | Dead drops | Implemented: `DeadDropNode` for deposit/retrieve flows. | Drop state is explicit and replay-safe. |
| Phase 9D | Object swap/carry | Implemented: `ObjectSwapNode` and item-swap requirements. | Swap actions use mission inventory/facts. |
| Phase 9E | Bug/eavesdrop | Implemented: `BugPlantNode`, `EavesdropZone`. | Timed stealth objectives are effect-driven. |
| Phase 9F | Custom chronographic sequences | Implemented: `CustomSequenceResource`, `CustomSequenceStep`, `CustomSequenceRunner`. | Ordered steps enforce first-before-second logic without a giant orchestrator. |
| Phase 9G | First side job | Implemented: Poop Bag Calibration Course in `Phase9SideJobProofRoom`. | Side job has validation scene/report and no mission-specific script dependency. |
| Phase 9H | Second side job | Implemented: Bentley's Snack Trail in `Phase9SideJobProofRoom`. | Reuse is proven across more than one scenario. |
| Phase 9I | Production adoption gate | Implemented: route-gated `PpTacoSouthSideJobSignoff` under Taco `PlugAndPlayPilot`. | Production placement does not regress Taco/Phase0J/Phase0K authority. |

### Phase 10: Hideout Rewards / Cozy Meta Hooks

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 10A | Reward-to-hideout contract | Implemented 2026-06-22 via `HideoutRewardAdapter.build_contract()`. | Mission effects grant data, not direct UI mutations. |
| Phase 10B | Hideout reward adapter | Implemented 2026-06-22 via `HideoutRewardAdapter` plus `HideoutStateController.apply_mission_reward_contract()`. | No duplicate hideout reward manager is added prematurely. |
| Phase 10C | Store/care hooks | Lite implemented for Taco store unlocks and Bentley sauce-paw cleanup. | Hideout controllers own UI and interactions. |
| Phase 10D | Collectible/decoration hooks | Lite implemented for Taco polaroid/trophy/typed collectible display keys and store decor unlock availability. | Rewards are visible without direct mission-to-UI calls. |
| Phase 10E | Mission-return hooks | Lite implemented by syncing completed mission rewards when `HideoutManager` loads. | Rewards apply after success, not failure/restart. |
| Phase 10F | Save/load and regression | Focused tests cover completed-mission save/load contract path and idempotence. | Hideout reward state does not corrupt saves. |

### Phase 11: Paper Trail / Deniability

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 11A | Trace event schema | Trace IDs, source IDs, type, severity, cleanup eligibility. | Trace events are inspectable and namespaced. |
| Phase 11B | Trace recording adapter | Paper-trail adapter over mission facts/results. | Evidence/trace does not require new global state first. |
| Phase 11C | Cleanup mechanics | `AuditTrailCleanupNode`, wipe/cleanup effects. | Player can reduce or clear specific trace events. |
| Phase 11D | Heat sink objects | `HeatSinkObject` or equivalent plausible misdirection. | Trace can be redirected or weakened through authored mechanics. |
| Phase 11E | Door/action memory | `DoorStateMemoryNode` and suspicious-state facts. | Player actions can affect deniability. |
| Phase 11F | Result summary integration | Mission result reflects clean/messy/explainable/seen states. | Trace affects results before complex NPC behavior. |

Status note as of 2026-06-22: Phase 11A-11F is implemented as a runtime-first paper-trail packet. `PaperTrailTraceEvent` defines the trace schema, `PaperTrailAdapter` records mission-local traces and annotates mission results, `AuditTrailCleanupNode` cleans or weakens eligible traces, `HeatSinkObject` redirects traces to plausible explanations, and `DoorStateMemoryNode` records suspicious door/action memory. `MissionFactBridge`, `MissionEffect`, and `MissionEffectApplier` expose paper-trail facts/effects through the existing authoring path. Mission Dock, templates, `Phase11PaperTrailProofRoom`, focused GdUnit tests, a static validator, and this report complete the first deniability slice without adding persistent save-schema fields or NPC belief simulation.

### Phase 12: Narrative And Presentation

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 12A | Dialogue key registry | Expand `MissionDialogueBridge` beyond fallback lines. | Mechanics trigger dialogue keys without knowing dialogue implementation. |
| Phase 12B | Dialogue/bark triggers | `DialogueTriggerZone`, `BarkTrigger`, cooldown/one-shot rules. | Bark/dialogue spam is prevented. |
| Phase 12C | Presentation sequence player | Presentation-safe sequence player for intro/outro/flavor beats. | Presentation sequencing does not own mission gameplay state. |
| Phase 12D | Camera bridge | `CameraBridge` with optional PhantomCamera adapter. | Missing PhantomCamera fails safely or falls back. |
| Phase 12E | Player control bridge | `PlayerControlBridge` for short locks/restores. | Player control always restores after interruption. |
| Phase 12F | Audio-visual bridge | `AudioVisualBridge` with optional Resonant adapter. | Resonant remains presentation-only and not mission-state authority. |
| Phase 12G | Mission intro/outro hooks | Data-driven start/end beats. | Intro/outro trigger from mission state without custom mission scripts. |
| Phase 12H | Microcutscene decision gate | Add `MicroCutscenePlayer` only if bridges are too small. | No overlapping presentation systems are created prematurely. |

Status note as of 2026-06-22: Phase 12A-12H is implemented as a bridge-first narrative/presentation packet. `MissionDialogueBridge` now resolves registered dialogue keys and current-scene `MissionDialogueProvider` lines before falling back to simple authored text. `DialogueTriggerZone` and `BarkTrigger` are placed trigger nodes with cooldown/one-shot spam prevention and Mission Dock placement/audit support. `PresentationSequencePlayer` coordinates short flavor, intro, and outro steps through `CameraBridge`, `PlayerControlBridge`, `AudioVisualBridge`, and `MissionDialogueBridge`; it intentionally does not own mission gameplay state and does not replace Phase 9 `CustomSequenceRunner`. `CameraBridge` includes named focus, built-in blend/restore/shake behavior, and optional PhantomCamera adapter hooks; `PlayerControlBridge` locks/restores player control and can guide a player node; `AudioVisualBridge` plays named cues through optional Resonant hooks plus existing `AudioManager` / `EventBus` fallbacks. PhantomCamera and Resonant are not installed, so safe fallback behavior is the validated path. `MicroCutscenePlayer` was not added because the bridge-based player is sufficient for this first Phase 12 scope.

### Phase 13: Social Stealth Identity

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 13A | Social fact vocabulary | Cover story, credential, protocol, believable task, professionalism facts. | Social state starts as mission facts/effects. |
| Phase 13B | Credential data | `CredentialData` and simple inspection requirements. | Inspection can check credentials without NPC rewrite. |
| Phase 13C | Cover story data | `CoverStoryData` and requirement integration. | Plausible reason-to-be-there gates can be authored. |
| Phase 13D | Inspection zones | `InspectionZone`. | NPC/security zone accepts/rejects player using data. |
| Phase 13E | Believable tasks | `BelievableTaskZone`. | Performing tasks can reduce suspicion or unlock routes. |
| Phase 13F | Protocol/cleanliness | `ProtocolZone`, `CleanlinessGate`, simple professionalism meter. | Social/protocol outcomes affect mission facts/results. |
| Phase 13G | First social stealth slice | One mission area proves believable-action gameplay. | Player can pass through social logic without combat/AI overhaul. |

Status note as of 2026-06-22: Phase 13A-13G is implemented as an adapter-first social stealth packet. `SocialStealthAdapter` stores mission-local social state and annotates mission results; it is intentionally not a global manager. `CoverStoryData`, `CredentialData`, and `InspectionRuleSet` define authored social identity data. `MissionFactBridge`, `MissionEffect`, and `MissionEffectApplier` expose cover story, credential, protocol, task, professionalism, cleanliness, and inspection state through the existing requirement/effect path. `InspectionZone`, `BelievableTaskZone`, `ProtocolZone`, `ProfessionalismMeterNode`, and `CleanlinessGate` provide the first placed social stealth mechanics. Mission Dock placement/audit support, templates, `Phase13SocialStealthProofRoom`, focused tests, static validation, and the AI report complete the first believable-action slice without NPC AI overhaul or production Taco coupling.

### Phase 14: Encounter / Boss Challenges

Status: Complete as of 2026-06-22 for reusable Phase 14A-14G systems. Production challenge placement is intentionally policy-gated until manual QA passes for Phases 9I-13.

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 14A | Encounter design contract | Non-HP challenge principles implemented through phase, meter, fact/effect, route, evidence, Bentley, social, and deniability contracts. | Encounter runtime avoids default combat/HP terms and does not add combat managers. |
| Phase 14B | Encounter data | `EncounterPhaseData` and `ChallengeMeterData`. | Encounter phase/meter logic is data-driven. |
| Phase 14C | Encounter controller | Mission-local `EncounterController` plus `EncounterResultAdapter`. | Controller is scene-local and does not duplicate objective, alert, card, inventory, or completion managers. |
| Phase 14D | Challenge objective nodes | `ChallengeObjectiveNode` and phase-gated mechanic integration. | Challenge steps reuse `MechanicAreaBase`, `RequirementSet`, and `EffectSet`. |
| Phase 14E | Meter integration | Suspicion, security integrity, evidence strength, Bentley confidence, deniability meters plus encounter facts/effects. | Meters are exposed through `encounter_meter`; events/result tags are exposed through existing authoring bridges. |
| Phase 14F | First challenge prototype | `Phase14EncounterProofRoom.tscn` with clean social, Bentley, evidence, and messy route buttons. | Player routes can resolve the encounter through authored systems, not HP combat. |
| Phase 14G | Production challenge gate | Policy-only gate documented; no Taco production placement added. | Production adoption waits for Jake manual QA confirmation for Phases 9I-13. |

### Phase 15: Bounded Reactive NPC / Social Consequence Layer

Status: Complete as of 2026-06-22 for Phase 15A-15I reusable systems. Production adoption is intentionally gated; no Taco/story mission placement was added.

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 15A | AI readiness audit | Keep the scope to authored signals and bounded consequences. | No full NPC simulation, faction system, gossip network, or combat AI rewrite. |
| Phase 15B | LimboAI adapter gate | Optional context-injected adapter only. | Existing guards/security/mechanics/effects have no direct LimboAI dependency. |
| Phase 15C | Signal schema | `SocialSignalEvent`. | NPC reactions consume explicit records, not ambient magic state. |
| Phase 15D | Attention budget | `NpcAttentionBudget`. | Caps, cooldowns, and debug snapshots prevent runaway cascades. |
| Phase 15E | Reaction rules/fallback | `SocialReactionRuleSet`, `ReactiveNpcFallbackDriver`, `ReactiveNpcBrainAdapter`. | Missing rules or missing Limbo safely degrade to ignore/fallback reactions. |
| Phase 15F | Authoring nodes | `InvestigationPointNode`, `RoutineOverrideNode`, templates, Mission Dock support. | Designers can author points/routine changes without mission scripts. |
| Phase 15G | Facts/effects/results | Reactive signal/reaction facts, signal/evaluate/result-tag effects, result UI. | Consequences route through existing requirement/effect/result paths. |
| Phase 15H | Proof/validation | `Phase15ReactiveNpcProofRoom`, GdUnit, static validator. | Ignore, inspect, authority report, and routine override flows are covered. |
| Phase 15I | Production adoption gate | Policy-only; no production placement. | Adoption waits for Jake manual QA and explicit request. |

### Phase 16: Taco Garage-Manager Deniability Production Adoption

Status: Implemented 2026-07-03 as a bounded production-adoption pass. This is intentionally not a new reusable manager family; it is the first Taco production composition of the already-built Phase 11-15 adapters.

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 16A | Production placement boundary | `Phase16GarageManagerDeniabilityController` under Taco `GameplayRoot/PlugAndPlayPilot`, `start_on_ready = false`. | Existing bridge stays scoped with `include_legacy_candidates = false`; Phase0J/Phase0K are untouched. |
| Phase 16B | Social route | Clean garage-manager cover/credential/task/protocol/inspection route through `SocialStealthAdapter`. | Social facts and encounter result tags prove a clean route without a mission-specific social manager. |
| Phase 16C | Bentley/evidence routes | Bentley distraction trace redirection and invoice/evidence trace route. | Paper-trail summaries and encounter meters reflect deniability/evidence choices. |
| Phase 16D | Messy/authority route | Witness trace plus bounded reactive authority-report signal. | Reactive NPC summary records authority report without LimboAI or broad NPC simulation. |
| Phase 16E | Cleanup/redirect route | Trace redirect/weaken path for manager-story cleanup. | Cleanup route updates paper trail and deniability meter. |
| Phase 16F | Dev route trigger | `Phase16GarageDeniabilityDevTrigger` as a plain callable node under `PlugAndPlayPilot`. | Dev hook does not read input, is not an `Area2D`, and does not expose legacy interaction methods. |
| Phase 16G | Validation/reporting | Focused GdUnit contract, static validator, roadmap/blueprint/changelog/report. | Static validator, focused GdUnit, and Taco headless smoke pass or document known noise. |

Rules:

1. Keep the Phase 16 controller mission-local and reversible.
2. Do not route normal Taco interaction scanning through legacy candidates; preserve `MissionInteractionBridge.include_legacy_candidates = false`.
3. Do not add direct LimboAI calls or a global NPC/suspicion manager.
4. Do not mutate Phase0J/Phase0K bag/code/Louis completion authority in this adoption packet.
5. Treat route methods as explicit script-triggered entry points until a later authoring/UI hookup pass is manually QA-approved.

### Phase 17: Taco Route QA Activation + Level-Builder Readiness

Status: Implemented 2026-07-04 as the next grouped milestone after Phase 16. This is an activation/readiness pass, not a full player-facing route UI pass. Jake manually QA-confirmed canonical Taco bag/code/Louis flow and route-label mapping after this packet, clearing the next packet for player-facing route activation.

| Subphase | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Phase 17A | QA route controls | F12 `Phase 17 - Garage Routes` checklist calls `Phase16GarageDeniabilityDevTrigger` methods directly. | Route calls remain QA/debug-only and do not add Area2D or legacy candidate scanning. |
| Phase 17B | Debug/result readability | `Phase16GarageManagerDeniabilityController.get_summary()`, F10 `phase17_route`, and `MissionResult` route line. | Focused tests prove route label reaches mission result payload. |
| Phase 17C | Mission Dock readiness audit | Assist Browser read-only checks for Phase 16/17 helpers, bridge scope, and reusable mechanic mix. | Static validator checks Mission Dock tokens and Taco bridge guard. |
| Phase 17D | Reusable starter template | `NewMissionStarterTemplate.tscn` with `RuntimeHelpers`, scoped bridge, `MissionMechanics`, sample mechanics, and dormant encounter controller. | Scene loads under GdUnit. |
| Phase 17E | Non-Taco skeleton proof | `Phase17LevelBuilderReadinessProofRoom.tscn` plus `Phase17LevelBuilderProofHarness.gd` proving social/paper/reactive/encounter/noise composition. | Focused GdUnit runs the integrated proof and validates summaries. |
| Phase 17F | Validation/reporting | Phase 17 static validator, focused GdUnit, Phase 16 regression, scene smokes, roadmap/blueprint/changelog/report. | Pass or document known MCP/headless noise. |

Rules:

1. Keep Phase 17 Taco activation QA/debug-only; player-facing route activation belongs to the next packet now that manual Taco bag/code/Louis QA is confirmed.
2. Do not add a normal player-facing route interactable, input listener, or legacy interaction candidate in this packet.
3. Preserve `MissionInteractionBridge.include_legacy_candidates = false` for Taco.
4. Use existing adapters and mission-local controllers; do not add a new route, suspicion, NPC, or level-builder manager.
5. Treat the non-Taco proof scene as a small repeatability skeleton, not a full story mission.

### Phase 19: Seven Systems Player-Facing Replan (Pressure Economy)

Status: Implemented 2026-07-09 as a six-packet grouped milestone from `.cursor/plans/seven_systems_player-facing_replan_9ee29f3c.plan.md`. The seven dev-menu systems now share one player-facing pressure economy: NOW (noise/stealth), SOON (witnesses/cover), LATER (traces/mess feeding the post-mission Investigation Report), META (venue heat feeding next-mission difficulty and the hideout Heat Scanner radio).

| Packet | Scope | Primary Outputs | Validation Gate |
|---|---|---|---|
| Packet 1 | Interaction/readability | Hold-interact on `MechanicAreaBase`; `MissionReadabilityLayer` (noise pulse rings, NPC pips, Casing Mode overlay) auto-mounted by `IsoMissionBase`. | `ReplanPacket1ReadabilityTest` 8/8. |
| Packet 2 | Heist kit | `incriminating`/`bulky` item fields, `InspectionRuleSet` pocket check, `HeistKitHud`, footstep noise tiers, decoy throw via `MissionPlayerKitLayer`. | `ReplanPacket2HeistKitTest` 9/9. |
| Packet 3 | Cover runtime | `CoverMeterRuntime` drains + alibi windows, repeatable `BelievableTaskZone` stations, `RoamingInspectorNpc`, `CoverChallengePrompt` via `MissionCoverLayer`. | `ReplanPacket3CoverRuntimeTest` 9/9. |
| Packet 4 | Trace/mess loop | `MessSpotNode` props with cleanup crossover, `PaperTrailAdapter` hardening, `InvestigationReportBuilder` + `MissionResult` report card, report heat into `GameState.venue_heat`. | `ReplanPacket4TraceMessTest` 7/7. |
| Packet 5 | Witness counterplay | `WitnessNpc` notice/report travel/distraction/gossip-lite, `PhoneSabotageNode` report-point sabotage. | `ReplanPacket5WitnessTest` 7/7. |
| Packet 6 | Heat meta loop | `HeatScannerRadio` readout + cool-down shift wired into the Heat Scanner station and `HideoutManager`, briefing heat line, `IsoMissionBase` venue-heat noise seeding, `get_mission_heat()` = max(report heat, failed attempts). | `ReplanPacket6HeatMetaTest` 7/7 plus live HideoutHub smoke. |

Rules:

1. Extend `MechanicAreaBase`, mission-scoped adapters, and `MissionAlertController` inputs; no new global managers.
2. Register replan input actions at runtime; do not write them into `project.godot`.
3. Trace hardening stays opt-in per mission via `PaperTrailAdapter.set_hardening_seconds()`.
4. Keep the cool-down shift as an instant hideout action until a playable mission variant is scoped.
5. Production Taco adoption of the new layers still requires Jake's manual QA before a milestone commit.

## Phase 14: Encounter / Boss Challenge Layer

### Timing

Implement after mission construction, inventory, cards, suspicion/alert, Bentley, puzzle/side jobs, narrative presentation, social stealth, paper trail, and at least one hideout reward loop are stable enough to support a larger challenge.

### Future Files

| Future File | Class Name | Type | Purpose |
|---|---|---|---|
| `src/missions/iso/encounters/EncounterPhaseData.gd` | `EncounterPhaseData` | `Resource` | Data for one challenge phase: requirements, objectives, effects, meter thresholds, and transition rules. |
| `src/missions/iso/encounters/EncounterController.gd` | `EncounterController` | `Node` | Mission-local controller that advances phases based on facts/objectives/effects. |
| `src/missions/iso/authoring/mechanics/ChallengeObjectiveNode.gd` | `ChallengeObjectiveNode` | `MechanicAreaBase` | Placed objective node for challenge-specific actions. |
| `src/missions/iso/encounters/ChallengeMeterData.gd` | `ChallengeMeterData` | `Resource` | Defines meter id, display name, min/max, warning thresholds, and result mapping. |
| `src/missions/iso/authoring/mechanics/DisruptionActionNode.gd` | `DisruptionActionNode` | `MechanicAreaBase` | Physical/social/security disruption action that changes encounter meters and optional paper/social/alert consequences without HP combat. |
| `src/missions/iso/encounters/EncounterResultAdapter.gd` | `EncounterResultAdapter` | `RefCounted` | Adds active encounter summary to mission results when a mission-local controller exists. |
| `scenes/dev/mission_authoring/Phase14EncounterProofRoom.tscn` | n/a | `Scene` | Dev proof room with four route buttons for clean social, Bentley, evidence, and messy routes. |
| `src/tools/editor/phase14_encounter/phase14_encounter_validator.py` | n/a | `Python validator` | Static guard for required Phase 14 files, facts/effects, buttons, Mission Dock support, result integration, and no default HP/combat terms. |

### Initial Meter Vocabulary

Use these meters before inventing combat health:

1. Suspicion pressure.
2. Security integrity.
3. Evidence strength.
4. Bentley confidence or support readiness.
5. Plausible deniability.
6. Route control.

### Rules

1. Encounter phases must read facts/objectives/effects instead of owning parallel mission state.
2. Encounter controllers are mission-local, not new global autoloads.
3. Challenge nodes should reuse `MechanicAreaBase`, `RequirementSet`, and `EffectSet` whenever possible.
4. Traditional HP combat is not the default challenge model.
5. A validation scene must prove phase advancement before production adoption.
6. Production Taco placement remains gated until Jake manually approves Phases 9I-13 production QA.

### Done Criteria

1. A challenge progresses through phases using existing mission facts/objectives/effects.
2. The player can win through stealth, social, route, evidence, Bentley, or deniability play.
3. Encounter state is debuggable in a report or debug panel.
4. No duplicate objective, alert, card, inventory, or completion manager is introduced.

## Phase 15: Bounded Reactive NPC / Social Consequence Layer

### Timing

The first implementation is intentionally bounded: authored mission mechanics create `SocialSignalEvent` records, mission-local adapters evaluate rule resources under `NpcAttentionBudget`, and fallback reactions record safe consequences. Do not expand this into full NPC belief simulation or broad production adoption without a separate request.

### LimboAI Policy

LimboAI is appropriate only when concrete reactive NPC behavior exceeds the current authored security/Bentley/mission fact approach.

Current Phase 15 code does not depend on LimboAI. It can use a context-injected `limbo_reactive_npc_adapter` only when supplied by future project-owned glue. Do not call LimboAI APIs directly from mission mechanics, effects, or production scene scripts.

### Future Files

| Future File | Class Name | Type | Purpose |
|---|---|---|---|
| `src/missions/iso/ai/SocialSignalEvent.gd` | `SocialSignalEvent` | `Resource` | Authored signal schema for explicit noise/social/trace/evidence/routine events. |
| `src/missions/iso/ai/NpcAttentionBudget.gd` | `NpcAttentionBudget` | `Resource` | Caps how much reactive behavior can cascade at once. |
| `src/missions/iso/ai/SocialReactionRuleSet.gd` | `SocialReactionRuleSet` | `Resource` | Maps accepted signals/facts to bounded reaction IDs and optional effects. |
| `src/missions/iso/ai/ReactiveNpcBrainAdapter.gd` | `ReactiveNpcBrainAdapter` | `RefCounted` | Mission-local signal/reaction recorder and evaluator with optional adapter gate. |
| `src/missions/iso/ai/ReactiveNpcFallbackDriver.gd` | `ReactiveNpcFallbackDriver` | `RefCounted` | Safe fallback implementation for ignore/look/inspect/report/routine/dialogue/encounter/effect reactions. |
| `src/missions/iso/ai/ReactiveNpcResultAdapter.gd` | `ReactiveNpcResultAdapter` | `RefCounted` | Adds reactive NPC summary to mission results. |
| `src/missions/iso/authoring/mechanics/InvestigationPointNode.gd` | `InvestigationPointNode` | `MechanicAreaBase` | Places bounded points NPCs can inspect after authored events. |
| `src/missions/iso/authoring/mechanics/RoutineOverrideNode.gd` | `RoutineOverrideNode` | `MechanicAreaBase` | Applies route/routine override flags and emits bounded social signals. |
| `scenes/dev/mission_authoring/Phase15ReactiveNpcProofRoom.tscn` | n/a | `Scene` | Dev proof room with ignore, inspect, authority report, and routine override buttons. |
| `src/tools/editor/phase15_reactive_npc/phase15_reactive_npc_validator.py` | n/a | `Python validator` | Static guard for files, facts/effects, proof buttons, Mission Dock support, result integration, and no direct LimboAI dependency. |

### First Prototype Candidates

1. Ignored signal proves safe no-op behavior when no rule matches.
2. Investigation signal records an inspect-point fallback reaction.
3. Evidence signal records an authority-report fallback reaction.
4. Routine override sets an authored mission flag and records a change-patrol fallback reaction.

### Rules

1. Start with one validation scene, not production Taco.
2. Keep behavior bounded and debuggable.
3. Preserve existing security authorables and event routing.
4. Use mission facts/events as the interface between AI and mission systems.
5. Provide fallback behavior when LimboAI is absent or disabled.
6. Do not create open-ended gossip/cascading systems without caps, cooldowns, and debug output.
7. Mechanics/effects/production scene scripts must not call optional plugin APIs directly.

### Done Criteria

1. Signal/reaction scenarios react to authored mission facts/events.
2. Behavior is inspectable in debug output and mission results.
3. LimboAI dependency is optional, absent-safe, and adapter-gated.
4. Existing guard/security/Bentley systems continue to work without behavior-tree dependency.
5. Production adoption remains gated until Jake asks for a production placement pass.

## Resource Authoring Naming Conventions

Use stable, searchable names.

Requirement Resources:

```text
resources/mission_authoring/requirements/<mission_id>/<mechanic_id>_requirements.tres
```

Effect Resources:

```text
resources/mission_authoring/effects/<mission_id>/<mechanic_id>_success_effects.tres
resources/mission_authoring/effects/<mission_id>/<mechanic_id>_failure_effects.tres
```

Reusable global Resources:

```text
resources/mission_authoring/shared/requirements/requires_louis_delivery_route.tres
resources/mission_authoring/shared/effects/complete_delivery_bag_objective.tres
```

Rules:

1. Use mission-specific Resources when the behavior is mission-specific.
2. Use shared Resources only when at least two mechanics need the exact same logic.
3. Avoid premature shared libraries of dozens of Resources.

## Designer Workflow For One Door

Example: loading dock door unlocked by Louis route card.

### Scene Node

Place:

```text
LockedInteractionNode
```

Set exported fields:

```text
mechanic_id = loading_dock_gate
display_name = Loading Dock Gate
interaction_mode = INTERACT_REQUIRED
one_shot = false
prompt_text = Press E: Open loading dock gate
locked_prompt_text = Louis knows this route. Bring the right plan.
interaction_priority = 650
lock_kind = gate
unlocked_flag = loading_dock_open
```

### Requirement Resource

Create:

```text
resources/mission_authoring/requirements/taco_bell_drop/loading_dock_gate_requirements.tres
```

Contents:

```text
RequirementSet
match_mode = ALL
locked_message = Requires Louis Delivery Route.
requirements[0]
  fact_type = selected_card
  key = louis_delivery_route
  operator = EQUALS
  expected_value_type = bool
  expected_bool = true
```

### Success Effect Resource

Create:

```text
resources/mission_authoring/effects/taco_bell_drop/loading_dock_gate_success_effects.tres
```

Contents:

```text
EffectSet
effects[0]
  effect_type = SET_MISSION_FLAG
  key = loading_dock_open
  value_type = bool
  value_bool = true
effects[1]
  effect_type = SET_PRIMARY_OBJECTIVE_TEXT
  value_type = string
  value_string = Loading dock open. Recover Louis's bag.
effects[2]
  effect_type = TRIGGER_SIMPLE_DIALOGUE
  payload = {"speaker": "Louis", "text": "Told you. Delivery people see everything."}
```

### Expected Runtime Result

If card is selected:

```text
Player presses E.
RequirementSet passes.
Gate sets mission flag.
QuestManager objective text updates.
DialogueManager plays Louis line.
Door visual/collision toggles.
```

If card is missing:

```text
Player sees locked prompt.
Activation fails safely.
Optional failure dialogue/effects can run if assigned.
```

## Designer Workflow For One Search Objective

Example: search office drawer for evidence clue.

### Scene Node

Place:

```text
InteractiveContainer
```

Set exported fields:

```text
mechanic_id = manager_drawer_clue
display_name = Manager Drawer
container_kind = drawer
interaction_mode = INTERACT_REQUIRED
one_shot = true
prompt_text = Press E: Search drawer
locked_prompt_text = Nothing to do here yet.
search_flag = manager_drawer_searched
```

### Requirement Resource

Optional. Leave empty if drawer is always searchable.

### Success Effects

```text
effects[0]
  effect_type = GRANT_EVIDENCE_CLUE
  key = sterling_invoice_taco
  payload = {
    "title": "Sterling Catering Invoice",
    "description": "A catering route links Sterling's shell office to Louis's delivery bag.",
    "category": "Taco Bell Drop",
    "mission_id": "taco_bell_drop"
  }
effects[1]
  effect_type = COMPLETE_OBJECTIVE
  key = find_sterling_invoice
  value_type = string
  value_string = Found Sterling catering invoice.
effects[2]
  effect_type = TRIGGER_SIMPLE_DIALOGUE
  payload = {"speaker": "Mere", "text": "That invoice is either evidence or performance art. Bag it."}
```

## Designer Workflow For One Extraction

Example: leave after recovering delivery bag.

### Scene Node

Place:

```text
ExtractionZone
```

Set exported fields:

```text
mechanic_id = louis_exit
display_name = Louis's Exit
interaction_mode = INTERACT_REQUIRED
one_shot = true
prompt_text = Press E: Leave with Louis
locked_prompt_text = Not yet. Recover the bag first.
required_objective_ids = [delivery_bag_recovered]
messy_if_alerted = true
extraction_tag = louis_delivery_exit
```

### Success Effects

```text
effects[0]
  effect_type = SET_MISSION_FLAG
  key = extracted_with_louis
  value_bool = true
effects[1]
  effect_type = REQUEST_MISSION_COMPLETE
```

### Expected Runtime Result

`MissionCompletionBridge` requests mission completion through existing completion flow and ultimately falls back to `GameState.complete_mission("taco_bell_drop")` if no mission-local completion controller handles it.

## Validation Plan

### Static Checks

Run after implementing scripts:

```text
Godot script parse/load check if available
GdUnit4 test run if available
Existing project validators relevant to changed mission systems
```

### GdUnit4 Test Targets

Write tests for:

1. `MissionRequirement.evaluate()` with selected cards.
2. `MissionRequirement.evaluate()` with completed objectives.
3. `RequirementSet.ALL` failure details.
4. `RequirementSet.ANY` success details.
5. `EffectSet.apply_all()` order.
6. `MissionEffectApplier.COMPLETE_OBJECTIVE` calls `QuestManager.complete_objective_id()`.
7. `MissionEffectApplier.SET_MISSION_FLAG` writes namespaced `GameState.dialogue_flags`.
8. `MechanicAreaBase` one-shot prevents duplicate effects.
9. `TriggerZone` automatic activation works.
10. `MissionInteractionBridge` selects highest-priority nearby candidate.

### Runtime Validation Scene

Create `MechanicAuthoringTestRoom.tscn` before changing production missions.

The scene must include:

1. Player spawn.
2. `MissionInteractionBridge`.
3. Debug label/HUD output.
4. Always-available trigger.
5. Card-locked trigger.
6. Objective completion trigger.
7. Search/reward trigger.
8. Extraction trigger.

### Production Migration Gate

Do not migrate Taco production interactables until:

1. Validation scene passes.
2. Tests pass.
3. Existing Phase0J interactables still work.
4. No duplicated interaction prompt appears.
5. No mission completion regression appears.

## Custom Sequences And Presentation Bridges

Build custom sequences after the core mission construction kit works. Do not use a giant global orchestrator as the first solution.

### CustomSequenceResource

Recommended future Resource:

`resources/mission_sequences/*.tres`

Fields:

```gdscript
@export var sequence_id: StringName = &"sequence"
@export var display_name: String = ""
@export var steps: Array[CustomSequenceStep] = []
@export var one_shot: bool = true
@export var debug_enabled: bool = true
```

### CustomSequenceStep

Fields:

```gdscript
@export var step_id: StringName = &"step"
@export var order_index: int = 0
@export var display_name: String = ""
@export var depends_on_step_ids: Array[StringName] = []
@export var requirements: RequirementSet
@export var on_start_effects: EffectSet
@export var on_complete_effects: EffectSet
@export_enum("manual", "mission_flag", "objective_completed", "timer", "node_signal") var completion_condition: String = "manual"
@export var completion_key: StringName = &""
@export var optional: bool = false
@export var blocking: bool = true
```

Chronographic order should come from `order_index` plus `depends_on_step_ids`. For example, a dead-drop flow should represent `drop_box_01` before `drop_box_02` as data, not as mission-specific script.

### CustomSequenceRunner

Future runtime node:

`src/missions/iso/authoring/core/CustomSequenceRunner.gd`

Responsibilities:

1. Load a `CustomSequenceResource`.
2. Evaluate step requirements through `RequirementSet`.
3. Apply step effects through `MissionEffectApplier`.
4. Emit debug output for current step, completed steps, blocked steps, and missing prerequisites.
5. Avoid controlling cameras, player input, dialogue, or audio directly; route those through bridges.

### CameraBridge And PhantomCamera

Future bridge:

`src/missions/iso/authoring/core/CameraBridge.gd`

Responsibilities:

1. Focus a named target node.
2. Switch to a named camera rig.
3. Blend for a duration.
4. Shake or pulse on alarm/presentation beats.
5. Restore the gameplay camera.
6. Use PhantomCamera if installed and validated; otherwise return a safe fallback result.

Placed mechanics and sequence steps must call `CameraBridge`, not PhantomCamera APIs directly.

### PlayerControlBridge

Future bridge:

`src/missions/iso/authoring/core/PlayerControlBridge.gd`

Responsibilities:

1. Temporarily lock/unlock player input.
2. Freeze movement while leaving UI/dialogue usable when needed.
3. Optionally guide player movement for short presentation beats.
4. Restore the previous control state even if a sequence is interrupted.

Use this only for short authored presentation moments. Do not use it as a general movement rewrite.

### AudioVisualBridge And Resonant

Future bridge:

`src/missions/iso/authoring/core/AudioVisualBridge.gd`

Responsibilities:

1. Play a named audio-visual cue.
2. Stop a named cue.
3. Pulse a cue at a node or global position.
4. Set cue intensity from alert/suspicion/objective state.
5. Use Resonant if installed and validated; otherwise return a safe fallback result.

Initial Resonant use cases should be presentation feedback only:

1. Security alarm pulses.
2. Suspicion/alert state audio-reactive overlays.
3. Dialogue and bark visual pulses.
4. Objective-complete stingers.
5. Mission intro/outro ambience.
6. Hideout or future club ambience polish.

Do not let Resonant become mission-state authority. Mission facts and effects remain owned by the mission-authoring foundation.

### LimboAI Deferral

Do not integrate LimboAI during the core mission-authoring or visual-authoring phases. Revisit LimboAI only when NPC/guard/social behavior needs behavior trees or state machines beyond the current authored security and Bentley command-point approach.

## Debug Panel Requirements

Extend `IsoMissionDebugPanel` only after the foundation works.

Add sections eventually:

```text
Mission Mechanics
  Active mechanic count
  Last activated mechanic
  Last requirement failure
  Last effect result

Mission Facts
  Mission flags for current mission
  Selected cards
  Active objectives
  Completed objectives

Interaction Bridge
  Nearest candidate
  Candidate priority
  Candidate availability
```

Do not block Phase 1 on the debug panel extension. The first version can use `EventBus.debug()` and node labels.

## Implementation Order With Commit-Sized Work Packets

### Packet 1: Core Data Resources

Files:

```text
MissionFactBridge.gd
MissionRequirement.gd
RequirementSet.gd
MissionEffect.gd
EffectSet.gd
MissionEffectApplier.gd
```

Validation:

```text
RequirementSet tests
EffectSet tests
No scenes touched
```

### Packet 2: Dialogue And Completion Bridges

Files:

```text
MissionDialogueBridge.gd
MissionCompletionBridge.gd
```

Validation:

```text
Simple dialogue effect test
Mission completion bridge fallback test with stub scene/context
```

### Packet 3: MechanicAreaBase And TriggerZone

Files:

```text
MechanicAreaBase.gd
TriggerZone.gd
MechanicAreaBase.tscn
TriggerZone.tscn
```

Validation:

```text
One-shot test
Prompt/locked prompt test
Manual scene run in validation room
```

### Packet 4: MissionInteractionBridge

Files:

```text
MissionInteractionBridge.gd
MechanicAuthoringTestRoom.tscn
```

Validation:

```text
Nearest candidate test
Manual keyboard/controller prompt test
No production mission migration
```

### Packet 5: Core Mission Nodes

Files:

```text
ExtractionZone.gd
LockedInteractionNode.gd
SearchZone.gd
InteractiveContainer.gd
RewardNode.gd
RouteUnlockNode.gd
```

Validation:

```text
Each node has one validation scene example
Each node has at least one focused test or manual validation note
```

### Packet 6: First Production Adoption

Target:

```text
One non-critical Taco route/search/extraction slice
```

Rules:

1. Keep original Phase0J path intact.
2. Add new authoring path beside it.
3. Verify both paths do not double-complete objectives.
4. Remove old path only in a later cleanup packet after successful playtest.

### Post-Foundation Tooling Packets

Do not start these until Packet 6 proves at least one non-critical production slice can use the reusable mission-authoring path.

1. PVGames Object Palette v2 brush/repeat placement and Y-sort route awareness.
2. Mission Paint Dock for visual-only floor/wall/decal/foreground passes.
3. Manual Animation Mapper/Reviewer and reviewed `SpriteFrames` generation.
4. Mission Authoring Palette for approved mechanic templates.
5. Mission Assist Browser and core gizmo validation.
6. Larger Scene/Asset Browser in read/search/select mode only.
7. Custom chronographic sequence Resources and runner.
8. `AudioVisualBridge` with optional Resonant integration.
9. `CameraBridge` with optional PhantomCamera integration.
10. `PlayerControlBridge` for short sequence control.

2026-05-22 progress note: PVGames Object Palette v2, Mission Paint Dock v1, and Manual Animation Mapper v1.3 now exist as focused editor tools. The Manual Animation Mapper has a repaired Large Review Canvas and successfully validated one reviewed `walk_toward_01` range through generated preview `SpriteFrames` in the sandbox. Production animation wiring is intentionally deferred to a separate promotion packet. The next animation gate is real reviewed-map curation from the manual 5-pack sheets, not production runtime wiring.

## Anti-Patterns To Avoid

1. Do not add one script per mission-specific locked door.
2. Do not put card checks directly inside every mechanic.
3. Do not make `RequirementSet` mutate state.
4. Do not make `EffectSet` check requirements.
5. Do not create a new objective manager.
6. Do not create a new card manager.
7. Do not complete missions directly from random placed nodes without `MissionCompletionBridge`.
8. Do not add permanent save fields before proving namespaced `dialogue_flags` are insufficient.
9. Do not migrate all Taco interactables in the first implementation pass.
10. Do not let generic `CALL_METHOD` become the default effect type.
11. Do not call optional plugins directly from mechanics; use project-owned bridges.
12. Do not build the large Scene/Asset Browser before the focused palette, paint, authoring, assist, and animation tools prove their workflows.
13. Do not treat generated animation classifier labels as production truth without manual review.

## Acceptance Criteria For The Whole Plug-And-Play Foundation

The foundation is successful when a designer can create this mini mission without custom script:

1. Start in a room.
2. Search a drawer.
3. Receive a clue.
4. Complete an objective.
5. Open a route if a card is selected.
6. Trigger a Bentley or dialogue bark.
7. Exit through an extraction zone.
8. Receive a mission result through existing mission completion flow.

The system is not successful if the designer still needs to write mission-specific GDScript for each ordinary door, drawer, clue, route, reward, and exit.

## Final Recommendation

Implement the foundation in this exact order:

1. `MissionFactBridge`
2. `MissionRequirement`
3. `RequirementSet`
4. `MissionEffect`
5. `EffectSet`
6. `MissionEffectApplier`
7. `MissionDialogueBridge`
8. `MissionCompletionBridge`
9. `MechanicAreaBase`
10. `TriggerZone`
11. `MissionInteractionBridge`
12. `MechanicAuthoringTestRoom.tscn`
13. `ObjectiveStepController`
14. `ExtractionZone`
15. `LockedInteractionNode`
16. `SearchZone`
17. `InteractiveContainer`
18. `RewardNode`
19. `RouteUnlockNode`

This gives the project the reusable language first, then the base node, then one proof node, then the production mechanic family.

After that foundation is validated, implement editor and presentation tooling in this order:

1. PVGames Object Palette v2 brush/repeat placement.
2. Mission Paint Dock.
3. Manual Animation Mapper/Reviewer.
4. Mission Authoring Palette.
5. Mission Assist Browser and core gizmos.
6. Larger Scene/Asset Browser.

Current status as of 2026-05-22: Items 1-3 have v1 implementations, and the immediate Large Review Canvas auto-detection/full-sheet scroll repair has passed manual QA. Before item 4, finish the animation review gate: curate a small reviewed map from the manual 5-pack sheets, generate validation-only `SpriteFrames`, and validate them in a sandbox without touching production player/Taco scenes.
7. Custom chronographic sequences.
8. `AudioVisualBridge` plus optional Resonant integration.
9. `CameraBridge` plus optional PhantomCamera integration.
10. `PlayerControlBridge`.
11. LimboAI later, only when mature NPC/social/guard behavior needs it.
