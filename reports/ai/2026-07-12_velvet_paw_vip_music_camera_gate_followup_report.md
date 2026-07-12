# Velvet Paw VIP Music, Camera, and Gate Follow-up

Date: 2026-07-12
Mode: Grouped repair packet retained
Status: Implemented and automation-complete; manual feel/audio QA remains

## Goal

- Start the registered jazz-floor cue when the player enters the club through the authored side door.
- Make only the VIP camera pause accumulated exposure while the player stands still and resume from the retained value when movement resumes.
- Keep the only left-side VIP entrance physically blocked until Bentley is parked at the exact authored wait marker while preserving protocol and phone objective ordering.

## Ownership and Implementation

- `AudioManager` remains the only music player and already rejects duplicate same-cue playback.
- `VelvetPawJazzClubMissionController` reconciles club-entry music against the entered-club fact and treats both `normal` and cleared `resolved` alert states as safe for playback. Suspicious, alerted, and hostile states still stop music.
- `MissionSecurityCamera` and `SecurityCameraAuthor` gained opt-in movement-sensitive exposure settings. Defaults remain disabled, so other cameras preserve prior behavior.
- The Velvet VIP camera alone enables movement-sensitive exposure with an 8 px/s threshold. Its local exposure value freezes instead of decaying while an otherwise actionable player stands still.
- The existing mission-local VIP gate reads Bentley's marker-specific command state. It opens only when the wait marker ID matches `velvet_paw_jazz_club.bentley_wait_marker.01` and Bentley remains within 72 px of the recorded wait position.
- `ProtocolZone` still requires both `velvet_paw_new_staff` cover and the exact Bentley wait state. The VIP phone still requires protocol completion.
- The existing `VipProtocolGateBlocker` geometry remains the sole opening blocker; no new manager or duplicate progression state was added.

## Files Changed In This Follow-up

- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
- `src/missions/iso/authoring/SecurityCameraAuthor.gd`
- `src/missions/iso/runtime/MissionSecurityCamera.gd`
- `src/missions/iso/runtime/VelvetPawJazzClubMissionController.gd`
- `tests/mission_authoring/VelvetCameraDetectionPolicyTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubPhysicsTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubRuntimeQATest.gd`
- `tests/mission_authoring/VelvetPawRouteComponent2Test.gd`
- `docs/blueprints/velvet_paw_jazz_club.blueprint.json`
- `docs/blueprints/velvet_paw_jazz_club.build_guide.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`

## Validation

- Focused camera, route-component, and physics suites: 23/23 passed, zero errors/failures/orphans (`reports/report_111/results.xml`).
- Focused runtime QA after side-door coverage: 9/9 passed, zero errors/failures/orphans (`reports/report_119/results.xml`).
- Full `tests/mission_authoring`: 499/499 passed across 64 suites, zero errors/failures/flaky/skipped/orphans (`reports/report_120/results.xml`).
- Blueprint validator: PASS, zero failures/warnings.
- Mission Dock static validator: PASS, zero failures/warnings.
- Standalone 120-frame headless production scene smoke: PASS; scene, MP3 stream, cameras, and guards loaded without script or scene errors.
- `git diff --check`: no whitespace errors; only the existing build-guide CRLF normalization warning.
- Godot DAP was not needed because no unexplained runtime exception or state failure remained.
- Kimi K2.6 was not available or used.

## Safety and Scope

- Work remained inside the authorized repository.
- No project settings, autoload declarations, branches, commits, staging, pushes, or history were changed.
- Pre-existing dirty work was preserved.
- GdUnit pruned tracked legacy report folders during validation; only those test-generated deletions were restored from the index.

## Remaining Manual QA

- Confirm the music is audible at the intended Music-bus mix when crossing the side-door threshold.
- Confirm stopping inside the VIP cone feels fair and that controller drift does not resume exposure.
- Confirm parking Bentley visibly opens the left-side gate, cover-less protocol remains blocked, cover plus parking completes protocol, and the phone remains locked until that completion.
- Confirm no alternate collision route reaches the VIP lounge around the existing perimeter and booth geometry.

## Manual Feedback Repair

- Moved `VipChampagnePolaroid` from the upper VIP edge at `(3008, 1792)` to `(2944, 2304)` beside the VIP phone.
- The polaroid now requires both `vpj_vip_protocol_complete` and `vpj_vip_voicemail_found`; otherwise it remains invisible, non-monitoring, and on collision layer 0.
- Shortened the VIP camera from 900 px to 520 px while preserving its movement-sensitive exposure behavior.
- `AudioManager` now guarantees the named `Music`, `SFX`, and `UI` buses it already targets. Both club entry zones directly notify the mission controller after successful activation so floor music starts immediately instead of depending only on polling.
- Focused camera/route/runtime QA: 22/22 passed with zero errors, failures, or orphans (`reports/report_121/results.xml`).
- Full `tests/mission_authoring`: 500/500 passed across 64 suites with zero errors, failures, flaky tests, skipped tests, or orphans (`reports/report_122/results.xml`).
- Standalone 120-frame production scene smoke loaded the mission and imported MP3 successfully; the already-running editor occupied MCP port 9090, producing the known non-gameplay socket warning.
- The earlier blueprint and Mission Dock validator results remain applicable because their contracts did not change. Their previously used script entrypoints are not present in this checkout, so this feedback pass could not rerun them.
- Audible speaker output remains a required fresh local playtest because headless automation can prove stream import, bus routing, entry callback, and active playback state but cannot prove physical output.
