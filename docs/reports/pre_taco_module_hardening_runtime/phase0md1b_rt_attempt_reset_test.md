# Attempt reset / beam (0M-D1B-RT)

**No in-engine simulation** (no Godot).

**Code review:** `reset_mission_runtime_for_new_attempt()` entry point exists; normal fail/win path reloads scene per `SceneManager` / `MissionResult`. Beam one-shot code paths were not modified in this RT pass.
