# GameSir Nova Lite Controller Layout

Date: 2026-07-13
Mode: Narrow request-specific controller packet, not a roadmap stage transition
Status: Automated implementation complete; first physical GameSir pass recorded and focused retest remains

## Goal

Provide a coherent Xbox/XInput layout for a GameSir Nova Lite while preserving the existing keyboard and mouse controls, making controller prompts player-facing, and closing controller-only interaction gaps.

## Input Contract

- Left Stick: move.
- Right Stick: aim poop-bag targeting.
- A: interact, advance dialogue, and accept focused UI.
- B: dodge during gameplay, cancel targeting, close dialogue, and cancel/back in UI.
- X: enter or leave poop-bag targeting.
- Y: finisher.
- LB: sprint.
- RB: heavy attack.
- LT: stealth.
- RT: light attack or throw a targeted poop bag.
- R3: Case the Joint.
- Menu/Start: pause or resume.
- D-pad Left/Up/Right/Down: Bentley bark/sniff/fetch/stay-heel.
- Enter and Space remain UI accept inputs; Escape remains UI cancel and pause.

## Changes

- `project.godot`
  - Added the right-stick aim actions and the Xbox/XInput bindings above.
  - Added explicit `ui_accept` A/Enter/Space and `ui_cancel` B/Escape contracts.
  - Removed the obsolete generic gamepad binding from `bentley_ability` to prevent duplicate Bentley commands.
- `src/utils/InputBindingFormatter.gd`
  - Added one semantic formatter for Xbox buttons, sticks, triggers, keyboard keys, and mouse buttons.
  - Interaction prompts now convert authored `Press E` and `[E]` text to combined controller/keyboard labels.
- `src/player/Player.gd`
  - Added right-stick poop-bag aiming, a visible world reticle, RT throw, and B cancel without changing mouse targeting.
  - Prevented R3 Case the Joint from firing while targeting.
- `src/combat/PlayerCombatController.gd`
  - Routed RB through the existing heavy attack and blocked combat while poop-bag targeting is active.
- `src/player/DogCompanion.gd`
  - Prevented D-pad commands while paused, in dialogue, under blocking UI, or while player control is disabled.
- `src/missions/iso/runtime/authoring/MissionInteractionBridge.gd`
  - Applied controller-aware interaction prompt formatting at the shared production bridge.
- `src/ui/DialogueBox.gd`, `src/ui/HUD.gd`, `src/ui/test_ui/controls_overlay.gd`, and `src/ui/test_ui/pause_menu.gd`
  - Replaced raw button numbers and keyboard-only instructions with semantic combined labels.
  - Added controller-aware dialogue advance/close hints and B close behavior.
  - Kept Menu/Start as the pause toggle while B only closes an already-open pause menu.
- Interaction pickup paths now expose availability/display metadata needed by the shared interaction and prompt surfaces.
- `tests/mission_authoring/ControllerInputLayoutTest.gd`
  - Added exact binding assertions, A/Enter/Space UI acceptance, semantic label tests, RB heavy dispatch, controller poop-bag targeting, and blocked-UI Bentley command coverage.
- Updated affected prompt expectations in `CaseJointHintProviderTest.gd` and `TimedDialoguePresentationTest.gd`.

## Physical QA Follow-up

Jake's first physical pass confirmed Left Stick, A, B dodge/dialogue close, LB sprint, LT stealth, RT light attack, Menu/Start pause, and D-pad Left/Up/Down.

The pass also exposed misleading or silent behavior rather than additional binding failures:

- X, Right Stick aim, and RT throw were tested with zero poop bags. Targeting intentionally requires at least one bag, so X correctly refused to enter targeting and Right Stick had no target to move.
- D-pad Right fetch requires a fetchable interactable within Bentley's range. The command already returned `Nothing nearby to fetch`, but the HUD replaced that feedback immediately.
- RB reached the heavy code path, but heavy reused the `quick_attack` cue and had no distinct impact feedback, making it look like another light attack.
- B resumed gameplay even when a pause-menu info subpanel was open, rather than backing out to the pause root first.
- Y silently rejected attempts before the STYLE meter was full.

Follow-up corrections:

- Contextual action feedback now remains visible in the HUD for 1.8 seconds, including no-bag, no-fetch-target, and finisher-not-ready messages.
- X without inventory now reports `No poop bags. Pick one up before targeting.`
- RB now records the heavy path, emits the distinct `heavy_attack` cue, and triggers stronger impact shake.
- B closes an open Objectives/Scheme Cards/Clues/Inventory/Controls subpanel and restores focus first; a second B at the pause root resumes gameplay.
- Y before full STYLE now reports the current STYLE amount instead of failing silently.

## Validation

- Relevant unique GdUnit coverage: PASS, 53/53.
- `ControllerInputLayoutTest`, `CompanionCommandPointTest`, and `CaseJointHintProviderTest`: PASS, 23/23; `reports/report_124/results.xml`.
- Follow-up `ControllerInputLayoutTest` and `VelvetPawControllerCheckpointTest`: PASS, 9/9; `reports/report_128/results.xml`.
- Expanded follow-up controller/production-adjacent gate: PASS, 39/39 across 6/6 suites; `reports/report_129/results.xml`.
- `TimedDialoguePresentationTest` and `PhaseD6PlayerFacingPolishTest`: PASS, 12/12; `reports/report_126/results.xml`.
- Production `VelvetPawJazzClubRuntimeQATest`: PASS, 14/14.
- Production `VelvetPawControllerCheckpointTest`: PASS, 3/3.
- The last two production suites are recorded in `reports/report_125/results.xml`.
- Main-menu headless smoke: PASS; `MainMenu.tscn` loaded and ran for 120 frames without script or parse errors.
- Production mission headless smoke: PASS; `VelvetPawJazzClub_Editable.tscn`, HUD, dialogue, controls overlay, pause menu, player, Bentley, cameras, and guards loaded and ran for 120 frames without script or parse errors.
- Follow-up production mission smoke after the physical-QA corrections: PASS for 120 frames. A separate running Godot process already owned MCP port `9090`, producing the known non-gameplay bind warning.
- Final combined pre-commit gate: controller suites PASS, 9/9. Across eight Component 2/controller suites, 79/81 test cases passed; the four assertions in two failed Component 2 cases all concern the unrelated VIP right-rail scene drift. XML evidence: `reports/report_130/results.xml`.
- Scoped `git diff --check`: PASS.

## Separate Existing Failure

The production skeleton and Component 2 contract gates are not fully green. `RightRailShape` is saved at `(2992,1600)`, size `(32,384)`, while the blueprint/tests require `(3008,1600)`, size `(64,384)`. This produces four assertions across two test cases.

That failure concerns concurrently modified VIP enclosure geometry in `VelvetPawJazzClub_Editable.tscn` and its skeleton test, not controller input or UI behavior. Those unrelated changes were preserved and not modified in this packet.

## Remaining Hardware Retest

- Pick up at least one poop bag, press X, confirm the green target reticle appears, aim it with Right Stick, then press RT to throw or B to cancel.
- Press X with zero bags and confirm the no-bag message remains readable.
- Stand near a fetchable pickup and press D-pad Right; also test away from pickups and confirm `Nothing nearby to fetch` remains readable.
- Compare RT light attack with RB heavy and confirm RB now has the heavier delayed impact/shake.
- Open a pause subpanel, press B once to return to pause, then press B again to resume gameplay.
- Fill the HUD STYLE bar with several attacks, confirm the `Finisher ready - press Y / R` hint, and press Y. Press Y before full STYLE and confirm the not-ready message.
- Press R3 by clicking the right analog stick inward and confirm the Case the Joint pulse/hint response.

## Safety And Continuity

- This stayed in a narrow request-specific slice rather than grouped-milestone mode because it did not change roadmap phase status or system architecture.
- No new global input manager or compatibility layer was introduced.
- Existing scene paths, authored action names, keyboard/mouse bindings, and unrelated dirty worktree changes were preserved.
- No roadmap or blueprint files were changed by this packet.
- No commit, stage, push, branch change, reset, or history operation was performed.
