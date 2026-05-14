# 0M-D6-01-FIX1 — Phase 0 safety baseline

**Hard assertions**

- `repo_root_confirmed` == true — `games/my-2d-game` contains `project.godot`.
- `current_branch_recorded` == true — `c2a-full-character-animation-20260509-172230`.
- `git_status_recorded` == true — captured at validation time (see JSON / `git status`).
- `d6_01_fix1_scope_confirmed` == true — security runtime behavior (guards, cameras, beam truth, heat verification, F10).
- `protected_files_identified` == true — no edits to `Player.gd`, `PlayerStaminaController.gd`, `project.godot`, `player.tscn`, assets, noncanonical Taco scenes (RedesignTest untouched).

**Playable Taco**

- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

**D6-01**

- Prior report pack expected under `docs/reports/d6_01_taco_security_heat_mvp/` (MVP wiring).
