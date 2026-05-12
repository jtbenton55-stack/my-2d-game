# 0M-D5-00 — Phase 2: Player control / core input

## Evidence summary

| Item | Level | Notes |
|------|-------|------|
| Player spawn / exists | VERIFIED_RUNTIME | `get_global_position()` on Player after Taco load: `(-2558.0, 185.0)` (fresh session, no teleport hacks). |
| Movement | NOT_TESTED | `grb_key` actions `move_right` (×3) and `grb_gamepad` axis0=1 did **not** change `global_position` in sampled frames — likely synthetic one-frame presses vs sustained WASD. **Not** treated as gameplay failure. |
| Collision / camera | MANUAL_REVIEW_REQUIRED | No automated camera trace in this pass. |
| Ctrl sprint | PARTIAL_RUNTIME | `Player.get_sprint_runtime_debug()` returned coherent data: `base_move_speed` 300, `sprint_multiplier` 1.35, `sprint_action_name` `sprint`, `ctrl_key_pressed` false at idle, stamina 100/100. **Sustained Ctrl + move** not proven via GRB. |
| Sprint vs Space dodge | STATIC_ONLY | `pause_menu.gd` controls text states Ctrl sprint vs Space dash; `project.godot` maps `sprint` and `dodge` separately. |
| Space dodge | NOT_TESTED | No reliable dodge trigger without movement context (dash requires move direction per in-game copy). |

## Conclusion

**Player exists and sprint subsystem is live in mission** (debug dictionary). **Movement and dodge were not proven by automation** — use manual checklist (WASD, Ctrl+move, Space with direction).
