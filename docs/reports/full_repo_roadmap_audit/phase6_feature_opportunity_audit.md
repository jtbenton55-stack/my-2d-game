# GAME-ROADMAP-01 — Phase 6: Feature Opportunity Audit

Each feature is prioritized by **timing** (now / next / soon / later / much_later), **size** (XS / S / M / L / XL), **risk**, **dependency**, whether it **supports future missions**, whether it **risks spaghetti**, and the **recommended owner system**.

Status guide:
- **now** — current vertical-slice work (D5).
- **next** — immediately after vertical slice.
- **soon** — Phase 1 showcase (Jazz → Rewrite).
- **later** — Phase 2/3 missions.
- **much_later** — Phase 4 / finale polish.

## 1. Highest-impact features for the immediate slice

| # | Feature | What it adds | Why it improves the game | Dependency | Risk | Size | When | Future missions | Spaghetti risk | Owner |
|---|---|---|---|---|---|---|---|---|---|---|
| F1 | **Attempt-reset contract** | New attempt clears Quest lines, beam-armed flag, Phase0K counters | Stops mid-run desync; makes Taco feel responsive on retry | D5-01 | low | S | **now** | yes | low if scoped | `MissionObjectiveBridge` + `IsoMissionBase` |
| F2 | **Pause payload pinned to Taco mission_id** | Pause Tabs reliably show Taco-relevant objectives/scheme/clues | Removes "what was I doing" confusion | D5-02 | low | XS | **now** | yes | low | `MissionPauseDataProvider` |
| F3 | **Louis bypass actually neutralizes beam alarm** | Louis route changes runtime, not just layout | The marquee scheme finally pays off | D5-03 | medium | M | **next** | yes (route pattern reusable) | medium | `TacoBellRouteBypassController` + router |
| F4 | **Mission Result + Hideout Return celebratory beat** | Result UI shows mission rewards + a one-line Bentley/Jake reaction; hideout returns with a polaroid added to the wall | Closes the run emotionally | F1–F3 | low | S | **next** | yes | low | `MissionResult.gd` + hideout bridge |

## 2. Core-loop / clarity features (Phase 1 spine)

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F5 | **HUD objective ticker + Bentley scent prompt** | Player always sees the immediate next action | next | S |
| F6 | **Stamina bar UI** (currently only debug overlay) | Sprint feels real | next | S |
| F7 | **Poop bag count + cooldown UI** | Tool feels real | next | S |
| F8 | **Mission Bible's 3-poop-bag pickup contract** for Taco | Reinforces the global tool loop | next | S |
| F9 | **Per-mission small mutation table** (heat steps) for Taco | Restart variety; matches Bible | soon | M |
| F10 | **"Lower Heat Run" + "Clean Getaway Attempt"** mission-board actions actually doing something | Reuse the existing button shells | soon | S |
| F11 | **Polaroid awarded on perfect run** appears in `PolaroidGallery` after return | Hideout has visible progress | soon | S |
| F12 | **Glow Guy + Tiny Icon pickup pattern** used on Taco (per Bible checklist) | Validates global collectible loop | soon | M |

## 3. Hideout usefulness

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F13 | **Mission Board: real progress strip per mission** (clues x/y, polaroid found, perfect ✓) | Hideout is where ambition lives | soon | M |
| F14 | **Evidence Board auto-populates when clues found** | Sterling story moves forward visibly | soon | M |
| F15 | **Bentley care station → small persistent buff** | Existing controller, almost free win | later | S |
| F16 | **Storefront: 1 actual purchasable cosmetic decoration** | Hideout decorating loop has stakes | later | S |
| F17 | **Hideout dialogue triggers based on most recent mission result** | World feels reactive | later | S |
| F18 | **Hideout backup-files cleanup pass** | Remove 22 + 15 backups under scenes/** | next (cleanup) | XS |

## 4. Mission variety / Phase 1 second mission

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F19 | **Migrate Jazz Club to iso framework (`IsoMissionBase` + minimal Phase0J/K)** | Get the second showcase mission on the proven spine | soon | L |
| F20 | **Music puzzle stays optional; not gameplay-blocking** | Reduce risk in iso migration | soon | S |
| F21 | **Yordano basement keycard pickup ported to iso placeholders** | Mission Bible: per-mission lock language | soon | S |

## 5. Stealth / detection feel

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F22 | **Light zone shading subtle visual** (existing `MissionLightZone`) | Stealth angles read better | later | S |
| F23 | **Alert state on HUD with 4-state ladder (normal/suspicious/alerted/resolved)** | Player understands consequences | later | S |
| F24 | **Camera vision cone subtle outline** | Gameplay learnability | later | M |
| F25 | **Single-shot alarm in `MissionAlertController` reused for Velvet stealth** | DRY the alarm pattern | later | S |

## 6. Combat / sprint / dodge feel

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F26 | **i-frames on dodge audited end-to-end** | Combat trust | next | S |
| F27 | **Dash from `DashAbility.gd` integrated as scheme card** instead of always-on | Card meaning | later | M |
| F28 | **Heavy attack ground slam (mouse2) made optional via scheme** | Mission-Bible "one combat beat per mission" | later | M |

## 7. Tools / poop bags

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F29 | **Bag cooldown / charge per attempt** | Pacing | next | S |
| F30 | **Aimed throw arc preview** | Player understands aim radius | next | S |
| F31 | **Decoy attracts patrol for X seconds, then forgets** | Bible decoy mechanic | later | M |

## 8. Scheme cards

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F32 | **3-card draft UI lands before Taco launch** (panel exists; flow not always wired) | Card meta-loop feels alive | next | S |
| F33 | **Card effects discoverable in mission via small toast on first activation** | Players learn cards | later | S |
| F34 | **`mere_legal_eyes` shortcut visible in Taco** (already partially in code: `_try_mere_legal_bypass`) | First Mere scheme matters | next | S |

## 9. Clues / evidence

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F35 | **First Sterling clue on Taco posts to Evidence Board on completion** | Story spine begins | next | S |
| F36 | **Evidence Board has 1 hideout interactable that opens the board scene** | Bible: clues are visible in hideout | already present; verify | XS |

## 10. Save/load UX

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F37 | **Confirm save state survives mission retry** | Player trust | next | S |
| F38 | **"Mission attempts" counter visible in mission board** | Existing data; just show it | later | S |

## 11. Pause / menu UX

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F39 | **Pause objectives tab show next required objective bolded** | Immediate clarity | now | XS |
| F40 | **Pause "Resume / Exit to Hideout" action confirmed across missions** | Exit safety | next | S |

## 12. Visual polish

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F41 | **Iso character scaling visual lock** | Already present; verify regression | next | XS |
| F42 | **Tile snap correction on hand-edited test scene** | Map quality | later | M |
| F43 | **Decor placement snap + valid feedback** | Already partially in `HideoutDecorPlacementValidator` | later | S |

## 13. Audio polish

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F44 | **One short ambience loop for Taco** | Game feels alive | later | S |
| F45 | **Beam alarm sting** | Gameplay clarity | later | S |
| F46 | **Hideout idle music** | Mood | later | S |
| F47 | **Dialogue typewriter sfx** | Already partly themed; finish | later | XS |

## 14. Art / object placement

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F48 | **Use PVGames icon library on existing mission icons** | Existing pipeline | later | S |
| F49 | **Hideout central security palette painted final** | Existing pipeline | later | M |
| F50 | **Object palette dock used to dress one Taco room** | Existing dock | later | S |

## 15. Animation pipeline

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F51 | **Adopt c2b_fix1 contextual classifier output as SpriteFrames for Parmida** | Animation pipeline lands | later | M |
| F52 | **Run anim used only when sprint active** | Anim parity without gating gameplay | later | S |

## 16. Accessibility / readability

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F53 | **Outline pulse on next interactable** | New-player onboarding | later | S |
| F54 | **Hold-to-interact option** | Accessibility | later | S |
| F55 | **Larger dialogue text option** | Already in HUD theme; expose | later | S |

## 17. Tutorial / onboarding

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F56 | **Hideout first-launch dialogue: Jake greets player + nudge to Mission Board** | Onboarding | next | S |
| F57 | **Inline poop-bag tutorial line on first pickup in Taco** | Tool discovery | next | S |
| F58 | **Sprint tutorial banner after 5 seconds of non-sprint movement** | Feature visibility | next | XS |

## 18. Debug / dev tools

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F59 | **Single keystroke debug HUD toggle for Phase0J + sprint overlays** | Dev productivity | next | S |
| F60 | **`reveal_safety` mode integrated as menu option** | QA convenience | later | S |
| F61 | **GRB friendly pause-without-tree-pause toggle** | Bridge stability | later | M |

## 19. Replayability

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F62 | **"Clean Getaway" tracking per mission** (no alarms, no damage) | Bible perfect-moment polaroid | soon | S |
| F63 | **Mission rank surfaces in hideout** | Existing `_mission_rank` not displayed | later | S |
| F64 | **Heat resets via "Lower Heat Run"** | Bible heat loop | soon | S |

## 20. Future missions (recommended next mission AFTER Phase 1 ships)

| # | Feature | Why | When | Size |
|---|---|---|---|---|
| F65 | **Rewrite Room on iso framework** | Phase 1 Bible third showcase | soon-after-Jazz | L |
| F66 | **Sterling clue chain that crosses 3 missions** | Story spine starts paying off | soon | M |
| F67 | **Sterling Tower stub finale (boss room only)** | End feels closer | much_later | XL |

## 21. Decisions / things to NOT add right now

- **Full procgen mutations** — Bible says "small tables, not full procgen"; do not exceed that.
- **Full combat overhaul** — current combat is sufficient for Taco; defer.
- **Full stealth AI rewrite** — defer.
- **More than 3 missions playable simultaneously** — defer until each has its own per-mission acceptance checklist passed.
- **README rewrite** is small-size **but** should NOT happen in the same pass as gameplay changes — do it as a stand-alone "doc hygiene" pass.

## 22. Priority summary

- **NOW (D5):** F1, F2, F39
- **NEXT (post-vertical slice):** F3, F4, F5, F6, F7, F8, F18, F29, F30, F32, F34, F35, F37, F40, F41, F56, F57, F58, F59
- **SOON (Phase 1 showcase):** F9, F10, F11, F12, F13, F14, F19, F20, F21, F62, F64
- **LATER (Phase 2/3):** F15, F16, F17, F22–F28, F31, F33, F38, F42–F55, F60, F61, F63, F65, F66
- **MUCH_LATER (finale):** F67

## 23. Hard assertions

- `feature_opportunities_identified`: **true** (67 catalogued)
- `features_prioritized_by_timing`: **true**

See `phase6_feature_opportunity_audit.json`.
