# Reporting And Backup Policy

This project keeps generated reports, audit reports, and backup files separated from active gameplay/runtime folders.

## Generated Test Reports

- GdUnit generated HTML/XML report folders use `reports/report_N/`.
- Keep only the latest useful generated report in normal cleanup branches.
- Preserve important pass/fail summaries in `reports/ai/` or `docs/reports/<phase>/` before deleting duplicate generated folders.
- Do not treat old `reports/report_N/` folders as source of truth; they are disposable generated artifacts.

Current latest known GdUnit evidence after the first repo organization cleanup pass:

- `reports/report_5/results.xml`
- `tests="4"`, `failures="0"`, `errors="0"`

If a later GdUnit run creates `reports/report_6/` or higher, that newer folder becomes the latest generated evidence.

## AI And Phase Reports

- `reports/ai/` is for concise AI handoff/summary reports.
- `docs/reports/<phase>/` is for phase-specific static/runtime audit outputs.
- Prefer a short summary report over preserving many duplicate generated HTML folders.

## Backup Scenes

- Active scene folders such as `scenes/characters/` and `scenes/ui/` should contain active scenes only.
- Rollback scene snapshots should live under `reports/godot_ignored_backups/` or another explicitly approved archive path.
- Do not move active gameplay scenes into backup folders unless a backup branch exists and Godot validation confirms no references.

## Local Archives

- Local zip backups should be created outside the repo under `C:\Users\jtben\Documents\PBD 2026\tools\backups\`.
- Do not commit zip archives into the game repo.

## Branch Safety

- Use `backup/<name>` branches for preserved restore points.
- Use `cleanup/<name>` branches for organization passes.
- Do not cleanup directly on the backup branch.
