# GAME-ROADMAP-01 — Phase 3: System-by-System Health Audit

Status codes: **READY / PARTIAL / BROKEN / STALE / DUPLICATED / SANDBOX_ONLY / UNKNOWN / MISSING**.

Machine-readable form: `phase3_system_health_audit.json`.

| # | System | Status | Evidence | What works | What is missing | Risks | Dependencies | Next recommended action | Fix when |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Project startup | READY | `project.godot` `run/main_scene = scenes/MainMenu.tscn`, 13 autoloads parse | Engine boots, main menu opens | nothing critical | New autoload churn could regress save schema | autoloads | none | ignore |
| 2 | `SceneManager` | READY | `src/autoload/SceneManager.gd` (~120 LOC) | Single entry; uses `MissionSceneResolver` for taco | none | Future regressions easy if more missions need overrides | resolver, GameState | leave as-is; add unit harness later | later |
| 3 | `GameState` | PARTIAL | `src/autoload/GameState.gd` ~870 LOC, `SAVE_VERSION=0.4.0-bible` | mission catalog, unlock graph, save schema, clues, scheme cards, poop bags, alerts | catalog scene_path for taco still points to classic story room (resolver overrides) | Catalog drift if more missions need playable overrides | resolver, SaveManager | normalize catalog `scene_path` for taco OR document override pattern | later (P2) |
| 4 | `SaveManager` | READY | `src/autoload/SaveManager.gd` ~70 LOC, JSON in `user://saves/` | 3 slots, autosave at mission boundary | no migration tests | save_version mismatch tolerated only with debug log | GameState | ignore | ignore |
| 5 | `HideoutHub` | READY | `scenes/hideout/HideoutHub.tscn` (~2494 lines), `HideoutManager.gd` (~918 LOC) | scene loads; stations + decorating + storefront + portrait dialogue confirmed | nothing critical for playability | scene size + 22 backup files in same folder | controllers below, dialogue, store | clean up backup files into `docs/reports/**/backups/` | later (P3) |
| 6 | `MissionBoard` (controller) | READY | `src/hideout/HideoutMissionBoardController.gd` ~90 LOC | Lists catalog, status text per mission, taco launch | Locked-mission UX ("Locked. Future job scaffold.") is just text | no future-mission preview | catalog + resolver | extend when 2nd mission becomes playable | later (P3) |
| 7 | `MissionSceneResolver` | READY | `src/missions/MissionSceneResolver.gd` ~63 LOC | hard-coded taco override, debug + default paths, legacy detector | needs to grow when other missions get iso surfaces | string-typed mission ids | GameState | extend per new playable mission | later (P3) |
| 8 | Taco Bell expanded mission scene | PARTIAL | `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` ~1.43 MB / 1875 node lines | Loads, Phase0J/K instantiated, Player + Bentley spawn (D1C runtime smoke), beam logic in `IsoMissionBase` | end-to-end objective lifecycle through retry not proven; Louis bypass has no gameplay effect | hard-coded cells, marker bake fragility | IsoMissionBase, Phase0J/K | run a D5-01 attempt-reset pass | **now (P0)** |
| 9 | Mission framework (`IsoMissionBase`/`LevelBase`) | PARTIAL | `IsoMissionBase.gd` 2632 LOC monolith; `LevelBase.gd` ~170 LOC thin | base scene structure, tile painting, marker indexing, runtime spawn, dev harness | extraction into RuntimeSpawner / RouteSubsystem / AlarmSubsystem / MarkerIndex / TacoBellFlavorAdapter | size + duplicated objective writes | many | DO NOT split before D5-01; extract after a working slice | later (P5) |
| 10 | `MissionObjectiveBridge` | PARTIAL | `src/missions/objectives/MissionObjectiveBridge.gd` 6 LOC (mostly docstring) | bridge file exists; class_name registered | `reset_runtime_objectives_for_mission` is a STUB | three writers issue | QuestManager, IsoMissionBase, Phase0K | implement reset + single-writer contract in D5-01 | **now (P0)** |
| 11 | `MissionPauseDataProvider` | READY | `src/missions/ui/MissionPauseDataProvider.gd` (D2 introduced) | `get_objective_snapshot`, `get_scheme_card_snapshot`, `get_clue_snapshot`, `get_pause_payload`, `has_mission_context`, `get_provider_id` all exist | needs explicit Taco mission_id pin during runtime | ID fallback through `GameState.current_mission_id` only | GameState | verify in runtime smoke; tighten in D5-02 | next (P1) |
| 12 | `MissionClueBridge` | PARTIAL | thin RefCounted class | shell exists | actual reset/publish API empty | not yet wired | GameState evidence_clues | extend during Jazz Club work | later (P2) |
| 13 | `MissionSchemeBridge` | PARTIAL | thin RefCounted class | shell exists | same as above | scheme effect dispatch still in `CardEffects` | CardManager, CardEffects | extend when scheme effects need mission gating | later (P2) |
| 14 | Tool surface / poop bags | READY | `MissionToolSurfaceHelper`, `Player._try_throw_poop_bag`, `IsoMissionBase.deploy_poop_bag_decoy_at` | aimed throw end-to-end | duck-typed `scene.has_method(...)` calls still in Player | new missions must replicate API | Player, IsoMissionBase | replace duck-typing with `IToolMissionSurface` group or signal | later (P2) |
| 15 | Sprint / stamina | READY | `PlayerStaminaController.gd` ~120 LOC; D2A-FIX2 validators PASS | Ctrl + fallback C; stamina drain/regen; runtime debug overlay | UI bar | static validators PASS; runtime PASS not claimed | Player.gd | manual runtime confirm; consider HUD bar | later (P2) |
| 16 | Space dodge / dash | READY | `Player.gd` dodge timer; D2A-FIX2 confirms Space dodge only | dodge works (per validator) | combat-dash separation tested only superficially | invulnerable frames bound to timer | Player.gd | regression-test alongside D5-01 | later (P2) |
| 17 | Player movement / collision | READY | `Player.gd` `_physics_process` + iso collision size override | works in iso | only WASD; no analog scaling smoothing notes | sprint+dodge interplay subtle | Player.gd | none | ignore |
| 18 | Player visuals | READY | sprite + parallel `PlayerVisualAnimator.gd` | parallel track; not gameplay-gated | full anim integration optional | n/a | character art | none for vertical slice | later (P3) |
| 19 | Character animations (c2a/c2b pipeline) | PARTIAL | `character_animation_c2b_fix1` reports produced contextual classifier; pipeline outputs catalog | classifier + recommended clips present | not yet imported as SpriteFrames in playable scenes | animation NOT a vertical-slice dependency | data only | revisit after Phase 1 ships | later (P3) |
| 20 | Dialogue / portraits | READY | `DialogueManager`, `DialogueBox.tscn`, `DialoguePortraitRegistry.gd`, hideout portrait pipeline | hideout portrait dialogue works | mission-side dialogue still mostly hooks | n/a | DialogueManager | extend per Mission Bible per-mission cutscene checklist | later (P2) |
| 21 | Storefront / Neon Nook | READY | `HideoutStoreController.gd`, `HideoutStorefrontPanel.gd/.tscn` | store opens, scrolls, icons drawn | inventory & money loop minimal | n/a | data/store | extend post-Phase 1 | later (P3) |
| 22 | PVGames icon library | READY | `pvgames_icon_library_b9_builder.py` + reports | icons importable | n/a | n/a | data only | leave as-is | ignore |
| 23 | Object palette / stamping | READY | `pvgames_object_palette` addon + `pvgames_editable_object_*.py` + `PVGEditableObject.gd` | dock + stamping works in editor | not used by missions yet | n/a | hideout art | leave as-is | ignore |
| 24 | Asset pipeline | READY | `pvgames_central_security_paintable_tileset_builder.py`, palettes, paint-layer cleanup | paintable palettes generated; central security palettes verified | only relevant for hideout/missions that paint | n/a | data only | leave as-is | ignore |
| 25 | UI / pause menu | DUPLICATED | `src/ui/PauseMenu.gd` + `src/ui/test_ui/pause_menu.gd` | test_ui version is production; reads pause provider | path smell only | naming + folder | provider | move test_ui pause menu under `src/ui/mission/pause/` later | later (P3) |
| 26 | Validators / test harnesses | READY | 41 Python validators under `src/tools/editor/` | Per-phase static validators pass | no headless Godot CI | n/a | python | maintain; add D5-01 validator | next (P1) |
| 27 | Docs / reports | PARTIAL | 26 doc-report folders + Mission Bible + README | foundational audits, D4 spec exist | README + D1B canonical-scene stale | confusing for future agents | n/a | annotate stale reports (Phase 4) | next (P1) |
| 28 | Build / runtime / GRB tooling | PARTIAL | `addons/godot-runtime-bridge`, `addons/godot_mcp`, MCP autoloads | bridge runs when game is open; ping works while editor session live | "pause tree drops bridge" issue; not running right now (`grb_ping` -> not connected) | runtime smoke fragile | engine running | leave; document limitations | later |
| 29 | Future mission framework | PARTIAL | `mission_module_audit` recommends extractions; D4 spec defers them | conceptual map exists | actual extraction not done | extraction is large-touch | IsoMissionBase | wait until Phase 1 slice ships | later (P5) |
| 30 | Save / load / persistence | READY | autosave at mission_start/complete/fail; schema versioned; `_validate_and_fix_mission_unlocks` on load | works | no migration ladder for older saves | low | GameState | none | ignore |

## Critical risk summary

- **P0 (block playable Taco quality)**: Objective writer convergence + `MissionObjectiveBridge.reset` stub + Taco mission_id in pause payload.
- **P1 (block next mission)**: Phase0J/K Taco-scene-local — when Jazz Club starts using iso framework, controllers must either be moved to `framework/` or split into `framework/` + `taco_adapter`.
- **P2 (architectural debt)**: `IsoMissionBase` monolith — fine to keep for Taco; refactor after Phase 1 ships.
- **P3 (clutter / friction)**: scene backups in `scenes/**`, duplicate pause menus, stale README/D1B docs.

## Hard assertions

- `system_health_audit_completed`: **true**
- `each_major_system_classified`: **true**
- `critical_risks_flagged`: **true**

See `phase3_system_health_audit.json` for the row-by-row machine-readable form.
