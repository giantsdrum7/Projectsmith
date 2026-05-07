#Requires -Version 7.0
<#
.SYNOPSIS
    Stop hook: non-blocking reminder to run /verify if code-relevant files changed.
.DESCRIPTION
    Triggered by the Stop hook in .claude/settings.json (no matcher — fires on every stop).

    Checks stdin JSON for stop_hook_active to avoid recursive reminders. Gathers
    changed files from git (staged, unstaged, untracked) and filters for code-relevant
    paths (Python source, tests, scripts). If code changes are detected, prints a
    reminder to run /verify.

    Exit 0 always — never blocks Stop, never auto-runs verification.
    Fails open silently if git commands fail or input is unparseable.
#>

$ErrorActionPreference = "SilentlyContinue"

try {
    $raw = [Console]::In.ReadToEnd()
    $json = $raw | ConvertFrom-Json -ErrorAction Stop
    if ($json.stop_hook_active -eq $true) { exit 0 }
} catch {
    # Unparseable input — fail open
}

$codePatterns = @(
    '^src/.*\.py$',
    '^tests/.*\.py$',
    '^scripts/.*\.(ps1|sh)$'
)

$changedFiles = @()

try {
    $unstaged = git diff --name-only 2>$null
    if ($unstaged) { $changedFiles += $unstaged }

    $staged = git diff --cached --name-only 2>$null
    if ($staged) { $changedFiles += $staged }

    $untracked = git ls-files --others --exclude-standard 2>$null
    if ($untracked) { $changedFiles += $untracked }
} catch {
    exit 0
}

$changedFiles = $changedFiles | Sort-Object -Unique

$codeFiles = @()
foreach ($f in $changedFiles) {
    $normalized = $f -replace '\\', '/'
    foreach ($pattern in $codePatterns) {
        if ($normalized -match $pattern) {
            $codeFiles += $normalized
            break
        }
    }
}

if ($codeFiles.Count -eq 0) { exit 0 }

$hasFailure = Test-Path ".cursor/last-verify-failure.txt"

Write-Host ""
if ($hasFailure) {
    Write-Host "[verify-reminder] $($codeFiles.Count) code file(s) changed and a previous verify failure exists." -ForegroundColor Yellow
    Write-Host "[verify-reminder] Strongly recommended: run /verify before finishing." -ForegroundColor Yellow
} else {
    Write-Host "[verify-reminder] $($codeFiles.Count) code file(s) changed. Consider running /verify before finishing." -ForegroundColor DarkGray
}

exit 0
