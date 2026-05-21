# Packet 6B — Taco South Return Corridor Pilot Adoption Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Mission:** `taco_bell_drop`  
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Slice:** Candidate A (Packet 6A) — South Return Corridor `SearchZone` → `RewardNode` → `RouteUnlockNode`

## Goal

First controlled production-scene adoption of the validated plug-and-play construction kit: an optional, rollbackable pilot beside canonical Phase0J/Phase0K Taco completion. Pilot must not complete the mission or alter bag/manifest/Louis paths.

## Files changed

| File | Change |
|------|--------|
| `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` | Added `PlugAndPlayPilot` subtree, three pilot mechanics, `MissionInteractionBridge` |
| `src/missions/iso/runtime/authoring/MissionInteractionBridge.gd` | Added `include_legacy_candidates` (default `true`) for dual-bridge safety |
| `tests/mission_authoring/MissionInteractionBridgeTest.gd` | Added test for legacy exclusion when export is `false` |
| `reports/ai/2026-05-19_packet_6b_taco_south_pilot_adoption_report.md` | This report |

**Not modified:** `project.godot`, autoloads, `IsoMissionBase`, Phase0J/Phase0K scripts, canonical interactables, production completion wiring.

## Files inspected

- `reports/ai/2026-05-19_packet_6a_first_production_adoption_preflight_report.md`
- `reports/ai/2026-05-19_packet_2b10_construction_kit_validation_report.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md` (reference)
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` (reference)
- `src/missions/iso/authoring/mechanics/{SearchZone,RewardNode,RouteUnlockNode,MechanicAreaBase}.gd`
- `src/missions/iso/authoring/core/{MissionRequirement,RequirementSet,MissionEffect,EffectSet,MissionFactBridge}.gd`
- `src/missions/iso/runtime/{Phase0JInteractionBridge,Phase0KMissionCompletionController}.gd`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` (pattern reference)

## Implementation summary

1. Added `GameplayRoot/PlugAndPlayPilot` with three `Area2D` mechanics at Packet 6A coordinates.
2. Wired serialized `RequirementSet` / `EffectSet` subresources for reward/route gating and flag effects.
3. Added `GameplayRoot/RuntimeHelpers/MissionInteractionBridge` with `include_legacy_candidates = false` and `player_path = ../../EntityRoot/Player`.
4. Extended `MissionInteractionBridge` so Taco’s bridge does not target Phase0J/Phase0K/Louis groups while still collecting `mission_mechanic` / `interactable` pilot nodes.

**Note:** Godot MCP `save_scene` after disk edits reverted the scene once; pilot nodes were re-applied on disk and validated via runtime play (not MCP save). Avoid MCP `save_scene` on this scene until the editor reloads from disk.

## Exact scene path modified

`res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

## Pilot node tree added

```text
GameplayRoot
  PlugAndPlayPilot
    PpTacoSouthSearchDrop          (SearchZone.gd)
      CollisionShape2D
      HintLabel
    PpTacoSouthRewardScrap         (RewardNode.gd)
      CollisionShape2D
      RewardVisual
      RewardCollectedVisual
      HintLabel
    PpTacoSouthRoutePeek           (RouteUnlockNode.gd)
      CollisionShape2D
      RouteBlockedVisual
      RouteOpenVisual
      RoutePeekBlocker
      HintLabel
  RuntimeHelpers
    MissionInteractionBridge       (MissionInteractionBridge.gd)  [NEW]
    Phase0JInteractionBridge       [unchanged]
    Phase0KMissionCompletionController [unchanged]
```

## Final pilot coordinates (local to `PlugAndPlayPilot` / `GameplayRoot`)

| Node | Position |
|------|----------|
| `PpTacoSouthSearchDrop` | (520, 120) |
| `PpTacoSouthRewardScrap` | (640, 120) |
| `PpTacoSouthRoutePeek` | (760, 120) |

## Bridge configuration

| Property | Value |
|----------|--------|
| Path | `GameplayRoot/RuntimeHelpers/MissionInteractionBridge` |
| `player_path` | `../../EntityRoot/Player` |
| `interaction_radius` | `144` |
| `debug_enabled` | `false` |
| `include_legacy_candidates` | `false` |
| `action_interact` | `interact` (default) |

Phase0J bridge remains on `GameplayRoot/RuntimeHelpers/Phase0JInteractionBridge` unchanged.

## MissionInteractionBridge safety export

**Yes — required.** Added `@export var include_legacy_candidates: bool = true` (default preserves dev-room/tests). Taco sets `false` so the plug-and-play bridge does not collect `phase0j_interactable`, `phase0j_marker_debug`, or `phase0k_louis_exit` groups.

## Pilot ids / flags / effects

| Step | `mechanic_id` | Requirement | Success flags / state |
|------|---------------|-------------|------------------------|
| Search | `pp_taco_south_search` | none | `pp_taco_south_searched`, `pp_taco_south_found_scrap` |
| Reward | `pp_taco_south_reward` | `mission_flag` `pp_taco_south_found_scrap` EXISTS | `pp_taco_south_reward_collected`, `pp_taco_south_reward_effect` |
| Route | `pp_taco_south_route` | `mission_flag` `pp_taco_south_reward_collected` EXISTS | `pp_taco_south_route_open`, `pp_taco_south_route_effect` |

All keys are under `mission_flag:taco_bell_drop:pp_taco_south_*`. No inventory/cash/cards/completion effects.

## Pilot runtime validation results

Taco scene played via Godot MCP Pro; validation via `execute_game_script` (fresh pilot flags):

| Check | Result |
|-------|--------|
| `PlugAndPlayPilot` present | yes |
| Pre-reward collect | `requirements_failed` |
| Pre-route unlock | `requirements_failed` |
| Search | `activation_succeeded`; `pp_taco_south_found_scrap` / `pp_taco_south_searched` true |
| Reward | `reward_collected`; `pp_taco_south_reward_collected` true |
| Route | `route_unlocked`; `pp_taco_south_route_open` true |
| Reward visuals | `RewardVisual` hidden; `RewardCollectedVisual` shown |
| Route visuals | `RouteBlockedVisual` hidden; `RouteOpenVisual` shown |
| `RoutePeekBlocker` | disabled after unlock |
| Search repeat | `already_searched` |
| Reward repeat | `already_collected` |
| Route repeat | `already_unlocked` |
| `MissionInteractionBridge.try_interact_at_position` near search | `true` |
| `include_legacy_candidates` at runtime | `false` |

## Canonical Taco non-regression

| Check | Result |
|-------|--------|
| `Interactable_OBJ_bag_recovery` exists | yes |
| `Interactable_CLUE_route_manifest_half` exists | yes |
| `LouisExitToken` exists | yes |
| `delivery_bag_collected` after pilot chain | false (unchanged) |
| Phase0J/Phase0K scripts | not edited |
| Mission completion via pilot | not triggered |

Manual Phase0J bag/Louis interaction in the same MCP session was not exhaustively replayed; dual-bridge separation is enforced by group filtering plus distinct bridge nodes.

## Dual-bridge safety result

**Pass (architectural).** Plug-and-play bridge excludes legacy groups; Phase0J bridge untouched. Pilot mechanics remain in `mission_mechanic` / `interactable` groups for the new bridge only.

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit4 `res://tests/mission_authoring/` | **150/150 PASS** (report_29) |
| Godot LSP `MissionInteractionBridge.gd` | clean |
| Godot MCP Pro — Taco play + pilot script | pass (see above) |
| Godot MCP Pro — MainMenu play | loads as `MainMenu`, no crash |
| Godot DAP | not needed (no ambiguous debugger failures) |

## Godot MCP Pro result

- Scene file contains pilot subtree (confirmed via `search_in_files` and runtime `get_node`).
- **Caution:** Editor `get_node_properties` for pilot paths failed until disk reload; runtime play used updated file. Do not call MCP `save_scene` on Taco until editor reloads from disk.

## Kimi K2.6 MCP usage

| Call | Result |
|------|--------|
| Pre-implementation (prior session) | timeout |
| Post-implementation `regression_risk_review` | advisory received: watch legacy interaction starvation if bridge scope bleeds; verify dual-track mission state; keep flag guards strict |

Kimi advice reconciled against local results: runtime shows canonical nodes present and `delivery_bag_collected` false after pilot chain; bridge `include_legacy_candidates=false` is scoped on Taco instance only.

## Safety confirmation

- Only authorized files touched for this packet’s implementation scope.
- No `project.godot` / autoload / `IsoMissionBase` / Phase0J/Phase0K script edits.
- No canonical node deletion/disable.
- Pilot flags namespaced `pp_taco_south_*` only.
- Rollback is one scene subtree + bridge node (+ optional bridge script export revert).

## Rollback plan

1. Remove `GameplayRoot/PlugAndPlayPilot` from `TacoBellIso_Editable_RedesignTest.tscn`.
2. Remove `GameplayRoot/RuntimeHelpers/MissionInteractionBridge` if added only for this pilot.
3. Optionally revert `include_legacy_candidates` in `MissionInteractionBridge.gd` in a later packet if no other production scene needs it (keep if tests depend on it).
4. Optional save cleanup: delete `mission_flag:taco_bell_drop:pp_taco_south_*` keys from affected saves.
5. Re-run `res://tests/mission_authoring/` and MainMenu smoke.

## Known limitations

- Pilot positions are Packet 6A estimates; in-world reachability/visual overlap not fully playtested with live player movement through the south corridor.
- Runtime validation used direct mechanic APIs plus one bridge `try_interact_at_position`; full input-sim sequence (walk + interact key) not recorded.
- `RoutePeekBlocker` is a pilot-local `CollisionShape2D` demo disable, not production route manager integration.
- Editor MCP tree/properties may lag disk edits until manual scene reload.

## Recommended next step

**Packet 6C (or playtest packet):** Jake playtests south corridor pilot in-editor; confirm no overlap with bag/manifest/Louis/code-gate; then decide whether to widen adoption or remove pilot after metrics.
