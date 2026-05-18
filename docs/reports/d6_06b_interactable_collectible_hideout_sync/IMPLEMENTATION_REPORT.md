# D6-06B Implementation Report — Interactable-Backed Collectible Authoring + Hideout Sync

**Date:** 2026-05-17  
**Branch:** `c2a-full-character-animation-20260509-172230`  
**Status:** PASS (runtime validated via Godot MCP Pro)

## Summary

Replaced the failed D6-06 collision-only `AuthoredCollectiblePickup` path with **Phase0J E-interact** mechanics (`AuthoredPhase0JInteractablePickup` extending `Phase0JInteractablePickup`). Authored collectibles spawn under `GameplayRoot/GeneratedRuntimeInteractables/AuthoredGeneratedInteractables`, record into mission-attempt pending state, commit on successful exit completion, and set hideout display flags for HideoutHub sync.

## Root cause (D6-06 failure)

- `AuthoredCollectiblePickup` used walk-over `Area2D` overlap only; nodes were **not** in `interactable` / `phase0j_interactable` groups and did not implement the E-interact flow the player uses for working Taco collectibles.
- A **parse error** in `IsoMissionBase.gd` (`display_name` line missing `)`) prevented the mission script from loading, so `_setup_d6_06_collectible_authoring_runtime()` never ran at play start.

## Files added

| File | Role |
|------|------|
| `src/missions/iso/runtime/AuthoredPhase0JInteractablePickup.gd` | E-interact pickup; routes to `record_authored_collectible_attempt` |
| `src/missions/iso/runtime/MissionCollectibleHideoutSync.gd` | Hideout display keys + `GameState.dialogue_flags` sync |
| `src/tools/editor/d6_06b_interactable_collectible_hideout_sync/phase0md6_06b_static_validator.py` | Read-only static checks |

## Files modified

| File | Change |
|------|--------|
| `src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd` | Spawns Phase0J-style interactables under `AuthoredGeneratedInteractables` |
| `src/missions/iso/runtime/AuthoredCollectiblePickup.gd` | Marked DEPRECATED |
| `src/missions/iso/authoring/CollectibleAuthorBase.gd` | `hideout_collection_key` export |
| `src/levels/IsoMissionBase.gd` | Pending tracking, commit on `request_exit_completion`, clear on `fail_level` / reset |
| `src/missions/iso/runtime/IsoMissionDebugPanel.gd` | F10 pending/committed/path/hideout fields |
| `src/hideout/HideoutStateController.gd` | `mark_collectible_display_found()` + group |
| `src/hideout/HideoutManager.gd` | Apply persisted hideout flags on load |

## Protected files

Untouched: `project.godot`, `Player.gd`, `PlayerStaminaController.gd`, `scenes/characters/player.tscn`.

## Taco proof cluster

`GameplayRoot/SecurityAuthoringRoot/CollectibleAuthoringProof` (~8950, 620):

- `D6_06_PoopBag_Author` — `d6_06_proof_poop`
- `D6_06_Money_Author` — `d6_06_proof_money`
- `D6_06_Polaroid_Author` — `d6_06_proof_polaroid`
- `D6_06_TinyIcon_Author` — `d6_06_proof_tiny`

Runtime: 4 nodes under `AuthoredGeneratedInteractables`; F10 shows `phase0j_interactable` path kind.
