# 0M-D5-02B-FIX1 — HUD visibility final report

## Verdict: **PARTIAL**

Runtime bridge unavailable (`grb_ping` not connected). Static wiring review + code fixes completed; **full PASS requires local/GRB playtest**.

## Branch

`c2a-full-character-animation-20260509-172230`

## Files modified (this pass)

- `src/ui/HUD.gd`
- `scenes/ui/hud.tscn`
- `src/missions/ui/MissionHudDataProvider.gd`
- `src/player/PlayerSprintDebugOverlay.gd`
- `docs/CHANGELOG.md`

## Files created

See `phase0md5_02b_fix1_hud_visibility_final_report.json` → `files_created_this_pass`.

## HUD presence / visibility (evidence)

- **Before fix (static):** Taco RedesignTest embeds `hud.tscn` under mission root (known from repo structure).
- **Before/after visibility (runtime):** **Unknown** here — GRB offline.

## Root cause classification

See JSON `root_cause_classification`.

## CanvasLayer findings (Godot truth)

**Higher `CanvasLayer.layer` draws above lower layers.** Player HUD is **`50`** (within the 40–80 player-facing band). Debug surfaces are **`90` / `100` / `110`**, pause **`120`**. If debug layers are visible, they can cover HUD — default scripts keep them hidden.

## Fix implemented (summary)

1. **`HUD._refresh_mission_compact_hud`**: compute `payload` first; refresh objective when `in_mission`; only then require `MissionHudStrip` for stamina/poop; explicit poop label hide.
2. **`_player_facing_objective_line`**: readable `Objective:` prefix without double-prefix.
3. **`MissionHudDataProvider.sanitize_objective_line`**: reject obvious internal strings (`uid://`, `res://`, `::()` patterns).
4. **`hud.tscn`**: HUD `layer = 50`; `ObjectiveLabel` `anchor_left = 0.0`.
5. **`PlayerSprintDebugOverlay`**: F11 layer **`110`** (was `120`) — **high-caution** touch, justified to keep F11 in debug tier **below pause**.

## Feature status (post-fix, static)

| Item | Status |
| --- | --- |
| Objective ticker | Implemented + bounded + prefix |
| Stamina bar | Existing logic (requires sprint debug `ok`) |
| Poop label | Shown only when `poop_bags_visible` |
| Health overlap | Static geometry suggests low risk |

## Non-regression (static)

- **F10** remains debug-only toggle at layer **100** (above HUD **50** when open — intended).
- **Pause** remains **120** (above F11 **110**).
- **Phase0J** playfield HUD still `_ready` → `hide()` by default.

## Validation

- **Runtime:** PARTIAL (GRB not connected).
- **Static validator:** see `phase0md5_02b_fix1_static_validator_run.json`.

## Protected file safety

No edits to `project.godot`, `Player.gd`, `PlayerStaminaController.gd`, Taco scenes, `HideoutHub.tscn`, `player.tscn`, or `assets/**` **in this pass**.

## Machine-readable

See `phase0md5_02b_fix1_hud_visibility_final_report.json`.
