# Phase 0J-A — Visual Labels Baseline

**Status:** FAIL / partial, because the live runtime inspection call timed out after the scene launched.  
**Scope honored:** baseline, validation harness, runtime visual hider, editor-only labels. No gameplay fixes.

## Hashes and Backup

- **Duplicate exists:** true
- **Source exists:** true
- **Backup:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0ja_backup.20260506_060658.tscn`
- **Backup MD5:** `E97A7C97AC4645F6DABED353FBC03D4C`
- **Source MD5 before/after:** `6E4E9A790D257126B6F8A17587BACAF6` / `6E4E9A790D257126B6F8A17587BACAF6`
- **Duplicate MD5 before/after:** `E97A7C97AC4645F6DABED353FBC03D4C` / `5570E100635FC83C4AD66E5CD1FE436D`
- **Mission definition MD5 before/after:** `63A102D20E30BDA5A6CAA2B3B0934752` / `63A102D20E30BDA5A6CAA2B3B0934752`

## Manual Baseline Inventory

Tile layer summary:

| Layer | Classification | Runtime treatment |
|---|---|---|
| `GameplayRoot/GameplayFloorLayer` | old generated layer | unchanged |
| `GameplayRoot/GameplayCollisionLayer` | old generated/debug layer | unchanged |
| `GameplayRoot/GameplayMarkersLayer` | old authoring marker layer / blue-circle candidate | hidden at runtime by 0J-A hider |
| `GameplayRoot/LayoutRoot/FloorLayer` | current manual/generator floor layer | untouched |
| `GameplayRoot/LayoutRoot/WallLayer` | current manual/generator wall layer | untouched |
| `GameplayRoot/LayoutRoot/CoverLayer` | brown COVER visual artifact candidate | hidden at runtime by 0J-A hider |
| `GameplayRoot/LayoutRoot/CollisionBarrierLayer` | current barrier authoring layer | untouched |
| `GameplayRoot/LayoutRoot/MarkerTileLayer` | authoring marker layer | still hidden at runtime |

Marker/helper node summary:

- `GameplayRoot/MarkerRoot` and subgroups remain in place.
- Existing Phase 0I hiders remain in place under marker subgroups.
- Existing `GameplayRoot/Phase0IRouteSafeguard` remains unchanged.
- Crashed-attempt Phase 0J helper scripts existed on disk but were not wired into the scene before 0J-A.
- 0J-A added only `GameplayRoot/RuntimeHelpers/Phase0JRuntimeAuthoringHider` and `GameplayRoot/EditorOnlyRoomLabels`.

Artifact candidates:

- Brown COVER runtime artifact: `GameplayRoot/LayoutRoot/CoverLayer`.
- Blue/nonfunctional authoring artifact candidates: `GameplayRoot/GameplayMarkersLayer`, `GameplayRoot/LayoutRoot/MarkerTileLayer`, and `GameplayRoot/MarkerRoot/*` authoring subtrees.
- Real player/interactable/entity nodes were not targeted by the hider.

## Manual Preservation Check

- Full map generator run: false.
- Tile layer repaint: false.
- `tile_map_data` property count before/after: 5 / 5.
- Scene diff was limited to new ext_resources, `RuntimeHelpers`, `Phase0JRuntimeAuthoringHider`, and `EditorOnlyRoomLabels`.
- Manual positions moved: none intentionally.

Do not overwrite later:

- all current `FloorLayer`, `WallLayer`, `CoverLayer`, `CollisionBarrierLayer`, and `MarkerTileLayer` cells;
- all current `MarkerRoot` and `EditorOnlyPlaceholders` positions;
- current manual collectible/route/code/vent marker placements.

## Validation Harness

- **Path:** `res://src/tools/editor/TacoBellPhase0JValidationHarness.gd`
- **Created:** true
- **Scene modifying:** false
- **Modes:** `baseline`, `runtime_visibility`, `labels`, `source_hash`
- **Future stubs:** collision, gate, interactables, combat, cameras, routes are `not_run`.
- **Runtime execution:** not fully verified; live `game_eval` calls timed out after the scene launched.

## Runtime Visual Cleanup

Added scene-local hider:

- **Node:** `GameplayRoot/RuntimeHelpers/Phase0JRuntimeAuthoringHider`
- **Script:** `res://src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd`
- **Behavior:** runtime-only visibility hiding; no tile deletion; no repaint; no collision or gameplay changes.

Hider target paths:

- `GameplayRoot/LayoutRoot/CoverLayer`
- `GameplayRoot/GameplayMarkersLayer`
- `GameplayRoot/LayoutRoot/MarkerTileLayer`
- `GameplayRoot/MarkerRoot/Spawns`
- `GameplayRoot/MarkerRoot/Objectives`
- `GameplayRoot/MarkerRoot/Patrols`
- `GameplayRoot/MarkerRoot/Cameras`
- `GameplayRoot/MarkerRoot/Clues`
- `GameplayRoot/MarkerRoot/Collectibles`
- `GameplayRoot/MarkerRoot/Routes`
- `GameplayRoot/MarkerRoot/Transitions`
- `GameplayRoot/MarkerRoot/Exit`
- `GameplayRoot/MarkerRoot/EditorOnlyPlaceholders`

## Editor Room Labels

- **Parent:** `GameplayRoot/EditorOnlyRoomLabels`
- **Label helper:** `res://src/tools/editor/EditorOnlyRoomLabel.gd`
- **Count:** 31
- **Text color:** dark/black default from helper
- **z_index:** 4096
- **Gameplay groups:** none added
- **Runtime hidden:** intended by helper `_ready`; manual/runtime check required because live inspection timed out.

Labels added:

`Louis Start`, `Optional Market Nook`, `Midnight Market Street`, `North Shop Row`, `Dog Station Alley`, `Trash Alley`, `Loading Dock Lane`, `Delivery Alley Hub`, `Garage Entry Approach`, `Security Kiosk / Control Room`, `Safe Code Input`, `Garage Office / Code Clue Room`, `Code Gate`, `Post-Gate Buffer`, `Louis Service Corridor`, `Louis Return`, `Security Beam`, `Garage Floor`, `Upper Platform`, `Upper Control Alcove`, `Bag Recovery Room`, `South Return Corridor`, `Mission Exit`, `Bentley Route A`, `Bentley Route B`, `Bentley Route C`, `Bentley Route D`, `Bentley Utility Pocket A`, `Bentley Utility Pocket B`, `Bentley Utility Pocket C`, `Bentley Utility Pocket D`.

## Smoke Test

- **Godot full-control MCP used:** yes.
- **Godot version:** 4.6.2.
- **Runtime bridge used:** no; bridge reported not connected.
- **Scene launch:** `run_project` launched `TacoBellIso_Editable_RedesignTest.tscn`.
- **Debug output:** no new Phase 0J-A script errors observed; hider script loaded.
- **Live inspection:** failed; `game_eval` and scene-tree calls timed out.
- **Static scene read:** executed, but Godot isolated `read_scene` reports existing project autoload compile errors for unrelated globals (`GameState`, `EventBus`, etc.), as already seen in recovery.

## Deferred / Not Run

- wall collision;
- code gate blocker/collision;
- code gate interaction;
- interactables and Q/interact;
- guards/combat/health bars;
- cameras/detection;
- Bentley/Louis route mechanics.

## Files Changed

- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0ja_backup.20260506_060658.tscn`
- `res://src/tools/editor/TacoBellPhase0JValidationHarness.gd`
- `res://src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd`
- `res://docs/reports/taco_bell_phase_0ja_visual_labels_baseline.md`
- `res://docs/reports/taco_bell_phase_0ja_visual_labels_baseline.json`

## Assertion Ledger

| Assertion | Value |
|---|---:|
| `duplicate_scene_exists` | true |
| `source_scene_exists` | true |
| `phase0ja_duplicate_backup_created` | true |
| `source_md5_before_recorded` | true |
| `duplicate_md5_before_recorded` | true |
| `tilemap_inventory_completed` | true |
| `marker_node_inventory_completed` | true |
| `runtime_artifact_candidates_inventory_completed` | true |
| `existing_helper_nodes_inventory_completed` | true |
| `no_tile_layers_repainted_during_inventory` | true |
| `manual_preservation_check_completed` | true |
| `manual_positions_not_moved` | true |
| `full_map_generator_not_run` | true |
| `validation_harness_file_created` | true |
| `validation_harness_can_load_duplicate` | false |
| `validation_harness_reports_required_nodes` | true |
| `validation_harness_has_runtime_visibility_check` | true |
| `validation_harness_does_not_modify_scene` | true |
| `cover_artifacts_audited` | true |
| `blue_circle_artifacts_audited` | true |
| `cover_tiles_hidden_at_runtime_or_reported_real` | manual_check_required |
| `nonfunctional_blue_circles_hidden_at_runtime_or_reported_real` | manual_check_required |
| `manual_marker_tiles_not_deleted` | true |
| `manual_tile_layers_not_repainted` | true |
| `runtime_hider_targets_reported` | true |
| `editor_room_labels_parent_exists` | true |
| `editor_room_labels_count >= 25` | true |
| `editor_room_labels_dark_text` | true |
| `editor_room_labels_high_z` | true |
| `editor_room_labels_hidden_at_runtime` | manual_check_required |
| `editor_room_labels_have_owner` | static_scene_saved |
| `editor_room_labels_not_in_gameplay_groups` | true |
| `editor_room_labels_do_not_use_IsoMissionMarker` | true |
| `duplicate_scene_loads` | partial_mcp_launch_no_new_0ja_errors |
| `source_scene_unchanged` | true |
| `validation_harness_can_inspect_duplicate` | false |
| `runtime_visibility_smoke_completed_or_reported_unavailable` | true |
| `phase0ja_report_md_written` | true |
| `phase0ja_report_json_written` | true |
