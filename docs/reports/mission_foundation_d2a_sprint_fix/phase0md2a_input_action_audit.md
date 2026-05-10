# 0M-D2A — Input action audit

## Space

- **Action:** `dodge`
- **Binding:** `physical_keycode` **32** (Space) + gamepad button 2 in `project.godot`.
- **Effect:** Legacy mode: short `dodge_timer` burst at `dodge_speed`. Combat mode: `PlayerCombatController` listens for `dodge` → `DashAbility` dash.

## Ctrl (D2 regression)

- **Intended:** Ctrl as secondary `sprint` binding.
- **Bug:** D2 used `physical_keycode` **4194324**, which is **KEY_PAGEDOWN** in Godot 4 `@GlobalScope`, not Ctrl (**KEY_CTRL = 4194326**). So Ctrl never registered as sprint.

## Stamina sprint path (before D2A)

- `Player.gd` used `(not combat_on) and … Input.is_action_pressed(sprint_action_name)`.
- With default **hitbox combat enabled**, stamina sprint **never ran**; perceived “Space sprint” was **dash/dodge**, not `PlayerStaminaController`.

## After D2A

- `sprint` action: **Space (32)** + **Ctrl (4194326)**.
- `PlayerStaminaController.is_sprint_requested()` is the single press check.
- `Player.gd` allows stamina sprint in combat **except** during active combat dash or legacy dodge burst (avoids stacking with dash velocity).
