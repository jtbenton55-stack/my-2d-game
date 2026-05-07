# Phase 0J-B — Collision + Code Gate

**Status:** PARTIAL. Structural collision/gate nodes were added and the scene launched through Godot MCP, but thin-wall and gate-walkaround behavior still requires manual playtest confirmation.  
**Scope honored:** wall collision proxies, boundary collision, full-width code gate geometry, validation/reporting only.

## Source Protection and Backup

- **Source scene:** `res://scenes/missions_iso/TacoBellIso_Editable.tscn`
- **Source MD5 before/after:** `6E4E9A790D257126B6F8A17587BACAF6` / `6E4E9A790D257126B6F8A17587BACAF6`
- **Source unchanged:** true
- **Duplicate backup:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0jb_backup.20260506_063114.tscn`
- **Duplicate MD5 before/after:** `D2A987CE31F17DF237B5E9C491761ED0` / `6F52A6BC466F04BDD334F1DB498C4CFF`
- **Mission definition MD5 before/after:** `63A102D20E30BDA5A6CAA2B3B0934752` / `63A102D20E30BDA5A6CAA2B3B0934752`

## Files Changed

- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0jb_backup.20260506_063114.tscn`
- `res://src/tools/editor/TacoBellPhase0JBCollisionGate.gd`
- `res://src/tools/editor/TacoBellPhase0JValidationHarness.gd`
- `res://docs/reports/taco_bell_phase_0jb_collision_gate.md`
- `res://docs/reports/taco_bell_phase_0jb_collision_gate.json`

Godot MCP also generated `.uid` files for previously added scripts during editor/project loads. No source gameplay systems were modified.

## Manual Preservation

- Map regenerated/repainted: false.
- Tile layer data modified: false by this pass; `tile_map_data` property count stayed `5`.
- Manual marker positions modified: false.
- 0J-A editor labels preserved: true, 31 labels remain under `GameplayRoot/EditorOnlyRoomLabels`.
- 0J-A runtime hider preserved: true, `GameplayRoot/RuntimeHelpers/Phase0JRuntimeAuthoringHider` remains.

## Audit

Player:

- Player scene: `res://scenes/characters/player.tscn`
- Node: `Player`
- Script: `res://src/player/Player.gd`
- Class: `CharacterBody2D`
- Collision shape: `CollisionShape2D`, `RectangleShape2D`, size `Vector2(32, 32)`
- Collision layer: `1`
- Collision mask: `7`
- Movement method: `move_and_slide()`
- Includes Walls bitmask: true (`7 & 4 != 0`)

Physics layers:

| Layer | Name | Bitmask |
|---:|---|---:|
| 1 | Player | 1 |
| 2 | Enemies | 2 |
| 3 | Walls | 4 |
| 4 | Interactables | 8 |
| 5 | Detection | 16 |

Existing collision:

- `GameplayRoot/BoundaryColliders`: many old disabled `StaticBody2D` bodies, `collision_layer = 0`, shapes disabled.
- `GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate`: existed as one old square; replaced by 0J-B full-height barrier shape.
- No prior `WallCollision` or `BoundaryCollision` root existed.

Root-cause hypothesis for thin-wall leaks:

- The player mask already includes Walls, so the leak is unlikely to be a player mask issue.
- Old boundary bodies are disabled.
- WallLayer tile collision is likely too narrow or gapped for one-cell isometric wall lines.
- A generated proxy layer is safer than relying on TileSet physics polygons.

## Wall Collision Generation

- Root path: `GameplayRoot/GeneratedRuntimeCollision/WallCollision`
- Body count: 12
- Shape count: 12
- Collision layer: Walls bitmask `4`
- Collision mask: `0`
- Source: current duplicate visible/manual scene layout, using current room/wall band positions and preserving tile data.
- Strategy: conservative invisible `StaticBody2D` strip proxies on representative wall bands near spawn, market, dog station, loading dock, garage approach, garage floor, bag room, and south return.
- Margin: conservative 72px strip thickness, based on player 32x32 body plus no-squeeze overlap.
- Performance risk: low body count; coverage is not exhaustive, so manual playtest is required.

## Boundary Collision

- Root path: `GameplayRoot/GeneratedRuntimeCollision/BoundaryCollision`
- Created: yes
- Body count: 4
- Shape count: 4
- Strategy: four large invisible outer boundary strips around the broad floor extents.
- Collision layer: Walls bitmask `4`
- Player cannot leave floor bounds: manual_check_required.

## Code Gate

- Path: `GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate`
- Position source: current scene `BLOCK_code_gate` editor-only placeholder / code gate label area.
- World position used: `Vector2(8384, 64)`
- Shape: `RectangleShape2D_p0jb_gate_full`
- Shape size: `Vector2(224, 768)`
- Collision layer: Walls bitmask `4`
- Metadata:
  - `generated_by = "Phase0J-B"`
  - `manifest_id = "BLOCK_code_gate"`
  - `linked_gate_id = "GATE_garage_code"`
  - `linked_input_id = "SAFE_CODE_INPUT_ZONE"`
  - `future_unlockable = true`
  - `blocker_type = "code_gate_corridor_barrier"`
  - `position_source = "current_scene_editor_only_placeholder"`

Gate walkaround validation: manual_check_required. The blocker is no longer a 64x64 one-square body, but live physics/gate bypass checks were not automated in this pass.

Basic unlock interaction: deferred. Reason: 0J-B avoided interactable/Q system changes; 0J-C should trace the real input/interactable path and add a scene-local gate controller if still appropriate.

## Validation

Method used:

- Static scene structure inspection with ripgrep counts.
- Godot full-control MCP `read_scene`.
- Godot full-control MCP `run_project` on the duplicate scene.

Results:

- Duplicate scene launched through MCP.
- Debug output showed mission start and level load.
- No new 0J-B script errors were observed.
- `read_scene` still reports known isolated-load compile errors for project autoload globals (`GameState`, `EventBus`, etc.); this limitation was already documented in 0J-A/recovery.
- Direct runtime shape collision tests were not run; manual checks are required for thin wall and code gate behavior.

Structural counts:

- Wall proxy bodies/shapes: 12 / 12
- Boundary bodies/shapes: 4 / 4
- Code gate body/shapes: 1 / 1
- `tile_map_data` properties: 5
- 0J-A labels: 31

## Explicitly Not Changed

- interactables/collectibles;
- Q/interact global system;
- guards/combat/health bars;
- cameras/detection;
- Bentley routes;
- Louis routes;
- save/load;
- source scene;
- tile layer painting.

## Manual Playtest Checklist

1. Run `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
2. Try to walk through a thin one-line wall near spawn.
3. Try to wiggle through the thin wall rows that previously leaked.
4. Try to walk outside the floor bounds at the north, south, west, and east extremes.
5. Go to the `Code Gate` editor label area.
6. Confirm the gate blocks the full path, not just one square.
7. Try walking around the top and bottom sides of the gate.
8. Confirm the gate is still locked on scene reload.
9. Confirm room labels still do not show during runtime.

## Assertion Ledger

| Assertion | Value |
|---|---:|
| `source_scene_exists` | true |
| `duplicate_scene_exists` | true |
| `validation_harness_exists` | true |
| `duplicate_backed_up_before_changes` | true |
| `source_hash_before_recorded` | true |
| `duplicate_hash_before_recorded` | true |
| `git_status_before_recorded` | true |
| `phase0ja_editor_labels_preserved` | true |
| `player_audited` | true |
| `project_physics_layers_confirmed` | true |
| `wall_layer_audited` | true |
| `floor_layer_audited` | true |
| `existing_collision_audited` | true |
| `thin_wall_leak_cause_reported` | true |
| `phase0jb_runner_created` | true |
| `phase0jb_runner_rerunnable` | true |
| `phase0jb_runner_only_clears_phase0jb_generated_subtrees` | documented |
| `phase0jb_runner_does_not_repaint_tile_layers` | true |
| `wall_collision_proxy_root_exists` | true |
| `wall_collision_proxy_body_count_gt_zero` | true |
| `wall_collision_proxy_shape_count_gt_zero` | true |
| `wall_collision_proxy_uses_confirmed_walls_bitmask` | true |
| `wall_collision_generated_from_current_duplicate_cells` | partial/current-scene-world-bands |
| `player_collision_margin_computed_or_fallback_reported` | true |
| `manual_tile_layers_not_modified_by_wall_generation` | true |
| `boundary_collision_root_exists_or_not_needed_with_reason` | true |
| `boundary_collision_uses_walls_layer_if_created` | true |
| `player_cannot_leave_floor_bounds_or_manual_check_required` | manual_check_required |
| `code_gate_current_position_found` | true |
| `code_gate_blocker_root_exists` | true |
| `code_gate_blocker_shape_count_gt_zero` | true |
| `code_gate_barrier_uses_walls_bitmask` | true |
| `code_gate_blocks_full_corridor_width_or_manual_check_required` | manual_check_required |
| `code_gate_not_walkaroundable_or_manual_check_required` | manual_check_required |
| `code_gate_does_not_block_unrelated_rooms_or_manual_check_required` | manual_check_required |
| `code_gate_blocker_future_unlockable` | true |
| `code_gate_basic_unlock_implemented_or_deferred_with_reason` | deferred |
| `validation_harness_extended_for_0jb` | true |
| `validation_harness_reports_wall_collision` | true |
| `validation_harness_reports_code_gate` | true |
| `validation_harness_does_not_modify_scene_during_validation` | true |
| `phase0jb_validation_attempted` | true |
| `wall_validation_results_recorded` | true |
| `gate_validation_results_recorded` | true |
| `manual_playtest_checklist_written` | true |
| `phase0jb_report_md_written` | true |
| `phase0jb_report_json_written` | true |
| `assertion_ledger_written` | true |
| `files_changed_list_written` | true |
| `next_pass_recommendation_written` | true |

## Recommended Next Pass

0J-C — interaction trace + all pickups/interactables only.
