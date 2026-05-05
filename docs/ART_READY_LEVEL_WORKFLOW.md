# Art-Ready Isometric Level Workflow

Phase 1 adds a parallel data-driven isometric blockout framework. It does **not** replace the existing story mission scenes.

## Editor-Authorable Iso Mission Workflow (Phase 2A.5)

Current Taco Bell mode is **hybrid**.

- `MissionDefinition` is the source of mission metadata (objectives, clues, rewards, mutation pools, route requirements, typed collectible metadata).
- Scene-authored data is the source of exact marker positions via `GameplayRoot/AuthoringMarkers` (`IsoAuthoringMarker.gd`) and may also be the source of tile layout when `authoring_mode` is `scene_authored`/`hybrid`.
- Runtime systems read scene markers first, then definition fallback positions.

In authoring_mode = "hybrid", scene-authored marker positions are the source of truth for placement.  MissionDefinition data supplies metadata and mission rules.  If a scene marker exists for an object, runtime must use the scene marker position, not the generated definition position.

### Source-Of-Truth Contract

- `generated`: runtime clears/repaints gameplay tile layers and regenerates marker placements from definition cells.
- `scene_authored`: runtime keeps scene tilemaps and marker nodes; generator must not clear hand-authored gameplay layers.
- `hybrid` (Taco Bell now): mission data comes from definition, positions come from scene markers when present; definition marker cells are fallback.

### Safe Manual Edits

- Safe to edit: `GameplayRoot/AuthoringMarkers`, `GameplayFloorLayer`, `GameplayCollisionLayer`, `GameplayMarkersLayer` (debug/semantic), route subarea spawn markers, and marker node positions for objectives/collectibles/routes/cameras/lights/alarms/transitions.
- Safe to add/move/delete approved marker types in `IsoAuthoringMarker.marker_type` (player spawn, guard spawn, code gate, clue, Glow Guy, Tiny Icon, poop bag, scent trails, route access, transition, exit, alarm, ambush, subarea spawns, etc.).
- Safe to hand-place floor/wall/cover/collision barrier tiles in hybrid and scene-authored modes.

### Unsafe Manual Edits

- Do not manually paint gameplay-critical collision in `ArtRoot` (visual-only).
- Do not treat `RuntimeSystems` children as authored content; they are runtime-spawned and may be recreated every load.
- In `generated` mode, gameplay tile/marker edits are expected to be overwritten.

### How To Author Common Items

- Add guard: place `IsoAuthoringMarker` with `marker_type=GUARD_SPAWN`, `marker_id=<spawn_id from definition enemy entry>`.
- Add patrol route: add `PATROL_POINT` markers with shared `linked_guard_id`, sorted by `order`.
- Add collectible: marker type `POLAROID_*`, `GLOW_GUY`, `TINY_ICON`, or `POOP_BAG` with `marker_id=<collectible_id>`.
- Move exit: marker type `EXIT`, `marker_id=exit_return_to_louis`.
- Add camera/light/alarm: `SECURITY_CAMERA`, `SHADOW_ZONE`/`BRIGHT_ZONE`/`FLICKER_ZONE`, `ALARM_ZONE`.
- Add transition route test: `ROUTE_ACCESS` plus `SUBAREA_SPAWN` markers for entry/return ids.

### Validate + Test

1. Run `MissionBlockoutValidator.validate(def, current_scene)`.
2. Check debug fields: `authoring_mode`, `layout_source`, `marker_source`, `scene_markers_found`, `generated_markers_found`, `runtime_marker_to_object_counts`, `enemy_iso_scale_ok`, `overlapping_interactables`.
3. Confirm `runtime_position_mismatches=[]` and `hybrid_ignored_scene_markers=[]` after marker moves.
4. In debug builds, use `IsoMissionDebugPanel` for heat, alarm, route, poop bag, code gate, and teleport smoke actions.
5. Confirm player-facing checks: code-gate wrong/correct path, scent fake/real behavior, route lock/unlock behavior, alarm->extra guard escalation, and combat hit compatibility (`Player attacked` / `Guard hit`).

### 2A.5 Gameplay-Testability Notes

- `SceneManager.start_mission("taco_bell_drop")` now uses `TacoBellIso_Editable.tscn` in debug mode when `dev_force_iso_taco_bell` is enabled.
- `IsoMissionDebugPanel` now reports active real scent route, active garage code, extra guard/camera booleans, and typed collectible counts.
- Interaction selection now strongly deprioritizes completed interactables and prefers incomplete/required nodes.
- Guard/camera stealth visibility is debug-visible (camera cones + guard cones) and alert controller reports detection modifier (light-zone + cover).

### Direct Answer: “Will manual edits persist?”

- **Yes in `scene_authored` and `hybrid`** for approved gameplay tile/marker layers and `IsoAuthoringMarker` nodes.
- **No in `generated`** for generated gameplay tile/marker content.
- Taco Bell is now `hybrid`, so marker and tile edits in gameplay layers are used at runtime unless you explicitly switch mode back to `generated`.

## Editable Scene Workflow (Phase 2A.4A)

- Primary editable scene: `res://scenes/missions_iso/TacoBellIso_Editable.tscn`
- Destructive test scene: `res://scenes/missions_iso/TacoBellIso_Editable_Test.tscn`
- Bake tool entry: `res://src/tools/BakeIsoMissionToEditableScene.gd` or `IsoMissionBase.bake_to_editable_scene()`
- Editor-authorable roots:
  - `GameplayRoot/LayoutRoot/*` for hand-painted floor/wall/cover/barrier
  - `GameplayRoot/MarkerRoot/*` for draggable gameplay markers
  - `GameplayRoot/RuntimeSystems/*` for runtime-only spawned objects (not hand-authored)
- Detailed Q/A and first-safe-edit tutorial: `docs/ISO_EDITOR_AUTHORING_WORKFLOW.md`

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
    BoundaryColliders
    RuntimeSystems
      SpawnedGuards
      SpawnedCameras
      LightZones
      DetectionZones
      AlarmZones
      EncounterZones
      RouteAccessPoints
      TransitionTriggers
      DebugLabels
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
    Cameras
    Interactables
    DynamicProps
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

Phase 2A promotes this scene to the Taco Bell gold-standard blockout candidate:

- `GameplayRoot` is generated from `assets/missions/taco_bell_iso_blockout_definition.tres`.
- Zone labels and semantic marker tiles are placeholder-safe and may be deleted/hidden later only after equivalent art-readable cues exist.
- Phase 2A.2 reshapes the spatial profile into the reference topology for future missions: west Louis start, market-street branch to a north dog-station dead end, central delivery-alley scent hub, two fake scent dead ends, real eastbound garage route, large garage floor, security/keycard booth, garage office/code gate, ambush room, bag room, south return drop, long westbound return corridor, and west-side exit.
- `ArtRoot` remains for hand-painted Monogon art only. Paint ground, walls, props, lighting, and decoration under `ArtRoot`; do not add gameplay collision there.
- Keep `GameplayCollisionLayer` and `BoundaryColliders` as the source of truth for walls/containment. Boundary colliders are generated from exterior wall cells so containment follows the irregular graybox footprint instead of a broad map rectangle.
- Interior graybox cover/choke markers are generated as colliding cover cells in `GameplayCollisionLayer`; paint visual cars, cones, office props, trash, loading docks, and garage dressing under `ArtRoot` later while preserving the collision cells until QA replaces them intentionally.
- Required objectives, clues, collectibles, gates, scent trails, and exits are represented by Area2D placeholders with interaction radii/debug labels. Non-interactable enemy/heat markers should remain documented as encounter markers, not player-facing E targets.
- Start areas need extra physical clearance, not just grid reachability. Keep the player spawn centered in at least a 3x3 clear floor patch, keep the first exit into the next zone at least 2 cells wide, and verify real movement input before relying on teleported smoke checks.
- Required routes need physical passage clearance, not just connected floor cells. Main-route passages should validate at 3+ open cells, the south return/exit approach should stay comfortably wider than the iso player body, and future blockouts should keep any brief doorway/choke readable and physically testable. The current iso blockout player instance is locally scaled to 0.86 visual size with a 24x24 collision body; do not apply that shrink to non-iso missions.
- Runtime gameplay systems should be spawned/configured from mission markers or definition data into `GameplayRoot/RuntimeSystems`, not painted directly into art layers. Keep guards/cameras/light-zones/alarm-zones/encounter-triggers/route-access/transition stubs deterministic and validated.
- `ArtRoot` remains paint-only. Even when final Monogon art is added, keep detection/gameplay collisions in gameplay/runtime layers until an explicit gameplay replacement has been QA-validated.
- When painting final art, preserve the marker cells for required objectives, clues, collectibles, gates, and exit until QA verifies the painted scene still guides the player.
- Before switching story flow, run `MissionBlockoutValidator` and a manual playthrough of `TacoBellIsoBlockout.tscn`.

## Future Conversion Steps

1. Create a `MissionDefinition` from Mission Bible + current `GameState` ids.
2. Duplicate `IsoMissionTemplate.tscn` into `scenes/missions_iso/`.
3. Assign the definition to the root `IsoMissionBase.gd`.
4. Run validator.
5. Iterate until gameplay path works with placeholder tiles.
6. Only after gameplay is stable, paint final Monogon art under `ArtRoot`.
