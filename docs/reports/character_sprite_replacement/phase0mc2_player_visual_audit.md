# 0M-C2 Player Visual Audit

Player scene: `res://scenes/characters/player.tscn`
Player root: `Player` `CharacterBody2D`.
Player script: `res://src/player/Player.gd`.
Old visual: `AnimatedSprite2D`, position `(0,-16)`, scale `(0.68,0.68)`, SpriteFrames `res://assets/sprites/player_sprite_frames.tres`.
Collision: root layer 1/mask 7; main `CollisionShape2D` rectangle 32x32 at `(0,8)`; combat/hurtbox/detection shapes preserved.
Camera: HideoutHub overrides `GameplayRoot/Characters/Player/Camera2D`; player scene has no camera node.
HideoutHub and Taco Bell both instance the shared player scene, so the production change is shared but visual-only.
Files to modify: player scene only, plus generated visual resources/reports.
