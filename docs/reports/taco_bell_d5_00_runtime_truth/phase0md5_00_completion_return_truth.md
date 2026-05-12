# 0M-D5-00 — Phase 8: Completion / failure / return

## GRB automation

- **NOT_TESTED** for full win/lose → `MissionResult` → Hideout within this pass (time + input complexity; GRB instability after pause test).

## Static / design references (STATIC_ONLY)

- `pause_menu.gd` `exit_button` → `SceneManager.return_to_hideout()`.
- `IsoMissionBase` documents normal completion/failure using **SceneManager scene reload** in comment near `reset_mission_runtime_for_new_attempt` (read during counter phase).

## Save / errors

- Hideout transition produced **11** engine errors (tileset / image / deferred add_child) — **observed at runtime** in `grb_get_errors`; unclear if user-visible; log for follow-up.

## Conclusion

Treat **completion loop** as **MANUAL_REVIEW_REQUIRED** (finish Taco, confirm result UI, confirm Hideout + MissionBoard state).
