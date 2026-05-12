# 0M-D5-02A — Phase 1: UI / debug inventory

| Path | Context | Position / layer | Default visibility | Overflow risk | Classification |
|------|---------|-------------------|-------------------|---------------|------------------|
| `src/ui/HUD.gd` + HUD scene | Mission/global | Top bars | Player-facing | Low (ProgressBars) | KEEP_BUT_MAKE_COMPACT (D5-02B adds bars here) |
| `src/ui/test_ui/pause_menu.gd` | Taco pause | layer 120 | Hidden until Esc | Was high (Label only) | **REPLACE_WITH_SCROLLABLE_PANEL** (done) |
| `src/ui/test_ui/controls_overlay.gd` + `.tscn` | Mission | Bottom-right | Hidden unless F1 | Was medium | **REPLACE_WITH_SCROLLABLE_PANEL** (done) |
| `src/ui/PauseMenu.gd` | Alternate pause | varies | Unknown | UNKNOWN | DEFER (duplicate vs test_ui pause) |
| `src/missions/iso/runtime/Phase0JDebugHUD.gd` | Taco iso | layer 90, top-left | Was always on | Medium | **HIDE_BY_DEFAULT** + scroll (done) |
| `src/missions/iso/runtime/IsoMissionDebugPanel.gd` | Taco iso | layer 100 | Was on in debug build | Status text | **HIDE_BY_DEFAULT** + scroll (done) |
| `src/player/PlayerSprintDebugOverlay.gd` | Player child | layer 120 | Was on in debug | High (long label) | **DEV_TOGGLE_ONLY** F11 + bounded scroll (done) |
| `src/hideout/HideoutDebugController.gd` | Hideout | Debug panel | Was visible | Buttons only | **HIDE_BY_DEFAULT** panel root (done) |
| `HideoutHub` `DebugHideoutPanel` | Hideout | UI layer | Now hidden via controller | Low | HIDE_BY_DEFAULT |
| `src/ui/DialogueBox.gd` | Global dialogue | Center | Conditional | Medium | DEFER (portrait mission) |
| `src/ui/MissionResult.gd` | Post-mission | Full screen | Conditional | Low | KEEP_ALWAYS_VISIBLE |
| `src/ui/SchemeCardMenu.gd` | Hideout/mission | Modal | Conditional | Medium | DEFER |
| `src/ui/evidence_board/*` | Hideout | Panel | Conditional | Medium | DEFER |
| `src/ui/HideoutStorefrontPanel.gd` | Hideout | Panel | Conditional | Medium | DEFER |
| Taco `GeneratedRuntimeMarkerDebugInteractables` | Taco | World | Dev markers | N/A | DEFER (world gizmos, not corner text) |
| `DebugLabels` / `DebugUI` / `DebugLabelLayer` | Taco | Runtime | varies | UNKNOWN | UNKNOWN_NEEDS_MANUAL_REVIEW |

**Corner clutter (primary):** Phase0JDebugHUD, IsoMissionDebugPanel, ControlsOverlay (when toggled), sprint overlay (when enabled), hideout debug panel.
