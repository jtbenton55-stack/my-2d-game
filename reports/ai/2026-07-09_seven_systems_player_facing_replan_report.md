# Seven Systems Player-Facing Replan - Implementation Report

- Date: 2026-07-09
- Agent: Cursor (implementation/debugging)
- Milestone: "Player-Facing Replan: The Seven Pressure Systems" (grouped-milestone mode, 6 packets)
- Plan: `.cursor/plans/seven_systems_player-facing_replan_9ee29f3c.plan.md` (not modified)

## Summary

Implemented all six replan packets converting the seven adapter-backed dev-menu systems
(inventory, social/professional, noise/stealth, paper trail, cleanliness, reactive NPC,
heat scanner) into a player-facing pressure economy: NOW (noise/stealth), SOON
(witnesses/cover), LATER (traces/mess -> Investigation Report), META (venue heat ->
next-mission difficulty + hideout scanner radio).

## Packet 1 - Interaction and readability layer

- `src/missions/iso/authoring/mechanics/MechanicAreaBase.gd`: hold-interact channel
  (exported `interact_duration`, radial progress arc, interrupt on movement, optional
  alert exposure on interrupt via `interrupt_alert_exposure`). Instant interact preserved
  when duration is 0.
- New `src/missions/iso/runtime/readability/`:
  - `NoisePulseVisualizer.gd` - expanding rings for every `EventBus.mission_noise_emitted`.
  - `NpcAlertPipVisualizer.gd` - ?/! pips over `enemy` group by reaction/alert state.
  - `MissionCasingOverlay.gd` - hold `case_the_joint` (Tab, registered at runtime) shows
    paper traces, mess spots, noise memory, and a cover summary near the player.
  - `MissionReadabilityLayer.gd` - composer, auto-mounted by `IsoMissionBase`.

## Packet 2 - Player kit

- `ItemData.gd` / `InventoryEntry.gd`: new `incriminating: int (0-5)` and `bulky: bool`.
- `MissionInventory.gd`: `get_incriminating_total()`, `has_bulky_item()`.
- `InspectionRuleSet.gd`: optional `max_incriminating` pocket check.
- New `src/missions/iso/runtime/kit/`:
  - `HeistKitHud.gd` - 8-slot bar (4 loadout / 4 mission), incriminating/bulky tinting.
  - `PlayerFootstepNoiseEmitter.gd` - sneak/walk/run noise tiers; bulky items widen radius.
  - `KitDecoyThrower.gd` - G throws `decoy_coin` toward mouse, consumes item, emits decoy noise.
  - `MissionPlayerKitLayer.gd` - composer, auto-mounted by `IsoMissionBase`.

## Packet 3 - Cover runtime

- New `src/missions/iso/runtime/cover/`:
  - `CoverMeterRuntime.gd` - professionalism drains for running indoors and heavy
    incriminating carry; alibi window registry (`register_alibi_window`).
  - `CoverChallengePrompt.gd` - Bluff / Excuse / Deflect-to-Bentley (keys 1/2/3),
    gated by cover-story/credential facts; exposure decay or bump.
  - `MissionCoverLayer.gd` - composer, auto-mounted by `IsoMissionBase`.
- `BelievableTaskZone.gd`: `alibi_window_seconds`, `repeat_cooldown_seconds` (repeatable alibi stations).
- New `src/missions/iso/ai/RoamingInspectorNpc.gd` - timed rounds, walks to player,
  evaluates `InspectionRuleSet`, alibi bypass, confiscation + challenge on fail.

## Packet 4 - Trace and mess loop

- New `src/missions/iso/runtime/mess/MessSpotNode.gd` - physical mess (group
  `mission_mess`), hold-clean = cleanliness + professionalism + alibi + optional
  Clorox-protocol trace wipe radius; `spawn_mess()` static helper.
- `PaperTrailAdapter.gd`: trace hardening (`default_hardening_seconds`,
  `is_trace_hardened`, cleanup rejects hardened traces with `paper_trace_hardened`).
- New `src/missions/iso/runtime/report/InvestigationReportBuilder.gd` - post-mission
  report (verdict, headline, prime suspect, narrative lines, heat_delta 0-5).
- `GameState.gd`: mission results annotated with `investigation_report`; report heat
  stored in `venue_heat`; `get_mission_heat()` = max(report heat, failed attempts);
  `cool_venue_heat()`. `MissionResult.gd` renders the report card.

## Packet 5 - Witness counterplay

- New `src/missions/iso/ai/WitnessNpc.gd` - scan -> notice (?) -> walk to report point
  (!) -> file report (signal + witness trace + exposure); distracted by player decoy/bark
  noise; stands down if mess is cleaned first; gossip-lite (one hop, faster notice).
- New `src/missions/iso/authoring/mechanics/PhoneSabotageNode.gd` - hold-sabotage a
  report point; witnesses arriving there give up; leaves an `audit_log` trace.

## Packet 6 - Heat meta loop

- New `src/hideout/HeatScannerRadio.gd` - police-band readout per venue (0-5 dial,
  chatter escalates with heat) + `run_cooldown_shift()` (-2 heat, only for worked
  venues, cannot cool below the failed-attempt floor).
- `HideoutStationCatalog.gd`: Heat Scanner station now has "Listen to the Radio" and
  "Run Cool-Down Shift" buttons; new `cool_down_shift` allowed action; radio copy.
- `HideoutManager.gd`: handles `view_heat` (radio readout) and `cool_down_shift`.
- `HideoutMissionBoardController.gd`: briefing heat line ("Heat: 3/5 - jumpy staff,
  extra patrol pressure...") always shown for the selected mission.
- `IsoMissionBase.gd`: `_apply_venue_heat_seed()` lowers the alert controller noise
  threshold at hot venues (jumpier staff). Existing heat-driven security spawn cap
  (4+heat), reinforcement cooldown, and search roles now receive report-driven heat
  automatically through `get_mission_heat()`.

## Validation

- GdUnit4 (headless, Godot 4.6.2 console binary): 47/47 tests pass across
  `ReplanPacket1ReadabilityTest` (8), `ReplanPacket2HeistKitTest` (9),
  `ReplanPacket3CoverRuntimeTest` (9), `ReplanPacket4TraceMessTest` (7),
  `ReplanPacket5WitnessTest` (7), `ReplanPacket6HeatMetaTest` (7).
- Godot MCP Pro runtime smoke (HideoutHub.tscn live): scanner radio readout rendered
  correct dial/chatter for seeded heat 3; `cool_down_shift` through the real
  `HideoutManager` action path lowered heat 3 -> 1 with panel feedback (screenshot
  taken); briefing line reflected live heat.

## Risks / follow-ups

- Trace hardening defaults to disabled (`default_hardening_seconds = 0`); missions must
  opt in.
- Cool-down shift is currently an instant hideout action, not a playable mission
  variant; the playable variant remains future content.
- New input actions (`case_the_joint`, `kit_throw_decoy`) are registered at runtime,
  not in project.godot.
- Manual QA recommended for production Taco Bell mission before any milestone commit
  (per accelerated-milestone guardrails).
- `MilestoneAProofMission.tscn` had a pre-existing uncommitted modification before this
  milestone started; untouched by this work.

## Grouped-milestone mode statement

Work stayed in grouped-milestone mode throughout: six packets, each spanning runtime
code + resources + tests, no fallback to narrow slices was needed. No rewrites; all
changes extend `MechanicAreaBase`, the existing adapters, `MissionAlertController`
inputs, and `GameState` heat.
