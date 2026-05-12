# 0M-D5-00 — Phase 5: Counter / attempt reset

## Runtime snapshot (initial Taco load)

From `get_runtime_debug_summary()`:

- `attempt_runtime_state`: alarms 0, poop_bags_used 0, wrong_code 0, etc.
- `garage_beam_armed` true / `garage_beam_triggered` false (aligned with reset attempt dict).

## Where counters live (STATIC_ONLY)

- `IsoMissionBase._attempt_runtime_state` — incremented by alarm/tool paths; duplicated into `get_runtime_debug_summary()`.

## Reset on new attempt / relaunch (STATIC_ONLY)

- `_setup_runtime_systems()` calls `_reset_attempt_runtime_state()` first, then clears runtime buckets and regenerates spawns (`IsoMissionBase.gd`).
- `_setup_runtime_systems` is invoked from layout/marker generation path (`_regenerate…` flow) and from **`reset_mission_runtime_for_new_attempt()`** (documented entry).
- **Full scene reload** for a new Taco run **re-runs** mission `_ready` / generation pipeline → **expect fresh** `_attempt_runtime_state` for a new scene instance.

## `MissionObjectiveBridge.reset_runtime_objectives_for_mission`

- Still a **no-op** (`pass`) — **STATIC_ONLY**.
- **Runtime bug from stub:** **not demonstrated** this pass; `QuestManager` display may desync from mission gating on edge retries — **MANUAL_REVIEW_REQUIRED** (die/retry without full scene reload if such path exists).

## GRB retry / relaunch

- **NOT_TESTED** end-to-end (would require completing/failing mission then re-entering Taco within one session with error-free GRB).

## D5-01 need assessment

- **Demote P0 “broken reset” claim:** attempt-local dict reset is clearly implemented for runtime systems on regeneration / `reset_mission_runtime_for_new_attempt`.
- **Keep D5-01** as **optional architecture / Quest alignment** if manual play finds **in-mission retry** without scene reload leaks objectives — **not proven here**.
