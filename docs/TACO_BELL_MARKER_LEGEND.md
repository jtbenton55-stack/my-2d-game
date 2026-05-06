# Taco Bell Iso Marker Legend

Scene audited: `res://scenes/missions_iso/TacoBellIso_Editable.tscn`

This pass documents current marker authoring behavior only. It does **not** redesign the level or move/delete markers.

## How Marker Authoring Currently Works

- **Authoring source:** `GameplayRoot/MarkerRoot` `Node2D` markers (`IsoMissionMarker.gd`).
- **Runtime generation:** `IsoMissionBase.gd` reads mission definition + scene markers and spawns runtime nodes into `GameplayRoot/RuntimeSystems` and `EntityRoot`.
- **Tile hints:** `GameplayRoot/LayoutRoot/MarkerTileLayer` stores marker hint tiles (editor aid).
- **Debug labels:** `GameplayRoot/LayoutRoot/DebugLabelLayer` is currently empty in scene; per-marker `EditorLabel` children exist under each marker node.
- **Required safety rule:** markers outside floor / in blocking collision are validated by `MissionBlockoutValidator`.

## Runtime Buckets Spawned From Marker/Definition Data

- `RuntimeSystems/SpawnedGuards` from guard spawn markers/definitions.
- `RuntimeSystems/SpawnedCameras` + `RuntimeSystems/DetectionZones` from camera markers/definitions.
- `RuntimeSystems/AlarmZones` from alarm markers/definitions.
- `RuntimeSystems/EncounterZones` from ambush markers/definitions.
- `RuntimeSystems/RouteAccessPoints` from route markers/definitions.
- `RuntimeSystems/TransitionTriggers` from transition markers/definitions.
- `RuntimeSystems/LightZones` from light zone markers/definitions.
- `EntityRoot/Interactables` includes clue/collectible/objective/gate/route placeholders positioned from markers.

## Marker Type Legend (currently used in Taco Bell)

| Marker Type / Pattern | What It Is | What It Does | Player Sees It | Debug Only? | Required | Safe To Move? | Safe To Delete? | Links | If Missing | Expected Folder | Suggested Icon/Color |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `player_spawn`, `bentley_spawn` | Start spawns | Sets mission start points | No | Yes (label) | Yes | Carefully (must stay on floor) | No | `group_id` | Broken spawn start | `MarkerRoot/Spawns` | `SP` cyan |
| `transition_entry` (spawn-style route anchors) | Route entry/return spawn anchors | Intended route spawn anchors; currently partially legacy vs runtime SpawnPoints | No | Yes | For route clarity yes | Yes, if destination chain preserved | No (without retargeting) | `group_id` route ids | Route return confusion/invalid teleports | `MarkerRoot/Spawns` | `RS` teal |
| `objective` (default when `marker_type` unset) | Objective interaction anchors | Drives objective interactables text/state | Yes (objective updates) | Labels yes | Mostly yes | Yes, maintain floor + progression order | No | `linked_objective_id` | Objective step can fail to complete | `MarkerRoot/Objectives` | `OBJ` yellow |
| Objective-labeled scent proxies (`scent_*` under Objectives) | Objective-linked scent checkpoints | Acts as objective/hint nodes, not canonical scent-trail markers | Sometimes via interaction text | Labels yes | Mixed | Yes with caution | Usually no | `linked_objective_id` | Scent step progression confusion | `MarkerRoot/Objectives` | `OBJ-S` amber |
| `guard_spawn` | Guard origin | Spawns initial guard runtime | Yes (guard entity) | Marker label yes | Yes | Yes, keep patrol coverage valid | No | `linked_guard_id` | Missing guard pressure/combat check | `MarkerRoot/Enemies` | `G` red |
| `patrol_point` | Patrol waypoints | Defines patrol route order for linked guard | No direct marker | Yes | Yes for authored patrol | Yes, keep reachable | No | `linked_guard_id`, `order` | Patrol path degrades/fallback path used | `MarkerRoot/Patrols` | `P` red-orange |
| `shadow_zone` (used as light zones currently) | Light stealth modifier zones | Spawns mission light zones | Mostly indirect | Yes | Optional but important | Yes | Yes, with stealth tuning impact | none | Less stealth readability/variation | `MarkerRoot/LightZones` | `LZ` indigo |
| `alarm_zone` | Alarm trigger area | Raises alert/alarm flow | Indirect (alarms/guards) | Yes | Yes | Yes, keep fair pathing | No | none | Alarm beat lost/misplaced | `MarkerRoot/AlarmZones` | `AL` orange |
| `ambush_trigger` | Encounter trigger | Ambush beat / one-shot state | Indirect (combat/dialogue) | Yes | Yes | Yes, keep encounter fairness | No | none | Ambush beat missing | `MarkerRoot/EncounterZones` | `AMB` crimson |
| `clue` | Evidence clue pickup anchors | Spawns clue interactables and evidence records | Yes | Yes | Yes (story clues) | Yes | No for required clues | `linked_clue_id` | Story/evidence progression break | `MarkerRoot/Clues` | `CL` blue |
| `polaroid_hidden`, `polaroid_perfect`, `glow_guy`, `tiny_icon`, `poop_bag` | Collectible anchors | Spawns collectible pickups/rewards | Yes | Yes | Optional/bonus except mission-required counts | Yes | Usually yes (except required objectives tied to them) | `linked_collectible_id` | Bonus/optional objective failures | `MarkerRoot/Collectibles` | `COL` green |
| `scent_trail_fake` (under ScentTrails) | Canonical scent trail markers | Feeds runtime scent-trail placement/logic | Yes via scent interactables | Yes | Yes for scent puzzle | Yes, preserve ambiguity/fairness | No | `linked_objective_id` | Scent branch may become obvious/broken | `MarkerRoot/ScentTrails` | `SC` purple |
| `code_gate` | Code gate anchor | Spawns code gate interaction/barrier pair | Yes | Yes | Yes | Yes, keep beam/gate separation | No | `linked_objective_id` | Gate progression breaks | `MarkerRoot/Gates` | `CG` magenta |
| `route_access` | Route interact anchors | Spawns route access points (Louis/Vent/keycard/decoy/terminal hooks) | Yes | Yes | Yes for alt routes | Yes | No unless route removed intentionally | `linked_route_id` | Route lock/unlock flow breaks | `MarkerRoot/Routes` | `RT` cyan-green |
| `transition` | Transition trigger anchors | Spawns transition trigger areas | Usually indirect | Yes | Yes | Yes, preserve destination chain | No | `group_id` | Wrong returns/softlocks | `MarkerRoot/Transitions` | `TR` sky |
| `exit` | Mission exit trigger anchor | Exit completion path | Yes | Yes | Yes | Yes with completion checks | No | `group_id=exit` | Mission cannot complete | `MarkerRoot/Exit` | `EX` white |

## Objective Markers Clarified

- Objective markers are **interaction/progression anchors** (not pure UI hints).
- Players usually experience them as interact prompts, dialogue/objective updates, or completion checks.
- Debug view shows explicit label text and marker IDs.
- Objective marker vs help marker:
  - objective marker advances required/optional mission state;
  - help/tutorial marker would be advisory only.
- Objective marker vs hazard marker:
  - objective marker is progression intent;
  - hazard/alarm marker is fail-pressure/detection intent.
- Objective marker vs scent marker:
  - objective marker can reference scent goals;
  - scent markers represent trail logic points (real/fake branching).
- Objective text appears through quest/objective systems and is now also visible through pause-menu objective views.

## Light Zones Clarified

- Current light zones are authored as `shadow_zone` marker types in Taco Bell.
- Runtime uses them through `MissionLightZone` systems to modify stealth/detection behavior.
- They do **not** directly choose real/fake scent trail.
- They can be renamed/reskinned conceptually as floodlights/searchlights in editor documentation if runtime linkage is preserved.
- They are adjacent to but distinct from camera cone detection:
  - light zone = ambient visibility modifier;
  - camera cone = directional detection source.

## Objective vs Help vs Hazard vs Scent (with Taco Bell examples)

- **Objective marker**: advances mission progression state.
  - Example: `objective_inspect_sauce_packets_or_receipt`.
- **Help/Tutorial marker**: explanatory guidance only, no progression gate.
  - Taco Bell currently uses little dedicated help-marker typing; tutorial-like guidance is usually carried by objective/proxy text.
- **Hazard marker**: danger/alert pressure.
  - Example: `alarmzone_alarm_zone_placeholder` and `encounter_garage_floor_2_ambush_marker`.
- **Scent marker**: Bentley sniff route option/proxy.
  - Canonical option examples: `scent_real_parking_garage`, `scent_real_parking_garage_02` (legacy names retained).
  - Objective proxy examples: `scent_fake_loading_dock`, `scent_real_parking_garage_03`.

Ground rule for designers:
- objective/hazard/scent can be spatially close, but keep their authoring purpose distinct in metadata and labels.

## Recommended Marker Category Scheme (editor-facing)

- Objective
- Help/Tutorial
- Scent Real
- Scent Fake
- Scent Path
- Guard Spawn
- Patrol Point
- Camera/Floodlight
- Light Zone
- Alarm Trigger
- Encounter Trigger
- Code Gate
- Door/Gate Blocker
- Route Entrance
- Route Spawn
- Route Return Trigger
- Route Return Destination
- Vent Entrance
- Vent Exit
- Stairs Up
- Stairs Down
- Collectible
- Poop Bag Pickup
- Poop Bag Throw Target
- Clue
- Flavor Interactable
- Exit

## Recommended Visual Marker Icon Plan

| Category | Icon | Color | Abbrev | Editor Visible | Debug Visible | Normal Gameplay Visible |
|---|---|---|---|---|---|---|
| Objective | target-diamond | yellow | `OBJ` | Yes | Yes | No |
| Help/Tutorial | info-circle | light blue | `TIP` | Yes | Yes | Optional text only |
| Scent Real | paw-solid | deep purple | `SR` | Yes | Yes | No explicit label |
| Scent Fake | paw-outline | gray-purple | `SF` | Yes | Yes | No explicit label |
| Scent Path | dotted-paw | muted violet | `SP` | Yes | Yes | No |
| Guard Spawn | shield | red | `GS` | Yes | Yes | No |
| Patrol Point | route-dot | orange-red | `PP` | Yes | Yes | No |
| Camera/Floodlight | camera | orange | `CAM` | Yes | Yes | Cone only |
| Light Zone | lightbulb | indigo | `LZ` | Yes | Yes | Indirect |
| Alarm Trigger | siren | orange-red | `AL` | Yes | Yes | Indirect |
| Encounter Trigger | crossed-blades | crimson | `AMB` | Yes | Yes | Indirect |
| Code Gate | keypad | magenta | `CG` | Yes | Yes | Gate object |
| Route Entrance | door-in | cyan | `RE` | Yes | Yes | Route interactable |
| Route Return Trigger | door-out | cyan-green | `RR` | Yes | Yes | Transition only |
| Collectible | spark | green | `COL` | Yes | Yes | Pickup object |
| Poop Bag Pickup | bag | olive | `PB` | Yes | Yes | Pickup object |
| Clue | file | blue | `CL` | Yes | Yes | Pickup object |
| Exit | flag | white | `EX` | Yes | Yes | Exit trigger |

## MarkerTileLayer Authoring Vocabulary (Phase 0G v6)

The `MarkerTileLayer` is an editor-visual aid only and is decoupled from `marker_type` (gameplay). Painting a marker tile does **not** spawn gameplay. The vocabulary now contains 30 abbreviations; in addition to the 28 already present, two new tiles support route-doors and control switches without overloading other categories:

| Abbreviation | Atlas coords | Intent | Notes |
| --- | --- | --- | --- |
| `DOOR` | `(8, 4)` | Route entry / return door | Use for `ROUTE_IN_*` service-door entries and `ROUTE_RET_*` return triggers. Distinct from `GATE` (which is reserved for the actual code gate). |
| `SWITCH` | `(9, 4)` | Control panel / lever / Bentley switch | Use for `SAFE_CODE_INPUT_ZONE`, `CONTROL_alarm_panel`, `CONTROL_camera_terminal`, `CONTROL_door_controls`, and every `BENTLEY_SWITCH_*` row. Never use `GATE`/`CAM`/`LIGHT`/`EXIT` for switches. |

Neither `DOOR` nor `SWITCH` carries a physics polygon. Both are visible/selectable in the `MarkerAuthoringTileset.tres` palette.

## Scent Normalization Map (Phase 0E)

- **Canonical scent options (`ScentTrails` folder)**
  - `scent_real_parking_garage` -> classified `scent_fake_option`
  - `scent_real_parking_garage_02` -> classified `scent_fake_option`
  - Notes: names kept for compatibility; editor metadata now clarifies fake-role intent.
- **Objective proxies (`Objectives` folder)**
  - `scent_real_parking_garage_03` -> `scent_objective_proxy`
  - `scent_fake_loading_dock` -> `scent_objective_proxy`
  - `scent_fake_trash_area`, `_02` -> `legacy_proxy`
  - `scent_fake_trash_area_03` -> `scent_objective_proxy`
- **Real-route secrecy**
  - debug/editor labels can be explicit (`SCENT_FAKE`, `SCENT_PROXY`)
  - player-facing copy should remain in-world/vague
  - normal HUD should not reveal exact real route

## Route / Spawn / Transition Chain Definitions

- **RouteAccess**: marker player interacts with to enter/use route.
- **RouteEntrySpawn**: where route traversal starts.
- **RouteReturnTrigger**: trigger used to return from route segment.
- **RouteReturnDestination**: destination spawn after return.
- **Transition**: generic transition mechanic marker; may be route or stairs.
- **Return Trigger vs Destination**:
  - trigger is event source
  - destination is landing location

Current chain examples:
- Louis: `route_louis_delivery_future` -> `spawn_route_louis_entry` -> `transition_route_louis_return` -> `spawn_route_louis_return`
- Bentley vent: `route_bentley_vent` -> `spawn_route_vent_entry` -> `transition_route_vent_return` -> `spawn_route_vent_return`
- Poop bag decoy: `route_poopbagdecoy_loading_dock` is utility marker (`PoopBagDistractionPoint`), not a full traversal chain.

## Designer Grouping Safety

- Runtime marker scanning is recursive from `MarkerRoot`.
- Marker identity depends on IDs/types/links, not strict folder path.
- Physical mass-reparenting is still treated as **high-risk** during active QA because many systems and docs currently reference existing structure.
- Phase 0E chooses non-invasive normalization (metadata + docs) over reparenting.

## Future Tile/Stamp Recommendations (preparation only)

| Design Need | Recommended Form |
|---|---|
| Correct/incorrect scent path | marker node + debug overlay tile |
| Patrol path | marker node (`patrol_point`) + optional line overlay |
| Light zones | marker node (`shadow_zone`/`bright_zone`) + tinted debug tile |
| Alarm / encounter | marker node + hazard tile |
| Gates/doors | marker node + gate stamp |
| Stairs up/down | transition marker + stairs stamp |
| Safe code input zone | debug-only overlay tile/stamp |
| Bypass danger zone | debug-only overlay tile/stamp |
| Route entrance/return destination | marker node + route stamp |
| Poop bag throw target | utility marker node + optional decoy stamp |
| Bentley command spot | optional helper marker node (debug-only) |

## Optional Editor Helper (proposal only, not implemented here)

- `MarkerLegendOverlay` editor-only script that toggles marker label visibility by category:
  - scent
  - route
  - objective
  - camera/light
  - guard/patrol
  - collectibles
  - transitions

No runtime behavior changes are required for this helper; it can remain `@tool` + editor-only.
