# F10 Spawn Truth Cleanup

IsoMissionDebugPanel now shows guard counts as functional/raw/invalid ignored/cap/queued and last spawn as source/mode, requested, chosen, actual, result, reason, and distance. Active guards list is limited to the first three functional security guards. Beam copy is player-readable and avoids raw dictionary dumps.

## Assertions
- ASSERT f10_spawn_truth_readable == true
- ASSERT f10_not_overcrowded_with_code_language == true
- ASSERT f10_shows_chosen_and_actual_spawn_position == true
