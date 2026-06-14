# AI Tooling Setup Status

## Completed

- Verified Godot project root and `project.godot`.
- Confirmed branch and clean git status.
- Created timestamped setup backups under:
  `reports/ai/setup-backups/20260516-173823/`
- Ensured standard setup directories exist.
- Detected paid Godot MCP Pro package under:
  `addons/godot-mcp-pro/`
- Confirmed paid server package:
  `addons/godot-mcp-pro/server/package.json`
- Built paid server and confirmed entrypoint:
  `addons/godot-mcp-pro/server/build/index.js`
- Normalized addon plugin folder into:
  `addons/godot_mcp/` (copied from paid package, original retained)
- Updated `.cursor/mcp.json` with:
  - `godot-mcp-pro`
  - `godot-lsp-diagnostics`
  - retained `siliconflow-kimi-k2-6`
- Cleared Godot Tools settings from `.vscode/settings.json`.
- Added AGENTS/runbook/checklists and script scaffolding docs.

## Pending / TODO

1. Open Godot -> Project -> Project Settings -> Plugins -> enable Godot MCP Pro.
2. Go is missing from PATH; install Go and rerun build for:
   `C:\Users\jtben\Documents\PBD 2026\tools\godot-dap-mcp-server`
3. After Go is installed, build:
   `go build -o godot-dap-mcp-server.exe cmd/godot-dap-mcp-server/main.go`
4. Once `godot-dap-mcp-server.exe` exists, add `godot-dap-debugger` entry to `.cursor/mcp.json`.
5. Install GdUnit4 manually from official source (AssetLib or official release) into:
   `addons\gdUnit4\`
6. Open Godot and enable GdUnit4 plugin.
7. Optional toolchain (`opencode`, `godot`) may be missing from PATH in some shells. Do not depend on `nmem`; use the Nowledge Mem HTTP API workaround instead.

## Manual Instructions: GdUnit4 Install

1. Open Godot.
2. Open AssetLib.
3. Search `GdUnit4`.
4. Install a version compatible with Godot 4.6.x.
5. Restart Godot.
6. Enable the GdUnit4 plugin.
7. Confirm the GdUnit inspector appears.

## Manual Instructions: OpenCode + Nowledge Mem

- Start Nowledge Mem.
- Confirm the local API is reachable:
  - `Invoke-RestMethod -Uri "http://127.0.0.1:14242/health" -Method Get`
- Use `http://127.0.0.1:14242` directly for memory automation when wrappers fail:
  - `POST /memories/search`
  - `POST /memories`
  - `PATCH /memories/{memory_id}`
- `opencode plugin opencode-nowledge-mem -g` may remain installed, but do not retry `nmem` if the wrapper reports `nmem CLI not found`.
