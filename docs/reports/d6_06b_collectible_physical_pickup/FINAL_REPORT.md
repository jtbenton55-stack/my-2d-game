# PHASE 0M-D6-06B — Final Report

## 1. Goal — **PASS**

Authored collectibles are physically collectible via overlap (`body_entered` / `overlap_scan`). F10 uses collapsible sections with Collectible Authoring open by default.

## 2. Files changed

**Modified**
- `src/missions/iso/runtime/AuthoredCollectiblePickup.gd`
- `src/missions/iso/runtime/CollectibleAuthoringRuntimeBuilder.gd`
- `src/missions/iso/authoring/CollectibleAuthorBase.gd`
- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`

**Added**
- `src/tools/editor/d6_06b_collectible_physical_pickup/phase0md6_06b_static_validator.py`
- `docs/reports/d6_06b_collectible_physical_pickup/*`

**Protected (untouched):** `project.godot`, `Player.gd`, `player.tscn`, save/load, HUD/input.

## 3. Root cause

1. **Spawn order:** `CollisionShape2D` was added after `parent.add_child(pickup)`, so `_ready()` ran before a shape existed.
2. **Small radius:** Default 22px circle was smaller than the visible icon and easy to miss while walking.
3. **No overlap fallback:** Only `body_entered` was used; no deferred overlap scan or `_physics_process` check when the player was already inside or physics had not synced yet.

## 4. Fix

- Builder adds shape **before** `add_child`, then calls `configure_from_config`.
- Explicit `monitoring = true`, `collision_mask = 1`, shape enabled, default radius **40px**.
- `pickup_radius` on `CollectibleAuthorBase` (editor preview shows radius).
- `body_entered` + deferred `_check_overlapping_bodies` + `_physics_process` `overlap_scan`.
- Shared `try_collect(source, body)` with duplicate prevention and collision disable on collect.
- F10 records `d6_06_last_pickup_source`, body name, shape/monitoring, `d6_06_physical_overlap_verified`.

## 5. F10 section cleanup

| Section | Default state |
|---------|----------------|
| Mission header | Always visible |
| Collectible Authoring | **Open** (`DEBUG_FOCUS_SECTION := "collectibles"`) |
| Security, Events, AMBUSH, Camera, Guard, Effects, Door | **Collapsed** one-line summaries |
| Legacy FIX7 | Collapsed (hidden unless `SHOW_LEGACY_SECURITY_DEBUG`) |

Change focus per pass: set `DEBUG_FOCUS_SECTION` in `IsoMissionDebugPanel.gd` (e.g. `"door"`, `"security"`).

## 6. Manual test

1. Run Taco RedesignTest.
2. Go to collectible proof cluster (runtime ~7640,789 in current scene layout — SW of security proof).
3. Walk into each colored circle — should collect without debug cheats.
4. F10: `[-] Collectible Authoring` expanded; other sections `[+]` summaries.
5. After pickup: `Source: body_entered` or `overlap_scan`, `overlap verified: yes`.

## 7. Validation

| Tool | Result |
|------|--------|
| Static validator | **PASS** |
| Godot MCP | **PASS** — `body_entered` after overlap; `d6_06_physical_overlap_verified: true`; pickups consumed |
| LSP | No new errors from D6-06B files (editor autoload warnings pre-existing) |
| GdUnit4 | Not run — no D6-06B tests |
| DAP | Not needed |
| Screenshot | `user://d6_06b_physical_pickup_proof.png` |

Kimi: not used.

## 8. Safety

Repo-only; no git history changes; no secrets accessed.

## 9. Suggested next step

**D6-06A** — polish, persistence, objective hooks once Jake confirms walk-up pickup in editor playtest.
