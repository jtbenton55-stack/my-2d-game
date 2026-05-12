# GAME-ROADMAP-01 — Phase 2B: Mission Bible Alignment Audit

**Mission Bible file used:** `res://docs/MISSION_BIBLE.md` (Sterling Syndicate Arc, 61 lines).

This phase compares the Mission Bible's intended vision against what the repo actually implements today. Status enums and roadmap impact enums follow the prompt spec.

## 1. Mission Bible's intended vision (summary)

The Sterling Syndicate Arc is an 11-mission heist series structured around one **leverage layer per mission** (delivery routes, blackmail/nightlife, IP/contracts, transport, laundering, vault tribute, muscle, real estate, personal intimidation, hit network, "everything"). Each polished mission should contain:

- 3–5 zones, primary objective chain, one access gate, optional Bentley/Scheme card path
- ≥1 hidden polaroid, ≥1 Glow Guy, ≥1 Tiny Icon, **three poop bag pickups**
- ≥2 stealth angles, ≥1 combat/escape beat, micro-cutscene, mid-mission twist
- One Sterling clue, restart mutation table, one reward card or crew favor

**Global target systems:** polaroids (regular + hidden + perfect-moment), Glow Guys/Desk Spirits, Tiny Icons/Shelf Goblins, Bentley poop bags (utility), evidence clues, lock language, live restart/heat with mutation tables.

**Build/polish order recommended in Bible:**
1. **Phase 1 showcase** — Taco Bell → Jazz Club → Rewrite Room
2. **Phase 2 pacing** — Car Chase, Clean Job, Diamond Job
3. **Phase 3 personality** — Persian Tea, Elephant in the Room, Arm Wrestling
4. **Phase 4 finale** — Shadow Contract, Sterling Tower

## 2. Mission-by-mission alignment

Evidence sources: `src/autoload/GameState.gd:mission_catalog`, `src/missions/*Mission.gd`, `scenes/missions/*.tscn`, `scenes/missions_iso/*.tscn`, `MissionSceneResolver.gd`, recent reports.

| # | Mission Bible | Catalog id | Scenes found | Scripts found | Status | Roadmap impact | Notes |
|---|---------------|------------|--------------|---------------|--------|----------------|-------|
| 1 | Taco Bell Drop | `taco_bell_drop` | `scenes/missions/TacoBellMission.tscn` (legacy classic), `scenes/missions_iso/TacoBellIso_Editable.tscn` (legacy bake), **`scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (playable)** | `TacoBellMission.gd` (classic, unused), `IsoMissionBase.gd` + Phase0J/K stack | **PARTIAL** | **USE_AS_GUIDING_VISION** + **IMPLEMENT_SOON** | Map + framework present; objective reset, Louis bypass, beam-once verification still gaps |
| 2 | Velvet Paw Jazz Club | `velvet_paw_jazz_club` | `JazzClubMission.tscn`, `JazzClubOwnerArena.tscn` | `JazzClubMission.gd`, `JazzClubOwnerArena.gd`, `music_puzzle_trigger.gd`, `owner_suite_stairs.gd`, `ledger_decoy_interact.gd`, `yordano_basement_interact.gd`, `velvet_prop.gd` | **PARTIAL** (LevelBase-style scene with multi-floor logic in `FOLLOWUPS.md`) | **IMPLEMENT_AFTER_TACO_VERTICAL_SLICE** + revise into iso framework | Substantial gameplay but uses old `LevelBase`-style. Phase 4 hostile/stealth logic deferred per FOLLOWUPS |
| 3 | Rewrite Room | `rewrite_room` | `RewriteRoomMission.tscn` | `RewriteRoomMission.gd` | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_MULTI_MISSION_FOUNDATION** | Story-room scaffold |
| 4 | Fast Family Getaway | `fast_family_getaway` | `CarChaseMission.tscn` | `CarChaseMission.gd` | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_POLISH** | "Different gameplay style" — risk of one-off mechanic |
| 5 | Clean Job | `clean_job` | `CleanJobMission.tscn` | `CleanJobMission.gd` | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_MULTI_MISSION_FOUNDATION** | |
| 6 | Diamond a Year Job | `diamond_a_year_job` | `DiamondVaultMission.tscn` | `DiamondVaultMission.gd` | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_MULTI_MISSION_FOUNDATION** | |
| 7 | Arm-Wrestling Underground | `arm_wrestling_underground` | `ArmWrestlingMission.tscn` | `ArmWrestlingMission.gd` | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_POLISH** | Mini-game shape implied; needs design |
| 8 | Persian Tea and Poison Ink | `persian_tea_poison_ink` | `PersianTeaMission.tscn` | `PersianTeaMission.gd` | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_POLISH** | |
| 9 | Elephant in the Room | `elephant_in_the_room` | `ElephantRoomMission.tscn` | `ElephantRoomMission.gd` | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_POLISH** | Bentley/Ellie emotional beat |
| 10 | Shadow Solo Contract | `shadow_solo_contract` | `ShadowSoloMission.tscn` | `ShadowSoloMission.gd` | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_POLISH** | |
| 11 | Sterling Tower (finale) | `sterling_tower_heist` | `SterlingTowerMission.tscn` | `SterlingTowerMission.gd`, `sterling_clue_note.gd`, `VictorSterling.gd` (enemy) | **PLACEHOLDER_ONLY** | **DEFER_UNTIL_MULTI_MISSION_FOUNDATION** | Gated by 9 prerequisites in `GameState._can_unlock_sterling_tower` |

**Catalog vs Bible coverage:** All 11 Mission Bible missions exist as catalog entries + at least scaffold scenes. Only `taco_bell_drop` has a real playable iso surface.

## 3. Core loop — Bible intent vs current repo

| Loop step | Bible intent | Current repo state | Status |
|-----------|--------------|--------------------|--------|
| Hideout → mission launcher | implied | `HideoutHub → HideoutMissionBoardController.launch_taco_bell` working | **IMPLEMENTED_READY** (Taco only) |
| Scheme card draft | implied | `SchemeCardMenu.tscn`, `CardManager`, `GameState.selected_cards`, hideout panel | **IMPLEMENTED_NEEDS_TESTING** in pipeline |
| Mission play | one mechanic + one twist | Taco has gameplay; others are scaffolds | **PARTIAL** |
| Results / reward | crew favor, reward card, polaroid | `LevelBase.complete_level → GameState.complete_mission → MissionResult` | **IMPLEMENTED_READY** but emotional polish missing |
| Return to hideout | implied | `SceneManager.return_to_hideout` working | **IMPLEMENTED_READY** |
| Mission unlock progression | per build order | `GameState._unlock_next_missions` matches Bible branch shape | **IMPLEMENTED_READY** (code only) |
| Route unlocks (Louis etc.) | per mission | `unlock_crew_assist("louis_delivery_route_assist")` on taco success; **not yet used** | **PARTIAL** |
| Heat / failure / replay loop | mutation table per mission | `mission_mutation_state`, `get_or_roll_mission_mutations`, `_update_mission_heat_state` exist; **TacoBellMission.gd's `_apply_taco_bell_mutations` is in classic script, not in the iso playable** | **PARTIAL / STALE_OR_SUPERSEDED** |
| Save persistence | implied | JSON save, version `0.4.0-bible`, schema-validated | **IMPLEMENTED_READY** |
| Evidence/clue progression | per mission | `evidence_clues` + `sterling_clues` dictionaries + `evidence_board.tscn` | **PARTIAL** (UI shell ok; data not flowing yet) |
| Sterling Tower / finale gating | "all clues + 9 prereq missions" | `_can_unlock_sterling_tower` requires 9 specific completions | **IMPLEMENTED_READY** (logic) / **PLACEHOLDER_ONLY** (mission) |
| Character unlocks | crew favors, helped friends | `friend_favors`, `help_friend`, `crew_members` | **IMPLEMENTED_READY** (model) |
| Store / decorating / hideout progression | implied (polaroid gallery, glow shelf) | `HideoutStoreController`, `HideoutDecoratingModeController`, `GlowCollectibleShelf`, `PolaroidGallery` | **IMPLEMENTED_READY** |
| Bentley/Jake/Mere/Louis as anchors | central | Crew default list incl. `jake, bentley`; portraits + dialogue (c2a/c2b passes); Louis route in Taco; Mere "legal eyes" scheme card | **PARTIAL** |

## 4. Mechanic-by-mechanic comparison

| Mechanic | Bible call-out | Repo state | Status |
|---|---|---|---|
| Objectives | primary chain per mission | `QuestManager` + `MissionObjectiveBridge` + `IsoMissionBase._required_objective_ids`; **three writers** | **PARTIAL** |
| Clues / evidence | per-mission "Sterling clue" + board | `GameState.sterling_clues` + `evidence_clues`; `evidence_board.tscn`; bridge stub | **PARTIAL** |
| Scheme cards | meta loadout | `SchemeCardMenu`, `CardManager`, 16+ id-list in `unlocked_cards`; bridges into bonuses (`Polaroid Proof`, `Diamond a Year`) | **IMPLEMENTED_NEEDS_TESTING** |
| Tools — poop bags | utility (evidence cleanup, scent decoy, slip trap) | Aimed throw + `MissionToolSurfaceHelper` + `IsoMissionBase.deploy_poop_bag_decoy_at`; mission counts attempt usage | **IMPLEMENTED_NEEDS_TESTING** |
| Stealth / detection | per mission | `MissionAlertController`, `MissionSecurityCamera`, `MissionLightZone`, `vision_cone.gd`, `StealthSystem.gd` | **PARTIAL** |
| Sprint / dodge / combat | implied | Sprint+stamina (Ctrl/C), Dodge (Space), basic attack + dash + melee hitbox | **IMPLEMENTED_NEEDS_TESTING** |
| Dialogue / portraits | implied (memory dialogue, friend hints) | `DialogueManager`, `DialogueBox`, `DialoguePortraitRegistry`, `HideoutCharacterDialogueBank` | **IMPLEMENTED_READY** (hideout); mission-side mostly hooks |
| Character interactions | crew, friends | hideout NPCs with portraits; `friend_favors` model | **IMPLEMENTED_NEEDS_TESTING** |
| Mission reset/retry | per attempt + heat steps | `IsoMissionBase._reset_attempt_runtime_state`; `MissionObjectiveBridge.reset_runtime_objectives_for_mission` STUB | **PARTIAL** |
| Save/load persistence | implied | JSON 3-slot autosave at mission start/complete/fail | **IMPLEMENTED_READY** |
| Pause menu owns Obj/Scheme/Clues | implied | `pause_menu.gd` (test_ui) reads `MissionPauseDataProvider`; payload covers all three | **IMPLEMENTED_NEEDS_TESTING** |
| Reusable mission module spine | implied | `mission_module_audit` and `pre_taco_module_hardening` established framework; `IsoMissionBase` is the seam | **PARTIAL** |
| Live restart / mutations | per mission table | `MissionMutationHelper` + `mission_mutation_state` + `_apply_taco_bell_mutations` (classic script only) | **PARTIAL / STALE_OR_SUPERSEDED** |
| Lock language (badges/codes/wristbands) | per mission | code gate present; no badge/wristband content yet | **PARTIAL** |
| Polaroids + Glow Guys + Tiny Icons | global | catalog ids per mission; `polaroid_pickup.gd`, `GlowCollectibleShelf` | **PARTIAL** (data + UI; pickups for Taco only) |

## 5. Character / emotional anchor comparison

| Bible expectation | Repo state |
|---|---|
| **Bentley** central, emotional anchor | `DogCompanion.gd` spawned by `LevelBase`; case_the_joint Bentley ability; Bentley care station in hideout; Elephant in the Room → `ellie_polaroid`; **IMPLEMENTED_READY (mechanics) / PARTIAL (story moments)** |
| **Jake** | hideout NPC + scheme card `jakes_resident_orders`; failure boost dialogue flag | **IMPLEMENTED_NEEDS_TESTING** |
| **Mere** | scheme card `mere_legal_eyes`, hint in Taco (`_try_mere_legal_bypass`); portrait | **PARTIAL** |
| **Louis** | exit/route, scheme card `louis_delivery_route`, hideout NPC, Phase0K Louis exit interactable | **IMPLEMENTED_READY (mechanics) / PARTIAL (gameplay parity for bypass)** |
| Yordano, Bryce, JC, Violet, Jinx, Eren, Kiro, Jin, Dom | hideout/character refs + mission-specific scripts | **PLACEHOLDER_ONLY** for most |

## 6. Alignment score

| Dimension | Score (0–5) | Reasoning |
|---|---|---|
| Mission catalog coverage | **4/5** | All 11 missions present as ids/scaffolds |
| Framework alignment (Bible's "reusable spine") | **2.5/5** | Pieces exist; convergence (objective ownership, attempt reset, Louis bypass parity) not done |
| Single-mission depth | **3/5** | Taco has lots of moving parts; not yet end-to-end clean |
| Content depth across catalog | **1/5** | Only Taco has real iso content; others are story-room placeholders |
| Global systems (clues, polaroids, glow guys, mutations) | **2.5/5** | Data layer there; population/wiring only partial |
| Emotional anchors | **3/5** | Hideout + dialogue + Bentley present; mission moments missing |
| Mission Bible currency | **4/5** | Still represents the best guiding vision; mostly accurate |

**Overall rating:** **Partial alignment, with the framework + Hideout strong and the mission content very thin.**

## 7. Biggest gaps between plan and current repo

1. Only one mission is actually playable.
2. The Bible's "reusable mission spine" is half-built — Phase0J/K stack is named generic but scoped to Taco.
3. Heat/mutation system designed in Bible exists in code but is **only wired in the legacy classic Taco script**, not in the iso playable.
4. Bible's Phase 1 showcase (Taco → Jazz → Rewrite) is bottlenecked because Jazz and Rewrite are not on the iso framework yet.
5. Restart/heat loop not proven on the playable Taco.
6. Lock language (delivery badges, VIP wristbands, ledger shards) not implemented beyond the Taco code gate.
7. Mission "result" UX doesn't yet emotionally close a run.

## 8. Mission Bible ideas that should still guide development

- **"One mechanic, one emotional flavor, one map shape, one conspiracy clue per mission"** — perfect razor for Taco vertical slice quality.
- **Recommended build order** Phase 1 → 4 (Taco, Jazz, Rewrite first) — directly maps to roadmap below.
- **Sterling steals leverage, identity, authorship, safety, belonging — not only money** — gives missions different "feels" and prevents mechanical sameness.
- **Per-mission checklist** (3–5 zones, primary chain, gate, optional path, hidden polaroid, glow guy, tiny icon, 3 poop bags, ≥2 stealth angles, ≥1 combat/escape beat) — use as a literal acceptance checklist for new missions.
- **Sterling Tower as convergence of clues + favors** — protects the finale from "boss arena only" syndrome.
- **Bentley emotional anchor** — Elephant in the Room is the keystone late mission; preserve.

## 9. Mission Bible ideas that are stale or should be revised

- Bible doesn't mention the **isometric framework** decision; the build order implicitly assumed `LevelBase`-style rooms. New roadmap should clarify each Phase 1 mission belongs on `IsoMissionBase` (or its successor) once extracted.
- **"Live restart / heat"** assumed per-mission mutation tables; current implementation has `mission_mutation_state` but only `_apply_taco_bell_mutations` is populated. Revise to require a small mutation table per Phase-1 mission.
- The Bible references **Glow Guys / Desk Spirits / Tiny Icons / Shelf Goblins** as flavor names; the code uses the legacy IDs (`taco_bell_smiskis` → `taco_bell_glow_guys`) — keep migration map (`POLAROID_LEGACY_IDS`) but ensure new mission ids match Bible naming.
- **Friend Yordano/JC/Violet** quirks may need lighter scope than originally drafted.

## 10. Mission Bible ideas that should be deferred

- Full Phase 2/3/4 missions until the Phase 1 showcase has a clean, polished slice.
- Full procgen mutation system per mission (Bible already says "small mutation tables, not full procgen" — keep it small).
- Music puzzle / screenwriting puzzle complexity until Jazz Club / Rewrite Room reach iso framework.
- Sterling Tower full design until at least 3 missions complete (otherwise prereq logic guards nothing meaningful).

## 11. Conflicts between Mission Bible and newer reports/code

- **Bible places `TacoBellMission.tscn` (classic story room) as primary; D1C confirms `TacoBellIso_Editable_RedesignTest.tscn` is the actual playable.** Bible should be amended to acknowledge the iso framework.
- **D1B "canonical = Editable.tscn" decision conflicts with current code** — D1C / current resolver win. Future Bible/decision docs should match.
- **`README.md` "5 unique missions complete" conflicts with both the Bible and reality.** README needs rewrite or removal.

## 12. What the Mission Bible implies the next roadmap should prioritize

1. Finish a clean Taco vertical slice (objective reset, Louis bypass parity, beam once, return-to-hideout celebration).
2. Then build Jazz Club on the iso framework (it has the second-most existing content).
3. Then build Rewrite Room on the iso framework (third Phase 1 showcase mission).
4. Migrate global systems (mutations, polaroids, glow guys, tiny icons) into the reusable mission spine as part of those builds.
5. Keep finale + later missions deferred until Phase 1 ships.

## 13. Recommended treatment of the Mission Bible going forward

- **Treat the Bible as the guiding vision document, not as a build manual.**
- After Phase 1 stabilizes, add a one-page **Bible Addendum** that maps each mission to the iso framework + per-mission checklist + lock language item.
- Use the per-mission checklist verbatim as the acceptance criteria for "is this mission ready to leave PARTIAL state."

## 14. Hard assertions

- `mission_bible_searched`: **true**
- `mission_bible_found_or_missing_reported`: **true** (found at `docs/MISSION_BIBLE.md`)
- `mission_bible_alignment_audit_created`: **true**
- `mission_list_compared_to_repo`: **true**
- `core_loop_compared_to_repo`: **true**
- `roadmap_implications_extracted`: **true**

See `phase2b_mission_bible_alignment_audit.json`.
