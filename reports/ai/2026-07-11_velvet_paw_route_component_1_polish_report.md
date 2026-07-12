# Velvet Paw Route Component 1 Polish

Date: 2026-07-11

## Outcome

Applied the requested post-playtest polish before Route Component 2.

- Bouncer and Bentley rejection lines auto-advance after 2.5 seconds each.
- Enter closes any open dialogue, even when E advance and Skip are disabled.
- Bentley's alley line is `There are too many colognes. And none of them smell as good as my expression.`
- Seven mission-local room curtains keep all authored regions intact but reveal only the player's current region.

## Visibility Contract

The visibility regions use the existing blueprint rectangles for street, club main floor, bathroom, stage, backstage, owner suite, and basement. Curtains are opaque `Polygon2D` world visuals with no collision. The active curtain is hidden and all six inactive curtains are visible. Door and wall bands retain the previous valid region so crossing a threshold does not reveal the whole map. All Velvet teleport zones request an immediate refresh after moving the player.

This remains mission-local because no second production mission currently needs the contract. It does not reorganize scene nodes, clear TileMap data, alter collision, or change authored mechanics.

## Tests

- `TimedDialoguePresentationTest`: Enter dismissal and control-hint behavior.
- `VelvetPawRouteComponent1Test`: exact 2.5-second timing metadata.
- `VelvetPawJazzClubProductionSkeletonTest`: approved Bentley alley copy.
- `VelvetPawJazzClubRuntimeQATest`: all seven active regions, six concealed regions, doorway-band retention, non-colliding curtains, and clean teardown.

Final validation:

- Focused production skeleton: 19/19 PASS.
- Focused runtime QA: 8/8 PASS.
- Full `tests/mission_authoring`: 474/474 PASS across 61 suites with zero errors, failures, flakes, skips, or orphans.
- Blueprint validator: PASS for all three specs and 55 mechanic types with no failures or warnings.
- Direct production-scene headless smoke: 120 frames, exit 0.
- `git diff --check`: no whitespace errors; only the existing build-guide CRLF conversion warning remains.

## Manual QA

1. Confirm both rejection lines remain visible for approximately 2.5 seconds.
2. Press Enter during timed and normal dialogue and confirm the box closes immediately.
3. Trigger Bentley's alley dialogue and confirm the approved line exactly.
4. Walk from the street into the club and verify no inactive map region is visible from either side.
5. Visit the bathroom, stage, backstage, owner suite, and basement; verify only the occupied region is revealed and HUD/dialogue remain visible.

## Next Component

Proceed to Route Component 2: **Explore the Club Floor** after visual confirmation of curtain coverage and transitions.
