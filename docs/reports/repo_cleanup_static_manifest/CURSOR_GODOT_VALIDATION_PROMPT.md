# Cursor Prompt: Godot Runtime Validation Only

You are Cursor running in Jake's Godot 4.6.2 project.

Repo:
`C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game`

This is the Cursor/Godot half of a split cleanup-validation workflow.

OpenCode has already done the static-only side and wrote:

- `docs/reports/repo_cleanup_static_manifest/REPO_CLEANUP_STATIC_MANIFEST.md`
- `docs/reports/repo_cleanup_static_manifest/cleanup_candidates.csv`
- `reports/ai/REPO_CLEANUP_STATIC_MANIFEST_REPORT.md`

## Split Of Responsibilities

OpenCode/static side:

- Static reference scans.
- Cleanup manifest creation.
- Docs/report/debug-artifact classification.
- No gameplay runtime authority.

Cursor/Godot side:

- Godot editor/runtime validation with Godot MCP Pro / GRB / DAP where useful.
- Scene open/play checks.
- Runtime tree inspection.
- Screenshots if useful.
- Confirm whether cleanup candidates are safe to archive later.

## Hard Rules

- Do not delete, move, rename, quarantine, or edit gameplay files in this pass.
- Do not edit `.tscn` scenes in this pass.
- Do not edit `project.godot`.
- Do not commit, stage, push, branch, reset, stash, or rewrite history.
- Treat the dirty worktree as pre-existing active work and do not revert it.
- If Godot tooling writes generated reports, document them, but do not clean them up in this pass.
- Write reports only under:
  - `docs/reports/repo_cleanup_static_manifest/`
  - `reports/ai/`

## Goal

Validate the cleanup candidates from OpenCode's static manifest using Godot runtime/editor evidence. Produce a runtime validation report that says which candidates are safe later, which must be kept, and which need more investigation.

## Required Baseline

1. Run `git status --short` and record it.
2. Read `docs/reports/repo_cleanup_static_manifest/REPO_CLEANUP_STATIC_MANIFEST.md`.
3. Confirm `project.godot` still autoloads `GameState="*res://src/autoload/GameState.gd"`, not the MCP bisection shim/stub.
4. Confirm playable Taco route still resolves through `src/missions/MissionSceneResolver.gd` to `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.

## Runtime Checks To Perform If Tooling Allows

1. Open and/or run `res://scenes/MainMenu.tscn`.
2. Open and/or run `res://scenes/hideout/HideoutHub.tscn`.
3. Open and/or run `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
4. Inspect runtime tree for expected roots/managers/builders:
   - Main menu root and start/continue UI.
   - Hideout manager cluster and hideout sync surfaces.
   - Taco `GameplayRoot`, `SecurityAuthoringRoot`, generated runtime interactables, completion controller, and debug panel.
5. If feasible, run a mission launch flow from MainMenu/Hideout to Taco and return/stop cleanly.
6. If feasible, run GdUnit for `tests/d6_06/MissionAuthoredCollectiblePersistenceTest.gd`; if this creates `reports/report_N`, record the folder and leave it untouched.

## Candidate-Specific Questions

Answer each with evidence:

1. `reports/report_1/`, `reports/report_2/`, `reports/report_3/`
   - Are these only generated GdUnit reports?
   - Is `report_3/results.xml` the latest passing report?
   - Can older duplicate reports be archived/deleted later?

2. `src/autoload/GameState_McpBisectShim.gd`, `src/autoload/GameState_McpBisectStub.gd`, and `.uid` files
   - Are they referenced by `project.godot`, scene ext_resources, scripts, or active MCP workflows?
   - Does MCP/GRB/DAP still need them as repro harnesses?
   - Should they be kept as tooling harnesses or quarantined later?

3. `scenes/testing/McpRuntimeBlankTest.tscn`
   - Does it still serve as the MCP playmode recovery harness?
   - Should it be kept and documented, or archived later?

4. Backup scenes in active folders
   - `scenes/characters/player.phase0mc2_scale_backup.20260509_165530.tscn`
   - `scenes/characters/player.phase0mc2_visual_backup.20260509_102642.tscn`
   - `scenes/ui/DialogueBox.phase0mc3_portrait_dialogue_backup.20260509_065454.tscn`
   - Are these referenced by current scenes/scripts/project settings?
   - Can they later move to `reports/godot_ignored_backups/` without breaking editor loads?

5. `src/missions/iso/runtime/AuthoredCollectiblePickup.gd`
   - Confirm current runtime builder uses `AuthoredPhase0JInteractablePickup.gd` instead.
   - Identify old validators/reports that still require the deprecated file.
   - Recommend whether to keep, mark stale, or quarantine later.

6. Taco scene variants
   - `TacoBellIso_Editable.tscn`
   - `TacoBellIso_Editable_Test.tscn`
   - `TacoBellIso_Editable2.tscn`
   - `TacoBellIsoBlockout.tscn`
   - `TacoBellIsoHandEditTest.tscn`
   - Confirm playable route is `RedesignTest`.
   - Confirm whether bake/test helpers still reference old variants.
   - Do not recommend deletion unless every dynamic/static reference is understood.

7. Hideout tool/test scenes
   - `scenes/hideout/tools/*.tscn`
   - `scenes/hideout/tests/*.tscn`
   - Determine whether these are active editor tooling, stale review scenes, or archive candidates.

## Required Outputs

Create:

- `docs/reports/repo_cleanup_static_manifest/CURSOR_RUNTIME_VALIDATION_REPORT.md`
- `reports/ai/CURSOR_REPO_CLEANUP_RUNTIME_VALIDATION_SUMMARY.md`

The report must include:

- Tools used and unavailable tools.
- Runtime checks performed and results.
- Candidate-by-candidate verdict: `KEEP`, `SAFE_TO_ARCHIVE_LATER`, `QUARANTINE_AFTER_APPROVAL`, `DO_NOT_TOUCH`, or `UNKNOWN_NEEDS_MORE_EVIDENCE`.
- Exact files that would be touched in a future cleanup pass.
- Anything OpenCode got wrong or understated.
- Clear statement that no cleanup was performed.

Stop after writing the validation reports. Do not perform cleanup.
