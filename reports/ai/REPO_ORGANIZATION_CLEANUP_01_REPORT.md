# REPO ORGANIZATION CLEANUP 01 REPORT

Cleanup branch: `cleanup/repo-organization-2026-05-19`

Backup baseline: `backup/pre-cleanup-2026-05-19` at `8c72546`

## Scope

Performed the first low-risk repository organization cleanup pass.

No gameplay scripts, active gameplay scenes, `project.godot`, Taco scene variants, HideoutHub, `IsoMissionBase.gd`, or scene nodes were intentionally changed.

## Changes Made

- Removed superseded generated GdUnit report folders:
  - `reports/report_1/`
  - `reports/report_2/`
  - `reports/report_3/`
  - `reports/report_4/`
- Kept latest generated GdUnit report evidence:
  - `reports/report_5/results.xml`
- Moved rollback scene backups out of active scene folders:
  - `scenes/characters/player.phase0mc2_scale_backup.20260509_165530.tscn` -> `reports/godot_ignored_backups/scenes/characters/player.phase0mc2_scale_backup.20260509_165530.tscn`
  - `scenes/characters/player.phase0mc2_visual_backup.20260509_102642.tscn` -> `reports/godot_ignored_backups/scenes/characters/player.phase0mc2_visual_backup.20260509_102642.tscn`
  - `scenes/ui/DialogueBox.phase0mc3_portrait_dialogue_backup.20260509_065454.tscn` -> `reports/godot_ignored_backups/scenes/ui/DialogueBox.phase0mc3_portrait_dialogue_backup.20260509_065454.tscn`
- Added canonical authoring and organization docs:
  - `docs/AUTHORING_GUIDE.md`
  - `docs/REPORTING_AND_BACKUP_POLICY.md`
  - `docs/REPO_ORGANIZATION_GUIDE.md`
- Converted overlapping authorable docs into compatibility entry points:
  - `docs/AUTHORABLE_NODES_GUIDE.md`
  - `docs/AUTHORABLE_USE_GUIDE.md`
- Added scene/tooling classification readmes:
  - `scenes/missions_iso/README.md`
  - `scenes/hideout/README.md`
  - `scenes/testing/README.md`
- Marked superseded D6-06 validators:
  - `src/tools/editor/d6_06_collectible_authoring/README.md`
  - `src/tools/editor/d6_06b_collectible_physical_pickup/README.md`
  - Updated validator docstrings to state they target deprecated `AuthoredCollectiblePickup` paths.

## Reference Checks

- Searched `src/`, `scenes/`, and `project.godot` for active references to moved backup scene filenames.
- No active references were found.

## Validation

- `git diff --check`: PASS.
- `python src/tools/editor/d6_07_broader_interactable_authoring/phase0md6_07_static_validator.py`: PASS with warning that `project.godot` may have been touched recently.
- `python src/tools/editor/d6_07b_authorable_standardization/phase0md6_07b_static_validator.py`: PASS.
- `python src/tools/editor/d6_08a_security_authorables/phase0md6_08a_security_authorable_validator.py`: PASS with warning that `SecurityAuthoringRoot runtime_enabled` is not explicit in scene text.
- `addons/gdUnit4/runtest.cmd --godot_binary "...Godot_v4.6.2-stable_win64.exe" -a res://tests/d6_06/`: PASS, 4 tests, 0 failures, 0 errors.

## Known Validation Issue

- `python src/tools/editor/d6_06b_interactable_collectible_hideout_sync/phase0md6_06b_static_validator.py`: FAIL.
- Error: `Taco scene missing proof node D6_06_CaseCash_LegacyAlias_Author`.
- This cleanup pass did not change Taco scene proof nodes and did not attempt to fix gameplay/scene content. Treat this as a current validator/scene-drift follow-up outside this repo-organization-only pass.

## Runtime Scene Checks

No Godot scene runtime smoke was run by OpenCode in this cleanup pass. Cursor had already performed the runtime validation pass immediately before this cleanup and confirmed MainMenu, HideoutHub, and playable Taco opened/ran sufficiently for cleanup planning.

## Safety Notes

- Backup branch remains available on GitHub: `backup/pre-cleanup-2026-05-19`.
- Cleanup branch is isolated from the backup branch.
- Moved rollback scenes remain locally in `reports/godot_ignored_backups/`, which is intentionally ignored by default. The original tracked copies are preserved on the backup branch. If Jake wants these three archived scenes tracked on the cleanup branch, they should be explicitly force-added or moved to a non-ignored archive path in a follow-up.
