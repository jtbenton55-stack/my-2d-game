# Decisions

## 2026-05-10: Sprint input canonicalization (0M-D2A) + runtime fix (0M-D2A-FIX1)
**Canonical action:** `sprint` — **Ctrl-only** on the Input Map (`physical_keycode` **4194326** = `KEY_CTRL`). **Space** remains **`dodge`** only (dash / dodge burst). **`is_sprint_requested()`** also checks **`Input.is_physical_key_pressed(KEY_CTRL)`** because standalone Ctrl is not always surfaced reliably through `Input.is_action_pressed("sprint")` alone. Do not use **4194324** for Ctrl (that is **KEY_PAGEDOWN**). Stamina sprint is decided in **`PlayerStaminaController`**; **`Player.gd`** must not gate stamina sprint on `(not combat_on)` when hitbox combat is the default. While **dash** or **legacy dodge burst** is active, stamina sprint request is ignored so burst movement is not multiplied. Speed multiplier is read only when **`is_sprint_active()`** after `process_frame`.

## 2026-05-10: Mission scene resolver seam (0M-D2)
**Playable iso routing** for `taco_bell_drop` is owned by **`MissionSceneResolver.resolve_playable_scene_path`** → `TacoBellIso_Editable_RedesignTest.tscn`. **`GameState.mission_catalog["taco_bell_drop"].scene_path`** may remain the **classic** `TacoBellMission.tscn` for legacy/story definitions; hideout launch and `SceneManager.start_mission` use the resolver so the board never drifts back to the small iso bake without an explicit code change. **`MissionPauseDataProvider`** is the mission-agnostic entry for pause UI snapshots (objectives / scheme cards / clues).

## 2026-05-10: Taco iso scenes + dialogue/tool seams (0M-D1B, amended 0M-D1C)
**Playable expanded-map Taco (Hideout MissionBoard, `SceneManager` debug iso override for `taco_bell_drop`, `IsoMissionDebugPanel` restart):** `TacoBellIso_Editable_RedesignTest.tscn` — larger authored scene (Phase0J/K evolution; ~1.4M chars / ~1875 `[node` lines vs `TacoBellIso_Editable.tscn` ~706K / ~856). **`TacoBellIso_Editable.tscn`** remains the **bake/pipeline default output** from `IsoMissionBase` (`bake_to_editable_scene`, etc.) and a **leaner legacy baseline** for tooling; do not delete. **Dialogue:** generic `IsoMissionBase` must not preload Taco dialogue; taco missions resolve `TacoBellDialogueProvider` when `get_mission_id()` contains `taco`. **Tools:** player uses `MissionToolSurfaceHelper` → mission `handle_tool_use` / legacy deploy. **Objectives:** `QuestManager` owns pause/HUD strings; Iso owns gating IDs — `MissionObjectiveBridge` documents and wraps writes from Iso.

## 2026-05-09: Parmida C2B-FIX1 Contextual Frame Classifier (Sandbox Only)
PVGames female stack is analyzed in **row-major global order** with a **21-frame** context window (not row-only labels). Segments may split rows or span row boundaries; **walk_best** is chosen from segments overlapping row 0 / early row 1, never rows 35–37 as walk. Outputs are diagnostic only (`c2b_context_classifier/`, FIX1 reports, optional GIFs with documented cap).

## 2026-05-09: Parmida C2B Animation Discovery (Sandbox Only)
Parmida PVGames stack uses a **200×200** sheet grid (not 100×200). C2B pipeline composes five female layers, builds row forensics under `docs/reports/character_animation_c2b/`, and may emit **idle + walk** SpriteFrames in `c2b_full_animation/` while marking **run/attack** as not found when no row passes automated safety gates. Production player scenes and Taco Bell remain unchanged until a separate manual promotion pass.

## 2026-04-28: Build Spine Before Stretch Content
The project prioritizes a complete replayable meta-loop over a large unfinished RPG. The working spine is Hideout -> Mission Select -> Scheme Cards -> Mission -> Result -> Hideout.

## 2026-04-28: Use Compact Systems To Imply Scale
Nocturne City should feel large through district names, recurring contacts, cards, polaroids, and crew favors rather than a huge map.

## 2026-04-28: Failure Is Progress
Failure returns to the hideout/result screen with intel and supportive dialogue. No "Game Over" language in normal play.

## 2026-04-28: Avoid Direct IP Copying
Homage NPCs and jokes are allowed, but no copied designs, logos, powers, or exact franchise dialogue.

## 2026-04-29: Scheme Cards Are Passive Loadouts
Cards chosen before a mission apply automatically (buffs, perks, or Taco Bell–specific bypasses). No in-mission hotkey; visibility comes from the HUD card strip plus `EventBus.card_triggered` toasts when something fires.

## 2026-04-29: Hitbox Combat vs Legacy Dodge
Default player uses `PlayerCombatController` (hitbox melee + dash module). Space triggers dash with invulnerability via the `invulnerable` property plus the `invulnerable` group; turning off `PlayerCombatController.enabled` falls back to the older dodge timer + circular attack range for debugging or mods.

## 2026-04-29: Jazz Club Mission Structure
Wrong setlist is a timed alarm hunt (overlay + extra guards + resolve), not a hard fail. Correct setlist unlocks vertical progression (stairs/upstairs) where the real ledger lives behind a boss encounter (reused bruiser pattern first). Shared UI (`readable_note`) uses `CanvasLayer` so mission `Node2D` roots don’t clip fullscreen controls.

## 2026-05-01: Mission Bible Meta Serialization
Persist mission-spanning state in `GameState`: `velvet_paw_resume_data`, rolled `mission_mutation_state` per mission id, structured `sterling_clues` for evidence-board parity, and run-scoped `poop_bag_count` with intel bonus when ≥3 bags used in a successful mission attempt. Bump `SAVE_VERSION` to `0.4.0-bible` and migrate legacy polaroid ids via `POLAROID_LEGACY_IDS`.

## 2026-04-30: Legally Safe Collectible Naming + Polaroid Migration
Optional environmental polaroids use original IP-safe IDs (`taco_bell_glow_guys`, `velvet_shelf_goblins`). Legacy save keys (`*_smiskis`) map through `GameState.POLAROID_LEGACY_IDS` and `_migrate_polaroid_ids_inplace()` on load. Hideout shelf UI is `GlowCollectibleShelf` / `SceneManager.open_glow_collectible_shelf`. `debug_unlock_all_missions` defaults to **false** so normal story unlock order is preserved; enable locally for QA.
