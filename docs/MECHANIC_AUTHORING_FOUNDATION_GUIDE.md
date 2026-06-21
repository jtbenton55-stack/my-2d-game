# Mechanic Authoring Foundation Guide

Concise guide for Packet 2 mechanic authoring: `TriggerZone`, requirement/effect resources, and `MissionInteractionBridge`.

## Purpose

The Packet 2 foundation lets you place **mission mechanics** in a scene as `Area2D` nodes with:

- **Requirements** (`RequirementSet` / `MissionRequirement`) — when the mechanic is available
- **Effects** (`EffectSet` / `MissionEffect`) — what happens on success or failure
- **Interaction** — player presses `interact` (E) via `MissionInteractionBridge`

This replaces ad-hoc per-mission scripts for simple triggers, flags, and dialogue hooks.

## Dev validation scene

**Path:** `res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`

**Controller:** `res://src/missions/iso/dev/MechanicAuthoringTestRoomController.gd`

- Sets `GameState.current_mission_id` to `mechanic_authoring_test` for the session
- Arrow keys move the dummy `Player` (group `player`)
- `E` / `Q` use existing input actions `interact` / `case_the_joint`
- Status label shows key mission flags
- Includes a `LockedInteractionNode` sample gate (`Locks/DevLockedGate`) unlocked after trigger **C** sets `dev_unlock_flag`
- Includes a `SearchZone` sample drawer (`Searches/DevSearchDrawer`) that sets `dev_drawer_searched` and `dev_drawer_found_clue`
- Includes an `ExtractionZone` sample exit (`Exits/DevExtractionZone`) that requires `dev_drawer_found_clue`, then sets `dev_extraction_used` and `dev_clean_extraction`
- Includes an `InteractiveContainer` sample locker (`Containers/DevLocker`) that sets `dev_locker_opened`, `dev_locker_searched`, and `dev_locker_found_item`
- Includes a `RewardNode` sample pickup (`Rewards/DevRewardPickup`) that sets `dev_reward_collected` and `dev_reward_effect_applied`
- Includes a `RouteUnlockNode` sample shortcut (`Routes/DevRouteUnlock`) that requires `dev_reward_collected`, then sets `dev_route_open` and toggles route visuals/collisions
- Includes a `SideObjectiveNode` sample (`Objectives/DevSideObjective`) that requires `dev_route_open`, completes `dev_side_objective`, and sets handled/effect flags
- Includes a Phase 5D inventory proof (`InventoryPickupNode_phase5d_delivery_badge` -> `RouteUnlockNode_phase5d_badge_route`) where a picked-up item unlocks a route through `inventory_has_item`
- Includes Phase 7 Bentley command proofs (`CompanionCommandPoint_phase7_bark`, `_sniff`, `_fetch`, `BentleyCrawlspaceConnector_phase7e`, `BentleyWaitMarker_phase7f`) where Bentley commands apply normal success effects and fetch targets a nearby inventory token
- Includes Phase 8A-8D-lite noise/distraction proofs (`NoiseEmitterNode_phase8a_bark_lure`, `DistractionObject_phase8d_decoy`) where placed noise applies normal success effects and routes to `MissionAlertController`

**Not** the main scene and **not** wired into production missions. Use only for authoring validation.

## Place a TriggerZone

1. Add an `Area2D` to your mission scene.
2. Attach `res://src/missions/iso/authoring/mechanics/TriggerZone.gd`.
3. Add a child `CollisionShape2D` (rectangle is fine).
4. Set exports on the trigger:
   - `mechanic_id` — stable id for logs/signals
   - `interaction_mode` — use **Interact Required** (`1`) for press-E mechanics
   - `prompt_text` / `locked_prompt_text`
   - `mission_id_override` — if the scene is not already under the correct `GameState.current_mission_id`
5. On `_ready`, nodes join groups `mission_mechanic` and `interactable` automatically.

## Assign a RequirementSet

Create or assign a `RequirementSet` resource on the trigger’s `requirements` export.

Example (mission flag must exist):

```gdscript
var requirement := MissionRequirement.new()
requirement.fact_type = &"mission_flag"
requirement.key = "dev_unlock_flag"
requirement.operator = MissionRequirement.Operator.EXISTS
requirement.expected_value_type = "exists"

var set := RequirementSet.new()
set.requirements = [requirement]
set.locked_message = "Locked until dev_unlock_flag is set."
trigger.requirements = set
```

Leave `requirements` empty for always-available mechanics.

## Assign an EffectSet

Create or assign a `EffectSet` on `success_effects` and optionally `failure_effects`.

Example (set mission flag):

```gdscript
var effect := MissionEffect.new()
effect.effect_type = MissionEffect.EffectType.SET_MISSION_FLAG
effect.key = "dev_unlock_flag"
effect.value_type = "bool"
effect.value_bool = true

var set := EffectSet.new()
set.effects = [effect]
trigger.success_effects = set
```

Other effect types include `TRIGGER_SIMPLE_DIALOGUE` (see dev scene `DialogueTrigger`).

## Mission flag namespacing

Mission flags are stored in `GameState.dialogue_flags` with keys:

```text
mission_flag:<mission_id>:<flag_id>
```

Example: mission `mechanic_authoring_test`, flag `dev_unlock_flag` →

```text
mission_flag:mechanic_authoring_test:dev_unlock_flag
```

Use `MissionFactBridge` / `MissionEffect` with `fact_type` / `effect_type` `mission_flag` and `SET_MISSION_FLAG`; the applier applies the namespace from the active mission context.

## MissionInteractionBridge

Add a node with `MissionInteractionBridge.gd` to the scene (sibling of mechanics is fine).

| Export | Role |
|--------|------|
| `player_path` | NodePath to the player (or leave empty; uses group `player`) |
| `interaction_radius` | Max distance to collect candidates (dev room uses ~220) |
| `action_interact` | Default `interact` (E) |
| `action_scan_or_debug` | Default `case_the_joint` (Q) |

**How candidates are found:**

1. Collect nodes in groups: `mission_mechanic`, `interactable`, `phase0j_interactable`, `phase0j_marker_debug`, `phase0k_louis_exit`
2. Keep nodes that implement `interact`, `on_interact`, `use`, or `inspect_marker`
3. Filter by distance to the player within `interaction_radius`
4. Sort by available → uncompleted → priority → distance
5. Call the first candidate’s interaction method

`TriggerZone` implements `interact` / `on_interact` and routes to `activate()` with requirement/effect evaluation.

## Wire the dev test room pattern

1. `MechanicAuthoringTestRoomController` sets mission id and configures triggers by node name under `Triggers/`.
2. `MissionInteractionBridge` gets `player_path` set at runtime to the dummy player.
3. Move near a trigger, press **E**, read the status label for flag changes.

## LockedInteractionNode

Use for doors, gates, safes, terminals, scanners, and containers that require a key, card, flag, or other requirement before opening.

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/LockedInteractionNode.gd`.
2. Set `requirements` (e.g. mission flag or selected card) and `success_effects` (objectives, flags, dialogue).
3. Optionally set `unlocked_flag` to persist unlock state as `mission_flag:<mission_id>:<flag>`.
4. Wire `nodes_to_hide_on_unlock`, `collisions_to_disable_on_unlock`, or shorthand `target_visual_path` / `target_collision_path` for local door visuals/blockers.
5. Add `MissionInteractionBridge` in the scene; player presses **E** when in range.

Example: gate requires `mission_flag` `has_keycard`; on success sets `dev_gate_open` and disables a child `CollisionShape2D`.

**Limitations:** No door animation/audio system yet (`locked_sound_key` / `unlocked_sound_key` are placeholders).

## SearchZone

Use for drawers, shelves, trash bins, counters, desks, evidence spots, and other searchable props.

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/SearchZone.gd`.
2. Set `success_effects` to grant clues/items/flags/objective progress via `EffectSet`.
3. Optionally set `searched_flag` to persist searched state as `mission_flag:<mission_id>:<flag>`.
4. Wire `target_visual_path`, `nodes_to_hide_on_search`, and `nodes_to_show_on_search` for closed/open visuals.

Example: searchable drawer sets `dev_drawer_searched` and `dev_drawer_found_clue`, hides `DrawerClosedVisual`, shows `DrawerFoundVisual`.

**Limitations:** No timed search animation in v1. For open/closed container state, prefer `InteractiveContainer`.

## InteractiveContainer

Use for drawers, lockers, fridges, filing cabinets, crates, trash bins, safes, and similar props that open/search in one interaction.

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/InteractiveContainer.gd`.
2. Set `success_effects` for clues/items/flags (applied directly — no inventory UI).
3. Optionally set `opened_flag` and `searched_flag` for persistent mission flags.
4. Wire `closed_visual_path`, `open_visual_path`, and optional show/hide node lists for open/closed visuals.
5. Use `requirements` or `LockedInteractionNode` for key/card gating — not built into the container itself.

Example: locker sets `dev_locker_opened`, `dev_locker_searched`, and `dev_locker_found_item`, hides `LockerClosedVisual`, shows `LockerOpenVisual`.

**Limitations:** No inventory UI or item grid. Effects apply directly through `EffectSet`.

## ObjectiveStepController

Static adapter over `QuestManager` for objective-gated mechanics. Use `activate_objective`, `complete_objective`, `fail_objective`, and query helpers instead of calling `QuestManager` directly from authored nodes.

## ExtractionZone

Use for mission exits and conditional extraction points that should complete (or nearly complete) a job.

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/ExtractionZone.gd`.
2. Set `requirements` (e.g. mission flag from a `SearchZone`) and optional `required_objective_ids` / `optional_objective_ids`.
3. Assign `clean_exit_effects` and optionally `messy_exit_effects` for alert/pressure exits.
4. Set `extraction_flag` to persist extraction as `mission_flag:<mission_id>:<flag>`.
5. Leave `complete_mission_on_success = false` in dev/test scenes; set `true` in production missions when ready.

Example: extraction requires `dev_drawer_found_clue`, sets `dev_extraction_used`, applies `dev_clean_extraction` via `clean_exit_effects`, and routes mission completion through `MissionCompletionBridge` when enabled.

**Limitations:** Production mission migration is not done yet. No Taco/Louis wiring in this packet.

## RewardNode

Use for visible pickup spots: clues, small rewards, case cash, typed collectibles, evidence, and reward flags.

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/RewardNode.gd`.
2. Set `success_effects` for the actual reward (`SET_MISSION_FLAG`, `GRANT_TYPED_COLLECTIBLE`, `GRANT_EVIDENCE_CLUE`, etc.).
3. Optionally set `collected_flag` to persist collection as `mission_flag:<mission_id>:<flag>`.
4. Wire `target_visual_path` and `nodes_to_show_on_collect` to hide/show pickup visuals.

Example: visible pickup sets `dev_reward_collected`, applies `dev_reward_effect_applied`, hides `RewardVisual`, shows `RewardCollectedVisual`.

**Limitations:** No inventory UI or reward popup. Reward specifics are delegated to `EffectSet` / `MissionEffectApplier`.

## InventoryPickupNode

Use for visible mission-only item pickups such as keys, badges, route tokens, tools, evidence, and heist-kit objects.

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/InventoryPickupNode.gd`, or instance `res://scenes/missions/iso/authoring/InventoryPickupNodeTemplate.tscn`.
2. Set `item_id`, `item_count`, `item_category`, and `collected_flag`. If using `item_data`, the node reads the item id/category/stack policy from that Resource.
3. Set `requirements` when the pickup should be gated. A failed requirement does not grant the item.
4. Gate downstream mechanics with `MissionRequirement.fact_type = &"inventory_has_item"`, `inventory_item_count`, or `inventory_has_category`.
5. Use F10 during mission playtest to inspect the compact `mission_inv` line.

Example: pickup grants `delivery_badge`; route requirement `inventory_has_item` with key `delivery_badge` then unlocks the badge route.

**Limitations:** Mission-only item state is runtime-only and intentionally not saved yet. Use mission flags or future persistent item schema only when a production mission proves persistence is needed.

## CompanionCommandPoint

Phase 7E-7G-lite extends this command-point family with crawlspace, wait-marker, and card-tuned command behavior.

Use for placed Bentley command prompts that should run through normal requirements/effects instead of custom mission scripts.

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/CompanionCommandPoint.gd`, or instance `res://scenes/missions/iso/authoring/CompanionCommandPointTemplate.tscn`.
2. Set `command_type` to `bark`, `sniff`, `fetch`, `crawlspace`, or `wait`.
3. Set `companion_path` when the scene has a known Bentley node, or leave it empty to find the first node in group `bentley`.
4. Set `requirements`, `success_effects`, and `failure_effects` like any other `MechanicAreaBase` mechanic.
5. Use Mission Dock for safe placement defaults; it audits missing `command_type` values.

Example: a bark command point sets `phase7_bark_command_used`; a fetch command point asks Bentley to fetch a nearby `InventoryPickupNode`; a crawlspace connector sets a route/open flag after Bentley moves to the marker; a wait marker holds Bentley at the marker for puzzle timing.

**Limitations:** Phase 7-lite proves bark/sniff/fetch/crawlspace/wait command points. Production mission placement and full noise/listener AI are deferred.

## NoiseEmitterNode / DistractionObject / NoiseListenerComponent / NoiseReactiveGuard

Phase 8A-8D-lite adds the first reusable noise/distraction authoring nodes.
Phase 8E-8G-lite adds the first reusable listener component and bridges existing poop-bag decoy points into the same noise event path.
Phase 8H-lite adds a small guard/debug receiver for listener callbacks.

Use `NoiseEmitterNode` when a placed object, marker, or command point should emit a structured noise event after normal requirement/effect success. Use `DistractionObject` for a player-team decoy/distraction default.

1. Set `mechanic_id` and `noise_id` to stable mission-local IDs.
2. Choose `noise_kind` such as `bark`, `decoy`, or `object`.
3. Set `noise_radius` and `noise_strength` for debug/listener tuning.
4. Add `success_effects` for mission flags/objectives when the noise action should advance authoring state.
5. Leave `route_to_alert_controller` enabled when the mission has a `MissionAlertController` receiver.

Use `NoiseListenerComponent` as a child of a guard/NPC/debug receiver when it should record in-range noise events. It listens to `EventBus.mission_noise_emitted`, filters by radius/kind/team, stores the last heard event, sets lightweight debug metadata on its parent, and can call parent `on_noise_heard(noise_event, listener)` if a receiver script provides that method.

Use `NoiseReactiveGuard` as a lightweight parent receiver for `NoiseListenerComponent` when a guard/debug node should enter an `investigating_noise` state, record an investigate target, and optionally face the noise source. It intentionally does not path or chase yet.

`DogCompanion.command_bark()` also emits a `bentley_bark` noise event through the same schema. `MissionPoopBagDecoyPoint` emits a `poop_decoy` noise event after a poop bag is successfully consumed. `MissionAlertController` records recent noise events and can move normal missions to suspicious for player-team noise. Full guard pathing AI remains future Phase 8+ work.

## TerminalHackNode

Phase 9A starts the Puzzle And Side Job Kit with a terminal/hack mechanic built as a thin `LockedInteractionNode` subclass.

Use `TerminalHackNode` when a terminal, keypad, console, or hack panel should require ordinary `RequirementSet` facts and apply ordinary `EffectSet` outputs.

1. Set `terminal_id` and `mechanic_id` to stable mission-local IDs.
2. Set `hack_completed_flag` or `unlocked_flag` so completion is inspectable through mission facts.
3. Add requirements for code/card/tool/item facts instead of custom terminal scripts.
4. Add success effects for objective, route, evidence, item, or debug flags.
5. Use Mission Dock for safe placement defaults; it audits missing terminal IDs and completion flags.

Example: a terminal requires a code fact, sets `phase9a_terminal_hacked`, and applies an effect that unlocks a route or completes an objective.

**Limitations:** Phase 9A proves terminal/hack authoring only. Phase 9B adds linked power puzzle nodes, but side jobs, dead drops, object swaps, bug/eavesdrop zones, and a custom sequence runner are still deferred.

## Phase 9B Power Puzzle Nodes

Phase 9B adds three small mission-local puzzle nodes. They use mission flags as the contract between placed mechanics instead of a global puzzle manager.

Use `TimedSwitchNode` when an interaction should set a temporary mission flag for circuits or requirements.

1. Set `switch_id`, `switch_flag`, and `mechanic_id` to stable mission-local IDs.
2. Set `active_seconds` to the desired timer window.
3. Leave `clear_flag_on_expire` enabled when the switch should only power circuits temporarily.
4. Add optional success effects for objective/debug state.

Use `PressurePlateNode` when occupancy should set a mission flag while pressed.

1. Set `plate_id`, `pressed_flag`, and `mechanic_id` to stable mission-local IDs.
2. Keep `clear_flag_on_exit` enabled for ordinary pressure plates.
3. Add requirements if only a specific actor/item/state can press the plate.
4. Add optional success effects for objective/debug state.

Use `PowerCircuitNode` when a mission-local puzzle should check linked flags and then power a route, lock, objective, or debug fact.

1. Set `circuit_id`, `circuit_flag`, and `mechanic_id` to stable mission-local IDs.
2. Add `required_power_flags` that match switch/plate flags.
3. Keep `require_all_flags` enabled for AND-style circuits, or disable it for OR-style circuits.
4. Add success effects for route/objective/evidence changes and optional failure effects for feedback.

Example: a timed switch sets `phase9b_switch_active`, a plate sets `phase9b_plate_pressed`, and a circuit with both in `required_power_flags` sets `phase9b_circuit_powered` plus any route/objective effects.

**Limitations:** Phase 9B proves linked power puzzles only. It does not add a puzzle manager, custom sequence runner, production Taco placement, save-schema changes, side jobs, or authored route mutations beyond ordinary effect sets.

## RouteUnlockNode

Use for shortcuts, hidden paths, route gates, and local traversal mutations (show path, hide blocker, enable/disable collisions).

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd`.
2. Set `requirements` (mission flags, selected cards, objectives — via `RequirementSet`, not hardcoded card logic).
3. Set `success_effects` and optional `route_flag` for persistent unlock state.
4. Wire `nodes_to_show`, `nodes_to_hide`, `collisions_to_enable`, and `collisions_to_disable`.

Example: route requires `dev_reward_collected`, sets `dev_route_open`, shows `RouteOpenVisual`, hides `RouteBlockedVisual`, disables `RouteBlocker`, enables `RoutePassageShape`.

**Limitations:** No route manager, mutation manager, or production route migration yet.

## SideObjectiveNode

Use for optional/side objectives placed in the scene: activate, complete, or fail objectives through `ObjectiveStepController`.

1. Add an `Area2D` and attach `res://src/missions/iso/authoring/mechanics/SideObjectiveNode.gd`.
2. Set unique `objective_id` and `objective_action` (`ACTIVATE`, `COMPLETE`, `FAIL`).
3. Set `requirements` and `success_effects` like other mechanics.
4. Optionally set `objective_flag` for persistent handled state.

Example: route-gated side objective completes `dev_side_objective`, sets `dev_side_objective_handled`, applies `dev_side_objective_effect_applied`. Dev room pre-activates the objective via `ObjectiveStepController` before completion.

**Limitations:** Uses existing `QuestManager` through `ObjectiveStepController` only. No mission rating/result UI yet.

## Multiple instances in one mission

You can place many nodes of the same mechanic class in one scene. Each instance must use **unique** persistent identifiers so state and flags do not cross-contaminate:

- **RewardNode:** unique `reward_id`, `mechanic_id`, `collected_flag`, and success-effect keys
- **InventoryPickupNode:** unique `item_id`, `reward_id`, `mechanic_id`, and `collected_flag`
- **SearchZone:** unique `mechanic_id`, `searched_flag`
- **RouteUnlockNode:** unique `route_id`, `route_flag`, `mechanic_id`
- **SideObjectiveNode:** unique `objective_id`, `objective_flag`, `mechanic_id`

Dev room `MultiInstance/` demonstrates paired Reward A/B, Search A/B, and Route A/B samples. GdUnit tests cover multi-instance isolation for rewards, searches, routes, and side objectives.

## Current limitations

- Core mechanic examples still live in the dev validation scene, and the first production adoption slice now uses `SchemeCardTriggerNode` plus `RouteUnlockNode` in Taco for the Louis Delivery Route card path
- No full visual authoring palette in the editor
- `TriggerZone` defaults to `AUTOMATIC_ON_ENTER` in `_init()`; dev room overrides to `INTERACT_REQUIRED` in the controller
- `SchemeCardTriggerNode` is validated for reusable card-driven setup, route facts, ready-time hooks, and one Taco production slice using `louis_delivery_route`
- Namespaced `mission_flag:<mission_id>:` values are attempt-local for mission starts; `GameState.start_mission()` clears flags for the launching mission so card/setup route flags do not leak between runs
- Inventory/heist-kit has a mission-only Phase 5D-lite pickup/debug proof; no persistent item save schema, grid UI, noise, or social stealth yet
- Bentley commands have a Phase 7-lite bark/sniff/fetch/crawlspace/wait command-point proof; production placement is still deferred
- Noise/distraction has a Phase 8A-8D-lite event/emitter/distraction proof, a Phase 8E-8G-lite listener/poop-decoy bridge proof, and a Phase 8H-lite guard response proof; full guard pathing AI and production placement are still deferred
- Puzzle kit has Phase 9A terminal/hack proof through `TerminalHackNode` plus Phase 9B linked power puzzle proof through `PowerCircuitNode`, `TimedSwitchNode`, and `PressurePlateNode`; side jobs, dead drops, object swaps, bug/eavesdrop zones, and custom sequences are still deferred
- No Mission Authoring Palette or Mission Assist Browser yet; build those after the reusable mechanics and first production adoption slice are stable
- No custom chronographic sequence runner yet; use ordinary mechanics/effects until sequence data Resources are implemented

## Recent mechanic nodes

1. `MissionModifierSet` — mission-wide modifier bundles  
2. `SchemeCardTriggerNode` — card-triggered mission effects  
3. `InventoryPickupNode` — mission-only item pickups through the reward/effect pipeline
4. `CompanionCommandPoint` — placed Bentley commands through the requirement/effect pipeline
5. `BentleyCrawlspaceConnector` — thin crawlspace command-point subclass
6. `BentleyWaitMarker` — thin wait-marker command-point subclass
7. `NoiseEmitterNode` — placed structured noise event emitter
8. `DistractionObject` — player-team decoy/distraction emitter subclass
9. `NoiseListenerComponent` — mission-local guard/NPC/debug receiver for structured noise events
10. `NoiseReactiveGuard` — lightweight listener parent that records an investigating-noise response
11. `TerminalHackNode` — requirement/effect-driven terminal hack built on `LockedInteractionNode`
12. `TimedSwitchNode` — reusable switch that sets and expires a mission flag
13. `PressurePlateNode` — occupancy-driven plate that sets/clears a mission flag
14. `PowerCircuitNode` — linked-power checker that reads mission flags and applies normal effects when powered

## Related future editor tooling

After the foundation is validated, the roadmap/blueprint call for focused editor tools in this order:

1. PVGames Object Palette v2 brush/repeat placement for visual assets.
2. Mission Paint Dock for visual-only floor/wall/decal/foreground passes.
3. Manual Animation Mapper/Reviewer for PVGames character creator sheets.
4. Mission Authoring Palette for placing approved mechanic templates with safe defaults.
5. Mission Assist Browser for duplicate IDs, broken links, requirement/effect validation, and core gizmos.
6. Custom chronographic sequence tooling for authored ordered steps such as first dead drop before second dead drop.

See `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md` for the full packet sequence.
