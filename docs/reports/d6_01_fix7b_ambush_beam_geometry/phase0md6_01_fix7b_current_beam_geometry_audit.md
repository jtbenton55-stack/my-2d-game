# Current beam geometry audit (pre-FIX7B behavior)

## Locations

- **Anchor resolution:** `_setup_fix7_ambush_beam_runtime()` — `_find_authoring_marker` then `_find_runtime_debug_marker("AMBUSH_security_beam")`.
- **Visual:** `_attach_fix7_ambush_beam_visual()` under `GameplayRoot/RuntimeSystems/SecurityBeam_Ambush_RightHallway` with child `AmbushBeamLine` (`Line2D`).
- **Trigger:** `AlarmZone_AMBUSH_security_beam` under `GameplayRoot/RuntimeSystems/AlarmZones`, `CollisionShape2D` + `RectangleShape2D`.

## Pre-FIX7B values (root cause)

| Item | Value |
|------|--------|
| Line2D points | World endpoints `anchor ± Vector2(92, 0)` converted with `host.to_local` while `host` had default position `(0,0)` → **horizontal segment in world X** |
| Line2D width | 34 px |
| RectangleShape2D size (runtime create path) | `Vector2(170, 52)` — **wide horizontal slab** |
| Visual/trigger mismatch | Compared trigger to **anchor** while visual center tracked anchor; host not positioned at anchor → geometry confusion |

## Hypothesis verdict

- **A (horizontal points):** CONFIRMED — delta along X.
- **B (horizontal rect):** CONFIRMED — width ≫ height.
- **C (offset):** Partial — anchor correct; choke needed named offset from marker cluster.
- **D (wall height):** Fixed nominal height `D6_FIX7B_AMBUSH_BEAM_HEIGHT` (560) for this pass.
- **E (coordinate space):** Partial — FIX7B sets `host.global_position = beam_center` and uses local vertical points `(0, ±h/2)`; Area2D `global_position = beam_center`.

## Stale visuals

- `_remove_fix7_stale_temp_beam_nodes` removes legacy FIX4–FIX6B hosts and `SecurityBeam_Ambush_RightHallway` before deferred setup recreates the canonical beam.
