# 0M-D6-00 — Design decision: Security + Heat

## 1. Heat in plain English

**Heat** is “how much trouble this mission id remembers you caused,” stored as **`failed_attempts` capped at 5** and surfaced via `GameState.get_mission_heat`. It makes later **replays harder** (mutated layout, tighter code tolerance, faster cameras, extra pressure) — not the same thing as a momentary alarm during a single attempt.

## 2. Persistence model

- **Persistent across attempts** for a given `mission_id` (until hideout systems / debug reset it).
- **Not a global single integer** — keyed per mission; hideout may show Taco-specific narrative states separately.

## 3–4. What increases / decreases heat

- **Increases:** mission failure paths that increment `failed_attempts` (exact call sites today are **distributed** — D6-01 must define the **canonical increment rules** so beams, wrong codes, and soft fails do not double-count).
- **Decreases:** intended future UX = replay / “lower heat run” style actions — **currently placeholder** in hideout feedback; **no proven decrement** in audited iso runtime.

## 5–6. During vs between missions

- **During:** heat selects **`_heat_profile`** (wrong code threshold, camera multipliers, extra camera/guard pressure, fake scent penalty) and **Louis hint text**.
- **Between:** drives hideout **Heat Scanner** copy, mission board replay affordances, and mutation rolls.

## 7–8. Relationship map (guards / cameras / beams / wrong code)

- **Guards & cameras** should emit **security events** into a **single adapter** (new thin module in D6-01) that forwards to `MissionAlertController` + optional performance counters + heat policy.
- **Wrong-code path** already spawns guards and can emit `wrong_code_alarm` style detection — must not also silently stack duplicate “alarms” unless intended.

## 9. Taxonomy (distinctions)

| Term | Meaning |
|------|---------|
| **Detection** | Per-frame sensing (camera exposure, guard LOS) — inputs to alert controller. |
| **Suspicion** | Short-lived elevated attention (`MissionAlertController` suspicious + decay). |
| **Alert** | Attempt-local FSM state on `MissionAlertController` (`normal/suspicious/alerted/resolved`). |
| **Alarm** | `record_alarm_event` path: performance counters, screen shake, optional reinforcement spawn hook. |
| **Heat** | Persistent per-mission difficulty index from `failed_attempts` cap 5. |
| **Failure** | Mission loss / abandon — ends attempt; may increment heat depending on design rule (D6-01 codifies). |

## 10. Beam vs wrong code (design targets)

- **Beam:** treat as **alarm-class security event** (one-shot trip) — always produces a **normalized SecurityEvent** `{source, kind, severity}`; may increment **attempt-local alarm count**; **whether it increments heat** is a **D6-01 policy flag** defaulting to *yes only on full run failure* to avoid harsh double punishment mid-attempt unless gameplay demands.
- **Wrong code:** already spans **guard spawn** + **detection event** — must share adapter; heat effect = **optional** +1 failed only when threshold exceeded **or** on mission fail (choose one in implementation spec).

## 11–12. Taco MVP vs reuse

- **Taco MVP:** wire **garage beam + code gate + camera + guard** through **one SecurityEventAdapter**; expose counters on **F10** + one **pause line**; do **not** build full stealth AI.
- **Reuse:** adapter + event enum live under `src/missions/iso/runtime/` for any iso mission.

## 13–15. HUD / pause / F10 / save

- **HUD player strip:** keep compact; heat **not required** on HUD for MVP — optional numeric heat in F10 only.
- **Pause:** single plain-English heat line + link to detail in mission performance section.
- **Save:** continue using `GameState` serialization paths for `failed_attempts` / `mission_heat_states` / `mission_performance` — **do not fork new save keys** without migration plan.

## Assertions

| Assertion | Value |
|-----------|--------|
| heat_defined_plain_english | true |
| security_event_taxonomy_defined | true |
| taco_security_heat_mvp_defined | true |
