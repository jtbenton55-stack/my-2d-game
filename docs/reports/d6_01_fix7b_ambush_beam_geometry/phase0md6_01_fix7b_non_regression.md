# Non-regression checklist (code inspection)

| Area | Status |
|------|--------|
| Camera guard spawn path | Unchanged (`_spawn_security_camera`, MissionSecurityCamera) |
| Wrong-code guard spawn | Unchanged (not touched) |
| Guard cooldown / search net | Unchanged (no edits to spawn probe logic) |
| `beam_trip` / alarm handler | Same `body_entered` bind `"AMBUSH_security_beam"` + existing `_on_runtime_alarm_zone_entered` |
| Mid-run heat policy | No changes to heat writes; existing audit string preserved |
| Save keys | None added |
| HUD / Player | No `Player.gd` / stamina / `player.tscn` edits |
| F1 / F10 / F11 / pause | Debug panel text-only extension |

**Runtime playtest:** Not executed in this environment (Godot binary not on PATH); manual verification required for spawn paths and beam trip.
