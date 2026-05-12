# 0M-D5-02A — Phase 7: Runtime / GRB validation

## Performed

- **GRB** tier 2: MainMenu → Hideout → `launch_taco_bell` → Taco loaded.
- `grb_find_nodes` Debug: confirmed **IsoMissionDebugPanel** path and **Phase0JDebugHUD** path + new **DebugScroll** child name from live tree (post-build).
- `IsoMissionDebugPanel.visible` **false** at sample time.

## Not performed / limitations

- **Pause** Esc path and scrollbar drag — **manual** (paused GRB limitation per D5-00).
- **F11/F10/F1** toggle verification — **manual**.
- **New errors:** `grb_get_errors` not re-polled after this pass’s final code edit in-session.

## Manual checklist

See final report **AE**.
