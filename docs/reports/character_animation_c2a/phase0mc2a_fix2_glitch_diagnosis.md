# Phase 0M-C2A-FIX2 — Glitch diagnosis (FIX1 / legacy composite)

## Primary root cause (classified)

**G — WRONG_ROW_SELECTED** combined with **L — SOURCE_LAYOUT_MISUNDERSTOOD**

The FIX1 pipeline advanced **columns 0–9** on assumed “idle” and “walk” **kit rows** (e.g. row 0 / row 10 style layout) without proving those strips are a coherent generic idle/walk cycle on the PVGames **100×200** mega-grid. On this kit, **horizontal strips are not guaranteed to be temporal animation frames**; they can jump between poses, directions, or partial crops when misread—matching sandbox symptoms (half-body feel, leg pop, anchor jitter).

## Secondary / contributing factors

- **K — BAD_FIX1_SPRITEFRAMES:** Resource was structurally valid for Godot 4 but **bound to a composite built with incorrect row semantics**, so atlas regions were “correct” for the wrong pixels.
- **B — WRONG_ATLAS_REGION:** Symptom layer—regions matched the broken composite, not a stable full-body cycle.

## Per-animation notes (FIX1)

- **idle / walk:** Each frame used a **100×200** region, but **semantic** alignment across time was wrong → visible glitching despite consistent region dimensions.

## Checks performed (assertions)

- `glitch_diagnosis_completed` == true  
- `current_bad_regions_inspected` == true (see `phase0mc2a_fix2_current_bad_frames_contact_sheet.*`)  
- `current_bad_frame_visibility_checked` == true (labels on forensic sheet)  
- `root_cause_classified` == true (see JSON `primary` / `secondary`)  

## Machine-readable

See `phase0mc2a_fix2_glitch_diagnosis.json`.
