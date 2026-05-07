#Requires -Version 7.0
<#
.SYNOPSIS
    PreToolUse hook: approval gate for edits to protected governance files.
.DESCRIPTION
    Triggered by the PreToolUse hook in .claude/settings.json via matcher "Edit|Write".

    Reads JSON context from stdin, extracts the target file path, and checks it against
    the protected file set. If the file is protected, emits a structured JSON response
    requesting human approval. Otherwise exits silently.

    Protected files include human-only governance files, hook scripts, and key config files.
    See AGENTS.md — Human-Only Files for the governance rationale.

    Exit 0 always — this hook uses permissionDecision "ask" to prompt the user,
    never exit 2 to hard-block. Fails open on parse errors or missing input.
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

$ProtectedNames = @(
    "AGENTS.md",
    "CLAUDE.md",
    "CURSOR_RULES.md",
    "pyproject.toml",
    "CODEOWNERS",
    ".pre-commit-config.yaml",
    "copier.yaml",
    ".claude/settings.json"
)

$normalizedFile = $file -replace '\\', '/'

$isProtected = $false
$relativePath = $normalizedFile

foreach ($name in $ProtectedNames) {
    if ($normalizedFile -like "*/$name" -or $normalizedFile -eq $name) {
        $isProtected = $true
        $relativePath = $name
        break
    }
}

if (-not $isProtected -and $normalizedFile -match '/\.claude/hooks/' ) {
    $isProtected = $true
    if ($normalizedFile -match '\.claude/hooks/(.+)$') {
        $relativePath = ".claude/hooks/$($Matches[1])"
    }
}

if ($isProtected) {
    $response = @{
        hookEventName      = "PreToolUse"
        permissionDecision = "ask"
        reason             = "This file ($relativePath) is protected. Human approval is required before editing."
    } | ConvertTo-Json -Compress
    Write-Output $response
}

exit 0
