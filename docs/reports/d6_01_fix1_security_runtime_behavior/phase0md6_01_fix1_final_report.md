# 0M-D6-01-FIX1 — Final report

## Verdict: **PARTIAL**

Implementation and static review are complete; **in-editor / GRB playtest was not executed** in this agent session, so gameplay acceptance is **manual**.

## Branch

`c2a-full-character-animation-20260509-172230`

## GOOD / BAD guard

| | Path |
|---|------|
| **GOOD** | `res://scenes/characters/guard.tscn` → `Guard.gd` / `EnemyBase.gd` |
| **BAD (retained, not for security)** | `Phase0KGuardPatrol.gd` — still used by `Phase0KGuardSpawner` for `GUARD` markers only |

**Security spawns (wrong-code, camera/alarm):** **GOOD** only (`bad_guard_used_for_security_spawns`: **false**).

## Implementation summary

1. **`MissionSecurityGuardResolver.gd`** — canonical good scene path.  
2. **`Phase0KBWrongCodeAttackGuardSpawner.gd`** → `spawn_attack_guard_near_player`.  
3. **`Phase0KCameraSpawner.gd`** — default parent `EntityRoot/Cameras`.  
4. **`MissionSecurityCamera.gd`** — `require_line_of_sight` default false; controller refresh.  
5. **`MissionAlertController.gd`** — per-source spawn cooldown; beam → `beam_trip`.  
6. **`IsoMissionBase.gd`** — security spawn cap, offsets, `security_chase_soft` meta, fallback patrol, skip bad auto-patrol for `attack_guard_*`, removed recursive `register_detection` after spawn, heat-1 camera tuning, runtime debug fields.  
7. **`EnemyBase.gd`** — soft chase when `security_chase_soft`.  
8. **`IsoMissionDebugPanel.gd`** — F10 beam/cap/paths.  
9. **Reports + validator** under `docs/reports/d6_01_fix1_security_runtime_behavior/` and `src/tools/editor/d6_01_fix1_security_runtime_behavior/`.

## Forbidden files

- `project.godot` — **not** modified (FIX1).  
- `Player.gd`, `PlayerStaminaController.gd`, `player.tscn` — **not** modified (FIX1).  
- `TacoBellIso_Editable_RedesignTest.tscn` — **not** modified (FIX1).

## Beam

Runtime **`AlarmZone_garage_entry_beam`** under **`GameplayRoot/RuntimeSystems/AlarmZones`**. Zone-based, not a visible laser mesh. F10 includes **hint** and **armed/triggered** summary fields.

## Heat

Persistent heat policy unchanged. **Heat == 1** camera multipliers slightly increased for clearer replay feel.

## Kimi

**Skipped** — no advisory call; no data sent.

## Static validator

Run: `python src/tools/editor/d6_01_fix1_security_runtime_behavior/phase0md6_01_fix1_static_validator.py` from repo root. See `phase0md6_01_fix1_static_validator_run.json`.

## Manual test checklist

1. Launch project.  
2. HideoutHub.  
3. MissionBoard → Taco **RedesignTest**.  
4. Player + Bentley spawn.  
5. Objective ticker.  
6. Stamina bar.  
7. Poop count.  
8. Ctrl sprint.  
9. Space dash.  
10. F10 — security block.  
11. GOOD/BAD lines present.  
12. Wrong code → **large** guard, chases, does not face-hug as aggressively (soft chase).  
13. Escape guard → search/patrol fallback (navmesh-dependent).  
14. Multiple camera cones → detection + events in F10; reinforcements after cooldown, not every frame.  
15. Garage beam zone → **beam_trip** once per attempt in F10.  
16. Mid-run events do **not** add persistent heat.  
17. Fail mission → heat / failed_attempts +1.  
18. Relaunch with higher heat → cameras / wrong-code threshold measurably stricter.  
19. Esc pause — heat line, scroll.  
20. F1, F11.  
21. Output — no new errors.
