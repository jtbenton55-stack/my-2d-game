# FIX6 Final Report

Status: PARTIAL. Root cause: live security guards were placed through the shared spawn path, then fallback patrol assignment called Guard.assign_patrol_path(), which snaps global_position to the first patrol point. That produced requested/chosen/actual divergence and far-left/offscreen guards. FIX6 now chooses player-near positions, sets final global_position after add_child and after patrol setup, rejects far/offscreen guards from functional cap, and shows source/mode/requested/chosen/actual/result/reason/distance in F10. Runtime probe confirmed camera and wrong-code live spawn entry points choose and keep actual (-2338,185), 220 px from player, invalid 0. Red beam is runtime-created under visible RuntimeSystems and tagged D6_FIX6_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS. Kimi bridge preflight returned Kimi bridge OK; advisory was used but not treated as authoritative. Runtime validation is headless only, so manual camera cone, wrong-code UI entry, visual beam, F10 scroll, F1/F11/pause, and guard feel remain to be confirmed manually.

Manual checklist: launch project; reach HideoutHub; launch Taco; confirm player/Bentley/HUD; test Ctrl sprint, Space dash, F1/F10/F11/pause; stand in camera cone; verify visible reachable guard and F10 chosen=actual; repeat after cooldown; enter wrong garage code to alarm; verify visible reachable guard; verify purple warp absent; find red beam before bag room; walk through beam and watch beam_trip or armed/triggered status; confirm mid-run events do not directly increase persistent heat; check Output for new errors.

## Assertions
- ASSERT final_report_created == true
- ASSERT protected_file_safety_confirmed == true
- ASSERT runtime_validation_status_recorded == true
