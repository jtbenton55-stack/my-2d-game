# Velvet Paw Route Component 1

Date: 2026-07-11

## Outcome

Implemented the complete exterior approach packet as a grouped milestone while preserving the existing 68-slot mission architecture and source TileMap payloads.

Player routes:

- Normal access: timed bouncer rejection -> queue eavesdrop -> east alley -> fixed-open staff entrance.
- VIP access: F12 QA selector or future Taco entitlement projection -> front inspection -> dynamic crowd rope opens -> front-entry trigger advances the same `vpj_entered_club` fact.

## Runtime Contracts

- Future Taco entitlement ID: `velvet_paw_vip_access`.
- Velvet cover fact: `velvet_paw_vip_guest`.
- Velvet credential fact: `velvet_paw_vip_wristband`.
- F12 selection is attempt-local and does not create a persistence/save schema.
- Normal access removes only those two Velvet VIP facts.
- The queue inspection requires both facts and zero incriminating weight.

## Presentation

- Timed dialogue metadata is opt-in per line through `auto_advance_seconds`, `allow_manual_advance`, and `allow_skip`.
- The front sequence displays `Bouncer: You're not on the list.` for 2.5 seconds, then `Bentley: Do they know who I am?!` for 2.5 seconds, then dismisses without E.
- Enter closes any open dialogue, including timed lines that disable E advance and Skip.
- Existing manually advanced dialogue remains unchanged.
- Replacement dialogue invalidates old timers.
- No-key `DialogueTriggerZone` fallback presentation now supplies its authored text correctly.
- The alley fallback is `There are too many colognes. And none of them smell as good as my expression.`
- Queue eavesdrop completion displays the staff-door discovery in the dialogue box.
- The VIP phone displays the assistant voicemail and grants `velvet_paw_vip_voicemail_copy`.
- The alley dead drop consumes that copy, sets `vpj_vip_voicemail_copy_dropped`, and confirms Mere can retrieve it.

## VIP Phone

The phone remains inside Velvet Paw at `(2816, 2304)` in the VIP booth area. It is not in Taco Bell and not in the alley. The player approaches and presses E. Its information points toward the green-room staff badge; it does not grant front-door VIP access.

## Interaction And Hints

- `MissionInteractionBridge` now owns E interaction only; Q cannot activate mechanics.
- The bridge refreshes the existing HUD control hint every 0.20 seconds while a prompt target is configured.
- Player Q keeps the existing Case the Joint pulse and requests one mission-local hint provider.
- `CaseHintDefinition` supports RequirementSet, anchor distance, priority, text, speaker, and cooldown.
- `MissionCaseHintProvider` makes deterministic authored-order selections and emits `EventBus.case_hint_requested`.
- HUD presents a temporary non-blocking toast without replacing objective state or opening dialogue.
- Component 1 authors VIP-front, queue-listening, and post-eavesdrop alley hints.

## Collision

The source collision payload remains unchanged:

- Wall cells: 1,420.
- Collision-barrier cells: 446.
- Source blocking union: 1,996.

The 12 authored cells covering `front_entrance_crowd_rope` are listed in `layout_collision_excluded_cells`. Runtime compact collision omits those cells and the wall proxy omits the two overlapping wall cells. A mission-local `FrontEntranceCrowdRopeBlocker/RopeShape` replaces them.

Runtime result:

- Compact static collision cells: 1,984.
- Wall proxy polygons: 1,418.
- Dynamic blocker bodies: 6.
- Dynamic shapes: 7.

Passing the VIP inspection disables the rope shape and hides the visible rope line. Source paint and blueprint analysis remain available as authoring evidence.

## Area Visibility

- Seven mission-local, non-colliding room curtains preserve the complete map while concealing inactive regions.
- Only the player's current street, main-floor, bathroom, stage, backstage, owner-suite, or basement region is revealed.
- Doorway bands retain the previous valid region; teleport success signals refresh visibility immediately.
- HUD and dialogue remain above the world curtains.

## Main Files

- `scenes/missions_iso/VelvetPawJazzClub_Editable.tscn`
- `src/autoload/DialogueManager.gd`
- `src/ui/DialogueBox.gd`
- `src/missions/iso/presentation/DialogueTriggerZone.gd`
- `src/missions/iso/social/SocialStealthAdapter.gd`
- `src/missions/iso/runtime/MissionQAChecklistPanel.gd`
- `src/missions/iso/runtime/authoring/MissionInteractionBridge.gd`
- `src/missions/iso/runtime/readability/CaseHintDefinition.gd`
- `src/missions/iso/runtime/readability/MissionCaseHintProvider.gd`
- `src/player/Player.gd`
- `src/ui/HUD.gd`
- `src/utils/EventBus.gd`
- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/LayoutWallCellCollisionGenerator.gd`
- `docs/blueprints/velvet_paw_jazz_club.blueprint.json`
- `docs/blueprints/velvet_paw_jazz_club.build_guide.md`

## Validation

- Timed dialogue focused suite: 8/8 PASS.
- Case the Joint provider: 6/6 PASS.
- MissionInteractionBridge regression: 14/14 PASS.
- Route Component 1 behavior: 4/4 PASS, zero errors/failures/orphans.
- Velvet physics: 10/10 PASS, zero errors/failures/orphans.
- Production skeleton repair run reached 17 tests with only the newly added dialogue fallback assertion failing; fallback was then authored and is included in the final rerun gate.
- Godot editor import loaded the changed scripts and production scene.
- `git diff --check`: PASS apart from the existing build-guide line-ending warning.

Post-playtest polish gate:

- Timed-dialogue/Enter behavior and exact alley copy are regression-covered.
- Runtime area visibility: 8/8 PASS across all seven authored regions.
- Production skeleton: 19/19 PASS.
- Full `tests/mission_authoring`: 474/474 PASS across 61 suites, zero errors, failures, skips, flakes, or orphans.
- Blueprint validator: PASS across all three specs and 55 mechanic types, no failures or warnings.
- Direct 120-frame production-scene headless smoke: exit 0.
- Detail report: `reports/ai/2026-07-11_velvet_paw_route_component_1_polish_report.md`.

Final gates:

- Production skeleton: 19/19 PASS.
- Runtime QA: 7/7 PASS, including dynamic VIP rope and front-entry traversal.
- Level blueprint layout painter: 9/9 PASS after updating the front opening expectation from permanent/crowd-rope to dynamic/VIP-social-gate.
- Full `tests/mission_authoring`: 472/472 PASS across 61 suites, zero errors, failures, skips, flakes, or orphans.
- Blueprint validator: PASS across all three blueprint specs, 55 mechanic types, no failures or warnings.
- Direct headless production-scene smoke for 120 frames: exit 0; the mission started, runtime systems loaded, and the scene shut down cleanly. The existing editor/runtime process already owned MCP port 9090, so the smoke logged the expected non-fatal bind warning.
- `git diff --check`: PASS apart from the existing build-guide line-ending warning.

## Manual QA

Manual production confirmation is still required for:

1. Normal spawn -> automatic bouncer/Bentley timing -> queue eavesdrop -> alley entry.
2. F12 -> VIP guest + wristband -> E at inspection -> rope visual/collision opens -> front entry.
3. Nearby prompts while entering and leaving interaction range.
4. Q hint readability and cooldown at the front queue and alley.
5. VIP phone E interaction, return to alley, and dead-drop confirmation.
6. Rope placement/readability against the eventual production art.

## Next Component

After manual confirmation, proceed one route component at a time with **2. Explore the Club Floor**.
