$ErrorActionPreference = "SilentlyContinue"

function Write-Status {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Detail = ""
    )
    if ($Detail) {
        Write-Output ("[{0}] {1} - {2}" -f $Status, $Name, $Detail)
    } else {
        Write-Output ("[{0}] {1}" -f $Status, $Name)
    }
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $root

Write-Output "AI Tooling Check"
Write-Output ("Workspace: {0}" -f $root)

$commands = @("node", "npm", "npx", "git", "go", "opencode", "nmem", "godot", "cursor")
foreach ($cmd in $commands) {
    $resolved = Get-Command $cmd
    if ($resolved) {
        Write-Status $cmd "OK" $resolved.Source
    } else {
        Write-Status $cmd "MISSING" "Not found in PATH"
    }
}

$mcpPath = Join-Path $root ".cursor\mcp.json"
if (Test-Path $mcpPath) {
    try {
        $mcpJson = Get-Content -Raw -Path $mcpPath | ConvertFrom-Json
        Write-Status ".cursor/mcp.json" "OK" "Valid JSON"

        if ($mcpJson.mcpServers.'godot-mcp-pro' -and $mcpJson.mcpServers.'godot-mcp-pro'.args.Count -gt 0) {
            $proEntrypoint = $mcpJson.mcpServers.'godot-mcp-pro'.args[0]
            if (Test-Path $proEntrypoint) {
                Write-Status "godot-mcp-pro entrypoint" "OK" $proEntrypoint
            } else {
                Write-Status "godot-mcp-pro entrypoint" "MISSING" $proEntrypoint
            }
        } else {
            Write-Status "godot-mcp-pro entrypoint" "SKIP" "Server not configured"
        }
    } catch {
        Write-Status ".cursor/mcp.json" "ERROR" "Invalid JSON"
    }
} else {
    Write-Status ".cursor/mcp.json" "MISSING" "File not found"
}

$dapExe = "C:\Users\jtben\Documents\PBD 2026\tools\godot-dap-mcp-server\godot-dap-mcp-server.exe"
if (Test-Path $dapExe) {
    Write-Status "godot-dap-mcp-server.exe" "OK" $dapExe
} else {
    Write-Status "godot-dap-mcp-server.exe" "MISSING" $dapExe
}

$paths = @(
    "addons\godot_mcp",
    "addons\gdUnit4",
    "project.godot"
)

foreach ($rel in $paths) {
    $full = Join-Path $root $rel
    if (Test-Path $full) {
        Write-Status $rel "OK"
    } else {
        Write-Status $rel "MISSING"
    }
}
