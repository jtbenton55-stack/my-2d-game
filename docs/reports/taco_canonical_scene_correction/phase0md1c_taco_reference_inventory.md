# 0M-D1C — Taco reference inventory (Phase 1)

## Active player-facing iso routes (updated in Phase 3)

| Location | Role |
|----------|------|
| `HideoutMissionBoardController.gd` → `TACO_BELL_SCENE` | MissionBoard **Start / Replay** |
| `HideoutStationCatalog.gd` → `TACO_BELL_SCENE` | Catalog slot 0 `scene_path` |
| `SceneManager.gd` → debug `taco_bell_drop` override | Scheme / `start_mission` debug iso path |
| `IsoMissionDebugPanel.gd` → `_on_restart` | Debug restart loads iso scene |

## Legacy / non-authoritative for iso Taco

| Location | Note |
|----------|------|
| `GameState.mission_catalog["taco_bell_drop"].scene_path` | `TacoBellMission.tscn` — classic room, not iso hideout path |
| `IsoMissionBase.bake_to_editable_scene` default | Writes **Editable** — bake output, not “which map players fly” |

## Broader repo

Dozens of **validators**, **reports**, and **Phase0J/K** tooling files reference one or both scenes; see JSON for structured summary. No mission other than `taco_bell_drop` routing was changed.
