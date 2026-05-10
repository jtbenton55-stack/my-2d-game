# 0M-D1B-RT2 — Pause / objectives UI (Phase 6)

## Runtime attempt

`grb_call_method` on `/root/TacoBellIso_Editable/PauseMenu` with `_pause_game()` (sets `get_tree().paused = true`).

## Outcome

The next MCP call (`grb_get_property`) **timed out** and the bridge reported **not connected** — pausing the scene tree appears incompatible with this GRB automation session.

## Static fallback

`src/ui/test_ui/pause_menu.gd` programmatically adds **Objectives**, **Scheme Cards**, and **Clues** buttons and routes them to `_toggle_info_panel`.

## Recommendation

For automated GRB runs, avoid full-tree pause unless a **resume** path is invoked immediately via `call_deferred`, or use an input mode / mission pause implementation that does not freeze GRB servicing.
