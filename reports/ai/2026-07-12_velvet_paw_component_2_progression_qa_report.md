# Velvet Paw Component 2 Progression/QA Repair

Date: 2026-07-12

## Scope

Grouped Component 2 repair covering live security QA controls, table-service progression, physical VIP/back-room gating, watched interaction timing, delayed VIP voicemail collection, and mission inventory visibility. No new manager or controller-input scope was added.

## Implemented

- Added F12 checklist mode `Velvet Paw - Security/Fight` with `Increase Heat`, `Suspicion`, `Alert`, `Resolve`, and `Hostile/Fight` actions.
- Added reusable `GameState.increase_venue_heat()` and `MissionAlertController.resolve_alert()` APIs. Heat changes refresh the live Velvet camera posture.
- Lengthened the four watched objective theft holds from 1.0-1.25 seconds to 1.5-1.75 seconds.
- Preserved west-bar glass clearing as the immediate `velvet_paw_new_staff` cover source. Main-floor guards and automatic floor inspection continue to honor that cover before table-service completion.
- Added three visible one-shot table interactions at `(896,2176)`, `(1664,2176)`, and `(2368,2176)`. They require the west-bar task and set independent table facts.
- Added aggregate `vpj_three_tables_cleared`. It opens the bathroom-to-stage service doorway, participates in VIP gate opening, and is required by VIP protocol.
- VIP gate now requires active barback cover, all three table runs, and Bentley parked at the exact marker. Added fixed north rail `(2624,1312)`, size `(64,576)`, to close the prior geometric bypass.
- Added `StageServiceDoorBlocker` at `(608,928)`, size `(64,192)`, matching the room-right-of-bathroom doorway.
- Kept the VIP voicemail at the in-booth phone `(2816,2304)` but made it hidden/non-collidable until protocol completes. Collection grants `VIP Voicemail Copy` to mission inventory.
- Objective pickups now provide readable display names in pause inventory. Blackmail briefcase now grants an inventory entry. Polaroid collection mirrors the persistent collectible into attempt inventory.
- Blueprint expanded from 68 to 71 slots and from seven to eight dynamic blocker contracts; generated build guide refreshed.
- Preserved the pre-existing scene label edits to VIP camera and guard author labels.

## Files

- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
- `src/autoload/GameState.gd`
- `src/collectibles/polaroid_pickup.gd`
- `src/missions/iso/authoring/mechanics/InventoryPickupNode.gd`
- `src/missions/iso/runtime/MissionAlertController.gd`
- `src/missions/iso/runtime/MissionQAChecklistPanel.gd`
- `src/missions/iso/runtime/VelvetPawJazzClubMissionController.gd`
- `docs/blueprints/velvet_paw_jazz_club.blueprint.json`
- `docs/blueprints/velvet_paw_jazz_club.build_guide.md`
- `tests/mission_authoring/LevelBlueprintLayoutPainterTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubPhysicsTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubRuntimeQATest.gd`
- `tests/mission_authoring/VelvetPawRouteComponent2Test.gd`

## Validation

- Production scene startup: PASS, two-frame headless smoke.
- Blueprint validator: PASS, no failures or warnings.
- Focused Component 2/physics/runtime/production/camera suites: PASS, 55/55, zero orphans.
- Full `tests/mission_authoring`: 496/498 initially passed. The two failures were stale expected classifications for the newly dynamic bathroom service opening, not runtime failures. Updated that contract and reran `LevelBlueprintLayoutPainterTest`: PASS, 9/9.
- `git diff --check`: PASS except the existing generated build-guide CRLF normalization warning.

## Controller Status

This packet's original controller subset was superseded by the final Xbox/GameSir layout and physical-QA follow-up. The current contract uses A interact, B dodge/cancel, X poop-bag targeting, Y finisher, LB sprint, RB heavy, LT stealth, RT light attack/targeted throw, R3 Case the Joint, Start pause, and D-pad Bentley commands. See `reports/ai/2026-07-13_gamesir_nova_lite_controller_layout_report.md` for current status and remaining hardware checks.

## Manual QA

1. Fully restart Godot so current autoload scripts are active.
2. Use F12 -> `Velvet Paw - Security/Fight` to test heat, suspicion, alert, resolve, and hostile states.
3. Confirm first west-bar glasses grant cover, floor guards tolerate it, and floor inspection passes before any table runs.
4. Confirm all three table prompts are readable and require E/hold.
5. Confirm the bathroom service doorway remains blocked through two tables and opens after the third.
6. Confirm VIP cannot be bypassed north of the gate.
7. Confirm no partial combination opens VIP; barback cover, all three tables, and exact Bentley parking must all be complete.
8. Confirm protocol then reveals both the voicemail and polaroid inside VIP, and pause -> Inventory lists collected mission items.
9. Plug in a controller and verify the currently mapped subset above; report device-specific labels or focus problems.

## Remaining Risk

- Table positions and simple placeholder visuals require Jake's visual/readability approval.
- Physical controller and menu-focus testing was not available through headless automation.
- Audio loudness and collision feel remain manual checks.

## VIP Gate And Music Correction

User follow-up found two concrete scene/runtime defects after the initial packet.

- The current editor scene had moved the dynamic VIP gate to `(2624,1504)` and transformed the fixed rail into a thin strip near `x=2538`, leaving the actual `x=2624` boundary open. Restored the fixed rail to `(2624,1312)`, size `(64,576)`, and the sole gate to `(2624,1696)`, size `(64,192)`.
- Added one authoritative VIP prerequisite predicate: active `velvet_paw_new_staff` cover, all three table facts, and Bentley waiting at the exact marker within 72 px. The same predicate opens the collision gate and enables the protocol interaction.
- Moved the smaller protocol footprint entirely inside VIP and made it disabled, non-monitoring, and non-colliding until all three prerequisites pass.
- Restored phone `(2816,2304)` and polaroid `(2944,2304)` inside the booth. Protocol success now immediately enables both; the polaroid no longer depends on voicemail and now rejects interaction while hidden.
- Unparked Bentley in the VIP camera approach now emits an initial retreat/park warning and a final warning at suspicious state. The camera accumulates while the player stands still and alert still routes to the VIP reinforcement response.
- Exact music root cause: the physical staff doorway spans `x=2880..3072`, but its entry trigger covered only `x=2880..3008`; the floor-music volume also ended near `x=3012`. A right-side crossing could miss both while direct-activation tests passed. The entry trigger now covers the full opening with tolerance, the music volume covers that doorway, and the controller reconciles physical entry from the club-interior position.
- `AudioManager` explicitly initializes its owned Music bus unmuted at 0 dB and exposes cue, stream, playback position, player volume, Music bus, and Master bus diagnostics in F12.
- Added a physical right-edge crossing regression that proves `vpj_entered_club`, `velvet_paw_floor`, the Paolo Argento stream, active playback, and an unmuted 0 dB Music bus.

Correction validation:

- Four-suite focused run: all non-runtime suites passed; the new crossing test initially stopped on the street side and was corrected to traverse fully through the doorway.
- Final `VelvetPawJazzClubRuntimeQATest`: PASS, 14/14, zero errors/failures/orphans.
- Production scene headless startup: PASS.

Controller truth after the later GameSir pass is maintained in the dedicated controller report; the original inspection above is historical and no longer describes the final action map.

## Pre-commit Checkpoint 2026-07-13

- Final combined Component 2/controller gate: 79/81 test cases passed across eight suites; controller suites passed 9/9.
- Four assertion failures across two test cases all identify `VipNorthRailBlocker/RightRailShape` scene drift.
- Saved scene value: position `(2992,1600)`, size `(32,384)`.
- Blueprint/test contract: position `(3008,1600)`, size `(64,384)`.
- Physics, camera, guard, runtime QA, and controller suites otherwise pass.
- This state is a test-needed checkpoint and not Component 2 completion/sign-off. XML evidence: `reports/report_130/results.xml`.
