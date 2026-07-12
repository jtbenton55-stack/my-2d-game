# Velvet Paw Jazz Club — Full Mission Build Spec (Phases 1–6)

Working spec for the single-pass build of `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`.
If your context is compacted mid-run, RE-READ THIS FILE instead of asking for the prompt again.

Repo rules: follow `AGENTS.md`. Do not git commit. Do not modify `src/missions/JazzClubMission.gd`
or `scenes/missions/JazzClubMission.tscn`. Do not paint tiles. No unrelated cleanup.

## Source-of-truth files

- Blueprint spec (68 slots): `docs/blueprints/velvet_paw_jazz_club.blueprint.json`
- Build guide (parents, per-slot notes): `docs/blueprints/velvet_paw_jazz_club.build_guide.md`
- Scene + wiring style to mirror: `scenes/missions_iso/CornerStoreCashout_Editable.tscn`
- Controller to mirror: `src/missions/iso/runtime/CornerStoreCashoutMissionController.gd`
- Requirement/effect sub-resource examples: `scenes/dev/mission_authoring/MilestoneAProofMission.tscn`
- Mission Dock rules: `addons/mission_dock/MissionDock.gd` (MECHANIC_SCRIPTS, ID_PROPERTY_BY_TYPE)
- Coverage check: `src/tools/authoring/LevelBlueprintSpec.gd`
- Dialogue zone exports: `src/missions/iso/presentation/DialogueTriggerZone.gd`
- Legacy dialogue/beat source (read-only): `src/missions/JazzClubMission.gd`
- Test to mirror: `tests/mission_authoring/CornerStoreCashoutProductionSkeletonTest.gd`

## Canonical flag vocabulary (do not invent alternates)

```
vpj_eavesdrop_done, vpj_alley_intro_done, vpj_entered_club,
vpj_bar_task_done, vpj_vip_voicemail_found,
vpj_staff_badge_collected, vpj_staff_gate_open,
vpj_clue_setlist_read, vpj_clue_manager_read, vpj_soundcheck_done,
vpj_decoy_ledger_found, vpj_setlist_solved, vpj_backstage_hatch_open,
vpj_yordano_briefed, vpj_vault_power_rerouted, vpj_server_vault_open,
vpj_shard_collected, vpj_owner_stairs_open, vpj_owner_defeated,
vpj_briefcase_collected, vpj_escape_hatch_open, secret_velvet_collectible
```

GameState globals (already exist; set via mission controller):
`velvet_paw_club_hostile`, `velvet_paw_basement_shard_collected`, `velvet_paw_basement_keycard_collected`.
Sterling clue on setlist success: `jazz_club_encoded_setlist` (GRANT_EVIDENCE_CLUE).

## PHASE 1 — Scene shell + overlay

- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`, root uses `IsoMissionBase.gd`,
  `auto_generate_from_definition = false`, `mission_definition` = new .tres below.
- Node tree mirrors Corner Store: GameplayRoot (LayoutRoot with Floor/Wall/Cover/CollisionBarrier/MarkerTile
  layers + AuthoringBlueprintLayer at (0,0) pointing at the blueprint JSON, opacity 0.35),
  GameplayFloor/Collision/Markers layers, EntityRoot (Enemies, Interactables), SpawnPoints/default
  Marker2D at (256, 2880), MarkerRoot/Spawns, SecurityAuthoringRoot, RuntimeHelpers
  (MissionInteractionBridge include_legacy_candidates=false, MissionAlertController
  mission_id="velvet_paw_jazz_club", VelvetPawJazzClubMissionController in Phase 5),
  MissionMechanics; ArtRoot layers; Camera2D limits covering 4480x3200.
- `assets/missions/velvet_paw_jazz_club_definition.tres` mirroring corner store definition
  (mission_id velvet_paw_jazz_club, authoring_mode scene_authored, implementation_status production_skeleton).
- GameState catalog: add `"playable_iso_scene": "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"`
  to the velvet_paw_jazz_club entry; keep legacy scene_path.
- GATE 1: scene instantiates clean; MissionSceneResolver resolves to the new path.

## PHASE 2 — Place all 68 stubs

- One node per blueprint mechanic_slot. Node type per Mission Dock rules (Area2D+CollisionShape2D for
  zones; Marker2D for PlayerStartMarker/TeleportTargetMarker; Node for EncounterController/
  ProfessionalismMeterNode/PresentationSequencePlayer; Node2D for security/collectible authors).
- Name: `{MechanicType}_{suggested_id dots->underscores}`. Parent: MarkerRoot/Spawns for player start;
  SecurityAuthoringRoot for security/collectible author types; MissionMechanics otherwise.
- Position from slot; collision size from slot (default 96x96). ID property = suggested_id per
  ID_PROPERTY_BY_TYPE. mission_id_override = "velvet_paw_jazz_club" where supported.
- GATE 2: LevelBlueprintSpec.coverage() = 68/68 placed, 0 missing, 0 mismatched.

## PHASE 3 — Wiring

- RequirementSet/MissionRequirement sub-resources for gates (fact_type mission_flag, operator exists),
  EffectSet/MissionEffect for outcomes; built-in searched_flag/collected_flag/unlocked_flag where sufficient.
- Critical chain: side_door_entry sets vpj_entered_club; bar_task sets vpj_bar_task_done;
  vip_phone_search sets vpj_vip_voicemail_found; staff_badge_pickup (req voicemail, soft) sets
  vpj_staff_badge_collected; staff_gate (req badge) sets vpj_staff_gate_open; clues/soundcheck/lockers
  req gate open and set their flags; backstage_crate_search (req both clues) sets vpj_decoy_ledger_found;
  setlist_terminal (req both clues) success sets vpj_setlist_solved + GRANT_EVIDENCE_CLUE
  jazz_club_encoded_setlist + opens backstage_hatch + triggers stage_presentation, failure fires
  wrong_note_alarm (8s reinforcements via alarm_spawn); backstage_hatch sets vpj_backstage_hatch_open;
  basement_teleport (req hatch) -> basement_arrival; yordano_dialogue one-shot sets vpj_yordano_briefed;
  vault_power (req briefed) sets vpj_vault_power_rerouted; server_vault (req power) sets
  vpj_server_vault_open; ledger_shard (req vault) sets vpj_shard_collected (controller also sets
  GameState shard flag); return_teleport (req shard) -> return_marker + controller flips
  velvet_paw_club_hostile; owner_stairs (req hostile + keycard) sets vpj_owner_stairs_open;
  suite_teleport -> suite_arrival; owner_encounter sets vpj_owner_defeated; briefcase_reward
  (req defeated) sets vpj_briefcase_collected; shelf_goblin_secret (req briefcase) sets
  secret_velvet_collectible; escape_route (req briefcase) sets vpj_escape_hatch_open;
  extraction requires vpj_escape_hatch_open.
- Teleport pairs cross-linked: basement_teleport->basement_arrival, return_teleport->return_marker,
  suite_teleport->suite_arrival (zone target_id = marker target_id).
- GuardPatrolRouteAuthor: 2-4 Waypoint child Node2Ds per route; GuardSpawnAuthor.route_id linked.
  Optional slots (poop bags, glow guy, dead_drop, bug_plant, hidden_polaroid, suite_stash,
  lights_disruption, scheme_card_bassdrop, music zones, professionalism feeds): simple built-in wiring.
- GATE 3: scene instantiates clean; run
  `python src/tools/editor/level_blueprint/level_blueprint_validator.py` and
  `python src/tools/editor/phase2k_mission_dock_static_validator.py` (both PASS).

## PHASE 4 — Dialogue

Use DialogueTriggerZone `fallback_speaker`/`fallback_text` (or dialogue_key if registered) plus
per-mechanic prompt_text/found_message/locked_prompt_text. Voices: Parmida dry, Bentley parenthetical
barks, Yordano stoic-funny (see assets/dialogue/yordano.json). Required content:

1. alley_dialogue — Bentley: "There are too many colognes. And none of them smell as good as my expression."
2. queue_eavesdrop — patrons hint the staff side door propped open between sets.
3. vip_phone_search found_message — assistant voicemail: "Shred before midnight" + badge in green room.
4. clue_setlist note (legacy): "Album arc tonight—start where we started hungry, ballad in the middle
   breath, end where the jury listens."
5. clue_manager_notes (legacy): "Setlist policy: five songs only—follow the release timeline, not the
   merch table. If an extra title sneaks in, it's wrong even when it rhymes."
6. stage_presentation — Yordano: "House lights love you. Don't waste the downbeat."
7. wrong_note_alarm coaching — Yordano: tuck behind the bar / melt into the dance floor silhouette.
8. yordano_dialogue (basement, legacy): "That hum is the vault handshake. I green-lit it—go pull
   Sterling's purple shard before lawyers remote-wipe."
9. bathroom_bark — "(Bentley respects the grout lines.)"
10. briefcase_reward prompt — "Grab it and don't admire the view."
11. Hostile-flip line on return_teleport; escape cue on escape_route; decoy-ledger twist on
    backstage_crate_search.

GATE 4: scene instantiates clean; every DialogueTriggerZone has non-empty fallback text or valid key.

## PHASE 5 — Mission controller

`src/missions/iso/runtime/VelvetPawJazzClubMissionController.gd` mirroring the Corner Store controller:
mission_id "velvet_paw_jazz_club"; sync_from_mission_facts() reads vpj_* flags into typed vars;
reset_attempt_state(); owns GameState side effects (shard pickup -> velvet_paw_basement_shard_collected,
keycard -> velvet_paw_basement_keycard_collected, shard+upstairs return -> velvet_paw_club_hostile);
phase-appropriate QuestManager objective text (reuse legacy strings). Add node under RuntimeHelpers.
GATE 5: script validates; scene instantiates with controller attached.

## PHASE 6 — Tests, validation, report

`tests/mission_authoring/VelvetPawJazzClubProductionSkeletonTest.gd` (mirror Corner Store test):
- Scene loads; bridge exists include_legacy_candidates=false; alert + mission controllers exist;
  AuthoringBlueprintLayer under GameplayRoot/LayoutRoot with correct blueprint_path.
- Resolver returns new scene path.
- Blueprint coverage 68/68, 0 missing, 0 mismatched.
- Flag chain: vpj_staff_badge_collected gates staff_gate requirement (blocked before, allowed after).
- Extraction blocked before vpj_escape_hatch_open, allowed after.
- Controller sync_from_mission_facts() reflects flags.

Run: both python validators + VelvetPawJazzClubProductionSkeletonTest +
MissionSceneResolverCatalogTest + full mission_authoring GdUnit suite. Report actual results.

Write `reports/ai/2026-07-09_velvet_paw_full_mission_build_report.md`: files created/changed,
per-phase status, coverage evidence, test results, flag table as wired, deferrals, manual QA
checklist for Jake. Save a Nowledge Mem handoff (HTTP API http://127.0.0.1:14242 if nmem CLI missing).

## Acceptable deferrals (report them, don't fake them)

- Owner boss-arena scene transition (ChallengeObjectiveNode stub setting vpj_owner_defeated is fine).
- Setlist puzzle mini-game UI (TerminalHackNode success/fail contract is the requirement).
- Professionalism numeric tuning, patrol timing polish, scheme-card stun VFX.
- Tile painting and art.

## Success criteria

Overlay aligned to all 68 stubs; coverage 68/68; validators PASS; GdUnit green; critical chain
(entry -> badge -> gate -> clues -> setlist -> basement -> shard -> hostile -> stairs -> briefcase
-> escape) walkable via wired flags.
