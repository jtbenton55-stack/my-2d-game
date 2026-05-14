# 0M-D6-00 — Design decision: Clorox wiping

## 1. What the player wipes

**Trace interactables** — world nodes marked as wipeable (smear, fingerprint glass, contaminated counter) — **not** arbitrary walls. Distinct from hideout “wipe paws” care.

## 2. Why it matters

- **Readability:** reinforces “responsible heist” fantasy.
- **Mechanics:** optional **risk/time tradeoff** (stand still to channel wipe).
- **Scoring:** can improve **Clean Getaway / perfect moment components** without being a hard gate.

## 3. Heat / evidence / rank linkage

- **Default MVP:** wiping a trace **prevents or refunds a small heat increment that would otherwise apply at mission end** *or* adds a **performance bonus flag** `traces_cleaned` consumed by `_finalize_mission_performance` — pick **one primary** in D6-02 to avoid double rewards.
- **Evidence board clues** remain meta; **do not conflate** with per-mission smear unless explicitly authored.

## 4. Required?

- **No** for Taco completion in MVP.

## 5–7. Time / interrupt / risk

- **Timed hold** (e.g., 0.8–1.2 s) cancelable on damage/move.
- **Risk:** player exposed during channel; guards use existing detection.

## 8. Progress / feedback

- Progress ring or segmented shader on interactable; audio + one objective line.

## 9–10. Taco vs future

- **Taco:** 1–3 pre-placed wipe spots tied to high-traffic mess fiction (sauce splatter, paw prints near service lane).
- **Future missions:** reuse `WipeableTrace` component + interaction contract.

## 11–12. D6-02 smallest MVP

- Add **resource + interactable** + hold interaction + **one performance field** + F10 counter.
- **Defer:** chain-wiping puzzles, multi-tool chemistry, stealth grid contamination sim.

## 13–14. Tooling model

- **Both:** contextual interactables in-world; optional **single carried Clorox charge** as scheme unlock later.

## Assertions

| Assertion | Value |
|-----------|--------|
| clorox_design_decision_created | true |
| clorox_mvp_defined | true |
| clorox_not_overbuilt | true |
