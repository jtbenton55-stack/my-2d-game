# 0M-D5-02B-FIX4 — Stamina tuning fix

## Change

In `PlayerStaminaController.gd`:

- `drain_rate_per_sec`: **50.0** (~**2 s** full sprint from 100→0 at default max).
- `regen_rate_per_sec`: **`100.0 / 15.0`** (~**15 s** 0→full at default max).

## Preserved

- `drain_rate_per_sec` (35.0), sprint multiplier, exhaustion threshold, `process_frame` logic, `minf` regen clamp.
- No regen-delay feature added (none existed; brief stays 0 s).

## Assertions

| Assertion | Value |
|-----------|--------|
| stamina_regen_rate_slowed | true |
| sprint_drain_preserved | true |
| ctrl_release_regen_preserved | true |
| no_input_binding_changes | true |
| no_duplicate_stamina_logic_added | true |
