# Mission Implementation Status

## Phase 1 Framework

Implemented additively beside the current story missions:

- Typed `MissionDefinition` Resource classes.
- `IsoMissionBase.gd` reusable isometric blockout generator.
- Canonical `IsoMissionTemplate.tscn`.
- Semantic iso blockout TileSet and generated placeholder atlas.
- Generic placeholder interactables for objectives, clues, collectibles, poop bags, puzzle gates, access items, cutscene triggers, friend assists, and exits.
- Lightweight typed collectible tracking for Mission Bible collectible types.
- `MissionBlockoutValidator.gd`.
- Taco Bell Drop sample definition and isolated iso blockout prototype.

## What Remains Stubbed

- Glow Guy / Desk Spirit / Tiny Icon / Shelf Goblin hideout UI integration.
- Full evidence-board UI integration for new clue resources.
- Real enemy spawning/path following from `MissionSpawnDefinition`.
- Puzzle-specific UI beyond placeholder triggers.
- Full reachability/pathfinding validation.
- Automated completion smoke path.
- ArtRoot painting with final Monogon art.

## Taco Bell Sample Status

- Scene: `scenes/missions_iso/TacoBellIsoBlockout.tscn`
- Definition: `assets/missions/taco_bell_iso_blockout_definition.tres`
- Not registered in `GameState.mission_catalog`; run directly for Phase 1 testing.
- Includes zones, objectives, a puzzle gate, Bentley scent placeholder, one required clue, Polaroid, Glow Guy, Tiny Icon, three poop bags, exit, reward card reference, final tower logistics links, and mutation data.

## Taco Bell Phase 2A Iso Conversion

- Status: `BLOCKOUT_GOLD_STANDARD_CANDIDATE`.
- Still additive: `GameState.mission_catalog["taco_bell_drop"].scene_path` continues to point at the existing story `TacoBellMission.tscn`.
- The iso blockout now represents the full Taco Bell Drop route as a deliberate 15-zone tutorial map: west Louis handoff, market street, north dog-station dead end, delivery-alley scent hub, north trash fake trail, south loading-dock fake trail, east real garage entrance, large garage floor 1, north security/keycard booth, northeast garage office/code gate, garage floor 2 ambush, bag recovery room, south return drop, long westbound return corridor, and west-side return-to-Louis exit.
- Implemented placeholder mechanics: Bentley real/fake scent feedback, garage code gate with mutation-aware code, staff keycard/bypass pickup, readable objective chain, required clue pickups, optional collectibles, heat guard/camera/alarm markers, micro-cutscene hooks, locked-exit feedback, and walk-in/E exit completion.
- Validator result: PASS with reachable required objectives/clues/exit, open internal transitions, generated boundary colliders, no marker/floor/art collision leaks, and a real mission completion path.
- Phase 2A.2 map reshape: no longer a straight test track. Distinct graybox spaces, optional side branches, readable choke points, colliding cover blocks, room-like garage/office/bag spaces, and a separate southern loop-back return path are generated from the mission definition plus the Taco Bell layout profile.
- Collision status: `GameplayCollisionLayer` paints walls around the irregular floor footprint and intentional `TILE_COVER` blockers; generated `BoundaryColliders` now follow exterior wall cells rather than one broad rectangular cage. Required interactables use Area2D radii/debug labels and are validated for group/method/shape support.
- Phase 2A.2 start-area fix: the Louis handoff plaza was widened after manual testing found the player could spawn pinned by the wall-following boundary rectangles. Spawn now sits in a validated 3x3 clear floor area, the Start-to-Market opening validates at 2+ cells wide, and movement-first smoke testing must confirm real input moves the player before any teleported objective checks.
- Phase 2A.2 passage-clearance fix: the southern return corridor, bag-room drop, and west exit approach were widened after manual testing found grid-reachable passages that the player body could not physically fit through. Required route connections now validate at 3+ cells wide, the return/exit approach validates separately, and the iso blockout player instance uses a local 0.86 visual scale with a 24x24 collision body; the base player scene remains unchanged.
- Still stubbed: real keypad UI, final enemy/patrol/camera AI polish, true vent traversal, future reward-card shortcut behavior, final art painting, hideout display UI for non-Polaroid typed collectibles.
- Safe future switch criteria: after one manual QA pass in the editor, it is reasonable in a later phase to switch `GameState.mission_catalog["taco_bell_drop"].scene_path` to `res://scenes/missions_iso/TacoBellIsoBlockout.tscn`.

## Known Bible vs Current Code Mismatches

- `docs/MISSION_BIBLE.md` names the Phase 2 transport slot as **Car Chase**, while current project ids use `fast_family_getaway`.
- Some Mission Bible intended rewards are not current `GameState.mission_catalog` rewards. Phase 1 records rewards in definitions but does not change catalog behavior.
- Typed collectibles beyond Polaroids exist as design targets, but current project has only robust Polaroid support plus poop bags. Phase 1 tracks the rest as placeholder flags.
- Several existing story mission scripts already contain bespoke partial implementations; Phase 1 does not migrate or replace them.

## Recommended Conversion Order

1. Taco Bell Drop
2. Velvet Paw Jazz Club
3. Rewrite Room
4. Clean Job
5. Diamond a Year Job
6. Fast Family Getaway
7. Persian Tea and Poison Ink
8. Elephant in the Room
9. Arm-Wrestling Underground
10. Shadow Solo Contract
11. Sterling Tower Heist
