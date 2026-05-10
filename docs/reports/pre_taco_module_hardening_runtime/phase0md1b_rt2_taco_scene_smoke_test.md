# 0M-D1B-RT2 — Taco Bell runtime smoke (Phase 5)

## Scene load

`grb_runtime_info.current_scene` reported **`res://scenes/missions_iso/TacoBellIso_Editable.tscn`** with root name `TacoBellIso_Editable`.

## Player

`grb_find_nodes` located `CharacterBody2D` **Player** at `/root/TacoBellIso_Editable/EntityRoot/Player` (plus `PlayerVisual_Parmida`, `PlayerCombatController`).

## Movement / collision / camera

**Not verified in motion:** `global_position` stayed `(-2558, 185)` after `grb_key` (`move_right`) and `grb_gamepad` axis injection; `velocity` remained `(0, 0)`. Likely **GRB synthetic input isolation** or lack of sustained `Input.get_action_strength` in this automation mode.

## Engine output

`grb_get_errors` during the session showed **11** errors dominated by **TileSet** / **empty Image** while **HideoutHub** was loading — not traced to new D1B GD modules. One **warning** referenced an **invalid UID** on a Taco scene `ext_resource` with text-path fallback.
