# PHASE 0M-REPO-AUDIT-01

Audit-only repository + Godot scene/runtime assessment for cleanup planning and future plug-and-play authoring.

## Scope and method

- Read-only repo inspection across startup/autoloads, mission/hideout architecture, authoring/runtime systems, tests, validators, docs, and TileMap/assets.
- Godot MCP Pro editor and runtime checks on:
  - `res://scenes/MainMenu.tscn`
  - `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
  - `res://scenes/hideout/HideoutHub.tscn`
- Godot LSP diagnostics tool attempted (`scan_workspace_diagnostics`) but returned `files_scanned: 0` in this environment.
- Godot DAP debugger reachability validated (`godot_ping`).
- Kimi K2.6 used as advisory second-brain for risk blind spots and safe sequencing.

## Pre-existing working tree state

The repository started dirty with many modified/untracked gameplay/docs/report files outside this audit folder. Those were treated as pre-existing and untouched.

## Current working gameplay spine (protected)

Classified `PROTECTED_BASELINE`:

- Startup/menu flow: `project.godot` -> `res://scenes/MainMenu.tscn` -> `SceneManager.start_new_game()`.
- Hideout loop: `res://scenes/hideout/HideoutHub.tscn` with `HideoutManager` + manager cluster.
- Mission resolver/launch path: `MissionSceneResolver.resolve_playable_scene_path("taco_bell_drop")` -> `TacoBellIso_Editable_RedesignTest`.
- Mission architecture: `IsoMissionBase.gd` with `GameplayRoot`, `ArtRoot`, `EntityRoot`, `MarkerRoot`, `RuntimeSystems`.
- Interaction funnel: `Phase0JInteractionBridge.gd`.
- Authored security runtime: `SecurityAuthoringRoot.gd` + `MissionAuthoringRuntimeBuilder.gd` + `SecurityEventRouter.gd`.
- Authored collectible runtime: `CollectibleAuthoringRuntimeBuilder.gd` + `AuthoredPhase0JInteractablePickup.gd`.
- Mission completion path: `Phase0KMissionCompletionController.gd` + `Phase0KLouisExitInteractable.gd`.
- Success-commit + hideout sync: `MissionAuthoredCollectiblePersistence.gd` + `MissionCollectibleHideoutSync.gd`.
- Debug/operator visibility: `IsoMissionDebugPanel.gd` (F10/F9 path).

## Active systems summary

Classified `KEEP_ACTIVE` or `PROTECTED_BASELINE`:

- Core autoloads (`GameState`, `SaveManager`, `AudioManager`, `SceneManager`, `DialogueManager`, `QuestManager`, `CardManager`, `CardEffects`, `EventBus`, `CollectibleManager`).
- Taco mission authorable security stack (beams, cameras, guard spawns, patrols, area triggers, effect authors).
- Taco collectible authorables (`PoopBag`, `CaseCash`, `Polaroid`, `TinyIcon`, `GlowGuy`, `Clue`).
- Hideout sync displays (case cash, glow shelf, clue/evidence board, collectible displays).
- Louis exit and completion fallback integration.
- Security runtime classes (`MissionSecurityCamera`, guard and patrol runtime components, mission alert/controller path).

## Legacy and cleanup candidates (not executed)

Top findings:

- `src/missions/iso/runtime/AuthoredCollectiblePickup.gd` appears legacy/superseded by authored Phase0J interactable path.
- Taco scene contains heavy proof/editor residue under `SecurityAuthoringRoot` (many auto-named label nodes like `@Label@#####`).
- Large runtime debug marker surfaces (`GeneratedRuntimeMarkerDebugInteractables`) can create noise and coupling risk.
- Multiple mission scene variants (`TacoBellIso_Editable*.tscn`) exist while resolver pins playable flow to `TacoBellIso_Editable_RedesignTest.tscn`.
- Hideout includes large paint/depth layer families (`PVG_*`) and tool scaffolding that should be treated carefully.

## Scene/node clutter observations

- Taco has high counts of `Label`, `CollisionShape2D`, and runtime/debug `Area2D` nodes.
- Hideout has manager-heavy hierarchy and many paint/depth tilemap layers, including central-security paint variants.
- Several nodes are clearly proof/debug-oriented by naming, but many are runtime-generated or builder-dependent, so direct removal is high-risk without staged validation.

## TileMap/assets readiness for future visual map painting

Strengths:

- Clear structural split in Taco between gameplay tile/collision/marker layers and art layers.
- Hideout already uses layered paint model (`floor`, `wall`, `depth`, `foreground`) useful for future map-authoring conventions.
- TileMapLayer usage is broad and explicit, supporting visual pipeline work.

Risks:

- Layer taxonomy is large and partially mission/tool-specific.
- Naming/style consistency is mixed (legacy + phase tags + tool labels).
- Runtime/editor logs include tile/texture warnings that should be baseline-stabilized before large-scale painting refactors.

## Architecture risk summary

- `IsoMissionBase.gd` is highly central and large; changes there have broad blast radius.
- Many dynamic dependencies (groups, signal/event routing, runtime builders) are not fully visible from static scene-tree snapshots.
- Interaction and completion paths depend on runtime-generated nodes and naming contracts.
- Hideout manager composition is functionally active but tightly coupled.

## Validation outcomes

- Godot MCP Pro: successful project info + scene open + scene tree + runtime play/stop checks.
- Runtime baseline:
  - Main scene plays and returns expected main menu tree.
  - Taco scene plays and exposes expected root/layer structure.
  - Hideout scene plays and exposes expected manager/layer structure.
- Godot editor errors: warnings and some runtime/editor issues observed (including shadowing warnings, tool-annotation mismatch warning, and tile/texture warning traces).
- Godot LSP diagnostics: tool limitation in this run (`files_scanned: 0`).
- GdUnit4 and writing validators: intentionally skipped (would write outside approved audit output paths).

## Cleanup safety posture

- Do not remove or move baseline systems in current branch.
- Prefer staged, reversible candidate handling in a later approved cleanup pass with manifest + rollback paths.
- Treat dynamic runtime-builder and group/signal-linked nodes as `HIGH_RISK_DO_NOT_TOUCH_YET` unless runtime-validated in isolation.
