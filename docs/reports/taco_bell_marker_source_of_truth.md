# Taco Bell Marker Source of Truth

Scene: `res://scenes/missions_iso/TacoBellIso_Editable.tscn`  
Scope: runtime-affecting marker authoring contract for manual editor work.

## Runtime truth rules

- Runtime marker discovery is recursive from `GameplayRoot/MarkerRoot` (via `_collect_marker_nodes_recursive` in `IsoMissionBase`).
- Marker identity is primarily by `marker_id`, `marker_type`, and link fields (not strict parent path).
- Do **not** change `marker_id` unless all references and validator/runtime checks are updated.

## Source-of-truth table

Legend:
- `runtime-used`: `yes` / `unknown` / `legacy`
- `safe_to_move`: `yes` / `caution` / `no`
- `safe_to_delete`: `no` unless explicitly called safe

| marker_id | node name | node path | marker_type | group_id | editor_display_name | marker_purpose | runtime-used | player-facing | safe_to_move | safe_to_delete | linked markers | mechanic | authoring notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| default | default | `.../Spawns/default` | player_spawn | default |  | gameplay | legacy | no | caution | no | player_spawn_main | route/transition infra | duplicate spawn fallback |
| player_spawn_main | player_spawn_main | `.../Spawns/player_spawn_main` | player_spawn | spawns |  | gameplay | yes | no | caution | no | bentley_spawn_main | objective flow | primary player start |
| bentley_spawn_main | bentley_spawn_main | `.../Spawns/bentley_spawn_main` | bentley_spawn | spawns |  | gameplay | yes | no | caution | no | player_spawn_main | objective flow | primary Bentley start |
| spawn_route_louis_entry | spawn_route_louis_entry | `.../Spawns/spawn_route_louis_entry` | transition_entry | route_louis_entry | Louis Route Entry Spawn | RouteEntrySpawn | legacy | no | caution | no | transition_route_louis_return, spawn_route_louis_return | route | legacy naming retained |
| spawn_route_louis_return | spawn_route_louis_return | `.../Spawns/spawn_route_louis_return` | transition_entry | route_louis_return | Louis Route Return Destination | RouteReturnDestination | legacy | no | caution | no | transition_route_louis_return | route | return destination anchor |
| spawn_route_vent_entry | spawn_route_vent_entry | `.../Spawns/spawn_route_vent_entry` | transition_entry | route_vent_entry | Bentley Vent Entry Spawn | VentEntrance | legacy | no | caution | no | transition_route_vent_return, spawn_route_vent_return | route | vent entry anchor |
| spawn_route_vent_return | spawn_route_vent_return | `.../Spawns/spawn_route_vent_return` | transition_entry | route_vent_return | Bentley Vent Return Destination | VentExit | legacy | no | caution | no | transition_route_vent_return | route | vent return anchor |
| objective_talk_to_louis | objective_talk_to_louis | `.../Objectives/objective_talk_to_louis` | objective |  |  | gameplay | yes | yes | caution | no | linked objective id | objective | required progression |
| objective_inspect_sauce_packets_or_receipt | objective_inspect_sauce_packets_or_receipt | `.../Objectives/objective_inspect_sauce_packets_or_receipt` | objective |  |  | gameplay | yes | yes | caution | no | clue_sauce_packet_vp | objective | required progression |
| scent_real_parking_garage_03 | scent_real_parking_garage_03 | `.../Objectives/scent_real_parking_garage_03` | objective |  | Scent Objective Proxy - Garage Decision | scent_objective_proxy | yes | indirect | caution | no | scent group markers | scent/objective | proxy only, not canonical scent trail |
| scent_fake_loading_dock | scent_fake_loading_dock | `.../Objectives/scent_fake_loading_dock` | objective |  | Scent Objective Proxy - Loading Dock | scent_objective_proxy | yes | indirect | caution | no | scent group markers | scent/objective | objective proxy marker |
| scent_fake_trash_area | scent_fake_trash_area | `.../Objectives/scent_fake_trash_area` | objective |  | Scent Objective Proxy - Trash | legacy_proxy | yes | indirect | caution | no | scent group markers | scent/objective | legacy proxy retained |
| scent_fake_trash_area_02 | scent_fake_trash_area_02 | `.../Objectives/scent_fake_trash_area_02` | objective |  | Scent Objective Proxy - Dock Alt | legacy_proxy | yes | indirect | caution | no | scent group markers | scent/objective | duplicate proxy retained |
| scent_fake_trash_area_03 | scent_fake_trash_area_03 | `.../Objectives/scent_fake_trash_area_03` | objective |  | Scent Objective Proxy - Garage | scent_objective_proxy | yes | indirect | caution | no | scent group markers | scent/objective | proxy near real decision cell |
| scent_real_parking_garage | scent_real_parking_garage | `.../ScentTrails/scent_real_parking_garage` | scent_trail_fake |  | Fake Scent Option A - Trash | scent_fake_option | yes | yes | caution | no | follow_correct_bentley_scent_trail | scent | **name/type mismatch retained for compatibility** |
| scent_real_parking_garage_02 | scent_real_parking_garage_02 | `.../ScentTrails/scent_real_parking_garage_02` | scent_trail_fake |  | Fake Scent Option B - Loading Dock | scent_fake_option | yes | yes | caution | no | follow_correct_bentley_scent_trail | scent | **name/type mismatch retained for compatibility** |
| objective_enter_parking_garage | objective_enter_parking_garage | `.../Objectives/objective_enter_parking_garage` | objective |  |  | gameplay | yes | yes | caution | no | linked objective id | objective | required |
| objective_get_garage_staff_keycard_or_bypass | objective_get_garage_staff_keycard_or_bypass | `.../Objectives/objective_get_garage_staff_keycard_or_bypass` | objective |  |  | gameplay | yes | yes | caution | no | route_garage_staff_keycard_route | objective | required |
| objective_retrieve_delivery_bag | objective_retrieve_delivery_bag | `.../Objectives/objective_retrieve_delivery_bag` | objective |  |  | gameplay | yes | yes | caution | no | clue_velvet_paw_stamp | objective | required |
| objective_escape_and_return_to_louis | objective_escape_and_return_to_louis | `.../Objectives/objective_escape_and_return_to_louis` | objective |  |  | gameplay | yes | yes | caution | no | exit_return_to_louis | objective | required |
| objective_find_hidden_dog_station_poop_bag_pack | objective_find_hidden_dog_station_poop_bag_pack | `.../Objectives/objective_find_hidden_dog_station_poop_bag_pack` | objective |  |  | gameplay | yes | yes | caution | no | poop_bag_dog_station | collectible/objective | optional |
| objective_complete_without_triggering_garage_alarm | objective_complete_without_triggering_garage_alarm | `.../Objectives/objective_complete_without_triggering_garage_alarm` | objective |  |  | gameplay | yes | yes | caution | no | alarmzone_alarm_zone_placeholder | objective/hazard | optional challenge |
| objective_find_glow_guy_under_garage_stairs | objective_find_glow_guy_under_garage_stairs | `.../Objectives/objective_find_glow_guy_under_garage_stairs` | objective |  |  | gameplay | yes | yes | caution | no | glow_guy_garage_stairs | collectible/objective | optional |
| objective_find_hidden_polaroid | objective_find_hidden_polaroid | `.../Objectives/objective_find_hidden_polaroid` | objective |  |  | gameplay | yes | yes | caution | no | hidden_polaroid_market_rain | collectible/objective | optional |
| objective_reach_exit_with_all_three_poop_bags | objective_reach_exit_with_all_three_poop_bags | `.../Objectives/objective_reach_exit_with_all_three_poop_bags` | objective |  |  | gameplay | yes | yes | caution | no | poop_bag_* + exit | objective | optional |
| garage_floor_1_guard_placeholder | garage_floor_1_guard_placeholder | `.../Enemies/garage_floor_1_guard_placeholder` | guard_spawn |  |  | gameplay | yes | indirect | caution | no | patrol points 01/02/03 | guard | required pressure |
| patrol_garage_floor_1_guard_placeholder_01 | patrol...01 | `.../Patrols/...01` | patrol_point | garage_floor_1_guard_placeholder |  | gameplay | yes | no | yes | no | guard + order chain | patrol | keep order |
| patrol_garage_floor_1_guard_placeholder_02 | patrol...02 | `.../Patrols/...02` | patrol_point | garage_floor_1_guard_placeholder |  | gameplay | yes | no | yes | no | guard + order chain | patrol | keep order |
| patrol_garage_floor_1_guard_placeholder_03 | patrol...03 | `.../Patrols/...03` | patrol_point | garage_floor_1_guard_placeholder |  | gameplay | yes | no | yes | no | guard + order chain | patrol | keep order |
| lightzone_fake_scent_trail_a_trash_area | lightzone...a | `.../LightZones/...a` | shadow_zone |  |  | gameplay | yes | indirect | yes | caution |  | camera/floodlight + light zone | passive stealth modifier area |
| lightzone_fake_scent_trail_b_loading_dock | lightzone...b | `.../LightZones/...b` | shadow_zone |  |  | gameplay | yes | indirect | yes | caution |  | camera/floodlight + light zone | passive stealth modifier area |
| lightzone_parking_garage_floor_1 | lightzone...garage | `.../LightZones/...garage` | shadow_zone |  |  | gameplay | yes | indirect | yes | caution |  | camera/floodlight + light zone | passive stealth modifier area |
| alarmzone_alarm_zone_placeholder | alarmzone_alarm_zone_placeholder | `.../AlarmZones/...` | alarm_zone |  |  | gameplay | yes | indirect | caution | no | garage_entry_beam runtime | alarm | one-shot beam source |
| encounter_garage_floor_2_ambush_marker | encounter_garage_floor_2_ambush_marker | `.../EncounterZones/...` | ambush_trigger |  |  | gameplay | yes | indirect | caution | no | ambush guard spawn | encounter | one-shot ambush |
| clue_sterling_delivery_token | clue_sterling_delivery_token | `.../Clues/...` | clue |  |  | gameplay | yes | yes | yes | caution | linked_clue_id | clue | required narrative |
| clue_velvet_paw_stamp | clue_velvet_paw_stamp | `.../Clues/...` | clue |  |  | gameplay | yes | yes | yes | caution | linked_clue_id | clue | required narrative |
| clue_route_manifest_half | clue_route_manifest_half | `.../Clues/...` | clue |  |  | gameplay | yes | yes | yes | caution | linked_clue_id | clue | required narrative |
| clue_sauce_packet_vp | clue_sauce_packet_vp | `.../Clues/...` | clue |  |  | gameplay | yes | yes | yes | caution | linked_clue_id | clue | required narrative |
| hidden_polaroid_market_rain | hidden_polaroid_market_rain | `.../Collectibles/...` | polaroid_hidden |  |  | gameplay | yes | yes | yes | caution | linked_collectible_id | collectible | optional |
| perfect_polaroid_garage_ambush | perfect_polaroid_garage_ambush | `.../Collectibles/...` | polaroid_perfect |  |  | gameplay | yes | yes | yes | caution | linked_collectible_id | collectible | optional |
| glow_guy_garage_stairs | glow_guy_garage_stairs | `.../Collectibles/...` | glow_guy |  |  | gameplay | yes | yes | yes | caution | linked_collectible_id | collectible | optional |
| tiny_icon_louis_delivery | tiny_icon_louis_delivery | `.../Collectibles/...` | tiny_icon |  |  | gameplay | yes | yes | yes | caution | linked_collectible_id | collectible | optional |
| keycard_garage_staff | keycard_garage_staff | `.../Collectibles/...` | polaroid_hidden |  |  | gameplay | yes | yes | caution | caution | linked_collectible_id | collectible/gate | keycard semantics via linked id |
| poop_bag_dog_station | poop_bag_dog_station | `.../Collectibles/...` | poop_bag |  |  | gameplay | yes | yes | yes | caution | linked_collectible_id | poop bag pickup | optional |
| poop_bag_garage_pet_bin | poop_bag_garage_pet_bin | `.../Collectibles/...` | poop_bag |  |  | gameplay | yes | yes | **caution** | caution | linked_collectible_id | poop bag pickup | currently flagged inside blocking collision by validator |
| poop_bag_lobby_trash | poop_bag_lobby_trash | `.../Collectibles/...` | poop_bag |  |  | gameplay | yes | yes | yes | caution | linked_collectible_id | poop bag pickup | optional |
| code_gate_garage_office | code_gate_garage_office | `.../Gates/...` | code_gate |  |  | gameplay | yes | yes | caution | no | linked objective id | gate | required |
| route_bentley_vent | route_bentley_vent | `.../Routes/...` | route_access |  | Bentley Vent Access | RouteAccess | yes | yes | caution | no | linked_route_id + vent spawn/return chain | route | vent chain root |
| route_louis_delivery_future | route_louis_delivery_future | `.../Routes/...` | route_access |  | Louis Route Access | RouteAccess | yes | yes | caution | no | linked_route_id + louis spawn/return chain | route | louis chain root |
| route_garage_staff_keycard_route | route_garage_staff_keycard_route | `.../Routes/...` | route_access |  | Garage Keycard Route Access | RouteAccess | yes | yes | caution | no | linked_route_id | route | keycard bypass |
| route_poopbagdecoy_loading_dock | route_poopbagdecoy_loading_dock | `.../Routes/...` | route_access |  | Poop Bag Distraction Point | PoopBagDistractionPoint | yes | yes | caution | no | linked_route_id | route/decoy | classify as decoy utility point |
| route_cameraterminal_security_booth | route_cameraterminal_security_booth | `.../Routes/...` | route_access |  | Security Booth Terminal Access | RouteAccess | yes | yes | caution | no | linked_route_id | route | terminal utility route |
| transition_garage_floor2_service_stairs | transition_garage_floor2_service_stairs | `.../Transitions/...` | transition | garage_floor2_service_stairs | Stairs Up Transition | StairsUp | yes | indirect | caution | no | group chain | transition | floor connector |
| transition_route_louis_return | transition_route_louis_return | `.../Transitions/...` | transition | route_louis_return | Louis Route Return Trigger | RouteReturnTrigger | yes | indirect | caution | no | spawn_route_louis_return | transition/route | Louis return trigger |
| transition_route_vent_return | transition_route_vent_return | `.../Transitions/...` | transition | route_vent_return | Bentley Vent Return Trigger | RouteReturnTrigger | yes | indirect | caution | no | spawn_route_vent_return | transition/route | Vent return trigger |
| exit_return_to_louis | exit_return_to_louis | `.../Exit/...` | exit | exit |  | gameplay | yes | yes | caution | no | objective escape chain | exit | mission completion |

## Special clarifications

### Poop bag decoy route classification

- `route_poopbagdecoy_loading_dock` is currently treated as **PoopBagDistractionPoint** (utility decoy marker), not a full traversal route chain.
- It is retained for compatibility and runtime linkage.

### Scent normalization stance

- Canonical `ScentTrails` markers now carry explicit editor metadata (`editor_display_name`, `scent_role`, `marker_purpose`) to remove “real/fake” naming ambiguity without breaking current runtime contracts.
- Objective scent proxies are explicitly tagged as proxies / legacy proxies.

### Designer group move sets (non-invasive)

No marker reparenting was applied in this pass. Use these logical move sets while selecting nodes manually:

- `ScentInvestigationGroup`
  - `scent_real_parking_garage`
  - `scent_real_parking_garage_02`
  - `scent_real_parking_garage_03`
  - `scent_fake_loading_dock`
  - `scent_fake_trash_area`
  - `scent_fake_trash_area_02`
  - `scent_fake_trash_area_03`
- `GarageBeamAmbushGroup`
  - `alarmzone_alarm_zone_placeholder`
  - `encounter_garage_floor_2_ambush_marker`
  - `objective_complete_without_triggering_garage_alarm`
- `LouisRouteGroup`
  - `route_louis_delivery_future`
  - `spawn_route_louis_entry`
  - `transition_route_louis_return`
  - `spawn_route_louis_return`
- `BentleyVentGroup`
  - `route_bentley_vent`
  - `spawn_route_vent_entry`
  - `transition_route_vent_return`
  - `spawn_route_vent_return`
- `CodeGateGroup`
  - `code_gate_garage_office`
  - `objective_get_garage_staff_keycard_or_bypass`
  - `route_garage_staff_keycard_route`
  - `route_cameraterminal_security_booth`
