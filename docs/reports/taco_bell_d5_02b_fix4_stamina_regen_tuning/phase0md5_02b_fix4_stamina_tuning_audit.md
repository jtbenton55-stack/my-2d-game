# 0M-D5-02B-FIX4 — Stamina tuning audit

## PlayerStaminaController.gd

| Item | Value |
|------|--------|
| max_stamina | 100.0 |
| drain_rate_per_sec (current) | **50.0** (~2s full sprint burn at max 100) |
| regen_rate_per_sec (before FIX4) | 22.0 |
| regen_rate_per_sec (current) | **100/15** (~6.67/s, ~15s refill at max 100) |
| regen delay | None — instant regen when not sprinting |
| Exported | No — `regen_rate_per_sec` is a plain `var` (tunable in code; name is clear) |
| Regen while standing | Yes — whenever `_sprinting` is false |
| Regen while walking (no Ctrl sprint) | Yes — same branch |
| exhausted_threshold | 0.5 — `can_sprint()` gate; unchanged |
| Clamp | 0..max via `maxf` / `minf` in `process_frame` |

## Player.gd (read-only)

`process_frame(delta, wants_sprint, …)` is invoked each physics frame when `can_control` — no change required for tuning.

## HUD / MissionHudDataProvider (read-only)

Stamina still read from `get_sprint_runtime_debug()` / snapshot — no mutation.

## Tuning target (current)

- **Refill:** ~**15 s** from 0→full at default max 100 → `regen_rate_per_sec = 100.0 / 15.0`.
- **Sprint burn:** ~**2 s** from full→0 while sprinting at default max 100 → `drain_rate_per_sec = 50.0` (= `max_stamina / 2`).

(History: initial FIX4 explored 22 → 12.5 → 8 regen/s before these design targets.)

## Kimi

**Not needed** — single-variable change; no conflicting multi-file logic.

## Assertions

| Assertion | Value |
|-----------|--------|
| current_regen_rate_identified | true |
| max_stamina_identified | true |
| tuning_target_selected | true |
| kimi_needed_decision_recorded | true |
