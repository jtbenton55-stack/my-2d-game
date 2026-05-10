# 0M-D2A-FIX1 — Runtime forensic audit

## Root causes

1. **`sprint` included Space** while **`dodge` also uses Space** — sustained stamina sprint could not be separated cleanly from dash/dodge, and `legacy_dodge_burst` / dash suppression interacted badly with player expectations.
2. **Ctrl via `Input.is_action_pressed("sprint")` alone** is unreliable on some stacks when Ctrl is the only `InputEventKey` binding; **physical key read** is required as a fallback.
3. **Multiplier gate** used `wants_sprint` instead of **`is_sprint_active()`** after `process_frame`, which could desync display intent from actual internal sprint state in edge cases.

## Velocity path

`move_speed` is scaled once, then `velocity = input_vector * move_speed` (or dash/dodge override). `DashAbility` still overrides during dash.

See `phase0md2a_fix1_runtime_forensic_audit.json`.
