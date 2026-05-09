from pathlib import Path
import json, subprocess, sys
from PIL import Image
ROOT = Path(__file__).resolve().parents[3]
checks = []
def add(label, ok): checks.append({"label": label, "ok": bool(ok)})
add("reveal-safe backup exists", Path(r"C:\Users\jtben\Documents\PBD 2026\OpenClaw\main\games\_reveal_safe_backups\my-2d-game_REVEAL_SAFE_20260509_092013").exists())
add("current branch is c2", subprocess.check_output(["git","branch","--show-current"], cwd=ROOT, text=True).strip()=="c2-character-sprites-one-shot-20260509-092204")
player = (ROOT/"scenes/characters/player.tscn").read_text(encoding="utf-8")
add("player root preserved", '[node name="Player" type="CharacterBody2D"]' in player)
add("player script preserved", 'path="res://src/player/Player.gd"' in player)
add("new visual exists in player scene", 'PlayerVisual_Parmida' in player)
add("old visual preserved hidden", 'metadata/phase0mc2_fallback' in player and 'visible = false' in player)
add("main collision shape still exists", '[node name="CollisionShape2D" type="CollisionShape2D" parent="."]' in player)
add("root collision layer/mask unchanged", 'collision_layer = 1' in player and 'collision_mask = 7' in player)
add("sandbox exists", (ROOT/"scenes/hideout/tools/CharacterVisualSandbox_0MC2.tscn").exists())
add("sandbox report exists", (ROOT/"docs/reports/character_sprite_replacement/phase0mc2_character_visual_sandbox_report.json").exists())
add("generated visual exists", (ROOT/"assets/characters/generated_player_visuals/parmida_player_visual_0mc2.png").exists())
im = Image.open(ROOT/"assets/characters/generated_player_visuals/parmida_player_visual_0mc2.png").convert("RGBA")
add("generated visual has alpha", im.getchannel("A").getextrema()[0] < 255)
protected = subprocess.check_output(["git","diff","--name-only","--","scenes/missions_iso/TacoBellIso_Editable.tscn","scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"], cwd=ROOT, text=True).strip()
add("Taco Bell scenes unmodified", protected == "")
raw = subprocess.check_output(["git","diff","--name-only","--","assets/characters/pvgames_cyber_city_character_creator_kit","assets/tilesets/cyber_city_core_tilesets"], cwd=ROOT, text=True).strip()
add("raw purchased source assets unmodified", raw == "")
report = {"status": "PASS" if all(c["ok"] for c in checks) else "FAIL", "checks": checks}
out = ROOT/"docs/reports/character_sprite_replacement/phase0mc2_static_validator.json"
out.write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))
sys.exit(0 if report["status"] == "PASS" else 1)
