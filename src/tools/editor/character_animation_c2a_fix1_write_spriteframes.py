"""One-shot: write Godot 4-compatible SpriteFrames for C2A fix1."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "assets/characters/generated_player_visuals/c2a_animation/parmida_player_spriteframes_0mc2a_fix1.tres"


def main() -> None:
    lines: list[str] = [
        '[gd_resource type="SpriteFrames" format=3]',
        "",
        '[ext_resource type="Texture2D" path="res://assets/characters/generated_player_visuals/c2a_animation/parmida_player_composite_sheet_0mc2a.png" id="1_sheet"]',
        "",
    ]
    for i in range(10):
        x = i * 100
        lines += [
            f'[sub_resource type="AtlasTexture" id="idle_{i}"]',
            'atlas = ExtResource("1_sheet")',
            f"region = Rect2({x}, 0, 100, 200)",
            "",
        ]
    for i in range(10):
        x = i * 100
        lines += [
            f'[sub_resource type="AtlasTexture" id="walk_{i}"]',
            'atlas = ExtResource("1_sheet")',
            f"region = Rect2({x}, 200, 100, 200)",
            "",
        ]
    idle_frames = ", ".join([f'SubResource("idle_{i}")' for i in range(10)])
    walk_frames = ", ".join([f'SubResource("walk_{i}")' for i in range(10)])
    lines += [
        "[resource]",
        "animations = [ {",
        f'"frames": [ {idle_frames} ],',
        '"loop": true,',
        '"name": "idle",',
        '"speed": 6.0',
        "}, {",
        f'"frames": [ {walk_frames} ],',
        '"loop": true,',
        '"name": "walk",',
        '"speed": 10.0',
        "} ]",
        "",
    ]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print("Wrote", OUT, OUT.stat().st_size, "bytes")


if __name__ == "__main__":
    main()
