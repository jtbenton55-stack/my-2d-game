# 0M-D5-02A — Phase 3: UI ownership / consolidation

## Policy

| Concern | Owner after D5-02A → D5-02B |
|--------|------------------------------|
| Objective ticker (future) | **Main HUD** (`res://scenes/ui/hud.tscn` + `src/ui/HUD.gd`) — compact top strip, no duplicate pause text |
| Stamina bar (future) | **Main HUD** |
| Poop bag count (future) | **Main HUD** |
| Compact control hint (future) | **HUD** one-liner or **ControlsOverlay** minimized default — not both long |
| Detailed objectives / schemes / clues | **Pause** (`pause_menu.gd`) — scrollable |
| Controls reference (long) | **Pause “Controls”** + optional F1 overlay (bounded) |
| Sprint signal chain | **PlayerSprintDebugOverlay** — F11 toggle, scroll bounded |
| Iso mission runtime metrics | **IsoMissionDebugPanel** — F10 compact, F9 details (scroll) |
| Phase0J marker counts | **Phase0JDebugHUD** — hidden unless `visible_by_default` or `show_message` with default on |
| Hideout cheat states | **DebugHideoutPanel** — hidden; re-show via scene tree / future F12 if added |
| Debug / validators | **Test scenes** under `scenes/hideout/tools/` — unchanged |

## Default visibility after this pass (Taco)

- **Player-facing HUD bars:** unchanged (existing HUD).
- **Corner debug CanvasLayers:** **hidden** (Phase0J, Iso debug, sprint overlay until F11).
- **Controls overlay:** still **F1**, content **scrollable**.
- **Pause info panels:** **scrollable** RichTextLabel.

## D5-02B “slots reserved”

- **Top-left:** avoid new permanent widgets (was debug-heavy).
- **Top-center / top-right:** preferred for ticker + thin bars (document for D5-02B prompt).
