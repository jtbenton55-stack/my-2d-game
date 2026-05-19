# D6-06D — Collectible Persistence + Mission Completion Hardening

**Date:** 2026-05-17  
**Verdict:** **PASS** (persistence/idempotency/failure guards); HideoutHub **visual** remains **PARTIAL** (flags verified via runtime scripts, not full shelf playthrough)

## Audit summary

### Authored collectible path (D6-06B/C, unchanged collection)

1. **Collect:** `AuthoredPhase0JInteractablePickup` (E via `Phase0JInteractionBridge`) → `record_authored_collectible_attempt()` → `_d6_06_pending_collectibles`.
2. **Success commit:** `commit_authored_collectibles_for_success(reason)` (single boundary) → `_commit_pending_authored_collectibles()` → GameState / adapter / hideout flags; `D6_06_PERSIST.mark_persisted()`.
3. **Failure/restart:** `fail_level()` and attempt reset call `_clear_pending_authored_collectibles()`; resets `_d6_06_authored_commit_applied`; does **not** remove committed `GameState` flags.
4. **In-run duplicate:** Pickup disables interaction/collision after collect (D6-06C).
5. **Cross-run duplicate:** `MissionAuthoredCollectiblePersistence.is_already_persisted()` skips commit; hideout `mark_hideout_display_found` is idempotent.

### Mission completion paths

| Path | When | Commits collectibles? |
|------|------|------------------------|
| **Formal** `request_exit_completion()` | All `_required_objective_ids` done | Yes, via `commit_authored_collectibles_for_success` |
| **Taco Louis fallback** `apply_phase0k_louis_exit_completion()` | Bag + gate (Phase0K), formal objectives incomplete | Yes, same commit boundary |
| **Denied fallback** | Mission not in allowlist | No; warning + `fallback_denied` |

**Taco-specific:** Only `taco_bell_drop` is in `PHASE0K_LOUIS_EXIT_FALLBACK_MISSION_IDS`. Future missions must not be added without design review.

**Intended for future missions:** Formal `request_exit_completion()` only. Louis fallback is explicit opt-in via allowlist.

## Code changes

| File | Change |
|------|--------|
| `MissionAuthoredCollectiblePersistence.gd` | **New** — `class_name`, persist flag helpers, `is_already_persisted`, `mark_persisted` |
| `IsoMissionBase.gd` | Allowlist, `commit_authored_collectibles_for_success`, `apply_phase0k_louis_exit_completion`, idempotent commit + replay skip |
| `Phase0KMissionCompletionController.gd` | Fallback routes to `apply_phase0k_louis_exit_completion` (no direct `_commit_pending_*`) |
| `MissionCollectibleHideoutSync.gd` | Idempotent `mark_hideout_display_found` |
| `phase0md6_06b_static_validator.py` | D6-06D guard checks |
| `tests/d6_06/MissionAuthoredCollectiblePersistenceTest.gd` | **New** — 3 GdUnit4 smoke tests |

**Protected files:** untouched (`project.godot`, `Player.gd`, `player.tscn`).

## Persistence / idempotency validation

| Check | Method | Result |
|-------|--------|--------|
| Single commit on success | MCP `commit_authored_collectibles_for_success` ×2 | 1st `committed:1`; 2nd `already_applied:true`, poop 0→1 once |
| Replay skip | MCP `_commit_pending` after `mark_persisted` | `already_persisted:1`, `committed:0` |
| Failure no-commit | MCP `fail_level` after pending | pending cleared; `d6_06_authored_committed:*` **not** set |
| Taco allowlist | MCP runtime | `fallback_allowed=true` for `taco_bell_drop` |
| Hideout flag on commit | MCP | `hideout_display:poop_bag_fire_sauce_roll=true` after poop commit |

## Failure / restart

- `fail_level` → `_clear_pending_authored_collectibles("mission_failed")` — verified no persist flag for failed pending ID.
- Committed flags from earlier success in same session are not rolled back (by design).

## Hideout validation

- **Verified (runtime):** `hideout_display:*` dialogue flags set on commit; `MissionCollectibleHideoutSync` no-op when flag already true.
- **Not verified this pass:** Full HideoutHub scene load/shelf visuals after mission return (manual checklist still recommended).

## Godot MCP Pro

- Opened / played `TacoBellIso_Editable_RedesignTest.tscn`
- Runtime scripts: commit idempotency, fail no-commit, replay skip, allowlist check
- Screenshot captured in-session (Taco iso test room with player + poop bag marker)
- Louis `find_best_candidate` at (800,848) returned none in this MCP session (player not at exit); D6-06C manual pass still authoritative for Louis focus

## Godot LSP diagnostics

- `scan_workspace_diagnostics`: 0 issues (editor scan at report time)

## GdUnit4

```
addons/gdUnit4/runtest.cmd --godot_binary <Godot 4.6.2> -a res://tests/d6_06/
→ 3/3 PASSED (MissionAuthoredCollectiblePersistenceTest)
```

## DAP

Not required; commit/fail state confirmed via MCP `execute_game_script`.

## Static validator

```
python src/tools/editor/d6_06b_interactable_collectible_hideout_sync/phase0md6_06b_static_validator.py
→ PASS
```

## Kimi K2.6 (advisory)

- **Mode:** `regression_risk_review`
- **Adopted:** Treat `commit_authored_collectibles_for_success` as sole boundary; allowlist for Taco fallback; persist checks must read `GameState` dialogue flags (implemented).
- **Rejected / already covered:** Extra `_has_committed` variable (duplicate of `_d6_06_authored_commit_applied`).
- **Noted:** Risk if `fail_level` runs after commit in same instance — mitigated by `is_complete` / `_mission_completing` guards on exit paths.
- No secrets sent to Kimi.

## Known limitations

- Full player-driven playthrough (4 proof items + bag + Louis + HideoutHub visual) not repeated in this MCP pass; relies on D6-06C manual PASS + targeted MCP hooks.
- Money proof uses separate `d6_06_money:*` flags; not re-tested end-to-end here.
- `find_best_candidate` at exit not reconfirmed at Louis coordinates in D6-06D MCP session.

## Manual retest checklist

1. Play Taco iso mission; collect 4 authored proof items + bag; open gate; talk to Louis.
2. Complete mission; confirm HideoutHub shows at least one display (poop/polaroid/tiny).
3. Replay mission; confirm proof items do not duplicate counters/flags.
4. Fail/restart mid-mission with pending pickups; confirm hideout unchanged.

## Related

- [D6-06C Louis exit report](./D6_06C_LOUIS_EXIT_REGRESSION_REPORT.md)
- [D6-06B interactable collectibles](./D6_06B_INTERACTABLE_COLLECTIBLE_HIDEOUT_SYNC_REPORT.md) (if present)
