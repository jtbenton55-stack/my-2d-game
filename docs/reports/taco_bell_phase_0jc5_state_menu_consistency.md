# Taco Bell Phase 0J-C5 State/Menu Consistency

Status: **PARTIAL**

C5 repaired count monotonicity, canonical HUD counts, red readable debug text, objective adapter state updates, and code UI instructions. It did not patch shared/global pause menu plumbing, so the pause menu Objectives submenu remains `manual_check_required`/blocked without approval for a shared `QuestManager` or pause menu patch.

## Protection

- Backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0jc5_backup.20260506_171341.tscn`
- Source hash before/after: `6E4E9A790D257126B6F8A17587BACAF6` / `6E4E9A790D257126B6F8A17587BACAF6`
- Duplicate hash before/after: `12EE2E9F39021A084EB0A05A6B5C0D7E` / `12EE2E9F39021A084EB0A05A6B5C0D7E`
- Wall collision shape count before/after: `2368` / `2368`
- Map regenerated/repainted: no
- Runtime inventory: 49 pickup interactables, 139 debug marker interactables, 188 runtime labels

## Count Root Cause

C4 maintained mutable `category_counts` deltas separately from per-category collected dictionaries and HUD-local counters. Because aliases such as `BAG`, `poop_bag`, `GLOW`, and `glow_guy` were normalized inconsistently, the HUD could display values that were not derived from canonical collected IDs. C5 replaces that with `collected_by_category` sets and derives every count from set sizes.

Canonical categories:

- `poop_bag`
- `bag`
- `evidence_clue`
- `polaroid`
- `glow_guy`
- `tiny_icon`
- `objective_bag`

Normalization is implemented in `Phase0JMissionStateAdapter.normalize_category()`. `get_all_counts()` returns set sizes, and `assert_monotonic_counts()` guards against any category decreasing during collection.

## Runtime Validation

Validated with Godot MCP:

- `read_scene`: passed
- Scene helpers present: `Phase0JMissionStateAdapter`, `Phase0JDebugHUD`, `Phase0JCodeInputUI`
- Wall body children: `2368`
- Monotonic sequence: collecting glow, poop bag, tiny, then duplicate glow kept prior counts stable
- Duplicate collect: returned `already_done = true` and did not increment/decrement
- Code UI: opens, wrong code fails, `0420` unlocks, state adapter gate state updates
- Red text: `Phase0JDebugHUD` labels red; `IsoMissionDebugPanel` compact/details labels red

## HUD And Debug Text

`Phase0JDebugHUD` now reads counts from `Phase0JMissionStateAdapter.get_all_counts()` and displays:

`C5 counts (source: Phase0JMissionStateAdapter)`

All canonical categories are shown. Labels are bright red with black outline and a dark semi-transparent panel. The left transparent debug menu in `IsoMissionDebugPanel` applies the same red text, black outline, and dark panel styling to `CompactDebugHUD` and `DebugDetailsPanel`.

## Pause Objectives Audit

Pause menu source:

- Script: `res://src/ui/test_ui/pause_menu.gd`
- Method: `_objectives_text()`
- Reads: `QuestManager.get_current_objective(mission_id)` and `QuestManager.get_completed_objectives(mission_id)`

Problem: `QuestManager.gd` does not implement those getters. `Phase0JObjectiveAdapter` can call `QuestManager.set_objective()`, and runtime validation confirmed `QuestManager.objectives["taco_bell_drop"]` updates, but the pause menu does not read that dictionary directly. Under the C5 rules, no shared/global patch was made.

Required exception-protocol patch if approved:

- File: `res://src/autoload/QuestManager.gd`
- Missing functions: `get_current_objective(mission_id)` and `get_completed_objectives(mission_id)`
- Minimal patch: return `objectives.get(mission_id, active_objective)` and `completed_objectives.get(mission_id, [])`, or update `pause_menu.gd` to read existing QuestManager fields.
- Risk: low, but global to all missions because `QuestManager` is an autoload.
- Gate option: getters are generic/read-only and should be safe; a scene-specific gate is possible but unnecessary if getters preserve current behavior.

## Files Changed

- `res://src/missions/iso/runtime/Phase0JMissionStateAdapter.gd`
- `res://src/missions/iso/runtime/Phase0JDebugHUD.gd`
- `res://src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `res://src/missions/iso/runtime/Phase0JCodeInputUI.gd`
- `res://src/missions/iso/runtime/Phase0JMechanicRouter.gd`
- `res://src/tools/editor/TacoBellPhase0JC5StateMenuConsistency.gd`
- `res://docs/reports/taco_bell_phase_0jc5_state_menu_consistency.md`
- `res://docs/reports/taco_bell_phase_0jc5_state_menu_consistency.json`

## Assertion Ledger

- Duplicate backed up before C5: PASS
- Source hash recorded before: PASS
- Wall collision count before `2368`: PASS
- Runtime helpers inventory recorded: PASS
- Transparent left debug menu audited: PASS
- Pause objective source audited: PASS
- Count subtraction root cause reported: PASS
- Category aliases audited: PASS
- Counts set-derived: PASS
- Collection never decrements any category: PASS
- Duplicate collection does not increment/decrement: PASS
- HUD reads adapter counts: PASS
- HUD displays all C5 categories and source: PASS
- Phase0J HUD text red: PASS
- Transparent left debug text red: PASS
- Red text has dark outline/panel: PASS
- Objective adapter updates local and QuestManager objective state: PASS
- Pause menu refresh/population: MANUAL_REQUIRED, shared patch needed
- Code UI opens and `0420` unlocks: PASS
- Reports written: PASS

## Manual Playtest Checklist

1. Run `TacoBellIso_Editable_RedesignTest.tscn`.
2. Confirm walls still work.
3. Confirm the HUD text is red and readable.
4. Confirm the transparent left-side menu/debug text is red and readable.
5. Collect one Glow Guy.
6. Confirm `glow_guy` count increments.
7. Collect one poop bag.
8. Confirm `poop_bag` count increments and `glow_guy` count does not decrease.
9. Collect one tiny item.
10. Confirm `tiny_icon` count increments and prior counts do not decrease.
11. Re-interact with the same collected items.
12. Confirm no count increments and no count decrements.
13. Collect one clue.
14. Confirm clue/evidence submenu still updates.
15. Interact with one objective marker.
16. Open pause menu Objectives submenu.
17. Confirm objective appears or approve the shared getter patch described above.
18. Interact with delivery bag/objective bag.
19. Confirm `objective_bag` count/state updates.
20. Go to code gate.
21. Confirm code UI shows instructions and current input.
22. Enter wrong code and confirm feedback.
23. Enter `0420` and confirm gate unlocks.
24. Confirm debug HUD counts match collected items.
