# HideoutHub Phase 0M-D Progression / Store / Decoration Systems

Status: PASS

Backup: `res://scenes/hideout/HideoutHub.phase0md_backup.20260507_060218.tscn`

Taco Bell scenes modified: no

## Summary

0M-D turns the HideoutHub into a stronger between-missions loop while preserving movement, collision, floor shape, station positions, player layering, the existing interaction spine, and Monogon-ready GameplayRoot / ArtRoot separation.

Runtime checks confirmed the scene loads with 0 errors, Planning Table exposes dynamic equip buttons, equipping a card updates `HideoutStateController`, Mission Board opens a start confirmation before launch, Store purchases spend local Case Cash and add owned decor inventory, Open Decor Area can place a purchased item into placed decor state, and Greenhouse Alcove opens as an interactable station.

## Files Created

- `res://scenes/hideout/HideoutHub.phase0md_backup.20260507_060218.tscn`
- `res://src/hideout/HideoutDialogueBank.gd`
- `res://src/hideout/HideoutDecorationController.gd`
- `res://src/tools/editor/HideoutPhase0MDValidator.gd`
- `res://docs/reports/hideout_phase_0md_progression_store_decoration_systems.md`
- `res://docs/reports/hideout_phase_0md_progression_store_decoration_systems.json`

## Files Modified

- `res://scenes/hideout/HideoutHub.tscn`
- `res://src/autoload/GameState.gd`
- `res://src/hideout/ScrollableStationPanel.gd`
- `res://src/hideout/HideoutStateController.gd`
- `res://src/hideout/HideoutStationCatalog.gd`
- `res://src/hideout/HideoutManager.gd`
- `res://src/hideout/HideoutMissionBoardController.gd`
- `res://src/hideout/HideoutSchemeCardController.gd`
- `res://src/hideout/HideoutCollectibleController.gd`
- `res://src/hideout/HideoutCareController.gd`
- `res://src/hideout/HideoutStoreController.gd`
- `res://src/hideout/HideoutCharacterController.gd`

## Scheme Card Loadout V2

The Planning Table now lists all unlocked cards by slot and creates equip actions dynamically. Locked Taco Bell cards show the hint: “Complete The Taco Bell Drop to unlock.” Equipping enforces slot compatibility and replaces only the matching slot. Clear Plan, Clear Trick, Clear Comfort/Chaos, and Clear All actions update state immediately.

Action format:

- `equip_scheme_card:<card_id>`
- `clear_scheme_slot:plan`
- `clear_scheme_slot:trick`
- `clear_scheme_slot:comfort_chaos`
- `clear_scheme_loadout`

## Card Catalog

- `bentley_sniff_pass` — Bentley Sniff Pass — plan — fresh
- `treat_based_negotiation` — Treat-Based Negotiation — trick — fresh
- `definitely_normal_hoodie` — Definitely Normal Hoodie — comfort_chaos — fresh
- `poop_bag_protocol` — Poop Bag Protocol — plan — fresh
- `jakes_sleep_deprived_insight` — Jake’s Sleep-Deprived Insight — plan — fresh
- `meres_vibe_check` — Mere’s Vibe Check — comfort_chaos — fresh
- `fire_sauce_diversion` — Fire Sauce Diversion — trick — Taco Bell completed
- `drive_thru_timing_window` — Drive-Thru Timing Window — plan — Taco Bell completed
- `security_booth_coupon` — Security Booth Coupon — trick — Taco Bell completed
- `baja_blast_nerves` — Baja Blast Nerves — comfort_chaos — Taco Bell completed

## Mission Start Confirmation

Mission Board `launch_taco_bell` now opens `Ready for The Taco Bell Drop?` first. It shows current Plan, Trick, and Comfort/Chaos cards, warns if any slot is empty, offers Go to Planning Table, and only launches after `confirm_launch_taco_bell`. Before launch, `HideoutStateController.get_current_scheme_loadout()` is written to `GameState.current_scheme_loadout` through a minimal setter.

## Panel Navigation

`ScrollableStationPanel` now stores `current_panel_data` and `panel_history`. Root world interactions clear history. Subpanels push current panel data. `back` restores the parent panel when history exists; `close` closes the full panel, clears history, and removes `blocking_ui`.

## Dialogue Bank

`HideoutDialogueBank.gd` includes rotating/random lines with immediate repeat avoidance and fallback text. Required contexts have at least 3 lines, including care actions, Bentley/Jake/Mere/Louis states, store feedback, greenhouse actions, mission start warning, evidence review, open decor, and placement feedback.

## Currency

Currency name: Case Cash.

Description: “Money, favors, and suspiciously liquid reimbursement.”

Fresh starts at 75 Case Cash. Taco Bell Completed raises currency to at least 150 without lowering higher current cash. Store purchases spend Case Cash through `spend_case_cash()` and cannot go negative.

Mission reward scaffold:

- Base delivery payout: +50 Case Cash
- Clean getaway bonus: pending
- Clue bonus: pending
- Collectible bonus: pending
- High heat penalty: deferred

## Storefront Catalog

- Taco Bell Stool — Furniture — 35 — floor_item, furniture
- Employees Must Wash Paws Sign — Wall Decor — 20 — wall_item
- Sauce Packet Rug — Rugs — 45 — rug, floor_item
- Neon Menu Panel — Lights — 60 — wall_item, light
- Mild Sauce Throw Pillow — Bentley Items — 25 — bentley_item, tabletop_item
- Drive-Thru Headset — Care Station Upgrades — 30 — care_station_item, tabletop_item
- Security Booth Monitor — Collectible Displays — 50 — tabletop_item, shelf_item
- Suspicious Fry Basket — Mission Trophies — 40 — mission_trophy, shelf_item, tabletop_item

Purchase behavior handles locked, already owned, insufficient funds, and success states. Successful purchases subtract Case Cash, mark the item purchased/delivered, and add it to owned placeable inventory.

## Decoration Placement

`HideoutDecorationController` tracks owned placeable items, selected item, placed items, and a starter anchor list. Open Decor Area can select an owned item, place it at the next compatible anchor, move it to the next compatible anchor, remove it, or clear all placed decor. Placeholder visuals are rectangles and labels under `ArtRoot/World/DecorationLayer/PlacedDecor`; they have no collision and are not Monogon art.

## Placement Anchors

- `decor_anchor_furniture_01` — floor_item, furniture, large_furniture
- `decor_anchor_furniture_02` — floor_item, furniture, large_furniture
- `decor_anchor_furniture_03` — floor_item, furniture, large_furniture
- `decor_anchor_rug_01` — rug, floor_item
- `decor_anchor_wall_01` — wall_item, light
- `decor_anchor_wall_02` — wall_item, light
- `decor_anchor_care_01` — care_station_item, bentley_item, tabletop_item
- `decor_anchor_shelf_01` — shelf_item, tabletop_item, mission_trophy, collectible_display
- `decor_anchor_tabletop_01` — tabletop_item
- `decor_anchor_trophy_01` — mission_trophy, shelf_item

## Greenhouse

Added `greenhouse_alcove` to the station catalog without changing greenhouse geometry. It opens Greenhouse Alcove content and supports Take a Breath, Water Suspicious Plants, and Inspect the Skyline actions using DialogueBank lines.

## Taco Bell Completed Displays

The Taco Bell Completed debug state now sets Taco Bell Polaroid, Glow Guy, Sauce Packet icon, Drive-Thru Bell icon, Fire Sauce Emergency Roll, and Taco Bell trophy found. Display panels support View Found, View Missing, and Arrange Later.

## Mission Name Cleanup

Mission Board now displays clean mission names without bracketed raw mission IDs. Technical IDs remain internal in catalog/state data.

## Button Action Routing

- `launch_taco_bell`: opens mission start confirmation
- `confirm_launch_taco_bell`: writes loadout and launches RedesignTest
- `go_to_planning_table`: opens Planning Table
- `back`: returns to parent panel when possible
- `close`: closes full panel
- `equip_scheme_card:<card_id>`: equips compatible unlocked card
- `clear_scheme_slot:<slot>`: clears one active slot
- `clear_scheme_loadout`: clears all slots
- `care_wipe_paws`: updates care state and shows random quote
- `care_give_treat`: updates care state and shows random quote
- `care_brush`: updates care state and shows random quote
- `care_restock_poop_bags`: updates care state and shows random quote
- `care_view_poop_bags`: opens poop bag submenu
- `store_view_category:<category>`: opens category submenu
- `store_buy_item:<item_id>`: attempts purchase
- `decor_select_item:<item_id>`: selects owned decor item
- `decor_place_selected`: places selected item
- `decor_move_selected`: moves selected placed item
- `decor_remove_selected`: removes selected placed item
- `decor_clear_all`: clears placed decor
- `greenhouse_take_breath`: shows random line
- `greenhouse_water_plants`: shows random line
- `greenhouse_inspect_skyline`: shows random line
- `show_found_collection:<display_id>`: shows found display items
- `show_missing_collection:<display_id>`: shows missing display items
- `arrange_later`: shows randomized arrange-later placeholder
- `talk`: shows random state-appropriate dialogue
- `unknown_placeholder`: safe fallback

## Validator Results

- Validator created: PASS
- Godot runtime scene load: PASS
- Runtime error count after final checks: 0
- Dynamic Planning Table buttons: PASS
- Equip card updates state: PASS
- Mission start confirmation opens: PASS
- Store purchase adds owned decor: PASS
- Decor placement adds placed item state: PASS
- Greenhouse station opens: PASS
- Lints on touched files: PASS
- Taco Bell scenes modified: no

## Known Placeholders

- Scheme cards carry into mission-start state but do not affect Taco Bell gameplay yet.
- Store/decor/currency are local/debug state, not final persistence.
- Decoration placement is button-based, not drag/drop.
- Placeholder decor visuals are rectangles and labels.
- Mission result bonuses are scaffolds except Case Cash floor/debug payout.

## Risks / Fragile Areas

- Runtime state resets until SaveManager integration.
- Store purchases use local state and a simple item catalog.
- Decoration visuals are rebuilt from state and have no final art replacement pipeline yet.
- Full manual E-interaction walkaround is still required after the new Greenhouse station.

## Manual Playtest Checklist

1. Open `res://scenes/hideout/HideoutHub.tscn`.
2. Confirm movement and collision still work.
3. Open Planning Table.
4. Confirm all unlocked scheme cards have equip options.
5. Equip one Plan card.
6. Equip one Trick card.
7. Equip one Comfort/Chaos card.
8. Confirm active slots update.
9. Open MissionBoard.
10. Confirm mission names do not show bracketed technical IDs.
11. Click Start The Taco Bell Drop.
12. Confirm mission-start warning shows current equipped cards.
13. Click Go to Planning Table and confirm it opens Planning Table.
14. Return to Mission Board.
15. Start mission again.
16. Confirm Taco Bell launches.
17. Reopen HideoutHub.
18. Open Bentley Care Station.
19. Press Wipe Paws multiple times and confirm varied Bentley quotes.
20. Press Give Treat multiple times and confirm varied quotes.
21. Press Brush multiple times and confirm varied quotes.
22. Press Restock Poop Bags multiple times and confirm varied quotes.
23. Open Bentley/Jake/Mere and confirm varied dialogue.
24. Toggle High Heat and confirm dialogue changes.
25. Toggle Taco Bell Completed and confirm dialogue changes.
26. Toggle Louis Unlocked and confirm Louis varied dialogue.
27. Open Store Terminal.
28. Confirm Case Cash appears.
29. Confirm store categories appear.
30. Toggle Taco Bell Completed if needed to unlock items.
31. Buy one item.
32. Confirm Case Cash decreases.
33. Confirm item appears in owned inventory / loot crate / decor inventory.
34. Open Open Decor Area.
35. Place purchased item.
36. Confirm placeholder visual appears in hideout.
37. Move placed item to next anchor if implemented.
38. Remove placed item if implemented.
39. Open Greenhouse Alcove and press E.
40. Confirm greenhouse panel/actions/quotes work.
41. Toggle Taco Bell Completed.
42. Open Polaroid Wall and confirm Taco Bell Polaroid found/viewable.
43. Open Glow Guy Shelf and confirm Taco Bell Glow Guy found/viewable.
44. Open Tiny Icon Shelf and confirm Taco Bell icons found/viewable.
45. Open Poop Bag Display and confirm Fire Sauce Emergency Roll found/viewable.
46. Test a submenu and press Back.
47. Confirm Back returns to parent menu instead of closing the entire panel.
48. Confirm Close still closes the panel.
49. Confirm E still works after closing panels.
50. Confirm MissionBoard still launches Taco Bell.
51. Confirm no Taco Bell scene was modified.

## Recommended Next Step

If manual 0M-D test passes: 0M-B — Hideout visual dressing / Monogon-style prop pass.

If manual 0M-D test fails: 0M-D2 — focused fix for failed system.
