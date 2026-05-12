# 0M-D5-00 — Runtime truth final report

## Verdict: **PARTIAL**

Runtime **was** launched and multiple **GRB** checks succeeded, but several user-listed behaviors were **not** fully exercised under automation (movement, beam crossing, pause UI while tree paused, completion loop). Per instructions, **PARTIAL** — not PASS.

## Runtime tools used

- **GRB** (`project-0-my-2d-game-godot-runtime-bridge`): `grb_launch`, `grb_reset`, `grb_runtime_info`, `grb_scene_tree`, `grb_find_nodes`, `grb_get_property`, `grb_get_errors`, `grb_press_button`, `grb_key`, `grb_gamepad`, `grb_call_method`, `grb_set_property` (tier **2** session).

## What was runtime-tested (high confidence)

- MainMenu → HideoutHub (`NewGameButton`).
- Taco load path → **`res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`** (`grb_runtime_info` + root `scene_file_path`).
- `HideoutMissionBoardController.launch_taco_bell()` (same resolver path as MissionBoard UI).
- Player + DogCompanion existence; initial `Player.get_global_position()` sample.
- `Player.get_sprint_runtime_debug()` dictionary (stamina, sprint multiplier, action wiring).
- `IsoMissionBase.get_runtime_debug_summary()` initial beam flags + attempt counters.
- Hideout `MissionBoard` station UI visibility after `interact` + player teleport near board (tier-2 positioning).

## What was static-only or manual

- Beam **player walk-through** and **re-arm after retry** (code reviewed; not observed end-to-end).
- Pause **tabs content** (GRB stalled when `get_tree().paused` likely true after `ui_cancel`).
- Completion / MissionResult / return loop (not run).
- Louis gameplay bypass (router deferred — code).

## Runtime limitations

1. **Synthetic input** did not move Player (`move_right` / gamepad axis) — **do not** infer movement failure.
2. **`grb_set_property` on Player `global_position`** caused unreliable readback in one session — avoid for proof.
3. **Pause (`get_tree().paused = true`)** appears to **break / stall GRB** commands — use manual pause checks or mission-specific unpause hooks for future harnesses.
4. **Tier-2** calls were required for mission/hideout automation beyond tier-1.

## d5_01 (attempt-reset / objective lifecycle)

**Recommendation:** **OPTIONAL / DEFER** as default next implementation pass **unless** manual play confirms **in-scene retry without reload** leaks Quest vs mission gates.

**Reason:** `IsoMissionBase._setup_runtime_systems()` calls `_reset_attempt_runtime_state()` and clears runtime buckets — **fresh Taco scene load** resets attempt counters in live summary. `MissionObjectiveBridge.reset_runtime_objectives_for_mission` remains a **stub**, but **no runtime failure was demonstrated** from that stub this pass.

## Single best next implementation pass

**0M-D5-02-UX — Taco player-facing clarity (HUD + pause readability)**  
Goal: show **current objective**, **stamina**, and **poop bag charges** in mission HUD; verify pause uses **Esc** and objectives remain readable; optionally pin pause snapshot to `taco_bell_drop` if `GameState.current_mission_id` can drift.

## Next three implementation steps

1. **HUD pass** — objective line + stamina bar + poop bag count (mission UI layer, not `Player.gd` if avoidable).
2. **Pause copy / mission_id** — confirm `MissionPauseDataProvider` / `GameState` alignment for Taco; small fix only if reproducible drift.
3. **Louis bypass parity** — implement real `PARITY_IMPLEMENTED` behavior in `Phase0JMechanicRouter` for intended bypass (only after UX readable).

## Things to avoid

- No `IsoMissionBase` wide refactor until UX readable.
- No claiming D5-01 P0 without manual retry leak repro.
- No relying on GRB `pause` action — game uses **`ui_cancel`** for pause menu toggle.

## Files

- **Modified:** none (gameplay).
- **Created:** this report tree + `phase0md5_00_static_validator.py`.

## Protected files

No edits to `project.godot`, `Player.gd`, Taco scenes, `HideoutHub`, assets (see `git status` after report add).

## Static validator

See `phase0md5_00_static_validator_run.json`.

## Evidence level summary

- **VERIFIED_RUNTIME:** Launch chain, Taco scene path, player/dog existence, initial runtime summary, sprint debug snapshot, mission board panel visibility path (with tier-2 assist).
- **PARTIAL_RUNTIME:** Sprint sustained, post-load engine errors count, station approach.
- **STATIC_ONLY:** Beam one-shot code, counter reset wiring, Louis router, poop tool code path, pause menu wiring.
- **NOT_TESTED:** Movement, dodge, beam crossing, pause tab text, poop throw, completion loop, in-mission retry leak.
- **MANUAL_REVIEW_REQUIRED:** All NOT_TESTED items + post-pause UI.
