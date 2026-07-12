# Velvet Paw Route Component 2 Feedback Pass

Date: 2026-07-11
Status: implemented; manual visual/playable confirmation pending

## Scope

Addressed Jake's first Component 2 playtest feedback as one grouped packet: uninterrupted club music, visible cameras and patrol guards, readable protocol/cover/inspection feedback, wall-safe interactions, Bentley's dance-floor complaint, and a collision/object-label debug overlay.

## Changes

- Added stable music cue identity to `AudioManager` and `MusicTriggerZone`. Entering another zone with cue `velvet_paw_floor` leaves the current stream and playback position unchanged. Alarm or hostile/fight state stops the music.
- Added visible camera housing/lens presentation to generic runtime security cameras.
- Added opt-in initial guard spawning and Velvet's post-startup retry so two ambient patrol guards survive the base mission's startup security cleanup. Initial patrols are not tagged as alarm-response guards.
- Made the dance-floor inspection automatic. It visibly rejects players without `velvet_paw_new_staff` and accepts players after the west-bar believable task.
- Added visible dialogue feedback when clearing glasses establishes the new-barback cover.
- Clarified the protocol interaction: leave Bentley at the dance-floor edge and establish the new-staff cover before entering the VIP protocol area.
- Added Bentley's requested two dialogue lines to the wait marker.
- Added collision-layer line-of-sight filtering to all bridge-selected E interactions, preventing activation through walls or barriers.
- Hid the generic blueprint interaction marker at runtime; it has no intended player-facing behavior.
- Added a Velvet-only `Red Map Overlay` checkbox to the F12 QA menu. It outlines and labels walls, collision barriers, cover, interactables, mechanics, interaction zones, guards, cameras, the player, and Bentley.

## Validation

- `VelvetPawRouteComponent2Test.gd`: 3/3 pass with live two-guard/two-camera assertions and no timer workaround.
- Focused integrated suites: 50/50 pass.
- Full `tests/mission_authoring`: 478/478 pass, zero GdUnit orphans.
- Corrected F12 red-map-overlay focus: 6/6 pass, including checkbox state and an enabled render frame.
- Visual follow-up: the player and Bentley, including all child collision/detection areas, are fully excluded from overlay geometry and labels.
- Gameplay `Camera2D` view nodes are excluded from overlay geometry and labels; security cameras remain visible in the overlay.
- 180-frame headless Velvet scene smoke: pass; both guard scenes and runtime cameras load.
- The existing invalid imported-music UID warning remains non-blocking because Godot resolves the text path correctly.
- Two attempted validator commands used obsolete script paths and were not counted as validation. Existing full scene/blueprint suites passed.

## Manual QA

1. Enter normally and confirm floor jazz does not restart when crossing between same-cue floor zones.
2. Confirm two guards patrol and two camera bodies/cones are visible.
3. Enter the dance-floor inspection without cover and confirm automatic rejection dialogue.
4. Clear west-bar glasses, confirm cover feedback, then re-enter inspection and confirm acceptance.
5. Place Bentley at the dance-floor marker and verify both requested lines appear in order.
6. Attempt to use the formerly visible blue marker through the wall; it should be hidden and all other E targets should be wall-blocked.
7. Press F12, enable `Red Map Overlay`, and verify the complete red outlines and labels; disable the checkbox to hide them.
8. Trigger an alarm/fight and confirm house jazz stops.

## Risks And Next Step

- Camera and guard art is readable generic runtime presentation, not final production art.
- Overlay labels intentionally prioritize complete debugging coverage over player-facing polish.
- Component 2 remains pending Jake's manual confirmation. After confirmation, continue to Component 3, Acquire Staff Access.
- Work stayed in grouped-milestone mode.
