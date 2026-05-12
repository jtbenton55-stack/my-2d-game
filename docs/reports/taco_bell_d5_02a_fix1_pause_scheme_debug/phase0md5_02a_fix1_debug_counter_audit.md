# Phase 3 — Debug / counter panel duplication

## Always-visible top-left panel

- **Owner:** `Phase0JDebugHUD` (`CanvasLayer`, layer 90) under `GameplayRoot/RuntimeHelpers`.
- **Scene default:** `TacoBellIso_Editable_RedesignTest.tscn` set `visible_by_default = true`, forcing the large counter / C5 counts panel on during play.
- **Metrics shown:** Collected/inspected counters, Phase0J category counts (`poop_bag`, `bag`, `objective_bag`, …), gate line, adapter-driven state — overlaps top-left HUD / health region.

## F10 panel

- **Owner:** `IsoMissionDebugPanel` (`CanvasLayer`, layer 100), toggled with **F10** (compact) / **F9** (details).
- **Metrics:** Mission heat, attempt counters, runtime summary, poop_used, alarms, etc.

## Duplication

- **Poop / bag / objective-style counts:** Present on Phase0J HUD (adapter categories) **and** partially on Iso compact line (attempt `poop_bags_used` vs adapter `poop_bag`).

## Consolidation direction

- Keep **F10** as the scrollable dev home for merged metrics.
- **Phase0JDebugHUD:** force hidden during play via `force_playfield_hidden` (default true) so scene `visible_by_default` cannot cover health bars; toasts route to `EventBus.debug` when hidden.
