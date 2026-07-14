# Velvet Paw VIP Countdown Checkpoint 2

Date: 2026-07-13
Mode: Narrow checkpoint inside the grouped Velvet Paw repair milestone
Status: Automated checkpoint complete; manual visual/controller QA remains

## Goal

Resolve the production-scene drift that blocked further edits, make the VIP camera require a readable six-second exposure before security response, and preserve the guard collision repair from checkpoint 1.

## Scene Reconciliation

`scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` is back on the intended Component 2 contract:

- VIP protocol position `(2784, 1664)` with a `192 x 128` footprint entirely inside the lounge.
- VIP phone hidden, non-monitoring, and non-colliding until protocol completion.
- VIP gate shape `64 x 192` on the authored `x=2624` boundary.
- Fixed north rail at `(2624, 1312)` with size `64 x 576`.
- Nine route-blocker bodies total: eight dynamic blocker contracts plus the fixed north rail. The staff gate intentionally owns its two existing shapes.

The runtime QA contract asserts the exact nine-child `RouteBlockers` count, so duplicate serialized blocker bodies fail deterministically.

## Camera Countdown

- `SecurityCameraAuthor.gd` adds opt-in `minimum_exposure_seconds` and `show_exposure_countdown_ring` authoring fields.
- `MissionSecurityCamera.gd` accumulates continuous eligible exposure, resets when exposure is lost, and reports duration/elapsed/progress/completion in debug state.
- The ring is attached above the observed player and drains green to yellow to red. It represents remaining exposure time rather than a second alert authority.
- The default duration is `0.0`, preserving existing camera behavior outside explicit opt-in scenes.
- The Velvet VIP camera opts into `6.0` seconds and permits stationary exposure.
- `VelvetPawJazzClubMissionController.gd` may issue approach/final warnings while exposure builds, but cannot set `vpj_vip_trespass_alarm` or spawn response guards before the camera reports completion.

No global camera, suspicion, HUD, or response manager was added.

## Tests

- `VelvetCameraDetectionPolicyTest.gd` covers authoring propagation, exact six-second accumulation, no early detection, reset behavior, ring drain, and green/yellow/red states.
- `VelvetPawJazzClubRuntimeQATest.gd` covers no response at `5.99` seconds, response at completed exposure, reconciled progression, physical routes, and exact route-blocker body count.
- `VelvetPawRouteComponent2Test.gd` covers scene geometry, phone/protocol state, camera duration, and production response wiring.
- `GuardBehaviorTest.gd` re-proves shared guard body/LOS/knockback collision and live startup/reinforcement contracts.

## Validation

- Focused GdUnit wrapper run: PASS, 41/41 across 4/4 suites; zero errors, failures, flaky cases, skips, or orphans.
- XML evidence: `reports/velvet_vip_countdown_checkpoint2/report_4/results.xml`.
- Level blueprint validator: PASS for all three specs and 55 mechanic types; zero failures or warnings.
- Production scene headless startup: PASS; mission, cameras, and guards load without script/runtime errors.
- `git diff --check` on the checkpoint implementation files: PASS.
- Direct `GdUnitCmdTool.gd` retries crashed natively with signal 11 before test execution; the repository-supported `addons/gdUnit4/runtest.cmd` wrapper completed cleanly and produced the cited XML.
- Godot MCP Pro was not available in this OpenCode tool session, so screenshot/input inspection was not performed.

## Remaining Manual QA

- Confirm the countdown ring stays readable against production art at gameplay zoom.
- Confirm leaving the cone visibly resets the countdown and that six seconds feels fair.
- Confirm warning timing and reinforcement arrival feel correct with real movement.
- Confirm controller-only Bentley park/stay flow once that input is wired.
- Recheck VIP rail/gate collision feel in the editor before any future scene save.

## Safety And Continuity

- Grouped-milestone mode fell back to this narrow Stage 2B checkpoint because production-scene drift and runner instability required a smaller rollback boundary.
- Existing mission-local controller and shared camera/alert seams were extended; no duplicate manager or compatibility layer was introduced.
- Existing unrelated worktree changes were preserved.
- No commit, stage, push, branch change, reset, or history operation was performed.
