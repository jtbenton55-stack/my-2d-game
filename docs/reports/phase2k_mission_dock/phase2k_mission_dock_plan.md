# Phase 2K Mission Dock Plan

## Goal

Deliver one combined editor plugin called **Mission Dock** with two clearly separated tabs:

1. **Mission Authoring Palette** — place approved reusable mechanic nodes with safe defaults.
2. **Mission Assist Browser** — read-only scene audit for duplicate IDs, broken links, missing required fields/resources, unsafe effects, and quick node selection.

Phase 2K is an editor UX entry point over the existing mission-authoring foundation. It does **not** create a new mission format, runtime manager, mission manager, save format, or alternate gameplay system.

## Combined Mission Dock decision

Phase 2K is intentionally **one dock**, not two separate docks. Both sections live in `addons/mission_dock/MissionDock.gd` under a `TabContainer`.

## Source rules

Blueprint layering remains:

`Placed mechanic node -> RequirementSet checks -> EffectSet applies -> thin bridges/adapters -> existing authoritative managers`

The dock must not bypass this layering.

## Included sections

### Mission Authoring Palette

- Mechanic type dropdown for all approved Phase 2K mechanic classes
- Mission ID override, mechanic ID base, display name
- Parent target path + Use Selected Node As Parent + Ensure MissionMechanics Parent
- Position/shape controls
- Interaction mode, prompt text, one-shot
- Optional starter RequirementSet (in-memory only)
- Optional starter success EffectSet (in-memory only)
- Dry Run Placement (non-mutating)
- Last Placement Summary panel (read-only requirement/effect verification after dry run or placement)
- Parent resolution: blank `Parent Target Path` → `MissionMechanics` only; editor selection never used implicitly
- Place At Typed Position (UndoRedo)
- Place With Mouse (UndoRedo, Esc/RMB cancel/disarm)
- SideObjectiveNode refuses placement without explicit objective_id

### Mission Assist Browser

- Refresh Scene Audit (read-only)
- Severity and issue-type filters
- Issue list + details panel
- Select Node / Copy Node Path / Copy Issue Summary / Copy Full Audit Summary
- No auto-fix, no scene mutation, no resource saves

## Supported mechanic classes

- SearchZone
- RewardNode
- LockedInteractionNode
- RouteUnlockNode
- InteractiveContainer
- ExtractionZone
- SideObjectiveNode
- TriggerZone

## Authoring Palette UI contract

See task spec. All scene mutations use `EditorUndoRedoManager`. Owner is set recursively so placed nodes save in the edited scene. RequirementSet/EffectSet are in-memory resources assigned to placed nodes in v1; no `.tres` files.

## Assist Browser audit contract

Scan edited scene recursively for supported mechanic scripts/classes. Also honor `mission_mechanic` group when present. Emit normalized issue dictionaries with severity, code, message, node_path, node_name, mechanic_id, details.

Checks include duplicate IDs/flags, missing required fields, broken NodePaths, invalid collision shapes, unknown requirement fact types, empty effect keys, and unsafe extraction settings.

## Safety boundaries

Forbidden parent targets include generated runtime collision layers and protected Phase0J/Phase0K runtime containers (referenced in safety text only; runtime scripts are not edited).

Do not edit:

- IsoMissionBase
- Phase0J/Phase0K runtime scripts
- save/load systems
- autoloads
- production Taco gameplay behavior

Do not place under generated runtime collision nodes.

## Implementation packets

1. Plugin skeleton (`plugin.cfg`, `MissionDockPlugin.gd`, `MissionDock.gd` UI shell)
2. Read-only Mission Assist Browser audit
3. Authoring Palette placement for SearchZone and RewardNode
4. Remaining supported mechanic placements with safe defaults
5. Static validator + docs/report updates
6. Manual Godot validation in `MechanicAuthoringTestRoom.tscn`

## Validation plan

- `git diff --check`
- Godot LSP diagnostics on plugin/dock scripts
- `python src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py`
- GdUnit4 `tests/mission_authoring` if available
- Manual editor QA: dock loads, audit refresh is non-mutating, SearchZone/RewardNode placement + UndoRedo, audit detects placed nodes and duplicate IDs

## Deferred items

- Auto-fix audit issues (explicitly out of scope for v1)
- External `.tres` RequirementSet/EffectSet authoring files
- Sequence tooling, inventory/heist kit, card modifiers, stealth/AI/NPC systems
- Mechanic gizmos (roadmap item still deferred)

## Plugin enablement

`project.godot` includes `res://addons/mission_dock/plugin.cfg` in `[editor_plugins]` enabled list so Mission Dock loads automatically for manual QA.

## Completion criteria

- One combined Mission Dock plugin exists with both tabs
- SearchZone and RewardNode placement works with UndoRedo
- All approved mechanic classes are selectable with safe defaults
- Assist Browser audits without mutation
- Static validator passes
- Phase 2K plan + AI report exist
- Roadmap/blueprint reflect Phase 2K implementation status as manual-QA pending
