# Changelog

## 2026-05-02
- **Isometric dev slice (isolated):** `scenes/dev/IsoVerticalSlice.tscn` + `IsoVerticalSlice.gd` — standalone `TileMapLayer` stack under `WorldRoot` (`GroundLayer`, `DetailLayer`, `WallLayer`, `PropLayer`, `EntityRoot`) with `y_sort_enabled`; runtime tile paint from temporary `assets/tilesets/iso_vertical_slice/` placeholder atlas + `IsoVerticalSlice.tres`; `GameState.mission_catalog` entry `iso_vertical_slice` (**not** in default `available_missions`). `player.tscn` **collision_mask** `3` → `7` so **layer 3 (Walls)** collides with `CharacterBody2D` (required for wall tiles without `Player.gd` changes). See `docs/ISOMETRIC_LEVEL_SPEC.md`.

## 2026-05-01
- **Velvet Paw Floor 2 (Phase 3):** `JazzClubMission.tscn` — `Floor2Visuals` backstage/VIP/sound-booth layout at `y=1664`; repositioned `BackstageArea`, rig stairs (`OwnerSuiteStairs`, `StairsWayfinding`, `UpstairsFloor`, `StairsBlocker`), balcony briefcase markers, mixer/VIP phone/goblin polaroid; `SoundBoothShipmentNote` readable manifest; `Floor2PlayerSpawn` marker for Phase 4; `StaffBadgePickup` + `StaffRouteZone` remain Floor 1 for pre-puzzle social stealth.
- **Mission Bible implementation pass:** Save version `0.4.0-bible` — `mission_mutation_state`, `sterling_clues`, `poop_bag_count`, serialized `velvet_paw_resume_data`; heat API `get_mission_heat`, mutation rolls, Responsible Crime Lord intel bonus (3 poop bags/run); `CollectibleManager.has_polaroid`; legacy polaroid ID migrations (`rewrite_room_proof`, `conservatory_serenity`, `ellie_rescue`, `shadow_solo_pose`).
- **Shared pickups:** `PoopBagPickup` + `scenes/collectibles/PoopBagPickup.tscn`, `spawn_poop_bags_at_global_positions` on `LevelBase`; `MissionMutationHelper`; contaminated manifest interact (`contaminated_evidence_pickup.gd`).
- **Evidence board:** Sterling clue cards with `sterling_clue_id` persistence, auto-import of discovered clues, link line drawing.
- **Taco Bell:** Mutation keypad codes + Glow Guy slots, heat extra patrol, Louis heat hint, Tiny Icon + 3 poop bags + optional contaminated pickup, perfect polaroid, structured Sterling clue.
- **Jazz Club:** Extra pickups (hidden stage polaroid, bathroom Glow Guy, Yordano Tiny Icon, 3 poop bags), ledger clue registration, perfect polaroid when no setlist alarm; upstairs boss flow unchanged.
- **All missions:** Poop bag spawns and/or mutation rolls where applicable; Persian Tea community clue; polaroid ID alignment for Rewrite / Elephant / Shadow hidden pickups.

## 2026-04-30
- **Legal-safe collectibles:** Renamed optional polaroid IDs `taco_bell_smiskis` → `taco_bell_glow_guys`, `velvet_smiskis` → `velvet_shelf_goblins`; `GameState.normalize_polaroid_id` + save migration; hideout shelf uses `GlowCollectibleShelf` / `SceneManager.open_glow_collectible_shelf`; `debug_unlock_all_missions` defaults **false** for story order.

## 2026-04-29
- **Combat / HUD:** Light attack bound to **J** (plus existing mouse/gamepad); Bentley dental save adds 500ms damage grace so multi-hits do not apply HP after the proc; enemies get `hit_recovery_delay` after being hit; boss HP bar offset raised; HUD **STYLE** bar + finisher hint; `EventBus.combat_style_changed`.
- **Debug / UX:** Club owner boss shows a floating HP bar (`BossFloatingHealthBar`), chases slower (`chase_speed` 60) for troubleshooting; `GameState.debug_unlock_all_missions` (default false since 2026-04-30) appends all `mission_catalog` IDs after `reset_for_new_game` / new game when enabled — saves are unchanged; automated unlock tests force the flag off during runs. Pause combat text notes dash needs a move direction.
- **Player combat integration:** `PlayerCombatController` + `DashAbility` + `MeleeHitbox` under `player.tscn`; hitbox-based light combo / heavy (Q or RMB) / style finisher (R) / dash i-frames (Space); stealth overlap + unaware enemies supports `instant_kill()`; `EnemyBase` exposes `is_aware()` / `instant_kill()`; `CardEffects` adds combo window, style decay reduction, finisher damage hooks; `CardManager.is_card_active()` aliases selection; `EventBus.screen_shake` for combat juice (listeners optional). Legacy range `_attack()` + dodge timers remain only if `PlayerCombatController.enabled` is false.
- **Jazz owner-suite boss arena:** New scene `JazzClubOwnerArena.tscn`—press **E** on `OwnerSuiteStairs` (after setlist + both clues) to load the fight; bruiser boss with intro/outro dialogue; mission state saved in `GameState.velvet_paw_resume_data`; victory returns to the club at `SpawnPoints/ReturnFromOwnerSuite` and unlocks the balcony briefcase pickup.
- **Jazz Club overhaul:** 5-slot setlist with decoys + album-order hint; readable notes render on a high `CanvasLayer` (no top-left clipping); wrong-setlist triggers bass alarm (red overlay, reinforced `guard.tscn` hunters, safe-spot objective copy, 8s resolve); clues repositioned on bar vs dance floor and green sniff-trail shortcut removed; solving setlist opens stairs/backstage blockers.
- **Input / interact:** `Player` advances dialogue with E from `_physics_process` (fullscreen UI was eating `_unhandled_input` before `DialogueBox`, soft-locking the world); modal note + music puzzle use `blocking_ui` on their `CanvasLayer` with E/Esc to close; `DialogueManager.next_line` debounced to avoid double-advances.
- **Jazz Club fix:** Disabled invisible `LedgerDecoy` interactable/collision (it was stealing [E] backstage and showing a ledger the real upstairs flow could not complete); added `StairsWayfinding` (rig stairs treads + hint) revealed when the setlist is solved so the 2F route is visible.
- Velvet Paw (Jazz Club): perimeter + shortcut seal + tall backstage seal (puzzle removes seal); staff south gate optional path after badge pickup; ledger decoy twist with real book under amp; staff badge + sound check micro-objectives; interactables (mixer, VIP phone, Sterling poster); optional `velvet_shelf_goblins` and bar polaroid pickups; clue notes advance clue count via `note_read`.
- Scheme Cards: HUD shows per-card title, description, and READY/ACTIVE/USED state with short toasts when effects fire (`EventBus.card_triggered`).
- Taco Bell mission: wired passive card outcomes — Louis delivery route (service door without keycard), Mere legal eyes (one-shot alarm bypass), Polaroid Proof (start with receipt code), Clorox Protocol (skip decoy twist), Diamond A Year (highlight loot + marker). Passive combat/movement cards announce ACTIVE on deploy.

## 2026-04-28
- Added creative direction, architecture, task list, and decision docs.
- Confirmed MVP/stretches are separated around the heist spine.
- Continued implementation toward Nocturne City hub and final payoff.
- Repaired and polished City Hub as a contact/mission bridge from the hideout.
- Added final ending payoff scene after Sterling Tower.
- Improved failure progression with rotating titles, intel, card hints, and Jake upgrade support.
- Added six stretch mission maps using a shared interactive mission framework.
- Added dedicated Bentley ability input, mission ranks, camera follow for larger maps, and safer Scheme Card validation.
- Started neon-noir theme polish and distinct placeholder tinting for Parmida and Bentley.
- Added modules for branching dialogue, readable notes, evidence board, stealth vision, patrol routes, cipher puzzles, objective chains, room transitions, loadouts, and polaroid pickups.
- Fixed lingering parser issues in Rewrite Room and guard visuals by replacing fragile polygon scene data with simple ColorRects.
