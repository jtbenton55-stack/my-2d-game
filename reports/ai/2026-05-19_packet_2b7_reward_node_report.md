# Packet 2B-7 — RewardNode Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Goal:** Add reusable visible pickup/reward mechanic extending `MechanicAreaBase`, with tests and dev-room validation.

## Files added

| File | Purpose |
|------|---------|
| `src/missions/iso/authoring/mechanics/RewardNode.gd` | Visible pickup/reward node |
| `tests/mission_authoring/RewardNodeTest.gd` | 11 focused GdUnit4 tests |

## Files modified

| File | Change |
|------|--------|
| `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` | Added `Rewards/DevRewardPickup` |
| `src/missions/iso/dev/MechanicAuthoringTestRoomController.gd` | `_configure_rewards()` + status flags |
| `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` | Short `RewardNode` section |

## Existing systems reused

- `MechanicAreaBase` — `activate()`, requirements, success/failure effects
- `RequirementSet` / `EffectSet` / `MissionEffect` / `MissionEffectApplier`
- `MissionFactBridge` — `collected_flag`, `GRANT_TYPED_COLLECTIBLE` routing
- `MissionInteractionBridge` — interaction routing

## Implementation summary

`RewardNode` provides `collect()` which delegates to `MechanicAreaBase.activate()` for requirement/effect evaluation. On success:

- Sets `collected` when `mark_collected_on_success`
- Sets `collected_flag` via `MissionFactBridge`
- Applies collect visual targets (hide pickup, show collected visual)
- Returns standard result dict with `reward_collected` code

No inventory UI, reward popup, or custom reward manager.

## EffectSet reward delegation

Reward specifics are entirely in `success_effects`:

- `SET_MISSION_FLAG` for flags like `dev_reward_effect_applied`
- `GRANT_TYPED_COLLECTIBLE` routes through `MissionEffectApplier` → `GameState.record_typed_collectible()`
- Other effect types (evidence, cards, etc.) work unchanged

Test `test_grant_typed_collectible_through_effect_set` confirms delegation.

## Dev room example (`Rewards/DevRewardPickup`)

- Prompt: `Press E: Collect dev reward`
- Sets `dev_reward_collected`, `dev_reward_effect_applied`
- Hides `RewardVisual`, shows `RewardCollectedVisual`

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit4 `tests/mission_authoring/` | **120/120** pass (109 prior + 11 new) |
| Godot LSP | Clean |
| Godot MCP `validate_script` | Pass |
| Dev room runtime | `reward_collected`, flags + visuals OK, repeat `already_collected` |
| MainMenu smoke | `MainMenu.tscn` loads |
| Godot DAP | Not needed |

## Kimi K2.6 MCP

Not used.

## Safety confirmation

- No `project.godot`, autoload, production scene, Taco, `IsoMissionBase`, or Phase0J changes
- No `RouteUnlockNode`, `SideObjectiveNode`, inventory UI, or reward popup
- No git commit/history changes

## Known limitations

- No inventory UI or reward popup
- Production mission migration not done
- `collect_sound_key` is a placeholder

## Recommended next step

Implement `RouteUnlockNode` or begin production adoption of reward pickups after Jake review.
