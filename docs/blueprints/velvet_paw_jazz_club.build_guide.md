# Build Guide: velvet_paw_jazz_club_v1

Generated from `velvet_paw_jazz_club.blueprint.json`. Do not edit by hand; re-run `python src/tools/editor/level_blueprint/generate_blueprint_guide.py docs/blueprints/velvet_paw_jazz_club.blueprint.json` after changing the spec.

- Mission ID: `velvet_paw_jazz_club`
- Canvas: 4480 x 3200 px
- Grid size: 64 px
- Description: Act 1 Mission 2 - Velvet Paw Jazz Club (Yordano, ~30 min). Full story build: alley entry past the front queue, social stealth on the club floor, staff badge + two setlist clues feeding the stage setlist hack, basement server vault for the Black Ledger Shard with Yordano's help, hostile-club return, owner suite fight for the blackmail briefcase, and a bass-drop basement escape. Pacing target: exterior 3 min, floor stealth 6 min, badge/clues/setlist 7 min, basement 6 min, hostile return 4 min, suite fight 3 min, escape 2 min.

## Setup

1. Open your mission scene (start from `scenes/templates/IsoMissionTemplate.tscn` for a new mission).
2. Add a `Node2D` named `AuthoringBlueprintLayer` with the script `res://src/tools/authoring/AuthoringBlueprintLayer.gd` (a good parent is `GameplayRoot/LayoutRoot`). Keep the node at position (0, 0).
3. Set its `blueprint_path` to `res://docs/blueprints/velvet_paw_jazz_club.blueprint.json`. The blueprint appears in the editor viewport.
4. Tune `opacity`, `draw_on_top`, and the `show_*` toggles while you work. The layer frees itself at runtime and is never visible to players.

## Trace Layout (Mission Paint Dock)

Paint each region onto its LayoutRoot tile layer:

| Region | Kind | Paint layer |
| --- | --- | --- |
| Street, Front Queue & Alley | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Club Main Floor (bar west, dance floor center, VIP east) | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Stage & Stage Wing | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Backstage / Green Room | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Bathroom | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Owner Suite - Floor 2 (reached via rig stairs teleport) | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Basement - Service Level (reached via stage hatch teleport) | floor | `GameplayRoot/LayoutRoot/FloorLayer` |
| Club Outer Walls (front door gap center-south, staff side door gap east-south) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Stage Row Wall (wing gaps: hatch near piano at x1024, staff gate at x2048) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Bathroom Wall (door gap at south) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Stage Wing Divider (staff gate gap at south end) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| VIP Rope Rail (rope gap at north end) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Owner Suite Walls (stairs arrival gap at south-west) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Basement Walls (hatch arrival gap at south-west, escape hatch gap at east) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Server Vault Cage (vault door gap at south center) | wall | `GameplayRoot/LayoutRoot/WallLayer` |
| Bar Counter | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| DJ Rig / Speaker Stack (owner stairs run behind this on floor plan east) | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Grand Piano (service hatch just east of it) | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Green Room Couch | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| VIP Booth North | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| VIP Booth South | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Owner Desk | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Server Rack Row (inside vault cage) | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Basement Storage Shelves | collision_barrier | `GameplayRoot/LayoutRoot/CollisionBarrierLayer` |
| Bar Corner (setlist-alarm safe spot) | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Dance Floor Silhouette (setlist-alarm safe spot) | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Subwoofer Stack Cover | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Costume Rack Cover (green room) | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Alley Dumpster | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Basement Crates | cover | `GameplayRoot/LayoutRoot/CoverLayer` |
| Spawn Area (street west) | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |
| Front Door (too crowded - queue blocks it) | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |
| Staff Side Door (the real way in) | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |
| Stage Center (setlist puzzle) | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |
| Owner Suite Balcony (briefcase) | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |
| Extraction Hatch (bass-drop escape) | marker | `GameplayRoot/LayoutRoot/MarkerTileLayer` |

## Place Mechanics (Mission Dock)

Slots are listed in dependency order; place them top to bottom. Use the Mission Dock palette's "Place From Blueprint" section to prefill each slot, then place at the typed position or with the mouse.

### 1. `player_start` - PlayerStartMarker

- Suggested ID: `start_main`
- Position: (256, 2880)
- Parent: `GameplayRoot/MarkerRoot/Spawns`
- Instructions: Parmida and Bentley arrive on the street, west of the front queue.

### 2. `queue_inspection` - InspectionZone

- Suggested ID: `velvet_paw_jazz_club.inspection_zone.01`
- Position: (1312, 2624)
- Zone size: 256 x 192
- Parent: `MissionMechanics`
- Instructions: Front-door bouncer works the velvet rope. Entering the queue without a wristband bounces the player back - this sells 'the front is too crowded' and pushes them toward the alley.

### 3. `queue_eavesdrop` - EavesdropZone

- Suggested ID: `velvet_paw_jazz_club.eavesdrop_zone.01`
- Position: (960, 2816)
- Zone size: 192 x 128
- Parent: `MissionMechanics`
- Instructions: Two patrons in line gripe that the horn section props the staff side door open between sets. Teaches the alley route without a map marker.

### 4. `alley_dialogue` - DialogueTriggerZone

- Suggested ID: `velvet_paw_jazz_club.dialogue_trigger_zone.01`
- Position: (2688, 2816)
- Zone size: 192 x 192
- Parent: `MissionMechanics`
- Instructions: Micro-cutscene intro beat: Bentley sniffs the alley ('Too many colognes. The bass line is honest, though.'). One-shot.

### 5. `dead_drop` - DeadDropNode

- Suggested ID: `velvet_paw_jazz_club.dead_drop_node.01`
- Position: (3136, 2944)
- Parent: `MissionMechanics`
- Instructions: Optional: loose brick behind the alley. Leaving a copy of the VIP voicemail here foreshadows Rewrite Room (Mere picks it up between missions).

### 6. `poop_bag_alley` - PoopBagAuthor

- Suggested ID: `velvet_paw_jazz_club.poop_bag_author.01`
- Position: (3264, 2752)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Poop bag 1 of 3, by the alley dumpster. Parent under GameplayRoot/SecurityAuthoringRoot.

### 7. `side_door_entry` - TriggerZone

- Suggested ID: `velvet_paw_jazz_club.trigger_zone.01`
- Position: (2944, 2496)
- Zone size: 128 x 96
- Parent: `MissionMechanics`
- Instructions: Staff side door in the alley - the actual entrance. Crossing it advances the mission to the social-stealth step. The eavesdrop zone hints at it.

### 8. `floor_music` - MusicTriggerZone

- Suggested ID: `velvet_paw_jazz_club.music_trigger_zone.01`
- Position: (2688, 2368)
- Zone size: 384 x 128
- Parent: `MissionMechanics`
- Instructions: House jazz set kicks in when the player steps onto the club floor from the side door.

### 9. `bouncer_route_a` - GuardPatrolRouteAuthor

- Suggested ID: `velvet_paw_jazz_club.guard_patrol_route_author.01`
- Position: (896, 1600)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Bouncer loop A: bar front, along the dance floor west edge, back past the bathroom door. Parent under GameplayRoot/SecurityAuthoringRoot.

### 10. `bouncer_spawn_a` - GuardSpawnAuthor

- Suggested ID: `velvet_paw_jazz_club.guard_spawn_author.01`
- Position: (896, 1728)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Depends on: `bouncer_route_a`
- Instructions: Bouncer on route A. Parent under GameplayRoot/SecurityAuthoringRoot.

### 11. `bouncer_route_b` - GuardPatrolRouteAuthor

- Suggested ID: `velvet_paw_jazz_club.guard_patrol_route_author.02`
- Position: (2240, 2112)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Bouncer loop B: dance floor south edge and the VIP rope gap. Parent under GameplayRoot/SecurityAuthoringRoot.

### 12. `bouncer_spawn_b` - GuardSpawnAuthor

- Suggested ID: `velvet_paw_jazz_club.guard_spawn_author.02`
- Position: (2240, 2240)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Depends on: `bouncer_route_b`
- Instructions: Bouncer on route B. Parent under GameplayRoot/SecurityAuthoringRoot.

### 13. `professionalism_meter` - ProfessionalismMeterNode

- Suggested ID: `velvet_paw_jazz_club.professionalism_meter_node.01`
- Position: (1600, 1280)
- Parent: `MissionMechanics`
- Instructions: Mission-wide social meter for the club floor. Bar task, VIP protocol, and inspection zones feed this; keep professionalism up or bouncers escalate faster.

### 14. `floor_inspection` - InspectionZone

- Suggested ID: `velvet_paw_jazz_club.inspection_zone.02`
- Position: (1600, 1600)
- Zone size: 320 x 256
- Parent: `MissionMechanics`
- Instructions: Head bouncer scans the dance floor center. Player needs an active cover story (bar_task) or a hide/cover option to pass. Stealth angle 1.

### 15. `bar_task` - BelievableTaskZone

- Suggested ID: `velvet_paw_jazz_club.believable_task_zone.01`
- Position: (512, 1408)
- Zone size: 128 x 128
- Parent: `MissionMechanics`
- Instructions: Clearing glasses at the bar sells the 'new staff' cover story used against floor_inspection.

### 16. `barback_distraction` - DistractionObject

- Suggested ID: `velvet_paw_jazz_club.distraction_object.01`
- Position: (704, 1856)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Instructions: Glass rack: knocking it pulls the nearest bouncer to the bar for a few seconds.

### 17. `investigation_point` - InvestigationPointNode

- Suggested ID: `velvet_paw_jazz_club.investigation_point_node.01`
- Position: (1024, 1728)
- Parent: `MissionMechanics`
- Instructions: Spilled drink on the floor. Bouncers who hear noise investigate here first, buying the player a route around them.

### 18. `noise_emitter` - NoiseEmitterNode

- Suggested ID: `velvet_paw_jazz_club.noise_emitter_node.01`
- Position: (1472, 1984)
- Parent: `MissionMechanics`
- Instructions: Subwoofer throb on the dance floor masks player footsteps inside its radius. Stealth angle 2.

### 19. `bentley_wait` - BentleyWaitMarker

- Suggested ID: `velvet_paw_jazz_club.bentley_wait_marker.01`
- Position: (1216, 2240)
- Parent: `MissionMechanics`
- Instructions: Park Bentley by the dance floor edge before working the VIP lounge - a dog in VIP breaks the protocol zone instantly.

### 20. `hide_booth` - HideSpotNode

- Suggested ID: `velvet_paw_jazz_club.hide_spot_node.01`
- Position: (2848, 1952)
- Parent: `MissionMechanics`
- Instructions: Slip between the two VIP booths to drop out of a bouncer's sightline.

### 21. `vip_protocol` - ProtocolZone

- Suggested ID: `velvet_paw_jazz_club.protocol_zone.01`
- Position: (2688, 1664)
- Zone size: 320 x 512
- Parent: `MissionMechanics`
- Instructions: VIP lounge etiquette: walk, no interact-spam, no dog. Ties into the vip_alt_route mutation roll - on strict rolls, require the bar_task cover first.

### 22. `vip_phone_search` - SearchZone

- Suggested ID: `velvet_paw_jazz_club.search_zone.01`
- Position: (2816, 2304)
- Zone size: 128 x 96
- Parent: `MissionMechanics`
- Instructions: VIP booth phone: voicemail from Sterling's assistant ('Shred before midnight'). Reveals where the staff badge hangs in the green room and sets the flag staff_badge_pickup requires.

### 23. `camera_vip` - SecurityCameraAuthor

- Suggested ID: `velvet_paw_jazz_club.security_camera_author.01`
- Position: (2624, 1600)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Camera over the VIP rope gap, sweeping the lounge. Parent under GameplayRoot/SecurityAuthoringRoot.

### 24. `bathroom_glow_guy` - GlowGuyAuthor

- Suggested ID: `velvet_paw_jazz_club.glow_guy_author.01`
- Position: (192, 576)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: velvet_bathroom_glow_guy - hidden Glow Guy behind the bathroom sink. Parent under GameplayRoot/SecurityAuthoringRoot.

### 25. `bathroom_bark` - BarkTrigger

- Suggested ID: `velvet_paw_jazz_club.bark_trigger.01`
- Position: (320, 832)
- Parent: `MissionMechanics`
- Instructions: Bentley bark line in the bathroom doorway: '(Bentley respects the grout lines.)' Points sharp-eared players at the Glow Guy.

### 26. `bentley_crawl` - BentleyCrawlspaceConnector

- Suggested ID: `velvet_paw_jazz_club.bentley_crawlspace_connector.01`
- Position: (2496, 1024)
- Parent: `MissionMechanics`
- Instructions: Optional route: vent in the stage row wall. Bentley crawls from the club floor into the green room and can fetch the staff badge without the VIP voicemail lead.

### 27. `staff_badge_pickup` - InventoryPickupNode

- Suggested ID: `velvet_paw_jazz_club.inventory_pickup_node.01`
- Position: (2432, 832)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `vip_phone_search`
- Instructions: Staff badge on the green room dressing rail. Main lead comes from vip_phone_search; bentley_crawl is the alternate way to reach it.

### 28. `staff_gate` - LockedInteractionNode

- Suggested ID: `velvet_paw_jazz_club.locked_interaction_node.01`
- Position: (2048, 960)
- Zone size: 96 x 128
- Parent: `MissionMechanics`
- Depends on: `staff_badge_pickup`
- Instructions: Staff gate at the south end of the stage wing divider. Unlocks with the staff badge and opens the whole stage/backstage row.

### 29. `green_room_lockers` - InteractiveContainer

- Suggested ID: `velvet_paw_jazz_club.interactive_container.01`
- Position: (2720, 512)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Instructions: Band lockers: tip-jar cash plus a rumor note about the owner's balcony habit (soft hint at where the briefcase ends up).

### 30. `clue_manager_notes` - ClueAuthor

- Suggested ID: `velvet_paw_jazz_club.clue_author.01`
- Position: (2304, 512)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Depends on: `staff_gate`
- Instructions: Stage Manager's Notes on the green room couch table - setlist clue 2 of 2 (five songs, release-timeline order). Parent under GameplayRoot/SecurityAuthoringRoot.

### 31. `soundcheck_task` - SideObjectiveNode

- Suggested ID: `velvet_paw_jazz_club.side_objective_node.01`
- Position: (1920, 704)
- Parent: `MissionMechanics`
- Depends on: `staff_gate`
- Instructions: Optional micro-objective: run the sound check at the wing mixing board. Completing it adds a crowd-cue hint line to the setlist puzzle.

### 32. `clue_setlist` - ClueAuthor

- Suggested ID: `velvet_paw_jazz_club.clue_author.02`
- Position: (832, 704)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Depends on: `staff_gate`
- Instructions: Crumpled Setlist Fragment taped to the piano lid - setlist clue 1 of 2 (album arc order). Parent under GameplayRoot/SecurityAuthoringRoot.

### 33. `backstage_crate_search` - SearchZone

- Suggested ID: `velvet_paw_jazz_club.search_zone.02`
- Position: (1568, 896)
- Zone size: 128 x 96
- Parent: `MissionMechanics`
- Depends on: `clue_setlist`, `clue_manager_notes`
- Instructions: Mid-mission twist: prop crates hold a DECOY ledger with blank pages. Searching it after both clues fires the 'Sterling's crew planted a prop' beat and points at the basement.

### 34. `setlist_terminal` - TerminalHackNode

- Suggested ID: `velvet_paw_jazz_club.terminal_hack_node.01`
- Position: (1152, 640)
- Parent: `MissionMechanics`
- Depends on: `clue_setlist`, `clue_manager_notes`
- Instructions: The stage setlist puzzle: reorder five songs using both clues (album arc + release timeline). Success opens the service hatch, grants the Sterling evidence clue jazz_club_encoded_setlist (connects_to: Rewrite Room), and triggers stage_presentation. Failure triggers wrong_note_alarm.

### 35. `stage_presentation` - PresentationSequencePlayer

- Suggested ID: `velvet_paw_jazz_club.presentation_sequence_player.01`
- Position: (1152, 512)
- Parent: `MissionMechanics`
- Depends on: `setlist_terminal`
- Instructions: Spotlight sweep + Yordano line ('House lights love you. Don't waste the downbeat.') when the setlist is solved.

### 36. `wrong_note_alarm` - SecurityEffectSetAuthor

- Suggested ID: `velvet_paw_jazz_club.security_effect_set_author.01`
- Position: (1344, 640)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Depends on: `setlist_terminal`
- Instructions: Setlist-alarm effect set: on terminal failure, red wash overlay + temporary reinforcements for ~8s. Bar Corner and Dance Floor Silhouette cover regions are the safe spots. Parent under GameplayRoot/SecurityAuthoringRoot.

### 37. `alarm_spawn` - GuardSpawnAuthor

- Suggested ID: `velvet_paw_jazz_club.guard_spawn_author.03`
- Position: (1664, 1088)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Depends on: `wrong_note_alarm`
- Instructions: Reinforcement bouncer spawn used only by the setlist alarm. Parent under GameplayRoot/SecurityAuthoringRoot.

### 38. `backstage_hatch` - RouteUnlockNode

- Suggested ID: `velvet_paw_jazz_club.route_unlock_node.01`
- Position: (1024, 832)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `setlist_terminal`
- Instructions: Service basement hatch east of the piano. Opens when the setlist terminal is solved.

### 39. `basement_teleport` - TeleportZone

- Suggested ID: `velvet_paw_jazz_club.teleport_zone.01`
- Position: (1024, 928)
- Zone size: 96 x 64
- Parent: `MissionMechanics`
- Depends on: `backstage_hatch`
- Instructions: Drop through the open hatch into the basement (targets basement_arrival).

### 40. `basement_arrival` - TeleportTargetMarker

- Suggested ID: `velvet_paw_jazz_club.teleport_target_marker.01`
- Position: (3616, 2944)
- Parent: `MissionMechanics`
- Depends on: `basement_teleport`
- Instructions: Basement arrival point at the bottom of the service ladder.

### 41. `yordano_dialogue` - DialogueTriggerZone

- Suggested ID: `velvet_paw_jazz_club.dialogue_trigger_zone.02`
- Position: (3776, 2816)
- Zone size: 192 x 192
- Parent: `MissionMechanics`
- Depends on: `basement_arrival`
- Instructions: Friend beat: Yordano over the house PA explains the vault handshake hum and green-lights the shard pull. One-shot.

### 42. `camera_basement` - SecurityCameraAuthor

- Suggested ID: `velvet_paw_jazz_club.security_camera_author.02`
- Position: (3872, 1760)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Camera watching the vault cage door from the north wall. Parent under GameplayRoot/SecurityAuthoringRoot.

### 43. `vault_power` - PowerCircuitNode

- Suggested ID: `velvet_paw_jazz_club.power_circuit_node.01`
- Position: (4160, 2464)
- Parent: `MissionMechanics`
- Depends on: `yordano_dialogue`
- Instructions: Breaker panel: reroute club power so the vault maglock drops on the next bass swell. The mission's puzzle beat for the basement.

### 44. `server_vault` - LockedInteractionNode

- Suggested ID: `velvet_paw_jazz_club.locked_interaction_node.02`
- Position: (3936, 2112)
- Zone size: 128 x 96
- Parent: `MissionMechanics`
- Depends on: `vault_power`
- Instructions: Vault cage door (gap in the cage's south wall). Opens once vault_power has rerouted the maglock.

### 45. `ledger_shard` - InventoryPickupNode

- Suggested ID: `velvet_paw_jazz_club.inventory_pickup_node.02`
- Position: (4224, 1920)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `server_vault`
- Instructions: Black Ledger Shard on the server rack. Sets GameState.velvet_paw_basement_shard_collected; taking it upstairs later flips velvet_paw_club_hostile. Physical pickup beat separate from the encoded-setlist Sterling clue.

### 46. `audit_cleanup` - AuditTrailCleanupNode

- Suggested ID: `velvet_paw_jazz_club.audit_trail_cleanup_node.01`
- Position: (3712, 2464)
- Parent: `MissionMechanics`
- Depends on: `ledger_shard`
- Instructions: Optional paper-trail beat: wipe the access log terminal so the shard pull never traces back to Yordano. Lowers post-mission heat.

### 47. `basement_keycard` - InventoryPickupNode

- Suggested ID: `velvet_paw_jazz_club.inventory_pickup_node.03`
- Position: (3584, 2336)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `ledger_shard`
- Instructions: Optional Black Ledger Keycard behind basement storage shelves. Sets velvet_paw_basement_keycard_collected so the player can reach owner_stairs during the hostile phase without thinning every bouncer.

### 48. `heat_sink` - HeatSinkObject

- Suggested ID: `velvet_paw_jazz_club.heat_sink_object.01`
- Position: (4096, 2560)
- Parent: `MissionMechanics`
- Depends on: `vault_power`
- Instructions: Optional paper-trail beat: plant a misdirection explanation on the basement breaker panel so the shard pull traces to 'equipment maintenance' instead of Yordano.

### 49. `poop_bag_basement` - PoopBagAuthor

- Suggested ID: `velvet_paw_jazz_club.poop_bag_author.02`
- Position: (3648, 2688)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Poop bag 2 of 3, by the basement crates. Parent under GameplayRoot/SecurityAuthoringRoot.

### 50. `return_teleport` - TeleportZone

- Suggested ID: `velvet_paw_jazz_club.teleport_zone.02`
- Position: (3616, 3040)
- Zone size: 96 x 64
- Parent: `MissionMechanics`
- Depends on: `ledger_shard`
- Instructions: Ladder back up to the stage row (targets return_marker). Taking the shard upstairs flips the club HOSTILE - bouncers hunt instead of patrol.

### 51. `return_marker` - TeleportTargetMarker

- Suggested ID: `velvet_paw_jazz_club.teleport_target_marker.02`
- Position: (1024, 1120)
- Parent: `MissionMechanics`
- Depends on: `return_teleport`
- Instructions: Floor 1 return point just south of the piano hatch.

### 52. `encounter_controller` - EncounterController

- Suggested ID: `velvet_paw_jazz_club.encounter_controller.01`
- Position: (1600, 1344)
- Parent: `MissionMechanics`
- Depends on: `return_teleport`
- Instructions: Hostile-club phase: escalates bouncer aggression after the shard return. Extend/wrap MissionAlertController behavior; combat-or-sneak beat.

### 53. `lights_disruption` - DisruptionActionNode

- Suggested ID: `velvet_paw_jazz_club.disruption_action_node.01`
- Position: (2176, 1408)
- Parent: `MissionMechanics`
- Depends on: `encounter_controller`
- Instructions: Optional: cut the strobes at the lighting panel - hostile bouncers lose the player for ~4 seconds.

### 54. `scheme_card_bassdrop` - SchemeCardTriggerNode

- Suggested ID: `velvet_paw_jazz_club.scheme_card_trigger_node.01`
- Position: (1856, 1216)
- Parent: `MissionMechanics`
- Instructions: yordano_bass_drop scheme card hook: if the card is equipped, trigger a bass drop here that stuns every bouncer for 5 seconds.

### 55. `owner_stairs` - LockedInteractionNode

- Suggested ID: `velvet_paw_jazz_club.locked_interaction_node.03`
- Position: (3008, 1216)
- Zone size: 96 x 128
- Parent: `MissionMechanics`
- Depends on: `return_teleport`
- Instructions: Rig stairs behind the DJ stack, east edge of the floor. Opens during the hostile phase after thinning bouncers — or silently if basement_keycard was collected.

### 56. `suite_teleport` - TeleportZone

- Suggested ID: `velvet_paw_jazz_club.teleport_zone.03`
- Position: (3008, 1120)
- Zone size: 96 x 64
- Parent: `MissionMechanics`
- Depends on: `owner_stairs`
- Instructions: Climb to the owner suite (targets suite_arrival).

### 57. `suite_arrival` - TeleportTargetMarker

- Suggested ID: `velvet_paw_jazz_club.teleport_target_marker.03`
- Position: (3616, 1216)
- Parent: `MissionMechanics`
- Depends on: `suite_teleport`
- Instructions: Owner suite arrival at the top of the rig stairs (south-west gap).

### 58. `beam_suite` - SecurityBeamAuthor

- Suggested ID: `velvet_paw_jazz_club.security_beam_author.01`
- Position: (3616, 832)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Laser beam across the suite corridor between the stairs and the office. Parent under GameplayRoot/SecurityAuthoringRoot.

### 59. `owner_encounter` - ChallengeObjectiveNode

- Suggested ID: `velvet_paw_jazz_club.challenge_objective_node.01`
- Position: (3904, 704)
- Parent: `MissionMechanics`
- Depends on: `suite_arrival`
- Instructions: Boss beat: the club owner defends the suite (existing JazzClubOwnerArena fight). Clearing it is required for the briefcase.

### 60. `bug_plant` - BugPlantNode

- Suggested ID: `velvet_paw_jazz_club.bug_plant_node.01`
- Position: (3840, 640)
- Parent: `MissionMechanics`
- Depends on: `owner_encounter`
- Instructions: Optional: plant a bug in the owner's desk phone after the fight - extra intel line for the Sterling Tower finale.

### 61. `briefcase_reward` - RewardNode

- Suggested ID: `velvet_paw_jazz_club.reward_node.01`
- Position: (4096, 320)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `owner_encounter`
- Instructions: The blackmail briefcase on the balcony - the mission target. 'Grab it and don't admire the view.'

### 62. `suite_stash` - CaseCashAuthor

- Suggested ID: `velvet_paw_jazz_club.case_cash_author.01`
- Position: (4288, 320)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Optional shelf-goblin stash at the balcony's east end (+1 intel bonus, velvet_shelf_goblins flavor). Parent under GameplayRoot/SecurityAuthoringRoot.

### 63. `hidden_polaroid` - SideObjectiveNode

- Suggested ID: `velvet_paw_jazz_club.side_objective_node.02`
- Position: (1344, 448)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `stage_presentation`
- Instructions: Hidden perfect-moment polaroid (jazz_club_polaroid): Bentley on stage wings during the spotlight sweep after setlist_terminal. Optional; wires to hideout gallery reward.

### 64. `shelf_goblin_secret` - SearchZone

- Suggested ID: `velvet_paw_jazz_club.search_zone.03`
- Position: (4160, 448)
- Zone size: 96 x 96
- Parent: `MissionMechanics`
- Depends on: `briefcase_reward`
- Instructions: Secret velvet_shelf_goblins collectible on the owner-suite balcony shelf. Searching after briefcase_reward sets secret_velvet_collectible for bonus intel.

### 65. `poop_bag_floor` - PoopBagAuthor

- Suggested ID: `velvet_paw_jazz_club.poop_bag_author.03`
- Position: (448, 2240)
- Parent: `GameplayRoot/SecurityAuthoringRoot`
- Instructions: Poop bag 3 of 3, near the club floor south wall. Parent under GameplayRoot/SecurityAuthoringRoot.

### 66. `escape_route` - RouteUnlockNode

- Suggested ID: `velvet_paw_jazz_club.route_unlock_node.02`
- Position: (4224, 2688)
- Zone size: 96 x 128
- Parent: `MissionMechanics`
- Depends on: `briefcase_reward`
- Instructions: Basement escape hatch (east wall gap) unlocks once the briefcase is taken - Yordano cues the bass drop to cover the exit.

### 67. `escape_music` - MusicTriggerZone

- Suggested ID: `velvet_paw_jazz_club.music_trigger_zone.02`
- Position: (4032, 2880)
- Zone size: 384 x 128
- Parent: `MissionMechanics`
- Instructions: Bass-drop escape theme when the player re-enters the basement south end with the briefcase.

### 68. `extraction` - ExtractionZone

- Suggested ID: `velvet_paw_jazz_club.extraction_zone.01`
- Position: (4224, 2944)
- Zone size: 128 x 128
- Parent: `MissionMechanics`
- Depends on: `escape_route`
- Instructions: Escape through the basement hatch before the bouncers regroup. Requires escape_route's open flag and the briefcase.

## Completion Checklist

- [ ] `player_start` (PlayerStartMarker) placed with id `start_main`
- [ ] `queue_inspection` (InspectionZone) placed with id `velvet_paw_jazz_club.inspection_zone.01`
- [ ] `queue_eavesdrop` (EavesdropZone) placed with id `velvet_paw_jazz_club.eavesdrop_zone.01`
- [ ] `alley_dialogue` (DialogueTriggerZone) placed with id `velvet_paw_jazz_club.dialogue_trigger_zone.01`
- [ ] `dead_drop` (DeadDropNode) placed with id `velvet_paw_jazz_club.dead_drop_node.01`
- [ ] `poop_bag_alley` (PoopBagAuthor) placed with id `velvet_paw_jazz_club.poop_bag_author.01`
- [ ] `side_door_entry` (TriggerZone) placed with id `velvet_paw_jazz_club.trigger_zone.01`
- [ ] `floor_music` (MusicTriggerZone) placed with id `velvet_paw_jazz_club.music_trigger_zone.01`
- [ ] `bouncer_route_a` (GuardPatrolRouteAuthor) placed with id `velvet_paw_jazz_club.guard_patrol_route_author.01`
- [ ] `bouncer_spawn_a` (GuardSpawnAuthor) placed with id `velvet_paw_jazz_club.guard_spawn_author.01`
- [ ] `bouncer_route_b` (GuardPatrolRouteAuthor) placed with id `velvet_paw_jazz_club.guard_patrol_route_author.02`
- [ ] `bouncer_spawn_b` (GuardSpawnAuthor) placed with id `velvet_paw_jazz_club.guard_spawn_author.02`
- [ ] `professionalism_meter` (ProfessionalismMeterNode) placed with id `velvet_paw_jazz_club.professionalism_meter_node.01`
- [ ] `floor_inspection` (InspectionZone) placed with id `velvet_paw_jazz_club.inspection_zone.02`
- [ ] `bar_task` (BelievableTaskZone) placed with id `velvet_paw_jazz_club.believable_task_zone.01`
- [ ] `barback_distraction` (DistractionObject) placed with id `velvet_paw_jazz_club.distraction_object.01`
- [ ] `investigation_point` (InvestigationPointNode) placed with id `velvet_paw_jazz_club.investigation_point_node.01`
- [ ] `noise_emitter` (NoiseEmitterNode) placed with id `velvet_paw_jazz_club.noise_emitter_node.01`
- [ ] `bentley_wait` (BentleyWaitMarker) placed with id `velvet_paw_jazz_club.bentley_wait_marker.01`
- [ ] `hide_booth` (HideSpotNode) placed with id `velvet_paw_jazz_club.hide_spot_node.01`
- [ ] `vip_protocol` (ProtocolZone) placed with id `velvet_paw_jazz_club.protocol_zone.01`
- [ ] `vip_phone_search` (SearchZone) placed with id `velvet_paw_jazz_club.search_zone.01`
- [ ] `camera_vip` (SecurityCameraAuthor) placed with id `velvet_paw_jazz_club.security_camera_author.01`
- [ ] `bathroom_glow_guy` (GlowGuyAuthor) placed with id `velvet_paw_jazz_club.glow_guy_author.01`
- [ ] `bathroom_bark` (BarkTrigger) placed with id `velvet_paw_jazz_club.bark_trigger.01`
- [ ] `bentley_crawl` (BentleyCrawlspaceConnector) placed with id `velvet_paw_jazz_club.bentley_crawlspace_connector.01`
- [ ] `staff_badge_pickup` (InventoryPickupNode) placed with id `velvet_paw_jazz_club.inventory_pickup_node.01`
- [ ] `staff_gate` (LockedInteractionNode) placed with id `velvet_paw_jazz_club.locked_interaction_node.01`
- [ ] `green_room_lockers` (InteractiveContainer) placed with id `velvet_paw_jazz_club.interactive_container.01`
- [ ] `clue_manager_notes` (ClueAuthor) placed with id `velvet_paw_jazz_club.clue_author.01`
- [ ] `soundcheck_task` (SideObjectiveNode) placed with id `velvet_paw_jazz_club.side_objective_node.01`
- [ ] `clue_setlist` (ClueAuthor) placed with id `velvet_paw_jazz_club.clue_author.02`
- [ ] `backstage_crate_search` (SearchZone) placed with id `velvet_paw_jazz_club.search_zone.02`
- [ ] `setlist_terminal` (TerminalHackNode) placed with id `velvet_paw_jazz_club.terminal_hack_node.01`
- [ ] `stage_presentation` (PresentationSequencePlayer) placed with id `velvet_paw_jazz_club.presentation_sequence_player.01`
- [ ] `wrong_note_alarm` (SecurityEffectSetAuthor) placed with id `velvet_paw_jazz_club.security_effect_set_author.01`
- [ ] `alarm_spawn` (GuardSpawnAuthor) placed with id `velvet_paw_jazz_club.guard_spawn_author.03`
- [ ] `backstage_hatch` (RouteUnlockNode) placed with id `velvet_paw_jazz_club.route_unlock_node.01`
- [ ] `basement_teleport` (TeleportZone) placed with id `velvet_paw_jazz_club.teleport_zone.01`
- [ ] `basement_arrival` (TeleportTargetMarker) placed with id `velvet_paw_jazz_club.teleport_target_marker.01`
- [ ] `yordano_dialogue` (DialogueTriggerZone) placed with id `velvet_paw_jazz_club.dialogue_trigger_zone.02`
- [ ] `camera_basement` (SecurityCameraAuthor) placed with id `velvet_paw_jazz_club.security_camera_author.02`
- [ ] `vault_power` (PowerCircuitNode) placed with id `velvet_paw_jazz_club.power_circuit_node.01`
- [ ] `server_vault` (LockedInteractionNode) placed with id `velvet_paw_jazz_club.locked_interaction_node.02`
- [ ] `ledger_shard` (InventoryPickupNode) placed with id `velvet_paw_jazz_club.inventory_pickup_node.02`
- [ ] `audit_cleanup` (AuditTrailCleanupNode) placed with id `velvet_paw_jazz_club.audit_trail_cleanup_node.01`
- [ ] `basement_keycard` (InventoryPickupNode) placed with id `velvet_paw_jazz_club.inventory_pickup_node.03`
- [ ] `heat_sink` (HeatSinkObject) placed with id `velvet_paw_jazz_club.heat_sink_object.01`
- [ ] `poop_bag_basement` (PoopBagAuthor) placed with id `velvet_paw_jazz_club.poop_bag_author.02`
- [ ] `return_teleport` (TeleportZone) placed with id `velvet_paw_jazz_club.teleport_zone.02`
- [ ] `return_marker` (TeleportTargetMarker) placed with id `velvet_paw_jazz_club.teleport_target_marker.02`
- [ ] `encounter_controller` (EncounterController) placed with id `velvet_paw_jazz_club.encounter_controller.01`
- [ ] `lights_disruption` (DisruptionActionNode) placed with id `velvet_paw_jazz_club.disruption_action_node.01`
- [ ] `scheme_card_bassdrop` (SchemeCardTriggerNode) placed with id `velvet_paw_jazz_club.scheme_card_trigger_node.01`
- [ ] `owner_stairs` (LockedInteractionNode) placed with id `velvet_paw_jazz_club.locked_interaction_node.03`
- [ ] `suite_teleport` (TeleportZone) placed with id `velvet_paw_jazz_club.teleport_zone.03`
- [ ] `suite_arrival` (TeleportTargetMarker) placed with id `velvet_paw_jazz_club.teleport_target_marker.03`
- [ ] `beam_suite` (SecurityBeamAuthor) placed with id `velvet_paw_jazz_club.security_beam_author.01`
- [ ] `owner_encounter` (ChallengeObjectiveNode) placed with id `velvet_paw_jazz_club.challenge_objective_node.01`
- [ ] `bug_plant` (BugPlantNode) placed with id `velvet_paw_jazz_club.bug_plant_node.01`
- [ ] `briefcase_reward` (RewardNode) placed with id `velvet_paw_jazz_club.reward_node.01`
- [ ] `suite_stash` (CaseCashAuthor) placed with id `velvet_paw_jazz_club.case_cash_author.01`
- [ ] `hidden_polaroid` (SideObjectiveNode) placed with id `velvet_paw_jazz_club.side_objective_node.02`
- [ ] `shelf_goblin_secret` (SearchZone) placed with id `velvet_paw_jazz_club.search_zone.03`
- [ ] `poop_bag_floor` (PoopBagAuthor) placed with id `velvet_paw_jazz_club.poop_bag_author.03`
- [ ] `escape_route` (RouteUnlockNode) placed with id `velvet_paw_jazz_club.route_unlock_node.02`
- [ ] `escape_music` (MusicTriggerZone) placed with id `velvet_paw_jazz_club.music_trigger_zone.02`
- [ ] `extraction` (ExtractionZone) placed with id `velvet_paw_jazz_club.extraction_zone.01`

When everything is placed, run Mission Dock's Assist Browser "Refresh Scene Audit" - the blueprint coverage entry should report all slots placed. Then hide or delete the `AuthoringBlueprintLayer` node.
