# 0M-D5-02B — Compact HUD final report

## Verdict: **PARTIAL**

Implementation complete in repo; live Godot sprint/poop motion tests not run from this session.

## Branch

`c2a-full-character-animation-20260509-172230`

## Files touched

- `src/ui/HUD.gd`
- `scenes/ui/hud.tscn`
- `src/missions/ui/MissionHudDataProvider.gd` (new)

## Summary

Compact mission HUD: bounded objective ticker, top-right sprint stamina bar + poop bag count, optional control hint (export off). Data via read-only `MissionHudDataProvider`. No Player / stamina script / Taco scene / project.godot edits.

## Limitations

- Stamina visibility requires `player` in tree with `get_sprint_runtime_debug()`; first frames may hide bar until spawn.
- Runtime validation manual.

## Next pass

Scheme-card gameplay effects bridge, or Taco polish per roadmap.
