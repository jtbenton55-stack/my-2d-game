# Decisions

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
