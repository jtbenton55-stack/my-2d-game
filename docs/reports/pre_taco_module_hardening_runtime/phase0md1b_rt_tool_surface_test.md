# Tool surface (0M-D1B-RT)

**Not executed in-engine.**

Static review: `MissionToolSurfaceHelper` delegates to `handle_tool_use` on `IsoMissionBase`; legacy `deploy_poop_bag_decoy_at` path remains for scenes without `handle_tool_use`.
