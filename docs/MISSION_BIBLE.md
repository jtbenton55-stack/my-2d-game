# Mission Bible (Sterling Syndicate Arc)

Design source for distinct missions: one mechanic, one emotional flavor, one map shape, one conspiracy clue per mission. Implementation uses `LevelBase`, `GameState.mission_catalog`, `CollectibleManager`, `QuestManager`, and per-mission scripts under `src/missions/`.

## Legal-safe product stand-ins

Do **not** use real collectible brand names or likenesses in copy or assets. In-universe terms:

| Inspiration (vibe only) | In-game names |
|---------------------------|----------------|
| Glow-in-dark mini figures | **Glow Guys**, **Desk Spirits** |
| Stylized shelf figures | **Tiny Icons**, **Shelf Goblins**, **Little Weirdos** |

Polaroid-style IDs in code: `taco_bell_glow_guys`, `velvet_shelf_goblins` (legacy save IDs migrate via `GameState.normalize_polaroid_id`).

## Sterling arc — control methods (one layer per mission)

| Mission | Sterling controls | Clue reveals |
|---------|-------------------|--------------|
| Taco Bell Drop | Delivery routes, safehouse logistics | Secret packets through ordinary delivery |
| Velvet Paw Jazz Club | Blackmail, nightlife, private ledgers | Data hidden in performance/music systems |
| Rewrite Room | Law firms, IP theft, contracts | Creative ownership stolen legally |
| Fast Family Getaway | Cars, garages, transport | Evidence via modified vehicles / routes |
| Clean Job | Luxury showrooms, laundering | Physical erasure of crime traces |
| Diamond Job | High-value vaults, tribute assets | Blackmail keys / bribe diamonds in vaults |
| Arm-Wrestling Underground | Muscle, intimidation | “Legal-adjacent” muscle via fight clubs |
| Persian Tea and Poison Ink | Culture, real estate, community | Takeover of meaningful community spaces |
| Elephant in the Room | Personal intimidation | Sterling threatens what the crew loves |
| Shadow Solo Contract | Assassins, elite enforcement | Private hit network |
| Sterling Tower | Everything | Clues converge: ledger + ownership files |

**Theme:** Sterling steals leverage, identity, authorship, safety, and belonging — not only money. Payoff through friendship, loyalty, and favors.

## Global systems (target)

- **Polaroids:** completion + hidden + “perfect moment”; hideout gallery + memory dialogue.
- **Glow Guys / Desk Spirits:** tiny hidden env collectibles; set bonuses when themed sets complete.
- **Tiny Icons / Shelf Goblins:** friend/mission trophies; cosmetic + set dialogue/card art.
- **Bentley poop bags:** utility (evidence cleanup, scent decoy, slip trap, “Responsible Crime Lord” bonus).
- **Evidence clues:** name, description, category, hideout board link, unlock/modify missions.
- **Lock language:** delivery badge, staff keycard, VIP wristband, Sterling bronze/silver/gold, elevator fuse, ledger shard, ciphers, Bentley vent tag, crew favor token.
- **Live restart / heat:** small mutation tables (not full procgen): heat steps, alternate codes, moved collectibles, extra patrols, weather, friend hints after failures.

## Build / polish order (recommended)

1. **Phase 1 — showcase:** Taco Bell Drop → Jazz Club → Rewrite Room.  
2. **Phase 2 — pacing:** Car Chase, Clean Job, Diamond Job.  
3. **Phase 3 — personality:** Persian Tea, Elephant in the Room, Arm Wrestling.  
4. **Phase 4 — finale:** Shadow Contract, Sterling Tower.

## Per-mission checklist (template)

Each polished mission should include: 3–5 zones; primary objective chain; one access gate (item/code/puzzle); one Bentley or Scheme Card optional path; hidden polaroid; one Glow Guy; one Tiny Icon; three poop bag pickups (one optional use); ≥2 stealth angles; ≥1 combat or escape beat; micro-cutscene; mid-mission twist; one Sterling clue; restart mutation table; one reward card or crew favor. Keep mission-specific code lean; extend shared systems first.

## Code touchpoints

- Missions: `src/missions/*Mission.gd`, `scenes/missions/*.tscn`
- State: `src/autoload/GameState.gd` (missions, polaroids, migration)
- Collectibles: `src/collectibles/CollectibleManager.gd`, polaroid pickups, hideout `GlowCollectibleShelf`
- Clue board: `src/ui/evidence_board/`
