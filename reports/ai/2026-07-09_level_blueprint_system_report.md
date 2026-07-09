# 2026-07-09 Level Blueprint System (Dev-Only Design Overlay)

Agent: Cursor (Fable 5). Grouped-milestone packet implementing Jake's requested dev-only 2D
level-design layer plus the approved improvements (coverage audit, dock prefill, dependency
arrows, legend, grid, reference library). PNG rendering was explicitly deferred by Jake.

## What Changed

### New

- `src/tools/authoring/LevelBlueprintSpec.gd` - shared spec parsing/validation/coverage
  helper (RefCounted, static functions only). Owns `CATEGORY_BY_TYPE` covering all 55
  Mission Dock mechanic types, region kinds mapped 1:1 to Mission Paint Dock layers, and
  the coverage diff (placed / missing / mismatched by `suggested_id` + script file match).
- `src/tools/authoring/AuthoringBlueprintLayer.gd` - `@tool` Node2D overlay renderer.
  Draws canvas frame, grid, region fills/outlines (rect/polyline/circle), category-colored
  mechanic slot markers with type + slot id labels, dashed dependency arrows, and an
  auto-generated legend. Inspector toggles: `overlay_visible`, `opacity`, `draw_on_top`,
  `show_*`, `reload_blueprint`. Draw-only; never mutates the scene.
  Player safety: frees itself in `_ready()` whenever `Engine.is_editor_hint()` is false.
- `docs/blueprints/starter_room.blueprint.json` - minimal reference blueprint (core
  search -> reward -> route unlock -> extraction chain).
- `docs/blueprints/laundromat_heist.blueprint.json` - full-feature reference blueprint
  (3 rooms, lock-and-key chain, social stealth, Bentley route, security authors,
  collectible, music trigger).
- `docs/blueprints/*.build_guide.md` - generated build guides (dependency-ordered steps,
  paint-layer table, completion checklist).
- `src/tools/editor/level_blueprint/generate_blueprint_guide.py` - deterministic
  spec -> Markdown guide generator (`--all` or single spec).
- `src/tools/editor/level_blueprint/level_blueprint_validator.py` - static validator:
  required files, layer dev-only guarantees, Mission Dock token checks, MECHANIC_TYPES <->
  CATEGORY_BY_TYPE parity, and full schema validation of every spec + guide freshness.
  Writes `docs/reports/level_blueprint/level_blueprint_validator_run.json`.
- `tests/mission_authoring/LevelBlueprintLayerTest.gd` - 8 GdUnit tests.
- `docs/How to Use/Level Blueprints.md` - workflow guide, spec reference, AI generation
  contract, troubleshooting.
- `scenes/dev/mission_authoring/LevelBlueprintProofRoom.tscn` - minimal proof scene with
  the layer pointed at the starter blueprint.

### Modified

- `addons/mission_dock/MissionDock.gd`:
  - New palette section "Place From Blueprint": Refresh Blueprint Slots (reads the
    AuthoringBlueprintLayer in the open scene, lists slots as `[PLACED|MISSING|MISMATCH]`,
    missing-first) and Prefill From Selected Slot (copies mechanic type, suggested id,
    position, zone size into the existing palette fields; placement still goes through the
    normal Dry Run / Place actions and UndoRedo).
  - Assist Browser audit now emits `blueprint_coverage` (Info), `blueprint_slot_missing`
    (Warning), `blueprint_slot_type_mismatch` (Warning), `blueprint_spec_error` (Error)
    when a blueprint layer exists in the scene. Scenes without a layer are unaffected.
- `src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd`: new exported
  `hide_authoring_blueprint_layers` (default true) strips any node named
  `AuthoringBlueprintLayer` at runtime as a redundant second guard.
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`, `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`:
  implementation update entries.
- `docs/things to complete.md`: blueprint-layer todo checked off.

## Validation

- `python src/tools/editor/level_blueprint/level_blueprint_validator.py`: PASS
  (2 specs checked, 55 mechanic types in parity).
- `python src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py`:
  PASS (Mission Dock changes did not break Phase 2K contract).
- `addons/gdUnit4/runtest.cmd -a res://tests/mission_authoring/LevelBlueprintLayerTest.gd`:
  PASS 8/8 (`reports/report_86`) - spec load/validate, missing-spec error, type parity,
  runtime self-destruct, Phase0J strip, coverage placed/missing/mismatched, slot helpers +
  parent routing, dock integration tokens.
- `addons/gdUnit4/runtest.cmd -a res://tests/mission_authoring/Phase17LevelBuilderReadinessTest.gd`:
  PASS 5/5 (`reports/report_87`) - no regression from Mission Dock audit changes.
- Full `addons/gdUnit4/runtest.cmd -a res://tests/mission_authoring` regression:
  PASS 349/349 across 45 suites, 0 errors/failures (`reports/report_88`).
- Headless smoke `LevelBlueprintProofRoom.tscn`: loads clean, layer script loads, no errors,
  exit 0 (layer self-frees at runtime as designed).
- Godot MCP Pro editor proof: `validate_script` PASS for `AuthoringBlueprintLayer.gd`,
  `LevelBlueprintSpec.gd`, `MissionDock.gd`; proof scene opened in the editor and a
  screenshot confirmed the starter blueprint rendering (grid, floor region, labeled slots,
  dependency arrows, collision barrier).
- LSP diagnostics: clean on all three new/modified GDScripts (including
  `Phase0JRuntimeAuthoringHider.gd`; the editor MCP `validate_script` "Parse error" on the
  hider also fired for untouched control scripts, i.e. pre-existing editor-cache noise, and
  headless compile + GdUnit preload of the same script PASS).

## Known Noise / Risks

- The live Godot MCP Pro connection dropped during a second `reload_plugin` call and did
  not auto-reconnect within this session, so the in-editor "Place From Blueprint" button
  flow still needs one manual click-through by Jake (open any mission with the layer,
  Refresh Blueprint Slots, Prefill, Place). All underlying code paths are covered by
  GdUnit + editor script-method verification before the drop.
- After pulling these changes into an already-open editor, the Mission Dock plugin needs a
  disable/enable (or editor restart) to show the new palette section.
- Blueprint coordinates are plain world-space; iso-projection drawing mode is a possible
  future enhancement if tracing against diamond tiles feels misaligned.
- PNG rendering of specs deferred per Jake.

## How To Use

See `docs/How to Use/Level Blueprints.md`. Quick start: open
`scenes/dev/mission_authoring/LevelBlueprintProofRoom.tscn` to see the starter blueprint,
or add an `AuthoringBlueprintLayer` node to any mission and point it at a spec under
`docs/blueprints/`.

## Grouped-Milestone Mode Statement

This packet stayed in grouped-milestone mode: one milestone delivered runtime-safe overlay
code, a shared data/schema class, Mission Dock authoring integration, static validator,
GdUnit tests, reference content, proof scene, docs, and roadmap/blueprint updates, with no
rewrites of existing systems and clear rollback boundaries (all new files plus three small
additive edits).
