# 0M-D5-00 — Phase 7: Poop bag / tool

## Code paths (STATIC_ONLY)

- `IsoMissionBase.handle_tool_use` → `MissionToolSurfaceHelper` / `TOOL_POOP_BAG` path → `deploy_poop_bag_decoy_at` (`IsoMissionBase.gd`).
- `MissionToolSurfaceHelper.gd` defines `TOOL_POOP_BAG` (per prior audit; not re-printed here).

## Runtime (GRB)

- `get_runtime_debug_summary()` initial: `poop_bags_used` / collected **0** — counters wired.
- **Throw / aim / decoy spawn:** **NOT_TESTED** (no mouse path in GRB tier used; `grb_click` exists but no proof run).

## Player coupling (STATIC_ONLY)

- `Player.gd` uses duck-typed `deploy_poop_bag_decoy_at` on mission root (known pattern; not re-opened per no-edit rule).

## Conclusion

Tool pipeline is **present and counted** at mission level; **player-facing throw** needs **manual** T / click verification.
