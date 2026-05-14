# Spawn error audit

Godot error at `_spawn_guard_for_spawn` line **1426** (`enemies.add_child(guard)`): mutating the scene tree from inside Area2D **`body_entered` / exposure** callbacks causes *Can't change this state while flushing queries*.

**Plan:** Queue security spawn requests and `call_deferred` a flush that performs `_spawn_guard_for_spawn` and post-setup on the next idle frame.
