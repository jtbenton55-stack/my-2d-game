# Repo Cleanup Static Manifest

OpenCode static-only cleanup planning pass. No gameplay scripts, scenes, resources, project settings, tests, or reports were moved, deleted, or edited by this pass.

## Scope

- Reviewed Cursor's `repo_audit_01` outputs and second-pass repo evidence.
- Classified cleanup candidates that do not require immediate Godot runtime editing.
- Split work between OpenCode static planning and Cursor/Godot runtime validation.

## Key Constraint

The current working tree is intentionally dirty with active D6/D8 authorable/security/hideout work. Do not perform destructive cleanup until the active gameplay state is validated and preserved by Jake.

## Cursor Audit Correction

Cursor's `repo_audit_inventory.json` is useful but curated, not complete. It has `entry_count: 47`, while `git ls-files` plus untracked visible files showed about `9,646` repo-visible files at the time of this pass. Treat Cursor's inventory as an active-system inventory, not a full cleanup manifest.

## Static Cleanup Candidates

| ID | Paths | Classification | Risk | Owner | Recommended Next Action |
|---|---|---|---|---|---|
| DOC-AUTHORABLE-OVERLAP | `docs/AUTHORABLE_NODES_GUIDE.md`, `docs/AUTHORABLE_USE_GUIDE.md`, `docs/SECURITY_AUTHORABLES_GUIDE.md` | docs overlap, useful content | low | OpenCode/static | Later consolidate into one authorable index plus security-specific guide; do not delete yet. |
| REPORT-GDUNIT-DUPES | `reports/report_1/`, `reports/report_2/`, `reports/report_3/` | duplicate generated GdUnit reports | low | OpenCode/static after approval | Preserve latest pass/fail summary, then archive/delete duplicate generated folders in an approved cleanup pass. |
| MCP-BISECT-GAMESTATE | `src/autoload/GameState_McpBisectShim.gd`, `src/autoload/GameState_McpBisectStub.gd`, `.uid` siblings | MCP playmode bisection artifacts | medium-low | Cursor/runtime validation first | Verify not referenced by `project.godot`, scene ext_resources, or runtime setup; quarantine only after Cursor confirms MCP workflows no longer need them. |
| MCP-BLANK-TEST-SCENE | `scenes/testing/McpRuntimeBlankTest.tscn` | useful MCP runtime harness | keep/tooling | Cursor/runtime validation | Keep unless Jake decides MCP runtime recovery harness is obsolete. If retained, document under tooling docs. |
| SCENE-BACKUPS-ACTIVE-FOLDERS | `scenes/characters/player.phase0mc2_*_backup*.tscn`, `scenes/ui/DialogueBox.phase0mc3_*_backup*.tscn` | backup scenes inside active folders | medium | Cursor/runtime validation first | Verify active scenes load cleanly and backups are not referenced; then move to `reports/godot_ignored_backups/` or another approved archive path. |
| LEGACY-AUTHORED-PICKUP | `src/missions/iso/runtime/AuthoredCollectiblePickup.gd` | legacy runtime path | medium-low | Cursor/runtime validation first | Do not remove yet. Old validators still reference it. First update/retire stale validators, then quarantine with manifest. |
| STALE-VALIDATORS-DEPRECATED-PICKUP | `src/tools/editor/d6_06_collectible_authoring/`, `src/tools/editor/d6_06b_collectible_physical_pickup/`, related old reports | stale validators for deprecated pickup path | low-medium | OpenCode/static + Cursor test confirmation | Mark stale or superseded before any file movement. Current validator `d6_06b_interactable_collectible_hideout_sync` already enforces non-use. |
| TACO-SCENE-VARIANTS | `scenes/missions_iso/TacoBellIso_Editable*.tscn`, `TacoBellIsoBlockout.tscn`, `TacoBellIsoHandEditTest.tscn` | legacy/dev/bake variants | high | Cursor/runtime validation only | Do not move/delete in static cleanup. `IsoMissionBase` bake helpers and many validators/docs still reference legacy paths. |
| HIDEOUT-TOOL-SCENES | `scenes/hideout/tools/*.tscn`, `scenes/hideout/tests/*.tscn` | editor/tooling scenes | medium | Cursor/runtime validation | Classify as active tooling vs archive later. Do not delete without Godot editor validation. |
| OLD-REPORT-BACKUPS | `reports/godot_ignored_backups/`, `reports/ai/setup-backups/` | intentional backup archives | low | OpenCode/static after approval | Keep for now. If storage clutter matters, compress/archive outside gameplay folders in a separate human-approved pass. |

## Do Not Touch Yet

- `project.godot` autoloads and plugins.
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- `src/levels/IsoMissionBase.gd`.
- Active D6/D8 authoring and runtime scripts.
- Hideout manager/state/sync scripts.
- Any scene node cleanup under Taco or Hideout without Godot runtime parity checks.

## Safe First Cleanup Pass After Validation

1. Archive/delete duplicate `reports/report_1/`, `reports/report_2/`, `reports/report_3/` after preserving the latest XML pass summary.
2. Add docs index/consolidation note for authorable docs; do not remove docs until duplicate content is merged.
3. Move clearly orphaned backup scenes from active folders to `reports/godot_ignored_backups/` only after Cursor confirms no references.
4. Quarantine MCP bisection GameState files only after Cursor confirms MCP runtime/debugging workflows no longer use them.
5. Retire stale D6-06 validators only after the current D6-06/D6-07/D6-08 validators and GdUnit tests pass.

## Validation Required Before Cleanup

- `git status --short` baseline.
- Static reference scan for every candidate path and UID.
- Godot editor open check for `MainMenu`, `HideoutHub`, and playable Taco.
- Runtime smoke for MainMenu -> Hideout -> Taco -> completion/return if feasible.
- GdUnit `tests/d6_06/MissionAuthoredCollectiblePersistenceTest.gd` or documented reason if skipped.
- Screenshot/runtime tree evidence for Taco and Hideout if scene files are touched.
