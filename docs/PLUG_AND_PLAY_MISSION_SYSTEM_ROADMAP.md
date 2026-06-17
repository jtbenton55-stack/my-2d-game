# Plug-And-Play Mission System Roadmap

Date: 2026-05-19

Status: Planning document. No implementation is implied by this file.

## Purpose

This roadmap consolidates the current mission-system brainstorm into a repo-aware implementation plan for a Godot 4.6.2 project. The goal is to make future missions behave like authored content instead of one-off scripting work.

The target authoring model is:

```text
Mission = map + placed reusable mechanics + objective data + mission-specific story wrapper
```

The desired workflow is:

1. Paint or block out a mission map.
2. Drop reusable mechanic nodes into the scene.
3. Assign Resources for requirements, effects, prompts, dialogue keys, routes, and rewards.
4. Connect those placed nodes to existing mission, quest, save, card, dialogue, security, Bentley, and hideout systems.
5. Validate the mission through debug panels, static checks, GdUnit4 tests where available, and runtime playtesting.

## Current Project Reality

The project already has a substantial game spine. The roadmap must extend that spine instead of replacing it.

Existing systems that should be preserved and extended:

| Area | Current Repo Evidence | Roadmap Treatment |
|---|---|---|
| Boot and main menu | `project.godot`, `scenes/MainMenu.tscn`, `SceneManager.gd` | Keep. Do not rebuild. |
| Mission catalog and mission state | `GameState.gd` mission catalog/start/complete/fail/unlocks | Extend through adapters. |
| Save/load | `SaveManager.gd`, `GameState.to_dict()`, `GameState.from_dict()` | Extend for new state only when needed. |
| Objectives | `QuestManager.gd` active/completed objective records | Add an objective adapter. Do not replace. |
| Scheme cards | `CardManager.gd`, `SchemeCard.gd`, `CardEffects.gd`, `resources/cards/*.tres` | Extend into mission modifiers. |
| Dialogue | `DialogueManager.gd`, `MissionDialogueProvider.gd`, `HideoutDialogicAdapter.gd`, `DialogueBox.gd` | Add trigger/bridge nodes. Do not couple every mechanic directly to Dialogic. |
| Player/Bentley | `Player.gd`, `DogCompanion.gd`, `PlayerStaminaController.gd`, `PlayerVisualAnimator.gd` | Extend Bentley into command points. |
| Hideout | `HideoutManager.gd`, mission board, store, decoration, care, collectible/evidence UI | Extend carefully. Do not rebuild. |
| Collectibles | Collectible manager, authored collectible scripts, hideout sync/persistence | Reuse the authored-node pattern. |
| Security authoring | Security beam/camera/guard/patrol/area/effect author scripts and runtime builder | Reuse and generalize the authored-node pattern. |
| Mission runtime | `IsoMissionBase.gd`, `MissionSceneResolver.gd`, Phase0J/Phase0K bridge/completion code | Protect. Add adapters around it. |
| Art pipeline | PVGames paintable tilesets, PVGames object palette, Taco marker/iso docs, art-ready workflow docs | Formalize into production visual pass with explicit fixed-Z paint layers and a dedicated Y-sortable 2.5D object/player layer. |

## Non-Negotiable Implementation Principles

1. Do not create duplicate global managers when an existing manager can be extended through a thin adapter.
2. Do not rewrite `IsoMissionBase.gd` as part of early roadmap work.
3. Do not replace `QuestManager`; wrap it with mission-authoring helpers.
4. Do not replace `CardManager` or `CardEffects`; bridge cards into facts and mission modifiers.
5. Do not replace the authored collectible or security stacks; reuse their authoring/runtime-builder patterns.
6. Prefer Resources for data and placed nodes for authored scene behavior.
7. Prefer one small proof node before implementing a family of nodes.
8. Every mechanic should be testable in a small validation scene before it is used in a production mission.
9. Every reusable node should expose author-facing properties with clear names and safe defaults.
10. Runtime-only systems should be thin, explicit, and easy to debug from mission debug panels.

## System Family 1: World State, Requirements, And Effects

### Combines

- Game facts
- Mission flags
- Requirement sets
- Effect sets
- Objective-completion effects
- Route-unlock facts
- Card facts
- Social state facts
- Paper-trail facts
- Rewards
- Failure consequences

### Purpose

This family gives all future placed mechanics a shared vocabulary:

- Can this mechanic activate?
- Why can it not activate?
- What changes when it succeeds?
- What changes when it fails?
- What debug information should the designer see?

### Current Status

Partially exists through `GameState.gd`.

Likely existing responsibilities include:

- mission completion
- mission failure
- card unlock/selection
- evidence clues
- typed collectibles
- crew assists
- mission alert state
- mission performance events

### Roadmap Decision

Do not create a fully separate `GameFactManager` first. Add a thin fact/effect adapter over the current state spine unless later implementation proves that a new autoload is necessary.

### Initial Scope

`RequirementSet` should initially support:

- always true
- mission flag equals value
- mission flag exists
- selected card present
- card unlocked
- collectible acquired
- typed collectible count at least value
- objective active
- objective completed
- mission alert state equals value

`EffectSet` should initially support:

- set mission flag
- clear mission flag
- complete objective step
- activate objective step
- grant card
- grant collectible or typed collectible
- grant case cash or reward currency if current state supports it
- set mission alert state
- trigger dialogue key through dialogue bridge
- request extraction or mission completion through existing mission completion flow

### Priority

Very high. This is the foundation for the entire plug-and-play system.

## System Family 2: Authorable Mechanic Base

### Combines

- `MechanicAreaBase`
- trigger zones
- event volumes
- dialogue triggers
- scene flavor triggers
- ambush triggers
- bark triggers
- future social stealth areas
- future cleanup or trace areas

### Purpose

All placed mission mechanics should have consistent interaction behavior:

- player detection
- optional Bentley/NPC detection later
- prompt visibility
- requirement checking
- failure reason display
- one-shot or repeatable behavior
- activation by input or automatic overlap
- effect application
- debug labels and diagnostics
- editor-facing exported fields

### Current Status

The pattern exists in specialized form:

- `Phase0JInteractionBridge.gd`
- `AuthoredPhase0JInteractablePickup.gd`
- `CollectibleAuthoringRuntimeBuilder.gd`
- `SecurityAuthoringRoot.gd`
- `MissionAuthoringRuntimeBuilder.gd`
- `AreaTriggerAuthor.gd`

### Roadmap Decision

Generalize the successful authored collectible/security pattern. Do not invent a completely unrelated authoring approach.

### Initial Scope

`MechanicAreaBase` should own:

- `enabled`
- `interaction_mode`: automatic, interact-required, script-triggered
- `one_shot`
- `prompt_text`
- `locked_prompt_text`
- `requirements`
- `success_effects`
- `failure_effects`
- `debug_id`
- `show_debug_label`
- `allowed_actor_group`, initially defaulting to player group

Specific nodes should only add flavor-specific fields.

### Priority

Very high. This determines whether future work stays drag-and-drop.

## System Family 3: Objective And Mission Flow Adapter

### Combines

- objective step controller
- side objective nodes
- optional objectives
- mission result hooks
- mission rating hooks
- mission performance event hooks

### Purpose

Mission objectives should be data-driven and connectable from placed nodes. A mission designer should be able to say:

```text
When this placed node succeeds, complete objective taco.retrieve_drive.
```

without writing custom script for each mission.

### Current Status

Partially exists:

- `QuestManager.gd`
- `GameState.complete_mission`
- `GameState.fail_mission`
- `Phase0KMissionCompletionController.gd`
- `Phase0KLouisExitInteractable.gd`

### Roadmap Decision

Build an objective adapter over `QuestManager`, not a replacement objective system.

### Initial Scope

The adapter should support:

- activate objective
- complete objective
- fail optional objective
- check objective active
- check objective completed
- emit objective change signal if current systems need UI refresh
- write debug output identifying which placed node caused the objective change

### Priority

Very high. Objectives are the skeleton of missions.

## System Family 4: Input And Prompt Foundation

### Combines

- controller input audit
- keyboard/controller prompt swapping
- interaction prompts
- accept/cancel consistency
- scheme card UI input consistency
- Bentley command input consistency
- cutscene skip input consistency

### Purpose

Every interactable must expose the same input contract. The player should not learn a different interaction behavior for every mechanic family.

### Current Status

Needs an explicit audit.

Likely relevant files:

- `project.godot`
- `src/player/Player.gd`
- `src/ui/HUD.gd`
- `src/ui/PauseMenu.gd`
- `src/ui/SchemeCardMenu.gd`

### Roadmap Decision

Implement early enough that `MechanicAreaBase` does not hardcode temporary prompt behavior.

### Initial Scope

Minimum viable prompt support:

- one canonical interact action
- one canonical cancel action
- prompt text supplied by mechanic
- prompt visible only when current actor can use the mechanic
- locked prompt text when requirements fail
- optional debug text showing failed requirement reason

### Priority

High.

## System Family 5: Access, Locks, Containers, Search, And Rewards

### Combines

- locked doors
- keypad locks
- credential scanners
- ID badge scanners
- safes
- lockers
- drawers
- fridges
- filing cabinets
- search zones
- interactive containers
- reward nodes
- timed safe cracking

### Purpose

Rooms become playable when they contain reusable things the player can inspect, unlock, search, open, and loot.

### Current Status

Some placeholder scenes exist or likely exist:

- `AccessItem.tscn`
- `PuzzleGate.tscn`
- `CollectiblePickup.tscn`
- `CluePickup.tscn`
- `ObjectiveMarker.tscn`

These should not be assumed to be the full reusable interaction library yet.

### Roadmap Decision

Combine locks, containers, searches, and rewards into one practical interaction-object package, all built on `MechanicAreaBase`, `RequirementSet`, and `EffectSet`.

### Initial Scope

First nodes:

- `LockedInteractionNode`
- `SearchZone`
- `InteractiveContainer`
- `RewardNode`

Initial author-facing fields:

- display name
- prompt text
- locked prompt text
- requirements
- success effects
- failure effects
- opened/searched flag key
- one-shot behavior
- optional animation key
- optional sound key

### Priority

High.

## System Family 6: Extraction And Conditional Mission Exit

### Combines

- extraction zones
- conditional exits
- false exits
- clean exit vs messy exit
- Louis exit
- required item extraction

### Purpose

Every mission needs a reusable way to end successfully, fail, or branch results based on objective and item state.

### Current Status

Partially exists:

- `Phase0KMissionCompletionController.gd`
- `Phase0KLouisExitInteractable.gd`
- `ExitTrigger.tscn`
- `GameState.complete_mission`

### Roadmap Decision

Generalize the Louis/Taco completion pattern into reusable extraction nodes.

### Initial Scope

`ExtractionZone` should support:

- required objectives
- optional objectives checked for bonus results
- required items or collectibles
- clean/messy extraction tag
- success effects
- failure prompt
- mission completion request routed through existing completion flow

### Priority

Very high.

## System Family 7: Route Unlocks, Mission Mutations, And Scheme Card Hooks

### Combines

- route unlock nodes
- shortcuts
- one-way doors
- level mutation nodes
- mission modifiers
- scheme-card-triggered nodes
- heat-responsive props
- randomized spawn groups

### Purpose

Cards and mission state should change maps in concrete ways.

Examples:

- Louis delivery route unlocks loading dock access.
- Bentley card opens a sniff shortcut.
- Clorox wipe protocol makes cleanup stations stronger.
- Heat level causes a security guard spawn group to activate.

### Current Status

Partially exists:

- `CardManager.gd`
- `CardEffects.gd`
- `GameState.selected_cards`
- `MissionMutationDefinition.gd`
- `MissionRouteDefinition.gd`
- `resources/cards/*.tres`

### Roadmap Decision

Do not build a new card system. Add a card-to-fact and card-to-modifier bridge that placed nodes can query through `RequirementSet`.

### Initial Scope

First nodes/resources:

- `MissionModifierSet`
- `SchemeCardTriggerNode`
- `RouteUnlockNode`
- `MutationActivatorNode`

### Priority

High after base mechanics exist.

## System Family 8: Stealth Detection And Escalation

### Combines

- suspicion manager
- alarm state controller
- alert meter
- mission alert states
- lockdown
- escape state
- detection consequences

### Purpose

Stealth should be reactive and readable instead of only binary. The player should understand whether they are safe, suspicious, compromised, or in escape mode.

### Current Status

Partially exists:

- `GameState.set_mission_alert_state`
- `GameState.get_mission_alert_state`
- `MissionAlertController.gd`
- `SecurityEventRouter.gd`
- security camera/beam runtime
- guard spawn/patrol runtime

### Roadmap Decision

Extend the existing alert/security runtime. Do not create a duplicate alert system.

### Initial Scope

Initial states:

- calm
- suspicious
- alerted
- lockdown
- escape

Initial effects:

- increase suspicion
- decrease suspicion
- set alert state
- trigger alarm route mutation
- activate guard spawn group
- mark mission as messy

### Priority

High after core mission nodes.

## System Family 9: Patrol, Vision, Camera, And Guard Runtime

### Combines

- patrol routes
- vision sensors
- camera sweep
- camera loop
- guard posts
- rotating spotlight
- detection cones
- patrol modifiers

### Purpose

Stealth rooms need readable hazards that are easy to author.

### Current Status

Already substantially started:

- `SecurityCameraAuthor.gd`
- `SecurityBeamAuthor.gd`
- `GuardSpawnAuthor.gd`
- `GuardPatrolRouteAuthor.gd`
- `MissionAuthoringRuntimeBuilder.gd`
- `MissionSecurityCamera.gd`
- guard/patrol runtime scripts
- `SecurityAuthoringRoot.gd`

### Roadmap Decision

Polish and generalize. Do not rebuild.

### Priority

High, but mostly an extension path rather than greenfield work.

## System Family 10: Sound, Noise, And Distraction

### Combines

- sound radius
- noise emitters
- noise listeners
- distraction objects
- poop bag distraction
- Bentley bark
- decoy toy
- fragile noise props
- fake alarms
- ambient noise masking
- sound surface zones

### Purpose

Stealth becomes more interesting when the player can manipulate attention, not just avoid cones.

### Current Status

Not obviously implemented as a central reusable system.

Partial support may exist through Bentley/card effects and security event routing.

### Roadmap Decision

Implement after suspicion, guard response, and base authorable nodes exist.

### Initial Scope

First version:

- `NoiseEvent`
- `NoiseEmitterNode`
- `NoiseListenerComponent`
- `DistractionObject`
- Bentley bark integration

### Priority

Medium-high.

## System Family 11: Inventory / Heist Kit

### Combines

- item data
- lightweight inventory manager/module
- heist tools
- key items
- evidence items
- consumables
- assist items
- suspicious carry objects
- contraband profiles
- item heat

### Purpose

Locks, searches, objectives, scheme cards, Bentley fetch, evidence, and extraction need a shared item vocabulary.

### Current Status

The current `src/inventory` area appears card-heavy. There is also loadout UI code:

- `src/ui/loadout/item_slot.gd`
- `equipment_item.gd`
- `loadout_selector.gd`

A lightweight heist-kit inventory should be verified before implementation.

### Roadmap Decision

Build a custom lightweight mission inventory. Do not install or design a heavy grid inventory plugin.

### Initial Scope

`ItemData` should include:

- item id
- display name
- category
- stackable flag
- max stack
- mission-only flag
- suspicious flag
- heat value
- icon
- description

The initial inventory module should support:

- add item
- remove item
- has item
- item count
- clear mission-only items at mission end if needed
- serialize/deserialize through existing save model only when permanent inventory is introduced

### Priority

High, but after base requirement/effect mechanics.

## System Family 12: Bentley Companion Mechanics

### Combines

- companion command points
- Bentley sniff
- Bentley fetch
- Bentley bark distraction
- Bentley crawlspace
- wait/stay
- Bentley danger sense
- emotional read
- dog-permitted access
- Bentley small-item carry

### Purpose

Bentley should become a mechanical partner, not only a follower.

### Current Status

Partial foundation:

- `src/player/DogCompanion.gd`
- `CardEffects.get_bentley_recharge_multiplier`
- `CardEffects.get_bentley_bark_radius_multiplier`
- Bentley-related cards such as `bentley_dental_boy` and `fish_treat_focus`

### Roadmap Decision

Build Bentley verbs as command points placed in the mission. Use `RequirementSet` and `EffectSet` so Bentley interactions can participate in objectives, cards, routes, suspicion, and rewards.

### Initial Scope

First command points:

- `BentleySniffTrail`
- `BentleyFetchTarget`
- `BentleyBarkDistractionPoint`
- `BentleyCrawlspaceConnector`
- `BentleyWaitMarker`

### Priority

Very high for game identity, but implement after foundation and minimal stealth response.

## System Family 13: Dialogue, Barks, And Micro Presentation

### Combines

- dialogue trigger zones
- bark triggers
- dialogue bridge
- cutscene trigger
- micro cutscene player
- Dave-the-Diver-style splashes
- mission intro/outro hooks
- Bentley reactions

### Purpose

Add personality and story without hardcoding dialogue into every mechanic.

### Current Status

Partially exists:

- `DialogueManager.gd`
- `MissionDialogueProvider.gd`
- `HideoutDialogicAdapter.gd`
- `DialogueBox.gd`
- `CutsceneTrigger.tscn`
- `data/dialogue/dialogue_portraits.json`

### Roadmap Decision

Add wrappers and triggers. Avoid coupling every mechanic to Dialogic internals.

### Initial Scope

`DialogueBridge` should support:

- play mission dialogue key
- play bark key
- play one-shot line
- resolve mission-specific speaker names if existing systems support it
- fail gracefully if no dialogue system is active

### Priority

Medium-high.

## System Family 14: Puzzle Objective Kit

### Combines

- power circuits
- fuse boxes
- terminal hacking
- timed switches
- pressure plates
- multi-switch locks
- object swaps
- dead drops
- bug planting
- eavesdropping
- tail targets
- carry object constraints
- passwords from environment

### Purpose

Generate side jobs and mission variety with reusable nodes.

### Current Status

Some placeholder scenes likely exist:

- `PuzzleGate.tscn`
- `AccessItem.tscn`
- `FriendAssistTrigger.tscn`

The full puzzle kit is not yet built.

### Roadmap Decision

Implement after base mission kit, stealth, and inventory. Puzzle nodes should use the same requirement/effect language as doors and triggers.

### First Side Jobs To Prove The Kit

1. Poop Bag Calibration Course
2. Bentley's Snack Trail
3. Louis' Loading Dock Favor
4. Desk Spirit Filing Test
5. Bouncer's Clipboard

### Priority

Medium.

## System Family 15: Social Stealth Framework

### Combines

- cover story manager
- disguise/credential system
- believable task zones
- protocol zones
- professionalism meter
- inspection zones
- etiquette traps
- queue cover
- cleanliness gates

### Purpose

Make stealth about belonging, not only hiding.

### Current Status

Mostly not implemented as a reusable system.

Some card names and mission concepts support the fantasy:

- `persian_tea_focus`
- `mere_legal_eyes`
- `clorox_wipe_protocol`
- `louis_delivery_route`

### Roadmap Decision

Implement after base stealth, inventory, and card-modifier integration.

### Initial Scope

First social stealth nodes/resources:

- `CoverStoryData`
- `CredentialData`
- `InspectionZone`
- `BelievableTaskZone`
- `ProtocolZone`
- `ProfessionalismMeter`

### Priority

High for game identity, but not first.

## System Family 16: Trace, Paper Trail, And Plausible Deniability

### Combines

- paper trail manager
- audit trail cleanup nodes
- plausible deniability meter
- suspicion provenance
- heat sink objects
- door state memory
- counter-surveillance sweep
- chain of custody
- evidence cleanup

### Purpose

The crime/spy/legal fantasy becomes systemic. The player should think about what they can explain, erase, redirect, or plausibly deny.

### Current Status

Partial supporting systems exist:

- evidence clues in `GameState`
- evidence board UI
- collectible/hideout sync
- mission performance events

Paper trail and deniability are not yet central gameplay systems.

### Roadmap Decision

Implement after social stealth basics.

### Initial Scope

First trace concepts:

- `TraceEvent`
- `PaperTrailManager` or equivalent adapter
- `AuditTrailCleanupNode`
- `PlausibleDeniabilityMeter`
- `DoorStateMemoryNode`
- `HeatSinkObject`

### Priority

Medium-high, after core identity pillars are stable.

## System Family 17: Hideout Meta / Cozy Systems

### Combines

- care stations
- plant care
- plant growth
- watering
- hideout decoration rewards
- store items
- NPC hideout dialogue
- evidence/clue displays
- Glow Guy shelf
- Polaroid display
- case cash

### Purpose

Make the hideout emotionally rewarding between missions.

### Current Status

Already strong:

- `HideoutManager.gd`
- `HideoutStoreController.gd`
- `HideoutCareController.gd`
- `HideoutCollectibleController.gd`
- `HideoutDecorationController.gd`
- `HideoutMissionBoardController.gd`
- `data/store/birthday_store_items.json`
- evidence board / polaroid / Glow shelf UI

### Roadmap Decision

Extend later as meta-loop enhancement. Do not distract from mission authoring foundation.

### Priority

Medium.

## System Family 18: Encounter / Boss Challenge Layer

### Combines

- encounter controller
- boss challenge phases
- challenge objectives
- stealth boss
- social boss
- camera boss
- paper trail boss
- nonlethal challenge layer

### Purpose

Create boss-like missions without defaulting to traditional combat.

### Current Status

Not yet generalized.

There is some combat/card language, but the stronger fit is encounter phases, not HP fights.

### Roadmap Decision

Defer until core mission systems are stable.

### Initial Scope

Later concepts:

- `EncounterController`
- `EncounterPhaseData`
- `ChallengeObjectiveNode`
- suspicion meter challenge
- security integrity challenge
- evidence strength challenge
- Bentley confidence challenge
- plausible deniability challenge

### Priority

Later.

## System Family 19: Advanced NPC/Social Simulation

### Combines

- witness courier
- routine tampering
- emergency drill
- gossip propagation
- authority chain
- attention budget
- NPC belief puzzle
- cascading failure
- reputation misfire
- undercover fan NPC

### Purpose

Make levels feel alive and reactive.

### Current Status

Some foundations exist:

- `NPC.gd`
- guard runtime
- patrol runtime
- security systems

This level of simulation is not ready yet.

### Roadmap Decision

Defer. These systems depend on stable NPC, suspicion, fact, route, and social stealth foundations.

### Priority

Later.

## Systems Not To Build From Scratch

| Brainstorm Item | Current Repo Equivalent | Treatment |
|---|---|---|
| Basic mission catalog | `GameState.mission_catalog` | Extend only. |
| Mission start/complete/fail | `GameState`, `SceneManager`, `Phase0KMissionCompletionController` | Generalize extraction. |
| Save/load | `SaveManager`, `GameState.to_dict/from_dict` | Extend for new data. |
| Scheme card collection/selection | `CardManager`, `SchemeCard`, `CardEffects`, `resources/cards` | Extend into mission modifiers. |
| Basic objective records | `QuestManager` | Add adapter/wrapper. |
| Dialogue manager | `DialogueManager`, `MissionDialogueProvider` | Add triggers/bridge. |
| Authored collectibles | collectible authoring/runtime/persistence/hideout sync | Extend pattern. |
| Taco authored security | security authoring/runtime/router | Extend pattern. |
| Mission debug panel | `IsoMissionDebugPanel` | Extend debug sections. |
| Hideout mission board | `HideoutMissionBoardController` | Extend. |
| Hideout collectible displays | evidence board, shelf, polaroids, collectible controller | Extend. |
| Hideout decoration/store/care | existing hideout controllers | Extend. |
| Basic Bentley presence | `DogCompanion.gd` | Add command system. |
| Player stamina/visual animation | player/stamina/visual animator scripts | Integrate, do not rebuild. |
| Art tile asset availability | PVGames paintable tilesets, PVGames object palette, blockout docs | Formalize fixed paint layers plus sortable 2.5D object layers. |

## Systems To Combine

| Brainstorm Mechanics | Combined System Family |
|---|---|
| TriggerZone, DialogueTrigger, BarkTrigger, SceneFlavorTrigger, AmbushTrigger | Authorable Trigger/Event Zone |
| Locked door, keypad, safe, gate, credential scanner, ID badge scanner | LockedInteractionNode / AccessNode |
| SearchZone, drawer, locker, fridge, RewardNode, SafeCracker | Search/Container/Reward family |
| ExtractionZone, ConditionalExit, FalseExit | Extraction/Exit family |
| RouteUnlock, one-way door, shortcut, card route, Louis route | RouteUnlock family |
| PatrolRoute, camera sweep, spotlight, guard post, vision cone | Detection Authoring family |
| Noise lure, poop bag, Bentley bark, fake alarm, fragile prop | Noise/Distraction family |
| Bentley sniff, fetch, bark, crawl, wait | CompanionCommandPoint command types |
| Cover story, disguise, credential, inspection | Cover/Credential family |
| Believable task, protocol, professionalism, etiquette, queue cover | Social Stealth Behavior family |
| Paper trail, audit cleanup, deniability, trace, heat sink | Trace/Deniability family |
| Dead drop, bug plant, object swap, eavesdrop | Spy Objective family |
| Routine tampering, emergency drill, gossip, authority chain | Advanced NPC Social State family |

## Systems To Implement Separately

| System | Reason |
|---|---|
| Inventory / Heist Kit | Core data/model/UI/save dependency. |
| Scheme Cards / Mission Modifiers | Existing card spine deserves dedicated extension. |
| Suspicion / Alarm | Central mission state. |
| Sound / Noise | Central stealth event bus. |
| Bentley Command System | Core identity pillar. |
| Visual Tile/Asset Painting Pipeline | Separate production/art workflow, including fixed tile paint layers and Y-sortable 2.5D prop/player containers. |
| DialogueBridge | Prevents direct coupling from every node to dialogue internals. |
| EncounterController | Later challenge/boss architecture. |

## Systems To Ignore For Now

| Idea | Reason |
|---|---|
| Full traditional combat | Not core identity; risks scope creep. |
| Heavy inventory plugin | Custom heist-kit inventory fits better. |
| Rhythm stealth | Too niche and genre-shifting. |
| Territory influence map | Too macro before individual missions work. |
| Full NPC belief simulation | Too abstract early. |
| Dynamic complex pathfinding | Use explicit routes and markers first. |
| Big `IsoMissionBase.gd` rewrite | High risk; refactor later only with tests. |
| Large scene-node cleanup | Separate visibility/audit phase only. |

## Phase 0: Protect And Extend Existing Spine

### Goal

Protect existing working systems while preparing them for plug-and-play mission authoring.

### Preserve

- `GameState`
- `SaveManager`
- `SceneManager`
- `QuestManager`
- `CardManager`
- `CardEffects`
- authored collectible stack
- authored security stack
- `IsoMissionBase`
- `HideoutHub`
- Taco `RedesignTest`

### Tasks

1. Define current manager ownership.
2. Identify the narrowest safe adapter points.
3. Decide where fact helper methods live.
4. Decide how effect application reports errors.
5. Add docs/tests before changing production mission behavior.
6. Avoid new autoloads unless a concrete implementation need appears.

### Done Criteria

- There is a short ownership note for mission state, quest state, card state, dialogue, inventory, and security.
- The team agrees which existing managers are authoritative.
- The next phase can add Resources and base nodes without rewiring the whole project.

## Phase 1: Shared Authoring Foundation

### Goal

Create the minimum reusable foundation for future drag-and-drop mechanics.

### Build Or Extend

1. Fact helper adapter over `GameState` and existing managers.
2. `RequirementSet` Resource.
3. `EffectSet` Resource.
4. `MechanicAreaBase` scene/script.
5. Debug output conventions.
6. Small validation scene for mechanic nodes.

### Initial Supported Requirement Types

- none/always true
- mission flag exists
- mission flag equals string/bool/int
- card selected
- card unlocked
- collectible acquired
- typed collectible count
- objective active
- objective completed
- alert state equals

### Initial Supported Effect Types

- set mission flag
- clear mission flag
- activate objective
- complete objective
- grant collectible
- grant typed collectible count
- grant/unlock card
- set alert state
- trigger dialogue key
- request mission complete/extraction

### Done Criteria

- One placed test node can require a fact, display a prompt, activate, apply an effect, and mark itself used.
- Failed requirements produce a designer-readable reason.
- Existing mission state and objective state are not duplicated.
- The implementation is small enough to revert without damaging unrelated systems.

## Phase 2: Mission Construction Kit

### Goal

Allow a basic mission or side job to be built from placed nodes and Resources.

### Build

1. `TriggerZone`
2. `LockedInteractionNode`
3. `ExtractionZone`
4. `SearchZone`
5. `InteractiveContainer`
6. `RewardNode`
7. `RouteUnlockNode`
8. `SideObjectiveNode`
9. `ObjectiveStepController` adapter over `QuestManager`

### Editor Tooling After The Mechanics Stabilize

Do not build the full editor UX before the reusable mechanic nodes work in the validation room. Once the Phase 2 nodes are stable, add tooling in this order:

1. Mission Authoring Palette for placing approved mechanic templates with safe defaults.
2. Mission Assist Browser for scene-wide validation, duplicate ID checks, broken links, and quick node selection.
3. Mechanic gizmos for interaction radii, trigger shapes, requirement/effect status, objective order, route links, and extraction boundaries.
4. Larger Scene/Asset Browser only after the smaller palette/browser workflows prove the categories and filters.

### Reuse

- `QuestManager`
- `GameState`
- `Phase0JInteractionBridge`
- `Phase0KMissionCompletionController`

### Done Criteria

- A designer can create a small mission loop with no custom mission script.
- The loop can include entry, search, optional objective, reward, route unlock, and extraction.
- Debug labels identify which placed node caused each state change.
- The editor tooling can place and inspect the same reusable nodes without creating a parallel mission-authoring format.

## Phase 3: Visual Tile / Asset Painting Pipeline

### Goal

Make mission spaces readable enough for mechanics to be tested honestly.

### Current Assets And Docs

- PVGames paintable tilesets
- isometric blockout tileset
- Taco marker legends
- art-ready workflow docs
- PVGames object palette plugin
- visual helper tooling

The current PVGames object palette is a searchable stamper with typed/mouse placement, not a brush. It should be improved before large visual passes so repeated floor, wall, decal, and prop placement does not require one-by-one dragging.

### 2.5D Depth Sorting Decision

Future mission visual authoring should separate fixed paint layers from dynamic Y-sortable visuals.

Use fixed-Z layers for:

- floor paint
- ground decals
- wall/floor blockout readability
- always-behind background art
- always-front foreground overlays
- lighting, debug labels, and authoring markers

Use a dedicated Y-sortable 2.5D visual container for:

- the player visual/token
- NPC/guard visuals
- movable or individually placed PVGames props that the player can walk in front of or behind
- counters, tables, terminals, pillars, crates, and similar waist-height world objects

Do not rely on ad hoc child `Sprite2D.z_index` offsets such as `-90` as the primary depth system. Z bands should define broad strata; Y-sort should handle local front/behind behavior inside the sortable world layer.

### Build Or Formalize

1. Gameplay collision layer rules.
2. Walkable floor layer rules.
3. Wall/blocker layer rules.
4. Decorative prop layer rules.
5. Foreground/depth layer rules.
6. Debug/authoring marker layer rules.
7. Y-sortable 2.5D world-object layer rules.
8. PVGames object palette routing rules for fixed background, sortable world objects, and foreground overlays.
9. Pivot/origin rules for sortable props, especially foot/contact-point origins.
10. PVGames object palette brush mode for repeatable stamps: click-drag, spacing, snap, jitter, line/rectangle/scatter, and erase-created-by-palette modes.
11. Mission Paint Dock for visual-only floor, wall, decal, and foreground painting that respects the Taco visual layer taxonomy.
12. Manual animation mapper/reviewer for PVGames character creator sheets, using manually curated row/column ranges instead of unreliable classifier labels.
13. Larger Scene/Asset Browser Dock after the palette, paint dock, authoring palette, and animation mapper prove their smaller workflows.
14. Taco painting checklist.
15. Interactable highlight style.
16. Security hazard visibility style.
17. Screenshot before/after validation routine.

### Phase 3 Tooling Order

1. Harden the existing PVGames object palette into `PVGames Object Palette v2` with brush/repeat placement and Y-sort route awareness.
2. Add Mission Paint Dock for visual-only paint layers; keep collision and gameplay authoring out of this dock.
3. Add manual animation mapper/reviewer for PVGames character creator sheets before relying on generated animation metadata.
4. Pilot a sortable 2.5D prop lane in Taco with pivot/contact-point validation.
5. Build the larger Scene/Asset Browser only after the smaller tools prove their asset categories and target routes.

### Phase 3 Tooling Status As Of 2026-05-22

The first focused editor tools now exist, but several still need manual validation and production follow-up packets before they should be treated as final pipeline infrastructure.

| Tool | Current status | Notes / next gate |
|---|---|---|
| PVGames Object Palette v2 | Phase 3G manual QA passed; ready for sign-off | Explicit Placement Route UI, Sortable 2.5D Prop route, erase-created-by-palette, safe box erase, collapsible dock sections, taller Results list, Variation, Placement Shape (stroke/rectangle/scatter), non-mutating dry run/arming, repeatable Place With Mouse including after `Ctrl+Z`, and sortable placement over existing BackgroundArt. Remains visual editor tooling only. |
| Mission Paint Dock v1 | Implemented enough for manual paint/blockout testing | Includes visual paint mode plus locked layout/collision modes for `GameplayRoot/LayoutRoot` layers. Collision barrier erase was repaired after playtest. Keep collision edits explicit and validate movement after use. |
| Manual Animation Mapper / Reviewer v1.3 | Phase 3I animation preview validation complete | Loads PVGames/composite sheets, saves reviewed JSON maps, and can generate validation-only `SpriteFrames`. The dock writes the small external-reference Parmida preview at `res://resources/character_animation_maps/generated_preview/character_01_parmida_reference_variant_preview_spriteframes.tres`; the old embedded `parmida_manual_preview_spriteframes.tres` is legacy/unsafe for auto-loading. Manual QA confirmed 50x50 auto-detection, usable zoom/scroll/pan, clear selection workflow, JSON save/reload, reviewed `SpriteFrames` generation, sandbox playback, and 2026-06-09 animation preview validation. It still must not promote animations to `player.tscn`, Taco, or runtime controllers without a separate production promotion packet. |
| Scene/Asset Browser | Phase 3K complete as read-only browser foundation | The dock searches/selects/opens proven PVGames objects/icons, templates, animation maps/previews, dev scenes, and reports. Manual editor validation was completed on 2026-06-09. It remains explicitly non-authoring: no placement, stamping, painting, generation, promotion, save, route invention, or default-mechanic creation. |

Current animation gate status: Phase 3I preview validation passed on 2026-06-09. A separate production promotion packet is still required before any generated preview `SpriteFrames` are wired into `player.tscn`, Taco, or runtime controllers. Phase 3J and Phase 3K are complete as validation/tooling foundations, so the next gameplay-facing work should return to the production pilot / mission-authoring sequence unless a specific Phase 3 polish packet is prioritized.

### Proposed Visual Depth Bands

The initial authoring vocabulary should be:

| Band | Purpose | Sorting |
|---|---|---|
| Background/floor art | Floors, decals, rugs, floor stains, non-interactive under-player details | Fixed behind player |
| Sortable world visuals | Player, NPCs, guards, counters, tables, terminals, movable/placed props | Shared Y-sort parent |
| Foreground overlays | Ceiling trim, top-wall caps, always-front occluders, dramatic foreground art | Fixed in front |
| Debug/authoring overlays | Labels, marker guides, mechanic previews | High fixed Z and editor/runtime visibility rules |

PVGames palette containers should evolve from only `BehindPlayerObjects`, `OccludableObjects`, and `ForegroundObjects` into an explicit route for sortable 2.5D objects. Until that migration is implemented, `OccludableObjects` is a staging area, not the final long-term depth solution.

### Done Criteria

- A playable Taco area has clear walkable, blocked, interactable, hazard, and objective-readable spaces.
- Future missions can copy the visual layer taxonomy.
- Mechanics are not hidden by art noise.
- Player/world-object depth reads correctly in at least one test lane where the player walks above and below a sortable PVGames prop.
- Fixed tile painting remains collision-free and does not fight the sortable visual layer.
- Repeatable visual assets can be painted or brushed without one-by-one scene-tree dragging.
- Character animation mappings come from a reviewed row/column manifest, not from untrusted classifier clip names.

## Phase 4: Stealth Readability And Escalation

### Goal

Make detection, suspicion, and alarm states readable and reusable.

### Build Or Extend

1. Suspicion adapter/manager.
2. Existing mission alert state extensions.
3. Alarm state controller wrapper.
4. Patrol and vision polish on current security authorables.
5. Hide spots.
6. Camera sweep/camera loop extension.

### Reuse

- `MissionAlertController.gd`
- `SecurityEventRouter.gd`
- `MissionSecurityCamera.gd`
- guard/patrol runtime
- security author scripts

### Done Criteria

- Suspicion is debuggable.
- Detection consequences are data-driven through effects.
- Security events can activate mission facts, objectives, routes, or alarms.

## Phase 5: Inventory / Heist Kit

### Goal

Create a lightweight shared item vocabulary for mission mechanics.

### Build

1. `ItemData` Resource.
2. `InventoryEntry` data structure.
3. Lightweight inventory module or manager.
4. `InventoryPickup` mechanic node.
5. Save/load extension for persistent items only.
6. Mission-only item cleanup policy.
7. Simple UI list or debug panel view.
8. Integration with `RequirementSet`.

### Do Not Build Yet

- grid inventory
- crafting-heavy item system
- merchant economy
- large equipment plugin

### Done Criteria

- A locked node can require an item.
- A search node can grant an item.
- Extraction can require an item.
- Mission-only items do not pollute permanent save data unless explicitly intended.

## Phase 6: Scheme Card Mission Modifiers

### Goal

Make selected cards change mission setup and placed mechanics.

### Extend

- `CardManager`
- `CardEffects`
- `SchemeCard.gd`
- `GameState.selected_cards`

### Build

1. Card fact application.
2. `SchemeCardTriggerNode`.
3. Card-driven route unlocks.
4. Card-driven starting items.
5. Card-driven mission modifiers.

### Example Results

- Louis route card unlocks loading dock.
- Mere tip highlights a clue.
- Bentley card improves sniff/fetch/bark behavior.
- Clorox card enables wipe/cleanup bonuses.

### Done Criteria

- At least one selected card changes a placed node's availability.
- At least one selected card changes mission start conditions.
- Card behavior remains centralized enough to debug.

## Phase 7: Bentley Core Verbs

### Goal

Make Bentley a systemic partner.

### Build

1. `CompanionCommandPoint` base.
2. `BentleySniffTrail`.
3. `BentleyFetchTarget`.
4. `BentleyBarkDistractionPoint`.
5. `BentleyCrawlspaceConnector`.
6. `BentleyWaitMarker`.

### Reuse

- `DogCompanion.gd`
- `CardEffects` Bentley modifiers
- future noise/distraction system

### Done Criteria

- A placed command point can call Bentley to do one clear action.
- The action can be gated by requirement data.
- The action can apply effects.
- Card modifiers can influence at least one Bentley verb.

## Phase 8: Puzzle And Side Job Kit

### Goal

Create repeatable mission variety from a compact set of puzzle verbs.

### Build

1. Terminal/hack node.
2. Power circuit/fuse box.
3. Timed switch.
4. Pressure plate.
5. Dead drop.
6. Object swap.
7. Bug plant.
8. Eavesdrop zone.
9. Carry object.
10. Tail target later.
11. Custom chronographic sequence Resources for authored order-of-operations puzzles, such as first dead drop before second dead drop.

### Custom Sequence Direction

Prefer small data-driven custom sequences over a giant global orchestrator. A `CustomSequenceResource` should define ordered steps with `step_id`, `order_index`, requirements, completion conditions, and effects. Chronographic relationships should be explicit through `depends_on_step_ids` and readable editor gizmos.

### First Side Jobs

1. Poop Bag Calibration Course
2. Bentley's Snack Trail
3. Louis' Loading Dock Favor
4. Desk Spirit Filing Test
5. Bouncer's Clipboard

### Done Criteria

- At least two side jobs can be assembled mostly from reusable nodes.
- Puzzle nodes share the same requirement/effect/debug conventions as the core mission kit.
- Sequence puzzles can enforce authored order without mission-specific GDScript or a large orchestrator.

## Phase 9: Narrative And Presentation

### Goal

Add story, jokes, mission flavor, and pacing without hardcoding dialogue into mechanics.

### Build

1. `MissionDialogueBridge` expansion for real dialogue-key lookup while preserving simple fallback lines.
2. `DialogueTriggerZone`.
3. `BarkTrigger`.
4. `CustomSequenceRunner` for short authored sequences and mission presentation beats.
5. `CameraBridge` for named camera focus, blends, shake, and restore behavior.
6. PhantomCamera integration behind `CameraBridge` when camera presentation needs plugin-grade framing and blends.
7. `PlayerControlBridge` for temporary input lock, guided movement, and restore behavior during short sequences.
8. `AudioVisualBridge` for named presentation cues.
9. Resonant visual audio manager integration behind `AudioVisualBridge` for audio-reactive mission, UI, dialogue, alarm, and ambience feedback.
10. `MicroCutscenePlayer` only if the custom sequence runner proves too small for a recurring presentation need.
11. Mission intro hooks.
12. Mission outro hooks.

### Reuse

- `DialogueManager`
- `MissionDialogueProvider`
- `DialogueBox`
- Dialogic adapter if active
- PhantomCamera if installed and validated in this project
- Resonant if installed and validated in this project

### Done Criteria

- A mechanic can trigger dialogue through an effect without knowing dialogue implementation details.
- A mission intro/outro can be triggered by mission state.
- Bark spam is prevented by cooldowns or one-shot settings.
- Camera, player-control, and visual-audio plugin calls are routed through bridges rather than scattered through mechanics.
- If PhantomCamera or Resonant are absent, sequence steps fail safely or fall back to built-in behavior.

## Phase 10: Social Stealth Identity

### Goal

Make the game about acting believable, not only hiding.

### Build

1. `CoverStoryManager` or adapter.
2. Credential/inspection zone.
3. Believable task zone.
4. Protocol zone.
5. Professionalism meter.
6. Cleanliness gate/wipe station.

### Done Criteria

- An NPC/security zone can accept the player because the player has a plausible reason to be there.
- A believable task can reduce suspicion or prevent inspection.
- Professionalism/cleanliness can act as mission facts.

## Phase 11: Paper Trail / Deniability

### Goal

Make evidence, cleanup, trace, and plausible denial into gameplay.

### Build

1. Paper trail adapter/manager.
2. Audit trail cleanup node.
3. Plausible deniability meter.
4. Door state memory.
5. Suspicion provenance.
6. Heat sink object.

### Reuse

- evidence board
- `GameState` evidence records
- mission performance events

### Done Criteria

- The player can leave trace events.
- The player can clean up some trace events.
- Mission results can reflect whether the player was suspicious, seen, explainable, or deniable.

## Phase 12: Hideout Cozy Meta

### Goal

Strengthen the between-mission emotional loop after mission authoring is stable.

### Extend

- `HideoutCareController`
- `HideoutStoreController`
- `HideoutCollectibleController`
- decoration/store systems

### Build

1. Plant data.
2. Plant growth stage data.
3. Care station improvements.
4. Mission-return growth triggers.
5. Plant rewards/dialogue.

### Done Criteria

- Mission rewards visibly affect hideout state.
- Hideout care creates low-pressure reasons to return.
- Systems save/load cleanly.

## Phase 13: Encounter / Boss Challenges

### Goal

Create climactic challenge missions without defaulting to combat.

### Build

1. `EncounterController`.
2. `EncounterPhaseData`.
3. `ChallengeObjectiveNode`.
4. Suspicion challenge meter.
5. Security integrity challenge meter.
6. Evidence strength challenge meter.
7. Bentley confidence challenge meter.
8. Plausible deniability challenge meter.

### Avoid

Traditional HP combat as the default challenge model.

### Done Criteria

- A challenge can progress through phases using objective/fact state.
- The player wins through stealth, social, route, evidence, or Bentley play.

## Phase 14: Advanced Reactive NPC/Social Systems

### Goal

Make mature levels feel alive and reactive after the core systems are stable.

### Defer Until Later

- LimboAI integration for behavior trees/state machines.
- witness courier
- routine tampering
- emergency drill
- gossip propagation
- authority chain
- attention budget
- cascading failure
- reputation misfire
- retcon token

### Done Criteria

- Only start this phase after NPC, suspicion, social stealth, route, and fact systems are stable.
- LimboAI is used for mature NPC/guard/social behavior only after simpler authored command points and security authoring prove insufficient.

## Current Short-Term Dependency-Order Plan

Date: 2026-06-09

This section records the current short-term execution order. It is intended to be referenced and revised as validation results come in. The order below is dependency-driven rather than strict numeric phase order.

| Order | Work | Roadmap / Blueprint ID | Notes |
|---:|---|---|---|
| First | Validate Mission Paint Dock if using collision/layout edits | Phase 3H | Complete as of 2026-06-09. Jake confirmed Mission Paint Dock validation passed after the quick paint/collision-layout check. |
| Second | Validate animation previews before production promotion | Phase 3I | Complete as of 2026-06-09. Jake confirmed animation preview validation passed. Production animation promotion still requires a separate packet. |
| Third | Validate Taco production pilot / Packet 6C | Phase 2J, Packet 6C follow-up | Complete as of 2026-06-09. Jake confirmed Packet 6C passed: live pilot validation did not expose Phase0J/Phase0K regression. |
| Fourth | Fix pilot issues found during Packet 6C | Phase 2J follow-up | No immediate fix pass required after the 2026-06-09 Packet 6C pass. Reopen only if later validation finds pilot issues. |
| Fifth | Confirm core reusable mechanic kit status | Phase 1C, Phase 1E, Phase 1J, Phase 1K, Phase 2A-2H | Complete as of 2026-06-09. Jake confirmed GdUnit `mission_authoring` PASS, `MechanicAuthoringTestRoom` live chain PASS, Taco Packet 6C already confirmed, and no new core-kit fixes required. |
| Sixth | Finish necessary PVGames Palette v2 safety features | Phase 3G | Complete as of 2026-06-13. Jake confirmed scratch + sortable pilot manual QA passed, including repeatable Place With Mouse after `Ctrl+Z`, safe box erase, collapsible dock UX, rectangle/scatter placement, variation, sortable route placement, and non-palette erase refusal. |
| Seventh | Add combined Mission Dock (Authoring Palette + Assist Browser) | Phase 2K | Complete as of 2026-06-15. Implementation landed under `addons/mission_dock/`; places all approved mechanic classes with safe defaults and includes read-only scene audit. Jake manual QA found parent fallback, BBCode details, starter requirement, and verification-summary issues; post-QA fix pass retest passed. |
| Eighth | Mission Assist Browser follow-up polish | Phase 2K | Core audit shipped inside Mission Dock; gizmo/readability polish remains deferred. |
| Ninth | Add card-driven modifiers | Phase 6A-6F | Phase 6A implemented 2026-06-15; Phase 6B implemented 2026-06-16 with inspectable `MissionModifierSet` data bundles; Phase 6C plus 6D-lite/6E-lite implemented 2026-06-17 with reusable `SchemeCardTriggerNode`, route-flag proof, ready-time setup hook, tests, and dev-room sample. Production Phase 6F card slice remains deferred. |
| Tenth | Phase 4 stealth readability | Phase 4A-4G | Alert/suspicion/readability work after the production pilot foundation is trusted. |
| Eleventh | Phase 5 inventory / heist kit | Phase 5A-5F | Item data, mission inventory, and requirement/effect integration. |
| Twelfth | Bentley command points | Phase 7A-7G | Companion command mechanics built on the reusable mechanic foundation. |
| Thirteenth | Noise / distraction | Roadmap System Family 10; Blueprint Noise And Distraction section; related to Phase 7D | Sound/noise events, emitters, listeners, and distraction objects. |
| Fourteenth | Side jobs | Phase 8G-8H | First and second small side jobs assembled mostly from reusable nodes. |
| Fifteenth | Hideout rewards | Phase 12A-12F | Reward-to-hideout contract and cozy meta hooks. |
| Sixteenth | Paper trail | Phase 11A-11F | Trace events, cleanup, deniability, suspicious action memory, and result integration. |
| Seventeenth | Social stealth | Phase 10A-10G | Cover stories, credentials, believable tasks, inspections, and protocol/cleanliness. |
| Eighteenth | Encounters | Phase 13A-13G | Non-HP challenge/encounter layer. |
| Nineteenth | Advanced NPC | Phase 14A-14G | Reactive NPC/social systems after simpler systems are stable. |
| Twentieth | Narrative / presentation | Phase 9A-9H | Dialogue keys, barks, presentation sequences, camera/player/audio bridges. |

Update rule: revise this section after each completed gate or when validation changes the dependency order.

## Highest-Value Near-Term Build Order

This is the recommended first implementation sequence:

1. Fact helper adapter on `GameState` and existing managers.
2. `RequirementSet`.
3. `EffectSet`.
4. `MechanicAreaBase`.
5. `TriggerZone`.
6. `ObjectiveStepController` adapter over `QuestManager`.
7. `ExtractionZone`.
8. `LockedInteractionNode`.
9. `SearchZone`.
10. `InteractiveContainer` / `RewardNode`.
11. `RouteUnlockNode`.
12. PVGames Object Palette v2 brush/repeat placement and Y-sort route awareness.
13. Mission Paint Dock for visual-only floor/wall/decal/foreground passes.
14. Manual PVGames character animation mapper/reviewer foundation.
15. Reviewed animation-map curation for the manual 5-pack sheets using the repaired Large Review Canvas.
16. Sandbox validation of generated animation `SpriteFrames`, then a separate production promotion decision.
17. Taco visual readability / tile painting pass, including a first Y-sortable 2.5D visual lane.
18. Mission Authoring Palette.
19. Mission Assist Browser and core gizmos.
20. Heist-kit inventory.
21. Scheme card facts/modifiers.
22. Suspicion/alarm wrapper.
23. Bentley `CompanionCommandPoint`.
24. Noise/distraction.
25. First side job.
26. Custom chronographic sequences.
27. `AudioVisualBridge` with optional Resonant integration.
28. `CameraBridge` with optional PhantomCamera integration.
29. `PlayerControlBridge` for sequence control.

## Strategic Identity

The strongest game identity is not generic top-down stealth with guards.

The stronger target is:

```text
A cute noir heist/social-stealth game where the player wins by acting believable, using friends, cleaning up traces, drafting scheme cards, and solving problems with Bentley.
```

The systems that most protect that identity are:

1. Bentley command verbs.
2. Scheme card mission mutations.
3. Cover story and believable task systems.
4. Paper trail and plausible deniability systems.
5. Social debt and kindness shortcuts.
6. Hideout cozy rewards.
7. Art-painted readable 2.5D mission spaces.

The systems that most protect implementation sanity are:

1. Requirements.
2. Effects.
3. Mechanic base.
4. Objective adapter.
5. Inventory.
6. Card modifier bridge.
7. Debug/test rooms.
8. Visual layer rules.
9. Focused editor tools before large all-in-one browsers.
10. Plugin bridges that degrade safely when optional plugins are absent.

## Next Planning Document Needed

The next document should be an implementation blueprint for Phase 1 through Phase 2. It should specify exact script/resource names, folder locations, exported properties, method signatures, signal names, data structures, validation scenes, tests, and integration points with current managers.
