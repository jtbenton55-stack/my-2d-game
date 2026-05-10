# Phase 0M-C2A-FIX2 — Rebuilt frame quality (automated heuristics)

All rebuilt idle frames are **100×200 RGBA** files on a **fixed transparent canvas** (no per-frame crop to bbox).

## Idle summary

| Metric | Value |
|--------|-------|
| Frames | 10 (`idle_000` … `idle_009`) |
| Foot-bottom std (px) | **0.4** (low jitter across sequence) |
| Heuristic `all_ok` | **false** |

## Per-frame heuristic tags

Tags are **conservative** bbox heuristics (profile poses can look “half width” to a naive bbox classifier even on a full 100×200 canvas):

| Index | Tag |
|-------|-----|
| 0 | OK |
| 1 | OK |
| 2 | PARTIAL |
| 3 | OK |
| 4 | PARTIAL |
| 5 | OK |
| 6 | PARTIAL |
| 7 | OK |
| 8 | OK |
| 9 | OK |

## Walk

- **Not exported** (`walk.included` == false in metadata).

## Interpretation

- **Structural quality:** PASS (fixed size, alpha preserved, aligned layer rects).
- **Automated full-body classifier:** **PARTIAL** — do **not** treat as production-ready without **manual** review of `phase0mc2a_fix2_rebuilt_frames_contact_sheet.png` and live sandbox playback.

JSON detail: `phase0mc2a_fix2_rebuilt_frame_quality.json`.
