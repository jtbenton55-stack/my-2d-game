# Camera / cone response audit

**Script**  
- Primary gameplay path: `MissionSecurityCamera.gd` feeding `MissionAlertController` and `MissionSecurityEventAdapter`.

**Canonical Taco scene**  
- Not edited. Count of cone nodes left to editor inspection; **runtime** fix targets all instances using `MissionSecurityCamera` once parented under `EntityRoot/Cameras`.

**Inactive cones (prior)**  
- Cameras parented under `Phase0KRuntime/Cameras` could miss `EntityRoot` alert wiring and had strict LOS blocked by walls.

**Unification**  
- Single script path; spawner parent fix + LOS default + per-source cooldown in `MissionAlertController` for reinforcements.
