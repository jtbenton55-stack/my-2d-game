# CURSOR Post-Cleanup Runtime Regression Report

Date: 2026-05-19  
Branch: `cleanup/repo-organization-2026-05-19`  
Scope: Post–repo-organization cleanup runtime regression validation (reporting only)

## 1) Goal

This pass validates whether OpenCode’s first repo-organization cleanup (`REPO_ORGANIZATION_CLEANUP_01`) is safe so far. OpenCode changed docs, reports, backup organization, generated test-report handling, and classification/readme documentation. OpenCode did not intentionally change gameplay scripts, active gameplay scenes, `project.godot`, Taco scene variants, `HideoutHub`, `IsoMissionBase.gd`, or scene nodes.

**No cleanup or fixes were performed in this pass.**

## 2) Branch And Safety Baseline

| Check | Result |
|---|---|
| Current branch | `cleanup/repo-organization-2026-05-19` |
| Expected branch | `cleanup/repo-organization-2026-05-19` |
| Branch match | **Yes** |
| `git status --short` | Recorded (cleanup diffs: deleted `reports/report_1`–`report_4`, moved backup `.tscn` out of active folders, new docs/readmes, validator docstring/README updates) |
| Git history operations | **None** (no commit/stage/push/reset/stash/branch switch) |
| Gameplay/scene/project edits | **None** |
| Report writes | Only this file and `reports/ai/CURSOR_POST_CLEANUP_RUNTIME_REGRESSION_SUMMARY.md` |

### Cleanup facts recorded (from OpenCode report + local verification)

- Backup branch: `backup/pre-cleanup-2026-05-19`
- Cleanup branch: `cleanup/repo-organization-2026-05-19`
- Removed from working tree: `reports/report_1/` through `reports/report_4/`
- Latest pre-run GdUnit evidence on branch: `reports/report_5/results.xml` (4/4 pass)
- Backup `.tscn` files moved from active folders to `reports/godot_ignored_backups/` (local archive; git shows deletions from active paths)
- Authorable docs consolidated around `docs/AUTHORING_GUIDE.md`
- Stale D6-06 validators marked superseded (not deleted)

## 3) Tools Used

| Tool | Used | Result |
|---|---|---|
| Godot MCP Pro | Yes | Project info, scene open/play, runtime tree, UI click, editor errors |
| GdUnit4 CLI | Yes | `addons/gdUnit4/runtest.cmd` on `res://tests/d6_06/` |
| Godot DAP MCP | Yes | `godot_ping` responded |
| Godot LSP diagnostics | Yes | `scan_workspace_diagnostics` (67 files scanned) |
| Terminal/PowerShell | Yes | Validators, git status, GdUnit |
| Kimi K2.6 MCP | Yes | Advisory `regression_risk_review` only |

### Kimi K2.6 MCP usage

- **Used:** Yes (`ask_kimi_k2_6`, mode `regression_risk_review`)
- **Purpose:** Second-brain checklist for post-cleanup regression priorities
- **Adopted:** Reference-integrity sweep first; Taco runtime smoke; validator diff vs pre-existing D6-06B failure
- **Rejected:** Any destructive/broad cleanup suggestions (not applicable to this validation-only pass)
- **Secrets/private data:** None sent (sanitized task context only)
- **Authority:** Advisory only; all conclusions validated locally

## 4) Required Baseline Checks

| Check | Result |
|---|---|
| `GameState` autoload | `*res://src/autoload/GameState.gd` |
| `GameState_McpBisectShim` autoload | **Not present** |
| `GameState_McpBisectStub` autoload | **Not present** |
| Main scene | `res://scenes/MainMenu.tscn` |
| `MissionSceneResolver` for `taco_bell_drop` | `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` |
| Godot version (MCP) | 4.6.2-stable |

## 5) Scenes Opened / Run

| Scene | Opened | Ran | Observations |
|---|---|---|---|
| `res://scenes/MainMenu.tscn` | Yes | Yes | Buttons: New Game, Continue, Settings, Quit |
| `res://scenes/hideout/HideoutHub.tscn` | Yes (via New Game) | Yes | Transition MainMenu → HideoutHub confirmed |
| `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` | Yes | Yes | Runtime tree shows full mission systems (see §6) |

## 6) Runtime Regression Checks

### MainMenu

- **PASS:** Scene opens and runs.
- **PASS:** UI buttons present (`New Game`, `Continue`, `Settings`, `Quit`).
- **PASS:** MCP clicked `New Game`; runtime advanced to HideoutHub.
- **Classification:** No cleanup-caused errors observed.

### HideoutHub

- **PASS:** Loaded after MainMenu `New Game`.
- **PASS:** `HideoutHubRoot`, `GameplayRoot`, `Player`, manager cluster present.
- **PASS:** Station surfaces present including `MissionBoard`, `EvidenceBoard_TheBigCase`, `GlowGuyShelf`, `PolaroidWall`, `PoopBagCareDisplay`, `StoreTerminal`.
- **PASS:** UI panels present (`MissionBoardPanel`, `EvidencePanel`, `SchemeCardPanel`, etc.).
- **Not fully exercised:** Mission board open → Taco launch → return loop (tooling limitation; not attempted end-to-end in this pass).
- **Classification:** No cleanup-caused missing-resource errors.

### Taco playable scene

- **PASS:** Opens and runs from MCP `play_scene`.
- **PASS:** Root `TacoBellIso_Editable` with `IsoMissionBase.gd`.
- **PASS:** Runtime nodes confirmed:
  - `GameplayRoot`
  - `SecurityAuthoringRoot` (beam/camera/guard/trigger authors)
  - `RuntimeSystems` (`SpawnedGuards`, `SpawnedCameras`, `AlarmZones`, `AuthoringAreaTriggers`, etc.)
  - `GeneratedRuntimeInteractables` (many interactables including clues, bags, glow, tiny, Louis exit)
  - `RuntimeHelpers/Phase0KMissionCompletionController`
  - `LouisExitToken` (`Phase0KLouisExitInteractable.gd`)
- **PASS:** `CollectibleAuthoringRuntimeBuilder` still preloads `AuthoredPhase0JInteractablePickup.gd`.
- **Not re-captured this pass:** `IsoMissionDebugPanel` node in filtered runtime tree (confirmed in prior Cursor validation; no new missing-resource errors in editor log).
- **Classification:** No cleanup-caused missing-resource errors for deleted reports or moved backups.

### Major mechanics smoke (limited)

| Mechanic | Status | Classification |
|---|---|---|
| Player movement | Not exercised via MCP input | TOOLING_LIMITATION |
| F10 debug panel | Not exercised | TOOLING_LIMITATION |
| Authored collectibles generated | **Observed** in runtime tree | PASS |
| `AuthoredPhase0JInteractablePickup` path | **Confirmed** in builder script | PASS |
| Security beam/camera/guard runtime | **Observed** (`SpawnedGuards`, `SpawnedCameras`, `AlarmZones`, beam author) | PASS |
| Louis/completion controller | **Observed** | PASS |
| Full interact/collect/exit flow | Not exercised | TOOLING_LIMITATION |

## 7) Cleanup-Specific Checks

### Deleted generated report folders (`report_1`–`report_4`)

- Searched `src/`, `scenes/`, `project.godot`: **no references** to `reports/report_1` through `reports/report_4`.
- Taco/MainMenu/Hideout runtime: **no** `File not found` errors pointing at those paths.
- **Verdict:** Not runtime dependencies. **SAFE.**

### Latest GdUnit report state

- `reports/report_5/results.xml` exists (4 tests, 0 failures) — OpenCode baseline on branch.
- This pass generated `reports/report_6/results.xml` (4 tests, 0 failures).
- **Latest after this pass:** `reports/report_6/`
- Left untouched per instructions.

### Moved backup scenes

Active-path reference scan (`src/`, `scenes/`, `project.godot`):

- `player.phase0mc2_scale_backup.20260509_165530.tscn` — **no references**
- `player.phase0mc2_visual_backup.20260509_102642.tscn` — **no references**
- `DialogueBox.phase0mc3_portrait_dialogue_backup.20260509_065454.tscn` — **no references**

Archive copies confirmed under `reports/godot_ignored_backups/scenes/...` (local; ignored by default).

- **Verdict:** No active runtime dependency on old active-folder paths.

### Documentation/readme changes

- Docs/readme edits only; no runtime load paths observed.
- **Verdict:** Not runtime-impacting.

## 8) Validator And Test Results

### Static validators

| Validator | Result | Notes |
|---|---|---|
| `phase0md6_07_static_validator.py` | **PASS** | Warn: `project.godot` may have been touched recently |
| `phase0md6_07b_static_validator.py` | **PASS** | |
| `phase0md6_08a_security_authorable_validator.py` | **PASS** | Warn: `SecurityAuthoringRoot runtime_enabled` not explicit in scene text |
| `phase0md6_06b_static_validator.py` | **FAIL** | Exact known error: `Taco scene missing proof node D6_06_CaseCash_LegacyAlias_Author` |

### GdUnit4

- **Command:**
  ```text
  addons/gdUnit4/runtest.cmd --godot_binary "C:/Users/jtben/Documents/PBD 2026/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe" -a res://tests/d6_06/
  ```
- **Generated folder:** `reports/report_6/`
- **Suite:** `MissionAuthoredCollectiblePersistenceTest`
- **Tests:** 4
- **Failures:** 0
- **Errors:** 0
- **Skips/flaky:** 0
- **Supersedes:** `reports/report_5/` for latest generated evidence

## 9) Errors And Warnings (Classified)

| Message | Classification |
|---|---|
| D6-06B: `Taco scene missing proof node D6_06_CaseCash_LegacyAlias_Author` | **KNOWN_PRE_EXISTING** (same as OpenCode cleanup pass; scene-validator drift, not cleanup) |
| D6-07: `project.godot` may have been touched recently | **UNKNOWN_NEEDS_FOLLOWUP** (warn only; cleanup did not intentionally edit; may be editor metadata) |
| D6-08A: `SecurityAuthoringRoot runtime_enabled` not explicit | **LIKELY_PRE_EXISTING** |
| GDScript `SHADOWED_GLOBAL_IDENTIFIER`, `UNUSED_*`, `INTEGER_DIVISION` in IsoMissionBase/Player/etc. | **LIKELY_PRE_EXISTING** |
| Vulkan registry loader message | **LIKELY_PRE_EXISTING** |
| GdUnit run: `McpInteractionServer: Failed to listen on port 9090` when editor already bound port | **TOOLING_LIMITATION** (parallel MCP + GdUnit) |
| LSP warnings in HideoutManager, HideoutMissionBoardController, NPC, etc. | **LIKELY_PRE_EXISTING** |

**No errors classified as CLEANUP_CAUSED.**

## 10) Final Verdict

**PASS_WITH_KNOWN_PREEXISTING_ISSUES**

Cleanup organization changes did not break core editor/runtime flows tested. Known pre-existing validator drift (D6-06B proof node) and routine GDScript warnings remain. No evidence that deleted `reports/report_1`–`report_4` or moved backup scenes broke MainMenu, HideoutHub, or playable Taco loading.

## 11) Known Limitations

- Full MainMenu → Hideout → MissionBoard → Taco → completion → return loop not automated end-to-end.
- Player movement, F10 debug panel, and collectible interact/commit not exercised via MCP input.
- `IsoMissionDebugPanel` not re-listed in filtered Taco runtime tree this pass (prior validation + no new load errors).
- GdUnit created new `reports/report_6/` (left in place).
- Manual Jake playtest still valuable for feel/regression on mission board launch and hideout sync displays.

## 12) Suggested Next Step

1. **Safe to continue cleanup planning** on this branch (docs/archive classification), but do not delete Taco variants or quarantine MCP bisect files without a separate approved pass.
2. Track D6-06B validator/scene drift (`D6_06_CaseCash_LegacyAlias_Author`) as a **gameplay/validator follow-up**, not a cleanup blocker.
3. Optional: Jake manual smoke — open mission board, launch Taco, collect one authored item, exit — to confirm hideout sync after cleanup.
4. When ready for next cleanup slice: archive duplicate GdUnit folders using `report_6` as latest evidence (after explicit approval).
