# Mission Dock Mechanics: How To Use

This guide covers every mechanic type currently listed in the Mission Dock palette.

For Mission Dock placement, "layer" means the `Parent Target Path`, not a paint tile layer.

## Mechanic Placement Parents

| Mechanic Type | Parent Target Path | What To Change/Input |
|---|---|---|
| `SearchZone` | `MissionMechanics` | Keep auto ID. Optional: change `search_kind`, shape size, and success effect flag if making a custom chain. |
| `RewardNode` | `MissionMechanics` | Keep auto ID. Optional: set requirement flag to match a previous step and choose `reward_kind`. |
| `InventoryPickupNode` | `MissionMechanics` | Keep auto `item_id` or set a readable item ID. Optional: set `item_count` and `item_category`. |
| `CompanionCommandPoint` | `MissionMechanics` | Needs Bentley/companion present. Set `command_type` if not using default bark. |
| `BentleyCrawlspaceConnector` | `MissionMechanics` | Needs Bentley present. Lite proof command; keep defaults unless testing a specific route effect. |
| `BentleyWaitMarker` | `MissionMechanics` | Needs Bentley present. Keep defaults for wait command proof. |
| `NoiseEmitterNode` | `MissionMechanics` | Keep auto `noise_id`; optionally set `noise_kind`, `noise_team`, and radius/strength fields if exposed. |
| `DistractionObject` | `MissionMechanics` | Keep auto `noise_id`; default is player decoy noise. |
| `LockedInteractionNode` | `MissionMechanics` | Keep auto `unlocked_flag`. Optional: add requirements and target visual/collision paths for a visible door/gate unlock. |
| `TerminalHackNode` | `MissionMechanics` | Keep auto `terminal_id` and `hack_completed_flag`. Optional: add requirements if the terminal should be gated. |
| `PowerCircuitNode` | `MissionMechanics` | Set `required_power_flags` to flags from switches/plates. Keep auto `circuit_flag`. |
| `TimedSwitchNode` | `MissionMechanics` | Keep auto `switch_flag`; set `active_seconds` for test length. |
| `PressurePlateNode` | `MissionMechanics` | Keep auto `pressed_flag`; leave `clear_flag_on_exit = true` unless you need it to stay on after stepping off. |
| `DeadDropNode` | `MissionMechanics` | For easy proof set `drop_mode = retrieve`. Deposit mode requires the player to already have `item_id`. |
| `ObjectSwapNode` | `MissionMechanics` | Requires player to have `required_item_id`; set `replacement_item_id` if the swap grants a new item. |
| `BugPlantNode` | `MissionMechanics` | For easy proof set `consume_bug_item = false`; otherwise player needs `bug_item_id` first. |
| `EavesdropZone` | `MissionMechanics` | Keep auto ID; set `listen_seconds` to a short value like `3`. |
| `AuditTrailCleanupNode` | `MissionMechanics` | Needs a paper-trail trace to clean. Set `target_trace_id` or `target_source_id` for real proof. |
| `HeatSinkObject` | `MissionMechanics` | Keep auto `heat_sink_id`; optional: set `explanation_id`. |
| `DoorStateMemoryNode` | `MissionMechanics` | Keep auto `door_id`; optional: set `trace_id`, `cleanup_requirement`, and `opened_flag`. |
| `InspectionZone` | `MissionMechanics` | Needs a `rule_set` for meaningful pass/fail. Keep auto accepted/rejected flags for proof. |
| `BelievableTaskZone` | `MissionMechanics` | Keep auto `task_id`; optional: set `cover_story_id`, `protocol_id`, and deltas. |
| `ProtocolZone` | `MissionMechanics` | Keep auto `protocol_id`; leave required cover/credential blank for easy proof, or set them for gated proof. |
| `ProfessionalismMeterNode` | `MissionMechanics` | Passive setup node. Set initial professionalism/cleanliness if testing social gates. |
| `CleanlinessGate` | `MissionMechanics` | Requires enough cleanliness and optional protocol. Lower `min_cleanliness` or add a meter/task first for easy proof. |
| `EncounterController` | `MissionMechanics` | Passive controller. Keep default generated phases/meters for basic encounter proof. |
| `ChallengeObjectiveNode` | `MissionMechanics` | Best paired with `EncounterController`. Set/confirm controller path if not auto-resolved. |
| `EncounterRouteActionNode` | `MissionMechanics` | Best paired with route/result controller. Set `route_id`/label and any controller path if needed. |
| `DisruptionActionNode` | `MissionMechanics` | Best paired with `EncounterController`; optionally set trace/social/alert deltas. |
| `SchemeCardTriggerNode` | `MissionMechanics` | For easy proof keep `require_matching_modifier = false`; real proof needs modifier sets/cards. |
| `HideSpotNode` | `MissionMechanics` | Keep defaults; place near camera/beam/guard test area. |
| `InvestigationPointNode` | `MissionMechanics` | Social/reactive NPC proof node. Keep auto ID unless wiring a specific routine/reaction. |
| `RoutineOverrideNode` | `MissionMechanics` | Keep auto `routine_id`/override flag unless wiring to a specific NPC routine. |
| `PresentationSequencePlayer` | `MissionMechanics` | Passive/config-driven. Set sequence steps/library or run-on-ready flags for real proof. |
| `PlayerStartMarker` | `GameplayRoot/MarkerRoot/Spawns` | Keep `marker_id = start_main` for primary spawn. Place on walkable floor. |
| `TeleportZone` | `MissionMechanics` | Set `target_marker_path` to the placed `TeleportTargetMarker` node path. Optional: keep `route_open` requirement for chain proof. |
| `TeleportTargetMarker` | `MissionMechanics` | Keep auto `target_id`. Place where teleport should send the player. |
| `MusicTriggerZone` | `MissionMechanics` | Set `music_key` to a known cue like `mission_select`, `cozy_hideout`, or `title_theme`. |
| `SecurityBeamAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Keep `on_trip_event = ambush_beam_tripped`; adjust height/position so player crosses it. |
| `SecurityCameraAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Keep `on_alarm_event = camera_alarm`; adjust position, range, and `direction_degrees` so player enters cone. |
| `GuardSpawnAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Confirm `trigger_events = [ambush_beam_tripped, camera_alarm]`. Set `initial_behavior = patrol` and `patrol_route_id` if using patrol route. |
| `GuardPatrolRouteAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Keep auto `route_id`; add at least two direct child `Node2D` waypoints named `Waypoint0`, `Waypoint1`. |
| `AreaTriggerAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Set `on_enter_event`; pair with `GuardSpawnAuthor.trigger_events` or `SecurityEffectSetAuthor.trigger_events`. |
| `SecurityEffectSetAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Set `trigger_events` to match beam/camera/area events; add or confirm its `EffectSet`. |
| `PoopBagAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Keep auto `collectible_id`; optional: set `poop_count`. |
| `CaseCashAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Keep auto `collectible_id`; optional: set `case_cash_amount`. |
| `ClueAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Keep auto IDs; set clue title/text if doing real clue proof. |
| `GlowGuyAuthor` | `GameplayRoot/SecurityAuthoringRoot` | Keep auto IDs; optional: set display/reward details if exposed. |
| `DialogueTriggerZone` | `MissionMechanics` | Keep auto `dialogue_key`; fallback speaker/text are enough for proof. |
| `BarkTrigger` | `MissionMechanics` | Keep auto `bark_id`; set `bark_speaker`/`bark_text` if desired. |
| `RouteUnlockNode` | `MissionMechanics` | Keep auto `route_id`/`route_flag`; optional: wire visuals/collisions to open a visible blocker. |
| `InteractiveContainer` | `MissionMechanics` | Keep auto `opened_flag`/`searched_flag`; optional: wire open/closed visuals. |
| `ExtractionZone` | `MissionMechanics` | Keep auto extraction fields; by default it completes the mission on success. |
| `SideObjectiveNode` | `MissionMechanics` | Must set `objective_id`; choose activate/complete/fail action as needed. |
| `TriggerZone` | `MissionMechanics` | Keep automatic-on-enter for simple proof, or switch to interact-required if you want `E`. |

## Player Test / Use Order Notes

### Core Milestone A Chain

1. Spawn from `PlayerStartMarker` automatically.
2. Walk into `SearchZone` and press `E`; this should set the search flag.
3. Walk to `RewardNode` and press `E`; this should work after search.
4. Walk to `RouteUnlockNode` and press `E`; this should work after reward.
5. Walk into `TeleportZone` and press `E`; this should move player to `TeleportTargetMarker`.
6. Walk into `MusicTriggerZone`; no `E`, it triggers on enter.
7. Walk to collectible author such as `PoopBagAuthor` or `CaseCashAuthor`; walk onto/near it and press `E` if prompted.
8. Cross `SecurityBeamAuthor`; it should emit `ambush_beam_tripped`.
9. Stand in `SecurityCameraAuthor` cone; it should emit `camera_alarm` after detection.
10. Confirm `GuardSpawnAuthor` reacts to beam/camera event; player does not use it directly.
11. Confirm `GuardPatrolRouteAuthor` affects patrol route; player does not use it directly.
12. Walk to `HideSpotNode` and press `E`; leave the area to exit hide state.
13. Walk to `SchemeCardTriggerNode` and press `E`.
14. Walk to `ExtractionZone` and press `E`; mission should complete if requirements pass.

### Inventory / Item Mechanics

1. Press `E` on `InventoryPickupNode` to collect an item.
2. Press `E` on `InteractiveContainer` to open/search it.
3. For `DeadDropNode`, set `drop_mode = retrieve` for easy proof and press `E`; deposit mode needs the item first.
4. For `ObjectSwapNode`, collect/give yourself the required item first, then press `E` to swap.
5. For `BugPlantNode`, set `consume_bug_item = false` for easy proof, then press `E`; otherwise collect the bug item first.

### Power Puzzle Mechanics

1. Press `E` on `TimedSwitchNode`; it should show active state for `active_seconds`.
2. Stand on `PressurePlateNode`; no `E`, it should show pressed while occupied.
3. Press `E` on `PowerCircuitNode`; it powers only when its `required_power_flags` are currently true.

### Bentley / Companion Mechanics

1. Make sure Bentley/companion is present.
2. Press `E` on `CompanionCommandPoint` for default command proof.
3. Press `E` on `BentleyCrawlspaceConnector` for crawlspace command proof.
4. Press `E` on `BentleyWaitMarker` to make Bentley wait.

### Noise / Alert Mechanics

1. Press `E` on `NoiseEmitterNode`; check alert/noise debug output.
2. Press `E` on `DistractionObject`; it emits player decoy noise.
3. `SecurityBeamAuthor`, `SecurityCameraAuthor`, and `AreaTriggerAuthor` emit security events by crossing/entering, not by pressing `E`.
4. `SecurityEffectSetAuthor` is passive; it reacts only when its trigger event fires.

### Social / Stealth Mechanics

1. Place `ProfessionalismMeterNode` first if testing initial social values; player does not use it.
2. Press `E` on `BelievableTaskZone` to complete a believable task.
3. Press `E` on `ProtocolZone`; leave required cover/credential blank for easy proof.
4. Press `E` on `InspectionZone`; it needs a rule set for real pass/fail.
5. Press `E` on `CleanlinessGate`; it passes only if cleanliness/protocol requirements are met.
6. Stand in `EavesdropZone` until timer completes; leaving early cancels if `cancel_on_exit = true`.

### Paper Trail / Deniability Mechanics

1. Press `E` on `DoorStateMemoryNode` to record door/action memory.
2. Press `E` on `HeatSinkObject` to plant misdirection.
3. Press `E` on `AuditTrailCleanupNode` after a matching trace exists; otherwise it may have nothing to clean.

### Encounter Mechanics

1. Place `EncounterController`; player does not use it directly.
2. Press `E` on `ChallengeObjectiveNode` to send objective progress into the encounter.
3. Press `E` on `DisruptionActionNode` to send a disruption event.
4. Press `E` on `EncounterRouteActionNode` to choose/lock a route.

### Reactive NPC / Routine Mechanics

1. `InvestigationPointNode` is mostly for NPC/social reaction proof; press `E` only if a prompt appears.
2. Press `E` on `RoutineOverrideNode` to mark a routine override.

### Presentation Mechanics

1. `PresentationSequencePlayer` is passive/config-driven; it only runs if sequence data or run flags are configured.
2. Press `E` on `DialogueTriggerZone` to show fallback dialogue.
3. Press `E` on `BarkTrigger` to show/send a bark.
4. Walk into `TriggerZone` if automatic, or press `E` if set to interact-required.

### Objective / Exit Mechanics

1. Set `SideObjectiveNode.objective_id`, then press `E` to activate/complete/fail the side objective.
2. Press `E` on `ExtractionZone` to extract; it may require prior flags/objectives depending on setup.

## Quick Troubleshooting

| Symptom | Likely Fix |
|---|---|
| No prompt appears | Make sure the player overlaps the area shape and the node is under the correct parent. |
| Pressing `E` does nothing | Check requirements; the mechanic may be waiting on a mission flag or inventory item. |
| Teleport does nothing | Set `TeleportZone.target_marker_path` to the actual `TeleportTargetMarker` node path. |
| Music seems silent | Check Output for `Music cue: <key>` or inspect `/root/AudioManager.current_music`. |
| Guard does not spawn | Confirm beam/camera/area event matches `GuardSpawnAuthor.trigger_events`. |
| Patrol does not work | Confirm `GuardSpawnAuthor.patrol_route_id` matches `GuardPatrolRouteAuthor.route_id` and route has waypoints. |
| Circuit does not power | Confirm switch/plate flags match `PowerCircuitNode.required_power_flags` and are currently true. |
| Audit warns about IDs | Replace blank/`CHANGE_ME` values with unique IDs. |
