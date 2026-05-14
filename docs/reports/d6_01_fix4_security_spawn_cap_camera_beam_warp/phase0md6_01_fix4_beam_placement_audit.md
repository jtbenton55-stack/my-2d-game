# Beam placement / visibility audit

## Runtime node

- Alarm id **`garage_entry_beam`** → **`GameplayRoot/RuntimeSystems/AlarmZones/AlarmZone_garage_entry_beam`** (naming via `_node_name`).

## Visibility gap

- **`Line2D`** child of **`Area2D`** could sit under tile layers / low z; FIX4 adds **world-space** line under **`GameplayRoot/RuntimeSystems/DebugLabels`** (or `GameplayRoot` fallback) with high **`z_index`**.

## Route relationship (design only this pass)

- **Normal route:** crosses beam on approach to keypad.
- **Louis / Bentley bypass (future):** exits should land **behind** the beam toward the objective.

See `phase0md6_01_fix4_beam_placement_audit.json`.
