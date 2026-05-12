# 0M-D5-02B-FIX2 — Stamina bar final report

## Verdict: **PARTIAL**

Static root cause fixed and validator passes; **GRB offline** — no live proof of drain/regen in this session.

## Root cause

`MissionHudDataProvider` required `get_sprint_runtime_debug()["ok"]`. `Player.get_sprint_runtime_debug()` replaces the dict with `_stamina_controller.get_sprint_signal_chain_debug()` which **does not** include `ok`, so `stamina_visible` was always **false** and `HUD.gd` hid the bar.

## Fix

- Provider: accept **`current_stamina` + `max_stamina`** (or legacy `ok`); in-mission **100/100** placeholder + `stamina_fallback`.
- HUD: tooltip when fallback.
- Scene: **StyleBoxFlat** fill/bg + **160×12** min size.

## Files modified (this pass)

`src/missions/ui/MissionHudDataProvider.gd`, `src/ui/HUD.gd`, `scenes/ui/hud.tscn`, `docs/CHANGELOG.md`

## Protected files

No `Player.gd`, `PlayerStaminaController.gd`, `project.godot`, Taco scenes.

## Validation

- Runtime: PARTIAL (bridge not connected).
- Static: see `phase0md5_02b_fix2_static_validator_run.json`.

## Manual checklist

See mission prompt **AE** (19 steps).

JSON: `phase0md5_02b_fix2_stamina_bar_final_report.json`.
