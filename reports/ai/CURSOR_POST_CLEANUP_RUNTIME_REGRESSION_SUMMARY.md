# CURSOR Post-Cleanup Runtime Regression Summary

**Date:** 2026-05-19  
**Branch:** `cleanup/repo-organization-2026-05-19` (matched expected)  
**Verdict:** **PASS_WITH_KNOWN_PREEXISTING_ISSUES**

## Bottom line

OpenCode’s repo-organization cleanup (removed duplicate GdUnit report folders, moved backup scenes to archive paths, docs/readme consolidation) **did not break** the core flows tested: project autoloads, MainMenu, HideoutHub, and playable Taco RedesignTest.

**No cleanup-caused regressions were found.** No fixes were applied.

## What passed

- Branch and baseline checks (GameState autoload, Taco resolver → RedesignTest)
- Godot MCP Pro: MainMenu UI + New Game → HideoutHub transition
- HideoutHub runtime: managers, stations (mission board, evidence, glow shelf, etc.), player
- Taco runtime: `GameplayRoot`, `SecurityAuthoringRoot`, `RuntimeSystems`, `GeneratedRuntimeInteractables`, completion controller, Louis exit
- No active references to deleted `reports/report_1`–`report_4` or moved backup scene paths
- Validators: D6-07, D6-07B, D6-08A **PASS**
- GdUnit `tests/d6_06/`: **4/4 PASS** → new `reports/report_6/`
- Godot DAP ping OK; LSP scan OK (67 files)

## Known issues (not cleanup-caused)

- **D6-06B validator FAIL** (unchanged): `Taco scene missing proof node D6_06_CaseCash_LegacyAlias_Author` — scene/validator drift, documented before cleanup
- Routine GDScript warnings in editor log (shadowed identifiers, unused params, etc.)
- D6-07 warn about `project.godot` touch time (investigate separately; not attributed to cleanup)

## Not fully tested

- End-to-end MainMenu → Hideout → Taco → return
- Player movement, F10, collectible interact/commit via MCP
- Mission board UI open and Taco launch from hideout

## Kimi K2.6

Used once (`regression_risk_review`) with sanitized context. Reinforced reference-integrity and Taco smoke priorities. Advisory only; no secrets sent.

## Reports

- Full: `docs/reports/repo_cleanup_static_manifest/CURSOR_POST_CLEANUP_RUNTIME_REGRESSION_REPORT.md`
- This summary: `reports/ai/CURSOR_POST_CLEANUP_RUNTIME_REGRESSION_SUMMARY.md`

## Recommended next step

Cleanup is **safe to continue** for low-risk organizational work. Do **not** block on D6-06B validator failure for cleanup merge — treat it as a separate gameplay/validator follow-up. Optional Jake manual playtest for mission-board → Taco launch and hideout sync.
