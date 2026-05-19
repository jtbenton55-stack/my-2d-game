# Hideout Scenes

`HideoutHub.tscn` is the protected active hideout scene.

## Active Runtime

- `HideoutHub.tscn`: current hideout runtime scene with manager/controller cluster and hideout sync surfaces.
- `hideout.tscn`: older hideout scene kept for reference/legacy checks unless separately validated.

## Tooling And Tests

- `tools/`: PVGames palette/stamper/object-palette tooling scenes. Cursor runtime validation found active tooling references, so these should be kept.
- `tests/`: hideout/PVGames test scenes.

Do not move or delete hideout tool/test scenes without validating `src/tools/editor/` references and Godot editor behavior.
