# Camera movement fix

- **`Phase0KCameraSpawner`**: `add_child` → set `global_position` → deferred **`refresh_sweep_basis_from_world`**.
- **`MissionSecurityCamera`**: public **`refresh_sweep_basis_from_world`**; `_ready` uses **`call_deferred`**.
- **`IsoMissionBase._spawn_security_camera`**: deferred refresh after parenting.

See `phase0md6_01_fix4_camera_movement_fix.json`.
