# Packet 2B-4A Follow-up — LockedInteractionNode Dev Scene Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Agent:** Cursor (Auto)

## Goal

Add a dev-only `LockedInteractionNode` sample to `MechanicAuthoringTestRoom` for manual validation alongside existing `TriggerZone` examples, and re-check Godot MCP `validate_script` stale-cache behavior.

## Verdict

**PASS** — Dev locked gate works with existing `UnlockTrigger`; visual/collision toggles and mission flags verified via MCP runtime script. **63/63** GdUnit tests pass. LSP clean. MainMenu smoke OK.

## Files Added / Modified

| File | Action |
|------|--------|
| `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` | **Modified** — `Locks/DevLockedGate` + targets |
| `src/missions/iso/dev/MechanicAuthoringTestRoomController.gd` | **Modified** — `_configure_locks()`, status flags |
| `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md` | **Modified** — one-line dev room note |
| `reports/ai/2026-05-19_packet_2b4a_locked_interaction_node_dev_scene_report.md` | **Added** (this file) |

**Not modified:** `project.godot`, autoloads, production scenes, `LockedInteractionNode.gd`, Taco, Phase0J.

## Implementation Summary

### Scene (`Locks/DevLockedGate`)

- `LockedInteractionNode` at `(0, 140)` with interaction `CollisionShape2D`
- **GateVisual** (`ColorRect`) — hides on unlock via `target_visual_path`
- **GateBlocker** (`CollisionShape2D`) — disables on unlock via `target_collision_path`
- Hint label: `F: Locked gate (needs C first)`

### Controller

- `_configure_locks()` configures `DevLockedGate` at runtime:
  - Requires `dev_unlock_flag` (locked message: `Gate needs dev_unlock_flag`)
  - `unlocked_flag` + success effect: `dev_locked_gate_open`
  - `one_shot`, `open_on_success`, not stay-available after unlock
- Reuses existing **UnlockTrigger (C)** — no duplicate unlock source
- Status label adds `dev_locked_gate_open`
- UnlockTrigger hint updated to mention gate

### Manual test flow

1. Move to gate **F** → press **E** without flag → `requirements_failed`, gate stays locked, visual/blocker unchanged
2. Move to trigger **C** → press **E** → sets `dev_unlock_flag`
3. Return to gate **F** → press **E** → unlock succeeds, `dev_locked_gate_open=true`, visual hidden, blocker disabled

## Tests / Checks Run

| Check | Result |
|-------|--------|
| Godot LSP (`LockedInteractionNode.gd`, controller) | **Clean** |
| GdUnit4 `tests/mission_authoring/` | **63/63 PASSED** |
| MCP `validate_script` controller | **Valid** |
| MCP `validate_script` `LockedInteractionNode.gd` | **Still stale** (see below) |
| MCP dev room playtest | **PASS** — see runtime output |
| MainMenu smoke | **OK** |

### MCP dev room runtime validation

```
before_unlock_ok=false gate_unlocked=requirements_failed
after_unlock_ok=true unlocked=true flag=true visual=false blocker_disabled=true
```

## MCP Stale Cache Status

After `reload_project`:

| Script | MCP `validate_script` | LSP | GdUnit |
|--------|----------------------|-----|--------|
| `MechanicAuthoringTestRoomController.gd` | **Valid** | Clean | Pass |
| `LockedInteractionNode.gd` | **Parse error (stale)** | Clean | Pass (10 tests) |

**Conclusion:** MCP editor `validate_script` for `LockedInteractionNode.gd` remains stale/unreliable; **LSP + GdUnit + runtime playtest are authoritative**. No code change required — script compiles and runs correctly.

## Godot DAP

**Not needed** — no non-obvious failures.

## Safety Confirmation

- Dev-only scene/controller changes
- No production wiring, autoloads, or `project.godot` edits
- Existing trigger examples unchanged in behavior

## Known Limitations

- Gate/blocker share the same `RectangleShape2D` subresource in the `.tscn` (acceptable for dev room)
- `MechanicAreaBase` default `collision_shape_path` is `CollisionShape2D`; interaction shape is named `InteractionShape` (shape sizing helper may not apply — not required for this test)
- MCP `validate_script` still reports false negative on `LockedInteractionNode.gd`

## Recommended Next Step

Implement **SearchZone** (Packet 2B-4B) or add a second dev-room lock example (e.g. card-gated terminal using `selected_card` requirement).
