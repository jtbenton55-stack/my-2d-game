# 0M-D6-01-FIX7E — Final report (AMBUSH beam A–B span clamp)

**Verdict: PARTIAL** — Implementation and static validation complete; **in-editor playtest not run** in this environment (Godot CLI not on PATH).

## What changed

- **Root cause:** FIX7D used **largest vertical gap** across multiple probe Y values and **36px** outward overlap, inflating the beam beyond the local choke gap.
- **FIX7E:** Same **choke X** as FIX7D; **single** vertical ray pair at `(choke_x, probe_y)` with `probe_y` = midpoint of anchor and `spawn_route_louis_return` when available; **visual** = raw inner hits (0px visual overlap); **trigger** = visual ±8px height padding; **min/max** height guards with numeric fallback (360/400) on failure or absurd span.
- **F10:** Dedicated FIX7E proof block + runtime summary keys.

## Safety

- **Not modified:** `project.godot`, Player scripts, `player.tscn`, Taco scenes, assets, heat/save keys.
- **Kimi:** Not used.

## Follow-up

Run the manual checklist in `phase0md6_01_fix7e_final_report.json` inside Godot to promote PASS.
