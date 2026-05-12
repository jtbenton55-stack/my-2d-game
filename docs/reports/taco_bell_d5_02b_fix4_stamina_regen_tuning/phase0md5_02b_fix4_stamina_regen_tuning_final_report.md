# 0M-D5-02B-FIX4 — Stamina regen tuning final report

## Summary

**Regen:** `regen_rate_per_sec = 100.0 / 15.0` (~**15 s** for 0→full at `max_stamina` 100). **Drain:** `drain_rate_per_sec = 50.0` (~**2 s** full bar while sprinting at max 100). Earlier FIX4 iterations documented in changelog/history.

## Kimi

**Not used** — single-parameter tuning; no multi-file ambiguity.

## Files modified (gameplay)

- `src/player/PlayerStaminaController.gd`

## Manual checklist

See user brief items 1–22 (also embedded in `phase0md5_02b_fix4_stamina_regen_tuning_final_report.json`).
