# Phase 4 — HUD fix implemented

## Code changes (this pass)

| Area | Change |
| --- | --- |
| `src/ui/HUD.gd` | `_refresh_mission_compact_hud` computes `payload` first; updates objective when `in_mission`; only then requires `MissionHudStrip` for stamina/poop; `_player_facing_objective_line`; poop label explicit hide when not showing bags |
| `scenes/ui/hud.tscn` | HUD `layer = 50`; `ObjectiveLabel` `anchor_left = 0.0` |
| `src/missions/ui/MissionHudDataProvider.gd` | `sanitize_objective_line` rejects internal-ish strings |
| `src/player/PlayerSprintDebugOverlay.gd` | F11 overlay `layer = 110` (below pause `120`) |
| `docs/CHANGELOG.md` | FIX1 summary |

## Non-goals honored

- No second HUD system, no Taco scene edits in this pass, no `project.godot`, no `Player.gd` / `PlayerStaminaController.gd`.

## Assertions

See `phase0md5_02b_fix1_hud_fix.json`.
