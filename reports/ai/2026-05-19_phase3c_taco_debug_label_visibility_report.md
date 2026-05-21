# Phase 3C — Taco Runtime Debug-Label Visibility Policy Report

**Date:** 2026-05-19  
**Branch:** `new-feature-roadmap-branch`  
**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Packet type:** Runtime debug-label visibility policy (no gameplay / completion / map paint changes)

## Goal

Reduce Taco runtime debug-label clutter (especially `GeneratedRuntimeMarkerLabels`) while preserving Phase0J/Phase0K gameplay, plug-and-play pilot visuals, generated interactables, and recoverable authoring visibility.

## Files changed

| File | Change |
|------|--------|
| `src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd` | Extended with opt-in exports for generated runtime labels and security author labels |
| `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` | Taco opts in: `hide_generated_runtime_marker_labels = true` |
| `tests/mission_authoring/Phase0JRuntimeAuthoringHiderTest.gd` | **Added** — 5 focused GdUnit tests |
| `reports/ai/2026-05-19_phase3c_taco_debug_label_visibility_report.md` | This report |
| `reports/ai/phase3c_taco_debug_label_visibility_screenshots/*` | Before/after screenshots |

**Not modified:** `project.godot`, autoloads, `IsoMissionBase`, Phase0J/Phase0K interaction/completion scripts, pilot requirements/effects/flags, collision/tile paint, canonical interactable logic.

## Files inspected

| Area | Paths |
|------|--------|
| Phase 3A/3B | `reports/ai/2026-05-19_phase3a_*.md`, `reports/ai/2026-05-19_phase3b_*.md` |
| Scene | `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` |
| Hider / labels | `Phase0JRuntimeAuthoringHider.gd`, `Phase0JRuntimeMarkerLabel.gd`, `Phase0JMarkerDebugInteractable.gd` |
| Ownership | `IsoMissionBase.gd` (`_find_runtime_debug_marker`), `Phase0KBBoundsCleanup.gd` |
| Bridges | `Phase0JInteractionBridge.gd`, `MissionInteractionBridge.gd` (read-only) |

## Git / branch baseline

- **Branch:** `new-feature-roadmap-branch`
- **Pre-existing modified:** `TacoBellIso_Editable_RedesignTest.tscn` (Phase 3B pilot visuals)
- **Phase 3C adds:** `Phase0JRuntimeAuthoringHider.gd`, Taco hider exports, new test file, report/screenshots

## Label ownership audit

| Question | Finding |
|----------|---------|
| Where is `GeneratedRuntimeMarkerLabels`? | Baked in Taco scene under `GameplayRoot` (~188 children). Metadata: `Phase0J-C2`, `label_count = 188`. |
| Child type | `Node2D` per marker with `Phase0JRuntimeMarkerLabel.gd` — builds gray `SCENE_MARKER` panels (`Label`, `ColorRect`, `Polygon2D` icon) at `z_index = 4090`. |
| Populated at runtime? | Scene-baked; `IsoMissionBase` references this tree for `_find_runtime_debug_marker()` lookup only. |
| Interaction impact? | **Visual only.** Gameplay interactables live under `GeneratedRuntimeInteractables` (separate `Area2D` nodes). Hiding label root does not remove interactables. |
| Existing hider | `Phase0JRuntimeAuthoringHider` hides `MarkerRoot` subtrees and layout layers via `target_paths`; did **not** include `GeneratedRuntimeMarkerLabels`. |
| Security author labels | Separate under `GameplayRoot/SecurityAuthoringRoot` — child `AuthorLabel` nodes on beam/spawn/camera authors. Not part of `GeneratedRuntimeMarkerLabels`. |
| Player-facing must stay | `GeneratedRuntimeInteractables` polygons, `PlugAndPlayPilot` visuals/hints, HUD/UI, bridge prompts. |
| Debug recovery | Set `hide_generated_runtime_marker_labels = false` on Taco hider (or remove opt-in) to restore labels in play. Nodes are not deleted. |

## Implementation summary

Extended `Phase0JRuntimeAuthoringHider.gd` with backward-compatible exports:

```gdscript
@export var hide_generated_runtime_marker_labels: bool = false
@export var hide_security_author_labels: bool = false
@export var generated_runtime_marker_labels_path: NodePath = NodePath("../../GeneratedRuntimeMarkerLabels")
@export var security_authoring_root_path: NodePath = NodePath("../../SecurityAuthoringRoot")
```

At runtime (non-editor), when opt-in:

- Sets `visible = false` on the configured label root (and optional `AuthorLabel` descendants).
- Sets metadata `phase_0ja_hidden_at_runtime` for traceability.
- Does **not** delete nodes or alter interaction groups.

**Taco scene configuration** on `GameplayRoot/RuntimeHelpers/Phase0JRuntimeAuthoringHider`:

- `hide_generated_runtime_marker_labels = true`
- `generated_runtime_marker_labels_path = NodePath("../../GeneratedRuntimeMarkerLabels")`
- `hide_security_author_labels` left **false** (deferred)

## Exact visibility policy / configuration

| Target | Taco runtime | Default (other scenes) |
|--------|--------------|------------------------|
| `GeneratedRuntimeMarkerLabels` | Hidden (`visible = false`) | Unchanged (export default `false`) |
| `SecurityAuthoringRoot/AuthorLabel` | Visible | Unchanged unless `hide_security_author_labels = true` |
| `MarkerRoot` (via `target_paths`) | Hidden (existing 0J-A behavior) | Per scene config |
| `PlugAndPlayPilot` | Visible | N/A |
| `GeneratedRuntimeInteractables` | Visible | N/A |

## Before/after screenshots

| File | Description |
|------|-------------|
| `reports/ai/phase3c_taco_debug_label_visibility_screenshots/before_spawn_debug_labels.png` | Pre-change spawn (from Phase 3B before capture) |
| `reports/ai/phase3c_taco_debug_label_visibility_screenshots/after_spawn_labels_hidden.png` | Post-change spawn — gray marker panels absent |
| `reports/ai/phase3c_taco_debug_label_visibility_screenshots/after_pilot_lane_labels_hidden.png` | Pilot lane with labels hidden |
| `reports/ai/phase3c_taco_debug_label_visibility_screenshots/after_canonical_interactable_area.png` | Manifest interactable area — polygon icon visible, debug panel hidden |

## Generated runtime label visibility result

| Check | Result |
|-------|--------|
| `GeneratedRuntimeMarkerLabels.visible` at runtime | **false** |
| `phase_0ja_hidden_at_runtime` meta on root | **true** |
| Label child count in scene | **188** (unchanged; not deleted) |
| Spawn readability | Materially improved (no gray `SCENE_MARKER` wall at `z_index=4090`) |

## Security author label decision

**Deferred for Taco runtime.** `hide_security_author_labels` is implemented (hides only nodes named `AuthorLabel` under `SecurityAuthoringRoot`) but **not enabled** on Taco because:

- Security authors spawn runtime systems; full-root hide risk was avoided.
- Author labels may still help hazard orientation during playtests.
- Runtime check: `AMBUSH_security_beam/AuthorLabel` remains **visible** with Taco config.

Recommended **Phase 3D** candidate: enable `hide_security_author_labels = true` on Taco after a focused security playtest pass.

## Pilot gameplay preservation result

| Check | Result |
|-------|--------|
| Pre-reward / pre-route | `requirements_failed` |
| Search → reward → route | `activation_succeeded` → `reward_collected` → `route_unlocked` |
| `PlugAndPlayPilot.visible` | **true** |
| `include_legacy_candidates` | **false** |
| `delivery_bag_collected` after pilot chain | **false** |

## Canonical Taco non-regression result

| Check | Result |
|-------|--------|
| `Interactable_OBJ_bag_recovery` | exists |
| `Interactable_CLUE_route_manifest_half` | exists |
| `LouisExitToken` | exists |
| `GeneratedRuntimeInteractables.visible` | **true** |
| Phase0J/Phase0K scripts | not edited |
| Mission completion via pilot | not triggered |

## Tests / checks run

| Check | Result |
|-------|--------|
| GdUnit4 `Phase0JRuntimeAuthoringHiderTest.gd` | **5/5 PASS** |
| GdUnit4 `res://tests/mission_authoring/` (full) | **155/155 PASS** (150 prior + 5 new) |
| Godot LSP (changed `.gd` files) | **clean** |
| Godot MCP — Taco play + validation script | **pass** |
| Godot MCP — MainMenu | loads as `MainMenu` |
| Godot DAP | not needed |
| Kimi K2.6 MCP | not used |

## Godot MCP Pro result

- Reloaded project; opened Taco from disk.
- Runtime: labels hidden, pilot/interactables visible, pilot chain pass.
- Screenshots saved under `phase3c_taco_debug_label_visibility_screenshots/`.
- **Did not call `save_scene`** (disk already has intended Taco hider exports; avoid stale-editor overwrite per Packet 6B/3B caution).

## Safety confirmation

- Only authorized files changed.
- No `project.godot`, autoload, `IsoMissionBase`, Phase0J/Phase0K gameplay script, bridge logic, pilot config, tile paint, or collision edits.
- Debug labels hidden, not deleted.
- Default exports preserve non-Taco behavior.

## Rollback plan

1. On Taco `Phase0JRuntimeAuthoringHider`, set `hide_generated_runtime_marker_labels = false` (or remove the two export lines from scene).
2. Optionally revert `Phase0JRuntimeAuthoringHider.gd` if no other scene needs the exports.
3. Remove `tests/mission_authoring/Phase0JRuntimeAuthoringHiderTest.gd` if reverting script entirely.
4. Re-run `tests/mission_authoring/` and MainMenu smoke.
5. Play Taco — gray runtime marker panels return immediately.

## Known limitations

- Labels are hidden, not removed — editor still shows full tree; play hides via hider.
- Security `AuthorLabel` nodes still visible at runtime on Taco.
- Distant objectives (bag, etc.) still require camera movement; only clutter is reduced.
- `_find_runtime_debug_marker()` can still resolve hidden nodes by path (lookup unchanged).

## Recommended next step

**Phase 3D (optional):** Taco opt-in for `hide_security_author_labels = true` after security/hazard playtest, or spawn-radius label cull if full-tree hide is too broad for future missions.
