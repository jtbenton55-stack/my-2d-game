@tool
extends EditorScript
## Optional: run from ScriptEditor → File → Run on a Godot editor build.
## Primary validator is `src/tools/editor/mission_module_audit/mission_audit_validate.py`.

const REPORT_DIR := "res://docs/reports/mission_module_audit/"

func _run() -> void:
	var summary := {}
	var dir := DirAccess.open(REPORT_DIR)
	if dir == null:
		push_error("MissionModuleAuditValidator: cannot open " + REPORT_DIR)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and (name.ends_with(".json") or name.ends_with(".md")):
			summary[name] = true
		name = dir.get_next()
	dir.list_dir_end()
	print("MissionModuleAuditValidator: files under report dir: ", summary.keys())
