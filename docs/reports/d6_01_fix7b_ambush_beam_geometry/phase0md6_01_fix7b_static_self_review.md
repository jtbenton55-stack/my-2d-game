# Static self-review

1. **Changed gameplay files:** `src/levels/IsoMissionBase.gd`, `src/missions/iso/runtime/IsoMissionDebugPanel.gd` only.
2. **Forbidden files:** `project.godot`, `Player.gd`, `PlayerStaminaController.gd`, `player.tscn`, assets, noncanonical Taco scenes — **not modified**.
3. **FIX7A anchor resolver:** `_find_runtime_debug_marker` / authoring search intact; only geometry and state keys extended.
4. **Vertical beam:** `Line2D` local Y endpoints; `RectangleShape2D` tall; shared `beam_center`.
5. **Four-guard ambush:** Not implemented.
6. **Broad refactor:** No `IsoMissionBase` split; localized helpers + constants.
