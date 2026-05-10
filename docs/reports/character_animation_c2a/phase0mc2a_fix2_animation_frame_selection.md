# Phase 0M-C2A-FIX2 — Animation frame selection

## Requested vs delivered

- **Requested:** Option **C** — generic idle + generic walk (non-directional).
- **Delivered:** Option **B** — **idle only**. Automated gates **rejected every walk strip** examined under horizontal/vertical interpretations; including walk would violate the “no fake success” rule.

## Idle strip (chosen)

- **Orientation:** horizontal (fixed row, columns advance).
- **Kit row index:** **8**
- **Columns:** **0–9** (10 frames)
- **Rationale:** Pipeline scores candidate strips using **foot-bottom stability** and **inter-frame coherence**; row **8** won for the selected orientation.

## Walk strip

- **Included:** **no**
- **Rationale:** No candidate passed the stricter walk acceptance thresholds; metadata records `walk.included: false`.

## Scope constraints met

- No 4- or 8-direction animations.
- No promotion to production.

JSON mirror: `phase0mc2a_fix2_animation_frame_selection.json`.
