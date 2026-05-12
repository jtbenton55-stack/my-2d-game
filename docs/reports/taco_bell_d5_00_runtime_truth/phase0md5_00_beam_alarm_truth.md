# 0M-D5-00 — Phase 4: Beam / alarm truth

## Runtime (GRB)

- `IsoMissionBase.get_runtime_debug_summary()` on mission root (`/root/TacoBellIso_Editable`) after Taco load:
  - `garage_beam_armed`: **true**
  - `garage_beam_triggered`: **false**
  - `marker_to_runtime_counts.alarm_zones`: **1**
  - Spawned id includes `alarm_zones:garage_entry_beam`
- Live node: `/root/TacoBellIso_Editable/GameplayRoot/RuntimeSystems/AlarmZones/AlarmZone_garage_entry_beam` (`Area2D`), `global_position` ≈ `(-2076, 386)` (runtime placement under `RuntimeSystems`).

## Beam crossing / one-shot (automation)

- **NOT_TESTED** as true player walk-through: GRB synthetic movement did not prove overlap; tier-2 `global_position` writes on Player appeared to corrupt position readback `(0,0)` in a later probe — **do not treat as gameplay bug**; treat as **automation risk**.
- `get_overlapping_bodies()` on `AlarmZone_garage_entry_beam` returned `[]` while Player spawn was valid at `(-2558,185)` — player not in beam AABB.

## Static code (authoritative for one-shot design)

- `_spawn_alarm_zone`: `collision_layer = 0`, `collision_mask = 1` (detects layer-1 bodies).
- `_on_runtime_alarm_zone_entered`: for `garage_entry_beam`, uses `_is_alarm_zone_one_shot` → sets `_attempt_runtime_state["alarm_triggered:" + alarm_id]` before registering detection; second entry blocked by `_is_runtime_flag_true`.
- `get_runtime_debug_summary` maps `garage_beam_triggered` from that flag.

## Code gate vs beam

- **STATIC_ONLY / PARTIAL_RUNTIME:** `solve_garage_office_code` marker / code gate placeholder positions differ from `garage_entry_beam` alarm zone in debug `position_resolutions` (distinct IDs and coordinates in summary payload).

## Conclusion

- **One-shot logic is implemented in code** (STATIC_ONLY + runtime summary fields present).
- **Per-frame spam:** prevented by guard flag in handler (STATIC_ONLY).
- **Crossing / re-arm at runtime:** **MANUAL_REVIEW_REQUIRED** (walk into beam, relaunch mission, re-cross).
