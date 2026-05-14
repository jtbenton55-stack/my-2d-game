# PHASE 0M-D6-01-FIX6B F10 Search Net Debug Report

## Changes to F10 Display

### New Sections Added

**1. Lifecycle Stats (in Guards section)**
```
Lifecycle: active X / searching Y / dormant Z / removed N
```
- Shows active (chasing/attacking) guards
- Shows searching (patrol/search role) guards
- Shows dormant (far/inactive) guards
- Shows total removed by lifecycle cleanup

**2. Search Net Section (NEW)**
```
--- Search Net (FIX6B) ---
Heat X/5  Radius Y  Role [role]  Ordinal N
Roles: territorial/pursuer/flanker/choke/sentry
```

**3. Updated Beam Locator Section**
```
--- Beam Locator ---
Beam: armed  dist XXXpx  direction: left
Far-right hallway before bag room. Temporary FIX6B red line.
Walk through red line to test.
```

### Implementation Details

**IsoMissionBase.gd changes:**
- Added lifecycle stats to `_runtime_debug_summary()`
- Added search net fields: `search_net_heat`, `search_net_last_role`, `search_net_last_ordinal`
- Added `search_net_triangle_radius_by_heat` lookup
- Added `search_net_roles_by_heat` description

**IsoMissionDebugPanel.gd changes:**
- Added lifecycle display line after guard counts
- Added new "Search Net (FIX6B)" section
- Shows last assigned role and ordinal
- Shows radius for current heat level

### Design Principles

1. **Concise:** No huge dictionaries dumped
2. **Readable:** Clear labels, consistent formatting
3. **Useful:** Shows what matters for debugging search net
4. **Not overcrowded:** Sections are clearly separated

### Sample F10 Output

```
mission=taco_bell_drop
heat=3 attempts=0
code=2174
tiny=0 glow=0 polaroids=0 clues=0 poop_used=0
alert=low alarms=0 wrong_code=0 guards=0 cameras=0
--- Security ---
Heat 3/5  failed_runs 0  alert low
Cooldown: 4.5s
Guards: functional 2 / raw 2 / invalid 0 / cap 7 / queued 0 / reserved 0
Lifecycle: active 1 / searching 1 / dormant 0 / removed 0
Cameras in tree: 2 moving / 3 total
Last spawn: camera_01 / player_near
--- Search Net (FIX6B) ---
Heat 3/5  Radius 200  Role flanker  Ordinal 1
Roles: H0-1: territorial | H2-3: pursuer/flanker | H4: pursuer/flanker/choke/sentry | H5: +double sentry
--- Beam Locator ---
Beam: armed  dist 1450px  direction: right
...
```

### Assertions

- ASSERT f10_search_net_debug_added == true
- ASSERT f10_not_overcrowded_with_code_language == true

### Result

**F10 updated with search net and lifecycle debug info. Remains concise and readable.**
