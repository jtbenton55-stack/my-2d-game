# Mission Bible v2 (Sterling Syndicate Arc)

Design source of truth for the story arc, mission catalog, and side content. Implementation uses `LevelBase`/`IsoMissionBase`, `GameState.mission_catalog`, `CollectibleManager`, `QuestManager`, and per-mission scripts under `src/missions/`.

Supersedes Mission Bible v1 (2025 planning draft). Key changes: named protagonist arc, 3-act structure, all 9 major missions canonical, new Night Jobs side track, cool-down shift replay mechanic, naming reconciliation with code ids.

## Premise

**Parmida** wants to be a crime lord. Not a dangerous one — she wants the *legend*: the style, the respect, the name whispered in Nocturne City. Her partner is **Bentley**, her aloof black Shiba Inu, who judges her methods but never misses a job.

The joke the whole game leans on: every "crime" Parmida pulls is secretly a favor. She cases a joint and ends up fixing the owner's problem. She builds a syndicate and it turns out to be a friend group.

**Victor Sterling** is what an actual crime lord looks like: he owns delivery routes, nightclubs, law firms, garages, showrooms, and vaults, and he steals leverage, authorship, safety, and belonging from ordinary people — not only money. As Parmida's legend grows, the city keeps pointing her at people Sterling has hurt, and Sterling starts to see her as competition.

**Character arc:** Parmida chases the title (Act 1) → meets the man who really holds it and hates the mirror (Act 2) → takes him down, not for territory but for her friends, and redefines the title on her own terms (Act 3).

> Some empires are built on fear. Hers was built on favors.

## Legal-safe product stand-ins

Do **not** use real collectible brand names or likenesses in copy or assets. In-universe terms:

| Inspiration (vibe only) | In-game names |
|---------------------------|----------------|
| Glow-in-dark mini figures | **Glow Guys**, **Desk Spirits** |
| Stylized shelf figures | **Tiny Icons**, **Shelf Goblins**, **Little Weirdos** |

Polaroid-style IDs in code: `taco_bell_glow_guys`, `velvet_shelf_goblins` (legacy save IDs migrate via `GameState.normalize_polaroid_id`).

## Story structure — three acts, nine missions, one finale

All nine major missions are canonical story content and all are required to unlock the Sterling Tower finale (matches `GameState._can_unlock_sterling_tower()`).

### Act 1 — "Small Favors" (chasing the legend)

Parmida is hustling for reputation. Sterling is background noise — a name on invoices.

| # | Mission | Catalog id | Friend | Sterling controls | Clue reveals |
|---|---------|-----------|--------|-------------------|--------------|
| 1 | Taco Bell Drop | `taco_bell_drop` | Louis | Delivery routes, safehouse logistics | Secret packets through ordinary delivery |
| 2 | Velvet Paw Jazz Club | `velvet_paw_jazz_club` | Yordano | Blackmail, nightlife, private ledgers | Data hidden in performance/music systems |
| 3 | Rewrite Room | `rewrite_room` | Mere | Law firms, IP theft, contracts | Creative ownership stolen legally |

- Night Job on-ramp: **Corner Store Cashout** (`corner_store_cashout`) precedes or accompanies Taco Bell Drop as the tutorial-scale first favor.
- Plant the Bentley/Ellie setup during Act 1 (Taco Bell mission beat + hideout dialogue) so Elephant in the Room lands as a payoff.
- **Act break beat (after Rewrite Room):** the clue board connects three jobs to one name, and Sterling notices her — an intercepted note that reads like a rival's welcome. He thinks she is muscling into *his* rackets. Parmida is briefly flattered. The crew is not.

### Act 2 — "The Squeeze" (meeting the real thing)

Sterling pushes back the way a real crime lord does — through systems, not violence.

| # | Mission | Catalog id | Friend | Sterling controls | Clue reveals |
|---|---------|-----------|--------|-------------------|--------------|
| 4 | Clean Job | `clean_job` | Jinx | Luxury showrooms, laundering | Physical erasure of crime traces |
| 5 | Diamond a Year Job | `diamond_a_year_job` | Bryce | High-value vaults, tribute assets | Fifteen diamonds — one for each year of stolen work |
| 6 | Fast Family Getaway | `fast_family_getaway` | Dom | Cars, garages, transport | Evidence via modified vehicles / routes |

- **Fast Family Getaway design note:** this is a stealth mission with a timed escape finale (exfiltration to Dom's idling car under escalating pressure) — *not* a separate driving genre. The mission formerly labeled "Car Chase" in v1 is this mission; the canonical id is `fast_family_getaway`.
- **Midpoint reversal beat (after Fast Family Getaway):** Sterling retaliates personally — the threat reaches the hideout and the crew, and reveals he holds Ellie, Bentley's lost companion. Parmida's ambition stops being about the title.

### Act 3 — "What He Can't Buy" (the title, redefined)

| # | Mission | Catalog id | Friend | Sterling controls | Clue reveals |
|---|---------|-----------|--------|-------------------|--------------|
| 7 | Persian Tea and Poison Ink | `persian_tea_poison_ink` | JC | Culture, real estate, community | Takeover of meaningful community spaces |
| 8 | Elephant in the Room | `elephant_in_the_room` | Bentley | Personal intimidation | Sterling threatens what the crew loves — and holds Ellie |
| 9 | Shadow Solo Contract | `shadow_solo_contract` | Kiro/Jin | Assassins, elite enforcement | Private hit network guarding the tower's back entrance |

### Finale — Sterling Tower Heist (`sterling_tower_heist`)

Clues converge: ledger + ownership files. Every favor pays off — each friend helped contributes a visible assist (Louis's elevator, Mere's contract trap, Yordano's blackout, Dom's getaway, Jake's patch-up, Bentley's master key). Assists and ending lines scale with friends helped and Night Jobs completed. The ending closes the arc: the city calls Parmida a crime lord now, and the title means something new.

**Theme:** Sterling steals leverage, identity, authorship, safety, and belonging — not only money. Parmida's payoff comes through friendship, loyalty, and favors.

## Night Jobs (side track)

Optional micro-adventures (5–10 minutes) that build Parmida's street legend. Each Night Job must have:

1. Its own micro-story with a named NPC (small favor, small stakes, big personality).
2. A **unique** minigame or puzzle — never a reuse of a story-mission puzzle (story missions own: music sequence, legal-document assembly, keypad code gates).
3. Layered rewards: a scheme card or collectible set piece, plus world/story texture (rumor lines, hideout decorations, crew banter).

Night Jobs are never required to unlock the finale, but they add ending lines and Sterling Tower assists.

### Night Job catalog

| Night Job | Catalog id | Hook | Unique minigame/puzzle | Rewards |
|-----------|-----------|------|------------------------|---------|
| Corner Store Cashout | `corner_store_cashout` | Recover a misplaced cash envelope and petty insurance-scam evidence from a neon corner store back office | Back-office snoop under a chatty clerk's patrol rhythm | First favor, rumor lines, small intel |
| The Laundromat Heist | `laundromat_heist` (planned; build guide at `docs/blueprints/laundromat_heist.build_guide.md`) | A laundromat owner's machines are being used as a Sterling cash-wash node without her knowledge | Wash-cycle timing puzzle (move during noisy cycles, freeze during quiet ones) | Laundering-themed scheme card + Glow Guy |
| Arm-Wrestling Underground | `arm_wrestling_underground` | Win Violet's strength-club challenge and earn a counterpunch | Repeatable timing/strength arm-wrestling minigame | `violet_counterpunch` card + muscle favor; repeatable venue |
| Bentley's Walk | `bentleys_walk` (planned) | Walk Bentley through the neighborhood; his nose finds what people lost | Scent-trail tracking minigame | Poop-bag stock, future Night Job NPC introductions, rumor lines that foreshadow story missions |
| Hideout rehearsal puzzles | (hideout stations, not missions) | "Rehearsals" Parmida runs at the hideout between jobs | Safe-dial listening game (audio/timing); Polaroid darkroom development puzzle (timing/order, ties into the polaroid system); tea-brewing memory game at JC's (seeds Persian Tea's world before the mission) | Intel, cosmetics, Tiny Icons |

Future Night Job slots reserved: one per crew member as post-recruitment "friendship jobs" (e.g., a Yordano gig-night bouncer shift, a Mere paperwork caper), each granting that friend's second scheme card.

**Reward philosophy:** story missions grant clues + the friend; Night Jobs grant *legend* — scheme cards, collectible sets, hideout flair, rumor dialogue, and small favor boosts. Completing themed collectible sets via Night Jobs unlocks set-bonus dialogue.

**Arm-Wrestling reclassification note:** v1 listed Arm-Wrestling Underground as a main mission. It is now a Night Job (repeatable minigame venue). This matches the code: `_unlock_next_missions` grants it after Jazz Club, it grants a favor, and it has never been part of the `_can_unlock_sterling_tower()` gate.

## Cool-Down Shift (mechanic, not a mission)

Replaying an already-completed mission as a "cool-down shift": Parmida returns to the venue and acts *believable* — low-profile objectives only (no alarms, no incriminating pickups, blend-in tasks via `BelievableTaskZone`/cover systems) — to lower that venue's heat before the next job.

- Launch: a completed mission started with a `cooldown_shift` flag swaps its objective set to blend-in tasks.
- Success: calls the existing `GameState.cool_venue_heat()`; heat cannot cool below the failed-attempt floor.
- Reuses existing mission scenes with a modified objective set — no new maps.
- The instant hideout radio action (`run_cooldown_shift` on the Heat Scanner station) remains as a fallback until the playable variant ships, then becomes secondary.

## Global systems (target)

- **Polaroids:** completion + hidden + "perfect moment"; hideout gallery + memory dialogue.
- **Glow Guys / Desk Spirits:** tiny hidden env collectibles; set bonuses when themed sets complete.
- **Tiny Icons / Shelf Goblins:** friend/mission trophies; cosmetic + set dialogue/card art.
- **Bentley poop bags:** utility (evidence cleanup, scent decoy, slip trap, "Responsible Crime Lord" bonus).
- **Evidence clues:** every story mission wires exactly one Sterling clue into the board (`GameState.sterling_clues` / `evidence_clues`) with `connects_to` copy so the conspiracy is player-visible as a chain, mission by mission.
- **Lock language:** delivery badge, staff keycard, VIP wristband, Sterling bronze/silver/gold, elevator fuse, ledger shard, ciphers, Bentley vent tag, crew favor token.
- **Live restart / heat:** small mutation tables (not full procgen): heat steps, alternate codes, moved collectibles, extra patrols, weather, friend hints after failures. Failure is progress: every failed run returns to the hideout with intel, a failure-keyed crew hint, and Sterling-flavored investigation-report copy.
- **Sterling presence beats:** post-Rewrite "rival's welcome" note; post-Getaway personal retaliation revealing Ellie. Delivered via hideout dialogue + dialogue flags, not new systems.

## Build / polish order (recommended)

1. **Phase 1 — showcase:** Taco Bell Drop → Jazz Club → Rewrite Room (+ Corner Store Cashout as Night Job on-ramp).
2. **Phase 2 — pacing:** Clean Job, Diamond a Year Job, Fast Family Getaway (+ Laundromat Heist Night Job).
3. **Phase 3 — personality:** Persian Tea, Elephant in the Room (+ Arm-Wrestling venue, Bentley's Walk, rehearsal puzzles).
4. **Phase 4 — finale:** Shadow Solo Contract, Sterling Tower.

All Phase 1–4 story missions belong on the isometric framework (`IsoMissionBase` or its successor) once converted; the v1 assumption of `LevelBase`-style story rooms is retired.

## Per-mission checklist (template)

Each polished story mission should include: 3–5 zones; primary objective chain; one access gate (item/code/puzzle); one Bentley or Scheme Card optional path; hidden polaroid; one Glow Guy; one Tiny Icon; three poop bag pickups (one optional use); ≥2 stealth angles; ≥1 combat or escape beat; micro-cutscene; mid-mission twist; one Sterling clue wired to the evidence board with `connects_to` copy; restart mutation table; one reward card or crew favor. Keep mission-specific code lean; extend shared systems first.

Night Jobs use a lighter checklist: 1–2 zones; one named NPC with micro-story dialogue; one unique minigame/puzzle; one scheme card or collectible reward; one rumor/world-texture line; optional repeatability.

## Naming reconciliation (v1 → v2 / code)

| v1 name | Canonical id / status |
|---------|----------------------|
| Car Chase | `fast_family_getaway` (stealth mission + timed escape finale) |
| Arm-Wrestling Underground (main mission) | `arm_wrestling_underground` (Night Job, repeatable venue) |
| (absent from v1) | `corner_store_cashout` (canonical first Night Job) |
| (absent from v1) | `laundromat_heist` (planned Night Job) |
| (absent from v1) | `bentleys_walk` (planned Night Job) |

## Code touchpoints

- Missions: `src/missions/*Mission.gd`, `scenes/missions/*.tscn`, iso playable scenes under `scenes/missions_iso/`
- State: `src/autoload/GameState.gd` (mission catalog, unlock graph, clues, favors, heat, polaroids, migration)
- Collectibles: `src/collectibles/CollectibleManager.gd`, polaroid pickups, hideout `GlowCollectibleShelf`
- Clue board: `src/ui/evidence_board/`
- Ending: `src/ui/Ending.gd` (favor-conditional friend lines)
- Heat/cool-down: `src/hideout/HeatScannerRadio.gd`, `GameState.cool_venue_heat()`, `src/missions/iso/runtime/report/InvestigationReportBuilder.gd`
