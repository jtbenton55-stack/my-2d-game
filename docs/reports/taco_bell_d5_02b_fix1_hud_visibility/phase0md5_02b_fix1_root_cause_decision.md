# Phase 3 — Root cause decision

## Classification (from Phase 1 + static code review)

| Tag | Applies | Notes |
| --- | --- | --- |
| `CANVAS_LAYER_POLICY_MISSTATED_IN_PRIOR_CHAT` | Yes | Higher `CanvasLayer.layer` draws on top; player HUD belongs **below** debug 90–110 when debug is shown. |
| `HUD_REFRESH_STRUCTURE_RISK` | Yes (mitigated) | Prior `_refresh_mission_compact_hud` returned before `payload` if `MissionHudStrip` were null; reordered for robustness. |
| `OBJECTIVE_DATA_INTERNAL_STRINGS` | Partial | `MissionHudDataProvider.sanitize_objective_line` now drops obvious internal paths (`uid://`, `res://`, `::()` patterns). |
| `HUD_BEHIND_DEBUG_LAYER` | Conditional | Only if a debug CanvasLayer is visible; scripts default-hide Phase0J / F10 panel / F11 overlay. |
| `UNKNOWN_RUNTIME_LIMITATION` | Yes | GRB offline — no live tree proof in this session. |

## Smallest safe fix

1. **HUD.gd**: Always compute `payload` and refresh **objective** before requiring `MissionHudStrip`; add `_player_facing_objective_line`.
2. **MissionHudDataProvider.gd**: Harden `sanitize_objective_line` against internal-looking strings.
3. **hud.tscn**: `layer = 50`; explicit `anchor_left = 0.0` on objective band.
4. **PlayerSprintDebugOverlay.gd**: `layer = 110` (debug tier, **below pause 120**).

## Assertions

See `phase0md5_02b_fix1_root_cause_decision.json`.
