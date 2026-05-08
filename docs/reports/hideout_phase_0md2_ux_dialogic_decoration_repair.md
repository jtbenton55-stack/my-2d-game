# HideoutHub Phase 0M-D2 UX, Dialogic, Decoration Repair

Status: PARTIAL

0M-D2 repaired the global hideout station panel sizing path, canonical return-to-hideout scene path, visual storefront/decor scaffolds, placed-item removal, dynamic Bentley Care parent refresh, and expanded character dialogue. Runtime Godot validation is still a manual-check item because `godot` is not available on the shell `PATH` in this environment.

## Backup And Baseline

- Backup path: `res://scenes/hideout/HideoutHub.phase0md2_backup.20260507_152122.tscn`
- `project.godot` modified: no
- Project backup required: no
- SceneManager old hideout path: `res://scenes/hideout/hideout.tscn`
- SceneManager new hideout path: `res://scenes/hideout/HideoutHub.tscn`
- Pause exit path before fix: `src/ui/PauseMenu.gd` and `src/ui/test_ui/pause_menu.gd` call `SceneManager.return_to_hideout()`, which previously routed through the old `HIDEOUT_SCENE`
- Pause exit path after fix: same pause menu calls now route through `SceneManager.HIDEOUT_SCENE = res://scenes/hideout/HideoutHub.tscn`
- Taco Bell source scene modified: no
- Taco Bell RedesignTest scene modified: no

Baseline node/path record:

- HideoutHub root: `HideoutHubRoot`
- GameplayRoot: `GameplayRoot`
- ArtRoot: `ArtRoot`
- UI root: `UI`
- ScrollableStationPanel: `UI/ScrollableStationPanel`
- ScrollableStationPanel root Control: `PanelContainer`
- Title label: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/Title`
- Body ScrollContainer: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/ScrollContainer`
- Body RichTextLabel: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/ScrollContainer/Body`
- Button container: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/ActionButtonScroll/ActionButtons` at runtime
- Close button: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/CloseButton`
- Placed decor container: `ArtRoot/World/DecorationLayer/PlacedDecor`
- HideoutManager: `GameplayRoot/Managers/HideoutManager`
- HideoutStateController: `GameplayRoot/Managers/HideoutStateController`
- HideoutDecorationController: `GameplayRoot/Managers/HideoutDecorationController`
- HideoutStoreController: `GameplayRoot/Managers/HideoutStoreController`
- HideoutDialogueBank: `res://src/hideout/HideoutDialogueBank.gd`

Working-state facts preserved by static audit:

- Existing station catalog remains wired with 18+ stations.
- Mission Board launch path remains `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Scheme-card equip/loadout code remains in `HideoutSchemeCardController.gd` and `HideoutStateController.gd`.
- Mission-start warning remains in `HideoutManager._mission_start_confirmation_data()`.
- Case Cash purchase logic remains in `HideoutStoreController.gd` and `HideoutStateController.gd`.
- Placed item visuals remain under `ArtRoot/World/DecorationLayer/PlacedDecor`.
- Back/Close semantics are preserved through `ScrollableStationPanel` plus `HideoutManager`.
- `blocking_ui` is still removed in `ScrollableStationPanel.close_panel()`.
- Debug states still exist in `HideoutStateController.apply_debug_state()`.

## Implementation Summary

Universal panel scrolling/screen-fit:

- `ScrollableStationPanel.gd` now sizes itself against the viewport at open time using an 86% viewport-height cap.
- Body content remains inside `ScrollContainer`.
- Long action lists are wrapped into runtime `ActionButtonScroll`.
- Root Close is fixed outside scrollable content and remains reachable.
- Action-list Close buttons are stripped so there is exactly one full-panel Close affordance.
- Open/back actions reset body/action scroll position to top.

Duplicate Close and Back behavior:

- The header/bottom built-in `CloseButton` is the only full-panel close control.
- Submenu Back remains in the action list.
- Back regenerates dynamic root panels for stateful systems, preventing stale Bentley Care parent content.
- Close closes the panel and clears history.

Return-to-hideout:

- `SceneManager.HIDEOUT_SCENE` now points to `res://scenes/hideout/HideoutHub.tscn`.
- Pause menu exit, mission result return, gallery return, crew return, and other `SceneManager.return_to_hideout()` callers now use the new HideoutHub path through the canonical constant.

Visual storefront:

- Store body now includes placeholder visual item cards with `[ICON]`, item name, category, cost, state, description, and locked/owned/buy guidance.
- Buy actions are generated only for unlocked, unowned items.
- Purchase refreshes the category panel and shows the item as owned through existing store state.

Decoration placement:

- Implemented safe click-to-place V2 rather than physics-heavy drag/drop.
- Owned decor inventory is shown as `[CARD/ICON]` cards in Open Decor Area and Loot Crate.
- Selecting an owned item arms click-to-place mode and creates a placeholder `PlacementPreview`.
- Placing creates a placeholder non-colliding visual under `PlacedDecor`.
- Placed items can be selected again from Open Decor Area buttons or by clicking the placeholder `Area2D`.
- Selected placed items can be moved to the next compatible anchor or removed.
- Removing placed decor does not remove ownership and does not refund Case Cash.

Loot Crate / decor inventory:

- Loot Crate shows delivered/purchased items and an owned decor summary.
- Loot Crate includes `Open Decor Inventory`.
- Open Decor Area shows owned items, current selected item, placement mode, placed items, compatible anchors, and remove/clear actions.

Bentley Care refresh:

- Back from dynamic hideout submenus now regenerates the current station root panel where appropriate.
- Bentley Care actions update state immediately, and returning Back to the parent panel regenerates live checklist values.

Dialogic status:

- Attempted/investigated: yes
- Installed: no
- Enabled: no
- Source: official GitHub `dialogic-godot/dialogic`
- Latest observed release: `Dialogic 2.0 - Alpha 19`, January 12, 2026
- Minimum Godot version reported by release notes: Godot 4.4
- License: MIT, per public project metadata/search result
- Deferred reason: safe installation would require adding a large alpha plugin to `res://addons/dialogic/` and touching `project.godot`; given the repair-pass constraints, known 4.6 compatibility history, and no committed baseline, installation was deferred to avoid destabilizing the project.
- Adapter created: yes, `res://src/hideout/HideoutDialogicAdapter.gd`
- Fallback preserved: yes, all dialogue still falls back to `HideoutDialogueBank`.

Character dialogue:

- Jake: 24 lines across fresh, completed, missing-items, high-heat, and Louis-unlocked states.
- Mere: 24 lines across fresh, completed, missing-items, high-heat, and Louis-unlocked states.
- Bentley: 24 lines across fresh/bed, care-reactive, completed, high-heat, and store-purchase contexts.
- Louis: 8 unlocked/store lines.
- `Talk Again` uses `HideoutDialogicAdapter`, which falls back to randomized `HideoutDialogueBank` lines and avoids immediate repeats.

## Validator

- Created: `res://src/tools/editor/HideoutPhase0MD2Validator.gd`
- Static/IDE validation: passed lints for edited hideout/autoload/tool files.
- Runtime validator execution: manual check required because Godot CLI is not available on shell `PATH`.

## Files Created

- `res://scenes/hideout/HideoutHub.phase0md2_backup.20260507_152122.tscn`
- `res://src/hideout/HideoutDialogicAdapter.gd`
- `res://src/tools/editor/HideoutPhase0MD2Validator.gd`
- `res://docs/reports/hideout_phase_0md2_ux_dialogic_decoration_repair.md`
- `res://docs/reports/hideout_phase_0md2_ux_dialogic_decoration_repair.json`

## Files Modified

- `res://src/autoload/SceneManager.gd`
- `res://src/hideout/ScrollableStationPanel.gd`
- `res://src/hideout/HideoutManager.gd`
- `res://src/hideout/HideoutStoreController.gd`
- `res://src/hideout/HideoutDecorationController.gd`
- `res://src/hideout/HideoutDialogueBank.gd`
- `res://src/hideout/HideoutCharacterController.gd`

## Known Placeholders

- Store/decor visuals are text and simple placeholder shapes, not final art.
- Placement is click-to-place/anchor-based, not true drag/drop.
- Placed decor does not have collision and does not block player movement.
- Dialogic plugin installation is deferred; adapter is ready for a later migration.

## Risks / Fragile Areas

- Runtime UI sizing needs manual verification at the target 1280x720 viewport.
- Clickable placed decor uses runtime `Area2D` placeholder selection and should be tested in-game.
- Dialogic remains uninstalled; future installation should happen in its own pass with a `project.godot` backup.
- Existing working tree had pre-existing 0M-D dirty files before this pass.

## Manual Playtest Checklist

1. Open `HideoutHub.tscn`.
2. Open Planning Table.
3. Confirm menu is scrollable and Close is reachable.
4. Equip cards and confirm no cut-off.
5. Open Store Terminal.
6. Confirm visual storefront item cards show icon/name/cost/status.
7. Toggle Taco Bell Completed if needed.
8. Buy one item.
9. Confirm Case Cash decreases.
10. Open Loot Crate or Open Decor Area.
11. Confirm purchased item appears visually in inventory.
12. Click-place item onto hideout map.
13. Confirm placed item appears.
14. Click/select placed item again.
15. Move it elsewhere.
16. Remove/delete it.
17. Open Bentley Care Station.
18. Press Wipe/Brush/Treat/Restock.
19. Press Back.
20. Confirm parent menu says yes for updated care states.
21. Open store category submenu.
22. Press Back.
23. Confirm parent store menu returns.
24. Press Close.
25. Confirm panel closes.
26. Confirm there are not two Close buttons.
27. Launch Taco Bell.
28. Pause Taco Bell and choose exit to hideout.
29. Confirm it returns to `res://scenes/hideout/HideoutHub.tscn`.
30. Interact with Jake multiple times.
31. Confirm varied, better dialogue.
32. Interact with Mere multiple times.
33. Confirm varied, better dialogue.
34. Interact with Bentley/Louis and confirm dialogue still works.
35. Confirm E still works after panels close.
36. Confirm MissionBoard still launches Taco Bell.
37. Confirm no Taco Bell scenes were modified.

## Recommended Next Step

If manual 0M-D2 test passes: `0M-B — Hideout visual dressing / Monogon-style prop pass`.

If Dialogic should be installed and migrated next: `0M-D3 — Dialogic dialogue migration pass`.

If manual test fails: `0M-D2-FIX — focused fix for failed UX/decor/dialogue issue`.
