# Velvet Paw Guard Collision Checkpoint 1

Date: 2026-07-13
Mode: Narrow checkpoint inside the grouped Velvet Paw repair milestone
Status: Guard packet complete; production-scene drift blocks the next scene-editing packet

## Goal

Repair the shared production guard collision contract, make guard sight respect layer-4 walls, replace position-teleport knockback with collision-aware movement, and prove both startup and reinforcement guards use the corrected behavior.

## Changes

- `scenes/characters/guard.tscn`
  - Changed the guard body from player layer 1/mask 3 to enemy layer 2/mask 7.
- `src/enemies/EnemyBase.gd`
  - Changed LOS ray mask from 3 to 5 so rays query player layer 1 and wall layer 4.
  - Deferred damage knockback out of `MeleeHitbox.body_entered` physics callbacks and applied it through `move_and_collide`.
- `tests/mission_authoring/GuardBehaviorTest.gd`
  - Replaced the old layer-2 LOS blocker with a real layer-4 wall.
  - Added production packed-scene collision contract checks.
  - Added a real `CharacterBody2D` versus layer-4 `StaticBody2D` blocking test.
  - Added wall-stopped damage knockback coverage.
  - Added live Velvet checks for at least six startup guards and three VIP reinforcement guards using layer 2/mask 7.
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
  - Recorded the guard contract, validation, and current scene-drift blocker.

No navigation/pathfinding manager or compatibility layer was added. Existing patrol, investigation, and chase movement continues to use `move_and_slide`; guards now stop or slide against walls rather than pass through them.

## Validation

- Focused GdUnit final run: PASS, 14/14, zero errors, failures, skips, flaky cases, or orphans.
- Real physics proof: PASS for body blocking, LOS occlusion, and deferred knockback against layer-4 `StaticBody2D` walls.
- Production spawn proof: PASS for six or more ambient startup guards and three or more VIP response guards using layer 2/mask 7.
- Velvet production scene smoke: PASS, 120 headless frames; mission started and loaded with production guards.
- `git diff --check` for checkpoint files: PASS.
- Godot DAP: not needed; no unexplained runtime failure remained.
- Godot MCP Pro: not available in this OpenCode tool session; terminal Godot/GdUnit validation was used.
- GdUnit report artifacts were removed and the tracked historical report index was restored after testing.

The first knockback assertion expected exact contact at x=16.0 and observed Godot's normal safe-margin separation at x=15.9878. The assertion was corrected to validate the near side of the wall without depending on subpixel contact resolution.

## Scene Drift Blocker

The broader Component 2 run reached 13 passing guard tests, then stopped on five pre-existing production-scene contract failures. The current disk scene reports:

- Protocol position `(2824,1545)` instead of `(2784,1664)`.
- VIP phone visible instead of hidden.
- VIP gate shape `(24,128)` instead of `(64,192)`.
- North rail position approximately `(2623.75,1480)` instead of `(2624,1312)`.
- North rail size `(13.5,236)` instead of `(64,576)`.

This matches the handoff's unsaved-editor warning and indicates the editor-origin copy has reached disk since the prior validated correction. This checkpoint did not edit or restore `VelvetPawJazzClub_Editable.tscn`. The scene must be reconciled deliberately before the VIP countdown or SearchZone packet changes it.

## Safety And Continuity

- Existing unrelated and prior Velvet Paw changes were preserved.
- No files outside the repository were accessed or modified.
- No secrets or personal data were accessed.
- No commit, stage, push, branch change, reset, or history operation was performed.

## Next Step

Resolve the open/saved production-scene divergence first. After the intended scene state is preserved, continue with the six-second VIP camera exposure, countdown ring, and no-early-reinforcement packet.
