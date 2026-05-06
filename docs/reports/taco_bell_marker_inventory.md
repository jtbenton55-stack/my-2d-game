# Taco Bell Marker Inventory

Scene audited: `res://scenes/missions_iso/TacoBellIso_Editable.tscn`

Audit constraints followed:
- No marker moved/deleted.
- No runtime redesign performed.
- Inventory is documentation-only.

## Quick Totals

- Marker nodes audited: **57**
- Marker folders found: `Spawns`, `Objectives`, `Patrols`, `Enemies`, `LightZones`, `AlarmZones`, `EncounterZones`, `Clues`, `Collectibles`, `ScentTrails`, `Gates`, `Routes`, `Transitions`, `Exit`
- Validator floor-placement check: no off-floor markers (`markers_outside_floor = []`)
- Known overlap hotspots: scent/objective cluster around trash/loading and some route utility nodes

## Per-Marker Inventory

Legend for classification:
- `active`: currently contributes to gameplay/runtime
- `placeholder`: intentionally non-final or proxy marker
- `unused/legacy`: currently not clearly consumed by runtime pathing
- `unknown`: unclear intent from data and runtime mapping

| Node Name | Node Path | marker_id | marker_type | group_id | linked ids | world position | tile/cell | parent folder | classification | off-map | overlap/duplicate | missing links |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| default | `GameplayRoot/MarkerRoot/Spawns/default` | default | player_spawn | default | - | (-1248,16) | n/a | Spawns | legacy duplicate | no | overlaps player spawn role | no |
| spawn_route_louis_entry | `.../Spawns/spawn_route_louis_entry` | spawn_route_louis_entry | transition_entry | route_louis_entry | - | (3840,0) | n/a | Spawns | placeholder/legacy | off-main-area | no direct duplicate | maybe (runtime uses `route_louis_entry` spawn id) |
| spawn_route_louis_return | `.../Spawns/spawn_route_louis_return` | spawn_route_louis_return | transition_entry | route_louis_return | - | (672,-48) | n/a | Spawns | placeholder/legacy | no | near transition return chain | maybe |
| spawn_route_vent_entry | `.../Spawns/spawn_route_vent_entry` | spawn_route_vent_entry | transition_entry | route_vent_entry | - | (3840,192) | n/a | Spawns | placeholder/legacy | off-main-area | no direct duplicate | maybe |
| spawn_route_vent_return | `.../Spawns/spawn_route_vent_return` | spawn_route_vent_return | transition_entry | route_vent_return | - | (1536,-64) | n/a | Spawns | placeholder/legacy | no | near vent transition chain | maybe |
| player_spawn_main | `.../Spawns/player_spawn_main` | player_spawn_main | player_spawn | spawns | - | (-1248,16) | n/a | Spawns | active | no | role-duplicate with `default` | no |
| bentley_spawn_main | `.../Spawns/bentley_spawn_main` | bentley_spawn_main | bentley_spawn | spawns | - | (-1216,32) | n/a | Spawns | active | no | none | no |
| objective_talk_to_louis | `.../Objectives/objective_talk_to_louis` | objective_talk_to_louis | objective (default) | - | linked_objective_id=talk_to_louis | (-1151,-1) | n/a | Objectives | active | no | none | no |
| objective_inspect_sauce_packets_or_receipt | `.../Objectives/objective_inspect_sauce_packets_or_receipt` | objective_inspect_sauce_packets_or_receipt | objective | - | linked_objective_id=inspect_sauce_packets_or_receipt | (-608,16) | n/a | Objectives | active | no | near clue_sauce_packet_vp | no |
| scent_real_parking_garage_03 | `.../Objectives/scent_real_parking_garage_03` | scent_real_parking_garage_03 | objective | - | linked_objective_id=follow_correct_bentley_scent_trail | (191,30) | n/a | Objectives | active objective proxy | no | scent cluster | no |
| objective_enter_parking_garage | `.../Objectives/objective_enter_parking_garage` | objective_enter_parking_garage | objective | - | linked_objective_id=enter_parking_garage | (608,16) | n/a | Objectives | active | no | near route lous future | no |
| objective_get_garage_staff_keycard_or_bypass | `.../Objectives/objective_get_garage_staff_keycard_or_bypass` | objective_get_garage_staff_keycard_or_bypass | objective | - | linked_objective_id=get_garage_staff_keycard_or_bypass | (833,-97) | n/a | Objectives | active | no | near route keycard + terminal | no |
| objective_retrieve_delivery_bag | `.../Objectives/objective_retrieve_delivery_bag` | objective_retrieve_delivery_bag | objective | - | linked_objective_id=retrieve_delivery_bag | (1984,126) | n/a | Objectives | active | no | near clue cluster | no |
| objective_escape_and_return_to_louis | `.../Objectives/objective_escape_and_return_to_louis` | objective_escape_and_return_to_louis | objective | - | linked_objective_id=escape_and_return_to_louis | (-992,141) | n/a | Objectives | active | no | near exit objective | no |
| objective_find_hidden_dog_station_poop_bag_pack | `.../Objectives/objective_find_hidden_dog_station_poop_bag_pack` | objective_find_hidden_dog_station_poop_bag_pack | objective | - | linked_objective_id=find_hidden_dog_station_poop_bag_pack | (-672,-80) | n/a | Objectives | active | no | near poop_bag_dog_station | no |
| objective_complete_without_triggering_garage_alarm | `.../Objectives/objective_complete_without_triggering_garage_alarm` | objective_complete_without_triggering_garage_alarm | objective | - | linked_objective_id=complete_without_triggering_garage_alarm | (962,31) | n/a | Objectives | active | no | near alarm marker | no |
| scent_fake_loading_dock | `.../Objectives/scent_fake_loading_dock` | scent_fake_loading_dock | objective | - | linked_objective_id=recover_decoy_bag_extra_intel | (225,113) | n/a | Objectives | active objective proxy | no | overlaps scent/decoy route | no |
| objective_find_glow_guy_under_garage_stairs | `.../Objectives/objective_find_glow_guy_under_garage_stairs` | objective_find_glow_guy_under_garage_stairs | objective | - | linked_objective_id=find_glow_guy_under_garage_stairs | (1343,0) | n/a | Objectives | active | no | near glow guy + stairs transition | no |
| objective_find_hidden_polaroid | `.../Objectives/objective_find_hidden_polaroid` | objective_find_hidden_polaroid | objective | - | linked_objective_id=find_hidden_polaroid | (-704,64) | n/a | Objectives | active | no | none | no |
| objective_reach_exit_with_all_three_poop_bags | `.../Objectives/objective_reach_exit_with_all_three_poop_bags` | objective_reach_exit_with_all_three_poop_bags | objective | - | linked_objective_id=reach_exit_with_all_three_poop_bags | (-865,174) | n/a | Objectives | active | no | near exit | no |
| scent_fake_trash_area | `.../Objectives/scent_fake_trash_area` | scent_fake_trash_area | objective | - | linked_objective_id=complete_without_wrong_scent_trail | (-160,-80) | n/a | Objectives | active objective proxy | no | duplicate scent objective proxy | no |
| scent_fake_trash_area_02 | `.../Objectives/scent_fake_trash_area_02` | scent_fake_trash_area_02 | objective | - | linked_objective_id=complete_without_wrong_scent_trail | (192,96) | n/a | Objectives | active objective proxy | no | duplicate scent objective proxy | no |
| scent_fake_trash_area_03 | `.../Objectives/scent_fake_trash_area_03` | scent_fake_trash_area_03 | objective | - | linked_objective_id=complete_without_wrong_scent_trail | (224,16) | n/a | Objectives | active objective proxy | no | duplicate scent objective proxy | no |
| patrol_garage_floor_1_guard_placeholder_01 | `.../Patrols/patrol_garage_floor_1_guard_placeholder_01` | patrol_garage_floor_1_guard_placeholder_01 | patrol_point | garage_floor_1_guard_placeholder | linked_guard_id=garage_floor_1_guard_placeholder;order=1 | (582,28) | n/a | Patrols | active | no | patrol chain | no |
| patrol_garage_floor_1_guard_placeholder_02 | `.../Patrols/patrol_garage_floor_1_guard_placeholder_02` | patrol_garage_floor_1_guard_placeholder_02 | patrol_point | garage_floor_1_guard_placeholder | linked_guard_id=garage_floor_1_guard_placeholder;order=2 | (672,78) | n/a | Patrols | active | no | patrol chain | no |
| patrol_garage_floor_1_guard_placeholder_03 | `.../Patrols/patrol_garage_floor_1_guard_placeholder_03` | patrol_garage_floor_1_guard_placeholder_03 | patrol_point | garage_floor_1_guard_placeholder | linked_guard_id=garage_floor_1_guard_placeholder;order=3 | (762,28) | n/a | Patrols | active | no | patrol chain | no |
| garage_floor_1_guard_placeholder | `.../Enemies/garage_floor_1_guard_placeholder` | garage_floor_1_guard_placeholder | guard_spawn | - | linked_guard_id=garage_floor_1_guard_placeholder | (672,48) | n/a | Enemies | active | no | linked to 3 patrol points | no |
| lightzone_fake_scent_trail_a_trash_area | `.../LightZones/lightzone_fake_scent_trail_a_trash_area` | lightzone_fake_scent_trail_a_trash_area | shadow_zone | - | - | (-160,-80) | n/a | LightZones | active | no | near scent fake trash | no |
| lightzone_fake_scent_trail_b_loading_dock | `.../LightZones/lightzone_fake_scent_trail_b_loading_dock` | lightzone_fake_scent_trail_b_loading_dock | shadow_zone | - | - | (32,112) | n/a | LightZones | active | no | near scent loading | no |
| lightzone_parking_garage_floor_1 | `.../LightZones/lightzone_parking_garage_floor_1` | lightzone_parking_garage_floor_1 | shadow_zone | - | - | (864,16) | n/a | LightZones | active | no | separate zone coverage | no |
| alarmzone_alarm_zone_placeholder | `.../AlarmZones/alarmzone_alarm_zone_placeholder` | alarmzone_alarm_zone_placeholder | alarm_zone | - | - | (960,64) | n/a | AlarmZones | active placeholder id | no | near objective/alarm cluster | no |
| encounter_garage_floor_2_ambush_marker | `.../EncounterZones/encounter_garage_floor_2_ambush_marker` | encounter_garage_floor_2_ambush_marker | ambush_trigger | - | - | (1440,80) | n/a | EncounterZones | active | no | tied to ambush beat | no |
| clue_sterling_delivery_token | `.../Clues/clue_sterling_delivery_token` | clue_sterling_delivery_token | clue | - | linked_clue_id=sterling_delivery_token | (1888,48) | n/a | Clues | active | no | clue cluster near bag room | no |
| clue_velvet_paw_stamp | `.../Clues/clue_velvet_paw_stamp` | clue_velvet_paw_stamp | clue | - | linked_clue_id=velvet_paw_stamp | (2016,48) | n/a | Clues | active | no | near retrieve objective | no |
| clue_route_manifest_half | `.../Clues/clue_route_manifest_half` | clue_route_manifest_half | clue | - | linked_clue_id=route_manifest_half | (1377,-81) | n/a | Clues | active | no | near code/glow/stairs | no |
| clue_sauce_packet_vp | `.../Clues/clue_sauce_packet_vp` | clue_sauce_packet_vp | clue | - | linked_clue_id=sauce_packet_vp | (-544,48) | n/a | Clues | active | no | near inspect objective | no |
| hidden_polaroid_market_rain | `.../Collectibles/hidden_polaroid_market_rain` | hidden_polaroid_market_rain | polaroid_hidden | - | linked_collectible_id=taco_bell_midnight_market_rain | (1248,-48) | n/a | Collectibles | active | no | none | no |
| perfect_polaroid_garage_ambush | `.../Collectibles/perfect_polaroid_garage_ambush` | perfect_polaroid_garage_ambush | polaroid_perfect | - | linked_collectible_id=taco_bell_perfect_ambush | (1504,48) | n/a | Collectibles | active | no | near ambush area | no |
| glow_guy_garage_stairs | `.../Collectibles/glow_guy_garage_stairs` | glow_guy_garage_stairs | glow_guy | - | linked_collectible_id=taco_bell_glow_guys | (1376,-16) | n/a | Collectibles | active | no | near stairs objective | no |
| tiny_icon_louis_delivery | `.../Collectibles/tiny_icon_louis_delivery` | tiny_icon_louis_delivery | tiny_icon | - | linked_collectible_id=louis_tiny_icon_delivery_bag | (-960,64) | n/a | Collectibles | active | no | near escape route | no |
| keycard_garage_staff | `.../Collectibles/keycard_garage_staff` | keycard_garage_staff | polaroid_hidden (typed as keycard target) | - | linked_collectible_id=garage_staff_keycard | (928,-112) | n/a | Collectibles | active (type mismatch naming) | no | near route + terminal | no |
| poop_bag_dog_station | `.../Collectibles/poop_bag_dog_station` | poop_bag_dog_station | poop_bag | - | linked_collectible_id=taco_bell_poop_bag_1 | (-608,-80) | n/a | Collectibles | active | no | near objective find hidden bag | no |
| poop_bag_garage_pet_bin | `.../Collectibles/poop_bag_garage_pet_bin` | poop_bag_garage_pet_bin | poop_bag | - | linked_collectible_id=taco_bell_poop_bag_2 | (1026,65) | n/a | Collectibles | active | no | near alarm zone | no |
| poop_bag_lobby_trash | `.../Collectibles/poop_bag_lobby_trash` | poop_bag_lobby_trash | poop_bag | - | linked_collectible_id=taco_bell_poop_bag_3 | (-1024,192) | n/a | Collectibles | active | no | near exit objective chain | no |
| scent_real_parking_garage | `.../ScentTrails/scent_real_parking_garage` | scent_real_parking_garage | scent_trail_fake | - | linked_objective_id=follow_correct_bentley_scent_trail | (-160,-80) | n/a | ScentTrails | active but mislabeled naming | no | duplicates fake cluster | no |
| scent_real_parking_garage_02 | `.../ScentTrails/scent_real_parking_garage_02` | scent_real_parking_garage_02 | scent_trail_fake | - | linked_objective_id=follow_correct_bentley_scent_trail | (192,96) | n/a | ScentTrails | active but mislabeled naming | no | duplicates fake cluster | no |
| code_gate_garage_office | `.../Gates/code_gate_garage_office` | code_gate_garage_office | code_gate | - | linked_objective_id=solve_garage_office_code | (1408,-32) | n/a | Gates | active | no | near stairs/glow objective cluster | no |
| route_bentley_vent | `.../Routes/route_bentley_vent` | route_bentley_vent | route_access | - | linked_route_id=bentley_vent_route | (958,-62) | n/a | Routes | active | no | none | no |
| route_louis_delivery_future | `.../Routes/route_louis_delivery_future` | route_louis_delivery_future | route_access | - | linked_route_id=louis_delivery_route_future_shortcut | (576,-61) | n/a | Routes | active | no | none | no |
| route_garage_staff_keycard_route | `.../Routes/route_garage_staff_keycard_route` | route_garage_staff_keycard_route | route_access | - | linked_route_id=garage_staff_keycard_route | (925,-144) | n/a | Routes | active | no | near keycard + terminal route | no |
| route_poopbagdecoy_loading_dock | `.../Routes/route_poopbagdecoy_loading_dock` | route_poopbagdecoy_loading_dock | route_access | - | linked_route_id=poopbagdecoy_loading_dock | (160,112) | n/a | Routes | active | no | overlaps loading scent/objective cluster | no |
| route_cameraterminal_security_booth | `.../Routes/route_cameraterminal_security_booth` | route_cameraterminal_security_booth | route_access | - | linked_route_id=cameraterminal_security_booth | (990,-83) | n/a | Routes | active | no | near keycard route cluster | no |
| transition_garage_floor2_service_stairs | `.../Transitions/transition_garage_floor2_service_stairs` | transition_garage_floor2_service_stairs | transition | garage_floor2_service_stairs | - | (1533,0) | n/a | Transitions | active | no | near glow/code objective cluster | no |
| transition_route_louis_return | `.../Transitions/transition_route_louis_return` | transition_route_louis_return | transition | route_louis_return | - | (3840,0) | n/a | Transitions | active route return trigger | off-main-area | paired with spawn_route_louis_entry region | no |
| transition_route_vent_return | `.../Transitions/transition_route_vent_return` | transition_route_vent_return | transition | route_vent_return | - | (3840,192) | n/a | Transitions | active route return trigger | off-main-area | paired with spawn_route_vent_entry region | no |
| exit_return_to_louis | `.../Exit/exit_return_to_louis` | exit_return_to_louis | exit | exit | - | (-928,176) | n/a | Exit | active | no | near escape objective chain | no |

## Focus Audit: Scent Marker Confusion

### Classification model used

- `scent_sniff_point`
- `scent_path_point`
- `scent_real_option`
- `scent_fake_option`
- `scent_objective_proxy`
- `heat_mutation_option`
- `debug_only`
- `legacy_proxy`
- `unused_unknown`

### Scent marker classification (current)

- `scent_real_parking_garage` (`ScentTrails`)
  - classified as: `scent_fake_option`
  - runtime role: canonical scent option marker
  - note: `marker_id` name says "real", runtime type retained as fake for compatibility
- `scent_real_parking_garage_02` (`ScentTrails`)
  - classified as: `scent_fake_option`
  - runtime role: canonical scent option marker
  - note: same compatibility caveat as above
- `scent_real_parking_garage_03` (`Objectives`)
  - classified as: `scent_objective_proxy`
  - runtime role: objective proxy
- `scent_fake_loading_dock` (`Objectives`)
  - classified as: `scent_objective_proxy`
  - runtime role: objective proxy
- `scent_fake_trash_area` (`Objectives`)
  - classified as: `legacy_proxy`
- `scent_fake_trash_area_02` (`Objectives`)
  - classified as: `legacy_proxy`
- `scent_fake_trash_area_03` (`Objectives`)
  - classified as: `scent_objective_proxy`

### Scent-specific move/delete guidance

- Move together (caution): canonical `ScentTrails` markers and the proxied objective markers in the same local scent cluster.
- Not safe to delete yet:
  - all `ScentTrails` markers above
  - all objective scent proxies marked `legacy_proxy` (until chain consolidation)
  - any marker linked to `follow_correct_bentley_scent_trail` or `complete_without_wrong_scent_trail`

### Heat mutation scent markers

- No dedicated `heat_mutation_option` marker type is currently authored in this scene; heat-state effects are driven by runtime logic and linked placeholder systems.

## Focus Audit: Route / Spawn / Transition Confusion

### Route classification model used

- `RouteAccess`
- `RouteEntrySpawn`
- `RoutePassageMarker`
- `RouteReturnTrigger`
- `RouteReturnDestination`
- `RouteExit`
- `VentEntrance`
- `VentExit`
- `StairsUp`
- `StairsDown`
- `LegacyRouteProxy`
- `UnknownRouteMarker`

### Route marker classifications (current)

- `route_louis_delivery_future`: `RouteAccess`
- `spawn_route_louis_entry`: `RouteEntrySpawn` (legacy naming retained)
- `transition_route_louis_return`: `RouteReturnTrigger`
- `spawn_route_louis_return`: `RouteReturnDestination`
- `route_bentley_vent`: `RouteAccess`
- `spawn_route_vent_entry`: `VentEntrance`
- `transition_route_vent_return`: `RouteReturnTrigger`
- `spawn_route_vent_return`: `VentExit`
- `transition_garage_floor2_service_stairs`: `StairsUp`
- `route_garage_staff_keycard_route`: `RouteAccess`
- `route_cameraterminal_security_booth`: `RouteAccess`
- `route_poopbagdecoy_loading_dock`: `LegacyRouteProxy` (reclassified conceptually as `PoopBagDistractionPoint`)

### Route chain ownership summary

- Louis route chain:
  - access: `route_louis_delivery_future`
  - entry: `spawn_route_louis_entry`
  - return trigger: `transition_route_louis_return`
  - return destination: `spawn_route_louis_return`
  - bypass target: garage entry pressure area
- Bentley vent chain:
  - access: `route_bentley_vent`
  - entry: `spawn_route_vent_entry`
  - return trigger: `transition_route_vent_return`
  - return destination: `spawn_route_vent_return`
  - bypass target: office-gate pressure lane
- Poop bag decoy:
  - currently a utility distraction anchor, not a full route traversal chain

## Runtime/Link Integrity Flags

- Off-floor markers: none reported.
- Missing-link hard failures: none obvious from linked id fields.
- Confusing naming:
  - `scent_real_*` markers typed as `scent_trail_fake`
  - `spawn_route_*` ids do not exactly match runtime `route_*` spawn-id conventions.
- Overlap clusters (non-fatal but designer-confusing): scent/objective/loading-dock and keycard-route/terminal regions.
