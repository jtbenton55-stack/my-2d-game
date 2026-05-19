# REPO CLEANUP STATIC MANIFEST REPORT

OpenCode completed the static-only cleanup planning side. No cleanup was performed.

## Files Added

- `docs/reports/repo_cleanup_static_manifest/REPO_CLEANUP_STATIC_MANIFEST.md`
- `docs/reports/repo_cleanup_static_manifest/CURSOR_GODOT_VALIDATION_PROMPT.md`
- `docs/reports/repo_cleanup_static_manifest/cleanup_candidates.csv`
- `reports/ai/REPO_CLEANUP_STATIC_MANIFEST_REPORT.md`

## What This Pass Did

- Rechecked the dirty worktree before writing.
- Reviewed Cursor's `repo_audit_01` outputs.
- Verified Cursor's active-system classification is broadly credible.
- Added missing cleanup categories that need explicit validation before cleanup.
- Wrote a Cursor prompt for Godot MCP Pro/runtime validation.

## Main Findings

- Cursor's active gameplay spine classification is credible and should remain protected.
- Cursor's repo audit inventory is curated, not complete: it has `47` entries versus roughly `9,646` repo-visible tracked/untracked files from git at this pass.
- Duplicate generated GdUnit reports under `reports/report_1/`, `reports/report_2/`, and `reports/report_3/` are low-risk cleanup candidates after preserving the latest result summary.
- MCP bisection GameState shim/stub files are likely tooling artifacts, but Cursor should validate active MCP/GRB/DAP needs before quarantine.
- `scenes/testing/McpRuntimeBlankTest.tscn` appears to be a useful MCP runtime harness and should not be deleted without a tooling decision.
- Backup scenes in active folders should move only after Godot editor/runtime confirms no references.
- `AuthoredCollectiblePickup.gd` remains a plausible later quarantine candidate, but stale validators still reference it.
- Taco scene variants are high-risk and should stay untouched until Cursor validates bake/test/runtime references.

## Recommended Split

OpenCode should continue to own static docs/manifest/ref-scan work.

Cursor should own Godot runtime validation using MCP Pro/GRB/DAP/GdUnit where available. Cursor should not perform cleanup in the validation pass; it should only report candidate verdicts.

## Validation Not Run

- Godot editor/runtime checks were not run by OpenCode.
- GdUnit was not run by OpenCode in this pass.
- Nowledge Mem was unavailable earlier in this session because the `nmem` CLI was not found in this shell.
