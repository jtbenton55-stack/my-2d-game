# 0M-D6-01-FIX2 — Final report

## Verdict: **PARTIAL**

Root causes were identified and patched in code. **Godot runtime bridge was not connected** (`grb_ping`: launch game first), so this pass does **not** claim full PASS on acceptance criteria.

## Root causes

1. **Cameras / no spawn:** `MissionSecurityCamera` **else** branch called `MissionAlertController.decay_exposure` every frame per camera → **N× decay** on shared `alert_score` → threshold rarely reached → no `record_alarm_event` → no guard spawn.
2. **Wrong-code:** `Phase0KBWrongCodeAttackGuardSpawner` ignored **`get_wrong_code_alarm_threshold()`**; heat could require **1** attempt while KB still waited for **2**. Missing **`wrong_code_alarm`** adapter event at threshold.
3. **Beam F10:** Insufficient structured tester guidance.

## Repairs

- `MissionSecurityCamera.gd` — remove shared `decay_exposure` from per-camera loop; comment explains regression.
- `Phase0KBWrongCodeAttackGuardSpawner.gd` — heat-synced threshold; `_report_wrong_code_alarm_event`; `_last_effective_wrong_threshold` for result HUD.
- `IsoMissionBase.gd` — `beam_alarm_id`, `beam_runtime_node_path`, `beam_f10_how_to_test` in runtime debug summary.
- `IsoMissionDebugPanel.gd` — beam block + security policy line.

## Manual test checklist (condensed)

1. Launch project → HideoutHub → MissionBoard → Taco **RedesignTest**.
2. HUD: objective ticker, stamina, poop, Ctrl sprint, Space dash, F1/F10/F11, Esc pause + heat line scroll.
3. F10: security block shows **beam** section (node path, id, armed/triggered, how_to_test).
4. Enter **multiple** CAM cones; hold until alert; confirm **guard spawn** and **camera_detection** counter moves; stay in cone → second spawn after cooldown; no per-frame spam.
5. Garage code UI: wrong code until threshold; **wrong_code** / **wrong_code_alarm** in F10; guard spawns.
6. Walk **garage_entry_beam** zone once; **beam_trip** increments once.
7. Mid-run: persistent heat should **not** increase from these events alone; fail mission → heat +1 still (unchanged code path).
8. Output: watch for new errors.
