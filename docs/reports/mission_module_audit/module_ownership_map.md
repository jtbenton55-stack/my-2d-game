# Module ownership map

Intended vs current owners for responsibilities that future Cursor passes should not fight over. Full table: `module_ownership_map.json` → `rows`.

## P0 highlights

- **Lifecycle / attempt state:** still split across `LevelBase` and `IsoMissionBase`; needs explicit reset contract.
- **Tools:** `Player` owns UX; mission owns effect — introduce adapter surface.
- **Taco flavor:** should move out of `IsoMissionBase` preload into `TacoBellMissionAdapter` (or composition child).

## Hard assertions

See JSON `assertions`.
