# GAME-ROADMAP-01 — Phase 1: Full Repository Inventory

This is an evidence-based inventory drawn from the live repo (Godot 4.6.2, "Untitled Heist RPG", branch `c2a-full-character-animation-20260509-172230`). The machine-readable form is in `phase1_full_repo_inventory.json`. Notation for status / scope columns:

- **active** — currently used at runtime by the playable loop
- **test_only** — sandbox / dev harness scene/script
- **legacy** — superseded but still on disk
- **stale_doc** — older report that no longer matches code
- **placeholder** — type defined but not wired into a playable mission
- **reusable** — framework-level
- **mission_specific** — tied to one mission
- **risk: low/med/high**

## 1. Autoloads (`project.godot [autoload]`)

| Name | Path | Status | Notes |
|------|------|--------|-------|
| `GameState` | `src/autoload/GameState.gd` | active | Holds mission catalog, save schema `0.4.0-bible`, clues, scheme cards, poop bags, alerts, mutations |
| `SaveManager` | `src/autoload/SaveManager.gd` | active | JSON slots 0..2 under `user://saves/`; thin and clean (~70 LOC) |
| `AudioManager` | `src/autoload/AudioManager.gd` | active | Framework only, no audio assets shipped |
| `SceneManager` | `src/autoload/SceneManager.gd` | active | Single entry for scene changes; uses `MissionSceneResolver` for taco |
| `DialogueManager` | `src/autoload/DialogueManager.gd` | active | Used by hideout + missions |
| `QuestManager` | `src/autoload/QuestManager.gd` | active | Dual API: legacy `active_objective` string + new `active_objectives` dict |
| `CardManager` | `src/inventory/CardManager.gd` | active | Lives under `inventory/` but autoloaded; minor smell |
| `CardEffects` | `src/autoload/CardEffects.gd` | active | Card effect dispatch |
| `EventBus` | `src/utils/EventBus.gd` | active | Signal hub |
| `CollectibleManager` | `src/collectibles/CollectibleManager.gd` | active | Polaroid + collectible tracking |
| `MCPRuntime` | `uid://c13j8nchilhxj` | active | Editor/runtime MCP plugin autoload |
| `GRBServer` | `uid://hwkgc74v20qq` | active | Godot Runtime Bridge for read-only inspection |
| `McpInteractionServer` | `uid://dyhub7l5qsyig` | active | `scripts/mcp_interaction_server.gd` shim for MCP interactions |

## 2. Core gameplay / framework scripts

| Path | Role | Status | Risk | Notes |
|------|------|--------|------|-------|
| `src/levels/LevelBase.gd` | base scene class for missions | active | low | thin (~170 LOC); spawns player/dog, exit zone, complete/fail |
| `src/levels/IsoMissionBase.gd` | iso mission base (Taco family) | active | **high** | **~2632 LOC monolith** — owns tile painting, marker index, runtime spawning of guards/cameras/alarms/routes, code gate, Louis literals, poop decoy, debug |
| `src/levels/Hideout.gd` | hideout shell (legacy non-hub) | legacy | med | predates `HideoutHub` set of controllers; not the active hub script |
| `src/levels/CityHub.gd` | unused hub variant | legacy | low | referenced by `scenes/CityHub.tscn` only |
| `src/levels/HeistTutorial.gd` | tutorial level | placeholder | low | scene not in active flow |
| `src/levels/IsoVerticalSlice.gd` | dev sandbox | test_only | low | `scenes/dev/IsoVerticalSlice.tscn` |
| `src/levels/TestMissionRoom.gd` | test room | active | low | small safe mission; default fallback for unknown ids |
| `src/levels/room_transition.gd` | helper | active | low | room↔room transitions |
| `src/missions/MissionSceneResolver.gd` | mission scene routing | active | low | hard-codes `taco_bell_drop → TacoBellIso_Editable_RedesignTest.tscn` |
| `src/missions/MissionData.gd` | mission resource type | active | low | |
| `src/missions/MissionMutationHelper.gd` | mutation/heat helper | active | low | |
| `src/missions/definitions/MissionDefinition.gd` (+ 7 sibling defs) | resource schemas | active | low | clue, collectible, cutscene, gate, zone, spawn etc. |
| `src/missions/objectives/MissionObjectiveBridge.gd` | objective publishing bridge | **partial** | high | declared as the single-writer seam; key `reset_runtime_objectives_for_mission` is a STUB (per D4 audit) |
| `src/missions/clues/MissionClueBridge.gd` | clue bridge | partial | med | thin bridge; consumer only |
| `src/missions/schemes/MissionSchemeBridge.gd` | scheme bridge | partial | med | thin bridge; consumer only |
| `src/missions/ui/MissionPauseDataProvider.gd` | pause snapshot provider | active | low | drives objectives/scheme/clues tabs in pause |
| `src/missions/tools/MissionToolSurfaceHelper.gd` | tool surface helper | active | med | constant `TOOL_POOP_BAG`; helps decouple player→mission tool API |
| `src/missions/taco_bell/TacoBellDialogueProvider.gd` | taco-only dialogue provider | active | low | already extracted from IsoMissionBase (good) |
| `src/missions/iso/authoring/IsoMissionMarker.gd` | authoring marker resource | active | low | scene-time marker class |
| `src/missions/iso/placeholders/Mission*Placeholder.gd` (×12) | runtime placeholder scripts | active | low | objective, clue, collectible, exit, friend-assist, poop-bag, code-gate, cutscene, scent-trail, puzzle-gate, access-item, generic interactable |
| `src/missions/iso/runtime/Phase0J*` (×14) | Phase 0J controllers + adapters + router + HUD + bridge | active | high | only fully wired in `TacoBellIso_Editable_RedesignTest.tscn`; `Phase0JMechanicRouter` marks ROUTE_* as `INSPECT_ONLY_DEFERRED` |
| `src/missions/iso/runtime/Phase0K*` (×7) | Phase 0K completion controllers, guard spawner/patrol, Louis exit, bounds cleanup, bag-objective interactable | active | high | also Taco-scene-local; `Phase0KMissionCompletionController._seed_objectives` is a second objective writer |
| `src/missions/iso/runtime/IsoMissionDebugPanel.gd` | dev panel | active | low | F-key debug HUD |
| `src/missions/iso/runtime/Mission{AlertController, CameraShake, CameraTerminal, EncounterTrigger, LightZone, PoopBagDecoyPoint, RouteAccessPoint, SecurityCamera, TransitionPlaceholder}` | runtime systems | active | med | mostly used only by Taco today but generically named |
| Per-mission scripts: `ArmWrestlingMission.gd`, `CarChaseMission.gd`, `CleanJobMission.gd`, `DiamondVaultMission.gd`, `ElephantRoomMission.gd`, `JazzClubMission.gd`, `JazzClubOwnerArena.gd`, `PersianTeaMission.gd`, `RewriteRoomMission.gd`, `ShadowSoloMission.gd`, `SterlingTowerMission.gd`, `TacoBellMission.gd` (legacy classic story room), `InteractiveMission.gd`, `TestMission.gd` | per-mission rooms | mostly **stale** | high (collectively) | extend `LevelBase` (NOT IsoMissionBase); much of the catalog points here. Only TestMission/TestMissionRoom is in the active loop; **the playable Taco does not use `TacoBellMission.gd` at all** (resolver redirects). |
| `src/missions/{bag_pickup_zone, taco_bell_vent, garage_puzzle, sterling_clue_note, ledger_decoy_interact, music_puzzle_trigger, owner_suite_stairs, scent_trail_marker, service_door_trigger, velvet_prop, yard_entrance, yordano_basement_interact, intel_pickup, contaminated_evidence_pickup}` | mission-specific helpers | mostly stale | med | tied to `LevelBase`-style story rooms; not used by the iso playable Taco |

## 3. Player + character

| Path | Role | Status | Risk | Notes |
|------|------|--------|------|-------|
| `src/player/Player.gd` | player controller | active | high | ~530 LOC; owns input/movement/dodge/attack/case-the-joint/poop-bag targeting; calls `MissionToolSurfaceHelper` |
| `src/player/PlayerStaminaController.gd` | sprint stamina | active | med | RefCounted, ~120 LOC; sprint action binding via `project.godot` |
| `src/player/PlayerSprintDebugOverlay.gd` | runtime sprint diagnostics | active (debug) | low | new since D2A-FIX2 |
| `src/player/DogCompanion.gd` | Bentley companion | active | low | spawned by `LevelBase` / iso base |
| `src/characters/PlayerVisualAnimator.gd` | parallel animation track | active (visuals) | low | sprite-frame swapping is parallel — gameplay does not gate on animation |
| `src/characters/NPC.gd` | basic NPC | active | low | hideout NPCs |

## 4. Hideout systems (HideoutHub)

| Path | Role | Status | Risk |
|------|------|--------|------|
| `src/hideout/HideoutManager.gd` | scene-root controller (~918 LOC) | active | med |
| `src/hideout/HideoutMissionBoardController.gd` | mission board panel | active | low |
| `src/hideout/HideoutStateController.gd` | hideout state machine | active | low |
| `src/hideout/HideoutCharacterController.gd` | NPC characters in hub | active | low |
| `src/hideout/HideoutCareController.gd` | Bentley care station | active | low |
| `src/hideout/HideoutCollectibleController.gd` | collectibles panel | active | low |
| `src/hideout/HideoutDebugController.gd` | debug panel | active | low |
| `src/hideout/HideoutDecoratingModeController.gd` | decorating UX | active | low |
| `src/hideout/HideoutDecorationController.gd` | placed decor | active | low |
| `src/hideout/HideoutDecorGridOverlay.gd` | grid overlay | active | low |
| `src/hideout/HideoutDecorPlacementValidator.gd` | placement validator | active | low |
| `src/hideout/HideoutDialogicAdapter.gd` | portrait dialogue adapter | active | low |
| `src/hideout/HideoutDialogueBank.gd` | NPC dialogue bank | active | low |
| `src/hideout/HideoutEvidenceBoardController.gd` | evidence board panel | active | low |
| `src/hideout/HideoutInteractable.gd` / `HideoutInteractionBridge.gd` | station interaction | active | low |
| `src/hideout/HideoutPlacedDecorItem.gd` / `HideoutPlacementZone.gd` | placed-decor objects | active | low |
| `src/hideout/HideoutPVGamesVisualHelper.gd` | art helper | active | low |
| `src/hideout/HideoutSchemeCardController.gd` | scheme card panel | active | low |
| `src/hideout/HideoutStationCatalog.gd` | station catalog | active | low |
| `src/hideout/HideoutStoreController.gd` | store controller | active | low |
| `src/hideout/PVGEditableObject.gd` | editable PVG object | active | low |
| `src/hideout/ScrollableStationPanel.gd` | scrollable panel | active | low |

## 5. UI

| Path | Role | Status | Risk |
|------|------|--------|------|
| `src/ui/MainMenu.gd` + `scenes/MainMenu.tscn` | entry point (`run/main_scene`) | active | low |
| `src/ui/TitleScreen.gd` + `scenes/TitleScreen.tscn` | alternate title | legacy/test | low |
| `src/ui/HUD.gd` + `scenes/ui/hud.tscn` | in-mission HUD | active | low |
| `src/ui/PauseMenu.gd` + `scenes/ui/pause_menu.tscn` | older pause UI | legacy | med (duplicates `test_ui/pause_menu`) |
| `src/ui/test_ui/pause_menu.gd` + `.tscn` | **production pause** wired into RedesignTest | active | high (path smell) |
| `src/ui/test_ui/controls_overlay.gd` + `.tscn` | controls overlay | active | low |
| `src/ui/MissionSelect.gd`, `MissionButton.gd`, `SchemeCardMenu.gd`, `MissionResult.gd`, `CrewMenu.gd`, `Ending.gd`, `PolaroidGallery.gd`, `GlowCollectibleShelf.gd`, `DialogueBox.gd`, `DamageNumber.gd`, `HideoutStorefrontPanel.gd` | mission UI | active | low–med |
| `src/ui/evidence_board/evidence_board.{gd,tscn}` + `evidence_card.{gd,tscn}` | evidence board | active | low |
| `src/ui/loadout/{equipment_item, item_slot, loadout_selector}.{gd,tscn}` | loadout UI | active | low |

## 6. Other systems

| Area | Files | Status | Notes |
|------|-------|--------|-------|
| Dialogue | `src/dialogue/{branching_dialogue_trigger, choice_panel, DialoguePortraitRegistry, DialogueResource, HideoutCharacterDialogueBank}.gd` | active | portrait dialogue done in c2a/c2b passes |
| Collectibles | `src/collectibles/{CollectibleManager, CollectibleItem, polaroid_pickup, PoopBagPickup}.gd` | active | poop bag pickup is the global tool |
| Combat | `src/combat/{CombatSystem, DashAbility, MeleeHitbox, PlayerCombatController, StealthSystem}.gd` | active | minimal; combat NOT the focus for Taco vertical slice |
| Enemies | `src/enemies/{Bruiser, Goon, Guard, EnemyBase, patrol_component, vision_cone, BossFloatingHealthBar, VictorSterling}.gd` | active | only `Guard`/`Goon` exercised by Taco |
| Inventory | `src/inventory/{CardManager, SchemeCard}.gd` | active | scheme card model |
| Objectives | `src/objectives/{objective_area, objective_chain}.gd` | active | used by legacy `LevelBase`-style missions |
| Crew | `src/crew/` | active | crew data |
| Icons | `src/icons/` | active | runtime icon helpers |
| Interactables | `src/interactables/` | active | hideout/world interactables |
| Puzzles | `src/puzzles/` | active | mission-specific puzzles |
| Docs (in `src/docs/`) | small | reference | small notes |
| Tests | `src/tests/{SaveLoadTest, StoryUnlockTest, TestRunner}.gd` + `TestRunner.tscn` | partial | minimal test harness |
| Utils | `src/utils/EventBus.gd` etc. | active | signal hub |

## 7. Scenes — by area

### 7.1 Top-level
- `scenes/MainMenu.tscn` — **`run/main_scene`** entry
- `scenes/TitleScreen.tscn`, `scenes/CityHub.tscn` — legacy / unused in current flow

### 7.2 Hideout (`scenes/hideout/`)
- **`HideoutHub.tscn`** — the production hideout (~2494 lines)
- `hideout.tscn` — older alternate (legacy)
- **22 `HideoutHub.phase0m*_backup.*.tscn` files** — staged backups from every Phase 0M sub-pass. These are **untracked-style backups inside the scenes folder** and create real visual clutter / risk of mis-load
- 4 `pvgames_palette_wall_*.png` and `.import` files — palette tilesets accidentally living in scenes/hideout/

### 7.3 Mission scenes (legacy classic story rooms — `scenes/missions/`)
- `TacoBellMission.tscn` (classic story; **not the playable Taco**)
- `JazzClubMission.tscn`, `JazzClubOwnerArena.tscn`, `RewriteRoomMission.tscn`, `CarChaseMission.tscn`, `CleanJobMission.tscn`, `DiamondVaultMission.tscn`, `ElephantRoomMission.tscn`, `ArmWrestlingMission.tscn`, `PersianTeaMission.tscn`, `ShadowSoloMission.tscn`, `SterlingTowerMission.tscn`, `TestMission.tscn`, `TestMissionRoom.tscn`

### 7.4 Iso missions (`scenes/missions_iso/`)
- **`TacoBellIso_Editable_RedesignTest.tscn`** — **THE PLAYABLE TACO** (per `MissionSceneResolver`)
- `TacoBellIso_Editable.tscn` — legacy / bake-output; should not be playable target
- `TacoBellIso_Editable2.tscn`, `TacoBellIsoBlockout.tscn`, `TacoBellIsoHandEditTest.tscn`, `TacoBellIso_Editable_Test.tscn` — dev / test
- **15 `TacoBellIso_Editable_RedesignTest.<phase0...>_backup.*.tscn`** — phase backups (matches hideout pattern)

### 7.5 Mission placeholders (`scenes/mission_placeholders/`)
`AccessItem.tscn, CluePickup.tscn, CollectiblePickup.tscn, CutsceneTrigger.tscn, ExitTrigger.tscn, FriendAssistTrigger.tscn, ObjectiveMarker.tscn, PoopBagPickupPlaceholder.tscn, PuzzleGate.tscn`

### 7.6 UI (`scenes/ui/`)
Mission UI scenes: `CrewMenu, damage_number, DialogueBox (+ 1 backup), Ending, GlowCollectibleShelf, hud, MissionButton, MissionResult, MissionSelect, pause_menu, PolaroidGallery, SchemeCardMenu, HideoutStorefrontPanel`

### 7.7 Other scene folders
- `scenes/characters/` — character scenes
- `scenes/collectibles/` — collectible scenes
- `scenes/dev/IsoVerticalSlice.tscn` — dev sandbox
- `scenes/heists/`, `scenes/templates/` — present, mostly empty/placeholders

## 8. Data + resources

- `data/dialogue/`, `data/store/`
- `resources/cards/`, `resources/equipment/`

## 9. Docs / reports

Top-level docs of interest:
- `docs/MISSION_BIBLE.md` — design baseline (61 lines, terse)
- `docs/reference/`, `docs/reports/`
- `README.md` (legacy gift-game blurb — partially stale)
- `FOLLOWUPS.md` (Jazz Club Phase 2/4 deferred items)
- `ASSET_MANIFEST.md`, `RESCUE_NOTES.md`

`docs/reports/` subdirs (26 of them):
- `mission_module_audit` (architecture audit; foundational)
- `pre_taco_module_hardening` + `_runtime` (D1B; **superseded canonical-scene decision** — see Phase 4)
- `taco_canonical_scene_correction` (D1C; corrects D1B)
- `mission_foundation_d2`, `mission_foundation_d2a_sprint_fix`, `mission_foundation_d2a_fix1_sprint_runtime`, `mission_foundation_d2a_fix2_sprint_runtime_debug` (sprint + bridges)
- `taco_bell_redesign_d4` (the current "next step" plan)
- `character_animation_c2a`, `character_animation_c2b`, `character_animation_c2b_fix1`, `character_sprite_replacement` (animation pipeline reports)
- `hideout_dialogue_portraits`, `hideout_storefront_icons` (portrait + storefront passes)
- `pvgames_*` (×7) — paintable tilesets, central security palettes, icon library, object palette, geometry audit
- `reveal_safety`

## 10. Addons / plugins

| Addon | Purpose |
|-------|---------|
| `godot-runtime-bridge` | GRB MCP runtime inspection |
| `godot_mcp` | MCP plugin |
| `pvgames_object_palette` | PVGames object palette editor dock |

## 11. Tool scripts (`src/tools/editor/`)

41 Python scripts: per-phase static validators and builders for the character-animation pipeline, hideout dialogue portrait pipeline, PVGames asset pipeline (icon library, paintable palette, object palette, stamper), mission module audit, pre-taco hardening, taco canonical scene check, mission foundation D2/D2A, and taco redesign D4. All non-destructive; reads repo files, writes reports.

## 12. Identified duplication / overlap (preview of Phase 5)

1. **Two pause menu scripts** — `src/ui/PauseMenu.gd` + `src/ui/test_ui/pause_menu.gd`. Production uses the `test_ui` path.
2. **Two Taco "story" surfaces** — classic `TacoBellMission.tscn` + iso `TacoBellIso_Editable_RedesignTest.tscn`. The catalog still references the classic one, but the resolver overrides for the playable.
3. **Three objective writers** — `IsoMissionBase`, `Phase0KMissionCompletionController._seed_objectives`, `MissionObjectiveBridge.publish_primary_objective`. Convergence is a known P0 (D4 spec).
4. **Phase0J / Phase0K runtime stack is Taco-scene-local** despite generic names; if reused as a framework, names mislead.
5. **22 hideout + 15 Taco scene backups** sitting in `scenes/**` instead of `docs/reports/**/backups/`.
6. **README.md** still claims "5 unique missions, 16 scheme cards complete" — does not match current Mission Bible scope.

## 13. Hard assertions

- `repo_inventory_completed`: **true**
- `major_systems_identified`: **true**
- `autoloads_listed`: **true**
- `mission_scripts_listed`: **true**
- `iso_runtime_stack_listed`: **true**
- `scene_backups_flagged`: **true**

See `phase1_full_repo_inventory.json`.
