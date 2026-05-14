# F10 Spawn Truth Probe Plan

F10 should show concise security truth: source, mode, requested, chosen, actual, result, reason, distance, functional/raw/invalid/cap/queued counts, first three functional guard positions, and beam status. It should avoid large dictionaries and long node dumps.

## Assertions
- ASSERT f10_spawn_truth_probe_plan_created == true
- ASSERT f10_spawn_truth_fields_concise == true
