# 0M-D1B-RT2 — Bridge recovery (Phases 2 + 12 summary)

## Result
**PARTIAL bridge recovery:** MCP grb_launch / grb_reset started a Godot 4.6.2 session with **GRB tier 2** and a live TCP bridge (grb_runtime_info, grb_scene_tree, grb_call_method, …).

## Authorized path check
C:\Users\jtben\Documents\PBD 2026\Godot_v4.6.2-stable_win64.exe exists on this machine as a **directory**, not an executable — local headless launch using that string **fails**. Cursor MCP used the **companion console Godot** from GODOT_PATH instead.

## Activation (from DebugServer.gd)
- Feature: editor / debug / grb
- Env: GODOT_DEBUG_SERVER=1 or GDRB_TOKEN (handled by MCP launcher)

## Session end
grb_quit — game quit successfully.

## Failure modes seen
- First grb_ping without running game: *Bridge not connected. Launch the game first.*
- After _pause_game() on mission pause menu: MCP timeout / stale bridge — **avoid pausing the SceneTree during GRB automation** unless using a tier that can still pump RPCs.
