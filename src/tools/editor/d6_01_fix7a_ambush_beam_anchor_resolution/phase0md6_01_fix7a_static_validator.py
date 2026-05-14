import json
from pathlib import Path
root=Path("docs/reports/d6_01_fix7a_ambush_beam_anchor_resolution")
required=[
"phase0md6_01_fix7a_safety_baseline.json",
"phase0md6_01_fix7a_marker_anchor_audit.json",
"phase0md6_01_fix7a_implementation.json",
"phase0md6_01_fix7a_runtime_validation.json"
]
res={"missing":[],"parse_errors":[],"pass":True}
for f in required:
 p=root/f
 if not p.exists():
  res["missing"].append(f);res["pass"]=False;continue
 try:
  json.loads(p.read_text(encoding="utf-8"))
 except Exception as e:
  res["parse_errors"].append({"file":f,"error":str(e)});res["pass"]=False
(root/"phase0md6_01_fix7a_static_validator_run.json").write_text(json.dumps(res,indent=2),encoding="utf-8")
print("PASS" if res["pass"] else "FAIL")
