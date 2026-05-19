# D6-06D — Persistence + Completion Hardening (AI handoff)

**Verdict:** **PASS** (code + MCP hooks + GdUnit4); HideoutHub visual **PARTIAL**

## What changed

- Single commit API: `IsoMissionBase.commit_authored_collectibles_for_success()`
- Taco-only Louis fallback: `PHASE0K_LOUIS_EXIT_FALLBACK_MISSION_IDS = ["taco_bell_drop"]` + `apply_phase0k_louis_exit_completion()`
- Persistence helper: `MissionAuthoredCollectiblePersistence` (`class_name` + preload in tests)
- Replay guard: `is_already_persisted()` before commit; idempotent hideout flags
- Tests: `tests/d6_06/MissionAuthoredCollectiblePersistenceTest.gd` (3 passed)

## Files touched

- `src/missions/iso/runtime/MissionAuthoredCollectiblePersistence.gd` (new)
- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/Phase0KMissionCompletionController.gd`
- `src/missions/iso/runtime/MissionCollectibleHideoutSync.gd`
- `src/tools/editor/d6_06b_interactable_collectible_hideout_sync/phase0md6_06b_static_validator.py`
- `tests/d6_06/MissionAuthoredCollectiblePersistenceTest.gd` (new)

## Validation snapshot

| Tool | Result |
|------|--------|
| Static validator | PASS |
| GdUnit4 `tests/d6_06/` | 3/3 PASS |
| MCP commit ×2 | `already_applied` on 2nd call |
| MCP fail_level | pending cleared, no persist flag |
| MCP replay skip | `already_persisted:1` |
| Kimi | Advisory regression review; no blockers |

## Next step

- **D6-07:** broader interactable authoring (if PASS accepted)
- Optional: one manual HideoutHub visual pass after Taco complete

Full report: `docs/reports/d6_06b_interactable_collectible_hideout_sync/D6_06D_PERSISTENCE_COMPLETION_HARDENING_REPORT.md`
