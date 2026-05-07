# Taco Bell Birthday Build Checkpoint — Known Limitations

Generated: Wednesday, May 6, 2026, 8:41 PM UTC-4

## Scene To Use

`res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

## Protected Source Scene

`res://scenes/missions_iso/TacoBellIso_Editable.tscn`

## Current Status

**PLAYABLE_WITH_KNOWN_LIMITATIONS**

Taco Bell is good enough to park for the birthday build and move on to the HideoutHub production scaffold. The user has decided to stop iterating on guard/camera/bounds edge cases for now.

## Working Systems

- Delivery bag is inside the bag room, reachable, visible, and interactable.
- Picking up the delivery bag completes/updates the delivery bag objective.
- Objectives update in the pause menu.
- Running active/completed objective list was implemented.
- Louis recognizes when the player has the bag.
- Louis exit worked well in manual testing.
- Louis completes/ends the mission through the mission result flow.
- Code gate has three options.
- Wrong code gives feedback.
- Correct code `0420` unlocks the gate.
- Bentley key 3 no longer crashes.
- Bentley fetches appropriately.
- Camera cones exist in the mission.
- Guards exist in the mission.
- Wall collision works and has repeatedly validated at `2368` shapes.
- Counts remain set-derived and monotonic.
- Red HUD/debug text is readable.
- Purple labels/icons are useful enough for current testing.
- Pause menu objective data source is populated.

## Parked Known Limitations

- Newly spawned guards do not reliably attack the player.
- Some camera cones do not reliably spawn/dispatch guards when the player stands in visibility cones.
- Tokens, marker labels, and marker tiles still exist outside the walkable/walled mission area.
- Bounds cleanup is not fully persisted for `MarkerTileLayer` / `MarkerRoot` authoring markers.
- Guard/camera behavior is acceptable enough to move on, but needs post-birthday polish.
- Taco Bell is playable enough to park for now, but not fully final.

## Do Not Touch Before Hideout

- Do not continue guard AI polish before starting hideout.
- Do not continue camera dispatch polish before starting hideout.
- Do not continue bounds cleanup before starting hideout unless it blocks testing.
- Do not expand Taco Bell mechanics.
- Do not rebuild or repaint the map.
- Do not change wall collision.
- Do not change mission completion logic unless it breaks.
- Do not replace the current Taco Bell duplicate with the protected source scene.

## Recommended Next Step

**0M-A — HideoutHub production scaffold**

## Immediate Build Order

1. 0M-A HideoutHub production scaffold
2. 0M-B Hideout visual dressing
3. 0N Title screen/start loop
4. 0L Taco Bell Monogon visual dressing if time
5. Final QA/export

## Post-Birthday Fix List

- Real guard attack/chase reliability.
- Camera cone detection → guard dispatch.
- Persisted `MarkerTileLayer` / `MarkerRoot` bounds cleanup.
- Generalized editor contract for `GUARD` / `PATROL` / `CAM` markers.
- Art pass cleanup.
- Remove or debug-toggle labels once final art is in.

## Files Changed / Dirty State

Modified files from `git status`:

- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/autoload/QuestManager.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `src/player/DogCompanion.gd`
- `src/ui/test_ui/pause_menu.gd`

Untracked files are mostly Taco Bell phase reports/backups, Phase0J/Phase0K runtime helper scripts, and editor runner scripts. Important untracked groups:

- `docs/reports/taco_bell_phase_0j*`
- `docs/reports/taco_bell_phase_0k*`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0*.tscn`
- `src/missions/iso/runtime/Phase0J*.gd`
- `src/missions/iso/runtime/Phase0K*.gd`
- `src/tools/editor/TacoBellPhase0J*.gd`
- `src/tools/editor/TacoBellPhase0K*.gd`

See `res://docs/reports/taco_bell_birthday_build_checkpoint_file_inventory.md` for the full freeze inventory.

Warning: many `.uid` files and scene backups are untracked. Inspect before committing so accidental backups/runtime artifacts are not included unless intentionally desired.

## Source Scene Protection

Source scene appears untouched in git status.

`res://scenes/missions_iso/TacoBellIso_Editable.tscn` is not listed as modified.

## Wall Collision

Wall collision remains preserved according to recent reports:

- Path: `GameplayRoot/GeneratedRuntimeCollision/WallCollision`
- Expected count: `2368`
- Recent reports repeatedly validated before/after count as `2368`.

## Commit Recommendation

Suggested commit message:

`Checkpoint Taco Bell birthday mission loop`

## Manual QA Checklist

- Delivery bag works.
- Objective menu updates.
- Code gate works.
- Louis completes mission.
- Bentley key 3 does not crash.
- Wall collision works.
- No critical crash appears in the recent reports.
- Known guard/camera/bounds limitations are accepted for the birthday build.

## Freeze Decision

Move on now. Taco Bell should be treated as frozen for the Hideout/Title sprint unless a critical crash blocks testing.
