# Hideout heat display audit

## Taco pause

- Uses **`GameState.get_mission_heat`** / **`MissionPauseDataProvider`** (runtime truth).

## HideoutHub / mission board

- **`HideoutStateController`** maintains scaffold **`heat_state`**, **`taco_bell_heat`**, and mission status **`heat_state`** only when **`taco_bell_completed`** (see `get_mission_status`: fresh missions return **empty** heat string).
- **`HideoutMissionBoardController`** demo status can show placeholder **`heat_state`** from stub data — **not** wired to **`GameState.get_mission_heat("taco_bell_drop")`** during active development runs.

## Conclusion

- **Display sync mismatch** between narrative hideout scaffold and **`GameState`** mission heat.
- **No HideoutHub scene edit this pass** (per non-goals); future pass: read **`GameState`** into board copy when available.

See `phase0md6_01_fix4_hideout_heat_audit.json`.
