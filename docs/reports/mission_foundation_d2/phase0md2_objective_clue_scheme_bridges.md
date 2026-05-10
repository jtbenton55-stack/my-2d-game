# 0M-D2 — Objective / clue / scheme bridges

- **MissionObjectiveBridge:** `get_bridge_id`, existing `get_objective_snapshot` / publish helpers.
- **MissionClueBridge:** `GameState.sterling_clues` snapshot + safe `mark_clue_collected`.
- **MissionSchemeBridge:** equipped cards snapshot via `CardManager` + `GameState.unlocked_cards`; `has_scheme_effect` by `effect_key`.

All bridges avoid Taco-specific hardcoding in generic logic.

See `phase0md2_objective_clue_scheme_bridges.json`.
