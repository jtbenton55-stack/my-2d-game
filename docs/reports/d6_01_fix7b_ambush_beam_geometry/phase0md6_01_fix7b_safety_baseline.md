# D6-01-FIX7B — Phase 0 safety baseline

- **Repo root:** `C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\my-2d-game`
- **Branch:** `c2a-full-character-animation-20260509-172230`
- **Scope:** FIX7B AMBUSH beam geometry only (vertical Line2D + vertical `RectangleShape2D`, shared center). No four-guard ambush.
- **Playable Taco scene (exists, not modified):** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- **Forbidden (confirmed not in this diff):** `project.godot`, `Player.gd`, `PlayerStaminaController.gd`, `player.tscn`, assets, noncanonical Taco scenes.
- **FIX7A:** `_find_runtime_debug_marker` / authoring anchor resolution for `AMBUSH_security_beam` preserved in `_setup_fix7_ambush_beam_runtime`.

See paired JSON for machine-readable assertions.
