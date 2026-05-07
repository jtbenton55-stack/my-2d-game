# Hideout Phase 0M-A5 Panel Content Binding

Status: PARTIAL

0M-A5 repaired empty HideoutHub popups by creating one canonical panel data contract, populating every station with title/body/buttons, updating the scrollable panel to render dictionary button data, and routing panel actions through `HideoutManager`. Runtime checks confirmed Mission Board content, button rendering, care feedback, close/unblock behavior, and Taco Bell launch.

Status is PARTIAL only because a full manual walk-up check for all 18 stations is still recommended. Static validation confirms every required station has non-empty content.

## Backup

- `res://scenes/hideout/HideoutHub.phase0ma5_backup.20260507_003509.tscn`

Taco Bell scenes modified: no.

## Files Created

- `res://scenes/hideout/HideoutHub.phase0ma5_backup.20260507_003509.tscn`
- `res://src/tools/editor/HideoutPhase0MA5Validator.gd`
- `res://docs/reports/hideout_phase_0ma5_panel_content_binding.md`
- `res://docs/reports/hideout_phase_0ma5_panel_content_binding.json`

## Files Modified

- `res://src/hideout/HideoutStationCatalog.gd`
- `res://src/hideout/HideoutManager.gd`
- `res://src/hideout/ScrollableStationPanel.gd`
- `res://src/hideout/HideoutInteractable.gd`

## Empty Popup Root Cause

The panel stack had two content contract problems:

- `ScrollableStationPanel` only expected button strings, while 0M-A5 needed button dictionaries with explicit ids, labels, and actions.
- Generated `HideoutInteractable.panel_buttons` was typed as `Array[String]`, causing runtime conversion errors when station catalog button dictionaries were assigned.

Fixes:

- `panel_buttons` is now a generic `Array`.
- `ScrollableStationPanel.open_panel()` normalizes malformed/legacy button data.
- `HideoutManager.open_station()` normalizes IDs and opens canonical catalog panel data.

## Panel Node Paths

- UI: `UI`
- Panel root: `UI/ScrollableStationPanel`
- Title: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/Title`
- Scroll: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/ScrollContainer`
- Body: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/ScrollContainer/Body`
- Buttons: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/ActionButtons`
- Close: `UI/ScrollableStationPanel/MarginContainer/VBoxContainer/CloseButton`
- Debug panel: `UI/DebugHideoutPanel`

## Canonical Panel Contract

Each station panel is now represented as:

```gdscript
{
  "station_id": "mission_board",
  "title": "Mission Board",
  "body": "Choose the next mission...",
  "buttons": [
    {"id": "start_taco_bell", "label": "Start The Taco Bell Drop", "action": "launch_taco_bell"},
    {"id": "back", "label": "Back", "action": "close"}
  ],
  "classification": "FUNCTIONAL"
}
```

Unknown actions do not crash; they show placeholder feedback or print a clear debug line.

## Station Content Table

| station_id | title | body_non_empty | button_count | actions | classification |
|---|---|---:|---:|---|---|
| entry_exit_door | Entry / Exit | yes | 1 | close | PANEL_ONLY |
| bentley_care_station | Bentley Care Station | yes | 6 | care_wipe_paws, care_give_treat, care_brush, care_restock_poop_bags, care_view_poop_bags, close | FUNCTIONAL |
| loot_crate_drop_zone | Loot Crate Drop Zone | yes | 2 | inspect, close | DEBUG_STATE_VISUAL |
| bentley | Bentley | yes | 3 | talk, inspect, close | PANEL_ONLY |
| jake | Jake | yes | 2 | talk, close | PANEL_ONLY |
| mere | Mere | yes | 2 | talk, close | PANEL_ONLY |
| mission_board | Mission Board | yes | 3 | launch_taco_bell, show_known_info, close | FUNCTIONAL |
| evidence_board_big_case | The Big Case | yes | 3 | show_evidence, show_missing_evidence, close | FUNCTIONAL |
| planning_table | Planning Table | yes | 3 | show_scheme_cards, show_active_slots, close | FUNCTIONAL |
| polaroid_wall | Polaroid Wall | yes | 2 | show_collection, close | PANEL_ONLY |
| glow_guy_shelf | Glow Guy Shelf | yes | 2 | show_collection, close | PANEL_ONLY |
| tiny_icon_shelf | Tiny Icon Shelf | yes | 2 | show_collection, close | PANEL_ONLY |
| poop_bag_care_display | Poop Bag Display | yes | 3 | care_view_poop_bags, care_restock_poop_bags, close | PANEL_ONLY |
| store_terminal | Store Terminal | yes | 8 | show_store_category, close | FUNCTIONAL |
| open_decor_zone | Open Decor Area | yes | 2 | show_placement_zones, close | FUTURE_PLACEHOLDER |
| heat_scanner | Heat Scanner | yes | 2 | view_heat, close | DEBUG_STATE_VISUAL |
| louis | Louis | yes | 2 | show_store_category, close | DEBUG_STATE_VISUAL |
| test_interactable | Test Interactable | yes | 1 | close | PANEL_ONLY |

## Button Action Routing

| action_id | behavior | status |
|---|---|---|
| close | closes panel and removes `blocking_ui` | implemented |
| launch_taco_bell | starts `taco_bell_drop` and changes to frozen Taco Bell scene | implemented |
| show_known_info | shows Taco Bell known-info feedback | placeholder |
| show_scheme_cards | shows planning table card text | placeholder |
| show_active_slots | shows 3 active slot text | placeholder |
| show_evidence | shows evidence placeholder feedback | placeholder |
| show_missing_evidence | shows missing evidence feedback | placeholder |
| care_wipe_paws | shows paw wipe feedback | placeholder |
| care_give_treat | shows treat feedback | placeholder |
| care_brush | shows brushing feedback | placeholder |
| care_restock_poop_bags | shows restock feedback | placeholder |
| care_view_poop_bags | shows poop bag placeholder | placeholder |
| inspect | shows inspect placeholder | placeholder |
| show_collection | shows collection placeholder | placeholder |
| show_store_category | shows store placeholder | placeholder |
| show_placement_zones | shows placement scaffold feedback | placeholder |
| view_heat | shows heat scanner feedback | placeholder |
| talk | shows talk acknowledgement | placeholder |
| unknown_placeholder | shows safe fallback feedback | placeholder |

## Mission Board

- Title/body populated: yes.
- Lists 11 missions: yes.
- Button: `Start The Taco Bell Drop`.
- Action: `launch_taco_bell`.
- Launch path: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Runtime launch confirmed: yes.
- Forbidden progression labels absent: yes.

## Evidence / Planning / Care / Store

- EvidenceBoard content populated with vague Big Case language and clue placeholders.
- PlanningTable lists all 10 starter scheme cards.
- BentleyCareStation has five care actions plus Back; `care_wipe_paws` runtime feedback confirmed.
- StoreTerminal lists store categories and Taco Bell decor placeholders.

## Runtime / Validator Results

- HideoutHub scene load returned OK.
- Non-MCP Hideout script errors after fix: none.
- MissionBoard title runtime text: `Mission Board`.
- MissionBoard body contains `The Final Job`: true.
- MissionBoard buttons rendered: 3.
- First button text: `Start The Taco Bell Drop`.
- Care feedback includes `Paws wiped`: true.
- Closing panel leaves `blocking_ui` count at 0.
- Launch action changed scene to frozen Taco Bell.
- `HideoutPhase0MA5Validator.gd` created.

Known validation noise: the Godot Runtime Bridge may log `McpInteractionServer: Failed to listen on port 9090`; this is a local bridge port conflict, not a Hideout panel error.

## Known Placeholders

- Store categories are placeholder feedback.
- Scheme-card effects are not implemented.
- Decoration placement is not implemented.
- Collection rearranging is not implemented.
- Character dialogue is panel text, not full dialogue UI.

## Risks / Fragile Areas

- Manual walk-up test should still verify every station renders content in-game.
- Specialized controllers still exist; `HideoutManager` now prevents blank known stations by falling back to catalog data.
- Curly punctuation from design copy was normalized to ASCII in code strings.

## Manual Playtest Checklist

1. Open `res://scenes/hideout/HideoutHub.tscn`.
2. Press Play.
3. Walk to Entry/Exit and press E.
4. Confirm title, body text, and Back button appear.
5. Close panel.
6. Walk to Bentley Care Station and press E.
7. Confirm care buttons appear.
8. Press Wipe Paws or Give Treat and confirm feedback.
9. Close panel.
10. Walk to Bentley, Jake, and Mere and press E.
11. Confirm each has visible dialogue/content.
12. Walk to MissionBoard and press E.
13. Confirm 11 missions are listed.
14. Confirm The Taco Bell Drop has Start button/action.
15. Press Start The Taco Bell Drop.
16. Confirm `TacoBellIso_Editable_RedesignTest.tscn` launches.
17. Reopen HideoutHub.
18. Open The Big Case and confirm vague clue text appears.
19. Open Planning Table and confirm 10 scheme cards appear.
20. Open Polaroid Wall and confirm content appears.
21. Open Glow Guy Shelf and confirm content appears.
22. Open Tiny Icon Shelf and confirm content appears.
23. Open Poop Bag Display and confirm content appears.
24. Open Store Terminal and confirm categories/items appear.
25. Open Open Decor Area and confirm placement-zone text appears.
26. Open Heat Scanner and confirm heat text appears.
27. Toggle Louis Unlocked and interact with Louis.
28. Confirm Louis panel has text.
29. Confirm no required popup is empty.
30. Confirm every panel closes.
31. Confirm E works again after closing panels.
32. Confirm no Taco Bell scene was modified.

## Recommended Next Step

If manual panel content test passes: 0M-B - Hideout visual dressing / Monogon-style prop pass.

If manual panel content test fails: 0M-A6 - focused panel content fix.
