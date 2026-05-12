# GAME-ROADMAP-01 — Phase 2A: Current Game State Summary

## 1. What is the game right now?

**Concept (per code + Mission Bible):** "Untitled Heist RPG" — a top-down 2D heist with isometric maps, run-based missions, friend/crew progression, scheme cards, and a Sterling-syndicate finale. Tone: stylish, playful noir; emotional anchor = Bentley the dog.

**Concept (per actual playable surface today):** ONE iso heist map (Taco Bell Drop) that you can launch from a working hideout. Everything else in the mission catalog is either a placeholder story room or a stale `LevelBase`-style scene.

## 2. Current playable loop (evidence-based)

`scenes/MainMenu.tscn` (the project's `run/main_scene`) → New/Continue Game → `SceneManager.start_new_game()` resets state to `available_missions = ["taco_bell_drop"]` → loads `scenes/hideout/HideoutHub.tscn` → mission board / hideout stations / store / dialogue / decorating / evidence board are operable → "Start The Taco Bell Drop" button calls `HideoutMissionBoardController.launch_taco_bell()` which calls `MissionSceneResolver.resolve_playable_scene_path("taco_bell_drop")` → loads `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (the expanded iso map with Phase0J/K runtime stack) → player + dog spawn via `LevelBase` → in-mission systems (objectives, code gate, beam, route access, alarm controller, debug HUD, pause menu) come up → completion / failure / hideout return flows through `LevelBase` → `GameState.complete_mission` / `fail_mission` → `SceneManager.show_mission_result` → `MissionResult` scene → return to hideout. Save is auto-saved at attempt boundaries.

## 3. What actually works (verified by code + recent reports)

- **Main menu, new/continue game, save/load (JSON, 3 slots).**
- **HideoutHub:** state machine, station catalog, decorating mode, scheme card panel, evidence board panel, storefront, portrait dialogue (post-c2a/c2b), decor placement, debug controls.
- **Mission board → Taco launch:** `HideoutMissionBoardController` is the only mission with a real "Start" button; resolver correctly redirects to RedesignTest.
- **Iso Taco RedesignTest scene loads:** confirmed by D1C runtime smoke (GRB launched scene; Player present).
- **Phase 0J (code gate + adapters + bridge + router + debug HUD)** and **Phase 0K (mission completion controller, Louis exit, guard patrol/spawner, bounds cleanup, wrong-code attack guard)** are physically present in the scene and instantiable.
- **Beam one-shot logic** lives in `IsoMissionBase` (per D4 audit).
- **Pause menu** (`src/ui/test_ui/pause_menu.gd`) reads objectives/scheme/clues via `MissionPauseDataProvider`.
- **Tool surface for poop bags:** `MissionToolSurfaceHelper` + `IsoMissionBase.handle_tool_use` + `Player._try_throw_poop_bag` exists end-to-end; **aimed throw is wired**, although exact runtime behavior was last verified manually.
- **Sprint** (`Ctrl` / fallback `C`) via `PlayerStaminaController`; **Dodge** on Space; both passed D2A-FIX2 static checks.
- **Mission catalog progression rules** in `GameState._unlock_next_missions` define the entire Sterling arc graph in code.
- **Animation pipeline (c2a/c2b/c2b_fix1)** produced a contextual action classifier and recommended clips; the parallel `PlayerVisualAnimator.gd` exists.
- **PVGames asset pipeline** (palettes, icon library, object palette dock, paint-layer cleanup) is documented and built; assets are usable in the hideout.

## 4. What is only partially implemented

- **Objective state ownership** — three writers (IsoMissionBase, Phase0K, MissionObjectiveBridge). `MissionObjectiveBridge.reset_runtime_objectives_for_mission` is a **stub** (per D4).
- **Louis bypass route** — markers declare `bypasses_challenge_id="garage_entry_beam"` but `Phase0JMechanicRouter` still classifies ROUTE_* categories as **`INSPECT_ONLY_DEFERRED`** — so geometry exists but the bypass has no runtime gameplay effect yet.
- **Attempt reset semantics** — `IsoMissionBase._reset_attempt_runtime_state` exists, but QuestManager / Phase0K reset on reload isn't proven end-to-end (D4 risk).
- **Pause menu mission context** — works in Taco but the underlying `MissionPauseDataProvider._effective_mission_id` is a fallback; D2/D4 flagged need to verify non-empty `mission_id` in payload.
- **Stamina UX** — numeric controller works; **no UI bar** confirmed, only debug overlay.
- **Mission unlock graph** — code in `GameState` is complete, but only `taco_bell_drop` is intended to be playable now.
- **Hideout debug panel** — exists, but several station behaviors still output stub feedback ("scaffold").

## 5. What is broken / risky

- **Triple objective writes** (the seam D5-01 was designed to converge) — symptom: stale "Find Louis's bag" lines after restart, hint mismatch.
- **Pause + tree.pause + GRB interaction** — pausing the tree drops the bridge (D1B-RT2). Not user-facing, but the smoke harness is fragile.
- **`IsoMissionBase` is a 2632-line monolith** — every Taco fix touches a multi-system file. Highest mechanical-debt risk.
- **Hardcoded world cells for Louis corridor / beam** — silent breakage if map changes.
- **22+15 scene backups under `scenes/`** — risk of mis-opening a backup or signaling that the scene is volatile. Pure clutter, no behavior risk.
- **`README.md`** claims a fully-shipped 5-mission game with 16 scheme cards "complete" — actively misleading future agents/humans.

## 6. What is stale (from older plans)

- **D1B "canonical Taco scene = `TacoBellIso_Editable.tscn`" decision** — superseded by D1C which corrected the canonical/playable to RedesignTest.
- **Legacy `LevelBase`-style mission scripts** (`JazzClubMission.gd`, `RewriteRoomMission.gd`, `DiamondVaultMission.gd`, ...) — written before the iso framework decision; not part of the current "next mission" plan.
- **`scenes/missions/TacoBellMission.tscn`** + `src/missions/TacoBellMission.gd` — the classic story-room version; resolver bypasses them for `taco_bell_drop`.
- **README "5 missions complete"** narrative.
- **Older sprint/dodge fix reports** (`mission_foundation_d2`, `_d2a_sprint_fix`, `_d2a_fix1_sprint_runtime`) — fully superseded by `_d2a_fix2_sprint_runtime_debug`.

## 7. Reusable systems (worth investing in)

- `LevelBase`, `IsoMissionBase` (after extraction), `MissionSceneResolver`, `MissionPauseDataProvider`, `MissionObjectiveBridge`, `MissionClueBridge`, `MissionSchemeBridge`, `MissionToolSurfaceHelper`, `Mission*Placeholder` (12), `MissionAlertController`, `MissionSecurityCamera`, `MissionRouteAccessPoint`, `MissionLightZone`, `MissionEncounterTrigger`, `MissionCameraShake`, `MissionCameraTerminal`, `MissionTransitionPlaceholder`.
- `GameState`, `SaveManager`, `QuestManager`, `EventBus`, `DialogueManager`, `CollectibleManager`, `CardManager`/`CardEffects`.
- Hideout's controller-per-station pattern — clean, extensible, well-isolated.
- PVGames palette/icon library, object palette dock.

## 8. Spaghetti-prone systems

- `IsoMissionBase.gd` (size + many responsibilities).
- Player.gd ↔ scene root duck-typing (`scene.has_method("deploy_poop_bag_decoy_at")`).
- Phase0J/K "generic-named" controllers that are de-facto Taco-only.
- Two pause menu scripts; production uses the `test_ui/` path.
- Mission unlock matrix lives only in `GameState._unlock_next_missions`; coupling progression to a single private method.

## 9. The strongest playable content right now

The **Taco Bell Drop on RedesignTest**, when launched from the hideout. It has more honest-to-goodness gameplay surface (code gate, beam alarm, Louis route, poop bag tool, dog companion, debug HUD, pause menu) than the other missions combined. The **Hideout itself** is the second-strongest piece: it has multiple working stations, store, evidence board, scheme cards, and portrait dialogue.

## 10. The weakest links preventing this from feeling like a game

1. **Objective UX drift** — pause and HUD don't always agree on what to do next.
2. **No clean attempt reset** — Louis bypass / beam state can leak across retries.
3. **Louis bypass has no real gameplay difference yet** — the marquee scheme is layout-only.
4. **No mission "result + return" emotional beat** — `MissionResult` scene exists but the post-taco hideout return doesn't celebrate progress.
5. **One mission only** — Taco lands but Velvet / Rewrite have nothing to play yet.
6. **Stale docs and the README** — confuses humans and agents about the current scope.

## 11. Playable-loop identified?

**YES** — `Main Menu → Hideout → Mission Board → Taco RedesignTest → Result → Hideout`. Identified, not blocked.

## 12. Hard assertions

- `current_game_state_summarized`: **true**
- `playable_loop_identified_or_missing_reported`: **true** (identified)
- `working_systems_identified`: **true**
- `weakest_link_identified`: **true**

See `phase2_current_game_state.json`.
