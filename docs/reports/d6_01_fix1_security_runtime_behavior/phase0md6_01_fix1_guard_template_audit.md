# Guard template audit (FIX1)

**GOOD (large working guard)**  
- Scene: `res://scenes/characters/guard.tscn`  
- Logic: `Guard.gd` extending `EnemyBase.gd` — patrol, vision cone integration, chase/attack, search patterns as already authored.

**BAD / placeholder (small procedural)**  
- Script: `res://src/missions/iso/runtime/Phase0KGuardPatrol.gd` on bare `CharacterBody2D`.  
- Still spawned by **`Phase0KGuardSpawner`** for `MarkerRoot` **GUARD** category markers (ambient/editor pipeline), **not** for wrong-code or camera-driven security response after FIX1.

**Wrong-code**  
- `Phase0KBWrongCodeAttackGuardSpawner` now calls `IsoMissionBase.spawn_attack_guard_near_player("wrong_code_phase0kb")` → **GOOD** scene.

**Camera / alarm**  
- `MissionAlertController` / `IsoMissionBase.spawn_attack_guard_near_player` → **GOOD** scene.

**Stick / freeze**  
- Procedural guard lacked full AI spacing. Security spawns now use real guard + `security_chase_soft` on `EnemyBase` + offset spawn + small fallback patrol when no route.
