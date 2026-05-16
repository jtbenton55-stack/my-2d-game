# FIX7C — Beam geometry audit (FIX7B baseline)

## FIX7B (pre-FIX7C)

| Field | Value |
|-------|--------|
| `D6_FIX7B_AMBUSH_BEAM_CENTER_OFFSET` | `(-180, -48)` |
| Height | 560 px |
| Trigger | 56 × 560 |
| Visual width | 32 px |

## Issue

- Beam read as **too far right** vs white-line choke near `spawn_route_louis_return` / post-gate corridor.
- **560 px** vertical span insufficient for upper/lower wall-to-wall in that hallway.

## Geometry model (unchanged)

- Anchor: FIX7A resolution (`AMBUSH_security_beam`).
- `beam_center = anchor + offset`; `Line2D` local `(0, ±h/2)`; `RectangleShape2D` size = trigger size; same `global_position`.

## FIX7C correction intent

- Move center **~200 px further left** (delta on offset X: -180 → -380).
- Increase height to **840 px** and match trigger **72 × 840** (width in 56–80 range).
