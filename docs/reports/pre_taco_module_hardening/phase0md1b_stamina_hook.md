# Stamina / sprint hook (0M-D1B)

`PlayerStaminaController` (`RefCounted`) holds stamina math and signals. `Player.gd` wires it with **minimal** changes: no animation dependency; sprint only applies when `InputMap` has `sprint` and the player is not in stealth or hitbox-combat mode.

**Input:** `sprint` action is **not** added to `project.godot` in this pass — document and add later.

**Test:** `PlayerStaminaControllerTest_0MD1B.tscn` prints JSON snapshots to Output.
