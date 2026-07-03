# 2026-06-23 - Taco Bell D5 QA Dashboard

## Scope

Added a visual F12 QA dashboard for Taco D5 manual testing. This is a debug/readability packet intended to make D5-01, D5-02, and D5-03 easier to test together before continuing gameplay implementation.

This stayed narrow: no Taco scene edits, no Player edits, no project settings edits, and no new global manager.

## Files Changed

- `src/missions/iso/runtime/MissionQAChecklistPanel.gd`
- `src/tools/editor/taco_bell_d5_qa_dashboard/phase0md5_qa_dashboard_static_validator.py`
- `docs/reports/taco_bell_d5_qa_dashboard/phase0md5_qa_dashboard_static_validator_run.json`
- `reports/ai/2026-06-23_taco_bell_d5_qa_dashboard_report.md`

## Implementation Notes

- Extended the existing F12 `MissionQAChecklistPanel` instead of creating a parallel debug system.
- Added D5 tabs:
- `D5-01 - Attempt Reset`
- `D5-02 - Pause Context`
- `D5-03 - Louis Beam Bypass`
- Added live colored BBCode status badges such as `PASS`, `WAIT`, `READY`, `DONE`, `LOCKED`, `OPEN`, `TRIPPED`, `WARN`, and `FAIL`.
- Added contextual action buttons above the checklist body:
- D5-01: `Go Code Gate`, `Go Bag`, `Go Exit`, `Reset Attempt`, `Restart Scene`
- D5-02: `Go Start`, `Go Code Gate`, `Go Bag`
- D5-03: `Go Main Beam`, `Go Louis Route`, `Grant Louis Card`, `Remove Louis Card`, `Reset Attempt`
- Preserved older Phase 4G / security QA behavior and moved its previous hard-coded buttons into the same reusable action bar.
- Follow-up fix: D5 teleport buttons now resolve real RedesignTest scene markers/node paths instead of stale generic spawn ids/fallback cells. Current targets are `code_gate_garage_office`, `objective_retrieve_delivery_bag`, `objective_escape_and_return_to_louis`, `player_spawn_main`, `spawn_route_louis_entry`, and runtime/fallback beam node paths.
- Follow-up crash fix: marker lookup now reads optional node properties through `_node_string_property()` instead of unsafe `String(node.get(...))` conversions. The static validator now rejects that unsafe pattern.
- Live-QA follow-up: the underlying D5 reset hook now resets scene-local delivery bag visual/interaction state, and the runtime garage beam summary now recognizes the current authored `AMBUSH_security_beam` trigger as well as the legacy `garage_entry_beam` flag.

## How Jake Should Use It

- Press `F10` only if you want the compact/raw debug HUD.
- Press `F12` for the new readable QA dashboard.
- Choose `D5-01`, `D5-02`, or `D5-03` from the dropdown.
- Use the buttons above the checklist to teleport or reset the exact thing being tested.
- Watch the colored rows change as objectives, beam state, pause payload, route-card state, and reset metadata change.

## Validation

- PASS: `python "src/tools/editor/taco_bell_d5_qa_dashboard/phase0md5_qa_dashboard_static_validator.py"` (`45` checks after marker-target/crash follow-up; includes scene marker existence checks and unsafe marker-property conversion guard)
- PASS: `addons/gdUnit4/runtest.cmd --godot_binary "Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe" -a "res://tests/mission_authoring/SecurityReadabilityLiteTest.gd"`
- GdUnit result after marker-target/crash follow-up: `7/7` passed, `0` failures, `0` errors, `0` orphans. Latest HTML/XML report after bag/beam follow-up: `reports/report_90/`.
- PASS: D5-01 focused reset suite after bag/beam follow-up: `4/4` passed, report `reports/report_89/`.
- PASS: `git diff --check` for `MissionQAChecklistPanel.gd`.

## Known Noise

- GdUnit startup still logs existing remote debugger port `0`, controller mapping `misc2`, Vulkan loader registry, and MCP port `9090` warnings.
- Worktree remains heavily dirty with unrelated prior/generated files. This pass did not revert or stage them.

## Remaining Risks

- Manual visual QA is still needed in the live Taco scene to confirm F12 panel size/readability and button placement feel good on Jake's display.
- D5-03 gameplay wiring is intentionally not implemented here; the dashboard shows its bypass outcome as `WAIT` until that packet exists.
- The action buttons rely on existing mission teleport/reset hooks; if a spawn id is missing in a scene variant, the button may no-op or use the existing mission fallback behavior.
