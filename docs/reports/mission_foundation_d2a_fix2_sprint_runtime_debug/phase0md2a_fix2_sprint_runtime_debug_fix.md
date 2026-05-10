# 0M-D2A-FIX2 — Sprint runtime debug + fix (final report)

**Verdict (agent): PARTIAL** — input/bindings + diagnostics shipped; automated in-game sprint verification not performed (GRB disconnected).

## Sprint signal chain table

| Link | Status | Evidence |
| --- | --- | --- |
| Ctrl physically pressed | NOT TESTED | Overlay shows `ctrl_physical_pressed`; MCP `grb_ping` failed — no headless input. |
| sprint action pressed | NOT TESTED | Overlay shows `sprint_action_pressed` / strength; FIX2 adds keycode + `C` on `sprint`. |
| is_sprint_requested true | NOT TESTED | Live key in `get_sprint_runtime_debug()`. |
| is_sprint_active true | NOT TESTED | Requires requested + moving + stamina + gates. |
| speed multiplier > 1.0 | NOT TESTED | `speed_multiplier` in overlay. |
| multiplier applied to final velocity | TRUE | Code: one `move_speed *= sprint_mult`; then `velocity = input_vector * move_speed` when not dodge/dash combat branch. |
| actual velocity increases | NOT TESTED | Compare `velocity_length_post_slide` with/without sprint manually. |

## Root cause (identified for FIX2 code changes)

FIX1’s `sprint` `InputEventKey` used **`keycode` 0** with Ctrl **`physical_keycode` only**, and `is_sprint_requested` did not use **`get_action_strength`** or **`Input.is_key_pressed(KEY_CTRL)`**. Modifier-only maps are unreliable on some Windows/Godot combinations; **documented `C` fallback** and layout **`keycode` 4194326** address the smallest failing link in the input layer.

## Machine-readable summary

See `phase0md2a_fix2_sprint_runtime_debug_fix.json`.

---

## Output format (fill-in for chat / audit)

A. **0M-D2A-FIX2 SPRINT RUNTIME DEBUG + FIX:** PARTIAL  
B. **Current branch:** c2a-full-character-animation-20260509-172230  
C. **Goal implemented:** Runtime debug overlay + harness + hardened Ctrl/sprint detection + `project.godot` sprint bindings backup; smallest input-link fix.  
D. **Root cause identified:** Weak modifier-only sprint InputMap / missing strength + layout key polling (see above).  
E. **Sprint signal chain table:** See table above.  
F. **Ctrl detected by raw physical key:** NOT TESTED (overlay exposes it).  
G. **Ctrl detected by sprint action:** NOT TESTED (overlay exposes it; map fixed + C duplicate).  
H. **Sprint requested:** NOT TESTED  
I. **Sprint active:** NOT TESTED  
J. **Speed multiplier:** NOT TESTED when active  
K. **Final velocity affected:** TRUE (static: multiplier feeds `move_speed` then velocity).  
L. **Actual velocity increases:** NOT TESTED  
M. **Space dash/dodge preserved:** TRUE (dodge map + `Player.gd` dodge branch unchanged).  
N. **Sprint suppressed during dash/dodge only:** TRUE (static: `wants_sprint` gates `dash_active` and `legacy_dodge_burst`).  
O. **Debug overlay added:** YES  
P. **Debug overlay path:** res://src/player/PlayerSprintDebugOverlay.gd  
Q. **get_sprint_runtime_debug added:** extended (merge signal chain + per-frame physics cache).  
R. **project.godot modified:** YES (sprint events only).  
S. **project.godot backup path:** res://docs/reports/mission_foundation_d2a_fix2_sprint_runtime_debug/backups/project.phase0md2a_fix2_sprint_backup.20260510152155.godot  
T. **PlayerStaminaController modified:** YES  
U. **Player.gd modified:** YES (minimal sprint/debug only).  
V. **player.tscn modified:** NO  
W. **Taco scenes modified:** NO (this pass)  
X. **HideoutHub modified:** NO (this pass)  
Y. **Raw/generated assets modified:** NO (this pass)  
Z. **Sprint requires run animation:** NO  
AA. **Static validator result:** PASS  
AB. **Runtime/GRB validation result:** NOT RUN (bridge not connected)  
AC. **Files modified:** project.godot; src/player/Player.gd; src/player/PlayerStaminaController.gd  
AD. **Files created:** src/player/PlayerSprintDebugOverlay.gd (+ .uid); scenes/hideout/tools/PlayerSprintRuntimeTest_0MD2A_FIX2.gd/.tscn/.uid; src/tools/editor/mission_foundation_d2a_fix2_sprint_runtime_debug/phase0md2a_fix2_sprint_runtime_validator.py; docs/reports/mission_foundation_d2a_fix2_sprint_runtime_debug/** (reports + backup)  
AE. **New debugger errors:** none observed in static review; runtime unchecked.  
AF. **Architecture notes:** Overlay + dict are debug-only; stamina remains modular; single sprint multiplier application.  
AG. **Safety confirmation:** No Taco/Hideout/player scene edits; project.godot backed up before sprint edit.  
AH. **Known limitations:** GRB unavailable; sprint still requires movement + stamina for `_sprinting`; combat `can_act` gate still zeroes movement input (pre-existing).  
AI. **Reports written:** baseline, overlay, audit, implementation, harness, validation, runtime_validation, final_safety_review, this file (+ matching JSON).  
AJ. **Recommended next pass:** In-game confirm overlay chain with Ctrl and with **C** fallback; if link 1 false, capture OS/Godot version.  
AK. **Manual test checklist:** (see user spec items 1–20 — use overlay + Space dodge smoke test).
