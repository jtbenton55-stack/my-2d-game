# D6-08A Security Authorables — AI Handoff

**Status:** PASS (foundation)  
**Date:** 2026-05-18

## What was done

- Audited Taco `SecurityAuthoringRoot` vs `MarkerRoot` / Phase0K helpers
- Wrote taxonomy (READY / NEEDS BRIDGE / AUDIT ONLY / OBSOLETE)
- Added 7 security authoring templates under `scenes/missions_iso/security_authoring_templates/`
- Added `docs/SECURITY_AUTHORABLES_GUIDE.md` + cross-link from collectible guide
- Added static validator `phase0md6_08a_security_authorable_validator.py`
- Did **not** rewrite guard/camera/beam/alarm systems or modify Taco scene

## Taxonomy (short)

| READY | NEEDS BRIDGE | AUDIT ONLY | OBSOLETE |
|-------|--------------|------------|----------|
| beam, ambush beam, camera, guard spawn, patrol route, waypoint, area trigger | effects graph, alarm group, idle guard | door/keypad | marker-only security |

## Templates

Foundation + existing runtime on Taco. Placeholders: `CHANGE_ME_*`. Not for other missions until setup is generalized.

## Validator

```powershell
python src/tools/editor/d6_08a_security_authorables/phase0md6_08a_security_authorable_validator.py
```

## Kimi

Architecture review: agreed validator-first; deferred idle guard/alarm/door templates.

## Validation

- Validator: PASS
- MCP: Taco play OK; SecurityAuthoringRoot authors detected at runtime
- LSP: no new D6-08A parse errors
- GdUnit4: not run (no new tests)

## Next

D6-08B guard+patrol → 08C camera/beam → 08D ambush/alarm → 08E doors.

Full report: `docs/reports/d6_08a_security_authorables/D6_08A_SECURITY_AUTHORABLES_REPORT.md`
