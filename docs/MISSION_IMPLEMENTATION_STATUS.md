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
