# Accelerated Grouped-Milestone Operating Plan Report

**Date:** 2026-06-17
**Branch:** `new-feature-roadmap-branch`
**Status:** Documented operating plan

## Goal

Record Jake's updated implementation preference: move faster on the remaining plug-and-play game-system roadmap by taking larger grouped implementation swings while preserving full roadmap/blueprint objectives and validation discipline.

## Files Changed

- `AGENTS.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-06-17_accelerated_grouped_milestone_operating_plan_report.md`

## Operating Decisions

- Use broad grouped implementation packets by default when systems naturally share contracts, files, validation, or authoring flow.
- If broad packets become too buggy, fall back to 2-3 tightly related phase slices until the foundation stabilizes.
- Use the Phase 6C/6D-lite/6E-lite pattern as the model: multiple related slices in one milestone, explicit phase labels, implementation, tests, docs/report, and scene/dev proof where feasible.
- Preserve adapter-first architecture while moving faster.
- Allow dedicated managers only when a system clearly needs authoritative state across multiple mechanics, missions, or result screens.
- Inventory, paper trail, and mission rating/result systems may justify dedicated state systems.
- Suspicion/alert work should extend or wrap `MissionAlertController` before adding any global suspicion manager.
- Treat roadmap systems as complete only when the milestone accounts for runtime code, Resources/data classes, tests, scene proof, template scenes where useful, static validators where useful, docs/report, Mission Dock or authoring integration when relevant, and debug/readability support.
- Use high-risk implementation with guardrails: no broad rewrites, no duplicate managers without justification, no unrelated cleanup, focused tests for each new path, scene/headless smoke when feasible, and clear rollback boundaries.
- Commit after grouped milestones when Jake asks.
- Save Nowledge Mem handoffs after each phase packet inside a grouped milestone.

## Validation

- Documentation-only change.
- `git diff --check` should be run for `AGENTS.md`, roadmap, blueprint, and this report.

## Follow-Up

- Before continuing Phase 4B or later roadmap work, review the new `AGENTS.md` accelerated grouped-milestone mode.
- Phase 4A remains implemented but uncommitted at the time this report was written.
- Next likely grouped milestone after committing Phase 4A: Phase 4B-4D security event scene proof, template/validator, and debug readability.
