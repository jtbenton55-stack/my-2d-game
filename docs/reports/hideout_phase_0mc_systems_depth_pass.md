# HideoutHub Phase 0M-C Systems Depth Pass

Status: PASS

Backup: `res://scenes/hideout/HideoutHub.phase0mc_backup.20260507_011648.tscn`

Taco Bell scenes modified: no

## Summary

0M-C upgrades the working HideoutHub scaffold into a richer v1 systems scaffold while preserving layout, wall collision, player layering, station placement, interaction proxy placement, and the Mission Board launch path.

Runtime validation loaded `res://scenes/hideout/HideoutHub.tscn` cleanly, opened upgraded major panels, confirmed the Mission Board includes all 11 missions, confirmed Planning Table includes 10 cards, confirmed The Big Case includes clue state text, confirmed Store Terminal categories render, and confirmed Louis toggles visible in `louis_unlocked` and hidden in `fresh`.

## Files Created

- `res://scenes/hideout/HideoutHub.phase0mc_backup.20260507_011648.tscn`
- `res://src/hideout/HideoutStateController.gd`
- `res://src/tools/editor/HideoutPhase0MCValidator.gd`
- `res://docs/reports/hideout_phase_0mc_systems_depth_pass.md`
- `res://docs/reports/hideout_phase_0mc_systems_depth_pass.json`

## Files Modified

- `res://scenes/hideout/HideoutHub.tscn`
- `res://src/hideout/HideoutStationCatalog.gd`
- `res://src/hideout/HideoutManager.gd`
- `res://src/hideout/HideoutMissionBoardController.gd`
- `res://src/hideout/HideoutEvidenceBoardController.gd`
- `res://src/hideout/HideoutSchemeCardController.gd`
- `res://src/hideout/HideoutCollectibleController.gd`
- `res://src/hideout/HideoutCareController.gd`
- `res://src/hideout/HideoutStoreController.gd`
- `res://src/hideout/HideoutCharacterController.gd`
- `res://src/hideout/HideoutDebugController.gd`

## Feature Summary

State model: `HideoutStateController` tracks mission, evidence, collectibles, scheme cards, care flags, store state, character state, heat, and debug state. It is scene-local and ready for later SaveManager persistence.

Mission Board: now generates 11 mission rows from catalog data and Taco Bell status from the state controller. Fresh Taco Bell shows start/info/back only; completed states show replay, missing-item, and lower-heat options. Launch path remains `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.

The Big Case: now renders clue entries with state labels and supports review, mark-reviewed, and missing-evidence views. Forbidden progression labels are absent.

Planning Table: now renders 10 scheme cards, 3 active slots, locked/unlocked state, equip actions, and clear loadout. Real mission effects remain intentionally deferred.

Collectibles: Polaroid, Glow Guy, Tiny Icon, Poop Bag, and trophy data are state-aware with found/missing text and arrange-later feedback.

Bentley Care: care actions update local state flags and refresh panel text for paws, treat, brush, poop bags, sauce cleanup, and mood.

Store Terminal: categories and 8 Taco Bell-themed items now render with unlock/purchased state. Purchases update scene-local placeholder state only.

Character Dialogue: Bentley, Jake, Mere, and Louis lines react to debug state. Louis remains hidden/locked in fresh and visible/unlocked in Louis state.

Debug States: Fresh, Taco Bell Completed, Taco Bell Completed Missing Items, High Heat, and Louis Unlocked apply coherent state and refresh visible panels.

## Button Action Routing

- `launch_taco_bell`: launches Taco Bell RedesignTest, implemented.
- `replay_mission`: launches Taco Bell RedesignTest as replay, implemented.
- `show_known_info`: shows known mission info, implemented.
- `search_missing_items`: shows placeholder missing-item search feedback, placeholder.
- `view_missing_items`: shows mission missing-item summary, implemented.
- `lower_heat_run`: shows completed-mission lower-heat placeholder feedback, placeholder.
- `clean_getaway_attempt`: shows clean getaway placeholder feedback, placeholder.
- `view_results`: shows local debug result summary, implemented.
- `show_evidence`: shows clue detail view, implemented.
- `mark_evidence_reviewed`: sets reviewed flag and refreshes board, implemented.
- `show_missing_evidence`: shows missing clue view, implemented.
- `show_scheme_cards`: shows card catalog, implemented.
- `show_active_slots`: shows active loadout slots, implemented.
- `equip_scheme_card`: equips card into state slot, implemented.
- `clear_loadout`: clears active slots, implemented.
- `care_wipe_paws`: sets `bentley_wiped`, implemented.
- `care_give_treat`: sets `treat_packed` and mood, implemented.
- `care_brush`: sets `bentley_brushed`, implemented.
- `care_restock_poop_bags`: sets `poop_bags_stocked`, implemented.
- `care_view_poop_bags`: shows poop bag collection state, implemented.
- `show_collection`: shows found/missing/arrange views, implemented.
- `show_store_category`: shows category contents, implemented.
- `buy_store_placeholder`: updates purchased item local state, implemented.
- `show_placement_zones`: shows placement placeholder text, placeholder.
- `view_heat`: shows current heat state, implemented.
- `talk`: cycles/shows character dialogue, implemented.
- `inspect`: safe generic feedback, placeholder.
- `unknown_placeholder`: safe fallback feedback, placeholder.
- `close`: closes panel, implemented.

## Validation

- Godot runtime launch: PASS.
- HideoutHub scene load: PASS.
- Runtime errors after final load and checks: 0.
- Mission Board 11 missions content check: PASS.
- Planning Table 10 card content check: PASS.
- Evidence clue content check: PASS.
- Store category content check: PASS.
- Louis visible in `louis_unlocked`: PASS.
- Louis hidden in `fresh`: PASS.
- Static forbidden label search in `src/hideout`: PASS.
- Validator script created: PASS.

## Manual Test Checklist

1. Open `res://scenes/hideout/HideoutHub.tscn`.
2. Press Play.
3. Confirm player movement/collision still work.
4. Open MissionBoard.
5. Confirm 11 missions appear.
6. Confirm Fresh Taco Bell has Start Mission and no heat controls.
7. Launch Taco Bell and confirm RedesignTest opens.
8. Reopen HideoutHub.
9. Toggle Taco Bell Completed.
10. Open MissionBoard and confirm replay/lower heat options appear for Taco Bell.
11. Open The Big Case.
12. Confirm clue list/state text appears.
13. Press Review Taco Bell Clues.
14. Press View Missing Evidence.
15. Open Planning Table.
16. Confirm 10 scheme cards appear.
17. Equip one Plan card, one Trick card, one Comfort/Chaos card if implemented.
18. Confirm active slots update or show placeholder feedback.
19. Open Polaroid Wall.
20. Confirm found/missing view works.
21. Open Glow Guy Shelf.
22. Confirm found/missing view works.
23. Open Tiny Icon Shelf.
24. Confirm found/missing view works.
25. Open Poop Bag Display.
26. Confirm found/missing/restock info works.
27. Open Bentley Care Station.
28. Press Wipe Paws, Give Treat, Brush, Restock.
29. Confirm feedback/state text changes.
30. Open Store Terminal.
31. View multiple categories.
32. Try placeholder purchase if present.
33. Confirm feedback appears.
34. Interact with Bentley, Jake, Mere.
35. Toggle High Heat and confirm their dialogue changes.
36. Toggle Louis Unlocked.
37. Interact with Louis.
38. Confirm Louis dialogue appears.
39. Toggle Fresh and confirm Louis hides.
40. Confirm every panel closes.
41. Confirm E still works after closing panels.
42. Confirm no required popup is empty.
43. Confirm no forbidden Sterling progression labels appear.
44. Confirm no Taco Bell scene was modified.

## Known Placeholders

- Purchases are scene-local/debug only, not final economy or save persistence.
- Scheme cards update loadout state but do not affect mission gameplay.
- Lower Heat Run, Clean Getaway Attempt, and missing-item search are visible replay scaffolds.
- Decoration placement remains an arrange-later/placement-zone scaffold.
- Full selected-mission UI is represented by an expanded Taco Bell details block rather than a navigable mission selector.

## Risks / Fragile Areas

- The runtime state is scene-local. It will reset unless later wired to SaveManager.
- Panel action routing is centralized in `HideoutManager`; adding new actions requires updating the allowlist and match handler.
- Debug-state combinations are presets, not layered toggles. Louis state currently replaces the active preset.
- Manual E-interaction coverage still needs a full walkaround test after these script changes.

## Recommended Next Step

If manual systems test passes: 0M-B — Hideout visual dressing / Monogon-style prop pass.

If manual systems test fails: 0M-C2 — focused system content/action fix.
