# 0M-D1B-RT2 — Bridge / plugin diagnosis (Phase 1)

## Plugin files

- `addons/godot-runtime-bridge/plugin.cfg` — present (Godot Runtime Bridge 2.0.1)
- `addons/godot-runtime-bridge/runtime_bridge/DebugServer.gd` — documents `GDRB_*` activation gates

## `project.godot` (read-only)

Editor plugins include `res://addons/godot-runtime-bridge/plugin.cfg`. This file was **not** modified in RT2.

## Authorized Godot executable path

`C:\Users\jtben\Documents\PBD 2026\Godot_v4.6.2-stable_win64.exe` resolves to a **directory** on this host (not a `.exe`), so a direct shell launch using that path **fails**. MCP `grb_launch` used the **companion Godot console binary** from the Cursor/Godot integration (`GODOT_PATH`).

## MCP cold state

- `grb_ping` without a running session: **Bridge not connected. Launch the game first.**

## Root cause (prior RT)

Enabling the editor plugin does not start the TCP server. The bridge requires a **running Godot process** with feature `editor`/`debug`/`grb` **and** env `GODOT_DEBUG_SERVER=1` or `GDRB_TOKEN`. MCP `grb_launch` supplies that automatically.
