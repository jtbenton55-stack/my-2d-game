# Repo Organization Guide

This guide documents the intended boundaries for future cleanup and feature work.

## Primary Boundaries

| Area | Purpose |
|---|---|
| `src/` | Runtime and editor-support scripts that belong to the game project. |
| `scenes/` | Active Godot scenes, mission templates, testing harnesses, and editor tool scenes. |
| `data/` | Data files and authored configuration. |
| `docs/` | Stable project documentation and phase reports. |
| `reports/ai/` | AI handoff and summary reports. |
| `reports/report_N/` | Disposable generated GdUnit report output. |
| `reports/godot_ignored_backups/` | Archived Godot rollback scenes/backups, not active runtime content. |
| `tools/` | Repo-local tooling that is not gameplay runtime. |

## Active Runtime vs Tooling

Keep active gameplay paths visually separate from tooling and archives.

Protected active paths include:

- `project.godot`
- `scenes/MainMenu.tscn`
- `scenes/hideout/HideoutHub.tscn`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/levels/IsoMissionBase.gd`
- Active authored security/collectible runtime scripts under `src/missions/iso/`

Tooling/harness paths include:

- `scenes/testing/`
- `scenes/hideout/tools/`
- `scenes/hideout/tests/`
- `src/tools/editor/`

## Cleanup Rules

- Prefer documentation/readme classification before moving active-looking files.
- Move only files with no active runtime references and a backup branch available.
- Do not cleanup Taco or Hideout scene nodes without Godot runtime validation and screenshots.
- Do not delete mission scene variants until bake/test/tooling references are fully understood.
- Do not split `IsoMissionBase.gd` during cleanup-only passes.

## Future Refactor Direction

After cleanup and tests stabilize, `IsoMissionBase.gd` can be gradually decomposed into smaller mission services. Candidate seams:

- Mission lifecycle.
- Authoring runtime setup.
- Security runtime setup.
- Completion/exit flow.
- Debug panel setup.
- Marker/debug generation.

Do this in feature/refactor branches with runtime parity checks, not as part of report/archive cleanup.
