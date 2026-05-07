# Taco Bell Phase 0J-C4 Real Mechanics Integration

Status: PARTIAL

C4 moves pickups away from message-only behavior by adding scene-local adapters that update Phase0J local state and forward to real project APIs when safe. It is marked PARTIAL because MCP runtime validation timed out during the full all-49 verification pass after one fresh adapter-backed collection proof. The implementation is present, but the report does not overclaim full runtime/menu validation.

## Protection
- Source scene unchanged: yes.
- Source hash before/after: `6E4E9A790D257126B6F8A17587BACAF6` / `6E4E9A790D257126B6F8A17587BACAF6`.
- Duplicate backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0jc4_backup.20260506_142928.tscn`.
- Duplicate hash before/after: `1BECC6ACF1F7A63CDC80E9AD3420CA43` / `B002A8C4E1E412C6A107C15C93075952`.
- Wall collision helper unchanged: `3AC4BE6FB31F7234407EAA4CA5712866`.
- Wall collision shape count before/after: `2368` / `2368`.
- Map regenerated/repainted: no.

## Real System Audit
- `src/missions/iso/TypedMissionCollectible.gd`: `collect()` updates `GameState.typed_collectibles`, poop bags, clues, polaroids, and mission performance depending on type.
- `src/autoload/GameState.gd`: safe APIs include `add_poop_bag()`, `get_poop_bag_count()`, `ensure_and_discover_sterling_clue()`, `record_typed_collectible()`, `collect_polaroid()`, and `record_mission_performance_event()`.
- `src/collectibles/CollectibleManager.gd`: safe APIs include `collect_polaroid()`, `is_collected()`, and `get_collected_polaroids()`.
- `src/autoload/QuestManager.gd`: minimal objective APIs include `set_objective()` and `complete_objective()`.
- `src/ui/test_ui/pause_menu.gd`: Clues panel reads `GameState.sterling_clues`; no general typed collectible/tool tab found.
- `src/ui/PolaroidGallery.gd`: reads `GameState.collected_polaroids`.

## Added Runtime Adapters
- `GameplayRoot/RuntimeHelpers/Phase0JMissionStateAdapter`
- `GameplayRoot/RuntimeHelpers/Phase0JCollectibleMenuAdapter`
- `GameplayRoot/RuntimeHelpers/Phase0JObjectiveAdapter`
- `GameplayRoot/RuntimeHelpers/Phase0JMechanicRouter`

`Phase0JInteractablePickup.gd` now calls `Phase0JMissionStateAdapter.collect_item()` for collectibles. The adapter prevents double-counting, tracks category counts, forwards to the real APIs where available, and reports whether the real menu was updated or only local/typed state was updated.

## Category Integration Map
- Poop bags/BAG: `GameState.add_poop_bag()` and typed collectible state, plus C4 HUD count. No real pause tool tab found.
- CLUE/intel: `GameState.ensure_and_discover_sterling_clue()` so Pause -> Clues can read it.
- PHOTO/Polaroid: `CollectibleManager.collect_polaroid()` / `GameState.collected_polaroids`.
- GLOW/GLOW GUY: `TypedMissionCollectible` / `GameState.typed_collectibles`, C4 HUD count. No dedicated real menu tab found.
- TINY: `TypedMissionCollectible` / `GameState.typed_collectibles`, C4 HUD count. No dedicated real menu tab found.
- Objective/delivery bag: local objective flag, QuestManager objective message, typed clue/state record.
- SAFE_CODE_INPUT_ZONE: existing C2 code UI/controller preserved, plus C4 state adapter gate flag path.
- Non-collectible markers: mechanic router updates inspected state and reports deferred/unsafe old mechanics truthfully.

## Validation
- Static `read_scene`: PASS.
- Fresh in-memory scene contains C4 adapter nodes: PASS.
- Fresh adapter-backed collection proof: `GLOW_market_shop` found `Phase0JMissionStateAdapter`, incremented local `glow_guy` count, and updated `GameState.typed_collectibles`.
- Full all-49 runtime validation: MANUAL_REQUIRED because MCP `game_eval` timed out on longer validation snippets.
- Double-count prevention: implemented in adapter and partially exercised; all-49 proof is manual required.
- Code gate: C2 UI/collision behavior preserved; C4 state adapter path added. Full gate-state adapter proof is manual required due MCP timeout.

## Non-Collectible Parity Audit
- ROUTE/VENT/SWITCH/DOOR/EXIT: inspect-only deferred; old wrappers exist but transition/route/door mechanics are not safe to graft during C4.
- GUARD/PATROL/CAMERA/FLOOD/ALARM: separate combat/detection pass required.
- COVER/BLOCK/HELP/OBJ/SPAWN: inspect-only deferred or no old mechanic found.

## Manual Menu Verification
- Open pause menu: `Esc`.
- Clues: `Pause -> Clues`.
- Polaroids: verify through the existing `PolaroidGallery` flow; it reads `GameState.collected_polaroids`.
- Poop bags, Glow Guys, Tiny icons: verify C4 debug HUD counts; no dedicated pause collectible/tool tab was found.

## Manual Playtest Checklist
1. Run `TacoBellIso_Editable_RedesignTest.tscn`.
2. Confirm walls still work.
3. Confirm purple marker labels still visible.
4. Press E near one poop bag.
5. Confirm visible message.
6. Confirm poop bag count increments in HUD.
7. Open collectible/menu system if available and confirm poop bag/menu status.
8. Press E again on same poop bag and confirm it does not double-count.
9. Repeat for BAG, CLUE/intel, PHOTO/Polaroid, GLOW/GLOW GUY, TINY, and objective/delivery bag.
10. Confirm each changes local state and reports menu update status.
11. Go to `SAFE_CODE_INPUT_ZONE`.
12. Enter wrong code and confirm feedback.
13. Enter `0420` and confirm gate unlocks.
14. Walk through gate.
15. Press E near route, vent, switch, door, exit, guard, camera markers.
16. Confirm each either runs a real wrapped mechanic or clearly reports deferred status.
17. Confirm non-collectible markers do not disappear.
18. Confirm repeated interactions do not crash.
19. Confirm debug HUD counts match what you collected.
20. Confirm this report truthfully states whether the real collectible menu updated or only local debug state updated.

## Warnings
- C4 is PARTIAL, not PASS, because full all-49 runtime proof could not complete through MCP.
- No dedicated real pause menu tab was found for Glow Guys, Tiny icons, or poop bag tools.
- Non-collectible old mechanics are audited but mostly deferred rather than wrapped unsafely.
