# CURSOR Runtime Validation Report

Date: 2026-05-19  
Scope: Godot editor/runtime validation of static cleanup candidates from `REPO_CLEANUP_STATIC_MANIFEST.md`  
Cleanup performed: **None** (validation only)

## 1) Baseline And Guardrails

- Ran `git status --short` before validation and recorded an already-dirty active worktree.
- Did **not** edit gameplay scripts, scenes, resources, `project.godot`, or project settings.
- Did **not** stage, commit, push, branch, stash, or rewrite history.
- Wrote this report and summary report only.

## 2) Required Baseline Checks

1. `git status --short` captured successfully (dirty state preserved).
2. Read `docs/reports/repo_cleanup_static_manifest/REPO_CLEANUP_STATIC_MANIFEST.md`.
3. Confirmed `project.godot` autoload:
   - `GameState="*res://src/autoload/GameState.gd"`
   - No active `GameState_McpBisectShim` / `GameState_McpBisectStub` autoload entry.
4. Confirmed playable Taco route via `src/missions/MissionSceneResolver.gd`:
   - `TACO_BELL_MISSION_ID := "taco_bell_drop"`
   - `resolve_playable_scene_path()` returns `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` for Taco.

## 3) Tools Used And Availability

## Used

- `git` (status + report timestamp checks)
- Workspace scans (`rg`, `Glob`, `ReadFile`)
- Godot MCP Pro:
  - `get_project_info`
  - `open_scene`
  - `get_scene_tree`
  - `play_scene`
  - `get_game_scene_tree`
  - `find_ui_elements`
  - `click_button_by_text`
  - `stop_scene`
  - `get_editor_errors`
- Godot LSP diagnostics MCP:
  - `scan_workspace_diagnostics`
- Godot DAP MCP:
  - `godot_ping`
- GdUnit command:
  - `addons/gdUnit4/runtest.cmd --godot_binary ".../Godot_v4.6.2-stable_win64.exe" -a res://tests/d6_06/`

## Availability / limitations

- Godot MCP Pro editor scene introspection worked.
- Runtime tree calls worked on Taco runtime, but some `get_game_scene_tree` calls failed when short-lived sessions ended quickly (`Game stopped during command execution`), especially for lightweight scenes/flows.
- DAP server responded to ping but was not required for step-debug in this pass.

## 4) Runtime Checks Per Prompt

1. Open/run `MainMenu.tscn`:
   - Opened in editor successfully.
   - Runtime UI surfaced expected buttons (`New Game`, `Continue`, `Settings`, `Quit`).
   - Clicked `New Game` via MCP UI click helper; scene advanced quickly and runtime tree request raced with shutdown.
2. Open/run `HideoutHub.tscn`:
   - Opened successfully.
   - Scene tree confirms `HideoutManager` cluster and expected hideout manager/controller surfaces.
3. Open/run `TacoBellIso_Editable_RedesignTest.tscn`:
   - Opened successfully.
   - Runtime tree captured expected roots and systems:
     - `GameplayRoot`
     - `SecurityAuthoringRoot`
     - `RuntimeSystems`
     - `GeneratedRuntimeInteractables`
     - `RuntimeHelpers/Phase0KMissionCompletionController`
     - `IsoMissionDebugPanel`
4. Mission launch flow:
   - Partial evidence only (MainMenu runtime button click confirmed).
   - Full deterministic MainMenu -> Hideout -> Taco -> return flow not fully captured in one uninterrupted MCP runtime tree trace due session timing behavior.
5. GdUnit:
   - Executed successfully.
   - New output folder: `reports/report_4/`
   - `tests/d6_06/MissionAuthoredCollectiblePersistenceTest.gd` => **4/4 PASS** in `reports/report_4/results.xml`.

## 5) Candidate-By-Candidate Validation Verdicts

## REPORT-GDUNIT-DUPES (`reports/report_1/`, `reports/report_2/`, `reports/report_3/`)

- Evidence:
  - All three contain standard GdUnit HTML/XML artifact structure (`index.html`, `results.xml`, css, per-suite pages).
  - `results.xml` timestamps show `report_3` was newer than `report_1`/`report_2`.
  - This validation run created `report_4` with latest passing D6-06 suite.
- Answers:
  - Are these generated GdUnit reports? **Yes.**
  - Is `report_3/results.xml` the latest passing report? **No longer; `report_4/results.xml` is now latest.**
  - Can older duplicates be archived/deleted later? **Yes**, after preserving latest summary.
- Verdict: **SAFE_TO_ARCHIVE_LATER**

## MCP-BISECT-GAMESTATE (`GameState_McpBisectShim.gd`, `GameState_McpBisectStub.gd`, `.uid`)

- Evidence:
  - No references found in `project.godot`, `src/`, or `scenes/`.
  - Historical docs/reports show prior investigative use as MCP bisection harness artifacts.
- Answers:
  - Referenced by active autoload/scene wiring? **No evidence of active runtime wiring.**
  - Still needed by active MCP workflows? **Possibly for future repro harness reuse; current runtime did not require them.**
- Verdict: **QUARANTINE_AFTER_APPROVAL**

## MCP-BLANK-TEST-SCENE (`scenes/testing/McpRuntimeBlankTest.tscn`)

- Evidence:
  - Historical runtime recovery reports explicitly use it as MCP playmode harness.
  - Open/play still succeeds, confirming harness viability.
- Answer:
  - Serves MCP playmode recovery harness? **Yes, still useful.**
- Verdict: **KEEP**

## SCENE-BACKUPS-ACTIVE-FOLDERS

- Paths:
  - `scenes/characters/player.phase0mc2_scale_backup.20260509_165530.tscn`
  - `scenes/characters/player.phase0mc2_visual_backup.20260509_102642.tscn`
  - `scenes/ui/DialogueBox.phase0mc3_portrait_dialogue_backup.20260509_065454.tscn`
- Evidence:
  - Referenced by docs/reports as rollback backups.
  - No runtime/scene/script reference evidence in `src/` or `scenes/` (beyond docs/report mentions).
- Answer:
  - Can move to archive path later without breaking active loads? **Likely yes**, but only in an approved cleanup pass.
- Verdict: **SAFE_TO_ARCHIVE_LATER**

## LEGACY-AUTHORED-PICKUP (`src/missions/iso/runtime/AuthoredCollectiblePickup.gd`)

- Evidence:
  - Current runtime builder uses `AuthoredPhase0JInteractablePickup.gd`.
  - File is explicitly marked deprecated.
  - Older validators and reports still reference `AuthoredCollectiblePickup.gd`.
- Answer:
  - Current runtime path uses new interactable pickup? **Yes.**
  - Old validators/reports still require deprecated file? **Yes.**
- Verdict: **QUARANTINE_AFTER_APPROVAL** (after validator/report migration)

## TACO-SCENE-VARIANTS

- Paths:
  - `TacoBellIso_Editable.tscn`
  - `TacoBellIso_Editable_Test.tscn`
  - `TacoBellIso_Editable2.tscn`
  - `TacoBellIsoBlockout.tscn`
  - `TacoBellIsoHandEditTest.tscn`
- Evidence:
  - Playable mission resolver points to `TacoBellIso_Editable_RedesignTest.tscn`.
  - Multiple tools/builders/validators still reference legacy editable/blockout/test variants.
  - Runtime tree for Taco includes complex generated systems; deletion risk remains high.
- Answer:
  - Playable route is RedesignTest? **Yes.**
  - Old variants still referenced by bake/test/tooling helpers? **Yes.**
- Verdict: **DO_NOT_TOUCH**

## HIDEOUT-TOOL-SCENES (`scenes/hideout/tools/*.tscn`, `scenes/hideout/tests/*.tscn`)

- Evidence:
  - Large active tool scene set exists (`tools` folder) plus geometry audit test scene.
  - `src/tools/editor/*` contains many direct references/validators to these scenes.
- Answer:
  - Active tooling vs stale? **Predominantly active tooling references; not safe for broad archival now.**
- Verdict: **KEEP**

## 6) OpenCode Understated / Needs Update

- Static manifest item about `report_3` being latest is now outdated after this run; `report_4` is latest.
- Prior audit-era note that LSP scan returned zero files is no longer true in this environment; current scan returned files/issues data.

## 7) Exact Files For A Future Cleanup Pass (No Changes Done Now)

If approved in a separate cleanup pass, candidate touch list is:

- `reports/report_1/**`
- `reports/report_2/**`
- `reports/report_3/**`
- `src/autoload/GameState_McpBisectShim.gd`
- `src/autoload/GameState_McpBisectShim.gd.uid`
- `src/autoload/GameState_McpBisectStub.gd`
- `src/autoload/GameState_McpBisectStub.gd.uid`
- `scenes/characters/player.phase0mc2_scale_backup.20260509_165530.tscn`
- `scenes/characters/player.phase0mc2_visual_backup.20260509_102642.tscn`
- `scenes/ui/DialogueBox.phase0mc3_portrait_dialogue_backup.20260509_065454.tscn`
- `src/missions/iso/runtime/AuthoredCollectiblePickup.gd`
- Potentially stale validator/report sets after explicit migration plan:
  - `src/tools/editor/d6_06_collectible_authoring/**`
  - `src/tools/editor/d6_06b_collectible_physical_pickup/**`
  - related historical reports that hard-require deprecated pickup path

## 8) Final Statement

This pass performed **runtime/editor validation only** and produced reporting artifacts.  
**No cleanup (delete/move/rename/quarantine) was performed.**

