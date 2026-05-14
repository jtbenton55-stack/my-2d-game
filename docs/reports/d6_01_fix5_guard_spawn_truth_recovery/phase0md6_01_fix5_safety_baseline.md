# FIX5 safety baseline

- Repo root confirmed.
- Branch confirmed: c2a-full-character-animation-20260509-172230
- Scope confirmed: guard spawn truth/off-map cap repair/right-hall beam/warp removal (code-only).
- Pre-existing working-tree condition: scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn already modified before this pass; not edited by FIX5.
- Protected files remain forbidden (project.godot, Player.gd, PlayerStaminaController.gd, player.tscn, assets, noncanonical Taco scenes).
- Purple warp runtime helper disabled/removed in code.
- Beam is temporary runtime-only tag: D6_FIX5_TEMP_SECURITY_BEAM_REMOVE_OR_FINALIZE_IN_LEVEL_PASS.
