# Hideout Phase 0M-A Production Scaffold

Status: PARTIAL

0M-A created a playable, data-driven HideoutHub scaffold at `res://scenes/hideout/HideoutHub.tscn`. The scene loads with no runtime parse errors, spawns the standard player scene, creates separated gameplay/art layers, builds 18 interactables from `HideoutStationCatalog`, opens/closes a reusable scrollable station panel, includes 11 mission slots, and configures the Taco Bell launch path to the frozen duplicate scene.

Status is PARTIAL because player movement and physical wall collision still need a human Godot playtest. Runtime validation confirmed the player exists, collision bodies exist, the station panel opens/closes, Louis is hidden by default and visible in the debug state, but MCP input injection did not produce a reliable hold-to-move proof.

## 1. Audit Summary

- Player/controller: `res://scenes/characters/player.tscn` using `src/player/Player.gd`.
- Interaction pattern: player scans the global `interactable` group, calls `is_interaction_available(player)` when present, then calls `interact(self)` on nearby `Node2D` objects. Main interact action is `interact` / E. `case_the_joint` / Q is a separate scan pulse and not needed for hideout station panels.
- Scene transition pattern: `SceneManager.change_scene(path)` and `get_tree().change_scene_to_file(path)` are the existing transition paths. Mission starts usually go through `GameState.start_mission(mission_id)` then scene change.
- Mission launch pattern: 0M-A mission board calls `GameState.start_mission("taco_bell_drop")` and `SceneManager.change_scene("res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")`.
- Pause/menu/panel patterns: existing pause menu uses text panels; 0M-A uses a reusable `PanelContainer` with `ScrollContainer` and `RichTextLabel`.
- Quest/GameState/EventBus: no shared modifications were needed.
- HUD/dialogue/panel systems: no shared HUD/dialogue systems were modified.
- Isometric layer convention: Taco Bell separates gameplay helpers from visual TileMap layers; 0M-A mirrors this with `GameplayRoot` and `ArtRoot/World`.
- Existing hub scenes: `res://scenes/hideout/hideout.tscn` exists as an older flat/simple hub; `res://scenes/hideout/HideoutHub.tscn` is new; `res://scenes/CityHub.tscn` exists separately.
- Phase0J/0K concepts reused: runtime labels, local adapters/controllers, and scene-local interaction routing were reused conceptually only.
- Taco Bell freeze report read: `PLAYABLE_WITH_KNOWN_LIMITATIONS`; frozen launch scene is `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`; protected source is `res://scenes/missions_iso/TacoBellIso_Editable.tscn`.
- Monogon assets: available under `assets/tilesets/iso_vertical_slice/source/monogon/`, including cyberpunk interiors/buildings/city/streets and house interiors. They are not required for 0M-A gameplay.

Assertions: audit_completed=true; player_scene_identified=true; interaction_pattern_identified=true; scene_transition_pattern_identified=true; scrollable_UI_pattern_identified_or_fallback_defined=true; existing_hideout_scene_status_reported=true; Taco_Bell_freeze_report_read=true; Monogon_asset_status_reported=true.

## 2. Files Created

- `res://scenes/hideout/HideoutHub.tscn`
- `res://src/hideout/HideoutStationCatalog.gd`
- `res://src/hideout/HideoutInteractable.gd`
- `res://src/hideout/ScrollableStationPanel.gd`
- `res://src/hideout/HideoutManager.gd`
- `res://src/hideout/HideoutMissionBoardController.gd`
- `res://src/hideout/HideoutEvidenceBoardController.gd`
- `res://src/hideout/HideoutSchemeCardController.gd`
- `res://src/hideout/HideoutCollectibleController.gd`
- `res://src/hideout/HideoutCareController.gd`
- `res://src/hideout/HideoutStoreController.gd`
- `res://src/hideout/HideoutCharacterController.gd`
- `res://src/hideout/HideoutDebugController.gd`
- `res://src/hideout/HideoutPlacementZone.gd`
- `res://src/tools/editor/HideoutPhase0MAValidator.gd`
- `res://docs/reports/hideout_phase_0ma_production_scaffold.md`
- `res://docs/reports/hideout_phase_0ma_production_scaffold.json`
- `res://docs/reports/hideout_birthday_build_manual_test.md`

## 3. Files Modified

None. 0M-A only added new hideout/report files.

Shared code modifications: none.

Taco Bell scenes modified in this phase: no.

## 4. Chosen Scene Path

`res://scenes/hideout/HideoutHub.tscn`

Root node: `HideoutHubRoot`

## 5. Node Tree Summary

- `GameplayRoot`
  - `Navigation/Collision`, `WalkableArea`, `InteractionAreas`
  - `SpawnMarkers`
  - `Stations`
  - `Characters/Player`
  - `PlacementZones`
  - `SnapMarkers`
  - `Managers`
- `ArtRoot/World`
  - `FloorLayer`
  - `WallLayer`
  - `PropLayer`
  - `DecorationLayer`
  - `CollectibleLayer`
  - `CharacterVisualLayer`
  - `ForegroundLayer`
  - `LightingLayer`
- `UI`
  - `InteractionPrompt`
  - `ScrollableStationPanel`
  - station-specific placeholder panel nodes
  - `DebugHideoutPanel`

## 6. Playable Spine Result

- HideoutHub loads: yes.
- No parse errors: yes.
- Player spawns: yes.
- Player moves: manual_check_required.
- Collision exists: yes, 8 explicit collision bodies generated under `GameplayRoot/Navigation/Collision`.
- Test interactable opens panel: yes, runtime `open_station("test_interactable")` opened `ScrollableStationPanel`.
- Panel closes: yes, runtime `close()` hid the panel.
- Gameplay/art layer separation exists: yes.

## 7. Station Catalog Summary

`HideoutStationCatalog.gd` provides data entries with `station_id`, `display_name`, `station_type`, `panel_title`, `panel_body`, `panel_buttons`, `unlock_state`, `visible_in_states`, `placement_zone`, `node_path`, `classification`, `tags`, and `suggested_monogon_art_tags`.

Required stations exist: yes. Extra generic `test_interactable` exists for spine validation.

Assertions: station_catalog_exists=true; all_required_station_entries_exist=true; every_station_has_classification=true; station_catalog_has_monogon_art_tags_or_notes=true.

## 8. Interactable List And Classification

- entry_exit_door: PANEL_ONLY
- bentley_care_station: FUNCTIONAL
- loot_crate_drop_zone: DEBUG_STATE_VISUAL
- bentley: PANEL_ONLY
- jake: PANEL_ONLY
- mere: PANEL_ONLY
- louis: DEBUG_STATE_VISUAL
- mission_board: FUNCTIONAL
- evidence_board_big_case: FUNCTIONAL
- planning_table: FUNCTIONAL
- polaroid_wall: PANEL_ONLY
- glow_guy_shelf: PANEL_ONLY
- tiny_icon_shelf: PANEL_ONLY
- poop_bag_care_display: PANEL_ONLY
- store_terminal: FUNCTIONAL
- open_decor_zone: FUTURE_PLACEHOLDER
- heat_scanner: DEBUG_STATE_VISUAL
- test_interactable: PANEL_ONLY

Runtime interactable count: 18.

## 9. Panel And Scroll Status

`ScrollableStationPanel.gd` uses:

- `PanelContainer`
- `ScrollContainer`
- `RichTextLabel`
- generated action buttons
- close button
- `ui_cancel` close handling

Assertions: scrollable_panel_exists=true; text_heavy_panels_use_scroll_container=true; station_panel_close_works=true.

## 10. Mission Board Validation

- 11 mission slots: yes.
- Taco Bell available in Fresh state: yes.
- Taco Bell status text: "Ready for delivery."
- Taco Bell launch path: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- Fresh actions: Start Mission / View Known Info / Back.
- Completed actions: Replay Mission / Search for Missing Items / Lower Heat Run / Clean Getaway Attempt / View Results / Back.
- Route selection: absent.
- Assist selection: absent.
- Fresh heat controls: absent.
- Forbidden final progression labels: absent.

## 11. Evidence Board Validation

Title: `The Big Case`

Uses vague language:

- "A larger pattern is forming."
- "More pieces are connected."
- "Something bigger is behind this."
- "The map is becoming less comforting."

Forbidden labels absent from new hideout files: yes.

## 12. Scheme Cards

Active slots:

- Plan Card
- Trick Card
- Comfort/Chaos Card

Placeholder cards: 10. Gameplay effects are UI/data only in 0M-A.

## 13. Care Station

Care station is placed directly beside entry/exit in the southeast corner. Placeholder items and care actions are represented in panel text:

- Clorox wipes
- poop bag supply
- treat jar
- brush
- towel
- leash hook

Flags scaffolded: `bentley_wiped`, `bentley_brushed`, `treat_packed`, `poop_bags_stocked`.

## 14. Character Visibility And Debug States

Fresh:

- Bentley visible: yes.
- Jake visible: yes.
- Mere visible: yes.
- Louis hidden: yes.

Louis Unlocked:

- Louis appears near StoreTerminal: yes, runtime state application confirmed.

Debug trigger method: `DebugHideoutPanel` buttons in the upper-right UI. Buttons apply Fresh Hideout, Taco Bell Completed, Taco Bell Completed Missing Items, High Heat, and Louis Unlocked.

## 15. Collectible Displays

Displays created:

- PolaroidWall
- GlowGuyShelf
- TinyIconShelf
- PoopBagCareDisplay

Taco Bell completed states update display text and graybox visual tint. Missing items state keeps silhouette-style language.

## 16. Placement Zones And Snap Markers

Placement zones created:

- WallZone_North
- WallZone_West
- PolaroidWallZone
- ShelfZone_GlowGuys
- ShelfZone_TinyIcons
- ShelfZone_Trophies
- TableZone_Planning
- FloorZone_OpenDecor
- BentleyZone
- CareStationZone
- StoreDeliveryZone

Snap marker containers created:

- MissionCardSlots
- EvidenceClueSlots
- PolaroidSlots
- GlowGuySlots
- TinyIconSlots
- PoopBagSlots
- CareItemSlots
- SchemeCardSlots
- FurnitureAnchors
- StoreDeliveryAnchors

Mission card markers generated: 11.

## 17. Store Scaffold

Store terminal exists in the east zone. Fresh state uses anonymous catalog flavor. Louis Unlocked state changes store text to Louis black-market flavor. Store category and Taco Bell decor lists are panel-only; no economy is implemented.

## 18. Validator Results

Created: `res://src/tools/editor/HideoutPhase0MAValidator.gd`

Runtime validation performed through Godot Runtime Bridge:

- scene change to HideoutHub returned OK.
- runtime errors after load: 0.
- runtime warnings after load: 0.
- hideout interactables: 18.
- Louis hidden by default: true.
- `ScrollableStationPanel` has `ScrollContainer`: true.
- collision bodies: 8.
- mission card slots: 11.
- Louis Unlocked state makes Louis visible: true.
- generic test interactable opens panel: true.
- panel closes: true.

## 19. Monogon Readiness

Visual layers ready for Monogon tiles:

- `ArtRoot/World/FloorLayer`
- `ArtRoot/World/WallLayer`
- `ArtRoot/World/PropLayer`
- `ArtRoot/World/DecorationLayer`
- `ArtRoot/World/CollectibleLayer`
- `ArtRoot/World/CharacterVisualLayer`
- `ArtRoot/World/ForegroundLayer`
- `ArtRoot/World/LightingLayer`

Gameplay layers that should not be replaced by art:

- `GameplayRoot/Navigation`
- `GameplayRoot/Navigation/Collision`
- `GameplayRoot/Navigation/WalkableArea`
- `GameplayRoot/Stations`
- `GameplayRoot/PlacementZones`
- `GameplayRoot/SnapMarkers`
- `GameplayRoot/Managers`

Stations that should receive Monogon props in 0M-B:

- MissionBoard, PlanningTable, StoreTerminal, HeatScanner, EvidenceBoard_TheBigCase
- cozy lounge props for Bentley, Jake, Mere, couch/chair, Bentley bed
- collectible display props for PolaroidWall, GlowGuyShelf, TinyIconShelf, PoopBagCareDisplay
- care station props for wipes, treats, brush, towel, leash hook
- garage/greenhouse entry, counters, shelves, windows, vents, rugs, industrial boundaries

Tile-size/origin/y-sort risks:

- Monogon assets may use different pixel origins than the current graybox props.
- Isometric tile anchors may need per-layer offsets.
- Y-sort should remain on art layers, while station `Area2D` positions remain marker/interactable truth.
- Collision must be adjusted explicitly, not inferred from prop graphics.

Collision/art separation status:

- Collision is separate under `GameplayRoot/Navigation/Collision`.
- Placeholder props are visual-only under `ArtRoot/World/PropLayer`.
- Interactable identity is stored in `HideoutStationCatalog` and `HideoutInteractable`, not in tile graphics.

Recommended Monogon packs/zones:

- cyberpunk interior for mission board, planning table, store terminal, heat scanner, monitors, neon panels, security tech.
- house interior for cozy lounge, couch/chairs, rugs, Bentley bed, domestic shelves, warm props.
- cyberpunk city/building/street extras for entry/exit, rooftop garage boundary, windows, vents, industrial props, exterior city-view greenhouse edge.

Assertions: Monogon_ready_visual_layer_separation_exists=true; gameplay_logic_not_bound_to_visual_tiles=true; collision_is_separate_from_replaceable_art=true; stations_use_markers_or_interactables_not_tile_identity=true; Monogon_Readiness_report_section_written=true.

## 20. Known Placeholders

- Placeholder graybox visuals only.
- Debug/fake progression states are not persisted.
- Store is UI-only; no purchasing economy.
- Scheme cards are UI/data-only; no gameplay effects.
- Placement zones and snap markers exist; no drag/drop placement mode.
- Character dialogue is panel text, not full dialogue UI.
- Mission board launches only Taco Bell; other mission slots are scaffold placeholders.

## 21. Risks And Fragile Areas

- Movement and collision need a manual Godot editor playtest because MCP key injection did not provide a reliable movement proof.
- Runtime-generated scene children are not serialized into the `.tscn`; this is intentional for 0M-A data-driven scaffolding, but editor-only visual placement will need care in 0M-B.
- The existing `SceneManager.HIDEOUT_SCENE` still points at the older `res://scenes/hideout/hideout.tscn`; no shared hook was changed in 0M-A.

## 22. Manual Godot Editor Placement Notes

- Open `res://scenes/hideout/HideoutHub.tscn` directly for 0M-A.
- Keep gameplay markers/interactables under `GameplayRoot`.
- Add future Monogon visuals under `ArtRoot/World` visual layers.
- Do not move station identity into tile metadata.
- If Monogon props change walkability, update explicit collision under `GameplayRoot/Navigation/Collision`.

## 23. Recommended Next Step

0M-B - Hideout visual dressing / Monogon-style prop pass.
