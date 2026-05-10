# Auto-generated SpriteFrames generator for Parmida player visual
# Phase 0M-C2A

@tool
extends EditorScript

func _run():
    var sprite_frames = SpriteFrames.new()
    
    # Load the composite sheet
    var sheet = load("res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_composite_sheet_0mc2a.png")
    if sheet == null:
        push_error("Failed to load composite sheet")
        return
    
    var frame_width = 100
    var frame_height = 200
    var frames_per_anim = 10
    
    # Create idle animation
    var idle_frames = []
    for i in range(frames_per_anim):
        var atlas = AtlasTexture.new()
        atlas.atlas = sheet
        atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
        idle_frames.append(atlas)
    
    sprite_frames.add_animation("idle")
    sprite_frames.set_animation_speed("idle", 6.0)
    sprite_frames.set_animation_loop("idle", true)
    for frame in idle_frames:
        sprite_frames.add_frame("idle", frame)
    
    # Create walk animation
    var walk_frames = []
    for i in range(frames_per_anim):
        var atlas = AtlasTexture.new()
        atlas.atlas = sheet
        atlas.region = Rect2(i * frame_width, frame_height, frame_width, frame_height)
        walk_frames.append(atlas)
    
    sprite_frames.add_animation("walk")
    sprite_frames.set_animation_speed("walk", 10.0)
    sprite_frames.set_animation_loop("walk", true)
    for frame in walk_frames:
        sprite_frames.add_frame("walk", frame)
    
    # Save the resource
    var save_path = "res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a.tres"
    var err = ResourceSaver.save(sprite_frames, save_path)
    if err == OK:
        print("SpriteFrames saved to: " + save_path)
    else:
        push_error("Failed to save SpriteFrames: " + str(err))
