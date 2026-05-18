# D6-06C — Louis Exit Interaction Regression + Hideout Sync Validation

**Date:** 2026-05-17  
**Verdict:** **PASS** (Louis focus + D6-06 commit on Louis exit); HideoutHub **visual** still PARTIAL (manager flags only in MCP)

## Root cause

`Phase0JInteractionBridge` handles **E/Q** for the Taco iso mission and calls `set_input_as_handled()`, so `Player._try_interact()` often never runs.

The bridge only considered nodes matching `_is_phase0j_candidate()` (`Phase0J*` metadata or `phase0j_*` groups). **`LouisExitToken`** uses `Phase0KLouisExitInteractable` with `generated_by = "Phase0K"` and group `phase0k_louis_exit` — it was **excluded**.

At the mission exit **(800, 848)** several **`Phase0JMarkerDebugInteractable`** nodes share the same position (`Debug_EXIT_mission_return_to_louis`, `Debug_OBJ_return_to_louis`, etc.). They are always “incomplete” (`is_completed()` returns false) with priority **260**, so the bridge routed E/Q to **debug inspect** instead of Louis (**900**).

D6-06B **authored collectibles** (group `phase0j_interactable`, priority **620**) made focus competition worse anywhere the player stood near uncollected/collected pickups because `is_interaction_available()` stayed **true** after collection.

**Secondary:** `Phase0KMissionCompletionController.complete_mission_and_exit()` was wired to `request_exit_completion()`, which requires **all** IsoMission definition objectives. Louis/Phase0K only requires **bag + code gate**, so exit could reject even when the player met Louis’s conditions. D6-06 pending collectibles were not committed on that path.

## Fix (narrow)

| File | Change |
|------|--------|
| `Phase0JInteractionBridge.gd` | Include `phase0k_louis_exit` group; treat `Phase0K*` `generated_by` as candidates |
| `Phase0JInteractablePickup.gd` | `is_interaction_available` / prompt false when collected; disable collision after collect |
| `Phase0KLouisExitInteractable.gd` | Explicit interaction eligibility helpers |
| `Phase0KMissionCompletionController.gd` | Try `request_exit_completion` first; on Phase0K-valid exit fallback: `_commit_pending_authored_collectibles` + legacy `GameState.complete_mission`; autoload access via `get_node_or_null` |

**Protected files:** untouched (`Player.gd`, `player.tscn`, `project.godot`).

## Validation (Godot MCP Pro)

| Check | Result |
|-------|--------|
| `find_best_candidate` at Louis position | **LouisExitToken**, priority **900** |
| `complete_mission_and_exit` with bag+gate + pending poop | **poop 0→1**, `committed=1` |
| Authored collectibles still spawn (4) | PASS (from D6-06B, unchanged) |
| Hideout flag after commit | `hideout_display:polaroid_taco_bell` set when polaroid in pending (prior D6-06B test) |
| HideoutHub scene visual | Not loaded in MCP session |

## Manual retest checklist

1. Play `TacoBellIso_Editable_RedesignTest.tscn`.
2. Complete bag + code gate; collect 4 proof authored items (E).
3. Return to Louis at exit; **E** should show **Talk to Louis** (not debug marker inspect).
4. Complete via Louis; confirm mission result → HideoutHub.
5. Confirm poop/polaroid/tiny displays or flags in hideout.

## Kimi K2.6

Not called (prior session timeout; fix validated locally).

## Known limitations

- Louis fallback still uses `GameState.complete_mission` when IsoMission formal objectives are incomplete (restores pre-D6-06B Taco behavior).
- Full HideoutHub shelf visual pass requires manual load after return.
