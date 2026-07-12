# Velvet Paw Route Component 2 Security/Playability Report

Date: 2026-07-12
Mode: Grouped-milestone mode retained
Status: Automated closeout pass; manual production QA remains

## Scope

- Converted cameras from cosmetic/always-on behavior to a Velvet-opt-in suspicious-action policy.
- Replaced immediate radial guard aggression with facing-cone LOS awareness, buildup, decay, social-cover tolerance, and noise investigation.
- Authored every requested main-map camera location and four additional patrol routes.
- Repaired Bentley's wait marker, VIP protocol payoff, voicemail dead drop/evidence clue, separate VIP polaroid, and music playback wiring.

## Runtime Contracts

- Normal starting heat plus innocent cone occupancy does not accumulate camera exposure.
- Raised starting heat is immediately camera-actionable.
- Staff badge, ledger shard, basement keycard, and blackmail briefcase use hold-to-steal windows registered as `theft`.
- Manual sneak, hide-forced sneak, or `mission_hidden` protects theft from camera accumulation.
- Camera gameplay LOS and visible ray-fan cones clip against collision layer 4 and populated `CoverLayer` cells.
- Guards detect only inside their facing cone with LOS and threshold buildup; detection decays before awareness.
- Ambient floor guards use `Resource_vpj_floor_inspection_rules`; two rear-room patrol guards set `ignore_social_cover = true`.
- Guard noise listeners investigate decoys immediately, accumulate bark/player noise, inspect for three seconds, and resume the saved patrol waypoint.
- Bentley wait state records marker ID and world position. VIP protocol requires `velvet_paw_jazz_club.bentley_wait_marker.01` within 72 pixels.
- The VIP phone requires `vpj_vip_protocol_complete`, grants the voicemail copy, and shows Mere's dead-drop instruction.
- Dead-drop completion removes the copy and records evidence clue `velvet_paw_vip_voicemail` for the clue board.
- `velvet_vip_champagne_polaroid` is separate from mission-completion and stage polaroids and appears after VIP protocol.
- Floor and escape music zones register real streams; runtime tests verify `AudioManager.is_music_playing("velvet_paw_floor")`.

## Production Authoring

- 12 authored camera nodes are active at runtime, plus two pre-existing definition-generated cameras.
- 6 patrol routes contain 20 collision-clear waypoints.
- 6 initial patrol guards spawn: four socially tolerant floor guards and two rear-room attack-on-sight guards.
- The existing alarm reinforcement spawn remains event-driven and unchanged.
- Camera and guard post-startup reconciliation is mission-local and preserves the existing global lifecycle contracts.

## Files Changed In This Packet

- `scenes/characters/guard.tscn`
- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
- `src/collectibles/CollectibleManager.gd`
- `src/enemies/EnemyBase.gd`
- `src/enemies/Guard.gd`
- `src/missions/iso/authoring/GuardSpawnAuthor.gd`
- `src/missions/iso/authoring/SecurityCameraAuthor.gd`
- `src/missions/iso/authoring/mechanics/HideSpotNode.gd`
- `src/missions/iso/authoring/mechanics/MechanicAreaBase.gd`
- `src/missions/iso/authoring/mechanics/ProtocolZone.gd`
- `src/missions/iso/runtime/MissionAlertController.gd`
- `src/missions/iso/runtime/MissionSecurityCamera.gd`
- `src/missions/iso/runtime/VelvetPawJazzClubMissionController.gd`
- `src/player/DogCompanion.gd`
- `src/player/Player.gd`
- `tests/mission_authoring/GuardBehaviorTest.gd`
- `tests/mission_authoring/VelvetCameraDetectionPolicyTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd`
- `tests/mission_authoring/VelvetPawJazzClubRuntimeQATest.gd`
- `tests/mission_authoring/VelvetPawRouteComponent1Test.gd`
- `tests/mission_authoring/VelvetPawRouteComponent2Test.gd`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`

## Validation

- Focused grouped suites: 64/64 passed, zero errors/failures/orphans.
- Full `tests/mission_authoring`: 495/495 passed, zero errors/failures/flaky/skipped/orphans.
- Production runtime smoke: `godot --headless --path . --quit-after 120 scenes/missions_iso/VelvetPawJazzClub_Editable.tscn` passed and spawned cameras/guards.
- `git diff --check`: no whitespace errors; only the existing build-guide CRLF normalization warning.

## Remaining Manual QA

- Confirm camera cone colors, sweep timing, wall/cover clipping, and pickup timing feel at gameplay zoom.
- Confirm normal-heat standing in a cone remains harmless and raised initial heat is vigilant.
- Confirm sneaking and hide zones both protect watched theft in production play.
- Confirm staff cover suppresses floor guards but not the two rear-room guards.
- Confirm decoy and repeated Bentley bark investigation/resume behavior feels readable.
- Confirm Bentley parks at the exact marker and key 4 elsewhere does not satisfy VIP protocol.
- Confirm floor/escape music is audibly mixed on the Music bus, not merely playing in runtime state.
- Confirm Mere's phone/dead-drop dialogue, clue-board evidence, and the champagne polaroid presentation.
- Additional camera density in teleported owner-suite/basement islands remains deferred per Jake's instruction.
