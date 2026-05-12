# Phase 1 — Stamina bar static audit

## Scene / script wiring

| # | Question | Result |
| --- | --- | --- |
| 1 | `SprintStaminaBar` in `hud.tscn`? | Yes, under `MissionHudStrip`. |
| 2 | Exact path | `MissionHudStrip/SprintStaminaBar` |
| 3 | `HUD.gd` path | Same (`@onready` `MissionHudStrip/SprintStaminaBar`) |
| 4 | Default visible | Yes in `.tscn`; runtime hidden when `stamina_visible` false |
| 5 | Parent hidden | `MissionHudStrip.visible` toggled with `GameState.is_in_mission` |
| 6 | Size | Was `custom_minimum_size` height 10; **FIX2** sets **160×12** + fill/bg styles |
| 7 | Contrast | **FIX2** adds `StyleBoxFlat` fill/background on bar |
| 8 | Hidden when data missing | **Yes** — `HUD.gd` hid bar when `payload.stamina_visible` false |
| 9 | `stamina_visible` false cause | Provider required `dbg.ok`; see root cause |
| 10 | Player lookup | `get_first_node_in_group("player")` — OK when player in group |
| 11 | `get_sprint_runtime_debug` read | Called; keys `current_stamina` / `max_stamina` present in merged dict |
| 12 | Key mismatch | **`ok` missing** after dict replace in `Player.get_sprint_runtime_debug` |
| 13 | HUD value/max | Set from payload when visible |
| 14 | Hidden during Taco | **Yes**, due to false `stamina_visible` |

## Root cause (primary)

`MissionHudDataProvider` gated on `bool(dbg.get("ok", false))`. `Player.get_sprint_runtime_debug()` assigns `d = _stamina_controller.get_sprint_signal_chain_debug()`, which **does not include** `ok`, so the gate never opened.

## Assertions

See `phase0md5_02b_fix2_stamina_static_audit.json`.
