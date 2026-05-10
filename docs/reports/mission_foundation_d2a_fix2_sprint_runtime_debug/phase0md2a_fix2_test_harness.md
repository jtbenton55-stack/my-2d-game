# 0M-D2A-FIX2 — Test harness

- **Scene:** `res://scenes/hideout/tools/PlayerSprintRuntimeTest_0MD2A_FIX2.tscn`
- **Script:** `res://scenes/hideout/tools/PlayerSprintRuntimeTest_0MD2A_FIX2.gd`
- **Usage:** Add as child of a running mission (or any scene where a node in group `player` exists). Output (~2.2 Hz) prints compact chain `CTRL→ACT→REQ→ACTV→MULT→VEL` plus suppression, dash, dodge burst, stamina, and full `JSON.stringify` of `get_sprint_runtime_debug()`.

Assertions: see `phase0md2a_fix2_test_harness.json`.
