# Author Nodes Editor Plugin

Reference catalog for hand-placed **author nodes** in the Godot editor. Author nodes are thin `@tool` placement/preview components; runtime systems consume their exported configuration.

**Design goal:** Level designers place nodes visually in scenes. Runtime builders read author nodes and spawn real gameplay (beams, cameras, guards, loot, objectives, etc.).

**Current implementation status (as of D6-02 / D6-02A):** `SecurityAuthoringRoot`, `SecurityBeamAuthor`, and editor previews for camera/guard/patrol authors exist. Most nodes below are **planned** or **presets** for future phases.

---

## Security / Stealth

| Author Node | What It Does |
|-------------|--------------|
| `SecurityBeamAuthor` | Places a real laser/security beam with visual line, trigger area, alarm behavior, and guard response. |
| `SecurityCameraAuthor` | Places a real camera cone that can sweep, detect player, reduce stealth, raise alert, and spawn guards. |
| `GuardSpawnAuthor` | Defines where guards can spawn for patrols, alarms, ambushes, or reinforcements. |
| `GuardPatrolRouteAuthor` | Defines waypoint routes that guards follow, usually linked by `route_id` to a guard spawn. |
| `AlarmPanelAuthor` | Places a panel the player can disable, hack, or destroy to reduce alarms/security. |
| `SecurityTerminalAuthor` | Places a computer/security terminal for disabling cameras, beams, locks, or alarms. |
| `LockedGateAuthor` | Places a gate/door/barrier that blocks the player until unlocked. |
| `KeypadCodeGateAuthor` | Variant of locked gate requiring a code. Wrong codes can trigger alarms. |
| `KeycardDoorAuthor` | Variant of locked gate requiring a keycard/item. |
| `LightConeAuthor` | Places a light or visibility cone that affects stealth/detection. |
| `ShadowZoneAuthor` | Places a low-visibility area where the player is harder to detect. |
| `NoiseZoneAuthor` | Places an area where player actions make more noise or attract guards. |
| `TripwireAuthor` | Places a thin trigger line that trips alarm/ambush/effect when crossed. |
| `MotionSensorAuthor` | Places a sensor area that detects movement rather than vision-cone logic. |
| `LaserGridAuthor` | Places multiple beams/grid security; likely a stronger version of `SecurityBeamAuthor`. |
| `SafeZoneAuthor` | Places a zone where security ignores or loses the player (hiding spots, exits). |
| `EscapeRouteAuthor` | Defines where the player can leave the mission or where guards think the player might flee. |

---

## Collectibles / Loot

| Author Node | What It Does |
|-------------|--------------|
| `PoopBagAuthor` | Places a collectible poop bag tied to the existing poop counter/objective system. |
| `MoneyStackAuthor` | Places money/currency pickups. |
| `PolaroidAuthor` | Places collectible photos, lore, memories, or mission evidence. |
| `TinyIconAuthor` | Places tiny icon collectibles. |
| `GlowGuyAuthor` | Places special glow guy collectibles or characters. |
| `RareLootAuthor` | Places high-value unique loot with custom reward/heat/objective behavior. |
| `EvidenceItemAuthor` | Places evidence pickups used for mission objectives or story progression. |
| `MissionKeyItemAuthor` | Places a required item (keycard, code slip, bag, badge, tool). |
| `SnackPickupAuthor` | Places consumable pickups, health/stamina/boost items, or Taco-specific food items. |
| `DisguiseItemAuthor` | Places disguise pickups that change detection/guard response. |
| `ToolPickupAuthor` | Places tools (crowbar, lockpick, jammer, fake ID, etc.). |
| `SecretCacheAuthor` | Places hidden loot containers or bonus pickups. |
| `LootContainerAuthor` | Places a container that can hold randomized or configured loot. |

---

## Objectives

| Author Node | What It Does |
|-------------|--------------|
| `ObjectiveItemAuthor` | Places a required mission objective item. |
| `ObjectiveDropoffAuthor` | Places where the player must deliver/drop an item. |
| `OptionalObjectiveAuthor` | Places optional mission goals. |
| `BonusObjectiveAuthor` | Places higher-risk bonus goals for extra rewards. |
| `TimedObjectiveAuthor` | Places an objective with timer behavior. |
| `ExtractionZoneAuthor` | Places mission exit/completion zone. |
| `IntelPickupAuthor` | Places intel that reveals routes, codes, camera locations, or bonuses. |
| `SabotageTargetAuthor` | Places something the player must disable/destroy. |
| `RescueTargetAuthor` | Places an NPC/object that must be rescued or escorted. |
| `EvidencePlantAuthor` | Places a location where the player plants evidence or an item. |

---

## Interactables

| Author Node | What It Does |
|-------------|--------------|
| `DialogueNPCDeployAuthor` | Places an NPC with dialogue/interactions. |
| `VendorAuthor` | Places a shop/vendor interaction. |
| `DoorAuthor` | Places a basic door that opens/closes/locks. |
| `SwitchAuthor` | Places a toggle controlling lights, doors, alarms, etc. |
| `ButtonAuthor` | Places a one-shot or pressable action trigger. |
| `ComputerTerminalAuthor` | Places a terminal for hacking, codes, files, or security controls. |
| `DumpsterAuthor` | Places a dumpster for hiding, loot, disposal, or exit. |
| `VendingMachineAuthor` | Places vending machine interaction, loot, noise, or snack pickup. |
| `CashRegisterAuthor` | Places a register with money/loot/alarm risk. |
| `DriveThruWindowAuthor` | Places a Taco-specific interaction point. |
| `TrashCanAuthor` | Places trash/loot/hiding/searchable container. |
| `HidingSpotAuthor` | Places a spot where the player can hide from guards. |
| `VentEntranceAuthor` | Places a transition/shortcut between locations. |
| `ClimbPointAuthor` | Places climb/vault/traversal interaction. |

---

## AI / Encounter Design

| Author Node | What It Does |
|-------------|--------------|
| `CivilianSpawnAuthor` | Places civilians. |
| `WorkerSpawnAuthor` | Places workers/staff NPCs. |
| `ManagerSpawnAuthor` | Places manager-type NPCs, potentially with keys/objectives. |
| `PatrolGroupAuthor` | Places a group of guards/NPCs with shared patrol behavior. |
| `AmbushZoneAuthor` | Places a trigger zone that spawns or activates an ambush. |
| `SearchNetZoneAuthor` | Defines a zone where guards coordinate searches/flanks/chokepoints. |
| `ChokePointAuthor` | Marks important tactical hallway/doorway locations for guards/security. |
| `GuardPostAuthor` | Places a stationary or semi-stationary guard post. |
| `InvestigationPointAuthor` | Places locations guards inspect after alarm/noise. |
| `LastKnownPositionHintAuthor` | Marks where AI search logic should focus after losing the player. |
| `ReinforcementEntryAuthor` | Defines where reinforcement guards enter the map. |

---

## Mission Flow

| Author Node | What It Does |
|-------------|--------------|
| `PlayerSpawnAuthor` | Places mission start position. |
| `RouteStartAuthor` | Places alternate route starts. |
| `CheckpointAuthor` | Places respawn/restart/checkpoint locations. |
| `MissionBoundaryAuthor` | Defines playable area or camera/AI bounds. |
| `FailureZoneAuthor` | Places a zone that causes failure, capture, or warning. |
| `CompletionTriggerAuthor` | Places a mission completion trigger. |
| `ReturnToHideoutAuthor` | Places transition back to HideoutHub. |
| `HeatEscalationZoneAuthor` | Places zones/actions that increase heat. |
| `TutorialPromptAuthor` | Places tutorial/help text triggers. |
| `CutsceneTriggerAuthor` | Places trigger for dialogue/cutscene/scripted sequence. |

---

## Level Feel / Worldbuilding

| Author Node | What It Does |
|-------------|--------------|
| `AmbientAudioZoneAuthor` | Places ambient sound zones. |
| `MusicStingerAuthor` | Places one-shot music/audio moments. |
| `CameraBoundsAuthor` | Defines camera limits for a room/area. |
| `LightingMoodZoneAuthor` | Changes lighting/tint/mood in an area. |
| `CrowdNoiseZoneAuthor` | Adds background noise or masks player noise. |
| `FlavorTextInspectAuthor` | Adds inspectable environmental text. |
| `EnvironmentalHazardAuthor` | Places hazards (spills, fire, broken floor, electricity). |
| `DestructiblePropAuthor` | Places breakable objects. |
| `DecalAuthor` | Places visual-only decals/marks. |
| `SignageAuthor` | Places signs/labels/directional hints. |

---

## Taco Bell Specific

| Author Node | What It Does |
|-------------|--------------|
| `GarageCodeGateAuthor` | Taco-specific locked garage/code gate. Could be an `AccessGateAuthor` preset. |
| `DriveThruSpeakerAuthor` | Places drive-thru interaction/dialogue/security trigger. |
| `KitchenWorkerAuthor` | Places kitchen worker NPC. Could be an `NPCSpawnAuthor` preset. |
| `ManagerOfficeSafeAuthor` | Places safe with loot/objective/code/key. |
| `BagRoomObjectiveAuthor` | Places final bag/objective room item. |
| `FreezerDoorAuthor` | Places freezer access/locked door. |
| `RegisterLootAuthor` | Places cash register loot. |
| `SaucePacketCollectibleAuthor` | Taco-specific collectible. Could be a `CollectibleAuthor` preset. |
| `BathroomStallAuthor` | Places stall interaction/hiding/loot. |
| `DumpsterExitAuthor` | Places dumpster exit/shortcut. |
| `DeliveryDoorAuthor` | Places back/delivery door route. |

---

## Value Of Combining

- Less duplicate code
- Fewer bugs
- Easier runtime builder
- Easier testing
- Shared validation
- Faster future content creation
- One collectible system can handle many collectible types

---

## Value Of Keeping Separate

- Clearer scene tree for level design
- Better Inspector defaults
- Better editor previews
- Less confusing options
- Specialized validation
- Specialized runtime behavior
- Easier to drag exactly what you mean

### Example: preset vs generic

`AccessGateAuthor` can support both keypad and keycard, but a **`GarageCodeGateAuthor` preset** may still be valuable because it can default to:

- `access_type = code`
- `wrong_attempt_alarm = true`
- `mission_code_key = garage_code`
- Taco-specific label/color
- Taco-specific F10 fields

---

## Recommended Design (Hybrid)

Use a **hybrid** approach:

1. **Few reusable runtime systems** (actual gameplay logic)
2. **Several friendly authoring nodes or presets** (editor placement + preview)
3. **Specialized scripts only when behavior really differs**

### Example: access gates

| Layer | Name | Role |
|-------|------|------|
| Runtime system | `AccessGateRuntime` | Opens/closes, validates code/keycard, fires alarms |
| Generic author | `AccessGateAuthor` | Hand-placed gate with exports for type, code key, etc. |
| Presets / thin wrappers | `GarageCodeGateAuthor`, `KeycardDoorAuthor`, `LockedDoorAuthor` | Same runtime, Taco-friendly defaults and previews |

That yields **clean code** and a **good level-design workflow**.

---

## Related project paths

| Path | Purpose |
|------|---------|
| `src/missions/iso/authoring/` | Author node scripts (`SecurityBeamAuthor`, etc.) |
| `src/levels/IsoMissionBase.gd` | Mission runtime that consumes authoring nodes |
| `scenes/missions_iso/` | Mission scenes with `SecurityAuthoringRoot` children |
| `docs/reports/d6_02_security_authoring_foundation/` | D6-02 implementation reports |
| `docs/reports/d6_02a_security_beam_authoring_polish/` | D6-02A beam resize/preview reports |

---

## Conventions (current + planned)

- **`SecurityAuthoringRoot`** (or future category roots): container under `GameplayRoot` for security-related authors.
- **Author nodes** are `@tool` `Node2D` (or `Area2D` when triggers need editor handles).
- **No `class_name`** where global-class cache conflicts exist; duck-typed runtime lookup via `build_runtime_config()` and `has_method()`.
- **F10** reports `d6_02_*` / future `d6_*` fields for source, dimensions, validation status.
- **Fallback:** legacy geometry solvers (e.g. FIX7F) remain until hand-placed authoring is confirmed per mission.
