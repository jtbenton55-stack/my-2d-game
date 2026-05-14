# Wrong-code runtime audit

**UI:** `Phase0JCodeInputUI.submit_code` → `Phase0JCodeGateController.register_wrong_code_attempt` → `Phase0KBWrongCodeAttackGuardSpawner.register_wrong_code_attempt`.

**Counters:** `MissionSecurityEventAdapter.report_security_event("wrong_code", …)` from Phase0J and Phase0KB each wrong entry; attempt counters via `MissionCodeGatePlaceholder` path differ — garage flow is Phase0J.

**FIX2:** KB threshold aligned with `IsoMissionBase.get_wrong_code_alarm_threshold()`; `wrong_code_alarm` reported when threshold reached.
