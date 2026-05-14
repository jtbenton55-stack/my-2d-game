# Camera runtime path audit

Runtime cameras are **not** authored as finished nodes in the `.tscn`; `Phase0KCameraSpawner` instantiates `MissionSecurityCamera` for each `metadata/category = "CAM"` marker under `GameplayRoot/MarkerRoot/EditorOnlyPlaceholders`.

**Observed CAM markers (RedesignTest):** `CAM_bag_room`, `CAM_garage_lower`, `CAM_garage_upper`, `CAM_market_01`, `CAM_trash_alley`, `CAM_upper_high_heat`.

**Script:** `res://src/missions/iso/runtime/MissionSecurityCamera.gd`  
**Controller:** `MissionAlertController` in group `iso_alert_controller`.

**Regression:** Shared `decay_exposure` spam (FIX2 repair).
