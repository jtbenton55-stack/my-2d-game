# Regression root-cause audit (FIX2)

## Cameras / guards

`MissionSecurityCamera` accumulated exposure into `MissionAlertController.accumulate_exposure` while the player was inside the cone, but **each** camera in the `else` branch called `decay_exposure` on the **shared** `alert_score` every physics frame. With multiple spawned cameras this dominated the signal and prevented `alert_score >= 1.0` → no `record_alarm_event` → no `spawn_attack_guard_near_player`.

## Wrong-code

`Phase0KBWrongCodeAttackGuardSpawner` ignored `IsoMissionBase.get_wrong_code_alarm_threshold()` (heat-driven). At heat that sets threshold **1**, the spawner still required **2** KB-local attempts before dispatch, mismatching design and feeling like a no-op on first failure.

## F10 / beam

Runtime summary lacked structured beam fields; testers could not see node path + how-to-test in one place.
