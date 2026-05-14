# Camera movement regression audit

## Owner

- **`MissionSecurityCamera.gd`**: `_process` applies sweep using **`_base_rotation`** captured in `_ready`.

## Regression

- **`Phase0KCameraSpawner`**: **`add_child` before `global_position`**. `_ready` could run with **wrong** world transform, freezing sweep around an incorrect basis while the node was later moved.

## Fix

- Parent **then** set **`global_position`**, then **`call_deferred("refresh_sweep_basis_from_world")`**.
- **`MissionSecurityCamera`**: deferred **`refresh_sweep_basis_from_world`** replaces immediate `_base_rotation = global_rotation` in `_ready`.
- **`IsoMissionBase._spawn_security_camera`**: deferred refresh after `add_child` for consistency.

See `phase0md6_01_fix4_camera_movement_audit.json`.
