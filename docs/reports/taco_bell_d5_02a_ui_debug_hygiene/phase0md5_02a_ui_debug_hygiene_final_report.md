# 0M-D5-02A — Final report

## Verdict: **PARTIAL**

Implementation and static checks are complete; **pause scrollbar interaction** and **all resolution sizes** were not exhaustively runtime-tested (GRB + paused-tree limits).

## Branch

`c2a-full-character-animation-20260509-172230`

## Files modified (git diff)

- `src/missions/iso/runtime/Phase0JDebugHUD.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `src/player/PlayerSprintDebugOverlay.gd`
- `src/hideout/HideoutDebugController.gd`
- `src/ui/test_ui/pause_menu.gd`
- `src/ui/test_ui/controls_overlay.gd`
- `src/ui/test_ui/controls_overlay.tscn`

## Files created

- `docs/reports/taco_bell_d5_02a_ui_debug_hygiene/*` (this report set + validator run JSON)
- `src/tools/editor/taco_bell_d5_02a_ui_debug_hygiene/phase0md5_02a_static_validator.py`

## Biggest clutter sources (before)

- Phase0JDebugHUD (always-on + large corner panel)
- IsoMissionDebugPanel (on in debug builds)
- Sprint debug overlay (large top-left in debug)
- Hideout debug state panel
- Controls overlay text without outer scroll (label autowrap only)

## Hidden by default (after)

- `IsoMissionDebugPanel` root (`visible = false`; F10 / F9)
- `PlayerSprintDebugOverlay` (`hide()`; **F11** toggles)
- `DebugHideout*` panel root (via `HideoutDebugController`)
- `Phase0JDebugHUD` when `visible_by_default` is false and no forced toast visibility

## Standardized / bounded

- Pause info: **ScrollContainer + RichTextLabel** + deferred height fit
- Controls overlay: **ScrollContainer + RichTextLabel** + panel clip
- Sprint overlay: bounded panel + scroll + F11
- Phase0J panel: inner **ScrollContainer** for stacked labels
- Iso compact line: **ScrollContainer** + wrapped label + dynamic height

## Remaining risks

- HUD objective label length; dialogue / modals; world `Debug_*` markers — see JSON lists.

## D5-02B recommendation

Implement ticker + stamina + poop count in **`res://scenes/ui/hud.tscn` / `HUD.gd`**, keep detail in pause; follow `phase0md5_02a_d5_02b_hud_readiness_plan.md`.

## Validator

See `phase0md5_02a_static_validator_run.json`.
