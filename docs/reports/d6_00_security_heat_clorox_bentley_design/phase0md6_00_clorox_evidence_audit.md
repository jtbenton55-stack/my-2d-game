# 0M-D6-00 — Clorox / cleanup / evidence audit

## Clorox / wipe gameplay

| Area | Status |
|------|--------|
| **Clean Job mission** | `CleanJobMission.gd` — **implemented** evidence wipe zone, fingerprint reveal, optional wipe objective; **checks** `GameState.has_selected_card("clorox_wipe_protocol")` for bonus reveal behavior. |
| **Card hook** | `CardEffects.has_clorox_protocol()` — reads selected scheme card id `clorox_wipe_protocol`. |
| **Iso Taco** | No dedicated Clorox wipe interactable surfaced in this audit search under `src/missions/iso/**`; **Taco MVP does not yet carry CleanJob-style wiping**. |

## Evidence / traces (general)

- **Evidence board / clues:** `HideoutEvidenceBoardController`, `GameState.evidence_clues` / `sterling_clues`, `MissionHudDataProvider` sanitization — **meta progression**, not per-mission smear objects.
- **Iso typed collectibles** — `evidence_clue` category via `Phase0JMissionStateAdapter` / `TypedMissionCollectible`.
- **Poop bags** — tool + performance counters (`poop_bags_collected`); **no automatic “trace entity”** found in iso audit beyond gameplay narrative.

## Heat reduction via cleanup

- **No repo proof** in iso stack that wiping reduces `failed_attempts` / `get_mission_heat` — CleanJob grants intel / objective text, not GameState heat decrement.
- **Clean Getaway** — `HideoutMissionBoardController` exposes `clean_getaway_attempt` action; `HideoutManager` routes placeholder feedback — **hideout-level scaffold**, not iso runtime mechanic.

## Clean Getaway / perfect moment

- `GameState._finalize_mission_performance` sets `perfect_moment_earned` when **success** and **alarms_triggered==0** and **wrong_scent_trails_followed==0** — **performance-based**, orthogonal to Clorox today.

## Assertions

| Assertion | Value |
|-----------|--------|
| clorox_evidence_audit_completed | true |
| existing_cleanup_system_identified_or_missing_reported | true |
