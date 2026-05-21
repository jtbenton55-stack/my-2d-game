# Phase 3B — Taco South Return Pilot Lane Readability Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Packet type:** Scene-only visual/readability pass under `GameplayRoot/PlugAndPlayPilot` (no gameplay logic changes)

## Goal

Improve player-facing readability of the existing Packet 6B plug-and-play pilot (`SearchZone` → `RewardNode` → `RouteUnlockNode`) without repainting the full Taco map, changing collision, altering mission logic, or broadening plug-and-play adoption.

## Files changed

| File | Change |
|------|--------|
| `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` | Pilot lane visuals only under `PlugAndPlayPilot` |
| `reports/ai/2026-05-19_phase3b_taco_pilot_lane_readability_report.md` | This report |
| `reports/ai/phase3b_taco_pilot_lane_screenshots/*` | Before/after runtime screenshots |

**Not modified:** Any `.gd` file, `project.godot`, autoloads, `IsoMissionBase`, Phase0J/Phase0K scripts, `MissionInteractionBridge.gd`, canonical interactables, collision/barrier/tile paint, global debug labels, route systems, managers, save schema.

## Files inspected

| Area | Paths |
|------|--------|
| Phase 3A preflight | `reports/ai/2026-05-19_phase3a_taco_visual_readability_preflight_report.md` |
| Packet 6B pilot | `reports/ai/2026-05-19_packet_6b_taco_south_pilot_adoption_report.md` |
| Blueprint / roadmap | `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`, `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` |
| Authoring | `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`, `docs/ISO_EDITOR_TILE_PALETTE.md`, `docs/ART_READY_LEVEL_WORKFLOW.md` |
| Scene | `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` |

## Implementation summary

Scene-only edits limited to `GameplayRoot/PlugAndPlayPilot`:

1. **Pilot lane backdrop** — `PilotLaneBackdrop` (`Polygon2D`, charcoal semi-transparent strip, `z_index = -1`).
2. **Highlight rings** — `HighlightRing` (`Line2D`, closed, width 4) on each pilot mechanic with blueprint-aligned colors.
3. **Larger markers** — `SearchVisual` added; reward/route `ColorRect` chips enlarged to ~64×40 with higher contrast.
4. **Player-facing hint labels** — `HintLabel` text and style updated (font 12, dark fill + light outline, `z_index = 2`).
5. **Visual ordering** — `PlugAndPlayPilot.z_index = 30` (above runtime interactable polygons at 12, below Phase0J debug labels at 4090).

**Node choice:** `Polygon2D` for backdrop (world-space strip behind markers). `Line2D` for rings (visible on white floor, no collision).

## Exact scene path modified

`res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` → `GameplayRoot/PlugAndPlayPilot` subtree only.

## Visual nodes added/modified

| Node | Parent | Type | Notes |
|------|--------|------|-------|
| `PilotLaneBackdrop` | `PlugAndPlayPilot` | Polygon2D | `Color(0.12, 0.16, 0.22, 0.38)`, polygon ~(230,50)–(870,200), `z_index=-1` |
| `HighlightRing` | `PpTacoSouthSearchDrop` | Line2D | Yellow `Color(0.95, 0.85, 0.2, 0.92)` |
| `SearchVisual` | `PpTacoSouthSearchDrop` | ColorRect | 64×40 yellow chip |
| `HintLabel` | each pilot node | Label | Search / Collect / Open Route Peek |
| `HighlightRing` | `PpTacoSouthRewardScrap` | Line2D | Gold `Color(0.85, 0.65, 0.2, 0.92)` |
| `RewardVisual` / `RewardCollectedVisual` | reward | ColorRect | 64×40 gold / green collected state |
| `HighlightRing` | `PpTacoSouthRoutePeek` | Line2D | Purple `Color(0.75, 0.45, 0.95, 0.92)` |
| `RouteBlockedVisual` / `RouteOpenVisual` | route | ColorRect | 64×40 purple blocked / green open |
| `PlugAndPlayPilot` | `GameplayRoot` | Node2D | `z_index = 30` |

**Preserved (unchanged):** mechanic IDs, mission `taco_bell_drop`, flags `pp_taco_south_*`, requirements, success effects, `prompt_text`, collision shapes, pilot scripts, `MissionInteractionBridge.include_legacy_candidates = false`.

## Final visual colors/style decisions

| Mechanic | Ring / marker | Collected/open |
|----------|---------------|----------------|
| Search | Yellow `(0.95, 0.85, 0.2)` | N/A |
| Reward | Gold `(0.85, 0.65, 0.2)` | Green `(0.2, 0.85, 0.45)` when collected |
| Route | Purple ring `(0.75, 0.45, 0.95)`; blocked chip `(0.55, 0.25, 0.75)` | Green `(0.25, 0.75, 0.35)` when open |

Hint labels: dark text + cream outline; not gray debug-panel style.

## Before/after screenshot list

| File | Description |
|------|-------------|
| `reports/ai/phase3b_taco_pilot_lane_screenshots/before_spawn.png` | Pre-change (copied from Phase 3A capture) |
| `reports/ai/phase3b_taco_pilot_lane_screenshots/before_pilot_lane.png` | Pre-change pilot area baseline |
| `reports/ai/phase3b_taco_pilot_lane_screenshots/after_spawn.png` | Post-change spawn framing |
| `reports/ai/phase3b_taco_pilot_lane_screenshots/after_pilot_lane.png` | Post-change camera near pilot lane |
| `reports/ai/phase3b_taco_pilot_lane_screenshots/after_pilot_route_open.png` | Post-change with pilot chain completed (reward collected + route open visuals) |

Optional mid-chain frames (`after_pilot_search_complete`, `after_pilot_reward_collected`) were not captured separately; `after_pilot_route_open.png` documents the completed visual states.

## Pilot gameplay preservation result

Runtime validation via Godot MCP Pro `execute_game_script` (fresh pilot flags):

| Check | Result |
|-------|--------|
| Pre-reward collect | `requirements_failed` |
| Pre-route unlock | `requirements_failed` |
| Search | `activation_succeeded`; `pp_taco_south_found_scrap` true |
| Reward | `reward_collected`; `pp_taco_south_reward_collected` true |
| Route | `route_unlocked`; `pp_taco_south_route_open` true |
| Reward visuals | `RewardVisual` hidden; `RewardCollectedVisual` shown |
| Route visuals | `RouteBlockedVisual` hidden; `RouteOpenVisual` shown |
| `RoutePeekBlocker` | disabled after unlock |
| `MissionInteractionBridge.include_legacy_candidates` | `false` |
| `try_interact_at_position` near search | `true` |
| `delivery_bag_collected` after pilot chain | `false` |
| Phase3B nodes at runtime | `PilotLaneBackdrop`, all `HighlightRing`, `SearchVisual`, hints present |

Mechanic IDs and mission flags unchanged on disk.

## Canonical Taco non-regression result

| Check | Result |
|-------|--------|
| `Interactable_OBJ_bag_recovery` | exists |
| `Interactable_CLUE_route_manifest_half` | exists |
| `LouisExitToken` | exists at `GameplayRoot/GeneratedRuntimeInteractables/LouisExitToken` |
| Phase0J/Phase0K scripts | not edited |
| Mission completion via pilot | not triggered |
| Global debug labels / tile paint / collision | not edited |

## Tests / checks run

| Check | Result |
|-------|--------|
| Git branch | `new-feature-roadmap-branch` |
| GdUnit4 `res://tests/mission_authoring/` | **150/150 PASS** (exit 0, Overall Summary) |
| Godot LSP | N/A — no `.gd` files modified |
| Godot MCP Pro — reload + open Taco | pass |
| Godot MCP Pro — Taco play + pilot script | pass (see above) |
| Godot MCP Pro — MainMenu play | loads as `MainMenu`, no crash |
| Godot DAP | not needed (no ambiguous runtime failures after initial `await` crash in script) |
| Kimi K2.6 MCP | not used (small scene-only packet) |

## Godot MCP Pro result

- **Disk scene** contains Phase 3B nodes (confirmed via file grep).
- **Runtime play** loads updated pilot visuals; validation script passed without `await`.
- **Editor scene tree** (MCP `get_scene_tree`) did not list `PilotLaneBackdrop` / `HighlightRing` until editor reload — same stale-editor caution as Packet 6B. **Did not call MCP `save_scene`** to avoid overwriting disk with stale editor state.
- Screenshots saved under `res://reports/ai/phase3b_taco_pilot_lane_screenshots/`.

## Safety confirmation

- Only authorized files changed for this packet scope.
- No `project.godot` / autoload / `IsoMissionBase` / Phase0J/Phase0K / `MissionInteractionBridge.gd` edits.
- No canonical bag/manifest/Louis node edits.
- No `GeneratedRuntimeInteractables` structure changes beyond existing nodes.
- Rollback limited to removing Phase 3B visual children under `PlugAndPlayPilot`.

## Rollback plan

1. Under `GameplayRoot/PlugAndPlayPilot`, delete `PilotLaneBackdrop` and each `HighlightRing` / `SearchVisual`.
2. Revert `HintLabel` text/style and marker sizes/colors on the three pilot nodes.
3. Reset `PlugAndPlayPilot.z_index` if needed.
4. Re-run `res://tests/mission_authoring/` and MainMenu smoke.
5. Optional: delete `mission_flag:taco_bell_drop:pp_taco_south_*` from test saves.

## Known limitations

- Full-map debug label noise (`GeneratedRuntimeMarkerLabels`, security author labels) unchanged — deferred.
- Pilot lane is still blockout art, not production final.
- Editor may show pre-3B tree until **Project → Reload Current Project** or reopen scene from disk.
- Mid-chain screenshots not captured individually; completed-state frame included.
- Default spawn camera still does not frame the south pilot lane without moving camera/player (MCP script nudged camera for `after_pilot_lane.png`).

## Recommended next step

**Phase 3C or debug-label packet:** reduce `GeneratedRuntimeMarkerLabels` runtime noise policy, or continue art-ready workflow on a non-pilot Taco slice — without touching pilot requirements/effects.
