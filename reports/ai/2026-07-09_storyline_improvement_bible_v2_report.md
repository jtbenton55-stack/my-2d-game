# Storyline Improvement (Mission Bible v2) - Implementation Report

- Date: 2026-07-09
- Agent: Cursor (implementation/debugging)
- Milestone: Storyline Improvement Plan (grouped-milestone mode, docs + narrative systems packet)
- Plan: `.cursor/plans/storyline_improvement_plan_74875d8f.plan.md` (not modified)

## Summary

Implemented the Storyline Improvement Plan: rewrote the Mission Bible as v2 around
Parmida's "accidental crime lord" character arc (3 acts, all 9 major missions canonical,
Sterling Tower finale), added a formal Night Jobs side-content track, specced the
Cool-Down Shift as a replay mechanic, and wired the narrative into runtime systems:
per-mission Sterling clues with connects_to chains, one-shot Sterling escalation beats
and an Ellie setup beat in the hideout, an Act 1 in-mission Ellie plant, favor-conditional
ending lines, failure-cause crew hints, and Sterling-fixer-voiced investigation reports.

## Story decisions (canonical)

- Protagonist: Parmida (with Bentley), chasing "crime lord" legend; every crime is
  secretly a favor. Victor Sterling is the real thing and the mirror she rejects.
- Act 1 "Small Favors": Taco Bell, Jazz Club, Rewrite Room (+ Corner Store night job
  on-ramp). Act break: Sterling's "rival's welcome" note.
- Act 2 "The Squeeze": Clean Job, Diamond a Year, Fast Family Getaway (reframed as
  stealth + timed escape finale, not a driving genre). Midpoint: Sterling retaliates
  personally and reveals he holds Ellie.
- Act 3 "What He Can't Buy": Persian Tea, Elephant in the Room, Shadow Solo Contract,
  then Sterling Tower. Ending redefines the "crime lord" title.
- Night Jobs (optional, unique minigames, never reuse story puzzles): Corner Store
  Cashout (from start), Arm-Wrestling Underground (reclassified from story mission,
  repeatable), Laundromat Heist (planned stub), Bentley's Walk (planned stub),
  hideout rehearsal puzzles (safe-dial, darkroom, tea-brewing - future).
- Cool-Down Shift is a mechanic: replay a completed mission with blend-in objectives
  to lower venue heat. Documented in bible v2; playable variant is a later packet
  (instant radio action remains).

## Files changed

- `docs/MISSION_BIBLE.md` - rewritten as v2 (premise, acts, Night Jobs, cool-down
  shift, naming reconciliation, per-mission + night-job checklists).
- `docs/CREATIVE_DIRECTION.md` - premise/arc named Parmida; core content = 9 story
  missions + finale; Night Jobs track; key mechanics notes.
- `README.md` - removed false "5 unique missions complete" claim; added current
  status and act-structured mission list.
- `src/autoload/GameState.gd`:
  - `mission_catalog`: `mission_kind` (story/night_job/dev) + `act` tags; new
    `laundromat_heist` and `bentleys_walk` planned stubs; `arm_wrestling_underground`
    marked night_job/repeatable; reframed getaway/elephant descriptions.
  - `reset_for_new_game`: `corner_store_cashout` available from start.
  - `unlock_mission`: skips `planned` stubs; new helpers `get_mission_kind`,
    `is_night_job`, `is_mission_repeatable`.
  - `_unlock_next_missions`: taco also unlocks laundromat (no-op until stub
    activated); **finale gate re-checked after every completion** (fixes
    pre-existing order-dependence bug where completing elephant/shadow before the
    other story missions could strand the tower unlock).
  - `STORY_MISSION_STERLING_CLUES` + `_ensure_story_mission_sterling_clue`: one
    Sterling clue per story mission, discovered on success, attached to mission
    results with connects_to chain copy (taco keeps its dedicated path).
  - `_failure_crew_hint`: failure-cause crew line (camera/alarm/witness/guard/
    health/time) appended to failure next_steps.
- `src/dialogue/SterlingStoryBeats.gd` (new) - one-shot hideout beats: Ellie setup
  (post-taco), Sterling rival's welcome (post-rewrite), Sterling retaliation + Ellie
  reveal (post-getaway).
- `src/hideout/HideoutManager.gd` - plays oldest pending story beat once per hideout
  visit via existing DialogueManager path.
- `assets/dialogue/taco_bell_dialogue.json` + 
  `src/missions/iso/placeholders/MissionScentTrailPlaceholder.gd` - one-shot Ellie
  moment on first real-scent success in Taco Bell.
- `src/ui/Ending.gd` - friend lines conditional on `friend_favors`; absence lines for
  unhelped friends; Night Job bonus lines; arc-aware closing copy.
- `src/ui/MissionSelect.gd` - STORY and NIGHT JOBS sections (act order); planned
  stubs hidden; dossier "Unlock:" lines corrected to match the real unlock graph;
  Corner Store dossier added; unlock hints for new night jobs.
- `src/missions/iso/runtime/report/InvestigationReportBuilder.gd` - Sterling
  Holdings Risk Division signoff line per verdict.
- `src/tests/StoryUnlockTest.gd` - initial-state assertions updated for Corner Store
  on-ramp.
- `scenes/testing/HeadlessStoryUnlockHarness.tscn` + `.gd` (new) - headless runner
  for StoryUnlockTest + SaveLoadTest with exit code.

## Validation

- godot-lsp-diagnostics: clean (no errors/warnings) on all edited scripts.
- GdUnit4 (headless, Godot 4.6.2 console from tools folder):
  `res://tests/mission_authoring` full suite **398/398 passed** (includes
  ReplanPacket4TraceMessTest and ReplanPacket6HeatMetaTest covering the
  investigation report and heat systems touched here).
- Headless harness (`HeadlessStoryUnlockHarness.tscn`): StoryUnlockTest **16/16** +
  SaveLoadTest **8/8** passed. First run caught 1 failure ("Completion Order
  Independence") - a pre-existing gate bug, fixed by re-checking
  `_try_unlock_sterling_tower()` after every completion; re-run passed.
- Headless scene smoke: `HideoutHub.tscn` and `MissionSelect.tscn` load without
  script errors (only pre-existing tileset/theme warnings).

## Risks / follow-ups

- Sterling story beats and the ending rewrite are validated by parse/diagnostics and
  scene smoke, not by manual dialogue playthrough; Jake manual QA recommended
  (complete taco -> visit hideout -> Ellie beat should fire once).
- `laundromat_heist` / `bentleys_walk` are planned stubs pointing at
  TestMissionRoom.tscn and hidden from unlocks/UI until built.
- Cool-down shift playable variant (mission replay with blend-in objectives) is
  specced in bible v2 but not implemented; instant radio action unchanged.
- MissionResult evidence-clue rendering already supported the payload; the evidence
  board UI itself was not modified - clue records flow through the existing
  `sterling_clues`/`evidence_clues` stores.
- Debug "unlock all missions" appends planned stubs directly (bypasses
  `unlock_mission`); harmless since stubs load TestMissionRoom.

## Grouped-milestone mode statement

Work stayed in grouped-milestone mode: one cohesive packet spanning story docs,
catalog/state code, narrative runtime systems, UI, dialogue assets, tests, and a
headless harness. No rewrites of existing systems; all changes extend the existing
mission catalog, clue store, dialogue, and result pipelines.
