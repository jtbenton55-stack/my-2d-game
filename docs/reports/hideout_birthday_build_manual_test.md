# Hideout Birthday Build Manual Test

Scene: `res://scenes/hideout/HideoutHub.tscn`

Taco Bell launch target: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

Protected Taco Bell source scene: `res://scenes/missions_iso/TacoBellIso_Editable.tscn`

## Manual Test Checklist

1. Open `res://scenes/hideout/HideoutHub.tscn` directly in Godot.
2. Run the scene.
3. Confirm the player spawns near the southeast entry/care corner.
4. Move with the normal player controls.
5. Confirm the outer collision prevents walking through the garage/greenhouse boundary.
6. Walk to the generic `TEST INTERACTABLE`.
7. Press E/interact and confirm `ScrollableStationPanel` opens.
8. Confirm long text scrolls inside the panel and does not overflow off-screen.
9. Close the panel with Close, Back, or Escape.
10. Walk to every station and open/close each panel:
    - ENTRY / EXIT
    - BENTLEY CARE
    - LOOT CRATE
    - BENTLEY
    - JAKE
    - MERE
    - MISSION BOARD
    - THE BIG CASE
    - PLANNING TABLE
    - POLAROID WALL
    - GLOW GUY SHELF
    - TINY ICON SHELF
    - POOP BAGS
    - STORE
    - HEAT SCANNER
    - OPEN DECOR AREA
11. Confirm Bentley, Jake, and Mere are visible/interactable in Fresh state.
12. Confirm Louis is hidden in Fresh state.
13. Use `DebugHideoutPanel` buttons:
    - Fresh Hideout
    - Taco Bell Completed
    - Taco Bell Missing Items
    - High Heat
    - Louis Unlocked
14. Confirm Louis appears near StoreTerminal only in Louis Unlocked.
15. Confirm Taco Bell Completed changes collectible/evidence/store/care text or visual tint.
16. Confirm High Heat changes heat scanner / warning tint.
17. Open Mission Board in Fresh state.
18. Confirm there are 11 mission slots.
19. Confirm Taco Bell says friendly ready text and does not mention technical limitations.
20. Confirm Fresh mission actions are only Start Mission / View Known Info / Back.
21. Confirm there is no route selection.
22. Confirm there is no assist selection.
23. Confirm there are no heat controls for a fresh mission.
24. Press Start Mission and confirm it launches `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
25. Open Evidence Board.
26. Confirm title is `The Big Case`.
27. Confirm vague language is used.
28. Confirm these forbidden labels are absent:
    - Sterling Tower Progression
    - Sterling Syndicate Progression
    - Sterling Syndicate progression
29. Open Planning Table.
30. Confirm 3 active slots and 10 placeholder scheme cards are shown.
31. Confirm no scheme-card gameplay effects are implied as implemented.
32. Inspect the scene tree and confirm Monogon-ready separation:
    - gameplay under `GameplayRoot`
    - visuals under `ArtRoot/World`
    - collision under `GameplayRoot/Navigation/Collision`
    - replaceable props under `ArtRoot/World/PropLayer`
33. Confirm Monogon art is not required for gameplay.
34. Confirm station identity comes from interactables/catalog data, not tile graphics.
35. Confirm Taco Bell source scene `res://scenes/missions_iso/TacoBellIso_Editable.tscn` was not touched.

## Expected Result

The hideout is a playable physical graybox garage/greenhouse hub with reachable stations, scrollable text panels, fake progression state visuals, mission board launch to frozen Taco Bell, and clean layer separation for a later Monogon dressing pass.
