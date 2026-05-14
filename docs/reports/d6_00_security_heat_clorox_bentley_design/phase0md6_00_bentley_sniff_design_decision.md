# 0M-D6-00 — Design decision: Bentley sniff + case-the-joint

## 1. Keep Bentley sniffing as a separate coded mechanic now?

**No new standalone “sniff mode” in D6-03 MVP.** The repo already ships a **Q-based “Case the Joint” pulse** (`Player._try_case_the_joint`) that highlights **interactables, enemies, and `iso_security_camera`** — this is the correct **unified tactical read** surface.

## 2. Merge with case-the-joint?

**Yes — canon name:** *Case the Joint (Bentley assist flavor)* — future VO / FX can reference Bentley without a second system.

## 3. Q triggers?

**Already:** `case_the_joint` action.

## 4–5. Activation outcome / Bentley visuals

- **Now:** highlight pulse + short objective line; optional future: Bentley bark SFX + paw print decal (cosmetic).
- **Not now:** pathfinding sniff solver.

## 6. What is revealed?

- **Pulse MVP expansion (D6-03 if implemented):** add optional groups — `scent_trail` / clue markers / wipeable trace — **only if** those nodes exist in groups; still **no minimap**.

## 7. Cost model

- **Cooldown-based** (already present) — optionally consume **scheme card charge** later for extended radius / duration.

## 8. Taco vs tutorial vs future Bentley mission

- **Taco:** polish readability (group coverage, tuning range, F10 metrics) — **low cost**.
- **Playable Bentley mission:** **defer** until locomotion + security adapter stable.

## 9. Minimap redundancy

- Pulse is **local LOS-adjacent** info, not global map — **not redundant**.

## 10. D6-03 directive

**Default: DEFER feature expansion;** ship only **documentation + F10 telemetry + group list audit** if schedule tight. If implementing, cap at **+group targets + VFX/SFX polish**, no new input.

## 11–14. HUD / F10

- HUD: **optional** one-line hint first time per session.
- F10: log last pulse radius, targets found, cooldown remaining.

## Assertions

| Assertion | Value |
|-----------|--------|
| bentley_sniff_design_decision_created | true |
| q_case_the_joint_role_defined_or_deferred | true (defined — existing) |
| playable_bentley_scope_deferred_or_defined | true (deferred) |
