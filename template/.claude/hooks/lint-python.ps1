#Requires -Version 7.0
<#
.SYNOPSIS
    PostToolUse hook: run ruff lint feedback on .py files after Write or Edit.
.DESCRIPTION
    Triggered by the PostToolUse hook in .claude/settings.json via matcher "Edit|Write".

    IMPORTANT — Runtime verification note:
    The matcher string format ("Edit|Write") is confirmed as the current schema per
    https://json.schemastore.org/claude-code-settings.json and the official docs at
    https://code.claude.com/docs/en/hooks#matcher-patterns
    If this hook stops firing at runtime (i.e., ruff feedback never appears after .py edits),
    verify the current matcher spec at https://code.claude.com/docs/en/hooks and update
    settings.json accordingly. An alternative object-style matcher
    {"matcher": {"tools": ["Write", "Edit"]}} was documented in older versions.

    Claude Code sends JSON context on stdin. Relevant fields for PostToolUse:
      .tool_name       — "Write" or "Edit"
      .tool_input.file_path — absolute path of the affected file

    Exit 0 always (feedback only — hook must never block PostToolUse events).
#>

$ErrorActionPreference = "SilentlyContinue"

try {
    $raw = [Console]::In.ReadToEnd()
    $json = $raw | ConvertFrom-Json -ErrorAction Stop
    $file = $json.tool_input.file_path
} catch {
    exit 0
}

if (-not $file) { exit 0 }
if ($file -notmatch '\.py$') { exit 0 }

if (-not (Test-Path $file)) { exit 0 }

Write-Host "[lint-hook] ruff check $file" -ForegroundColor DarkGray
uv run ruff check $file 2>&1

exit 0
