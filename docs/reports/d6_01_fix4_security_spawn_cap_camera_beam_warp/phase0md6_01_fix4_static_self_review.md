# Static self-review (pre-runtime)

- **Player.gd / PlayerStaminaController.gd / project.godot / player.tscn / Taco scenes / assets:** not modified in this FIX4 patch set.
- **No new save keys.**
- **No new SecurityManager autoload.**
- **Cap:** failed spawns do not increment live meta; counter syncs to live count on success.
- **Camera decay:** `MissionSecurityCamera` still avoids multi-camera **`decay_exposure`** regression.

See `phase0md6_01_fix4_static_self_review.json`.
