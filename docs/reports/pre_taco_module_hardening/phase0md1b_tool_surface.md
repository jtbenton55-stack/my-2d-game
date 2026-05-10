# Tool / poop surface (0M-D1B)

`MissionToolSurfaceHelper` centralizes discovery of tool support and dispatches to `handle_tool_use` on the current scene when present, with legacy fallback to `deploy_poop_bag_decoy_at`.

`IsoMissionBase` implements `supports_tool` / `handle_tool_use` for `poop_bag`.

**Counter fix:** `deploy_poop_bag_decoy_at` already bumps `poop_bags_used`; Player no longer calls `increment_attempt_counter` a second time for the same throw.
