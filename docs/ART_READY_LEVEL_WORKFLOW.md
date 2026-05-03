# Art-Ready Isometric Level Workflow

Phase 1 adds a parallel data-driven isometric blockout framework. It does **not** replace the existing story mission scenes.

## Core Pieces

- `src/missions/definitions/` contains typed `Resource` classes for mission data.
- `src/levels/IsoMissionBase.gd` extends `LevelBase.gd` and generates functional blockouts from `MissionDefinition` resources.
- `scenes/templates/IsoMissionTemplate.tscn` is the canonical scene hierarchy.
- `assets/tilesets/iso_blockout/IsoBlockoutTileset.tres` is the semantic gameplay TileSet.
- `src/tools/MissionBlockoutValidator.gd` validates definitions and generated scenes.

## Scene Structure

```text
MissionRoot
  GameplayRoot
    GameplayFloorLayer
    GameplayCollisionLayer
    GameplayMarkersLayer
    ObjectiveAreas
    ExitAreas
    SpawnPoints
    EnemyPaths
  ArtRoot
    GroundArtLayer
    WallArtLayer
    PropArtLayer
    DecorBelowLayer
    DecorAboveLayer
    LightingLayer
  EntityRoot
    Enemies
    Interactables
  Camera2D
  MissionController
```

`GameplayRoot` is functional. `GameplayCollisionLayer` owns blocking collision. `GameplayMarkersLayer` is semantic/debug only.

`ArtRoot` is visual only. Later Monogon cyberpunk art should be painted under `ArtRoot` and should not become the source of gameplay collision.

## Placeholder Tile Semantics

The blockout atlas is a 6x3 grid of 64x64 tiles:

- `(0,0)` floor walkable
- `(1,0)` wall blocking
- `(2,0)` cover low
- `(3,0)` player spawn marker
- `(4,0)` enemy spawn marker
- `(5,0)` objective marker
- `(0,1)` interactable marker
- `(1,1)` clue marker
- `(2,1)` Polaroid marker
- `(3,1)` Glow Guy / Desk Spirit marker
- `(4,1)` Tiny Icon / Shelf Goblin marker
- `(5,1)` Bentley poop bag marker
- `(0,2)` hazard marker
- `(1,2)` camera bound marker
- `(2,2)` patrol point marker
- `(3,2)` exit marker
- `(4,2)` puzzle gate marker
- `(5,2)` friend assist trigger marker

Only wall and cover tiles have TileSet collision by default.

## Mission Definitions

Mission definitions live as `.tres` resources. They contain metadata, zones, objectives, collectibles, evidence clues, rewards, gates, cutscene stubs, mutations, routes, enemy markers, and final tower links.

Use `docs/MISSION_BIBLE.md` as the design source of truth. Use `GameState.mission_catalog` for current ids/reward behavior until the story flow is migrated.

## Placeholder Interactables

Generic placeholder scripts live under `src/missions/iso/placeholders/`. They use the existing `interactable` group and `interact(player)` pattern, plus `QuestManager`, `DialogueManager`, `GameState`, and `CollectibleManager` where applicable.

Typed Mission Bible collectibles beyond Polaroids are tracked lightly through saved `GameState.dialogue_flags` keys until the hideout UI gets a proper typed collectible layer.

## Validator

`MissionBlockoutValidator.gd` checks:

- mission id and display data
- primary objectives
- evidence clues
- rewards
- collectibles
- poop bag count warning
- required scene hierarchy
- floor and collision layer cells
- exit areas
- camera bounds
- generated objective/clue nodes
- reward mismatches against `GameState.mission_catalog`

Use it from Godot code or MCP:

```gdscript
var def := load("res://assets/missions/taco_bell_iso_blockout_definition.tres") as MissionDefinition
var report := MissionBlockoutValidator.validate(def, get_tree().current_scene)
MissionBlockoutValidator.print_report(report)
```

## Taco Bell Iso Prototype

Run directly:

`res://scenes/missions_iso/TacoBellIsoBlockout.tscn`

It is not registered into `GameState.mission_catalog`; this keeps the existing story Taco Bell mission intact.

## Future Conversion Steps

1. Create a `MissionDefinition` from Mission Bible + current `GameState` ids.
2. Duplicate `IsoMissionTemplate.tscn` into `scenes/missions_iso/`.
3. Assign the definition to the root `IsoMissionBase.gd`.
4. Run validator.
5. Iterate until gameplay path works with placeholder tiles.
6. Only after gameplay is stable, paint final Monogon art under `ArtRoot`.
