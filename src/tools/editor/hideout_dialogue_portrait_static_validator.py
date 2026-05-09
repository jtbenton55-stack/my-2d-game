"""Phase 0M-C3 - static validator for the hideout dialogue + portrait pass.

Runs the same checks as `HideoutDialoguePortraitValidator.gd` but from
plain Python so it can execute without a Godot CLI. Writes the results
back to the canonical reports folder.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REPORT_DIR = ROOT / "docs" / "reports" / "hideout_dialogue_portraits"

REQUIRED_FILES = [
    "src/dialogue/DialoguePortraitRegistry.gd",
    "src/dialogue/HideoutCharacterDialogueBank.gd",
    "src/ui/DialogueBox.gd",
    "src/autoload/DialogueManager.gd",
    "src/utils/EventBus.gd",
    "src/hideout/HideoutManager.gd",
    "scenes/ui/DialogueBox.tscn",
    "scenes/hideout/tools/HideoutDialoguePortraitTest.tscn",
    "src/tools/editor/HideoutDialoguePortraitTestRunner.gd",
    "src/tools/editor/HideoutDialoguePortraitValidator.gd",
    "data/dialogue/dialogue_portraits.json",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_dialogue_system_audit.md",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_dialogue_system_audit.json",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_sheet_scan.md",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_sheet_scan.json",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_slice_catalog.md",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_slice_catalog.json",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_slice_catalog.csv",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_assignment_report.md",
    "docs/reports/hideout_dialogue_portraits/phase0mc3_portrait_assignment_report.json",
    "docs/reports/hideout_dialogue_portraits/portrait_slices_contact_sheet.png",
]

REQUIRED_KEYS = ["jake", "parmida", "mere", "bentley", "louis", "fallback"]
TACO_BELL = [
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
]
MIN_LINES_PER_CHARACTER = 12

REQUIRED_MOTIFS = {
    "jake": ["poop bag", "tired", "Parmida"],
    "parmida": ["love", "Bentley"],
    "bentley": ["Mom", "Bark"],
    "louis": ["delivery", "Bentley"],
}


def count_pool_lines(text: str, name: str) -> int:
    pat = re.compile(
        r"const\s+_" + name + r"_LINES\s*:\s*Array\s*=\s*\[(.*?)\]",
        re.DOTALL,
    )
    m = pat.search(text)
    if not m:
        return 0
    body = m.group(1)
    # Each entry is a quoted string ending with `,`. Strings may contain
    # escaped quotes, but each one starts on its own line in our bank.
    return len(re.findall(r'^\s*"', body, re.MULTILINE))


def pool_text(text: str, name: str) -> str:
    pat = re.compile(
        r"const\s+_" + name + r"_LINES\s*:\s*Array\s*=\s*\[(.*?)\]",
        re.DOTALL,
    )
    m = pat.search(text)
    return m.group(1) if m else ""


def main() -> int:
    failures: list[str] = []
    checks: list[dict] = []

    def assert_(label: str, ok: bool) -> None:
        checks.append({"label": label, "ok": ok})
        if not ok:
            failures.append(label)

    for rel in REQUIRED_FILES:
        assert_(f"exists: {rel}", (ROOT / rel).exists())

    portrait_data_path = ROOT / "data/dialogue/dialogue_portraits.json"
    if portrait_data_path.exists():
        data = json.loads(portrait_data_path.read_text(encoding="utf-8"))
        portraits = data.get("portraits", {})
        for key in REQUIRED_KEYS:
            assert_(f"portraits has key: {key}", key in portraits)
        if "parmida" in portraits and "mere" in portraits:
            p1 = portraits["parmida"].get("png_path", "")
            p2 = portraits["mere"].get("png_path", "")
            assert_("parmida and mere share png_path", p1 == p2 and p1 != "")
        for key in REQUIRED_KEYS:
            if key in portraits:
                png = portraits[key].get("png_path", "")
                if png.startswith("res://"):
                    rel = png[len("res://"):]
                    assert_(
                        f"portrait png exists on disk: {key}",
                        (ROOT / rel).exists(),
                    )

    bank_path = ROOT / "src/dialogue/HideoutCharacterDialogueBank.gd"
    if bank_path.exists():
        bank_text = bank_path.read_text(encoding="utf-8")
        for cat, key in [("jake", "JAKE"), ("parmida", "PARMIDA"),
                         ("bentley", "BENTLEY"), ("louis", "LOUIS")]:
            n = count_pool_lines(bank_text, key)
            assert_(
                f"{cat} dialogue line count >= {MIN_LINES_PER_CHARACTER} (got {n})",
                n >= MIN_LINES_PER_CHARACTER,
            )
        for cat, motifs in REQUIRED_MOTIFS.items():
            body = pool_text(bank_text, cat.upper() if cat != "parmida" else "PARMIDA")
            if cat == "parmida":
                body = pool_text(bank_text, "PARMIDA")
            for motif in motifs:
                assert_(
                    f"{cat} dialogue mentions motif '{motif}'",
                    motif.lower() in body.lower(),
                )

    ev_path = ROOT / "src/utils/EventBus.gd"
    if ev_path.exists():
        ev = ev_path.read_text(encoding="utf-8")
        assert_(
            "EventBus declares dialogue_line_changed_full",
            "dialogue_line_changed_full" in ev,
        )

    dm_path = ROOT / "src/autoload/DialogueManager.gd"
    if dm_path.exists():
        dm = dm_path.read_text(encoding="utf-8")
        assert_(
            "DialogueManager emits dialogue_line_changed_full",
            "dialogue_line_changed_full.emit" in dm,
        )
        assert_(
            "Legacy dialogue_line_changed.emit still present",
            "dialogue_line_changed.emit" in dm,
        )

    db_path = ROOT / "scenes/ui/DialogueBox.tscn"
    if db_path.exists():
        db = db_path.read_text(encoding="utf-8")
        assert_(
            "DialogueBox.tscn has PortraitRect TextureRect",
            "PortraitRect" in db and "TextureRect" in db,
        )
        assert_(
            "DialogueBox.tscn UID dialoguebox_v2 unchanged",
            "dialoguebox_v2" in db,
        )

    hm_path = ROOT / "src/hideout/HideoutManager.gd"
    if hm_path.exists():
        hm = hm_path.read_text(encoding="utf-8")
        assert_(
            "HideoutManager has _open_character_portrait_dialogue",
            "_open_character_portrait_dialogue" in hm,
        )
        assert_(
            "HideoutManager imports HideoutCharacterDialogueBank",
            "HideoutCharacterDialogueBank" in hm,
        )

    hl_path = ROOT / "src/levels/Hideout.gd"
    if hl_path.exists():
        hl = hl_path.read_text(encoding="utf-8")
        assert_(
            "Hideout.gd uses HideoutCharacterDialogueBank for anchors",
            "HideoutCharacterDialogueBank" in hl,
        )

    for tb in TACO_BELL:
        assert_(f"taco bell scene still exists: {tb}", (ROOT / tb).exists())

    slice_dir = ROOT / "assets/portraits/generated_slices"
    pngs = list(slice_dir.glob("*.png")) if slice_dir.exists() else []
    assert_(f">=8 sliced PNGs (got {len(pngs)})", len(pngs) >= 8)
    atlas_dir = slice_dir / "atlas_textures"
    atlas = list(atlas_dir.glob("*.tres")) if atlas_dir.exists() else []
    assert_(f">=8 AtlasTexture .tres (got {len(atlas)})", len(atlas) >= 8)

    top = [p for p in (ROOT / "assets/portraits").iterdir()
           if p.is_file() and p.suffix.lower() == ".png"]
    assert_(
        f"5 top-level source sheets unchanged (got {len(top)})",
        len(top) == 5,
    )

    out = {
        "phase": "0M-C3",
        "pass": not failures,
        "failures": failures,
        "checks": checks,
        "ran_via": "python static validator (no Godot CLI required)",
    }
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    (REPORT_DIR / "phase0mc3_static_validator.json").write_text(
        json.dumps(out, indent=2), encoding="utf-8"
    )
    print(json.dumps(out, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
