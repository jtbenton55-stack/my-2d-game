# 0M-D5-02B-FIX3 — Stamina regen forensic audit

## 1. Where stamina drains

`PlayerStaminaController.process_frame`: when `_sprinting` is true, `current_stamina -= drain_rate_per_sec * delta` clamped with `maxf(0.0, ...)`.

`_sprinting` is set to `wants_sprint and can_sprint() and is_moving`.

## 2. Where stamina regenerates

Same `process_frame` else branch: `current_stamina = minf(max_stamina, current_stamina + regen_rate_per_sec * delta)` (post-fix; previously `mini(...)`).

## 3. Regeneration code existed?

Yes — but the clamp used **`mini()`** (integer min) on **float** values.

## 4. Regen depends on not moving?

No — regen runs whenever `_sprinting` is false (includes standing still and walking without sprint).

## 5. Other gates

- `Player.gd` sets `wants_sprint` false when stealth, combat dash, or legacy dodge burst; then `process_frame` still runs with `wants_sprint == false` → regen eligible.
- `_exhausted` does not block regen; it only affects `can_sprint()` for activating sprint.

## 6–8. Player update path

`Player._physics_process` calls `_stamina_controller.process_frame(delta, wants_sprint, input_vector.length() > 0.01)` every frame when `can_control` and controller non-null (not skipped when not sprinting), except early returns for stun / `not can_control`.

## 9–10. Sprint request / active after Ctrl release

`is_sprint_requested()` clears when Ctrl and sprint action release; `wants_sprint` becomes false → `_sprinting` false → regen branch.

## 11. Exhausted stuck?

No permanent block; sub-threshold stamina disables sprint via `can_sprint()` but regen still runs in else branch.

## 12. Clamp

Drain uses `maxf`; regen must use **`minf`** for float upper clamp.

## 13. `get_sprint_runtime_debug()`

Merges `get_sprint_signal_chain_debug()` (includes `current_stamina`, `max_stamina` from snapshot) + physics fields.

## 14–15. HUD / provider

`HUD._process` refreshes compact strip ~every 0.12s via `MissionHudDataProvider.get_hud_payload()` → live `get_sprint_runtime_debug()` on player. Not stale if `current_stamina` actually changes.

## 16. Display-only bug?

Unlikely while drain visibly works — same read path. Root cause was **controller float regen stalled by `mini()`**.

## Root cause classification

- **STAMINA_CLAMP_OR_THRESHOLD_BAD** (primary): `mini()` on floats truncates; a small per-frame regen increment can round away so stamina never climbs.
- ~~REGEN_NOT_IMPLEMENTED~~, ~~PROCESS_FRAME_SKIPPED_WHEN_NOT_SPRINTING~~, ~~EXHAUSTED_STATE_STUCK~~ — not supported by code review.

## Assertions

| Assertion | Value |
|-----------|--------|
| stamina_regen_code_audited | true |
| player_stamina_update_path_audited | true |
| hud_provider_read_path_audited | true |
| likely_regen_root_cause_identified_or_gap_reported | true |
